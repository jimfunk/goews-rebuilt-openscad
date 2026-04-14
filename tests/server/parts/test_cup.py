"""Tests for server.parts.cup module."""

import pytest
from pydantic import ValidationError
from server.parts.cup import CupDefinition, make_cup_filename
from server.enums import Variant


class TestCupDefinition:
    """Tests for CupDefinition model."""

    def test_default_values(self):
        """Test that default values are set correctly."""
        body = CupDefinition()
        assert body.inner_diameter == 37.5
        assert body.height == 24.39
        assert body.wall_thickness == 2
        assert body.bottom_thickness == 2
        assert body.inner_rounding == 0.5
        assert body.outer_rounding == 0.5
        assert body.hanger_tolerance == 0.15
        assert body.variant == Variant.ORIGINAL

    def test_custom_values(self):
        """Test that custom values are set correctly."""
        body = CupDefinition(
            inner_diameter=50,
            height=30,
            wall_thickness=3,
            bottom_thickness=3,
            inner_rounding=1,
            outer_rounding=1,
            hanger_tolerance=0.2,
            variant=Variant.THICKER_CLEATS,
        )
        assert body.inner_diameter == 50
        assert body.height == 30
        assert body.wall_thickness == 3
        assert body.bottom_thickness == 3
        assert body.inner_rounding == 1
        assert body.outer_rounding == 1
        assert body.hanger_tolerance == 0.2
        assert body.variant == Variant.THICKER_CLEATS

    def test_validation_inner_diameter_gt_zero(self):
        """Test that inner_diameter must be greater than zero."""
        with pytest.raises(ValidationError):
            CupDefinition(inner_diameter=0)

    def test_validation_height_gt_zero(self):
        """Test that height must be greater than zero."""
        with pytest.raises(ValidationError):
            CupDefinition(height=0)

    def test_validation_wall_thickness_gt_zero(self):
        """Test that wall_thickness must be greater than zero."""
        with pytest.raises(ValidationError):
            CupDefinition(wall_thickness=0)

    def test_validation_bottom_thickness_ge_zero(self):
        """Test that bottom_thickness must be greater than or equal to zero."""
        with pytest.raises(ValidationError):
            CupDefinition(bottom_thickness=-1)

    def test_validation_inner_rounding_ge_zero(self):
        """Test that inner_rounding must be greater than or equal to zero."""
        with pytest.raises(ValidationError):
            CupDefinition(inner_rounding=-0.1)

    def test_validation_outer_rounding_ge_zero(self):
        """Test that outer_rounding must be greater than or equal to zero."""
        with pytest.raises(ValidationError):
            CupDefinition(outer_rounding=-0.1)

    def test_validation_hanger_tolerance_ge_zero(self):
        """Test that hanger_tolerance must be greater than or equal to zero."""
        with pytest.raises(ValidationError):
            CupDefinition(hanger_tolerance=-0.1)


class TestMakeCupFilename:
    """Tests for make_cup_filename function."""

    def test_default_cup(self):
        """Test filename for default cup."""
        body = CupDefinition()
        assert make_cup_filename(body) == "cup-37.5x24.39-original.stl"

    def test_custom_dimensions(self):
        """Test filename with custom dimensions."""
        body = CupDefinition(inner_diameter=50, height=30)
        assert make_cup_filename(body) == "cup-50.0x30.0-original.stl"

    def test_thicker_cleats_variant(self):
        """Test filename with thicker cleats variant."""
        body = CupDefinition(variant=Variant.THICKER_CLEATS)
        assert make_cup_filename(body) == "cup-37.5x24.39-thicker_cleats.stl"

    def test_custom_wall_thickness(self):
        """Test filename with custom wall thickness."""
        body = CupDefinition(wall_thickness=3)
        assert make_cup_filename(body) == "cup-37.5x24.39-original-wall_thickness_3.0.stl"

    def test_custom_bottom_thickness(self):
        """Test filename with custom bottom thickness."""
        body = CupDefinition(bottom_thickness=3)
        assert make_cup_filename(body) == "cup-37.5x24.39-original-bottom_thickness_3.0.stl"

    def test_custom_inner_rounding(self):
        """Test filename with custom inner rounding."""
        body = CupDefinition(inner_rounding=1)
        assert make_cup_filename(body) == "cup-37.5x24.39-original-inner_rounding_1.0.stl"

    def test_custom_outer_rounding(self):
        """Test filename with custom outer rounding."""
        body = CupDefinition(outer_rounding=1)
        assert make_cup_filename(body) == "cup-37.5x24.39-original-outer_rounding_1.0.stl"

    def test_custom_hanger_tolerance(self):
        """Test filename with custom hanger tolerance."""
        body = CupDefinition(hanger_tolerance=0.2)
        assert make_cup_filename(body) == "cup-37.5x24.39-original-hanger_tolerance_0.2.stl"

    def test_multiple_non_default_options(self):
        """Test filename with multiple non-default options."""
        body = CupDefinition(
            inner_diameter=50,
            height=30,
            wall_thickness=3,
            variant=Variant.THICKER_CLEATS,
        )
        filename = make_cup_filename(body)
        assert filename.startswith("cup-50.0x30.0-thicker_cleats-")
        assert "wall_thickness_3.0" in filename
