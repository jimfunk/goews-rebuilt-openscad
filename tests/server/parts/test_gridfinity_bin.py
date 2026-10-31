"""Tests for server.parts.gridfinity_bin module."""

import pytest
from pydantic import ValidationError
from server.parts.gridfinity_bin import (
    GridfinityBinDefinition,
    GridzDefine,
    StyleTab,
    PlaceTab,
    make_gridfinity_bin_filename,
)
from server.enums import Variant


class TestGridfinityBinDefinition:
    """Tests for GridfinityBinDefinition model."""

    def test_default_values(self):
        """Test that default values are set correctly."""
        body = GridfinityBinDefinition()
        assert body.gridx == 2
        assert body.gridy == 1
        assert body.gridz == 3
        assert body.gridz_define == GridzDefine.GRIDZ_UNITS
        assert body.height_internal == 0
        assert body.enable_zsnap is False
        assert body.include_lip is True
        assert body.divx == 1
        assert body.divy == 1
        assert body.cut_cylinders is False
        assert body.cd == 10
        assert body.c_chamfer == 0.5
        assert body.style_tab == StyleTab.NONE
        assert body.place_tab == PlaceTab.EVERYWHERE
        assert body.scoop == 1
        assert body.only_corners is False
        assert body.refined_holes is False
        assert body.magnet_holes is False
        assert body.screw_holes is False
        assert body.crush_ribs is True
        assert body.chamfer_holes is False
        assert body.printable_hole_top is False
        assert body.enable_thumbscrew is False
        assert body.bottom_thickness == 1.2
        assert body.hanger_tolerance == 0.15
        assert body.variant == Variant.ORIGINAL

    def test_validation_gridx_ge_one(self):
        """Test that gridx must be greater than or equal to 1."""
        with pytest.raises(ValidationError):
            GridfinityBinDefinition(gridx=0)

    def test_validation_gridy_ge_one(self):
        """Test that gridy must be greater than or equal to 1."""
        with pytest.raises(ValidationError):
            GridfinityBinDefinition(gridy=0)

    def test_validation_gridz_ge_one(self):
        """Test that gridz must be greater than or equal to 1."""
        with pytest.raises(ValidationError):
            GridfinityBinDefinition(gridz=0)

    def test_validation_gridz_define(self):
        """Test that gridz_define must be a valid GridzDefine value."""
        with pytest.raises(ValidationError):
            GridfinityBinDefinition(gridz_define="Invalid")

    def test_validation_height_internal_ge_zero(self):
        """Test that height_internal must be greater than or equal to zero."""
        with pytest.raises(ValidationError):
            GridfinityBinDefinition(height_internal=-1)

    def test_validation_divx_ge_zero(self):
        """Test that divx must be greater than or equal to zero."""
        with pytest.raises(ValidationError):
            GridfinityBinDefinition(divx=-1)

    def test_validation_divy_ge_zero(self):
        """Test that divy must be greater than or equal to zero."""
        with pytest.raises(ValidationError):
            GridfinityBinDefinition(divy=-1)

    def test_validation_cd_gt_zero(self):
        """Test that cd must be greater than zero."""
        with pytest.raises(ValidationError):
            GridfinityBinDefinition(cd=0)

    def test_validation_c_chamfer_ge_zero(self):
        """Test that c_chamfer must be greater than or equal to zero."""
        with pytest.raises(ValidationError):
            GridfinityBinDefinition(c_chamfer=-0.1)

    def test_validation_scoop_ge_zero(self):
        """Test that scoop must be greater than or equal to zero."""
        with pytest.raises(ValidationError):
            GridfinityBinDefinition(scoop=-0.1)

    def test_validation_bottom_thickness_gt_zero(self):
        """Test that bottom_thickness must be greater than zero."""
        with pytest.raises(ValidationError):
            GridfinityBinDefinition(bottom_thickness=0)

    def test_validation_hanger_tolerance_ge_zero(self):
        """Test that hanger_tolerance must be greater than or equal to zero."""
        with pytest.raises(ValidationError):
            GridfinityBinDefinition(hanger_tolerance=-0.1)

    def test_validation_bottom_thickness_le_base_height(self):
        """Test that bottom_thickness cannot exceed the gridfinity base height."""
        assert GridfinityBinDefinition(bottom_thickness=7).bottom_thickness == 7
        with pytest.raises(ValidationError):
            GridfinityBinDefinition(bottom_thickness=7.01)

    def test_validation_scoop_le_one(self):
        """Test that scoop cannot exceed 100 percent."""
        assert GridfinityBinDefinition(scoop=0).scoop == 0
        assert GridfinityBinDefinition(scoop=1).scoop == 1
        with pytest.raises(ValidationError):
            GridfinityBinDefinition(scoop=1.1)


class TestGridfinityBinBuildConstraints:
    """Tests for parameter combinations OpenSCAD cannot build."""

    def test_thumbscrew_requires_full_base(self):
        """Test that thumbscrew rejects the default bottom_thickness."""
        with pytest.raises(ValidationError) as exc_info:
            GridfinityBinDefinition(enable_thumbscrew=True)
        assert exc_info.value.errors()[0]["loc"] == ("bottom_thickness",)

    def test_thumbscrew_with_full_base(self):
        """Test that thumbscrew is accepted with a full height base."""
        body = GridfinityBinDefinition(enable_thumbscrew=True, bottom_thickness=7)
        assert body.enable_thumbscrew is True

    def test_refined_holes_incompatible_with_magnet_holes(self):
        """Test that refined holes cannot be combined with magnet holes."""
        with pytest.raises(ValidationError) as exc_info:
            GridfinityBinDefinition(refined_holes=True, magnet_holes=True)
        assert exc_info.value.errors()[0]["loc"] == ("magnet_holes",)

    def test_refined_holes_with_screw_holes(self):
        """Test that refined holes are accepted with screw holes."""
        body = GridfinityBinDefinition(refined_holes=True, screw_holes=True)
        assert body.refined_holes is True

    def test_height_internal_maximum(self):
        """Test that height_internal cannot exceed the bin height less the lip support."""
        assert GridfinityBinDefinition(height_internal=19.8).height_internal == 19.8
        with pytest.raises(ValidationError) as exc_info:
            GridfinityBinDefinition(height_internal=19.81)
        assert exc_info.value.errors()[0]["loc"] == ("height_internal",)

    def test_height_internal_maximum_uses_gridz_define(self):
        """Test that the height_internal maximum follows the gridz definition."""
        body = GridfinityBinDefinition(gridz_define=GridzDefine.INTERNAL_MM, height_internal=8.8)
        assert body.height_internal == 8.8
        with pytest.raises(ValidationError):
            GridfinityBinDefinition(gridz_define=GridzDefine.INTERNAL_MM, height_internal=8.81)

    def test_height_internal_unlimited_without_lip(self):
        """Test that height_internal is unbounded when the lip is excluded."""
        body = GridfinityBinDefinition(include_lip=False, height_internal=1000)
        assert body.height_internal == 1000

    def test_divx_maximum(self):
        """Test that divx cannot subdivide a bin narrower than a compartment."""
        assert GridfinityBinDefinition(gridx=2, divx=13).divx == 13
        with pytest.raises(ValidationError) as exc_info:
            GridfinityBinDefinition(gridx=2, divx=14)
        assert exc_info.value.errors()[0]["loc"] == ("divx",)

    def test_divy_maximum(self):
        """Test that divy cannot subdivide a bin narrower than a compartment."""
        assert GridfinityBinDefinition(gridy=1, divy=6).divy == 6
        with pytest.raises(ValidationError) as exc_info:
            GridfinityBinDefinition(gridy=1, divy=7)
        assert exc_info.value.errors()[0]["loc"] == ("divy",)

    def test_divx_maximum_with_cut_cylinders(self):
        """Test that cylindrical cutouts allow more divisions than compartments."""
        assert GridfinityBinDefinition(gridx=2, divx=135, cut_cylinders=True).divx == 135
        with pytest.raises(ValidationError):
            GridfinityBinDefinition(gridx=2, divx=136, cut_cylinders=True)

    def test_divisions_ignored_when_solid(self):
        """Test that zero divisions produce a solid bin and skip the limits."""
        body = GridfinityBinDefinition(gridx=1, divx=0, divy=0)
        assert body.divx == 0

    def test_compartment_height_minimum(self):
        """Test that compartments require a minimum height above the base."""
        assert GridfinityBinDefinition(gridz=1, bottom_thickness=3).bottom_thickness == 3
        with pytest.raises(ValidationError) as exc_info:
            GridfinityBinDefinition(gridz=1, bottom_thickness=3.5)
        assert exc_info.value.errors()[0]["loc"] == ("bottom_thickness",)

    def test_compartment_height_skipped_without_infill(self):
        """Test that a full height base leaves no infill to subdivide."""
        body = GridfinityBinDefinition(gridz=1, bottom_thickness=7)
        assert body.bottom_thickness == 7


class TestMakeGridfinityBinFilename:
    """Tests for make_gridfinity_bin_filename function."""

    def test_default_bin(self):
        """Test filename for default bin."""
        body = GridfinityBinDefinition()
        assert make_gridfinity_bin_filename(body) == "gridfinity-bin-2x1x3-original.stl"

    def test_custom_dimensions(self):
        """Test filename with custom dimensions."""
        body = GridfinityBinDefinition(gridx=4, gridy=4, gridz=5)
        assert make_gridfinity_bin_filename(body) == "gridfinity-bin-4x4x5-original.stl"

    def test_thicker_cleats_variant(self):
        """Test filename with thicker cleats variant."""
        body = GridfinityBinDefinition(variant=Variant.THICKER_CLEATS)
        assert make_gridfinity_bin_filename(body) == "gridfinity-bin-2x1x3-thicker_cleats.stl"

    def test_no_lip(self):
        """Test filename with no lip."""
        body = GridfinityBinDefinition(include_lip=False)
        assert make_gridfinity_bin_filename(body) == "gridfinity-bin-2x1x3-original-no_include_lip.stl"

    def test_with_divisions_same(self):
        """Test filename with same divx and divy."""
        body = GridfinityBinDefinition(divx=2, divy=2)
        filename = make_gridfinity_bin_filename(body)
        assert "divx_2" in filename or "divy_2" in filename

    def test_with_divisions_different(self):
        """Test filename with different divx and divy."""
        body = GridfinityBinDefinition(divx=2, divy=3)
        filename = make_gridfinity_bin_filename(body)
        assert "divx_2" in filename
        assert "divy_3" in filename

    def test_cut_cylinders(self):
        """Test filename with cut cylinders."""
        body = GridfinityBinDefinition(cut_cylinders=True)
        assert make_gridfinity_bin_filename(body) == "gridfinity-bin-2x1x3-original-cut_cylinders.stl"

    def test_magnet_holes(self):
        """Test filename with magnet holes."""
        body = GridfinityBinDefinition(magnet_holes=True)
        assert make_gridfinity_bin_filename(body) == "gridfinity-bin-2x1x3-original-magnet_holes.stl"

    def test_screw_holes(self):
        """Test filename with screw holes."""
        body = GridfinityBinDefinition(screw_holes=True)
        assert make_gridfinity_bin_filename(body) == "gridfinity-bin-2x1x3-original-screw_holes.stl"

    def test_refined_holes(self):
        """Test filename with refined holes."""
        body = GridfinityBinDefinition(refined_holes=True)
        assert make_gridfinity_bin_filename(body) == "gridfinity-bin-2x1x3-original-refined_holes.stl"

    def test_enable_thumbscrew(self):
        """Test filename with thumbscrew enabled."""
        body = GridfinityBinDefinition(enable_thumbscrew=True, bottom_thickness=7)
        assert make_gridfinity_bin_filename(body) == "gridfinity-bin-2x1x3-original-enable_thumbscrew_bottom_thickness_7.0.stl"

    def test_custom_cd(self):
        """Test filename with custom cd."""
        body = GridfinityBinDefinition(cd=15)
        assert make_gridfinity_bin_filename(body) == "gridfinity-bin-2x1x3-original-cd_15.0.stl"

    def test_custom_c_chamfer(self):
        """Test filename with custom c_chamfer."""
        body = GridfinityBinDefinition(c_chamfer=1)
        assert make_gridfinity_bin_filename(body) == "gridfinity-bin-2x1x3-original-c_chamfer_1.0.stl"

    def test_custom_style_tab(self):
        """Test filename with custom style_tab."""
        body = GridfinityBinDefinition(style_tab=StyleTab.FULL)
        assert make_gridfinity_bin_filename(body) == "gridfinity-bin-2x1x3-original-style_tab_Full.stl"

    def test_custom_place_tab(self):
        """Test filename with custom place_tab."""
        body = GridfinityBinDefinition(place_tab=PlaceTab.TOP_LEFT_DIVISION)
        assert make_gridfinity_bin_filename(body) == "gridfinity-bin-2x1x3-original-place_tab_Top-Left Division.stl"

    def test_custom_scoop(self):
        """Test filename with custom scoop."""
        body = GridfinityBinDefinition(scoop=0)
        assert make_gridfinity_bin_filename(body) == "gridfinity-bin-2x1x3-original-scoop_0.0.stl"

    def test_only_corners(self):
        """Test filename with only_corners enabled."""
        body = GridfinityBinDefinition(only_corners=True)
        assert make_gridfinity_bin_filename(body) == "gridfinity-bin-2x1x3-original-only_corners.stl"

    def test_crush_ribs_false(self):
        """Test filename with crush_ribs disabled."""
        body = GridfinityBinDefinition(crush_ribs=False)
        assert make_gridfinity_bin_filename(body) == "gridfinity-bin-2x1x3-original-no_crush_ribs.stl"

    def test_chamfer_holes_true(self):
        """Test filename with chamfer_holes enabled."""
        body = GridfinityBinDefinition(chamfer_holes=True)
        assert make_gridfinity_bin_filename(body) == "gridfinity-bin-2x1x3-original-chamfer_holes.stl"

    def test_printable_hole_top_true(self):
        """Test filename with printable_hole_top enabled."""
        body = GridfinityBinDefinition(printable_hole_top=True)
        assert make_gridfinity_bin_filename(body) == "gridfinity-bin-2x1x3-original-printable_hole_top.stl"

    def test_custom_bottom_thickness(self):
        """Test filename with custom bottom thickness."""
        body = GridfinityBinDefinition(bottom_thickness=2)
        assert make_gridfinity_bin_filename(body) == "gridfinity-bin-2x1x3-original-bottom_thickness_2.0.stl"

    def test_custom_hanger_tolerance(self):
        """Test filename with custom hanger tolerance."""
        body = GridfinityBinDefinition(hanger_tolerance=0.2)
        assert make_gridfinity_bin_filename(body) == "gridfinity-bin-2x1x3-original-hanger_tolerance_0.2.stl"

    def test_multiple_non_default_options(self):
        """Test filename with multiple non-default options."""
        body = GridfinityBinDefinition(
            gridx=4,
            gridy=4,
            gridz=5,
            include_lip=False,
            magnet_holes=True,
            variant=Variant.THICKER_CLEATS,
        )
        filename = make_gridfinity_bin_filename(body)
        assert filename.startswith("gridfinity-bin-4x4x5-thicker_cleats-")
        assert "include_lip" in filename
        assert "magnet_holes" in filename
