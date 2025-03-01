include <BOSL2/std.scad>
include <BOSL2/threading.scad>

include <constants.scad>
use <bolt.scad>
use <hanger.scad>
use <hook.scad>
use <parsers.scad>
use <rack.scad>
use <tile.scad>

/* [Primary parameters] */
// Which part to build
part = 0; // [0: Tile, 1: Hook, 2: Bolt, 3: Rack, 4: Grid Tile]

// Which variant to use
variant = 0; // [0: Original, 1: Thicker cleats]

// Added to hangers to allow for easier insertion and removal. This can be reduced to make hanger plates tighter to the tile. It reduces the tilt but makes them harder to insert and remove
hanger_tolerance = 0.15;

/* [Tile parameters] */
// Tile columns in units
tile_columns = 4;

// Tile rows in units
tile_rows = 4;

// Fill top row
tile_fill_top = false;

// Fill bottom row
tile_fill_bottom = false;

// Fill left side
tile_fill_left = false;

// Fill right side
tile_fill_right = false;

// Mounting hole shank diameter
tile_mounting_hole_shank_diameter = 4;

// Mounting hole head diameter
tile_mounting_hole_head_diameter = 8;

// Mounting hole inset depth
tile_mounting_hole_inset_depth = 1;

// Mounting hole countersink depth. Set to 0 to disable countersink
tile_mounting_hole_countersink_depth = 2;

// List of tile positions to skip. Each entry is a pair of 1-based row and column coordinates with the origin at the lower left, eg: [1, 2], [3, 4]
tile_skip_list = "";

/* [Hook parameters] */
// Number of hooks
hooks = 1;

// Hook width in mm
hook_width = 10;

// Gap between hooks when there is more than one
hook_gap = 10;

// Hook shank length in mm
hook_shank_length = 10;

// Hook shank thickness in mm
hook_shank_thickness = 8;

// Hook post height in mm
hook_post_height = 18;

// Hook post thickness in mm
hook_post_thickness = 6;

// Hook rounding on the outer corners in mm
hook_rounding = 0.5;

/* [Rack parameters] */
// Number of slots in the rack
rack_slots = 7;

// Slot width in mm
rack_slot_width = 6;

// Divider width in mm
rack_divider_width = 10;

// Divider length in mm
rack_divider_length = 80;

// Divider thickness in mm
rack_divider_thickness = 6;

// Whether to include a lip at the front of the dividers
rack_lip = false;

// Lip height in mm
rack_lip_height = 8;

// Lip thickness in mm
rack_lip_thickness = 4;

// Rounding on the outer corners of the divider and lip in mm
rack_rounding = 0.5;

/* [Bolt parameters] */
// Bolt length in mm
bolt_length = 9;

// Bolt socket width in mm
bolt_socket_width = 8.4;

/* [Hidden] */
$fa=0.5;
$fs=0.5;


// The part to model
if (part == 0)
    tile(
        variant=variant,
        columns=tile_columns,
        rows=tile_rows,
        fill_top=tile_fill_top,
        fill_bottom=tile_fill_bottom,
        fill_left=tile_fill_left,
        fill_right=tile_fill_right,
        mounting_hole_shank_diameter=tile_mounting_hole_shank_diameter,
        mounting_hole_head_diameter=tile_mounting_hole_head_diameter,
        mounting_hole_inset_depth=tile_mounting_hole_inset_depth,
        mounting_hole_countersink_depth=tile_mounting_hole_countersink_depth,
        skiplist=parse_vector_list(tile_skip_list)
    );
else if (part == 1)
    hook(
        hooks=hooks,
        variant=variant,
        width=hook_width,
        gap=hook_gap,
        shank_length=hook_shank_length,
        shank_thickness=hook_shank_thickness,
        post_height=hook_post_height,
        post_thickness=hook_post_thickness,
        hanger_tolerance=hanger_tolerance,
        rounding=hook_rounding
    );
else if (part == 2)
    bolt(
        length=bolt_length,
        socket_width=bolt_socket_width
    );
else if (part == 3)
    rack(
        slots=rack_slots,
        slot_width=rack_slot_width,
        divider_width=rack_divider_width,
        divider_length=rack_divider_length,
        divider_thickness=rack_divider_thickness,
        lip=rack_lip,
        lip_height=rack_lip_height,
        lip_thickness=rack_lip_thickness,
        rounding=rack_rounding,
        hanger_tolerance=hanger_tolerance,
        variant=variant
    );
else if (part == 4)
    grid_tile(
        variant=variant,
        columns=tile_columns,
        rows=tile_rows,
        mounting_hole_shank_diameter=tile_mounting_hole_shank_diameter,
        mounting_hole_head_diameter=tile_mounting_hole_head_diameter,
        mounting_hole_inset_depth=tile_mounting_hole_inset_depth,
        mounting_hole_countersink_depth=tile_mounting_hole_countersink_depth,
        skiplist=parse_vector_list(tile_skip_list)
    );
