// stacked_goews_tiles.scad
//
// Export twice:
//
//   openscad -o goews-stack-pla.stl  -D 'part="pla"'  stacked_goews_tiles.scad
//   openscad -o goews-stack-petg.stl -D 'part="petg"' stacked_goews_tiles.scad
//
// Then import both STLs into Orca as one multi-part object.
// Assign PLA to goews-stack-pla.stl and PETG to goews-stack-petg.stl.
//
// In Orca:
//   - Enable multimaterial / multiple filaments
//   - Assign PLA to tiles + supports
//   - Assign PETG to separators + tabs
//   - Enable "Interface Shells"
//   - Do not use interlocking beams for this

include <constants.scad>
include <BOSL2/std.scad>
include <BOSL2/lists.scad>
include <BOSL2/threading.scad>

use <tile.scad>
use <grid_tile.scad>

/* [Stack] */

// "hex" or "grid". Hex is the primary path here.
tile_kind = "hex";

// "pla", "petg", or "all" for preview
part = "all";

// Number of actual GOEWS tiles in the stack
stack_count = 3;

// PETG separator thickness.
// Try 0.2 for one layer, 0.4 for two layers.
spacer_h = 0.2;

// Shrink the separator slightly so it does not poke past the plate edge/chamfer.
spacer_xy_delta = -0.20;

// "hex_cells" is fast and recommended for hex GOEWS plates.
// "projection_close" is slower, but useful if you use GOEWS fill_top/fill_bottom/etc.
separator_mode = "hex_cells";

// Used only by separator_mode="projection_close".
// Should be bigger than the largest hole radius you want closed.
separator_close_radius = 9;

// Tiny visual/alignment nudge, in case your local GOEWS checkout differs.
separator_nudge_x = 0;
separator_nudge_y = 0;

/* [Pull Tabs] */

enable_pull_tabs = true;

// "right", "left", "front", or "back"
// Right is the safest default for normal hex plates because the default stagger
// usually gives you a good mid-row attachment on that side.
tab_side = "right";

// How far the PETG tab sticks out beyond the plate footprint.
tab_len = 22;

// Width of the PETG tab.
tab_width = 18;

// How much the PETG tab overlaps into the separator sheet.
tab_overlap = 4;

// Rounded tab corners.
tab_radius = 3;

/* [PLA Tab Supports] */

// Add modeled PLA support islands under the exposed PETG pull tabs.
// These are actual PLA geometry, not slicer-generated supports.
enable_tab_supports = true;

// Keep support island separated from the tile by this much.
tab_support_tile_gap = 1.5;

// Leave this much of the outer PETG tab unsupported/free for easier grabbing.
tab_tip_free = 5;

// Width of PLA support under tab.
// Slightly narrower than tab_width makes it easier to break away.
tab_support_width = 14;

// Slightly round the support island corners.
tab_support_radius = 2;

// Height gap below PETG separator.
// 0 gives the best tab print reliability.
// Try 0.05 only if PETG bonds too hard to the PLA support.
tab_support_z_gap = 0;

/* [GOEWS Tile Parameters] */

variant = 1; // 0 original, 1 thicker cleats

columns = 4;
rows = 4;

// Hex edge fill params.
// The fast hex_cells separator does not model these fill pieces.
// Use separator_mode="projection_close" when these are enabled.
fill_top = false;
fill_bottom = false;
fill_left = false;
fill_right = false;

reverse_stagger = false;
exact_width = false;

// GOEWS skiplist uses 1-based [row, column] entries.
// Example: [[1, 2], [3, 4]]
skiplist = [];

mounting_hole_shank_diameter = 4;
mounting_hole_head_diameter = 8;
mounting_hole_inset_depth = 1;
mounting_hole_countersink_depth = 2;

/* [Hidden] */

$fa = 0.5;
$fs = 0.5;

stack_pitch = tile_thickness + spacer_h;

// Match tile.scad's stagger logic.
function hex_stagger_0() = reverse_stagger ? 1 : 0;
function hex_stagger_1() = reverse_stagger ? 0 : 1;

function hex_row_offset_x(row) =
  (row % 2 == hex_stagger_0()) ? tile_width / 2 : 0;

function hex_row_start_column(row) =
  exact_width && (row % 2 == hex_stagger_1()) ? 1 : 0;

function hex_row_min_x(row) =
  hex_row_offset_x(row) + hex_row_start_column(row) * tile_width;

function hex_row_max_x(row) =
  hex_row_offset_x(row) + columns * tile_width;

hex_min_x = min([for (row = [0 : rows - 1]) hex_row_min_x(row)]);
hex_max_x = max([for (row = [0 : rows - 1]) hex_row_max_x(row)]);
hex_min_y = 0;
hex_max_y = (rows - 1) * tile_y_offset + tile_height;

grid_min_x = 0;
grid_max_x = columns * tile_width;
grid_min_y = 0;
grid_max_y = rows * grid_tile_height;

footprint_min_x = tile_kind == "grid" ? grid_min_x : hex_min_x;
footprint_max_x = tile_kind == "grid" ? grid_max_x : hex_max_x;
footprint_min_y = tile_kind == "grid" ? grid_min_y : hex_min_y;
footprint_max_y = tile_kind == "grid" ? grid_max_y : hex_max_y;

footprint_center_x = (footprint_min_x + footprint_max_x) / 2;
footprint_center_y = (footprint_min_y + footprint_max_y) / 2;

module rounded_rect_2d(size=[10, 5], r=2) {
  rr = min(r, min(size[0], size[1]) / 2 - 0.01);

  offset(r=rr)
    square([
      max(0.01, size[0] - 2 * rr),
      max(0.01, size[1] - 2 * rr)
    ], center=true);
}

// Solid 2D version of GOEWS' pointy hex tile outline.
// This deliberately omits hanger holes, screw holes, rear cuts, etc.
module solid_hex_cell_2d() {
  polygon(points=[
    [tile_width / 2, 0],
    [tile_width, tile_height / 4],
    [tile_width, 3 * tile_height / 4],
    [tile_width / 2, tile_height],
    [0, 3 * tile_height / 4],
    [0, tile_height / 4]
  ]);
}

module one_tile() {
  if (tile_kind == "grid") {
    grid_tile(
      variant=variant,
      columns=columns,
      rows=rows,
      mounting_hole_shank_diameter=mounting_hole_shank_diameter,
      mounting_hole_head_diameter=mounting_hole_head_diameter,
      mounting_hole_inset_depth=mounting_hole_inset_depth,
      mounting_hole_countersink_depth=mounting_hole_countersink_depth,
      skiplist=skiplist
    );
  } else {
    tile(
      variant=variant,
      columns=columns,
      rows=rows,
      fill_top=fill_top,
      fill_bottom=fill_bottom,
      fill_left=fill_left,
      fill_right=fill_right,
      reverse_stagger=reverse_stagger,
      exact_width=exact_width,
      mounting_hole_shank_diameter=mounting_hole_shank_diameter,
      mounting_hole_head_diameter=mounting_hole_head_diameter,
      mounting_hole_inset_depth=mounting_hole_inset_depth,
      mounting_hole_countersink_depth=mounting_hole_countersink_depth,
      skiplist=skiplist,
      cut_outside_corners=true,
      chamfer_rear=true
    );
  }
}

module hex_cells_separator_2d() {
  translate([separator_nudge_x, separator_nudge_y])
    offset(delta=spacer_xy_delta)
      union() {
        for (row = [0 : rows - 1]) {
          offset_x = hex_row_offset_x(row);
          start_column = hex_row_start_column(row);
          pos_y = row * tile_y_offset;

          for (column = [start_column : columns - 1]) {
            pos_x = offset_x + column * tile_width;

            if (!in_list([row + 1, column + 1], skiplist)) {
              translate([pos_x, pos_y])
                solid_hex_cell_2d();
            }
          }
        }
      }
}

// Slower fallback that preserves the projected outside outline much better than hull().
// This can handle fill_top/fill_bottom/fill_left/fill_right more faithfully,
// but it is much slower because it projects the real tile.
module projection_closed_separator_2d() {
  translate([separator_nudge_x, separator_nudge_y])
    offset(delta=spacer_xy_delta)
      offset(delta=-separator_close_radius)
        offset(delta=separator_close_radius)
          projection(cut=true)
            one_tile();
}

module grid_separator_2d() {
  translate([separator_nudge_x, separator_nudge_y])
    offset(delta=spacer_xy_delta)
      square([grid_max_x - grid_min_x, grid_max_y - grid_min_y], center=false);
}

module separator_footprint_2d() {
  if (tile_kind == "grid") {
    grid_separator_2d();
  } else if (separator_mode == "projection_close") {
    projection_closed_separator_2d();
  } else {
    hex_cells_separator_2d();
  }
}

module tab_2d() {
  if (tab_side == "right") {
    translate([
      footprint_max_x + (tab_len - tab_overlap) / 2,
      footprint_center_y
    ])
      rounded_rect_2d([tab_len + tab_overlap, tab_width], tab_radius);

  } else if (tab_side == "left") {
    translate([
      footprint_min_x - (tab_len - tab_overlap) / 2,
      footprint_center_y
    ])
      rounded_rect_2d([tab_len + tab_overlap, tab_width], tab_radius);

  } else if (tab_side == "back") {
    translate([
      footprint_center_x,
      footprint_max_y + (tab_len - tab_overlap) / 2
    ])
      rounded_rect_2d([tab_width, tab_len + tab_overlap], tab_radius);

  } else {
    // "front"
    translate([
      footprint_center_x,
      footprint_min_y - (tab_len - tab_overlap) / 2
    ])
      rounded_rect_2d([tab_width, tab_len + tab_overlap], tab_radius);
  }
}

// Support is intentionally separated from the tile footprint.
// It starts outside the plate edge plus tab_support_tile_gap,
// and stops before the tab tip by tab_tip_free.
module tab_support_2d() {
  support_len = max(0.01, tab_len - tab_tip_free - tab_support_tile_gap);

  if (tab_side == "right") {
    translate([
      footprint_max_x + tab_support_tile_gap + support_len / 2,
      footprint_center_y
    ])
      rounded_rect_2d([support_len, tab_support_width], tab_support_radius);

  } else if (tab_side == "left") {
    translate([
      footprint_min_x - tab_support_tile_gap - support_len / 2,
      footprint_center_y
    ])
      rounded_rect_2d([support_len, tab_support_width], tab_support_radius);

  } else if (tab_side == "back") {
    translate([
      footprint_center_x,
      footprint_max_y + tab_support_tile_gap + support_len / 2
    ])
      rounded_rect_2d([tab_support_width, support_len], tab_support_radius);

  } else {
    // "front"
    translate([
      footprint_center_x,
      footprint_min_y - tab_support_tile_gap - support_len / 2
    ])
      rounded_rect_2d([tab_support_width, support_len], tab_support_radius);
  }
}

module separator_sheet() {
  linear_extrude(height=spacer_h)
    union() {
      separator_footprint_2d();

      if (enable_pull_tabs)
        tab_2d();
    }
}

module pla_tiles() {
  for (i = [0 : stack_count - 1]) {
    translate([0, 0, i * stack_pitch])
      one_tile();
  }
}

module pla_tab_supports() {
  support_h = max(0.01, tile_thickness - tab_support_z_gap);

  for (i = [0 : stack_count - 2]) {
    translate([0, 0, i * stack_pitch])
      linear_extrude(height=support_h)
        tab_support_2d();
  }
}

module pla_part() {
  pla_tiles();

  if (enable_pull_tabs && enable_tab_supports)
    pla_tab_supports();
}

module petg_part() {
  for (i = [0 : stack_count - 2]) {
    translate([0, 0, i * stack_pitch + tile_thickness])
      separator_sheet();
  }
}

if (part == "pla") {
  pla_part();
} else if (part == "petg") {
  petg_part();
} else {
  color("lightgray") pla_part();
  color("orange") petg_part();
}
