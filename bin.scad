include <BOSL2/std.scad>
include <BOSL2/shapes3d.scad>

include <constants.scad>
use <hanger.scad>


/* [Primary parameters] */
// Which variant to use
variant = 0; // [0: Original, 1: Thicker cleats]

// Added to hangers to allow for easier insertion and removal. This can be reduced to make hanger plates tighter to the tile. It reduces the tilt but makes them harder to insert and remove
hanger_tolerance = 0.15;

/* [Bin parameters] */
// Bin width in mm
width = 41.5;

// Bin depth in mm
depth = 41.5;

// Bin height in mm
height = 20;

// Bin wall thickness in mm
wall_thickness = 1;

// Bin bottom thickness in mm
bottom_thickness = 2;

// Bin lip thickness in mm
lip_thickness = 1;

// Bin inner rounding in mm
inner_rounding = 1;

// Bin outer rounding in mm
outer_rounding = 0.5;


/* [Hidden] */
$fa=0.5;
$fs=0.5;


module bin(
    width=41.5,
    depth=41.5,
    height=20,
    wall_thickness=1,
    bottom_thickness=2,
    lip_thickness=1,
    inner_rounding=1,
    outer_rounding=0.5,
    hanger_tolerance=0.15,
    variant=variant_original
) {
    hanger_plate_offset = get_hanger_plate_offset(variant, hanger_tolerance);
    hanger_total_thickness = hanger_thickness + hanger_plate_offset;
    plate_total_thickness = default_plate_thickness + hanger_total_thickness;

    x_offset = get_hanger_plate_width(width) / 2;
    x_plate_offset = (get_hanger_plate_width(width) - width) / 2;
    y_offset = plate_total_thickness;

    cutout = height > (plate_height - plate_cutout_radius) ? false : true;
    plate_outer_radius = height > (plate_height - plate_outer_radius) ? outer_rounding : plate_outer_radius;
    plate_extend_bottom = height > plate_height ? height - plate_height : 0;

    union() {
        hanger_plate(
            variant=variant,
            hanger_units=get_hanger_units_from_width(width),
            hanger_tolerance=hanger_tolerance,
            extend_bottom=plate_extend_bottom,
            cutout=cutout,
            outer_radius=plate_outer_radius
        );

        difference() {
            // Outer box
            translate([x_offset, y_offset, 0]) {
                cuboid(
                    [width, depth, height],
                    anchor=BOTTOM+FRONT,
                    rounding=outer_rounding,
                    edges=[BACK, TOP+RIGHT, TOP+LEFT]
                );
            }

            // Inner box
            translate([x_offset, y_offset, bottom_thickness]) {
                cuboid(
                    [width - (wall_thickness * 2), depth - wall_thickness, height],
                    anchor=BOTTOM+FRONT,
                    rounding=inner_rounding
                );
            }
        }

        // Lip
        translate([x_plate_offset, 0, 0]) {
            translate([width / 2, depth + y_offset - wall_thickness, height - lip_thickness])
                front_half()
                    xcyl(width - (2 * wall_thickness), r=lip_thickness);

            translate([wall_thickness, y_offset, height - lip_thickness])
                right_half()
                    ycyl(depth - wall_thickness, r=lip_thickness, anchor=FRONT);

            translate([width - wall_thickness, y_offset, height - lip_thickness])
                left_half()
                    ycyl(depth - wall_thickness, r=lip_thickness, anchor=FRONT);
        }
    }
}


bin(
    width=width,
    depth=depth,
    height=height,
    wall_thickness=wall_thickness,
    bottom_thickness=bottom_thickness,
    lip_thickness=lip_thickness,
    inner_rounding=inner_rounding,
    outer_rounding=outer_rounding,
    hanger_tolerance=hanger_tolerance,
    variant=variant
);
