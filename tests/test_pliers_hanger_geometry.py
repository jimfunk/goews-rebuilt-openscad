"""Optional real-render checks: install server/requirements-geometry.txt.

Set OPENSCAD to the executable and OPENSCADPATH to the BOSL2 library directory.
No renderer or mesh result is mocked. Tests skip when the renderer is unavailable.
"""

import math
import os
from pathlib import Path
import shlex
import shutil
import subprocess

import pytest

trimesh = pytest.importorskip("trimesh")

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "pliers_hanger.scad"


def run_openscad(tmp_path, **params):
    assert SOURCE.is_file(), "The Pliers Hanger OpenSCAD model must exist"
    executable = os.environ.get("OPENSCAD", "openscad")
    if not shutil.which(executable):
        pytest.skip("OpenSCAD is not installed; set OPENSCAD to run mesh checks")
    output = tmp_path / "pliers-hanger.stl"
    command = [executable, *shlex.split(os.environ.get("OPENSCAD_ARGS", "--backend manifold"))]
    command += [str(SOURCE), "-o", str(output)]
    for name, value in params.items():
        command += ["-D", f"{name}={value}"]
    result = subprocess.run(command, capture_output=True, text=True, timeout=180)
    return result, output


def render_model(tmp_path, **params):
    result, output = run_openscad(tmp_path, **params)
    assert result.returncode == 0, result.stderr
    assert "ERROR:" not in result.stderr, result.stderr
    assert "WARNING:" not in result.stderr, result.stderr
    assert output.is_file(), result.stderr
    # The shared hanger_plate also exports sub-nanometre coplanar slivers on
    # existing hooks. Welding those vertices collapses zero-area triangles.
    # Drop only duplicate/degenerate faces, without filling holes or remeshing.
    return load_without_repair(output)


def load_without_repair(path):
    mesh = trimesh.load_mesh(path)
    mesh.update_faces(mesh.unique_faces())
    mesh.update_faces(mesh.nondegenerate_faces())
    mesh.remove_unreferenced_vertices()
    # Do not use validate=True: it may fix winding and hide a source defect.
    assert mesh.is_winding_consistent
    assert mesh.volume > 0
    return mesh


def test_default_hanger_is_one_printable_solid(tmp_path):
    mesh = render_model(tmp_path)
    assert mesh.is_watertight
    assert mesh.is_winding_consistent
    assert mesh.is_volume
    assert len(mesh.split()) == 1
    assert mesh.bounds[0, 2] == pytest.approx(0, abs=1e-6)
    assert mesh.volume > 0


@pytest.mark.parametrize("params", [
    {"variant": 2}, {"width": 0}, {"depth": -1}, {"height": 0},
    {"tip_width": 24}, {"tip_width": 0}, {"lip_height": -1},
    {"lip_thickness": 0}, {"rounding": 2}, {"rounding": -1},
    {"hanger_tolerance": -0.1},
])
def test_invalid_customizer_values_fail_explicitly(tmp_path, params):
    result, _ = run_openscad(tmp_path, **params)
    assert "ERROR: Assertion" in result.stderr


@pytest.mark.parametrize("variant", [0, 1])
@pytest.mark.parametrize("params", [
    {},
    {"lip_height": 0, "lip_thickness": 0},
    {"rounding": 0},
    {"width": 60, "depth": 40, "height": 25, "tip_width": 8,
     "lip_height": 5, "lip_thickness": 4},
    {"width": 12, "depth": 12, "height": 8, "tip_width": 2,
     "lip_height": 2, "lip_thickness": 2, "rounding": 0.4},
    {"depth": 1},
    {"width": 34},
    {"hanger_tolerance": 0},
])
def test_parameter_combinations_stay_connected_and_on_bed(tmp_path, variant, params):
    mesh = render_model(tmp_path, variant=variant, **params)
    assert mesh.is_volume
    assert len(mesh.split()) == 1
    assert mesh.nondegenerate_faces().all()
    assert mesh.bounds[0, 2] == pytest.approx(0, abs=1e-6)
    depth = params.get("depth", 25)
    lip_height = params.get("lip_height", 4)
    lip_depth = params.get("lip_thickness", 3) if lip_height else 0
    tolerance = params.get("hanger_tolerance", 0.15)
    plate_front = 8 + tolerance + (0.75 if variant else 0)
    assert mesh.bounds[1, 1] == pytest.approx(plate_front + depth + lip_depth)
    height = params.get("height", 18)
    extension = max(0, height + lip_height + 2 - (24.823 - 10))
    assert mesh.bounds[1, 2] == pytest.approx(24.39 + extension)
    plate_width = 42 * math.ceil((params.get("width", 24) + 2 * lip_height) / 42)
    assert mesh.bounds[0, 0] >= -1e-6
    assert mesh.bounds[1, 0] <= plate_width + 1e-6


def test_support_tapers_between_handles_and_lip_retains_them(tmp_path):
    mesh = render_model(tmp_path)
    # Material along the support centre, widening toward its base, and a taller
    # flange only at the far end. These points are away from rounded surfaces.
    points = [
        [21, 20, 16], [29, 20, 2], [29, 20, 16],
        [21, 35, 20], [21, 20, 20], [35, 20, 12], [7, 20, 12],
    ]
    assert mesh.contains(points).tolist() == [True, True, False, True, False, False, False]


@pytest.mark.parametrize("variant", [0, 1])
def test_bolt_envelope_clear_and_shared_mount_unchanged(tmp_path, variant):
    mesh = render_model(tmp_path, variant=variant)
    extension = max(0, 18 + 4 + 2 - (24.823 - 10))
    plate_front = 8.15 + (0.75 if variant else 0)
    # The full head envelope's lowest point is 2 mm above the lip peak.
    bolt_bottom = 24.823 + extension - 10
    assert bolt_bottom - 22 == pytest.approx(2)
    assert not mesh.contains([[21, plate_front + 1, bolt_bottom + 0.1]])[0]

    # Independently render hanger_plate and compare the mounting volume.
    # Added support must not alter any shared rear mounting surface.
    source = tmp_path / "mount-reference.scad"
    source.write_text(
        "include <BOSL2/std.scad>\n"
        f"include <{ROOT / 'constants.scad'}>\n"
        f"use <{ROOT / 'hanger.scad'}>\n"
        "$fa=0.5; $fs=0.5;\n"
        f"hanger_plate(variant={variant}, hanger_units=1, "
        f"hanger_tolerance=0.15, extend_bottom={extension});\n"
    )
    output = tmp_path / "mount-reference.stl"
    command = [os.environ.get("OPENSCAD", "openscad"),
               *shlex.split(os.environ.get("OPENSCAD_ARGS", "--backend manifold")),
               str(source), "-o", str(output)]
    result = subprocess.run(command, capture_output=True, text=True, timeout=180)
    assert result.returncode == 0, result.stderr
    assert "ERROR:" not in result.stderr and "WARNING:" not in result.stderr
    reference = load_without_repair(output)
    # Sample the rear mounting volume and notch on a deterministic lattice,
    # avoiding exact surfaces; no mesh repair or alternate mount is substituted.
    import numpy as np
    points = np.array(np.meshgrid(
        np.linspace(0.37, 41.63, 31),
        np.linspace(0.13, plate_front - 0.03, 13),
        np.linspace(0.17, 24.39 + extension - 0.17, 23),
        indexing="ij",
    )).reshape(3, -1).T
    # Ray casting is memory intensive; keep the optional test usable on small
    # machines rather than materializing all ray/triangle pairs at once.
    for start in range(0, len(points), 256):
        sample = points[start:start + 256]
        assert np.array_equal(mesh.contains(sample), reference.contains(sample))
