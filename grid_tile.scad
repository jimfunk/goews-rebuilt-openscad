include <BOSL2/std.scad>
include <BOSL2/lists.scad>
include <BOSL2/threading.scad>

include <constants.scad>
include <parsers.scad>


/* [Primary parameters] */
// Which variant to use
variant = 0; // [0: Original, 1: Thicker cleats]

// Tile columns in units
columns = 4;

// Tile rows in units
rows = 4;

// Mounting hole shank diameter
mounting_hole_shank_diameter = 4;

// Mounting hole head diameter
mounting_hole_head_diameter = 8;

// Mounting hole inset depth
mounting_hole_inset_depth = 1;

// Mounting hole countersink depth. Set to 0 to disable countersink
mounting_hole_countersink_depth = 2;

// List of tile positions to skip. Each entry is a pair of 1-based row and column coordinates with the origin at the lower left, eg: [1, 2], [3, 4]
skip_list = "";


/* [Hidden] */
$fa=0.5;
$fs=0.5;


module tile_cleat(variant=variant_original) {
    difference() {
        translate([0, 0, tile_hanger_cleat_width])
            union() {
                if (variant == variant_thicker_cleats) {
                    linear_extrude(height = cleat_offset)
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
        linear_extrude(height = tile_hanger_cleat_width + cleat_offset)
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


module grid_tile_single(
    variant=variant_original,
    mounting_hole_shank_diameter=4,
    mounting_hole_head_diameter=8,
    mounting_hole_inset_depth=1,
    mounting_hole_countersink_depth=2
) {
    rear_cleat_thickness = variant == variant_original ? tile_hanger_rear_cleat_thickness : 0;
    cleat_additional_thickness = variant == variant_thicker_cleats ? cleat_offset : 0;
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


grid_tile(
    variant=variant,
    columns=columns,
    rows=rows,
    mounting_hole_shank_diameter=mounting_hole_shank_diameter,
    mounting_hole_head_diameter=mounting_hole_head_diameter,
    mounting_hole_inset_depth=mounting_hole_inset_depth,
    mounting_hole_countersink_depth=mounting_hole_countersink_depth,
    skiplist=parse_vector_list(skip_list)
);
