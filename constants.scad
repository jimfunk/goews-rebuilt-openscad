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
hanger_bolt_notch_radius = 9.5;

// Center of the hanger cutout that provides clearance for the threaded hole during
// insertion
hanger_bolt_notch_center_height = 16;

// Bolt notch head clearance diameter
hanger_bolt_notch_head_clearance_diameter = 20;

// Hanger plate offset (thicker cleats only)
hanger_offset = 0.75;

// Nominal plate width
plate_width = 42;

// Reduce overall plate width by this amount on each side to make it easier to have
// multiple plates next to each other
plate_side_tolerance = 0.25;

// Default plate thickness
default_plate_thickness = 3;

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

// Grid tile height
grid_tile_height = 36.373;

// Distance between bottom of grid tile and hanger
grid_hanger_y_offset = 3;

// The height of the triangles at the top and bottom of the hex tiles are derived from
// the width
tile_triangle_height = tile_width * (1 - sqrt(2) / 2);

// The center offset of a row above another
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

// Distance between top of hanger and center of threaded hole
tile_threaded_hole_y_offset_from_hanger_top = (tile_height - tile_threaded_hole_y_offset) - (tile_triangle_height + tile_hanger_height);

// Thread diameter
thread_diameter = 14;

// Thread pitch
thread_pitch = 2;

// Thread tolerance
thread_tolerance = 0.5;

// Distance between bottom of tile and center of mounting hole
tile_mounting_hole_y_offset = 6;

// Distance between bottom of grid tile and center of mounting holes
grid_tile_mounting_hole_y_offset = 30.436;

// Distance between side of grid tile and center of mounting hole
grid_tile_mounting_hole_x_offset = 8.3;

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


// Hole type definitions
hole_type_round = 1;
hole_type_hex_nut = 2;
hole_type_square_nut = 3;
hole_type_din912_socket_head = 4;
hole_type_iso7380_button_head = 5;
hole_type_din7991_countersink_head = 6;


// Cable clip orientations
cable_clip_orientation_vertical = 1;
cable_clip_orientation_horizontal_left = 2;
cable_clip_orientation_horizontal_right = 3;

// This is the distance between the hanger and the plate. It is extended for the
// thicker cleat variant
function get_hanger_plate_offset(variant, hanger_tolerance) =
    variant == variant_thicker_cleats ? hanger_offset + hanger_tolerance : hanger_tolerance;

// Get the number of hanger units needed for the given width
function get_hanger_units_from_width(width) =
    ceil(width / plate_width);

// Get the total hanger plate width for the given width
function get_hanger_plate_width(width) =
    let(units = get_hanger_units_from_width(width))
        (units * plate_width);


// Get hex nut width according to the nearest metric bolt diameter
function get_hex_nut_width(diameter) =
    let (
        rounded_diameter = floor(diameter * 2) / 2 // Round down to nearest 0.5
    )
    (rounded_diameter <= 2) ? 4 :  // M2
    (rounded_diameter <= 2.5) ? 5 :  // M2.5
    (rounded_diameter <= 3) ? 5.5 :  // M3
    (rounded_diameter <= 4) ? 7 :  // M4
    (rounded_diameter <= 5) ? 8 :  // M5
    (rounded_diameter <= 6) ? 10 :  // M6
    (rounded_diameter <= 7) ? 11 :  // M7
    (rounded_diameter <= 8) ? 13 :  // M8
    (rounded_diameter <= 10) ? 17 :  // M10
    (rounded_diameter <= 12) ? 19 :  // M12
    (rounded_diameter <= 14) ? 22 :  // M14
    (rounded_diameter <= 16) ? 24 :  // M16
    (rounded_diameter <= 18) ? 27 :  // M18
    (rounded_diameter <= 20) ? 30 :  // M20
    (rounded_diameter <= 22) ? 34 :  // M22
    (rounded_diameter <= 24) ? 36 :  // M24
    (rounded_diameter <= 27) ? 41 :  // M27
    (rounded_diameter <= 30) ? 46 :  // M30
    (rounded_diameter <= 33) ? 50 :  // M33
    (rounded_diameter <= 36) ? 55 :  // M36
    (rounded_diameter <= 39) ? 60 :  // M39
    (rounded_diameter <= 42) ? 65 :  // M42
    (rounded_diameter <= 45) ? 70 :  // M45
    (rounded_diameter <= 48) ? 75 :  // M48
    (rounded_diameter <= 52) ? 80 :  // M52
    (rounded_diameter <= 56) ? 85 :  // M56
    (rounded_diameter <= 60) ? 90 :  // M60
    (rounded_diameter <= 64) ? 95 :  // M64
    (95 + 1.25 * (rounded_diameter - 64)); // Extrapolate beyond M64

// Get hex nut thickness according to the nearest metric bolt diameter
function get_hex_nut_thickness(diameter) =
    let (
        rounded_diameter = floor(diameter * 2) / 2 // Round down to nearest 0.5
    )
    (rounded_diameter <= 2) ? 1.6 : // M2
    (rounded_diameter <= 2.5) ? 2.15 :  // M2.5
    (rounded_diameter <= 3) ? 2.4 :  // M3
    (rounded_diameter <= 4) ? 3.2 :  // M4
    (rounded_diameter <= 5) ? 4 :  // M5
    (rounded_diameter <= 6) ? 5 :  // M6
    (rounded_diameter <= 7) ? 5.5 :  // M7
    (rounded_diameter <= 8) ? 6.16 :  // M8
    (rounded_diameter <= 10) ? 7.65 :  // M10
    (rounded_diameter <= 12) ? 9.2 :  // M12
    (rounded_diameter <= 14) ? 10.3 :  // M14
    (rounded_diameter <= 16) ? 11.3 :  // M16
    (rounded_diameter <= 18) ? 12.8 :  // M18
    (rounded_diameter <= 20) ? 14 :  // M20
    (rounded_diameter <= 22) ? 15.4 :  // M22
    (rounded_diameter <= 24) ? 17 :  // M24
    (rounded_diameter <= 27) ? 18.7 :  // M27
    (rounded_diameter <= 30) ? 21.5 :  // M30
    (rounded_diameter <= 33) ? 23.8 :  // M33
    (rounded_diameter <= 36) ? 25.8 :  // M36
    (rounded_diameter <= 39) ? 28.8 :  // M39
    (rounded_diameter <= 42) ? 31.4 :  // M42
    (rounded_diameter <= 45) ? 34.4 :  // M45
    (rounded_diameter <= 48) ? 37.4 :  // M48
    (rounded_diameter <= 52) ? 40.4 :  // M52
    (rounded_diameter <= 56) ? 43.7 :  // M56
    (rounded_diameter <= 60) ? 47  :  // M60
    (rounded_diameter <= 64) ? 50.3 :  // M64
    (50.3 + 0.825 * (rounded_diameter - 64)); // Extrapolate beyond M64

// Get DIN 912 socket head cap screw head diameter according to the nearest metric bolt
// diameter
function get_din912_socket_head_diameter(diameter) =
    let (
        rounded_diameter = floor(diameter * 2) / 2 // Round down to nearest 0.5
    )
    (rounded_diameter <= 2) ? 3.8 :  // M2
    (rounded_diameter <= 2.5) ? 4.5 :  // M2.5
    (rounded_diameter <= 3) ? 5.5 :  // M3
    (rounded_diameter <= 4) ? 7.0 :  // M4
    (rounded_diameter <= 5) ? 8.5 :  // M5
    (rounded_diameter <= 6) ? 10.0 :  // M6
    (rounded_diameter <= 7) ? 11.0 :  // M7
    (rounded_diameter <= 8) ? 13.0 :  // M8
    (rounded_diameter <= 10) ? 16.0 :  // M10
    (rounded_diameter <= 12) ? 18.0 :  // M12
    (rounded_diameter <= 14) ? 21.0 :  // M14
    (rounded_diameter <= 16) ? 24.0 :  // M16
    (rounded_diameter <= 18) ? 27.0 :  // M18
    (rounded_diameter <= 20) ? 30.0 :  // M20
    (rounded_diameter <= 22) ? 33.0 :  // M22
    (rounded_diameter <= 24) ? 36.0 :  // M24
    (rounded_diameter <= 27) ? 40.0 :  // M27
    (rounded_diameter <= 30) ? 45.0 :  // M30
    (rounded_diameter <= 33) ? 50.0 :  // M33
    (rounded_diameter <= 36) ? 54.0 :  // M36
    (rounded_diameter <= 39) ? 58.0 :  // M39
    (rounded_diameter <= 42) ? 63.0 :  // M42
    (rounded_diameter <= 45) ? 68.0 :  // M45
    (rounded_diameter <= 48) ? 72.0 :  // M48
    (rounded_diameter <= 52) ? 78.0 :  // M52
    (rounded_diameter <= 56) ? 84.0 :  // M56
    (rounded_diameter <= 60) ? 90.0 :  // M60
    (rounded_diameter <= 64) ? 96.0 :  // M64
    (96.0 + 1.5 * (rounded_diameter - 64)); // Extrapolate beyond M64

// Get DIN 912 socket head cap screw head height according to the nearest metric bolt
// diameter
function get_din912_socket_head_height(diameter) =
    let (
        rounded_diameter = floor(diameter * 2) / 2 // Round down to nearest 0.5
    )
    (rounded_diameter <= 2) ? 2 :  // M2
    (rounded_diameter <= 2.5) ? 2.5 :  // M2.5
    (rounded_diameter <= 3) ? 3 :  // M3
    (rounded_diameter <= 4) ? 4 :  // M4
    (rounded_diameter <= 5) ? 5 :  // M5
    (rounded_diameter <= 6) ? 6 :  // M6
    (rounded_diameter <= 7) ? 7 :  // M7
    (rounded_diameter <= 8) ? 8 :  // M8
    (rounded_diameter <= 10) ? 10 :  // M10
    (rounded_diameter <= 12) ? 12 :  // M12
    (rounded_diameter <= 14) ? 14 :  // M14
    (rounded_diameter <= 16) ? 16 :  // M16
    (rounded_diameter <= 18) ? 18 :  // M18
    (rounded_diameter <= 20) ? 20 :  // M20
    (rounded_diameter <= 22) ? 22 :  // M22
    (rounded_diameter <= 24) ? 24 :  // M24
    (rounded_diameter <= 27) ? 27 :  // M27
    (rounded_diameter <= 30) ? 30 :  // M30
    (rounded_diameter <= 33) ? 33 :  // M33
    (rounded_diameter <= 36) ? 36 :  // M36
    (rounded_diameter <= 39) ? 39 :  // M39
    (rounded_diameter <= 42) ? 42 :  // M42
    (rounded_diameter <= 45) ? 45 :  // M45
    (rounded_diameter <= 48) ? 48 :  // M48
    (rounded_diameter <= 52) ? 52 :  // M52
    (rounded_diameter <= 56) ? 56 :  // M56
    (rounded_diameter <= 60) ? 60 :  // M60
    (rounded_diameter <= 64) ? 64 :  // M64
    rounded_diameter - 64; // Height is the same as bolt diameter

// Get ISO 7380-1 button head cap screw head diameter according to the nearest metric
// bolt diameter
function get_iso7380_button_head_diameter(diameter) =
    let (
        rounded_diameter = floor(diameter * 2) / 2 // Round down to nearest 0.5
    )
    (rounded_diameter <= 2) ? 3.8 :  // M2 (Standard)
    (rounded_diameter <= 2.5) ? 4.5 :  // M2.5 (Standard)
    (rounded_diameter <= 3) ? 5.7 :  // M3 (Standard)
    (rounded_diameter <= 4) ? 7.6 :  // M4 (Standard)
    (rounded_diameter <= 5) ? 9.5 :  // M5 (Standard)
    (rounded_diameter <= 6) ? 10.4 :  // M6 (Standard)
    (rounded_diameter <= 7) ? 12.0 :  // M7 (Interpolated)
    (rounded_diameter <= 8) ? 13.6 :  // M8 (Standard)
    (rounded_diameter <= 10) ? 17.1 :  // M10 (Standard)
    (rounded_diameter <= 12) ? 20.6 :  // M12 (Standard)
    (rounded_diameter <= 14) ? 24.0 :  // M14 (Interpolated)
    (rounded_diameter <= 16) ? 27.4 :  // M16 (Standard)
    (rounded_diameter <= 18) ? 30.5 :  // M18 (Interpolated)
    (rounded_diameter <= 20) ? 33.6 :  // M20 (Standard)
    (rounded_diameter <= 22) ? 37.0 :  // M22 (Interpolated)
    (rounded_diameter <= 24) ? 40.3 :  // M24 (Standard)
    (rounded_diameter <= 27) ? 45.3 :  // M27 (Extrapolated)
    (rounded_diameter <= 30) ? 50.4 :  // M30 (Extrapolated)
    (rounded_diameter <= 33) ? 55.4 :  // M33 (Extrapolated)
    (rounded_diameter <= 36) ? 60.4 :  // M36 (Extrapolated)
    (rounded_diameter <= 39) ? 65.4 :  // M39 (Extrapolated)
    (rounded_diameter <= 42) ? 70.5 :  // M42 (Extrapolated)
    (rounded_diameter <= 45) ? 75.5 :  // M45 (Extrapolated)
    (rounded_diameter <= 48) ? 80.5 :  // M48 (Extrapolated)
    (rounded_diameter <= 52) ? 87.2 :  // M52 (Extrapolated)
    (rounded_diameter <= 56) ? 93.9 :  // M56 (Extrapolated)
    (rounded_diameter <= 60) ? 100.6 :  // M60 (Extrapolated)
    (rounded_diameter <= 64) ? 107.3 :  // M64 (Extrapolated)
    (107.3 + 1.675 * (rounded_diameter - 64)); // Extrapolate beyond M64

// Get ISO 7380-1 button head cap screw head height according to the nearest metric
// bolt diameter
function get_iso7380_button_head_height(diameter) =
    let (
        rounded_diameter = floor(diameter * 2) / 2 // Round down to nearest 0.5
    )
    // Order from smallest to largest nominal diameter
    (rounded_diameter <= 2) ? 1.1 :  // M2
    (rounded_diameter <= 2.5) ? 1.4 :  // M2.5 (Standard value, 0.55*2.5=1.375)
    (rounded_diameter <= 3) ? 1.65 :  // M3
    (rounded_diameter <= 4) ? 2.2 :  // M4
    (rounded_diameter <= 5) ? 2.75 :  // M5
    (rounded_diameter <= 6) ? 3.3 :  // M6
    (rounded_diameter <= 7) ? 3.85 :  // M7 (0.55 * 7)
    (rounded_diameter <= 8) ? 4.4 :  // M8
    (rounded_diameter <= 10) ? 5.5 :  // M10
    (rounded_diameter <= 12) ? 6.6 :  // M12
    (rounded_diameter <= 14) ? 7.7 :  // M14 (0.55 * 14)
    (rounded_diameter <= 16) ? 8.8 :  // M16
    (rounded_diameter <= 18) ? 9.9 :  // M18 (0.55 * 18)
    (rounded_diameter <= 20) ? 11.0 :  // M20
    (rounded_diameter <= 22) ? 12.1 :  // M22 (0.55 * 22)
    (rounded_diameter <= 24) ? 13.2 :  // M24
    (rounded_diameter <= 27) ? 14.85 :  // M27 (0.55 * 27)
    (rounded_diameter <= 30) ? 16.5 :  // M30 (0.55 * 30)
    (rounded_diameter <= 33) ? 18.15 :  // M33 (0.55 * 33)
    (rounded_diameter <= 36) ? 19.8 :  // M36 (0.55 * 36)
    (rounded_diameter <= 39) ? 21.45 :  // M39 (0.55 * 39)
    (rounded_diameter <= 42) ? 23.1 :  // M42 (0.55 * 42)
    (rounded_diameter <= 45) ? 24.75 :  // M45 (0.55 * 45)
    (rounded_diameter <= 48) ? 26.4 :  // M48 (0.55 * 48)
    (rounded_diameter <= 52) ? 28.6 :  // M52 (0.55 * 52)
    (rounded_diameter <= 56) ? 30.8 :  // M56 (0.55 * 56)
    (rounded_diameter <= 60) ? 33.0 :  // M60 (0.55 * 60)
    (rounded_diameter <= 64) ? 35.2 :  // M64 (0.55 * 64)
    (0.55 * rounded_diameter); // Extrapolate beyond M64 (maintains 0.55*d rule)

// Get DIN 7991 countersunk head screw head diameter according to the nearest metric
// bolt diameter
function get_din7991_countersink_head_diameter(diameter) =
    let (
        rounded_diameter = floor(diameter * 2) / 2 // Round down to nearest 0.5
    )
    (rounded_diameter <= 3) ? 6.72 :  // M3
    (rounded_diameter <= 4) ? 8.96 :  // M4
    (rounded_diameter <= 5) ? 11.20 :  // M5
    (rounded_diameter <= 6) ? 13.44 :  // M6
    (rounded_diameter <= 7) ? 15.68 :  // M7 (Interpolated)
    (rounded_diameter <= 8) ? 17.92 :  // M8
    (rounded_diameter <= 10) ? 22.40 :  // M10
    (rounded_diameter <= 12) ? 26.88 :  // M12
    (rounded_diameter <= 14) ? 30.24 :  // M14 (Interpolated)
    (rounded_diameter <= 16) ? 33.60 :  // M16
    (rounded_diameter <= 18) ? 36.95 :  // M18 (Interpolated)
    (rounded_diameter <= 20) ? 40.30 :  // M20
    (rounded_diameter <= 22) ? 43.65 :  // M22 (Extrapolated)
    (rounded_diameter <= 24) ? 47.00 :  // M24 (Extrapolated)
    (rounded_diameter <= 27) ? 52.03 :  // M27 (Extrapolated)
    (rounded_diameter <= 30) ? 57.05 :  // M30 (Extrapolated)
    (rounded_diameter <= 33) ? 62.08 :  // M33 (Extrapolated)
    (rounded_diameter <= 36) ? 67.10 :  // M36 (Extrapolated)
    (rounded_diameter <= 39) ? 72.13 :  // M39 (Extrapolated)
    (rounded_diameter <= 42) ? 77.15 :  // M42 (Extrapolated)
    (rounded_diameter <= 45) ? 82.18 :  // M45 (Extrapolated)
    (rounded_diameter <= 48) ? 87.20 :  // M48 (Extrapolated)
    (rounded_diameter <= 52) ? 93.90 :  // M52 (Extrapolated)
    (rounded_diameter <= 56) ? 100.60 :  // M56 (Extrapolated)
    (rounded_diameter <= 60) ? 107.30 :  // M60 (Extrapolated)
    (rounded_diameter <= 64) ? 114.00 :  // M64 (Extrapolated)
    (114.00 + 1.675 * (rounded_diameter - 64)); // Extrapolate beyond M64

// Get DIN 7991 countersunk head screw head height according to the nearest metric bolt
// diameter
function get_din7991_countersink_head_height(diameter) =
    let (
        rounded_diameter = floor(diameter * 2) / 2 // Round down to nearest 0.5
    )
    (rounded_diameter <= 3) ? 1.86 :  // M3
    (rounded_diameter <= 4) ? 2.48 :  // M4
    (rounded_diameter <= 5) ? 3.10 :  // M5
    (rounded_diameter <= 6) ? 3.72 :  // M6
    (rounded_diameter <= 7) ? 4.34 :  // M7 (Interpolated)
    (rounded_diameter <= 8) ? 4.96 :  // M8
    (rounded_diameter <= 10) ? 6.20 :  // M10
    (rounded_diameter <= 12) ? 7.44 :  // M12
    (rounded_diameter <= 14) ? 8.12 :  // M14 (Interpolated)
    (rounded_diameter <= 16) ? 8.80 :  // M16
    (rounded_diameter <= 18) ? 9.48 :  // M18 (Interpolated)
    (rounded_diameter <= 20) ? 10.16 :  // M20
    (rounded_diameter <= 22) ? 10.84 :  // M22 (Extrapolated)
    (rounded_diameter <= 24) ? 11.52 :  // M24 (Extrapolated)
    (rounded_diameter <= 27) ? 12.54 :  // M27 (Extrapolated)
    (rounded_diameter <= 30) ? 13.56 :  // M30 (Extrapolated)
    (rounded_diameter <= 33) ? 14.58 :  // M33 (Extrapolated)
    (rounded_diameter <= 36) ? 15.60 :  // M36 (Extrapolated)
    (rounded_diameter <= 39) ? 16.62 :  // M39 (Extrapolated)
    (rounded_diameter <= 42) ? 17.64 :  // M42 (Extrapolated)
    (rounded_diameter <= 45) ? 18.66 :  // M45 (Extrapolated)
    (rounded_diameter <= 48) ? 19.68 :  // M48 (Extrapolated)
    (rounded_diameter <= 52) ? 21.04 :  // M52 (Extrapolated)
    (rounded_diameter <= 56) ? 22.40 :  // M56 (Extrapolated)
    (rounded_diameter <= 60) ? 23.76 :  // M60 (Extrapolated)
    (rounded_diameter <= 64) ? 25.12 :  // M64 (Extrapolated)
    (25.12 + 0.34 * (rounded_diameter - 64)); // Extrapolate beyond M64
