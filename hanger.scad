include <BOSL2/std.scad>

include <constants.scad>


// The hanger part. This is the profile that fits inside the tile
module hanger(variant=variant_original, hanger_tolerance) {
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
            rear_cutoff = hanger_thickness + hanger_offset - tile_thickness;
            linear_extrude(height = hanger_height)
                square([hanger_width, rear_cutoff]);
        }

        // Cutout
        translate([hanger_width / 2, 0, hanger_cutout_center_height])
            rotate([270, 0, 0])
                linear_extrude(height = hanger_total_thickness)
                    circle(r=hanger_cutout_radius);
    }
}

// The plate with a hanger attached to the back
module hanger_plate(variant=variant_original, hanger_tolerance) {
    hanger_plate_offset = get_hanger_plate_offset(variant, hanger_tolerance);
    hanger_total_thickness = hanger_thickness + hanger_plate_offset;

    translate([(plate_width - hanger_width) / 2, 0, 0]) {
        hanger(variant=variant, hanger_tolerance=hanger_tolerance);
    }

    // Main plate
    translate([plate_width, hanger_total_thickness, 0])
        rotate([90, 0, 180])
            linear_extrude(height=plate_thickness)
                difference() {
                    hull() {
                        square([plate_width, plate_height - plate_outer_radius]);
                        translate([plate_outer_radius, plate_height - plate_outer_radius, 0])
                            circle(3);
                        translate([plate_width - plate_outer_radius, plate_height - plate_outer_radius, 0])
                            circle(3);
                    }
                    union() {
                        translate([plate_width / 2, plate_cutout_y_offset])
                            circle(plate_cutout_radius);
                        translate([(plate_width / 2) - plate_cutout_radius + plate_inner_radius_offset, plate_height])
                            mask2d_roundover(
                                r=plate_inner_radius / 2,
                                spin=180
                            );
                        translate([(plate_width / 2) + plate_cutout_radius - plate_inner_radius_offset, plate_height])
                            rotate([0, 0, 90])
                                mask2d_roundover(
                                    r=plate_inner_radius / 2,
                                    spin=180
                                );
                    }
                }
}
