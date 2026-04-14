"""Tests for server.parts.bin module."""

import pytest
from pydantic import ValidationError
from server.parts.bin import BinDefinition, make_bin_filename
from server.enums import Variant


class TestBinDefinition:
    """Tests for BinDefinition model."""

    def test_default_values(self):
        """Test that default values are set correctly."""
        body = BinDefinition()
        assert body.width == 41.5
        assert body.depth == 41.5
        assert body.height == 20
        assert body.wall_thickness == 1
        assert body.bottom_thickness == 2
        assert body.lip_thickness == 1
        assert body.inner_rounding == 1
        assert body.outer_rounding == 0.5
        assert body.hanger_tolerance == 0.15
        assert body.variant == Variant.ORIGINAL

    def test_custom_values(self):
        """Test that custom values are set correctly."""
        body = BinDefinition(
            width=50,
            depth=60,
            height=30,
            wall_thickness=2,
            bottom_thickness=3,
            lip_thickness=0,
            inner_rounding=0.5,
            outer_rounding=0,
            hanger_tolerance=0.2,
            variant=Variant.THICKER_CLEATS,
        )
        assert body.width == 50
        assert body.depth == 60
        assert body.height == 30
        assert body.wall_thickness == 2
        assert body.bottom_thickness == 3
        assert body.lip_thickness == 0
        assert body.inner_rounding == 0.5
        assert body.outer_rounding == 0
        assert body.hanger_tolerance == 0.2
        assert body.variant == Variant.THICKER_CLEATS

    def test_validation_width_gt_zero(self):
        """Test that width must be greater than zero."""
        from pydantic import ValidationError

        with pytest.raises(ValidationError):
            BinDefinition(width=0)

        with pytest.raises(ValidationError):
            BinDefinition(width=-1)

    def test_validation_depth_gt_zero(self):
        """Test that depth must be greater than zero."""
        from pydantic import ValidationError

        with pytest.raises(ValidationError):
            BinDefinition(depth=0)

    def test_validation_height_gt_zero(self):
        """Test that height must be greater than zero."""
        from pydantic import ValidationError

        with pytest.raises(ValidationError):
            BinDefinition(height=0)

    def test_validation_wall_thickness_gt_zero(self):
        """Test that wall_thickness must be greater than zero."""
        from pydantic import ValidationError

        with pytest.raises(ValidationError):
            BinDefinition(wall_thickness=0)

    def test_validation_bottom_thickness_gt_zero(self):
        """Test that bottom_thickness must be greater than zero."""
        from pydantic import ValidationError

        with pytest.raises(ValidationError):
            BinDefinition(bottom_thickness=0)

    def test_validation_lip_thickness_ge_zero(self):
        """Test that lip_thickness must be greater than or equal to zero."""
        from pydantic import ValidationError

        with pytest.raises(ValidationError):
            BinDefinition(lip_thickness=-1)

    def test_validation_inner_rounding_ge_zero(self):
        """Test that inner_rounding must be greater than or equal to zero."""
        from pydantic import ValidationError

        with pytest.raises(ValidationError):
            BinDefinition(inner_rounding=-0.1)

    def test_validation_outer_rounding_ge_zero(self):
        """Test that outer_rounding must be greater than or equal to zero."""
        from pydantic import ValidationError

        with pytest.raises(ValidationError):
            BinDefinition(outer_rounding=-0.1)

    def test_validation_hanger_tolerance_ge_zero(self):
        """Test that hanger_tolerance must be greater than or equal to zero."""
        from pydantic import ValidationError

        with pytest.raises(ValidationError):
            BinDefinition(hanger_tolerance=-0.1)


class TestMakeBinFilename:
    """Tests for make_bin_filename function."""

    def test_default_bin(self):
        """Test filename for default bin."""
        body = BinDefinition()
        assert make_bin_filename(body) == "bin-41.5x41.5x20-original.stl"

    def test_custom_dimensions(self):
        """Test filename with custom dimensions."""
        body = BinDefinition(width=50, depth=60, height=30)
        assert make_bin_filename(body) == "bin-50.0x60.0x30.0-original.stl"

    def test_thicker_cleats_variant(self):
        """Test filename with thicker cleats variant."""
        body = BinDefinition(variant=Variant.THICKER_CLEATS)
        assert make_bin_filename(body) == "bin-41.5x41.5x20-thicker_cleats.stl"

    def test_custom_wall_thickness(self):
        """Test filename with custom wall thickness."""
        body = BinDefinition(wall_thickness=2)
        assert make_bin_filename(body) == "bin-41.5x41.5x20-original-wall_thickness_2.0.stl"

    def test_custom_bottom_thickness(self):
        """Test filename with custom bottom thickness."""
        body = BinDefinition(bottom_thickness=3)
        assert make_bin_filename(body) == "bin-41.5x41.5x20-original-bottom_thickness_3.0.stl"

    def test_custom_lip_thickness(self):
        """Test filename with custom lip thickness."""
        body = BinDefinition(lip_thickness=0)
        assert make_bin_filename(body) == "bin-41.5x41.5x20-original-lip_thickness_0.0.stl"

    def test_custom_inner_rounding(self):
        """Test filename with custom inner rounding."""
        body = BinDefinition(inner_rounding=0.5)
        assert make_bin_filename(body) == "bin-41.5x41.5x20-original-inner_rounding_0.5.stl"

    def test_custom_outer_rounding(self):
        """Test filename with custom outer rounding."""
        body = BinDefinition(outer_rounding=0)
        assert make_bin_filename(body) == "bin-41.5x41.5x20-original-outer_rounding_0.0.stl"

    def test_custom_hanger_tolerance(self):
        """Test filename with custom hanger tolerance."""
        body = BinDefinition(hanger_tolerance=0.2)
        assert make_bin_filename(body) == "bin-41.5x41.5x20-original-hanger_tolerance_0.2.stl"

    def test_multiple_non_default_options(self):
        """Test filename with multiple non-default options."""
        body = BinDefinition(
            width=50,
            depth=50,
            height=30,
            wall_thickness=2,
            bottom_thickness=3,
            variant=Variant.THICKER_CLEATS,
        )
        filename = make_bin_filename(body)
        assert filename.startswith("bin-50.0x50.0x30.0-thicker_cleats-")
        assert "wall_thickness_2.0" in filename
        assert "bottom_thickness_3.0" in filename

    def test_all_non_default_options(self):
        """Test filename with all options set to non-default values."""
        body = BinDefinition(
            width=100,
            depth=100,
            height=50,
            wall_thickness=2,
            bottom_thickness=4,
            lip_thickness=2,
            inner_rounding=2,
            outer_rounding=1,
            hanger_tolerance=0.3,
            variant=Variant.THICKER_CLEATS,
        )
        filename = make_bin_filename(body)
        assert filename.startswith("bin-100.0x100.0x50.0-thicker_cleats-")
        assert "wall_thickness_2.0" in filename
        assert "bottom_thickness_4.0" in filename
        assert "lip_thickness_2.0" in filename
        assert "inner_rounding_2.0" in filename
        assert "outer_rounding_1.0" in filename
        assert "hanger_tolerance_0.3" in filename
