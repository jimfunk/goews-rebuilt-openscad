include <BOSL2/std.scad>

include <constants.scad>


// The hanger part. This is the profile that fits inside the tile
module hanger(variant=variant_original, hanger_tolerance, extended_bottom=false) {
    midpoint = hanger_thickness / 2;
    hanger_plate_offset = get_hanger_plate_offset(variant, hanger_tolerance=hanger_tolerance);
    hanger_total_thickness = hanger_thickness + hanger_plate_offset;

    difference() {
        union() {
            // Main hanger profile
            linear_extrude(height=hanger_height)
                polygon(points = [
                    [midpoint, 0],
                    [0, midpoint],
                    [midpoint, hanger_thickness],
                    [hanger_width - midpoint, hanger_thickness],
                    [hanger_width, midpoint],
                    [hanger_width - midpoint, 0],
                ]);

            // Plate offset
            linear_extrude(height=hanger_height)
                translate([hanger_thickness / 2, hanger_thickness, 0])
                    square(size=[hanger_width - hanger_thickness, hanger_plate_offset]);

        }

        // Rear chamfer
        translate([0, hanger_thickness, 0])
            rotate([135, 0, 0])
                linear_extrude(hanger_thickness)
                    square([hanger_width, hanger_thickness * 2]);

        // Rear tile cutoff (only on thicker cleats)
        if (variant == variant_thicker_cleats) {
            rear_cutoff = hanger_total_thickness - tile_thickness;
            linear_extrude(height = hanger_height)
                square([hanger_width, rear_cutoff]);
        }

        // Bottom chamfer (only if thicker cleats and the hanger is above the build plate)
        if (extended_bottom && variant == variant_thicker_cleats) {
            translate([0, hanger_total_thickness, 0])
                wedge(
                    [hanger_width, hanger_plate_offset + midpoint, midpoint],
                    anchor=DOWN+LEFT+BACK
                );
        }

        // Cutout
        translate([hanger_width / 2, 0, hanger_bolt_notch_center_height])
            rotate([270, 0, 0])
                linear_extrude(height = hanger_total_thickness)
                    circle(r=hanger_bolt_notch_radius);
    }
}

// The plate with a hanger attached to the back but without the outer rounding
module hanger_plate_unit(
    variant=variant_original,
    plate_thickness=default_plate_thickness,
    bolt_notch=true,
    bolt_notch_thickness=default_plate_thickness,
    hanger_tolerance=0.15,
    extend_bottom=0
) {
    hanger_plate_offset = get_hanger_plate_offset(variant, hanger_tolerance);
    hanger_total_thickness = hanger_thickness + hanger_plate_offset;
    total_plate_height = plate_height + extend_bottom;
    extended_bottom = extend_bottom > 0 ? true : false;

    translate([(plate_width - hanger_width) / 2, 0, extend_bottom]) {
        hanger(
            variant=variant,
            hanger_tolerance=hanger_tolerance,
            extended_bottom=extend_bottom
        );
    }

    // Main plate
    translate([plate_width, hanger_total_thickness, 0])
        rotate([90, 0, 180])
            difference() {
                linear_extrude(height=plate_thickness) {
                    difference() {
                        square([plate_width, total_plate_height]);
                        if (bolt_notch) {
                            union() {
                                translate([plate_width / 2, plate_cutout_y_offset + extend_bottom])
                                    circle(plate_cutout_radius);
                                translate([(plate_width / 2) - plate_cutout_radius + plate_inner_radius_offset, total_plate_height])
                                    mask2d_roundover(
                                        r=plate_inner_radius / 2,
                                        spin=180
                                    );
                                translate([(plate_width / 2) + plate_cutout_radius - plate_inner_radius_offset, total_plate_height])
                                    rotate([0, 0, 90])
                                        mask2d_roundover(
                                            r=plate_inner_radius / 2,
                                            spin=180
                                        );
                            }
                        }
                    }
                }
                if (bolt_notch)
                    translate([plate_width / 2, plate_cutout_y_offset + extend_bottom, bolt_notch_thickness])
                        cylinder(d=hanger_bolt_notch_head_clearance_diameter, h=plate_thickness - bolt_notch_thickness);
            }
}


// The plate with a hanger attached to the back
module hanger_plate(
    variant=variant_original,
    plate_thickness=default_plate_thickness,
    bolt_notch=true,
    bolt_notch_thickness=default_plate_thickness,
    hanger_units=1,
    hanger_tolerance=0.15,
    extend_bottom=0,
    outer_radius=plate_outer_radius
) {
    hanger_plate_offset = get_hanger_plate_offset(variant, hanger_tolerance);
    hanger_total_thickness = hanger_thickness + hanger_plate_offset;
    total_plate_width = (hanger_units * plate_width) + ((hanger_units - 1) * plate_gap) ;
    total_plate_height = plate_height + extend_bottom;

    difference() {
        // Main hanger plates
        union() {
            for (i = [0:hanger_units - 1]) {
                // Plate with hanger
                translate([(plate_width + plate_gap) * i, 0, 0])
                    hanger_plate_unit(
                        variant=variant,
                        plate_thickness=plate_thickness,
                        hanger_tolerance=hanger_tolerance,
                        extend_bottom=extend_bottom,
                        bolt_notch=bolt_notch
                    );
                // Fill the gaps if we have multiple hangers
                if (i > 0 && i < hanger_units) {
                    translate([((plate_width + plate_gap) * (i - 1)) + plate_width, hanger_total_thickness, 0])
                        cube([plate_gap, plate_thickness, total_plate_height]);
                }
            }
        }

        if (outer_radius) {
            // Outer roundovers
            translate([0, hanger_total_thickness + plate_thickness, total_plate_height])
                rotate([90, 90, 0])
                    rounding_edge_mask(l=plate_thickness, r=outer_radius, anchor=BOTTOM);
            translate([total_plate_width, hanger_total_thickness + plate_thickness, total_plate_height])
                rotate([90, 180, 0])
                    rounding_edge_mask(l=plate_thickness, r=outer_radius, anchor=BOTTOM);
        }
    }
}

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
    full_plate_width = (units * plate_width) + ((units > 0 ? units - 1 : 0) * plate_gap);
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
