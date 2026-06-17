// stacked_goews_tiles.scad
//
// Export twice:
//   openscad -o goews-stack-pla.stl  -D 'part="pla"'  stacked_goews_tiles.scad
//   openscad -o goews-stack-petg.stl -D 'part="petg"' stacked_goews_tiles.scad
//
// Then import both STLs into Orca as one multi-part object.
// Assign PLA to goews-stack-pla.stl and PETG to goews-stack-petg.stl.

include <constants.scad>

// Use, do not include, because tile.scad/grid_tile.scad each render
// a top-level object at the bottom of the file.
use <tile.scad>
use <grid_tile.scad>

/* [Stack] */

// "hex" or "grid"
tile_kind = "hex";

// "pla", "petg", or "all" for preview
part = "petg";

// Number of actual GOEWS tiles in the stack
stack_count = 3;

// PETG separator thickness.
// Start with one or two layer heights. For 0.2mm layers, try 0.2 or 0.4.
spacer_h = 0.4;

// Slight XY adjustment for spacer sheets.
// 0 = exact first-layer footprint.
// -0.05 or -0.10 can reduce PETG fins around the outside.
spacer_xy_delta = -0.05;

/* [GOEWS tile parameters] */

variant = 1; // 0 original, 1 thicker cleats

columns = 4;
rows = 4;

// Hex-only edge fill params
fill_top = false;
fill_bottom = false;
fill_left = false;
fill_right = false;
reverse_stagger = false;
exact_width = false;

// Use real vector form here, not the GOEWS customizer string.
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

// The spacer is the first-layer footprint of the next tile.
// That is usually what you want the upper tile to start on.
module spacer_sheet() {
  linear_extrude(height=spacer_h)
    offset(delta=spacer_xy_delta)
      projection(cut=true)
        one_tile();
}

module pla_tiles() {
  for (i = [0 : stack_count - 1]) {
    translate([0, 0, i * stack_pitch])
      one_tile();
  }
}

module petg_spacers() {
  for (i = [0 : stack_count - 2]) {
    translate([0, 0, i * stack_pitch + tile_thickness])
      spacer_sheet();
  }
}

if (part == "pla") {
  pla_tiles();
} else if (part == "petg") {
  petg_spacers();
} else {
  color("lightgray") pla_tiles();
  color("orange") petg_spacers();
}
