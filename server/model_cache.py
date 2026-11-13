"""Bounded filesystem artifacts shared by the OpenSCAD generation endpoints.

Locks require a local POSIX filesystem (the supported Linux/macOS servers).
Only this module owns files inside the private artifacts-v1 namespace.
"""

import asyncio
from contextlib import asynccontextmanager, contextmanager
import fcntl
import hashlib
import json
import logging
import os
from pathlib import Path
import re
import stat
import tempfile


logger = logging.getLogger("openscad.cache")
CACHE_VERSION = 1
DEFAULT_MAX_BYTES = 512 * 1024 * 1024
ARTIFACT_NAME = re.compile(r"[0-9a-f]{64}\.stl")


def artifact_key(model: str, definitions: tuple, generation: str, backend: str, output_format: str) -> str:
    payload = json.dumps(
        [CACHE_VERSION, generation, model, backend, output_format, definitions],
        ensure_ascii=True, separators=(",", ":"), allow_nan=False,
    )
    return hashlib.sha256(payload.encode()).hexdigest()


def cache_directory() -> Path:
    default = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "goews"
    return Path(os.environ.get("GOEWS_CACHE_DIR", default)).expanduser()


def cache_budget() -> int:
    budget = int(os.environ.get("GOEWS_CACHE_MAX_BYTES", DEFAULT_MAX_BYTES))
    if budget < 0:
        raise ValueError("GOEWS_CACHE_MAX_BYTES must be nonnegative")
    return budget


class ArtifactCache:
    """Own only a private, versioned namespace below the configured directory."""

    def __init__(self, directory: Path, max_bytes: int):
        self.max_bytes = max_bytes
        self.root = directory.resolve() / f"artifacts-v{CACHE_VERSION}"
        self.root.mkdir(mode=0o700, parents=True, exist_ok=True)
        info = self.root.lstat()
        if not stat.S_ISDIR(info.st_mode) or info.st_uid != os.getuid() or info.st_mode & 0o077:
            raise OSError("Model cache directory must be private and owned by the service user")

    def _path(self, key: str) -> Path:
        if not re.fullmatch(r"[0-9a-f]{64}", key):
            raise ValueError("Invalid artifact key")
        return self.root / f"{key}.stl"

    def _open_lock(self, name: str) -> int:
        fd = os.open(self.root / name, os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
        info = os.fstat(fd)
        if not stat.S_ISREG(info.st_mode) or info.st_uid != os.getuid():
            os.close(fd)
            raise OSError("Unsafe model cache lock")
        return fd

    @asynccontextmanager
    async def generation_lock(self, key: str):
        self._path(key)  # Validate before deriving a lock filename.
        # Bounded lock striping avoids accumulating a lock file for every model.
        # A hash collision only serializes two otherwise independent builds.
        fd = self._open_lock(f"render-{key[:2]}.lock")
        try:
            while True:
                try:
                    fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
                    break
                except BlockingIOError:
                    await asyncio.sleep(0.05)
            yield
        finally:
            os.close(fd)

    @contextmanager
    def _storage_lock(self):
        fd = self._open_lock("storage.lock")
        try:
            fcntl.flock(fd, fcntl.LOCK_EX)
            yield
        finally:
            os.close(fd)

    def _owned_file(self, path: Path):
        info = path.lstat()
        if not stat.S_ISREG(info.st_mode) or info.st_uid != os.getuid() or info.st_nlink != 1:
            raise OSError(f"Unsafe model cache file: {path}")
        return info

    def _prune(self, reserve: int = 0) -> int:
        entries = []
        for path in self.root.iterdir():
            if ARTIFACT_NAME.fullmatch(path.name):
                info = self._owned_file(path)
                entries.append((info.st_mtime_ns, path, info.st_size))
            elif path.name.startswith(".write-"):
                # Writes hold storage.lock, so any temporary file found here is
                # left over from an interrupted process, not an active writer.
                self._owned_file(path)
                path.unlink()
        total = sum(size for _, _, size in entries)
        for _, path, size in sorted(entries):
            if total + reserve <= self.max_bytes:
                break
            path.unlink()
            total -= size
            logger.info("model_cache evict key=%s bytes=%d", path.stem, size)
        return total

    def read(self, key: str) -> bytes | None:
        with self._storage_lock():
            self._prune()
            path = self._path(key)
            try:
                self._owned_file(path)
                fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW)
            except FileNotFoundError:
                return None
            with os.fdopen(fd, "rb") as stream:
                data = stream.read()
                os.utime(stream.fileno(), None)
            if not data:
                path.unlink()
                return None
            return data

    def write(self, key: str, data: bytes) -> None:
        if not data or len(data) > self.max_bytes:
            logger.info("model_cache skip key=%s bytes=%d", key, len(data))
            return
        destination = self._path(key)
        with self._storage_lock():
            total = self._prune(reserve=len(data))
            fd, name = tempfile.mkstemp(prefix=".write-", dir=self.root)
            try:
                with os.fdopen(fd, "wb") as stream:
                    stream.write(data)
                    stream.flush()
                    os.fsync(stream.fileno())
                os.replace(name, destination)
            finally:
                Path(name).unlink(missing_ok=True)
            logger.info(
                "model_cache store key=%s bytes=%d storage_bytes=%d",
                key, len(data), total + len(data),
            )
