"""Tests for the pliers hanger model and API contract."""

from pathlib import Path
import shlex
import shutil
import subprocess
from unittest.mock import AsyncMock

import pytest
from pydantic import ValidationError

from server.enums import Variant
from server.parts import pliers_hanger
from server.parts.pliers_hanger import PliersHangerDefinition


@pytest.mark.parametrize("field", ["width", "depth", "height", "tip_width"])
@pytest.mark.parametrize("value", [0, -0.1])
def test_support_dimensions_must_be_positive(field, value):
    with pytest.raises(ValidationError):
        PliersHangerDefinition.model_validate({field: value})


@pytest.mark.parametrize(
    "field", ["lip_height", "lip_thickness", "rounding", "hanger_tolerance"]
)
def test_optional_dimensions_must_be_nonnegative(field):
    with pytest.raises(ValidationError):
        PliersHangerDefinition.model_validate({field: -0.1})


@pytest.mark.parametrize(
    "field",
    ["width", "depth", "height", "tip_width", "lip_height", "lip_thickness",
     "rounding", "hanger_tolerance"],
)
@pytest.mark.parametrize("value", [float("inf"), float("-inf"), float("nan")])
def test_all_dimensions_must_be_finite(field, value):
    with pytest.raises(ValidationError):
        PliersHangerDefinition.model_validate({field: value})


@pytest.mark.parametrize("tip_width", [24, 25])
def test_tip_must_be_narrower_than_base(tip_width):
    with pytest.raises(ValidationError, match="tip_width must be less than width"):
        PliersHangerDefinition(tip_width=tip_width)


@pytest.mark.parametrize(
    "dimensions", [{"rounding": 2}, {"rounding": 2.1}, {"height": 2}, {"height": 1.9}]
)
def test_rounding_must_fit_tip_and_height(dimensions):
    with pytest.raises(ValidationError, match=r"2 \* rounding must be less than"):
        PliersHangerDefinition.model_validate(dimensions)


@pytest.mark.parametrize(
    "dimensions", [{"rounding": 0}, {"rounding": 1.999}, {"height": 2.001}]
)
def test_valid_rounding_boundaries(dimensions):
    body = PliersHangerDefinition.model_validate(dimensions)
    for field, value in dimensions.items():
        assert getattr(body, field) == value


def test_enabled_lip_requires_positive_thickness():
    with pytest.raises(ValidationError, match="lip_thickness must be positive"):
        PliersHangerDefinition(lip_thickness=0)


@pytest.mark.parametrize("lip_thickness", [0, 3])
def test_zero_lip_height_disables_retainer(lip_thickness):
    body = PliersHangerDefinition(lip_height=0, lip_thickness=lip_thickness)
    assert body.lip_height == 0
    assert body.lip_thickness == lip_thickness


@pytest.mark.parametrize(
    "dimensions, variant, expected",
    [
        ({}, Variant.ORIGINAL, "pliers-hanger-24x25x18-original.stl"),
        ({}, Variant.THICKER_CLEATS, "pliers-hanger-24x25x18-thicker_cleats.stl"),
        ({"width": 24.5, "depth": 25.25, "height": 18.75}, Variant.ORIGINAL,
         "pliers-hanger-24.5x25.25x18.75-original.stl"),
    ],
)
def test_filename_preserves_dimensions_and_variant(dimensions, variant, expected):
    body = PliersHangerDefinition.model_validate({**dimensions, "variant": variant})
    assert pliers_hanger.make_pliers_hanger_filename(body) == expected


@pytest.mark.parametrize(
    "options, suffix",
    [
        ({"tip_width": 5}, "tip_width_5.0"),
        ({"lip_height": 0}, "lip_height_0.0"),
        ({"lip_thickness": 4}, "lip_thickness_4.0"),
        ({"rounding": 0}, "rounding_0.0"),
        ({"hanger_tolerance": 0}, "hanger_tolerance_0.0"),
        ({"tip_width": 5, "lip_height": 0, "lip_thickness": 0, "rounding": 0,
          "hanger_tolerance": 0.2},
         "tip_width_5.0_lip_height_0.0_lip_thickness_0.0_rounding_0.0_hanger_tolerance_0.2"),
    ],
)
def test_filename_appends_only_changed_options(options, suffix):
    body = PliersHangerDefinition.model_validate(options)
    assert pliers_hanger.make_pliers_hanger_filename(body) == (
        f"pliers-hanger-24x25x18-original-{suffix}.stl"
    )


def test_explicit_defaults_do_not_add_filename_options():
    body = PliersHangerDefinition.model_validate(PliersHangerDefinition().model_dump())
    assert pliers_hanger.make_pliers_hanger_filename(body) == (
        "pliers-hanger-24x25x18-original.stl"
    )


@pytest.mark.parametrize(
    "payload, expected_params, filename",
    [
        ({}, {
            "width": 24.0, "depth": 25.0, "height": 18.0, "tip_width": 4.0,
            "lip_height": 4.0, "lip_thickness": 3.0, "rounding": 1.0,
            "hanger_tolerance": 0.15, "variant": 0,
        }, "pliers-hanger-24x25x18-original.stl"),
        ({
            "width": 30.5, "depth": 28.25, "height": 20.75, "tip_width": 6.5,
            "lip_height": 5.5, "lip_thickness": 4.5, "rounding": 1.25,
            "hanger_tolerance": 0.2, "variant": "Thicker Cleats",
        }, {
            "width": 30.5, "depth": 28.25, "height": 20.75, "tip_width": 6.5,
            "lip_height": 5.5, "lip_thickness": 4.5, "rounding": 1.25,
            "hanger_tolerance": 0.2, "variant": 1,
        }, "pliers-hanger-30.5x28.25x20.75-thicker_cleats-tip_width_6.5_"
           "lip_height_5.5_lip_thickness_4.5_rounding_1.25_hanger_tolerance_0.2.stl"),
        ({"lip_height": 0, "lip_thickness": 0, "rounding": 0}, {
            "width": 24.0, "depth": 25.0, "height": 18.0, "tip_width": 4.0,
            "lip_height": 0.0, "lip_thickness": 0.0, "rounding": 0.0,
            "hanger_tolerance": 0.15, "variant": 0,
        }, "pliers-hanger-24x25x18-original-lip_height_0.0_lip_thickness_0.0_rounding_0.0.stl"),
    ],
)
def test_route_passes_every_parameter_to_build(monkeypatch, payload, expected_params, filename):
    from server.server import app

    # Only the external renderer is mocked; exercise routing and validation over HTTP.
    build = AsyncMock(return_value=b"renderer test bytes")
    monkeypatch.setattr(pliers_hanger, "build", build)
    _, result = app.test_client.post("/api/pliers_hanger", json=payload)

    assert result.status == 200
    assert result.body == b"renderer test bytes"
    assert result.headers["Content-Type"] == "model/stl"
    assert result.headers["Content-Disposition"] == f'attachment; filename="{filename}"'
    build.assert_awaited_once_with("pliers_hanger.scad", **expected_params)


@pytest.mark.parametrize(
    "payload",
    [{"width": 0}, {"depth": "Infinity"}, {"height": "NaN"}, {"tip_width": 24},
     {"rounding": 2}, {"lip_thickness": 0}, {"variant": "Unknown"}],
)
def test_route_rejects_invalid_dimensions_before_build(monkeypatch, payload):
    from server.server import app

    build = AsyncMock()
    monkeypatch.setattr(pliers_hanger, "build", build)
    _, result = app.test_client.post("/api/pliers_hanger", json=payload)

    assert result.status == 400
    build.assert_not_awaited()


@pytest.mark.skipif(shutil.which("make") is None, reason="GNU make is not installed")
def test_makefile_builds_only_default_variants(tmp_path):
    repo = Path(__file__).resolve().parents[3]
    result = subprocess.run(
        ["make", "-np", "parts-pliers-hangers", "TILE_FILL_PERMUTATIONS=",
         f"BUILD_DIR={tmp_path / 'build'}"],
        cwd=repo, capture_output=True, text=True, check=False,
    )
    assert result.returncode == 0, result.stderr
    commands = [
        shlex.split(line) for line in result.stdout.replace("\\\n", " ").splitlines()
        if line.startswith("openscad ")
    ]
    assert len(commands) == 2
    build_target = next(line for line in result.stdout.splitlines() if line.startswith("parts:"))
    clean_target = next(line for line in result.stdout.splitlines() if line.startswith("clean-parts:"))
    assert "parts-pliers-hangers" in build_target.split()
    assert "clean-parts-pliers-hangers" in clean_target.split()
    for command, (variant, number) in zip(commands, [("original", 0), ("thicker_cleats", 1)]):
        output = Path(command[command.index("-o") + 1])
        assert output == tmp_path / "build" / "pliers-hanger" / variant / (
            f"pliers-hanger-24x25x18-{variant}.stl"
        )
        assert "pliers_hanger.scad" in command
        target = next(line for line in result.stdout.splitlines() if line.startswith(f"{output}:"))
        assert {"pliers_hanger.scad", "hanger.scad", "constants.scad"} <= set(target.split()[1:])
        parameters = [command[index + 1] for index, value in enumerate(command) if value == "-D"]
        assert set(parameters) == {
            f"variant={number}", "width=24", "depth=25", "height=18", "tip_width=4",
            "lip_height=4", "lip_thickness=3", "rounding=1", "hanger_tolerance=0.15",
        }


@pytest.mark.skipif(shutil.which("make") is None, reason="GNU make is not installed")
def test_makefile_clean_is_scoped_to_pliers_hangers(tmp_path):
    repo = Path(__file__).resolve().parents[3]
    build_dir = tmp_path / "build"
    hanger_dir = build_dir / "pliers-hanger"
    hanger_dir.mkdir(parents=True)
    (hanger_dir / "example.stl").write_bytes(b"cleanup test fixture")
    sibling = build_dir / "keep.stl"
    sibling.write_bytes(b"unrelated test fixture")
    result = subprocess.run(
        ["make", "clean-parts-pliers-hangers", "TILE_FILL_PERMUTATIONS=",
         f"BUILD_DIR={build_dir}"],
        cwd=repo, capture_output=True, text=True, check=False,
    )
    assert result.returncode == 0, result.stderr
    assert not hanger_dir.exists()
    assert sibling.read_bytes() == b"unrelated test fixture"


def test_default_values():
    body = PliersHangerDefinition()
    assert body.model_dump() == {
        "width": 24.0,
        "depth": 25.0,
        "height": 18.0,
        "tip_width": 4.0,
        "lip_height": 4.0,
        "lip_thickness": 3.0,
        "rounding": 1.0,
        "hanger_tolerance": 0.15,
        "variant": Variant.ORIGINAL,
    }
