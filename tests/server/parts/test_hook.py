"""Tests for server.parts.hook module."""

import pytest
from pydantic import ValidationError
from server.parts.hook import HookDefinition, make_hook_filename
from server.enums import Variant


class TestHookDefinition:
    """Tests for HookDefinition model."""

    def test_default_values(self):
        """Test that default values are set correctly."""
        body = HookDefinition()
        assert body.hooks == 1
        assert body.width == 10
        assert body.gap == 10
        assert body.shank_length == 10
        assert body.shank_thickness == 8
        assert body.post_height == 18
        assert body.post_thickness == 6
        assert body.lip_thickness == 0
        assert body.rounding == 0.5
        assert body.hanger_tolerance == 0.15
        assert body.variant == Variant.ORIGINAL

    def test_validation_hooks_gt_zero(self):
        """Test that hooks must be greater than zero."""
        with pytest.raises(ValidationError):
            HookDefinition(hooks=0)

    def test_validation_width_gt_zero(self):
        """Test that width must be greater than zero."""
        with pytest.raises(ValidationError):
            HookDefinition(width=0)

    def test_validation_gap_gt_zero(self):
        """Test that gap must be greater than zero."""
        with pytest.raises(ValidationError):
            HookDefinition(gap=0)

    def test_validation_shank_length_gt_zero(self):
        """Test that shank_length must be greater than zero."""
        with pytest.raises(ValidationError):
            HookDefinition(shank_length=0)

    def test_validation_shank_thickness_gt_zero(self):
        """Test that shank_thickness must be greater than zero."""
        with pytest.raises(ValidationError):
            HookDefinition(shank_thickness=0)

    def test_validation_hanger_tolerance_ge_zero(self):
        """Test that hanger_tolerance must be greater than or equal to zero."""
        with pytest.raises(ValidationError):
            HookDefinition(hanger_tolerance=-0.1)


class TestMakeHookFilename:
    """Tests for make_hook_filename function."""

    def test_default_hook(self):
        """Test filename for default hook."""
        body = HookDefinition()
        assert make_hook_filename(body) == "hook-10x10-original.stl"

    def test_custom_dimensions(self):
        """Test filename with custom dimensions."""
        body = HookDefinition(width=20, shank_length=15)
        assert make_hook_filename(body) == "hook-20x15-original.stl"

    def test_thicker_cleats_variant(self):
        """Test filename with thicker cleats variant."""
        body = HookDefinition(variant=Variant.THICKER_CLEATS)
        assert make_hook_filename(body) == "hook-10x10-thicker_cleats.stl"

    def test_multiple_hooks(self):
        """Test filename with multiple hooks."""
        body = HookDefinition(hooks=3)
        assert make_hook_filename(body) == "hook-10x10-original-hooks_3.stl"

    def test_custom_gap(self):
        """Test filename with custom gap."""
        body = HookDefinition(gap=15)
        assert make_hook_filename(body) == "hook-10x10-original-gap_15.0.stl"

    def test_custom_shank_thickness(self):
        """Test filename with custom shank thickness."""
        body = HookDefinition(shank_thickness=10)
        assert make_hook_filename(body) == "hook-10x10-original-shank_thickness_10.0.stl"

    def test_custom_post_height(self):
        """Test filename with custom post height."""
        body = HookDefinition(post_height=25)
        assert make_hook_filename(body) == "hook-10x10-original-post_height_25.0.stl"

    def test_custom_post_thickness(self):
        """Test filename with custom post thickness."""
        body = HookDefinition(post_thickness=8)
        assert make_hook_filename(body) == "hook-10x10-original-post_thickness_8.0.stl"

    def test_with_lip(self):
        """Test filename with lip."""
        body = HookDefinition(lip_thickness=2)
        assert make_hook_filename(body) == "hook-10x10-original-lip_thickness_2.0.stl"

    def test_custom_rounding(self):
        """Test filename with custom rounding."""
        body = HookDefinition(rounding=1)
        assert make_hook_filename(body) == "hook-10x10-original-rounding_1.0.stl"

    def test_custom_hanger_tolerance(self):
        """Test filename with custom hanger tolerance."""
        body = HookDefinition(hanger_tolerance=0.2)
        assert make_hook_filename(body) == "hook-10x10-original-hanger_tolerance_0.2.stl"
