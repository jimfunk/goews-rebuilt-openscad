// tile_stack.scad
//
// Export twice:
//
//   openscad -o goews-stack-pla.stl  -D 'part="pla"'  tile_stack.scad
//   openscad -o goews-stack-petg.stl -D 'part="petg"' tile_stack.scad
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

include <parsers.scad>

/* [Stack] */

// "hex" or "grid"
tile_kind = "hex"; // [hex, grid]

// "pla", "petg", or "all" for preview
part = "all"; // [all, pla, petg]

stack_count = 3;

spacer_h = 0.6;

// Shrinks separator slightly so PETG does not peek past the plate edge.
spacer_xy_delta = -0.20;

// "hex_cells" is the recommended fast path for hex GOEWS plates.
// "projection_close" is slower, but handles fill_top/fill_bottom/etc better.
separator_mode = "hex_cells"; // [hex_cells, projection_close]

separator_close_radius = 9;

separator_nudge_x = 0;
separator_nudge_y = 0;

/* [Pull Tabs] */

enable_pull_tabs = true;

// "right", "left", "front", or "back"
tab_side = "right"; // [right, left, front, back]

tab_len = 22;
tab_width = 14;
tab_overlap = 4;
tab_radius = 2.5;

/* [PLA Tab Supports] */

enable_tab_supports = true;

// Gap between main tile body and PLA support island.
tab_support_tile_gap = 1.5;

// 0 means support reaches all the way to the PETG tab end.
// Increase only if you intentionally want unsupported PETG at the very tip.
tab_tip_free = 0;

tab_support_width = 14;
tab_support_radius = 2;

// 0 gives best PETG tab print reliability.
tab_support_z_gap = 0;

/* [GOEWS Tile Parameters] */

variant = 1;

columns = 4;
rows = 4;

fill_top = false;
fill_bottom = false;
fill_left = false;
fill_right = false;

reverse_stagger = false;
exact_width = false;

// GOEWS skiplist uses 1-based [row, column] entries.
// Example: [[1, 2], [3, 4]]
skip_list = "";
skiplist = parse_vector_list(skip_list);

mounting_hole_shank_diameter = 4;
mounting_hole_head_diameter = 8;
mounting_hole_inset_depth = 1;
mounting_hole_countersink_depth = 2;

/* [Separator Hole Relief] */

// Clearance around the threaded GOEWS bolt hole in the PETG separator.
// Increase this if the threaded hole still shows separator droop.
separator_threaded_hole_clearance = -0.8;

// Maximum unsupported distance the next tile's first layer has to bridge
// around the mounting shank hole. Larger values open more of the screw inset;
// smaller values give the next tile more support.
separator_mounting_hole_start_overhang = 0.8;

// Keep this much PETG lip around the screw-head inset edge.
// This prevents the separator from trying to bridge the whole inset.
separator_mounting_inset_edge_lip = 0.8;

// Keep this much PETG lip around the central hanger/window cutout.
// Larger values support the next tile more; smaller values open more of the window.
separator_window_edge_lip = 2.5;

// Rounded corner radius for the hanger/window relief cut.
separator_window_corner_radius = 2.5;

// Leave PETG under the circular pad around the GOEWS bolt hole.
// Larger values remove more PETG around that circular pad; smaller values
// leave more PETG separator material. This should stay smaller than the
// circular pad radius.
separator_window_threaded_pad_clearance = -0.5;

/* [Hidden] */

$fa = 0.5;
$fs = 0.5;

stack_pitch = tile_thickness + spacer_h;

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

function hex_row_center_x(row) =
  (hex_row_min_x(row) + hex_row_max_x(row)) / 2;

function hex_row_center_y(row) =
  row * tile_y_offset + tile_height / 2;

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

// Pick a real exposed hex row near the middle, rather than the overall bbox.
// This fixes tabs floating beside an indented hex edge.
hex_center_row = floor((rows - 1) / 2);

function hex_nearest_right_row(r=hex_center_row) =
  rows <= 1 ? 0 :
  hex_row_max_x(r) == hex_max_x ? r :
  r > 0 && hex_row_max_x(r - 1) == hex_max_x ? r - 1 :
  r + 1 < rows && hex_row_max_x(r + 1) == hex_max_x ? r + 1 :
  r;

function hex_nearest_left_row(r=hex_center_row) =
  rows <= 1 ? 0 :
  hex_row_min_x(r) == hex_min_x ? r :
  r > 0 && hex_row_min_x(r - 1) == hex_min_x ? r - 1 :
  r + 1 < rows && hex_row_min_x(r + 1) == hex_min_x ? r + 1 :
  r;

hex_right_tab_row = hex_nearest_right_row();
hex_left_tab_row = hex_nearest_left_row();
hex_front_tab_row = 0;
hex_back_tab_row = rows - 1;

function tab_anchor_x() =
  tile_kind == "hex" && tab_side == "right" ? hex_row_max_x(hex_right_tab_row) :
  tile_kind == "hex" && tab_side == "left"  ? hex_row_min_x(hex_left_tab_row) :
  tile_kind == "hex" && tab_side == "back"  ? hex_row_center_x(hex_back_tab_row) :
  tile_kind == "hex" && tab_side == "front" ? hex_row_center_x(hex_front_tab_row) :
  tab_side == "right" ? footprint_max_x :
  tab_side == "left"  ? footprint_min_x :
  footprint_center_x;

function tab_anchor_y() =
  tile_kind == "hex" && tab_side == "right" ? hex_row_center_y(hex_right_tab_row) :
  tile_kind == "hex" && tab_side == "left"  ? hex_row_center_y(hex_left_tab_row) :
  tile_kind == "hex" && tab_side == "back"  ? hex_max_y :
  tile_kind == "hex" && tab_side == "front" ? hex_min_y :
  tab_side == "back"  ? footprint_max_y :
  tab_side == "front" ? footprint_min_y :
  footprint_center_y;

function separator_threaded_hole_cut_radius() =
  (thread_diameter + thread_tolerance) / 2 + separator_threaded_hole_clearance;

function separator_mounting_hole_cut_radius() =
  max(
    mounting_hole_shank_diameter / 2,
    min(
      mounting_hole_shank_diameter / 2 + separator_mounting_hole_start_overhang,
      mounting_hole_head_diameter / 2 - separator_mounting_inset_edge_lip
    )
  );

function separator_window_cut_width() =
  max(0.01, tile_hanger_width - 2 * separator_window_edge_lip);

function separator_window_cut_height() =
  max(0.01, tile_hanger_height - 2 * separator_window_edge_lip);

function separator_window_cut_radius() =
  min(
    separator_window_corner_radius,
    min(separator_window_cut_width(), separator_window_cut_height()) / 2 - 0.01
  );

function separator_window_threaded_pad_keep_radius() =
  max(
    separator_threaded_hole_cut_radius(),
    tile_hanger_hole_outer_diameter - separator_window_threaded_pad_clearance
  );

module rounded_rect_2d(size=[10, 5], r=2) {
  rr = min(r, min(size[0], size[1]) / 2 - 0.01);

  offset(r=rr)
    square([
      max(0.01, size[0] - 2 * rr),
      max(0.01, size[1] - 2 * rr)
    ], center=true);
}

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

module separator_window_relief_2d() {
  hanger_x_offset = (tile_width - tile_hanger_width) / 2;

  difference() {
    translate([
      hanger_x_offset + tile_hanger_width / 2,
      tile_triangle_height + tile_hanger_height / 2
    ])
      rounded_rect_2d(
        [separator_window_cut_width(), separator_window_cut_height()],
        separator_window_cut_radius()
      );

    // Keep separator material under the circular boss/pad around the GOEWS
    // bolt hole. The actual threaded hole is still cut separately by
    // hex_separator_hole_relief_2d().
    translate([tile_width / 2, tile_height - tile_threaded_hole_y_offset])
      circle(r=separator_window_threaded_pad_keep_radius());
  }
}

module hex_separator_hole_relief_2d() {
  translate([separator_nudge_x, separator_nudge_y])
    union() {
      for (row = [0 : rows - 1]) {
        offset_x = hex_row_offset_x(row);
        start_column = hex_row_start_column(row);
        pos_y = row * tile_y_offset;

        for (column = [start_column : columns - 1]) {
          pos_x = offset_x + column * tile_width;

          if (!in_list([row + 1, column + 1], skiplist)) {
            translate([pos_x, pos_y]) {
              // Open most of the central hanger/window area, leaving a small
              // lip so the next tile's first layers have somewhere to start.
              // The circular GOEWS-bolt pad is protected by
              // separator_window_relief_2d(), then the actual threaded hole is
              // cut separately below.
              separator_window_relief_2d();

              // Do not bridge the threaded GOEWS bolt hole.
              translate([tile_width / 2, tile_height - tile_threaded_hole_y_offset])
                circle(r=separator_threaded_hole_cut_radius());

              // Open most of the mounting screw inset, while leaving a small
              // PETG ledge to support the next tile's first layer around the
              // shank hole.
              translate([tile_width / 2, tile_mounting_hole_y_offset])
                circle(r=separator_mounting_hole_cut_radius());
            }
          }
        }
      }
    }
}

module separator_hole_relief_2d() {
  if (tile_kind == "hex") {
    hex_separator_hole_relief_2d();
  }
}

module tab_2d() {
  ax = tab_anchor_x();
  ay = tab_anchor_y();

  if (tab_side == "right") {
    translate([ax + (tab_len - tab_overlap) / 2, ay])
      rounded_rect_2d([tab_len + tab_overlap, tab_width], tab_radius);

  } else if (tab_side == "left") {
    translate([ax - (tab_len - tab_overlap) / 2, ay])
      rounded_rect_2d([tab_len + tab_overlap, tab_width], tab_radius);

  } else if (tab_side == "back") {
    translate([ax, ay + (tab_len - tab_overlap) / 2])
      rounded_rect_2d([tab_width, tab_len + tab_overlap], tab_radius);

  } else {
    translate([ax, ay - (tab_len - tab_overlap) / 2])
      rounded_rect_2d([tab_width, tab_len + tab_overlap], tab_radius);
  }
}

module tab_support_2d() {
  ax = tab_anchor_x();
  ay = tab_anchor_y();

  support_len = max(0.01, tab_len - tab_support_tile_gap - tab_tip_free);

  if (tab_side == "right") {
    translate([ax + tab_support_tile_gap + support_len / 2, ay])
      rounded_rect_2d([support_len, tab_support_width], tab_support_radius);

  } else if (tab_side == "left") {
    translate([ax - tab_support_tile_gap - support_len / 2, ay])
      rounded_rect_2d([support_len, tab_support_width], tab_support_radius);

  } else if (tab_side == "back") {
    translate([ax, ay + tab_support_tile_gap + support_len / 2])
      rounded_rect_2d([tab_support_width, support_len], tab_support_radius);

  } else {
    translate([ax, ay - tab_support_tile_gap - support_len / 2])
      rounded_rect_2d([tab_support_width, support_len], tab_support_radius);
  }
}

module separator_sheet() {
  linear_extrude(height=spacer_h)
    difference() {
      union() {
        separator_footprint_2d();

        if (enable_pull_tabs)
          tab_2d();
      }

      separator_hole_relief_2d();
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
