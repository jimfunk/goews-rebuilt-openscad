from functools import lru_cache
import logging
from pathlib import Path
import subprocess


logger = logging.getLogger("openscad")


top_dir = (Path(__file__) / "../..").resolve()
model_file = top_dir / "GOEWS.scad"

class OpenSCADError(Exception):
    pass


@lru_cache(maxsize=1024)
def build(**params) -> bytes:
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
        if value:
            if isinstance(value, str):
                cmd += ["-D", f"{name}=\"{value}\""]
            else:
                cmd += ["-D", f"{name}={value}"]

    try:
        result = subprocess.run(cmd, capture_output=True, check=True)
    except subprocess.CalledProcessError as e:
        logger.error(f"OpenSCAD build failed: {e.stderr.decode()}")
        raise OpenSCADError("Model generation failed")

    return result.stdout
