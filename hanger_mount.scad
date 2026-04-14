include <BOSL2/std.scad>

include <constants.scad>
include <parsers.scad>
use <hanger.scad>


/* [Primary parameters] */
// Which variant to use
variant = 0; // [0: Original, 1: Thicker cleats]

// Added to hangers to allow for easier insertion and removal. This can be reduced to make hanger plates tighter to the tile. It reduces the tilt but makes them harder to insert and remove
hanger_tolerance = 0.15;

/* [Hanger mount parameters] */
// Each entry is a 5-tuple of (hole type, x offset from left, y offset from top, diameter, depth), eg: [2, 20.75, 17.5, 5, 8] for an M5 hole in the center of the bottom part with a hex nut recess
hanger_mount_holes = "[[2, 20.75, 17.5, 4, 8]]";

// Thickness of the hanger mount plate. You may have to manually adjust this based on the mounting hardware and the position of the holes
hanger_mount_plate_thickness = 8;

// Minimum width of the plate. If more than a standard plate width, it will be extended on the right side with more plate units
hanger_mount_minimum_width = 0;

// Minimum height of the plate. If more than a standard plate height, it will be extended downwards
hanger_mount_minimum_height = 0;

// Include a notch for the bolt. This allows for flush mounting
hanger_mount_bolt_notch = true;


/* [Hidden] */
$fa=0.5;
$fs=0.5;


// A plate with custom mounting holes. Each hole is expected to be a vector:
//  [
//    hole type,
//    center distance from left of plate,
//    center distance from top of plate,
//    hole diameter,
//    hole depth,
//  ]
module hanger_mount(
    holes=[],
    plate_thickness=default_plate_thickness,
    minimum_width=0,
    minimum_height=0,
    bolt_notch=true,
    bolt_notch_thickness=default_plate_thickness,
    hanger_tolerance=0.15,
    variant=variant_original
) {
    hanger_plate_offset = get_hanger_plate_offset(variant, hanger_tolerance);
    hanger_total_thickness = hanger_thickness + hanger_plate_offset;
    plate_total_thickness = plate_thickness + hanger_total_thickness;

    // Extend the width to accomodate the furthest hole or the minimum width
    hole_x_extents = [ for (hole = holes) hole[1] + hole[3] ];
    needed_plate_width = holes ? max(max(hole_x_extents), minimum_width) : minimum_width;
    units = needed_plate_width ? get_hanger_units_from_width(needed_plate_width) : 1;

    // We automatically extend the bottom if the lowest hole requires it, otherwise
    // use the minimum height
    hole_y_extents = [ for (hole = holes) hole[2] + hole[3] ];
    needed_plate_height = holes ? max(max(hole_y_extents), minimum_height) : minimum_height;
    extend_bottom = (needed_plate_height > plate_height) ? needed_plate_height - plate_height : 0;

    // We are referencing the holes from the left top of the plate, so we need to know
    // the full width and height
    full_plate_width = units * plate_width;
    full_plate_height = max(plate_height, needed_plate_height);

    difference() {
        hanger_plate(
            variant=variant,
            plate_thickness=plate_thickness,
            extend_bottom=extend_bottom,
            hanger_units=units,
            hanger_tolerance=hanger_tolerance,
            bolt_notch=bolt_notch
        );

        for (hole = holes) {
            hole_type = hole[0];
            hole_x = full_plate_width - hole[1];
            hole_z = full_plate_height - hole[2];

            hole_diameter = hole[3];
            hole_depth = hole[4];

            // Main hole
            translate([hole_x, plate_total_thickness, hole_z])
                ycyl(d=hole_diameter, h=hole_depth, anchor=BACK);

            // Nut insert or hex head if specified
            if (hole_type == hole_type_hex_nut || hole_type == hole_type_square_nut) {
                nut_width = get_hex_nut_width(hole_diameter);
                nut_thickness = get_hex_nut_thickness(hole_diameter);
                nut_depth = plate_total_thickness - hole_depth;
                nut_offset = hole_depth * -1;
                nut_sides = hole_type == hole_type_hex_nut ? 6 : 4;

                translate([hole_x, plate_total_thickness, hole_z])
                    union() {
                        translate([0, nut_offset, 0])
                            rotate([90, 0, 0])
                                regular_prism(n=nut_sides, id=nut_width, l=nut_depth, anchor=BOTTOM, spin=90);
                    }
            }

            // DIN912 socket head
            if (hole_type == hole_type_din912_socket_head) {
                head_diameter = get_din912_socket_head_diameter(hole_diameter);
                head_depth = plate_total_thickness - hole_depth;
                translate([hole_x, plate_total_thickness - hole_depth, hole_z])
                    ycyl(
                        d=head_diameter + 0.4,
                        h=head_depth,
                        anchor=BACK
                    );
            }

            // ISO 7380-1 button head
            if (hole_type == hole_type_iso7380_button_head) {
                head_diameter = get_iso7380_button_head_diameter(hole_diameter);
                head_depth = plate_total_thickness - hole_depth;
                translate([hole_x, plate_total_thickness - hole_depth, hole_z])
                    ycyl(
                        d=head_diameter + 0.4,
                        h=head_depth,
                        anchor=BACK
                    );
            }

            // DIN 7991 countersunk head
            if (hole_type == hole_type_din7991_countersink_head) {
                head_diameter = get_iso7380_button_head_diameter(hole_diameter);
                head_height = get_din7991_countersink_head_height(hole_diameter);
                head_clearance_depth = plate_total_thickness - hole_depth;

                union() {
                    translate([hole_x, plate_total_thickness - hole_depth, hole_z])
                        ycyl(
                            d=head_diameter + 0.4,
                            h=head_clearance_depth,
                            anchor=BACK
                        );
                    translate([hole_x, plate_total_thickness - hole_depth, hole_z])
                        #ycyl(
                            d1=head_diameter,
                            d2=hole_diameter,
                            h=head_height,
                            anchor=FRONT
                        );
                }
            }
        }
    }
}


hanger_mount(
    holes=parse_vector_list(hanger_mount_holes),
    plate_thickness=hanger_mount_plate_thickness,
    minimum_width=hanger_mount_minimum_width,
    minimum_height=hanger_mount_minimum_height,
    bolt_notch=hanger_mount_bolt_notch,
    hanger_tolerance=hanger_tolerance,
    variant=variant
);
