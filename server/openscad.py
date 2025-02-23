import asyncio
from async_lru import alru_cache
import logging
from pathlib import Path


logger = logging.getLogger("openscad")


top_dir = (Path(__file__) / "../..").resolve()
model_file = top_dir / "GOEWS.scad"


class OpenSCADError(Exception):
    pass


# Allow up to 32 processes at once
process_semaphore = asyncio.Semaphore(32)

@alru_cache(maxsize=1024)
async def build(**params) -> bytes:
    if not params:
        raise OpenSCADError("No parameters given")

    cmd = [
        "openscad",
        "--backend",
        "manifold",
        model_file,
        "-o",
        "-",
        "--export-format",
        "stl",
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
            raise OpenSCADError("Model generation failed")

    if proc.returncode != 0:
        logger.error(f"OpenSCAD build failed: {stderr.decode()}")
        raise OpenSCADError("Model generation failed")

    return stdout
