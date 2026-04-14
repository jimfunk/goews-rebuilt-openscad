"""Tests for server.parts.rack module."""

import pytest
from pydantic import ValidationError
from server.parts.rack import RackDefinition, make_rack_filename
from server.enums import Variant


class TestRackDefinition:
    """Tests for RackDefinition model."""

    def test_default_values(self):
        """Test that default values are set correctly."""
        body = RackDefinition()
        assert body.slots == 7
        assert body.slot_width == 6
        assert body.divider_width == 10
        assert body.divider_length == 80
        assert body.divider_thickness == 6
        assert body.lip is False
        assert body.lip_height == 8
        assert body.lip_thickness == 4
        assert body.rounding == 0.5
        assert body.hanger_tolerance == 0.15
        assert body.variant == Variant.ORIGINAL

    def test_validation_slots_gt_zero(self):
        """Test that slots must be greater than zero."""
        with pytest.raises(ValidationError):
            RackDefinition(slots=0)

    def test_validation_slot_width_gt_zero(self):
        """Test that slot_width must be greater than zero."""
        with pytest.raises(ValidationError):
            RackDefinition(slot_width=0)

    def test_validation_divider_width_gt_zero(self):
        """Test that divider_width must be greater than zero."""
        with pytest.raises(ValidationError):
            RackDefinition(divider_width=0)

    def test_validation_divider_length_gt_zero(self):
        """Test that divider_length must be greater than zero."""
        with pytest.raises(ValidationError):
            RackDefinition(divider_length=0)

    def test_validation_divider_thickness_gt_zero(self):
        """Test that divider_thickness must be greater than zero."""
        with pytest.raises(ValidationError):
            RackDefinition(divider_thickness=0)

    def test_validation_hanger_tolerance_ge_zero(self):
        """Test that hanger_tolerance must be greater than or equal to zero."""
        with pytest.raises(ValidationError):
            RackDefinition(hanger_tolerance=-0.1)


class TestMakeRackFilename:
    """Tests for make_rack_filename function."""

    def test_default_rack(self):
        """Test filename for default rack."""
        body = RackDefinition()
        assert make_rack_filename(body) == "rack-7slot-original.stl"

    def test_custom_slots(self):
        """Test filename with custom slots."""
        body = RackDefinition(slots=10)
        assert make_rack_filename(body) == "rack-10slot-original.stl"

    def test_thicker_cleats_variant(self):
        """Test filename with thicker cleats variant."""
        body = RackDefinition(variant=Variant.THICKER_CLEATS)
        assert make_rack_filename(body) == "rack-7slot-thicker_cleats.stl"

    def test_custom_slot_width(self):
        """Test filename with custom slot width."""
        body = RackDefinition(slot_width=8)
        assert make_rack_filename(body) == "rack-7slot-original-slot_width_8.0.stl"

    def test_custom_divider_width(self):
        """Test filename with custom divider width."""
        body = RackDefinition(divider_width=15)
        assert make_rack_filename(body) == "rack-7slot-original-divider_width_15.0.stl"

    def test_custom_divider_length(self):
        """Test filename with custom divider length."""
        body = RackDefinition(divider_length=100)
        assert make_rack_filename(body) == "rack-7slot-original-divider_length_100.0.stl"

    def test_custom_divider_thickness(self):
        """Test filename with custom divider thickness."""
        body = RackDefinition(divider_thickness=8)
        assert make_rack_filename(body) == "rack-7slot-original-divider_thickness_8.0.stl"

    def test_with_lip(self):
        """Test filename with lip enabled."""
        body = RackDefinition(lip=True)
        assert make_rack_filename(body) == "rack-7slot-original-lip.stl"

    def test_custom_lip_height(self):
        """Test filename with custom lip height."""
        body = RackDefinition(lip_height=10)
        assert make_rack_filename(body) == "rack-7slot-original-lip_height_10.0.stl"

    def test_custom_lip_thickness(self):
        """Test filename with custom lip thickness."""
        body = RackDefinition(lip_thickness=5)
        assert make_rack_filename(body) == "rack-7slot-original-lip_thickness_5.0.stl"

    def test_custom_rounding(self):
        """Test filename with custom rounding."""
        body = RackDefinition(rounding=1)
        assert make_rack_filename(body) == "rack-7slot-original-rounding_1.0.stl"

    def test_custom_hanger_tolerance(self):
        """Test filename with custom hanger tolerance."""
        body = RackDefinition(hanger_tolerance=0.2)
        assert make_rack_filename(body) == "rack-7slot-original-hanger_tolerance_0.2.stl"
