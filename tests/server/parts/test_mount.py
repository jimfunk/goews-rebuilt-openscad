"""Tests for server.parts.mount module."""

import pytest
from pydantic import ValidationError
from server.parts.mount import MountDefinition, MountHole, MountHoleType, make_mount_filename
from server.enums import Variant


class TestMountHoleType:
    """Tests for MountHoleType enum."""

    def test_round_to_int(self):
        """Test ROUND to_int conversion."""
        assert MountHoleType.ROUND.to_int() == 1

    def test_hex_to_int(self):
        """Test HEX to_int conversion."""
        assert MountHoleType.HEX.to_int() == 2

    def test_square_to_int(self):
        """Test SQUARE to_int conversion."""
        assert MountHoleType.SQUARE.to_int() == 3

    def test_socket_head_to_int(self):
        """Test SOCKET_HEAD to_int conversion."""
        assert MountHoleType.SOCKET_HEAD.to_int() == 4

    def test_button_head_to_int(self):
        """Test BUTTON_HEAD to_int conversion."""
        assert MountHoleType.BUTTON_HEAD.to_int() == 5

    def test_countersink_head_to_int(self):
        """Test COUNTERSINK_HEAD to_int conversion."""
        assert MountHoleType.COUNTERSINK_HEAD.to_int() == 6


class TestMountHole:
    """Tests for MountHole model."""

    def test_as_list(self):
        """Test as_list method."""
        hole = MountHole(
            hole_type=MountHoleType.ROUND,
            x_offset=10,
            y_offset=15,
            diameter=4,
            depth=5,
        )
        assert hole.as_list() == [1, 10, 15, 4, 5]

    def test_validation_x_offset_gt_zero(self):
        """Test that x_offset must be greater than zero."""
        with pytest.raises(ValidationError):
            MountHole(hole_type=MountHoleType.ROUND, x_offset=0, y_offset=10, diameter=4, depth=5)

    def test_validation_y_offset_gt_zero(self):
        """Test that y_offset must be greater than zero."""
        with pytest.raises(ValidationError):
            MountHole(hole_type=MountHoleType.ROUND, x_offset=10, y_offset=0, diameter=4, depth=5)

    def test_validation_diameter_gt_zero(self):
        """Test that diameter must be greater than zero."""
        with pytest.raises(ValidationError):
            MountHole(hole_type=MountHoleType.ROUND, x_offset=10, y_offset=10, diameter=0, depth=5)

    def test_validation_depth_gt_zero(self):
        """Test that depth must be greater than zero."""
        with pytest.raises(ValidationError):
            MountHole(hole_type=MountHoleType.ROUND, x_offset=10, y_offset=10, diameter=4, depth=0)


class TestMountDefinition:
    """Tests for MountDefinition model."""

    def test_default_values(self):
        """Test that default values are set correctly."""
        body = MountDefinition(
            holes=[MountHole(hole_type=MountHoleType.ROUND, x_offset=10, y_offset=10, diameter=4, depth=5)]
        )
        assert len(body.holes) == 1
        assert body.plate_thickness == 3
        assert body.minimum_width == 0
        assert body.minimum_height == 0
        assert body.bolt_notch is True
        assert body.hanger_tolerance == 0.15
        assert body.variant == Variant.ORIGINAL

    def test_validation_plate_thickness_gt_zero(self):
        """Test that plate_thickness must be greater than zero."""
        with pytest.raises(ValidationError):
            MountDefinition(
                holes=[MountHole(hole_type=MountHoleType.ROUND, x_offset=10, y_offset=10, diameter=4, depth=5)],
                plate_thickness=0,
            )

    def test_validation_minimum_width_ge_zero(self):
        """Test that minimum_width must be greater than or equal to zero."""
        with pytest.raises(ValidationError):
            MountDefinition(
                holes=[MountHole(hole_type=MountHoleType.ROUND, x_offset=10, y_offset=10, diameter=4, depth=5)],
                minimum_width=-1,
            )

    def test_validation_minimum_height_ge_zero(self):
        """Test that minimum_height must be greater than or equal to zero."""
        with pytest.raises(ValidationError):
            MountDefinition(
                holes=[MountHole(hole_type=MountHoleType.ROUND, x_offset=10, y_offset=10, diameter=4, depth=5)],
                minimum_height=-1,
            )

    def test_validation_hanger_tolerance_ge_zero(self):
        """Test that hanger_tolerance must be greater than or equal to zero."""
        with pytest.raises(ValidationError):
            MountDefinition(
                holes=[MountHole(hole_type=MountHoleType.ROUND, x_offset=10, y_offset=10, diameter=4, depth=5)],
                hanger_tolerance=-0.1,
            )


class TestMakeMountFilename:
    """Tests for make_mount_filename function."""

    def test_single_hole_mount(self):
        """Test filename for single hole mount."""
        body = MountDefinition(
            holes=[MountHole(hole_type=MountHoleType.ROUND, x_offset=10, y_offset=10, diameter=4, depth=5)]
        )
        assert make_mount_filename(body) == "mount-1hole-original.stl"

    def test_dual_hole_mount(self):
        """Test filename for dual hole mount."""
        body = MountDefinition(
            holes=[
                MountHole(hole_type=MountHoleType.ROUND, x_offset=10, y_offset=10, diameter=4, depth=5),
                MountHole(hole_type=MountHoleType.ROUND, x_offset=20, y_offset=20, diameter=4, depth=5),
            ]
        )
        assert make_mount_filename(body) == "mount-2hole-original.stl"

    def test_triple_hole_mount(self):
        """Test filename for triple hole mount."""
        body = MountDefinition(
            holes=[
                MountHole(hole_type=MountHoleType.ROUND, x_offset=10, y_offset=10, diameter=4, depth=5),
                MountHole(hole_type=MountHoleType.ROUND, x_offset=20, y_offset=20, diameter=4, depth=5),
                MountHole(hole_type=MountHoleType.ROUND, x_offset=30, y_offset=30, diameter=4, depth=5),
            ]
        )
        assert make_mount_filename(body) == "mount-3hole-original.stl"

    def test_custom_hole_count(self):
        """Test filename for custom hole count."""
        holes = [
            MountHole(hole_type=MountHoleType.ROUND, x_offset=10*i, y_offset=10*i, diameter=4, depth=5)
            for i in range(1, 6)
        ]
        body = MountDefinition(holes=holes)
        assert make_mount_filename(body) == "mount-5hole-original.stl"

    def test_thicker_cleats_variant(self):
        """Test filename with thicker cleats variant."""
        body = MountDefinition(
            holes=[MountHole(hole_type=MountHoleType.ROUND, x_offset=10, y_offset=10, diameter=4, depth=5)],
            variant=Variant.THICKER_CLEATS,
        )
        assert make_mount_filename(body) == "mount-1hole-thicker_cleats.stl"

    def test_custom_plate_thickness(self):
        """Test filename with custom plate thickness."""
        body = MountDefinition(
            holes=[MountHole(hole_type=MountHoleType.ROUND, x_offset=10, y_offset=10, diameter=4, depth=5)],
            plate_thickness=5,
        )
        assert make_mount_filename(body) == "mount-1hole-original-plate_thickness_5.0.stl"

    def test_custom_minimum_width(self):
        """Test filename with custom minimum width."""
        body = MountDefinition(
            holes=[MountHole(hole_type=MountHoleType.ROUND, x_offset=10, y_offset=10, diameter=4, depth=5)],
            minimum_width=50,
        )
        assert make_mount_filename(body) == "mount-1hole-original-minimum_width_50.0.stl"

    def test_custom_minimum_height(self):
        """Test filename with custom minimum height."""
        body = MountDefinition(
            holes=[MountHole(hole_type=MountHoleType.ROUND, x_offset=10, y_offset=10, diameter=4, depth=5)],
            minimum_height=30,
        )
        assert make_mount_filename(body) == "mount-1hole-original-minimum_height_30.0.stl"

    def test_bolt_notch_false(self):
        """Test filename with bolt_notch disabled."""
        body = MountDefinition(
            holes=[MountHole(hole_type=MountHoleType.ROUND, x_offset=10, y_offset=10, diameter=4, depth=5)],
            bolt_notch=False,
        )
        assert make_mount_filename(body) == "mount-1hole-original-no_bolt_notch.stl"

    def test_custom_hanger_tolerance(self):
        """Test filename with custom hanger tolerance."""
        body = MountDefinition(
            holes=[MountHole(hole_type=MountHoleType.ROUND, x_offset=10, y_offset=10, diameter=4, depth=5)],
            hanger_tolerance=0.2,
        )
        assert make_mount_filename(body) == "mount-1hole-original-hanger_tolerance_0.2.stl"
