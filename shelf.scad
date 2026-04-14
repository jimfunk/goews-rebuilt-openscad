include <BOSL2/std.scad>
include <BOSL2/shapes3d.scad>

include <constants.scad>
use <hanger.scad>


/* [Primary parameters] */
// Which variant to use
variant = 0; // [0: Original, 1: Thicker cleats]

// Added to hangers to allow for easier insertion and removal. This can be reduced to make hanger plates tighter to the tile. It reduces the tilt but makes them harder to insert and remove
hanger_tolerance = 0.15;

/* [Shelf parameters] */
// Shelf width
width = 83.5;

// Shelf depth
depth = 30;

// Shelf thickness
thickness = 4;

// Shelf rear fillet radius in mm
rear_fillet_radius = 1;

// Shelf rounding on the front edges in mm
rounding = 0.5;


/* [Hidden] */
$fa=0.5;
$fs=0.5;


module shelf(
    width=10,
    depth=10,
    thickness=4,
    rear_fillet_radius=1,
    rounding=0.5,
    hanger_tolerance=0.15,
    variant=variant_original
) {
    hanger_plate_offset = get_hanger_plate_offset(variant, hanger_tolerance);
    hanger_total_thickness = hanger_thickness + hanger_plate_offset;
    plate_total_thickness = default_plate_thickness + hanger_total_thickness;

    x_offset = get_hanger_plate_width(width) / 2;
    y_offset = plate_total_thickness;

    union() {
        hanger_plate(
            variant=variant,
            hanger_units=get_hanger_units_from_width(width),
            hanger_tolerance=hanger_tolerance
        );

        // Shelf
        translate([x_offset, y_offset, 0]) {
            cuboid(
                [width, depth, thickness],
                anchor=BOTTOM+FRONT,
                rounding=rounding,
                edges=[BACK]
            );
        }

        // Rear fillet
        translate([x_offset, y_offset, thickness]) {
            fillet(l=width, r=rear_fillet_radius, orient=LEFT);
        }
    }
}


shelf(
    width=width,
    depth=depth,
    thickness=thickness,
    rear_fillet_radius=rear_fillet_radius,
    rounding=rounding,
    hanger_tolerance=hanger_tolerance,
    variant=variant
);
