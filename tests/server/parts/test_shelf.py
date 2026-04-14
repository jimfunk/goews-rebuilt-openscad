"""Tests for server.parts.shelf module."""

import pytest
from pydantic import ValidationError
from server.parts.shelf import (
    ShelfDefinition, make_shelf_filename,
    HoleShelfDefinition, make_hole_shelf_filename,
    SlotShelfDefinition, make_slot_shelf_filename,
)
from server.enums import Variant


class TestShelfDefinition:
    """Tests for ShelfDefinition model."""

    def test_default_values(self):
        """Test that default values are set correctly."""
        body = ShelfDefinition()
        assert body.width == 83.5
        assert body.depth == 30
        assert body.thickness == 4
        assert body.rear_fillet_radius == 1
        assert body.rounding == 0.5
        assert body.hanger_tolerance == 0.15
        assert body.variant == Variant.ORIGINAL

    def test_validation_width_gt_zero(self):
        """Test that width must be greater than zero."""
        with pytest.raises(ValidationError):
            ShelfDefinition(width=0)

    def test_validation_depth_gt_zero(self):
        """Test that depth must be greater than zero."""
        with pytest.raises(ValidationError):
            ShelfDefinition(depth=0)

    def test_validation_thickness_gt_zero(self):
        """Test that thickness must be greater than zero."""
        with pytest.raises(ValidationError):
            ShelfDefinition(thickness=0)

    def test_validation_rear_fillet_radius_ge_zero(self):
        """Test that rear_fillet_radius must be greater than or equal to zero."""
        with pytest.raises(ValidationError):
            ShelfDefinition(rear_fillet_radius=-1)

    def test_validation_rounding_ge_zero(self):
        """Test that rounding must be greater than or equal to zero."""
        with pytest.raises(ValidationError):
            ShelfDefinition(rounding=-0.1)

    def test_validation_hanger_tolerance_ge_zero(self):
        """Test that hanger_tolerance must be greater than or equal to zero."""
        with pytest.raises(ValidationError):
            ShelfDefinition(hanger_tolerance=-0.1)


class TestMakeShelfFilename:
    """Tests for make_shelf_filename function."""

    def test_default_shelf(self):
        """Test filename for default shelf."""
        body = ShelfDefinition()
        assert make_shelf_filename(body) == "shelf-83.5x30-original.stl"

    def test_custom_dimensions(self):
        """Test filename with custom dimensions."""
        body = ShelfDefinition(width=100, depth=50)
        assert make_shelf_filename(body) == "shelf-100.0x50.0-original.stl"

    def test_thicker_cleats_variant(self):
        """Test filename with thicker cleats variant."""
        body = ShelfDefinition(variant=Variant.THICKER_CLEATS)
        assert make_shelf_filename(body) == "shelf-83.5x30-thicker_cleats.stl"

    def test_custom_thickness(self):
        """Test filename with custom thickness."""
        body = ShelfDefinition(thickness=5)
        assert make_shelf_filename(body) == "shelf-83.5x30-original-thickness_5.0.stl"

    def test_custom_rear_fillet_radius(self):
        """Test filename with custom rear fillet radius."""
        body = ShelfDefinition(rear_fillet_radius=2)
        assert make_shelf_filename(body) == "shelf-83.5x30-original-rear_fillet_radius_2.0.stl"

    def test_custom_rounding(self):
        """Test filename with custom rounding."""
        body = ShelfDefinition(rounding=1)
        assert make_shelf_filename(body) == "shelf-83.5x30-original-rounding_1.0.stl"

    def test_custom_hanger_tolerance(self):
        """Test filename with custom hanger tolerance."""
        body = ShelfDefinition(hanger_tolerance=0.2)
        assert make_shelf_filename(body) == "shelf-83.5x30-original-hanger_tolerance_0.2.stl"


class TestHoleShelfDefinition:
    """Tests for HoleShelfDefinition model."""

    def test_default_values(self):
        """Test that default values are set correctly."""
        body = HoleShelfDefinition()
        assert body.columns == 3
        assert body.rows == 1
        assert body.thickness == 4
        assert body.hole_radius == 3.5
        assert body.column_gap == 15
        assert body.row_gap == 15
        assert body.front_gap == 15
        assert body.rear_gap == 15
        assert body.side_gap == 15
        assert body.stagger is False
        assert body.rear_fillet_radius == 1
        assert body.rounding == 0.5
        assert body.hanger_tolerance == 0.15
        assert body.variant == Variant.ORIGINAL

    def test_validation_columns_gt_zero(self):
        """Test that columns must be greater than zero."""
        with pytest.raises(ValidationError):
            HoleShelfDefinition(columns=0)

    def test_validation_rows_gt_zero(self):
        """Test that rows must be greater than zero."""
        with pytest.raises(ValidationError):
            HoleShelfDefinition(rows=0)

    def test_validation_thickness_gt_zero(self):
        """Test that thickness must be greater than zero."""
        with pytest.raises(ValidationError):
            HoleShelfDefinition(thickness=0)

    def test_validation_hole_radius_gt_zero(self):
        """Test that hole_radius must be greater than zero."""
        with pytest.raises(ValidationError):
            HoleShelfDefinition(hole_radius=0)

    def test_validation_stagger(self):
        """Test that stagger is a boolean."""
        body = HoleShelfDefinition(stagger=True)
        assert body.stagger is True


class TestMakeHoleShelfFilename:
    """Tests for make_hole_shelf_filename function."""

    def test_default_hole_shelf(self):
        """Test filename for default hole shelf."""
        body = HoleShelfDefinition()
        assert make_hole_shelf_filename(body) == "hole-shelf-1x3-original.stl"

    def test_custom_dimensions(self):
        """Test filename with custom dimensions."""
        body = HoleShelfDefinition(rows=2, columns=5)
        assert make_hole_shelf_filename(body) == "hole-shelf-2x5-original.stl"

    def test_thicker_cleats_variant(self):
        """Test filename with thicker cleats variant."""
        body = HoleShelfDefinition(variant=Variant.THICKER_CLEATS)
        assert make_hole_shelf_filename(body) == "hole-shelf-1x3-thicker_cleats.stl"

    def test_stagger(self):
        """Test filename with stagger enabled."""
        body = HoleShelfDefinition(stagger=True)
        assert make_hole_shelf_filename(body) == "hole-shelf-1x3-original-stagger.stl"

    def test_custom_thickness(self):
        """Test filename with custom thickness."""
        body = HoleShelfDefinition(thickness=5)
        assert make_hole_shelf_filename(body) == "hole-shelf-1x3-original-thickness_5.0.stl"


class TestSlotShelfDefinition:
    """Tests for SlotShelfDefinition model."""

    def test_default_values(self):
        """Test that default values are set correctly."""
        body = SlotShelfDefinition()
        assert body.slots == 4
        assert body.thickness == 4
        assert body.slot_length == 40
        assert body.slot_width == 10
        assert body.slot_rounding == 1
        assert body.gap == 10
        assert body.front_gap == 5
        assert body.rear_gap == 10
        assert body.side_gap == 5
        assert body.rear_fillet_radius == 1
        assert body.rounding == 0.5
        assert body.hanger_tolerance == 0.15
        assert body.variant == Variant.ORIGINAL

    def test_validation_slots_gt_zero(self):
        """Test that slots must be greater than zero."""
        with pytest.raises(ValidationError):
            SlotShelfDefinition(slots=0)

    def test_validation_thickness_gt_zero(self):
        """Test that thickness must be greater than zero."""
        with pytest.raises(ValidationError):
            SlotShelfDefinition(thickness=0)

    def test_validation_slot_length_gt_zero(self):
        """Test that slot_length must be greater than zero."""
        with pytest.raises(ValidationError):
            SlotShelfDefinition(slot_length=0)

    def test_validation_slot_width_gt_zero(self):
        """Test that slot_width must be greater than zero."""
        with pytest.raises(ValidationError):
            SlotShelfDefinition(slot_width=0)


class TestMakeSlotShelfFilename:
    """Tests for make_slot_shelf_filename function."""

    def test_default_slot_shelf(self):
        """Test filename for default slot shelf."""
        body = SlotShelfDefinition()
        assert make_slot_shelf_filename(body) == "slot-shelf-10x40x4-original.stl"

    def test_custom_dimensions(self):
        """Test filename with custom dimensions."""
        body = SlotShelfDefinition(slot_width=15, slot_length=50, slots=6)
        assert make_slot_shelf_filename(body) == "slot-shelf-15.0x50.0x6-original.stl"

    def test_thicker_cleats_variant(self):
        """Test filename with thicker cleats variant."""
        body = SlotShelfDefinition(variant=Variant.THICKER_CLEATS)
        assert make_slot_shelf_filename(body) == "slot-shelf-10x40x4-thicker_cleats.stl"

    def test_custom_thickness(self):
        """Test filename with custom thickness."""
        body = SlotShelfDefinition(thickness=5)
        assert make_slot_shelf_filename(body) == "slot-shelf-10x40x4-original-thickness_5.0.stl"

    def test_custom_slot_rounding(self):
        """Test filename with custom slot rounding."""
        body = SlotShelfDefinition(slot_rounding=2)
        assert make_slot_shelf_filename(body) == "slot-shelf-10x40x4-original-slot_rounding_2.0.stl"
