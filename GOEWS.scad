include <BOSL2/std.scad>
include <BOSL2/threading.scad>

include <constants.scad>
use <bin.scad>
use <bolt.scad>
use <cup.scad>
use <gridfinity.scad>
use <hanger.scad>
use <hook.scad>
use <parsers.scad>
use <rack.scad>
use <shelf.scad>
use <tile.scad>

/* [Primary parameters] */
// Which part to build
part = 0; // [0: Tile, 1: Hook, 2: Bolt, 3: Rack, 4: Grid Tile, 5: Shelf, 6: Hole shelf, 7: Slot shelf, 8: Bin, 9: Cup, 10: Gridfinity shelf]

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

// Reverse row stagger. This is useful for allowing tiles with odd numbers of rows to align with tiles with even numbers of rows at the top instead of the bottom
tile_reverse_stagger = false;

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

/* [Shelf parameters] */
// Shelf width
shelf_width = 83.5;

// Shelf depth
shelf_depth = 30;

// Shelf thickness
shelf_thickness = 4;

// Shelf rear fillet radius in mm
shelf_rear_fillet_radius = 1;

// Shelf rounding on the front edges in mm
shelf_rounding = 0.5;

/* [Hole shelf parameters] */
// Number of columns in the shelf
hole_shelf_columns = 3;

// Number of rows in the shelf
hole_shelf_rows = 1;

// Shelf thickness
hole_shelf_thickness = 4;

// Hole radius in mm
hole_shelf_hole_radius = 3.5;

// Gap between holes in a column in mm
hole_shelf_column_gap = 15;

// Gap between holes in a row in mm
hole_shelf_row_gap = 15;

// Gap between front of shelf and the front holes in mm
hole_shelf_front_gap = 15;

// Gap between back of shelf and the rear holes in mm
hole_shelf_rear_gap = 15;

// Gap between side of shelf and the side holes in mm
hole_shelf_side_gap = 15;

// Stagger rows
hole_shelf_stagger = false;

// Shelf rear fillet radius in mm
hole_shelf_rear_fillet_radius = 1;

// Shelf rounding on the front edges in mm
hole_shelf_rounding = 0.5;

/* [Slot shelf parameters] */
// Number of slots in the shelf
slot_shelf_slots = 4;

// Shelf thickness
slot_shelf_thickness = 4;

// Slot length in mm
slot_shelf_slot_length = 40;

// Slot width in mm
slot_shelf_slot_width = 10;

// Slot corner rounding in mm
slot_shelf_slot_rounding = 1;

// Gap between slots in mm
slot_shelf_gap = 10;

// Gap between front of shelf and slots in mm
slot_shelf_front_gap = 5;

// Gap between rear of shelf and slots in mm
slot_shelf_rear_gap = 10;

// Gap between side of shelf and slots in mm
slot_shelf_side_gap = 5;

// Shelf rear fillet radius in mm
slot_shelf_rear_fillet_radius = 1;

// Shelf rounding on the front edges in mm
slot_shelf_rounding = 0.5;

/* [Bin parameters] */
// Bin width in mm
bin_width = 41.5;

// Bin depth in mm
bin_depth = 41.5;

// Bin height in mm
bin_height = 20;

// Bin wall thickness in mm
bin_wall_thickness = 1;

// Bin bottom thickness in mm
bin_bottom_thickness = 2;

// Bin lip thickness in mm
bin_lip_thickness = 1;

// Bin inner rounding in mm
bin_inner_rounding = 1;

// Bin outer rounding in mm
bin_outer_rounding = 0.5;


/* [Cup parameters] */
// Inner diameter in mm
cup_inner_diameter = 37.5;

// Height in mm
cup_height = 24.39;

// Wall thickness in mm
cup_wall_thickness = 2;

// Bottom thickness in mm
cup_bottom_thickness = 2;

// Outer rouding in mm
cup_inner_rounding = 0.5;

// Inner rounding in mm
cup_outer_rounding = 0.5;


/* [Gridfinity shelf parameters] */
// Number of grid units in the x direction
gridfinity_shelf_gridx = 2;

// Number of grid units in the y direction
gridfinity_shelf_gridy = 1;

// Distance between plate and base in mm
gridfinity_shelf_rear_offset = 4.5;

// Additional base thickness in mm. This improves rigidity but can be 0 to implement a thin baseplate
gridfinity_shelf_base_thickness = 0;

// Skeletonized. When the base thickness is > 0 this will remove unnecessary material from the base
gridfinity_shelf_skeletonized = true;

// Add magnet holes. Will be ignored if base thickness is < 4
gridfinity_shelf_magnet_holes = false;

// Add crush ribs to the magnet holes
gridfinity_shelf_magnet_hole_crush_ribs = false;

// Add a chamfer to the magnet holes
gridfinity_shelf_magnet_hole_chamfer = false;


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
        reverse_stagger=tile_reverse_stagger,
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
else if (part == 5)
    shelf(
        width=shelf_width,
        depth=shelf_depth,
        thickness=shelf_thickness,
        rear_fillet_radius=shelf_rear_fillet_radius,
        rounding=shelf_rounding,
        hanger_tolerance=hanger_tolerance,
        variant=variant
    );
else if (part == 6)
    hole_shelf(
        thickness=hole_shelf_thickness,
        columns=hole_shelf_columns,
        rows=hole_shelf_rows,
        hole_radius=hole_shelf_hole_radius,
        column_gap=hole_shelf_column_gap,
        row_gap=hole_shelf_row_gap,
        front_gap=hole_shelf_front_gap,
        rear_gap=hole_shelf_rear_gap,
        side_gap=hole_shelf_side_gap,
        stagger=hole_shelf_stagger,
        rear_fillet_radius=hole_shelf_rear_fillet_radius,
        rounding=hole_shelf_rounding,
        hanger_tolerance=hanger_tolerance,
        variant=variant
    );
else if (part == 7)
    slot_shelf(
        thickness=slot_shelf_thickness,
        slots=slot_shelf_slots,
        slot_length=slot_shelf_slot_length,
        slot_width=slot_shelf_slot_width,
        slot_rounding=slot_shelf_slot_rounding,
        gap=slot_shelf_gap,
        front_gap=slot_shelf_front_gap,
        rear_gap=slot_shelf_rear_gap,
        side_gap=slot_shelf_side_gap,
        rear_fillet_radius=slot_shelf_rear_fillet_radius,
        rounding=slot_shelf_rounding,
        hanger_tolerance=hanger_tolerance,
        variant=variant
    );
else if (part == 8)
    bin(
        width=bin_width,
        depth=bin_depth,
        height=bin_height,
        wall_thickness=bin_wall_thickness,
        bottom_thickness=bin_bottom_thickness,
        lip_thickness=bin_lip_thickness,
        inner_rounding=bin_inner_rounding,
        outer_rounding=bin_outer_rounding,
        hanger_tolerance=hanger_tolerance,
        variant=variant
    );
else if (part == 9)
    cup(
        inner_diameter=cup_inner_diameter,
        height=cup_height,
        wall_thickness=cup_wall_thickness,
        bottom_thickness=cup_bottom_thickness,
        inner_rounding=cup_inner_rounding,
        outer_rounding=cup_outer_rounding,
        hanger_tolerance=hanger_tolerance,
        variant=variant
    );
else if (part == 10)
    gridfinity_shelf(
        gridx=gridfinity_shelf_gridx,
        gridy=gridfinity_shelf_gridy,
        rear_offset=gridfinity_shelf_rear_offset,
        base_thickness=gridfinity_shelf_base_thickness,
        skeletonized=gridfinity_shelf_skeletonized,
        magnet_holes=gridfinity_shelf_magnet_holes,
        magnet_hole_crush_ribs=gridfinity_shelf_magnet_hole_crush_ribs,
        magnet_hole_chamfer=gridfinity_shelf_magnet_hole_chamfer,
        hanger_tolerance=hanger_tolerance,
        variant=variant
    );
