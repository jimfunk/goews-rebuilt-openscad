"""Tests for server.parts.cableclip module."""

import pytest
from pydantic import ValidationError
from server.parts.cableclip import CableclipDefinition, make_cableclip_filename, CableClipOrientation
from server.enums import Variant


class TestCableClipOrientation:
    """Tests for CableClipOrientation enum."""

    def test_vertical_to_int(self):
        """Test VERTICAL to_int conversion."""
        assert CableClipOrientation.VERTICAL.to_int() == 1

    def test_horizontal_left_to_int(self):
        """Test HORIZONTAL_LEFT to_int conversion."""
        assert CableClipOrientation.HORIZONTAL_LEFT.to_int() == 2

    def test_horizontal_right_to_int(self):
        """Test HORIZONTAL_RIGHT to_int conversion."""
        assert CableClipOrientation.HORIZONTAL_RIGHT.to_int() == 3


class TestCableclipDefinition:
    """Tests for CableclipDefinition model."""

    def test_default_values(self):
        """Test that default values are set correctly."""
        body = CableclipDefinition()
        assert body.orientation == CableClipOrientation.VERTICAL
        assert body.clips == 1
        assert body.cable_diameter == 5
        assert body.width == 6
        assert body.height == 8
        assert body.thickness == 3
        assert body.gap == 10
        assert body.lip_thickness == 2
        assert body.rounding == 0.5
        assert body.hanger_tolerance == 0.15
        assert body.variant == Variant.ORIGINAL

    def test_custom_values(self):
        """Test that custom values are set correctly."""
        body = CableclipDefinition(
            orientation=CableClipOrientation.HORIZONTAL_LEFT,
            clips=3,
            cable_diameter=8,
            width=8,
            height=10,
            thickness=4,
            gap=15,
            lip_thickness=3,
            rounding=1,
            hanger_tolerance=0.2,
            variant=Variant.THICKER_CLEATS,
        )
        assert body.orientation == CableClipOrientation.HORIZONTAL_LEFT
        assert body.clips == 3
        assert body.cable_diameter == 8
        assert body.width == 8
        assert body.height == 10
        assert body.thickness == 4
        assert body.gap == 15
        assert body.lip_thickness == 3
        assert body.rounding == 1
        assert body.hanger_tolerance == 0.2
        assert body.variant == Variant.THICKER_CLEATS

    def test_validation_clips_gt_zero(self):
        """Test that clips must be greater than zero."""
        with pytest.raises(ValidationError):
            CableclipDefinition(clips=0)

    def test_validation_cable_diameter_gt_zero(self):
        """Test that cable_diameter must be greater than zero."""
        with pytest.raises(ValidationError):
            CableclipDefinition(cable_diameter=0)

    def test_validation_width_gt_zero(self):
        """Test that width must be greater than zero."""
        with pytest.raises(ValidationError):
            CableclipDefinition(width=0)

    def test_validation_height_gt_zero(self):
        """Test that height must be greater than zero."""
        with pytest.raises(ValidationError):
            CableclipDefinition(height=0)

    def test_validation_thickness_gt_zero(self):
        """Test that thickness must be greater than zero."""
        with pytest.raises(ValidationError):
            CableclipDefinition(thickness=0)

    def test_validation_gap_gt_zero(self):
        """Test that gap must be greater than zero."""
        with pytest.raises(ValidationError):
            CableclipDefinition(gap=0)

    def test_validation_hanger_tolerance_ge_zero(self):
        """Test that hanger_tolerance must be greater than or equal to zero."""
        with pytest.raises(ValidationError):
            CableclipDefinition(hanger_tolerance=-0.1)


class TestMakeCableclipFilename:
    """Tests for make_cableclip_filename function."""

    def test_default_cableclip(self):
        """Test filename for default cableclip."""
        body = CableclipDefinition()
        assert make_cableclip_filename(body) == "cableclip-5mm-original.stl"

    def test_custom_diameter(self):
        """Test filename with custom cable diameter."""
        body = CableclipDefinition(cable_diameter=8)
        assert make_cableclip_filename(body) == "cableclip-8mm-original.stl"

    def test_thicker_cleats_variant(self):
        """Test filename with thicker cleats variant."""
        body = CableclipDefinition(variant=Variant.THICKER_CLEATS)
        assert make_cableclip_filename(body) == "cableclip-5mm-thicker_cleats.stl"

    def test_horizontal_left_orientation(self):
        """Test filename with horizontal left orientation."""
        body = CableclipDefinition(orientation=CableClipOrientation.HORIZONTAL_LEFT)
        filename = make_cableclip_filename(body)
        assert "orientation" in filename

    def test_horizontal_right_orientation(self):
        """Test filename with horizontal right orientation."""
        body = CableclipDefinition(orientation=CableClipOrientation.HORIZONTAL_RIGHT)
        filename = make_cableclip_filename(body)
        assert "orientation" in filename

    def test_multiple_clips(self):
        """Test filename with multiple clips."""
        body = CableclipDefinition(clips=3)
        assert make_cableclip_filename(body) == "cableclip-5mm-original-clips_3.stl"

    def test_custom_width(self):
        """Test filename with custom width."""
        body = CableclipDefinition(width=8)
        assert make_cableclip_filename(body) == "cableclip-5mm-original-width_8.0.stl"

    def test_custom_height(self):
        """Test filename with custom height."""
        body = CableclipDefinition(height=10)
        assert make_cableclip_filename(body) == "cableclip-5mm-original-height_10.0.stl"

    def test_custom_thickness(self):
        """Test filename with custom thickness."""
        body = CableclipDefinition(thickness=4)
        assert make_cableclip_filename(body) == "cableclip-5mm-original-thickness_4.0.stl"

    def test_custom_gap(self):
        """Test filename with custom gap."""
        body = CableclipDefinition(gap=15)
        assert make_cableclip_filename(body) == "cableclip-5mm-original-gap_15.0.stl"

    def test_custom_lip_thickness(self):
        """Test filename with custom lip thickness."""
        body = CableclipDefinition(lip_thickness=3)
        assert make_cableclip_filename(body) == "cableclip-5mm-original-lip_thickness_3.0.stl"

    def test_custom_rounding(self):
        """Test filename with custom rounding."""
        body = CableclipDefinition(rounding=1)
        assert make_cableclip_filename(body) == "cableclip-5mm-original-rounding_1.0.stl"

    def test_custom_hanger_tolerance(self):
        """Test filename with custom hanger tolerance."""
        body = CableclipDefinition(hanger_tolerance=0.2)
        assert make_cableclip_filename(body) == "cableclip-5mm-original-hanger_tolerance_0.2.stl"
