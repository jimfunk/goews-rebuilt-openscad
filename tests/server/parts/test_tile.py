"""Tests for server.parts.tile module."""

import pytest
from pydantic import ValidationError
from server.parts.tile import TileDefinition, make_tile_filename, GridTileDefinition, make_grid_tile_filename
from server.enums import Variant


class TestTileDefinition:
    """Tests for TileDefinition model."""

    def test_default_values(self):
        """Test that default values are set correctly."""
        body = TileDefinition()
        assert body.columns == 4
        assert body.rows == 4
        assert body.fill_top is False
        assert body.fill_bottom is False
        assert body.fill_left is False
        assert body.fill_right is False
        assert body.reverse_stagger is False
        assert body.exact_width is False
        assert body.mounting_hole_shank_diameter == 4
        assert body.mounting_hole_head_diameter == 8
        assert body.mounting_hole_inset_depth == 1
        assert body.mounting_hole_countersink_depth == 2
        assert body.skip_list == []
        assert body.variant == Variant.ORIGINAL

    def test_custom_values(self):
        """Test that custom values are set correctly."""
        body = TileDefinition(
            columns=3,
            rows=5,
            fill_top=True,
            fill_bottom=True,
            fill_left=True,
            fill_right=True,
            reverse_stagger=True,
            exact_width=True,
            mounting_hole_shank_diameter=5,
            mounting_hole_head_diameter=10,
            mounting_hole_inset_depth=2,
            mounting_hole_countersink_depth=0,
            skip_list=[[1, 1], [2, 2]],
            variant=Variant.THICKER_CLEATS,
        )
        assert body.columns == 3
        assert body.rows == 5
        assert body.fill_top is True
        assert body.fill_bottom is True
        assert body.fill_left is True
        assert body.fill_right is True
        assert body.reverse_stagger is True
        assert body.exact_width is True
        assert body.mounting_hole_shank_diameter == 5
        assert body.mounting_hole_head_diameter == 10
        assert body.mounting_hole_inset_depth == 2
        assert body.mounting_hole_countersink_depth == 0
        assert body.skip_list == [[1, 1], [2, 2]]
        assert body.variant == Variant.THICKER_CLEATS

    def test_validation_columns_gt_zero(self):
        """Test that columns must be greater than zero."""
        with pytest.raises(ValidationError):
            TileDefinition(columns=0)

    def test_validation_rows_gt_zero(self):
        """Test that rows must be greater than zero."""
        with pytest.raises(ValidationError):
            TileDefinition(rows=0)

    def test_validation_skip_list_coordinate_length(self):
        """Test that skip list coordinates must have length 2."""
        with pytest.raises(ValidationError, match="Skip list must be a list of"):
            TileDefinition(skip_list=[[1, 2, 3]])

    def test_validation_skip_list_coordinate_types(self):
        """Test that skip list coordinates must be integers."""
        with pytest.raises(ValidationError):
            TileDefinition(skip_list=[[1.5, 2]])

    def test_validation_skip_list_positive(self):
        """Test that skip list coordinates must be positive."""
        with pytest.raises(ValidationError, match="Skip list rows and columns must be greater"):
            TileDefinition(skip_list=[[0, 1]])
        
        with pytest.raises(ValidationError, match="Skip list rows and columns must be greater"):
            TileDefinition(skip_list=[[-1, 1]])


class TestMakeTileFilename:
    """Tests for make_tile_filename function."""

    def test_default_tile(self):
        """Test filename for default tile."""
        body = TileDefinition()
        assert make_tile_filename(body) == "tile-4x4-original.stl"

    def test_custom_dimensions(self):
        """Test filename with custom dimensions."""
        body = TileDefinition(columns=3, rows=5)
        assert make_tile_filename(body) == "tile-3x5-original.stl"

    def test_thicker_cleats_variant(self):
        """Test filename with thicker cleats variant."""
        body = TileDefinition(variant=Variant.THICKER_CLEATS)
        assert make_tile_filename(body) == "tile-4x4-thicker_cleats.stl"

    def test_fill_top(self):
        """Test filename with fill_top option."""
        body = TileDefinition(fill_top=True)
        assert make_tile_filename(body) == "tile-4x4-original-fill_top.stl"

    def test_fill_bottom(self):
        """Test filename with fill_bottom option."""
        body = TileDefinition(fill_bottom=True)
        assert make_tile_filename(body) == "tile-4x4-original-fill_bottom.stl"

    def test_fill_left(self):
        """Test filename with fill_left option."""
        body = TileDefinition(fill_left=True)
        assert make_tile_filename(body) == "tile-4x4-original-fill_left.stl"

    def test_fill_right(self):
        """Test filename with fill_right option."""
        body = TileDefinition(fill_right=True)
        assert make_tile_filename(body) == "tile-4x4-original-fill_right.stl"

    def test_multiple_fills(self):
        """Test filename with multiple fill options."""
        body = TileDefinition(fill_top=True, fill_bottom=True)
        filename = make_tile_filename(body)
        assert "fill_top" in filename
        assert "fill_bottom" in filename

    def test_reverse_stagger(self):
        """Test filename with reverse_stagger option."""
        body = TileDefinition(reverse_stagger=True)
        assert make_tile_filename(body) == "tile-4x4-original-reverse_stagger.stl"

    def test_exact_width(self):
        """Test filename with exact_width option."""
        body = TileDefinition(exact_width=True)
        assert make_tile_filename(body) == "tile-4x4-original-exact_width.stl"

    def test_custom_mounting_hole_shank_diameter(self):
        """Test filename with custom shank diameter."""
        body = TileDefinition(mounting_hole_shank_diameter=5)
        assert make_tile_filename(body) == "tile-4x4-original-mounting_hole_shank_diameter_5.0.stl"

    def test_custom_mounting_hole_head_diameter(self):
        """Test filename with custom head diameter."""
        body = TileDefinition(mounting_hole_head_diameter=10)
        assert make_tile_filename(body) == "tile-4x4-original-mounting_hole_head_diameter_10.0.stl"

    def test_custom_mounting_hole_inset_depth(self):
        """Test filename with custom inset depth."""
        body = TileDefinition(mounting_hole_inset_depth=2)
        assert make_tile_filename(body) == "tile-4x4-original-mounting_hole_inset_depth_2.0.stl"

    def test_custom_mounting_hole_countersink_depth(self):
        """Test filename with custom countersink depth."""
        body = TileDefinition(mounting_hole_countersink_depth=0)
        assert make_tile_filename(body) == "tile-4x4-original-mounting_hole_countersink_depth_0.0.stl"

    def test_complex_filename(self):
        """Test filename with multiple non-default options."""
        body = TileDefinition(
            columns=3,
            rows=5,
            fill_top=True,
            fill_bottom=True,
            reverse_stagger=True,
            variant=Variant.THICKER_CLEATS,
        )
        filename = make_tile_filename(body)
        assert filename.startswith("tile-3x5-thicker_cleats-")
        assert "fill_top" in filename
        assert "fill_bottom" in filename
        assert "reverse_stagger" in filename


class TestGridTileDefinition:
    """Tests for GridTileDefinition model."""

    def test_default_values(self):
        """Test that default values are set correctly."""
        body = GridTileDefinition()
        assert body.columns == 4
        assert body.rows == 4
        assert body.mounting_hole_shank_diameter == 4
        assert body.mounting_hole_head_diameter == 8
        assert body.mounting_hole_inset_depth == 1
        assert body.mounting_hole_countersink_depth == 2
        assert body.skip_list == []
        assert body.variant == Variant.ORIGINAL

    def test_validation_columns_gt_zero(self):
        """Test that columns must be greater than zero."""
        with pytest.raises(ValidationError):
            GridTileDefinition(columns=0)

    def test_validation_rows_gt_zero(self):
        """Test that rows must be greater than zero."""
        with pytest.raises(ValidationError):
            GridTileDefinition(rows=0)

    def test_validation_skip_list(self):
        """Test skip list validation."""
        with pytest.raises(ValidationError):
            GridTileDefinition(skip_list=[[1, 2, 3]])


class TestMakeGridTileFilename:
    """Tests for make_grid_tile_filename function."""

    def test_default_grid_tile(self):
        """Test filename for default grid tile."""
        body = GridTileDefinition()
        assert make_grid_tile_filename(body) == "grid-tile-4x4-original.stl"

    def test_custom_dimensions(self):
        """Test filename with custom dimensions."""
        body = GridTileDefinition(columns=2, rows=3)
        assert make_grid_tile_filename(body) == "grid-tile-2x3-original.stl"

    def test_thicker_cleats_variant(self):
        """Test filename with thicker cleats variant."""
        body = GridTileDefinition(variant=Variant.THICKER_CLEATS)
        assert make_grid_tile_filename(body) == "grid-tile-4x4-thicker_cleats.stl"

    def test_custom_mounting_hole_shank_diameter(self):
        """Test filename with custom shank diameter."""
        body = GridTileDefinition(mounting_hole_shank_diameter=5)
        assert make_grid_tile_filename(body) == "grid-tile-4x4-original-mounting_hole_shank_diameter_5.0.stl"

    def test_custom_mounting_hole_head_diameter(self):
        """Test filename with custom head diameter."""
        body = GridTileDefinition(mounting_hole_head_diameter=10)
        assert make_grid_tile_filename(body) == "grid-tile-4x4-original-mounting_hole_head_diameter_10.0.stl"

    def test_custom_mounting_hole_inset_depth(self):
        """Test filename with custom inset depth."""
        body = GridTileDefinition(mounting_hole_inset_depth=2)
        assert make_grid_tile_filename(body) == "grid-tile-4x4-original-mounting_hole_inset_depth_2.0.stl"

    def test_custom_mounting_hole_countersink_depth(self):
        """Test filename with custom countersink depth."""
        body = GridTileDefinition(mounting_hole_countersink_depth=0)
        assert make_grid_tile_filename(body) == "grid-tile-4x4-original-mounting_hole_countersink_depth_0.0.stl"
