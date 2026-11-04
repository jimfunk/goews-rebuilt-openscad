import asyncio
from async_lru import alru_cache
from contextlib import AsyncExitStack
import logging
from pathlib import Path
import subprocess
import time

from server.generation import generation_fingerprint
from server.model_cache import ArtifactCache, artifact_key, cache_budget, cache_directory


logger = logging.getLogger("openscad")


top_dir = (Path(__file__) / "../..").resolve()
RENDER_BACKEND = "manifold"
EXPORT_FORMAT = "stl"


class OpenSCADError(Exception):
    pass


def openscad_failure(stderr: bytes, action: str) -> OpenSCADError:
    """Log the full OpenSCAD output and return an error carrying its first ERROR line."""
    output = stderr.decode(errors="replace")
    logger.error(f"OpenSCAD {action} failed: {output}")
    detail = next((line for line in output.splitlines() if line.startswith("ERROR:")), None)
    return OpenSCADError(detail or f"{action} failed")


# Allow up to 32 processes at once
process_semaphore = asyncio.Semaphore(32)

def parameter_definitions(params: dict) -> tuple:
    """Canonicalize the effective -D arguments, not the raw request JSON."""
    definitions = []
    for name, value in sorted(params.items()):
        if value is None:
            continue
        if isinstance(value, str):
            value = f'"{value}"'
        elif isinstance(value, bool):
            value = str(value).lower()
        elif isinstance(value, float) and value.is_integer():
            value = str(int(value))
        else:
            value = str(value)
        definitions.append((name, value))
    return tuple(definitions)


async def build(model_file: str, **params) -> bytes:
    """Return a versioned artifact, or generate it once for concurrent callers."""
    if not params:
        raise OpenSCADError("No parameters given")
    definitions = parameter_definitions(params)
    budget = cache_budget()
    generation = None
    if budget:
        try:
            generation = await asyncio.to_thread(generation_fingerprint, top_dir)
        except (OSError, subprocess.SubprocessError) as exc:
            logger.warning("model_cache fingerprint unavailable; bypassing cache: %s", exc)
    return await _cached_build(
        top_dir, model_file, definitions, generation, cache_directory(), budget,
    )


# Keep only in-flight tasks, not a second entry-count-limited collection of STL
# bytes. async-lru shields a shared render when one waiting client disconnects.
@alru_cache(maxsize=None, ttl=0)
async def _cached_build(
    project: Path, model_file: str, definitions: tuple,
    generation: str | None, directory: Path, budget: int,
) -> bytes:
    if generation is None:
        return await _build(project, model_file, definitions)
    key = artifact_key(model_file, definitions, generation, RENDER_BACKEND, EXPORT_FORMAT)
    async with AsyncExitStack() as stack:
        try:
            cache = await asyncio.to_thread(ArtifactCache, directory, budget)
            await stack.enter_async_context(cache.generation_lock(key))
            cached = await asyncio.to_thread(cache.read, key)
        except OSError as exc:
            logger.warning("model_cache read unavailable; bypassing cache: %s", exc)
            return await _build(project, model_file, definitions)
        if cached is not None:
            logger.info("model_cache hit key=%s bytes=%d", key, len(cached))
            return cached
        logger.info("model_cache miss key=%s", key)
        started = time.monotonic()
        result = await _build(project, model_file, definitions)
        logger.info(
            "model_cache render key=%s seconds=%.3f bytes=%d",
            key, time.monotonic() - started, len(result),
        )
        try:
            # Do not publish under an obsolete key if sources changed mid-render.
            if await asyncio.to_thread(generation_fingerprint, project) == generation:
                await asyncio.to_thread(cache.write, key, result)
            else:
                logger.warning("model_cache inputs changed during render; not storing key=%s", key)
        except (OSError, subprocess.SubprocessError) as exc:
            logger.warning("model_cache write unavailable; returning uncached result: %s", exc)
        return result


async def _build(project: Path, model_file: str, definitions: tuple) -> bytes:
    cmd = [
        "openscad",
        "--backend",
        RENDER_BACKEND,
        str(project / model_file),
        "-o",
        "-",
        "--export-format",
        EXPORT_FORMAT,
    ]
    for name, value in definitions:
        cmd += ["-D", f"{name}={value}"]

    async with process_semaphore:
        proc = None
        try:
            proc = await asyncio.create_subprocess_exec(
                *cmd, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
            )
            stdout, stderr = await proc.communicate()
        except asyncio.CancelledError:
            if proc is not None and proc.returncode is None:
                proc.kill()
                await proc.wait()
            raise
        except Exception as exc:
            if proc is not None and proc.returncode is None:
                proc.kill()
                await proc.wait()
            logger.exception("Got exception running openscad")
            raise OpenSCADError("Model generation failed") from exc

    if proc.returncode != 0:
        raise openscad_failure(stderr, "Model generation")

    return stdout


@alru_cache(maxsize=256)
async def render_screenshot(model_file: str, width: int = 800, height: int = 600, **params) -> bytes:
    """Render a PNG screenshot of the model with given parameters."""
    if not params:
        raise OpenSCADError("No parameters given")

    cmd = [
        "openscad",
        "--backend",
        "manifold",
        "--render",
        "--imgsize",
        f"{width}x{height}",
        "--projection",
        "ortho",
        "-o",
        "-",
        str(top_dir / model_file),
    ]
    for name, value in params.items():
        if value is not None:
            if isinstance(value, str):
                cmd += ["-D", f'{name}="{value}"']
            elif isinstance(value, bool):
                cmd += ["-D", f'{name}={str(value).lower()}']
            else:
                cmd += ["-D", f"{name}={value}"]

    async with process_semaphore:
        try:
            proc = await asyncio.create_subprocess_exec(
                *cmd, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
            )
            stdout, stderr = await proc.communicate()
        except asyncio.CancelledError:
            proc.kill()
            raise
        except Exception:
            proc.kill()
            logger.exception("Got exception running openscad")
            raise OpenSCADError("Screenshot generation failed")

    if proc.returncode != 0:
        raise openscad_failure(stderr, "Screenshot generation")

    return stdout
