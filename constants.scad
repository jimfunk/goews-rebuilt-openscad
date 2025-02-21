/*
 * These constants should not be modified
 */

// The width of the hanger
hanger_width = 35.2;

// Hanger primary thickness
hanger_thickness = 5;

// Hanger height
hanger_height = 13.15;

// Radius of hanger cutout
hanger_cutout_radius = 9.5;

// Center of the hanger cutout that provides clearance for the threaded hole during
// insertion
hanger_cutout_center_height = 16;

// Hanger plate offset (thicker cleats only)
hanger_offset = 1;

// Plate width
plate_width = 41.5;

// The distance added between plate hangers when there are multiple
plate_gap = 0.5;

// Plate thickness
plate_thickness = 3;

// Plate height
plate_height = 24.39;

// Plate outer radius
plate_outer_radius = 3;

// Plate inner radius
plate_inner_radius = 4;

// Offset of the plate inner radius
plate_inner_radius_offset = 0.44;

// Plate bolt cutout radius
plate_cutout_radius = 7;

// Plate cutout offset from the bottom of the plate
plate_cutout_y_offset = 24.823;

// Tile thickness
tile_thickness = 6;

// Tile width
tile_width = 42;

// Tile height is derived from the width
tile_height = (2 * tile_width * sqrt(3)) / 3;

// The height of the triangles at the top and bottom of the hex tiles are derived from
// the width
tile_triangle_height = tile_width * (1 - sqrt(2) / 2);

tile_y_offset = tile_width * sqrt(3) / 2;

// Chamfer around top of tile
tile_chamfer = 0.5;

// Tile hanger width
tile_hanger_width = 36;

// Tile hanger height
tile_hanger_height = 22;

// Tile hanger cleat width
tile_hanger_cleat_width = 2.5;

// Tile hanger cleat lower height
tile_hanger_cleat_lower_height = 8;

// Tile hanger rear opening width (Original variant)
tile_hanger_rear_cleat_x_offset = 7.5;

// Tile hanger rear cleat thickness (Original variant)
tile_hanger_rear_cleat_thickness = 1;

// Tile hanger hole outer diameter
tile_hanger_hole_outer_diameter = 9;

// Distance between top of tile and center of threaded hole
tile_threaded_hole_y_offset = 11.55;

// Thread diameter
thread_diameter = 14;

// Thread pitch
thread_pitch = 2;

// Thread tolerance
thread_tolerance = 0.5;

// Distance between bottom of tile and center of mounting hole
tile_mounting_hole_y_offset = 6;

// Mounting hold shank diameter
tile_mounting_hole_shank_diameter = 4;

// Mounting hole countersink diameter
tile_mounting_hole_countersink_diameter = 8;

// Mounting hole countersink depth
tile_mounting_hole_countersink_depth = 2;

// Mounting hole countersink inset depth
tile_mounting_hole_countersink_inset_depth = 1;

// Bolt head outer diameter
bolt_head_outer_diameter = 19.35;

// Bolt head thickness
bolt_head_thickness = 4;

// Bolt head cutout radius for the outer profile
bolt_head_cutout_radius = 7.5;

// Bolt head cutout offset from center for the outer profile
bolt_head_cutout_offset = 14.175;


// Variant definitions
variant_original = 0;
variant_thicker_cleats = 1;


// This is the distance between the hanger and the plate. It is extended for the
// thicker cleat variant
function get_hanger_plate_offset(variant, hanger_tolerance) =
    variant == variant_thicker_cleats ? hanger_offset + hanger_tolerance : hanger_tolerance;

// Get the number of hanger units needed for the given width
function get_hanger_units_from_width(width) = ceil(width / plate_width);

// Get the total hanger plate width for the given width
function get_hanger_plate_width(width) = ceil(width / plate_width) * plate_width;
