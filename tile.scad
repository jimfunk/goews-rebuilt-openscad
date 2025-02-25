include <BOSL2/std.scad>
include <BOSL2/lists.scad>
include <BOSL2/threading.scad>

include <constants.scad>


module tile_cleat(variant=variant_original) {
    difference() {
        translate([0, 0, tile_hanger_cleat_width])
            union() {
                if (variant == variant_thicker_cleats) {
                    linear_extrude(height = hanger_offset)
                        square([tile_hanger_cleat_width, tile_hanger_cleat_lower_height + tile_hanger_cleat_width]);
                }
                rotate([270, 0, 0])
                    linear_extrude(height = tile_hanger_cleat_lower_height + tile_hanger_cleat_width)
                        polygon(
                            points=[
                                [0, 0],
                                [tile_hanger_cleat_width, 0],
                                [0, tile_hanger_cleat_width]
                            ]
                        );
            }
        linear_extrude(height = tile_hanger_cleat_width + hanger_offset)
            polygon(
                points = [
                    [0, tile_hanger_cleat_lower_height + tile_hanger_cleat_width],
                    [tile_hanger_cleat_width, tile_hanger_cleat_lower_height + tile_hanger_cleat_width],
                    [tile_hanger_cleat_width, tile_hanger_cleat_lower_height],
                ]
            );
    }
}


module hex_tile_single(
    variant=variant_original,
    mounting_hole_shank_diameter=4,
    mounting_hole_head_diameter=8,
    mounting_hole_inset_depth=1,
    mounting_hole_countersink_depth=2
) {
    rear_cleat_thickness = variant == variant_original ? tile_hanger_rear_cleat_thickness : 0;
    cleat_additional_thickness = variant == variant_thicker_cleats ? hanger_offset : 0;
    hanger_x_offset = (tile_width - tile_hanger_width) / 2;
    tile_hanger_y_offset = tile_triangle_height;
    threaded_hole_center_x = tile_width / 2;
    threaded_hole_center_y = tile_height - tile_threaded_hole_y_offset;
    mounting_hole_center_x = tile_width / 2;
    mounting_hole_center_y = tile_mounting_hole_y_offset;

    difference() {
        // Outer hex tile
        translate([tile_width / 2, tile_width / sqrt(3), 0])
            rotate([0, 0, 90])
                regular_prism(n=6, h=tile_thickness, id=tile_width, center=false, chamfer2=0.5);

        // Space for hanger
        linear_extrude(height=tile_thickness)
            difference() {
                translate([hanger_x_offset, tile_hanger_y_offset, 0])
                    square([tile_hanger_width, tile_hanger_height]);
                translate([threaded_hole_center_x, threaded_hole_center_y, 0])
                    circle(tile_hanger_hole_outer_diameter);
            }

        // Threaded hole
        translate([threaded_hole_center_x, threaded_hole_center_y, 0])
            threaded_rod(
                d=thread_diameter + thread_tolerance,
                length=tile_thickness,
                pitch=thread_pitch,
                internal=true,
                blunt_start=false,
                anchor=BOTTOM
            );

        // Mounting hole
        translate([mounting_hole_center_x, mounting_hole_center_y, 0]) {
            cylinder(h=tile_thickness, d=mounting_hole_shank_diameter);
            translate([0, 0, tile_thickness - mounting_hole_inset_depth])
                cylinder(h=mounting_hole_inset_depth, d=mounting_hole_head_diameter);
            if (mounting_hole_countersink_depth > 0) {
                translate([0, 0, tile_thickness - mounting_hole_inset_depth])
                    zcyl(h=mounting_hole_countersink_depth, d1=mounting_hole_shank_diameter, d2=mounting_hole_head_diameter, anchor=TOP);
            }
        }
    }

    // Left rear chamfer
    translate([hanger_x_offset, tile_triangle_height, rear_cleat_thickness])
        rotate([90, 270, 180])
            linear_extrude(height = tile_hanger_height)
                polygon(
                    points=[
                        [0, 0],
                        [hanger_thickness / 2, 0],
                        [0, hanger_thickness / 2]
                    ]
                );

    // Left front cleat
    translate([hanger_x_offset, tile_hanger_y_offset, (hanger_thickness / 2) + rear_cleat_thickness])
        tile_cleat(variant=variant);

    // Right rear chamfer
    translate([tile_width - hanger_x_offset, tile_triangle_height + tile_hanger_height, rear_cleat_thickness])
        rotate([0, 270, 90])
            linear_extrude(height = tile_hanger_height)
                polygon(
                    points=[
                        [0, 0],
                        [hanger_thickness / 2, 0],
                        [0, hanger_thickness / 2],
                    ]
                );

    // Right front cleat
    translate([hanger_x_offset + tile_hanger_width, tile_hanger_y_offset, (hanger_thickness / 2) + rear_cleat_thickness])
        xflip() tile_cleat(variant=variant);

    // Lower rear chamfer
    translate([hanger_x_offset + tile_hanger_width, tile_triangle_height])
        rotate([0, 270, 0])
            linear_extrude(height = tile_hanger_width)
                polygon(
                    points=[
                        [0, 0],
                        [hanger_thickness - cleat_additional_thickness + rear_cleat_thickness, 0],
                        [0, hanger_thickness - cleat_additional_thickness + rear_cleat_thickness]
                    ]
                );

    // Rear cleats (Only for the original variant)
    if (variant == variant_original) {
        translate([0, tile_triangle_height, 0])
            linear_extrude(height = tile_hanger_rear_cleat_thickness)
                square([tile_hanger_rear_cleat_x_offset, tile_hanger_height]);
        translate([tile_width - tile_hanger_rear_cleat_x_offset, tile_triangle_height, 0])
            linear_extrude(height = tile_hanger_rear_cleat_thickness)
                square([tile_hanger_rear_cleat_x_offset, tile_hanger_height]);
    }
}


module hex_fill_top(
    crop_left=false,
    crop_right=false,
    mounting_hole_shank_diameter=4,
    mounting_hole_head_diameter=8,
    mounting_hole_inset_depth=1,
    mounting_hole_countersink_depth=2
) {
    mounting_hole_center_x = tile_width / 2;
    mounting_hole_center_y = tile_mounting_hole_y_offset;

    difference() {
        // Body
        translate([tile_width / 2, tile_width / sqrt(3), 0])
            rotate([0, 0, 90])
                regular_prism(n=6, h=tile_thickness, id=tile_width, center=false, chamfer2=0.5);

        // Crop top
        translate([0, tile_triangle_height, 0])
            cube([tile_width, tile_height - tile_triangle_height, tile_thickness]);

        // Top chamfer
        translate([tile_width / 2, tile_triangle_height, tile_thickness])
            chamfer_edge_mask(l=tile_width, chamfer=0.5, orient=RIGHT);

        if (! (crop_left || crop_right)) {
            // Mounting hole
            translate([mounting_hole_center_x, mounting_hole_center_y, 0]) {
                cylinder(h=tile_thickness, d=mounting_hole_shank_diameter);
                translate([0, 0, tile_thickness - mounting_hole_inset_depth])
                    cylinder(h=mounting_hole_inset_depth, d=mounting_hole_head_diameter);
                translate([0, 0, tile_thickness - mounting_hole_inset_depth])
                    zcyl(h=mounting_hole_countersink_depth, d1=mounting_hole_shank_diameter, d2=mounting_hole_head_diameter, anchor=TOP);
            }
        }

        if (crop_left) {
            // Crop left side
            translate([0, 0, 0])
                cube([tile_width / 2, tile_height, tile_thickness]);
            // Left chamfer
            translate([tile_width / 2, tile_height / 2, tile_thickness])
                chamfer_edge_mask(l=tile_height, chamfer=0.5, orient=FRONT);
        }

        if (crop_right) {
            // Crop right side
            translate([tile_width / 2, 0, 0])
                cube([tile_width / 2, tile_height, tile_thickness]);
            // Right chamfer
            translate([tile_width / 2, tile_height / 2, tile_thickness])
                chamfer_edge_mask(l=tile_height, chamfer=0.5, orient=FRONT);
        }
    }
}

module hex_fill_bottom(crop_left=false, crop_right=false) {
    difference() {
        // Body
        translate([tile_width / 2, tile_triangle_height - (tile_height / 2), 0])
            rotate([0, 0, 90])
                regular_prism(n=6, h=tile_thickness, id=tile_width, center=false, chamfer2=0.5);

        // Crop bottom
        translate([0, -(tile_height - tile_triangle_height), 0])
            cube([tile_width, tile_height - tile_triangle_height, tile_thickness]);

        // Bottom chamfer
        translate([tile_width / 2, 0, tile_thickness])
            chamfer_edge_mask(l=tile_width, chamfer=0.5, orient=RIGHT);

        if (crop_left) {
            // Crop left side
            translate([0, 0, 0])
                cube([tile_width / 2, tile_height, tile_thickness]);
            // Left chamfer
            translate([tile_width / 2, tile_height / 2, tile_thickness])
                chamfer_edge_mask(l=tile_height, chamfer=0.5, orient=FRONT);
        }

        if (crop_right) {
            // Crop right side
            translate([tile_width / 2, 0, 0])
                cube([tile_width / 2, tile_height, tile_thickness]);
            // Right chamfer
            translate([tile_width / 2, tile_height / 2, tile_thickness])
                chamfer_edge_mask(l=tile_height, chamfer=0.5, orient=FRONT);
        }
    }
}


module hex_fill_left() {
    difference() {
        translate([0, tile_height / 2, 0])
            rotate([0, 0, 90])
                regular_prism(n=6, h=tile_thickness, id=tile_width, center=false, chamfer2=0.5);
        translate([- (tile_width / 2), 0, 0])
            cube([tile_width / 2, tile_height, tile_thickness]);
        translate([0, tile_height / 2, tile_thickness])
            chamfer_edge_mask(l=tile_height, chamfer=0.5, orient=FRONT);
    }
}


module hex_fill_right() {
    difference() {
        translate([tile_width / 2, tile_height / 2, 0])
            rotate([0, 0, 90])
                regular_prism(n=6, h=tile_thickness, id=tile_width, center=false, chamfer2=0.5);
        translate([(tile_width / 2), 0, 0])
            cube([tile_width / 2, tile_height, tile_thickness]);
        translate([tile_width / 2, tile_height / 2, tile_thickness])
            chamfer_edge_mask(l=tile_height, chamfer=0.5, orient=FRONT);
    }
}


module tile(
    variant=variant_original,
    columns=4,
    rows=4,
    fill_top=false,
    fill_bottom=false,
    fill_left=false,
    fill_right=false,
    mounting_hole_shank_diameter=4,
    mounting_hole_head_diameter=8,
    mounting_hole_inset_depth=1,
    mounting_hole_countersink_depth=2,
    skiplist=[]
) {
    for (row = [0 : rows - 1]) {
        offset_x = (row % 2 == 0) ? tile_width / 2 : 0;

        for (column = [0 : columns - 1]) {
            pos_x = offset_x + column * tile_width;
            pos_y = row * tile_y_offset;

            if (!in_list([row + 1, column + 1], skiplist)) {
                translate([pos_x, pos_y, 0])
                    hex_tile_single(
                        variant=variant,
                        mounting_hole_shank_diameter=mounting_hole_shank_diameter,
                        mounting_hole_head_diameter=mounting_hole_head_diameter,
                        mounting_hole_countersink_depth=mounting_hole_countersink_depth,
                        mounting_hole_inset_depth=mounting_hole_inset_depth
                    );
            }
            if (fill_left && column == 0 && offset_x) {
                translate([0, pos_y, 0])
                    hex_fill_left();
            }
            if (fill_right && column == (columns -1 ) && !offset_x) {
                translate([pos_x + tile_width, pos_y, 0])
                    hex_fill_right();
            }
        }

        if (fill_top && row == (rows - 1)) {
            // Fill in top row
            even_row = (row + 1) % 2 == 0;
            offset_x = even_row ? tile_width / 2 : tile_width;
            crop_left = (column == 0 && ! fill_left);

            for (column = [0 : columns]) {
                pos_x = (offset_x + column * tile_width) - tile_width;
                pos_y = tile_y_offset * (row + 1);
                translate([pos_x, pos_y, 0])
                    hex_fill_top(
                        crop_left=(column == 0 && (!fill_left || even_row)),
                        crop_right=(column == columns && (!fill_right || !even_row))
                    );
            }
        }

        if (fill_bottom && row == 0) {
            // Fill in bottom row
            offset_x = ((row + 1) % 2 == 0) ? tile_width / 2 : 0;

            for (column = [0 : columns]) {
                pos_x = (offset_x + column * tile_width);
                pos_y = tile_y_offset * (row);
                translate([pos_x, pos_y, 0])
                    hex_fill_bottom(
                        crop_left=(column == 0 && !fill_left),
                        crop_right=(column == columns)
                    );
            }
        }
    }
}


/*
 * Print time and filament use comparisons
 *
 * Original 6x6: 8 hours 2 minutes, 129g
 * Rebuilt original 6x6: 7 hours 3 minutes, 120g (7.0% reduction in filament)
 * Rebuilt thicker cleats 6x6: 6 hours 40 minutes, 111g (14.0% reduction in filament)
 *
 * Original 4x4: 3 hours 36 minutes, 58g
 * Original lite 4x4: 2 hours 54 minutes, 53g (8.6% reduction in filament)
 * Rebuilt original 4x4: 3 hours 11 minutes, 54g (6.9% reduction in filament)
 * Rebuilt thicker cleats 4x4: 3 hours 1 minute, 50g (13.8% reduction in filament)
 */
