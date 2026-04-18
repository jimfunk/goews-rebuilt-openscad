"""Tests for server.parts.gridfinity_shelf module."""

import pytest
from pydantic import ValidationError
from server.parts.gridfinity_shelf import (
    GridfinityShelfDefinition, make_gridfinity_shelf_filename,
)
from server.enums import Variant


class TestGridfinityShelfDefinition:
    """Tests for GridfinityShelfDefinition model."""

    def test_default_values(self):
        """Test that default values are set correctly."""
        body = GridfinityShelfDefinition()
        assert body.gridx == 2
        assert body.gridy == 1
        assert body.rear_offset == 4.5
        assert body.max_rear_offset_fillet == 10
        assert body.plate_thickness == 3
        assert body.base_thickness == 0
        assert body.skeletonized is True
        assert body.sides is False
        assert body.side_thickness == 2
        assert body.side_height == 20
        assert body.front is False
        assert body.front_thickness == 2
        assert body.front_height == 20
        assert body.magnet_holes is False
        assert body.magnet_hole_crush_ribs is False
        assert body.magnet_hole_chamfer is False
        assert body.hanger_tolerance == 0.15
        assert body.variant == Variant.ORIGINAL

    def test_validation_gridx_ge_one(self):
        """Test that gridx must be greater than or equal to one."""
        with pytest.raises(ValidationError):
            GridfinityShelfDefinition(gridx=0)

    def test_validation_gridy_ge_one(self):
        """Test that gridy must be greater than or equal to one."""
        with pytest.raises(ValidationError):
            GridfinityShelfDefinition(gridy=0)

    def test_validation_rear_offset_gt_zero(self):
        """Test that rear_offset must be greater than zero."""
        with pytest.raises(ValidationError):
            GridfinityShelfDefinition(rear_offset=0)

    def test_validation_max_rear_offset_fillet_ge_zero(self):
        """Test that max_rear_offset_fillet must be greater than or equal to zero."""
        with pytest.raises(ValidationError):
            GridfinityShelfDefinition(max_rear_offset_fillet=-1)

    def test_validation_plate_thickness_gt_zero(self):
        """Test that plate_thickness must be greater than zero."""
        with pytest.raises(ValidationError):
            GridfinityShelfDefinition(plate_thickness=0)

    def test_validation_base_thickness_ge_zero(self):
        """Test that base_thickness must be greater than or equal to zero."""
        with pytest.raises(ValidationError):
            GridfinityShelfDefinition(base_thickness=-1)

    def test_validation_side_thickness_gt_zero(self):
        """Test that side_thickness must be greater than zero."""
        with pytest.raises(ValidationError):
            GridfinityShelfDefinition(side_thickness=0)

    def test_validation_side_height_gt_zero(self):
        """Test that side_height must be greater than zero."""
        with pytest.raises(ValidationError):
            GridfinityShelfDefinition(side_height=0)

    def test_validation_front_thickness_gt_zero(self):
        """Test that front_thickness must be greater than zero."""
        with pytest.raises(ValidationError):
            GridfinityShelfDefinition(front_thickness=0)

    def test_validation_front_height_gt_zero(self):
        """Test that front_height must be greater than zero."""
        with pytest.raises(ValidationError):
            GridfinityShelfDefinition(front_height=0)

    def test_validation_hanger_tolerance_ge_zero(self):
        """Test that hanger_tolerance must be greater than or equal to zero."""
        with pytest.raises(ValidationError):
            GridfinityShelfDefinition(hanger_tolerance=-0.1)

    def test_sides_boolean(self):
        """Test that sides is a boolean."""
        body = GridfinityShelfDefinition(sides=True)
        assert body.sides is True

    def test_front_boolean(self):
        """Test that front is a boolean."""
        body = GridfinityShelfDefinition(front=True)
        assert body.front is True

    def test_skeletonized_boolean(self):
        """Test that skeletonized is a boolean."""
        body = GridfinityShelfDefinition(skeletonized=False)
        assert body.skeletonized is False

    def test_magnet_holes_boolean(self):
        """Test that magnet_holes is a boolean."""
        body = GridfinityShelfDefinition(magnet_holes=True)
        assert body.magnet_holes is True

    def test_magnet_hole_crush_ribs_boolean(self):
        """Test that magnet_hole_crush_ribs is a boolean."""
        body = GridfinityShelfDefinition(magnet_hole_crush_ribs=True)
        assert body.magnet_hole_crush_ribs is True

    def test_magnet_hole_chamfer_boolean(self):
        """Test that magnet_hole_chamfer is a boolean."""
        body = GridfinityShelfDefinition(magnet_hole_chamfer=True)
        assert body.magnet_hole_chamfer is True

    def test_variant_thicker_cleats(self):
        """Test that variant can be set to THICKER_CLEATS."""
        body = GridfinityShelfDefinition(variant=Variant.THICKER_CLEATS)
        assert body.variant == Variant.THICKER_CLEATS


class TestMakeGridfinityShelfFilename:
    """Tests for make_gridfinity_shelf_filename function."""

    def test_default_gridfinity_shelf(self):
        """Test filename for default gridfinity shelf."""
        body = GridfinityShelfDefinition()
        assert make_gridfinity_shelf_filename(body) == "gridfinity-shelf-2x1-original.stl"

    def test_custom_grid_dimensions(self):
        """Test filename with custom grid dimensions."""
        body = GridfinityShelfDefinition(gridx=3, gridy=2)
        assert make_gridfinity_shelf_filename(body) == "gridfinity-shelf-3x2-original.stl"

    def test_thicker_cleats_variant(self):
        """Test filename with thicker cleats variant."""
        body = GridfinityShelfDefinition(variant=Variant.THICKER_CLEATS)
        assert make_gridfinity_shelf_filename(body) == "gridfinity-shelf-2x1-thicker_cleats.stl"

    def test_custom_rear_offset(self):
        """Test filename with custom rear offset."""
        body = GridfinityShelfDefinition(rear_offset=5)
        assert make_gridfinity_shelf_filename(body) == "gridfinity-shelf-2x1-original-rear_offset_5.0.stl"

    def test_custom_max_rear_offset_fillet(self):
        """Test filename with custom max rear offset fillet."""
        body = GridfinityShelfDefinition(max_rear_offset_fillet=15)
        assert make_gridfinity_shelf_filename(body) == "gridfinity-shelf-2x1-original-max_rear_offset_fillet_15.0.stl"

    def test_custom_plate_thickness(self):
        """Test filename with custom plate thickness."""
        body = GridfinityShelfDefinition(plate_thickness=4)
        assert make_gridfinity_shelf_filename(body) == "gridfinity-shelf-2x1-original-plate_thickness_4.0.stl"

    def test_custom_base_thickness(self):
        """Test filename with custom base thickness."""
        body = GridfinityShelfDefinition(base_thickness=6)
        assert make_gridfinity_shelf_filename(body) == "gridfinity-shelf-2x1-original-base_thickness_6.0.stl"

    def test_no_skeletonized(self):
        """Test filename with skeletonized disabled."""
        body = GridfinityShelfDefinition(skeletonized=False)
        assert make_gridfinity_shelf_filename(body) == "gridfinity-shelf-2x1-original-no_skeletonized.stl"

    def test_with_sides(self):
        """Test filename with sides enabled."""
        body = GridfinityShelfDefinition(sides=True)
        assert make_gridfinity_shelf_filename(body) == "gridfinity-shelf-2x1-original-sides.stl"

    def test_custom_side_thickness(self):
        """Test filename with custom side thickness."""
        body = GridfinityShelfDefinition(side_thickness=3)
        assert make_gridfinity_shelf_filename(body) == "gridfinity-shelf-2x1-original-side_thickness_3.0.stl"

    def test_custom_side_height(self):
        """Test filename with custom side height."""
        body = GridfinityShelfDefinition(side_height=25)
        assert make_gridfinity_shelf_filename(body) == "gridfinity-shelf-2x1-original-side_height_25.0.stl"

    def test_with_front(self):
        """Test filename with front enabled."""
        body = GridfinityShelfDefinition(front=True)
        assert make_gridfinity_shelf_filename(body) == "gridfinity-shelf-2x1-original-front.stl"

    def test_custom_front_thickness(self):
        """Test filename with custom front thickness."""
        body = GridfinityShelfDefinition(front_thickness=3)
        assert make_gridfinity_shelf_filename(body) == "gridfinity-shelf-2x1-original-front_thickness_3.0.stl"

    def test_custom_front_height(self):
        """Test filename with custom front height."""
        body = GridfinityShelfDefinition(front_height=15)
        assert make_gridfinity_shelf_filename(body) == "gridfinity-shelf-2x1-original-front_height_15.0.stl"

    def test_with_magnet_holes(self):
        """Test filename with magnet holes enabled."""
        body = GridfinityShelfDefinition(magnet_holes=True)
        assert make_gridfinity_shelf_filename(body) == "gridfinity-shelf-2x1-original-magnet_holes.stl"

    def test_with_magnet_hole_crush_ribs(self):
        """Test filename with magnet hole crush ribs enabled."""
        body = GridfinityShelfDefinition(magnet_hole_crush_ribs=True)
        assert make_gridfinity_shelf_filename(body) == "gridfinity-shelf-2x1-original-magnet_hole_crush_ribs.stl"

    def test_with_magnet_hole_chamfer(self):
        """Test filename with magnet hole chamfer enabled."""
        body = GridfinityShelfDefinition(magnet_hole_chamfer=True)
        assert make_gridfinity_shelf_filename(body) == "gridfinity-shelf-2x1-original-magnet_hole_chamfer.stl"

    def test_custom_hanger_tolerance(self):
        """Test filename with custom hanger tolerance."""
        body = GridfinityShelfDefinition(hanger_tolerance=0.2)
        assert make_gridfinity_shelf_filename(body) == "gridfinity-shelf-2x1-original-hanger_tolerance_0.2.stl"

    def test_multiple_custom_options(self):
        """Test filename with multiple custom options."""
        body = GridfinityShelfDefinition(
            gridx=4,
            gridy=3,
            skeletonized=False,
            sides=True,
            magnet_holes=True,
        )
        filename = make_gridfinity_shelf_filename(body)
        assert filename.startswith("gridfinity-shelf-4x3-original")
        assert "no_skeletonized" in filename
        assert "sides" in filename
        assert "magnet_holes" in filename
