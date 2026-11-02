"""Fingerprint the inputs shared by this deployment's parametric models."""

from functools import lru_cache
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess


# Current models use SCAD sources; also cover common import()/surface() assets.
SOURCE_SUFFIXES = {".scad", ".stl", ".off", ".obj", ".amf", ".3mf", ".dxf", ".svg", ".dat", ".png"}
PROJECT_EXCLUDES = {"build", "venv", "frontend", "__pycache__"}


def _stamp(path: Path) -> tuple:
    info = path.stat()
    return (info.st_dev, info.st_ino, info.st_size, info.st_mtime_ns, info.st_ctime_ns)


@lru_cache(maxsize=8192)
def _file_digest(path: Path, stamp: tuple) -> str:
    with path.open("rb") as stream:
        digest = hashlib.file_digest(stream, "sha256").hexdigest()
    if _stamp(path) != stamp:
        raise OSError(f"Generation input changed while hashing: {path}")
    return digest


@lru_cache(maxsize=8)
def _renderer_info(executable: str, digest: str, search_path: str) -> tuple:
    # The executable digest and OPENSCADPATH are part of this memoization key.
    # --info reports the real search order, including platform-specific defaults.
    env = {**os.environ, "QT_QPA_PLATFORM": os.environ.get("QT_QPA_PLATFORM", "offscreen")}
    result = subprocess.run(
        [executable, "--info"], capture_output=True, text=True, timeout=15, env=env,
    )
    output = result.stdout + "\n" + result.stderr
    lines = output.splitlines()
    marker = "OpenSCAD library path:"
    if marker not in lines or not any(line.startswith("OpenSCAD Version:") for line in lines):
        raise OSError("Cannot discover OpenSCAD version and library paths")
    paths = []
    for line in lines[lines.index(marker) + 1:]:
        if not line.startswith("  "):
            break
        paths.append(str(Path(line.strip()).expanduser().resolve()))
    # Ignore GL diagnostics: --info may fail to create a context on a headless
    # server after printing all the build and search-path information we need.
    build_info = [line for line in lines[:lines.index(marker)] if line.strip()]
    return build_info, paths


def _sources(root: Path, project: bool = False):
    if not root.exists():
        return
    visited = set()

    def onerror(error):
        raise error

    for directory, dirs, files in os.walk(root, followlinks=True, onerror=onerror):
        resolved = Path(directory).resolve()
        if resolved in visited:
            dirs[:] = []
            continue
        visited.add(resolved)
        dirs[:] = sorted(
            name for name in dirs
            if not name.startswith(".") and (not project or name not in PROJECT_EXCLUDES)
        )
        for name in sorted(files):
            path = Path(directory) / name
            if path.suffix.lower() in SOURCE_SUFFIXES:
                yield str(path.relative_to(root)), _file_digest(path, _stamp(path))


def generation_fingerprint(project: Path) -> str:
    """Recheck source trees on each request; memoize only unchanged file content."""
    executable = shutil.which("openscad")
    if executable is None:
        raise OSError("OpenSCAD is not on PATH")
    executable_path = Path(executable).resolve()
    executable_digest = _file_digest(executable_path, _stamp(executable_path))
    build_info, libraries = _renderer_info(
        executable, executable_digest, os.environ.get("OPENSCADPATH", ""),
    )
    project = project.resolve()
    payload = [
        str(project), list(_sources(project, project=True)),
        executable, executable_digest, build_info,
        [(root, list(_sources(Path(root)))) for root in libraries],
        os.environ.get("GOEWS_GENERATOR_REVISION", ""),
    ]
    return hashlib.sha256(json.dumps(payload, separators=(",", ":")).encode()).hexdigest()
