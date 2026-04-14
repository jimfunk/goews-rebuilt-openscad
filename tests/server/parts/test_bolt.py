"""Tests for server.parts.bolt module."""

import pytest
from pydantic import ValidationError
from server.parts.bolt import BoltDefinition, make_bolt_filename, HeadType, HeadRecessType


class TestHeadType:
    """Tests for HeadType enum."""

    def test_original_to_int(self):
        """Test ORIGINAL to_int conversion."""
        assert HeadType.ORIGINAL.to_int() == 0

    def test_round_to_int(self):
        """Test ROUND to_int conversion."""
        assert HeadType.ROUND.to_int() == 1


class TestHeadRecessType:
    """Tests for HeadRecessType enum."""

    def test_hex_to_int(self):
        """Test HEX to_int conversion."""
        assert HeadRecessType.HEX.to_int() == 0

    def test_slot_to_int(self):
        """Test SLOT to_int conversion."""
        assert HeadRecessType.SLOT.to_int() == 1

    def test_philips2_to_int(self):
        """Test PHILIPS2 to_int conversion."""
        assert HeadRecessType.PHILIPS2.to_int() == 2

    def test_philips3_to_int(self):
        """Test PHILIPS3 to_int conversion."""
        assert HeadRecessType.PHILIPS3.to_int() == 3


class TestBoltDefinition:
    """Tests for BoltDefinition model."""

    def test_default_values(self):
        """Test that default values are set correctly."""
        body = BoltDefinition()
        assert body.length == 9
        assert body.head_type == HeadType.ORIGINAL
        assert body.head_recess_type == HeadRecessType.HEX
        assert body.head_recess_depth == 0
        assert body.hex_socket_width == 8.4
        assert body.slot_recess_width == 2
        assert body.slot_recess_length == 10

    def test_custom_values(self):
        """Test that custom values are set correctly."""
        body = BoltDefinition(
            length=16,
            head_type=HeadType.ROUND,
            head_recess_type=HeadRecessType.SLOT,
            head_recess_depth=1,
            hex_socket_width=10,
            slot_recess_width=3,
            slot_recess_length=15,
        )
        assert body.length == 16
        assert body.head_type == HeadType.ROUND
        assert body.head_recess_type == HeadRecessType.SLOT
        assert body.head_recess_depth == 1
        assert body.hex_socket_width == 10
        assert body.slot_recess_width == 3
        assert body.slot_recess_length == 15

    def test_validation_length_gt_zero(self):
        """Test that length must be greater than zero."""
        with pytest.raises(ValidationError):
            BoltDefinition(length=0)

    def test_validation_head_recess_depth_ge_zero(self):
        """Test that head_recess_depth must be greater than or equal to zero."""
        with pytest.raises(ValidationError):
            BoltDefinition(head_recess_depth=-1)

    def test_validation_hex_socket_width_gt_zero(self):
        """Test that hex_socket_width must be greater than zero."""
        with pytest.raises(ValidationError):
            BoltDefinition(hex_socket_width=0)

    def test_validation_slot_recess_width_gt_zero(self):
        """Test that slot_recess_width must be greater than zero."""
        with pytest.raises(ValidationError):
            BoltDefinition(slot_recess_width=0)

    def test_validation_slot_recess_length_gt_zero(self):
        """Test that slot_recess_length must be greater than zero."""
        with pytest.raises(ValidationError):
            BoltDefinition(slot_recess_length=0)


class TestMakeBoltFilename:
    """Tests for make_bolt_filename function."""

    def test_default_bolt(self):
        """Test filename for default bolt."""
        body = BoltDefinition()
        assert make_bolt_filename(body) == "bolt-9.stl"

    def test_custom_length(self):
        """Test filename with custom length."""
        body = BoltDefinition(length=16)
        assert make_bolt_filename(body) == "bolt-16.stl"

    def test_custom_head_type(self):
        """Test filename with custom head type."""
        body = BoltDefinition(head_type=HeadType.ROUND)
        filename = make_bolt_filename(body)
        assert filename.startswith("bolt-9-")
        assert "head_type" in filename

    def test_custom_head_recess_type(self):
        """Test filename with custom head recess type."""
        body = BoltDefinition(head_recess_type=HeadRecessType.SLOT)
        filename = make_bolt_filename(body)
        assert "head_recess_type" in filename

    def test_custom_head_recess_depth(self):
        """Test filename with custom head recess depth."""
        body = BoltDefinition(head_recess_depth=1)
        assert make_bolt_filename(body) == "bolt-9-head_recess_depth_1.0.stl"

    def test_custom_hex_socket_width(self):
        """Test filename with custom hex socket width."""
        body = BoltDefinition(hex_socket_width=10)
        assert make_bolt_filename(body) == "bolt-9-hex_socket_width_10.0.stl"

    def test_custom_slot_recess_width(self):
        """Test filename with custom slot recess width."""
        body = BoltDefinition(slot_recess_width=3)
        assert make_bolt_filename(body) == "bolt-9-slot_recess_width_3.0.stl"

    def test_custom_slot_recess_length(self):
        """Test filename with custom slot recess length."""
        body = BoltDefinition(slot_recess_length=15)
        assert make_bolt_filename(body) == "bolt-9-slot_recess_length_15.0.stl"
