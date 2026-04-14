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
        translate([-0.1, hanger_thickness, 0])
            rotate([135, 0, 0])
                linear_extrude(hanger_thickness)
                    square([hanger_width + 0.2, hanger_thickness * 2]);

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
        translate([hanger_width / 2, -0.1, hanger_bolt_notch_center_height])
            rotate([270, 0, 0])
                linear_extrude(height = hanger_total_thickness + 0.2)
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
    extend_bottom=0,
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
    outer_radius=plate_outer_radius,
    plate_side_tolerance=plate_side_tolerance,  // Add tolerance to sides to make it easier to have multiple units next to each other
) {
    hanger_plate_offset = get_hanger_plate_offset(variant, hanger_tolerance);
    hanger_total_thickness = hanger_thickness + hanger_plate_offset;
    total_plate_width = hanger_units * plate_width;
    total_plate_height = plate_height + extend_bottom;

    difference() {
        // Main hanger plates
        union() {
            for (i = [0:hanger_units - 1]) {
                // Plate with hanger
                translate([(plate_width) * i, 0, 0])
                    hanger_plate_unit(
                        variant=variant,
                        plate_thickness=plate_thickness,
                        hanger_tolerance=hanger_tolerance,
                        extend_bottom=extend_bottom,
                        bolt_notch=bolt_notch,
                    );
            }
        }

        if (plate_side_tolerance) {
            translate([-0.1, 0, 0])
                cube([plate_side_tolerance + 0.1, hanger_total_thickness + plate_thickness + 0.1, total_plate_height + 0.1]);
            translate([total_plate_width - plate_side_tolerance, 0, 0])
                cube([plate_side_tolerance + 0.1, hanger_total_thickness + plate_thickness + 0.1, total_plate_height + 0.1]);
        }

        if (outer_radius) {
            // Outer roundovers
            translate([plate_side_tolerance, hanger_total_thickness + plate_thickness + 0.1, total_plate_height])
                rotate([90, 90, 0])
                    rounding_edge_mask(l=plate_thickness + 0.2, r=outer_radius, anchor=BOTTOM);
            translate([total_plate_width - plate_side_tolerance, hanger_total_thickness + plate_thickness + 0.1, total_plate_height])
                rotate([90, 180, 0])
                    rounding_edge_mask(l=plate_thickness + 0.2, r=outer_radius, anchor=BOTTOM);
        }
    }
}
