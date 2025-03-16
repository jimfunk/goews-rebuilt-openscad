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


module mounting_hole(
    mounting_hole_shank_diameter=4,
    mounting_hole_head_diameter=8,
    mounting_hole_inset_depth=1,
    mounting_hole_countersink_depth=2,
) {
        cylinder(h=tile_thickness, d=mounting_hole_shank_diameter);
        translate([0, 0, tile_thickness - mounting_hole_inset_depth])
            cylinder(h=mounting_hole_inset_depth, d=mounting_hole_head_diameter);
        if (mounting_hole_countersink_depth > 0) {
            translate([0, 0, tile_thickness - mounting_hole_inset_depth])
                zcyl(h=mounting_hole_countersink_depth, d1=mounting_hole_shank_diameter, d2=mounting_hole_head_diameter, anchor=TOP);
        }
}


module hex_tile_single(
    variant=variant_original,
    mounting_hole_shank_diameter=4,
    mounting_hole_head_diameter=8,
    mounting_hole_inset_depth=1,
    mounting_hole_countersink_depth=2,
    cut_outside_corners=false,
    chamfer_rear=false,
    left_outside=false,
    left_inside=false,
    right_outside=false,
    right_inside=false,
    bottom=false,
    top=false,
    fill_bottom=false,
    fill_top=false,
    fill_left=false,
    fill_right=false
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
            diff() {
                regular_prism(n=6, h=tile_thickness, id=tile_width, center=false, chamfer2=0.5) {
                    tag("remove") {
                        if (cut_outside_corners && ((right_outside && !fill_right) || (right_inside && top && !fill_top && !fill_right))) {
                            attach("edge1")
                                translate([0, tile_thickness / 2, 0])
                                    cuboid([2, tile_thickness, .75]);
                        }
                        if (cut_outside_corners && right_outside && !fill_right && !(bottom && fill_bottom)) {
                            attach("edge2")
                                translate([0, tile_thickness / 2, 0])
                                    cuboid([2, tile_thickness, .75]);
                        }
                        if (cut_outside_corners && ((left_outside && !fill_left) || (left_inside && bottom && !fill_bottom && !fill_left))) {
                            attach("edge4")
                                translate([0, tile_thickness / 2, 0])
                                    cuboid([2, tile_thickness, .75]);
                        }
                        if (cut_outside_corners && left_outside && !fill_left && !(top &&  fill_top)) {
                            attach("edge5")
                                translate([0, tile_thickness / 2, 0])
                                    cuboid([2, tile_thickness, .75]);
                        }
                        if (chamfer_rear && ((right_outside && !fill_right) || (top && !fill_top))) {
                            attach("bot_edge0")
                                cuboid([tile_thickness, tile_width, 5]);
                        }
                        if (chamfer_rear && ((right_outside) || (right_inside && !fill_right))) {
                            attach("bot_edge1")
                                cuboid([tile_thickness, tile_width, 5]);
                        }
                        if (chamfer_rear && ((right_outside && !fill_right && !(bottom && fill_bottom)) || (bottom && !fill_bottom))) {
                            attach("bot_edge2")
                                cuboid([tile_thickness, tile_width, 5]);
                        }
                        if (chamfer_rear && ((left_outside && !fill_left) || (bottom && !fill_bottom))) {
                            attach("bot_edge3")
                                cuboid([tile_thickness, tile_width, 5]);
                        }
                        if (chamfer_rear && ((left_outside) || (left_inside && !fill_left))) {
                            attach("bot_edge4")
                                cuboid([tile_thickness, tile_width, 5]);
                        }
                        if (chamfer_rear && ((left_outside && !fill_left && !(top && fill_top)) || (top && !fill_top))) {
                            attach("bot_edge5")
                                cuboid([tile_thickness, tile_width, 5]);
                        }
                    }
                }
            }

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
            mounting_hole(
                mounting_hole_shank_diameter=mounting_hole_shank_diameter,
                mounting_hole_head_diameter=mounting_hole_head_diameter,
                mounting_hole_inset_depth=mounting_hole_inset_depth,
                mounting_hole_countersink_depth=mounting_hole_countersink_depth
            );
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
        translate([1, tile_triangle_height, 0])
            linear_extrude(height = tile_hanger_rear_cleat_thickness)
                square([tile_hanger_rear_cleat_x_offset-1, tile_hanger_height]);
        translate([tile_width - tile_hanger_rear_cleat_x_offset, tile_triangle_height, 0])
            linear_extrude(height = tile_hanger_rear_cleat_thickness)
                square([tile_hanger_rear_cleat_x_offset - 1, tile_hanger_height]);
    }
}


module hex_fill_top(
    crop_left=false,
    crop_right=false,
    mounting_hole_shank_diameter=4,
    mounting_hole_head_diameter=8,
    mounting_hole_inset_depth=1,
    mounting_hole_countersink_depth=2,
    chamfer_rear=false
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
        if (chamfer_rear) {
            translate([tile_width / 2, tile_triangle_height, 0])
                chamfer_edge_mask(l=tile_width, chamfer=0.5, orient=RIGHT);
        }

        if (! (crop_left || crop_right)) {
            // Mounting hole
            translate([mounting_hole_center_x, mounting_hole_center_y, 0]) {
                mounting_hole(
                    mounting_hole_shank_diameter=mounting_hole_shank_diameter,
                    mounting_hole_head_diameter=mounting_hole_head_diameter,
                    mounting_hole_inset_depth=mounting_hole_inset_depth,
                    mounting_hole_countersink_depth=mounting_hole_countersink_depth
                );
            }
        }

        if (crop_left) {
            // Crop left side
            translate([0, 0, 0])
                cube([tile_width / 2, tile_height, tile_thickness]);
            // Left chamfer
            translate([tile_width / 2, tile_height / 2, tile_thickness])
                chamfer_edge_mask(l=tile_height, chamfer=0.5, orient=FRONT);
            if (chamfer_rear) {
                translate([tile_width / 2, tile_height / 2, 0])
                    chamfer_edge_mask(l=tile_height, chamfer=0.5, orient=FRONT);
            }
        }

        if (crop_right) {
            // Crop right side
            translate([tile_width / 2, 0, 0])
                cube([tile_width / 2, tile_height, tile_thickness]);
            // Right chamfer
            translate([tile_width / 2, tile_height / 2, tile_thickness])
                chamfer_edge_mask(l=tile_height, chamfer=0.5, orient=FRONT);
            if (chamfer_rear) {
                translate([tile_width / 2, tile_height / 2, 0])
                    chamfer_edge_mask(l=tile_height, chamfer=0.5, orient=FRONT);
            }
        }
    }
}

module hex_fill_bottom(
    crop_left=false,
    crop_right=false,
    chamfer_rear=false
) {
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
        if (chamfer_rear) {
            translate([tile_width / 2, 0, 0])
                chamfer_edge_mask(l=tile_width, chamfer=0.5, orient=RIGHT);
        }

        if (crop_left) {
            // Crop left side
            translate([0, 0, 0])
                cube([tile_width / 2, tile_height, tile_thickness]);
            // Left chamfer
            translate([tile_width / 2, tile_height / 2, tile_thickness])
                chamfer_edge_mask(l=tile_height, chamfer=0.5, orient=FRONT);
            if (chamfer_rear) {
                translate([tile_width / 2, tile_height / 2, 0])
                    chamfer_edge_mask(l=tile_height, chamfer=0.5, orient=FRONT);
            }
        }

        if (crop_right) {
            // Crop right side
            translate([tile_width / 2, 0, 0])
                cube([tile_width / 2, tile_height, tile_thickness]);
            // Right chamfer
            translate([tile_width / 2, tile_height / 2, tile_thickness])
                chamfer_edge_mask(l=tile_height, chamfer=0.5, orient=FRONT);
            if (chamfer_rear) {
                translate([tile_width / 2, tile_height / 2, 0])
                    chamfer_edge_mask(l=tile_height, chamfer=0.5, orient=FRONT);
            }
        }
    }
}


module hex_fill_left(
    chamfer_rear=false,
    bottom=false,
    top=false,
    fill_bottom=false,
    fill_top=false,
    fill_left=false,
    fill_right=false
) {
    difference() {
        translate([0, tile_height / 2, 0])
            rotate([0, 0, 90])
                diff() {
                    regular_prism(n=6, h=tile_thickness, id=tile_width, center=false, chamfer2=0.5) {
                        tag("remove") {
                            if (chamfer_rear && bottom && !fill_bottom) {
                                attach("bot_edge2")
                                    cuboid([tile_thickness, tile_width, 5]);
                            }
                            if (chamfer_rear && top && !fill_top) {
                                attach("bot_edge0")
                                    cuboid([tile_thickness, tile_width, 5]);
                            }
                        }
                    }
                }
        translate([- (tile_width / 2), 0, 0])
            cube([tile_width / 2, tile_height, tile_thickness]);
        translate([0, tile_height / 2, tile_thickness])
            chamfer_edge_mask(l=tile_height, chamfer=0.5, orient=FRONT);
        if (chamfer_rear) {
            translate([0, tile_height / 2, 0])
                chamfer_edge_mask(l=tile_height, chamfer=0.5, orient=FRONT);
        }
    }
}


module hex_fill_right(
    chamfer_rear=false,
    bottom=false,
    top=false,
    fill_bottom=false,
    fill_top=false,
    fill_left=false,
    fill_right=false
) {
    difference() {
        translate([tile_width / 2, tile_height / 2, 0])
            rotate([0, 0, 90])
                diff() {
                    regular_prism(n=6, h=tile_thickness, id=tile_width, center=false, chamfer2=0.5) {
                        tag("remove") {
                            if (chamfer_rear && top && !fill_top) {
                                attach("bot_edge5")
                                    cuboid([tile_thickness, tile_width, 5]);
                            }
                        }
                    }
                }
        translate([(tile_width / 2), 0, 0])
            cube([tile_width / 2, tile_height, tile_thickness]);
        translate([tile_width / 2, tile_height / 2, tile_thickness])
            chamfer_edge_mask(l=tile_height, chamfer=0.5, orient=FRONT);
        if (chamfer_rear) {
            translate([tile_width / 2, tile_height / 2, 0])
                chamfer_edge_mask(l=tile_height, chamfer=0.5, orient=FRONT);
        }
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
    reverse_stagger=false,
    mounting_hole_shank_diameter=4,
    mounting_hole_head_diameter=8,
    mounting_hole_inset_depth=1,
    mounting_hole_countersink_depth=2,
    skiplist=[],
    cut_outside_corners=true,
    chamfer_rear=true,
) {
    stagger_0 = reverse_stagger ? 1 : 0;
    stagger_1 = reverse_stagger ? 0 : 1;

    for (row = [0 : rows - 1]) {
        offset_x = (row % 2 == stagger_0) ? tile_width / 2 : 0;

        for (column = [0 : columns - 1]) {
            pos_x = offset_x + column * tile_width;
            pos_y = row * tile_y_offset;

            // Determine outer corners and edges
            left_outside = (column == 0) && (row % 2 == stagger_1);
            left_inside = ((column == 0) && (row % 2 == stagger_0));
            right_outside = (column == (columns - 1)) && (row % 2 == stagger_0);
            right_inside = (column == (columns - 1)) && (row % 2 == stagger_1);
            bottom = row == 0;
            top = row == (rows - 1);

            if (!in_list([row + 1, column + 1], skiplist)) {
                translate([pos_x, pos_y, 0])
                    hex_tile_single(
                        variant=variant,
                        mounting_hole_shank_diameter=mounting_hole_shank_diameter,
                        mounting_hole_head_diameter=mounting_hole_head_diameter,
                        mounting_hole_countersink_depth=mounting_hole_countersink_depth,
                        mounting_hole_inset_depth=mounting_hole_inset_depth,
                        cut_outside_corners=cut_outside_corners,
                        chamfer_rear=chamfer_rear,
                        left_outside=left_outside,
                        left_inside=left_inside,
                        right_outside=right_outside,
                        right_inside=right_inside,
                        bottom=bottom,
                        top=top,
                        fill_bottom=fill_bottom,
                        fill_top=fill_top,
                        fill_left=fill_left,
                        fill_right=fill_right
                    );
            }
            if (fill_left && column == 0 && offset_x) {
                translate([0, pos_y, 0])
                    hex_fill_left(
                        chamfer_rear=chamfer_rear,
                        bottom=bottom,
                        top=top,
                        fill_bottom=fill_bottom,
                        fill_top=fill_top,
                        fill_left=fill_left,
                        fill_right=fill_right
                    );
            }
            if (fill_right && column == (columns -1 ) && !offset_x) {
                translate([pos_x + tile_width, pos_y, 0])
                    hex_fill_right(
                        chamfer_rear=chamfer_rear,
                        bottom=bottom,
                        top=top,
                        fill_bottom=fill_bottom,
                        fill_top=fill_top,
                        fill_left=fill_left,
                        fill_right=fill_right
                    );
            }
        }

        if (fill_top && row == (rows - 1)) {
            // Fill in top row
            even_row = (row + 1) % 2 == stagger_0;
            offset_x = even_row ? tile_width / 2 : tile_width;

            for (column = [0 : columns]) {
                pos_x = (offset_x + column * tile_width) - tile_width;
                pos_y = tile_y_offset * (row + 1);
                crop_left = (column == 0 && ! fill_left);
                translate([pos_x, pos_y, 0])
                    hex_fill_top(
                        crop_left=(column == 0 && (!fill_left || even_row)),
                        crop_right=(column == columns && (!fill_right || !even_row)),
                        mounting_hole_shank_diameter=mounting_hole_shank_diameter,
                        mounting_hole_head_diameter=mounting_hole_head_diameter,
                        mounting_hole_inset_depth=mounting_hole_inset_depth,
                        mounting_hole_countersink_depth=mounting_hole_countersink_depth,
                        chamfer_rear=chamfer_rear
                    );
            }
        }

        if (fill_bottom && row == 0) {
            // Fill in bottom row
            offset_x = reverse_stagger ? tile_width / -2 : 0;

            for (column = [0 : columns]) {
                pos_x = (offset_x + column * tile_width);
                echo(pos_x);
                pos_y = tile_y_offset * (row);
                translate([pos_x, pos_y, 0])
                    hex_fill_bottom(
                        crop_left=(column == 0 && (!fill_left || reverse_stagger)),
                        crop_right=(column == columns && (!fill_right || !reverse_stagger)),
                        chamfer_rear=chamfer_rear
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


module grid_tile_single(
    variant=variant_original,
    mounting_hole_shank_diameter=4,
    mounting_hole_head_diameter=8,
    mounting_hole_inset_depth=1,
    mounting_hole_countersink_depth=2
) {
    rear_cleat_thickness = variant == variant_original ? tile_hanger_rear_cleat_thickness : 0;
    cleat_additional_thickness = variant == variant_thicker_cleats ? hanger_offset : 0;
    hanger_x_offset = (tile_width - tile_hanger_width) / 2;
    threaded_hole_center_x = tile_width / 2;
    threaded_hole_center_y = grid_hanger_y_offset + tile_hanger_height + tile_threaded_hole_y_offset_from_hanger_top;
    mounting_hole_center_x = tile_width / 2;
    mounting_hole_center_y = tile_mounting_hole_y_offset;

    difference() {
        // Outer tile
        translate([tile_width / 2, grid_tile_height / 2, 0])
            cuboid([tile_width, grid_tile_height, tile_thickness], anchor=BOTTOM, chamfer=0.5, edges=TOP);

        // Space for hanger
        linear_extrude(height=tile_thickness)
            difference() {
                translate([hanger_x_offset, grid_hanger_y_offset, 0])
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

        // Mounting holes
        translate([grid_tile_mounting_hole_x_offset, grid_tile_mounting_hole_y_offset, 0]) {
            mounting_hole(
                mounting_hole_shank_diameter=mounting_hole_shank_diameter,
                mounting_hole_head_diameter=mounting_hole_head_diameter,
                mounting_hole_inset_depth=mounting_hole_inset_depth,
                mounting_hole_countersink_depth=mounting_hole_countersink_depth
            );
        }
        translate([tile_width - grid_tile_mounting_hole_x_offset, grid_tile_mounting_hole_y_offset, 0]) {
            mounting_hole(
                mounting_hole_shank_diameter=mounting_hole_shank_diameter,
                mounting_hole_head_diameter=mounting_hole_head_diameter,
                mounting_hole_inset_depth=mounting_hole_inset_depth,
                mounting_hole_countersink_depth=mounting_hole_countersink_depth
            );
        }
    }

    // Left rear chamfer
    translate([hanger_x_offset, grid_hanger_y_offset, rear_cleat_thickness])
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
    translate([hanger_x_offset, grid_hanger_y_offset, (hanger_thickness / 2) + rear_cleat_thickness])
        tile_cleat(variant=variant);

    // Right rear chamfer
    translate([tile_width - hanger_x_offset, grid_hanger_y_offset + tile_hanger_height, rear_cleat_thickness])
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
    translate([hanger_x_offset + tile_hanger_width, grid_hanger_y_offset, (hanger_thickness / 2) + rear_cleat_thickness])
        xflip() tile_cleat(variant=variant);

    // Lower rear chamfer
    translate([hanger_x_offset + tile_hanger_width, grid_hanger_y_offset])
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
        translate([0, grid_hanger_y_offset, 0])
            linear_extrude(height = tile_hanger_rear_cleat_thickness)
                square([tile_hanger_rear_cleat_x_offset, tile_hanger_height]);
        translate([tile_width - tile_hanger_rear_cleat_x_offset, grid_hanger_y_offset, 0])
            linear_extrude(height = tile_hanger_rear_cleat_thickness)
                square([tile_hanger_rear_cleat_x_offset, tile_hanger_height]);
    }
}


module grid_tile(
    variant=variant_original,
    columns=4,
    rows=4,
    mounting_hole_shank_diameter=4,
    mounting_hole_head_diameter=8,
    mounting_hole_inset_depth=1,
    mounting_hole_countersink_depth=2,
    skiplist=[]
) {
    for (row = [0 : rows - 1]) {
        for (column = [0 : columns - 1]) {
            pos_x = column * tile_width;
            pos_y = row * grid_tile_height;

            if (!in_list([row + 1, column + 1], skiplist)) {
                translate([pos_x, pos_y, 0])
                    grid_tile_single(
                        variant=variant,
                        mounting_hole_shank_diameter=mounting_hole_shank_diameter,
                        mounting_hole_head_diameter=mounting_hole_head_diameter,
                        mounting_hole_countersink_depth=mounting_hole_countersink_depth,
                        mounting_hole_inset_depth=mounting_hole_inset_depth
                    );
            }
        }
    }
}

/*
 * Print time and filament use comparisons
 *
 * Original 6x6:7 hours 32 minutes, 124g
 * Rebuilt original 6x6: 7 hours 20 minutes, 120g (3.2% reduction in filament)
 * Rebuilt thicker cleats 6x6: 6 hours, 52 minutes, 112g (9.7% reduction in filament)
 *
 * Original 4x4: 3 hours 25 minutes, 56g
 * Rebuilt original 4x4: 3 hours 18 minutes, 54g (3.6% reduction in filament)
 * Rebuilt thicker cleats 4x4: 3 hours 5 minutes, 51g (8.9% reduction in filament)
 */
