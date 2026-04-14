include <BOSL2/std.scad>
include <BOSL2/shapes3d.scad>
include <gridfinity-rebuilt-openscad/gridfinity-rebuilt-baseplate.scad>

include <constants.scad>
use <hanger.scad>


module solid_square_baseplate(size=BASEPLATE_DIMENSIONS, height=0) {
    difference() {
            linear_extrude(height + BASEPLATE_HEIGHT)
                square(size, center=true);
        translate([0, 0, height])
            baseplate_cutter(size, BASEPLATE_HEIGHT);
    }
}

module gridfinity_base(
    base_thickness=0,
    skeletonized=true,
    magnet_hole=false,
    magnet_hole_crush_ribs=false,
    magnet_hole_chamfer=false,
) {
    difference() {
        solid_square_baseplate(height=base_thickness);
        if (skeletonized) {
            linear_extrude(height=base_thickness)
                profile_skeleton();
        }
        if (magnet_hole) {
            hole_pattern() {
                translate([0, 0, base_thickness])
                    mirror([0, 0, 1])
                        block_base_hole(
                            bundle_hole_options(
                                magnet_hole=magnet_hole,
                                crush_ribs=magnet_hole_crush_ribs,
                                chamfer=magnet_hole_chamfer
                            )
                        );
            }
        }
    }
}

module gridfinity_shelf(
    gridx=2,
    gridy=1,
    rear_offset=4.5,
    max_rear_offset_fillet=10,
    base_thickness=5,
    skeletonized=true,
    sides=false,
    side_thickness=2,
    side_height=20,
    front=false,
    front_thickness=2,
    front_height=10,
    magnet_holes=false,
    magnet_hole_crush_ribs=false,
    magnet_hole_chamfer=false,
    base_width=42,
    plate_thickness=default_plate_thickness,
    hanger_tolerance=0.15,
    variant=variant_original
) {
    hanger_plate_offset = get_hanger_plate_offset(variant, hanger_tolerance);
    hanger_total_thickness = hanger_thickness + hanger_plate_offset;
    plate_total_thickness = plate_thickness + hanger_total_thickness;

    width = base_width * gridx;
    nominal_width = base_width == 42 ? (base_width * gridx) - 1 : (base_width * gridx);
    total_width = sides ? width + 2 * side_thickness : width;
    total_plate_width = get_hanger_plate_width(nominal_width);
    base_depth = base_width * gridy + rear_offset;
    baseplate_depth = base_width * gridy;
    total_baseplate_height = base_thickness + BASEPLATE_HEIGHT;

    x_offset = get_hanger_plate_width(nominal_width) / 2;

    magnet_hole = base_thickness >= 4 ? magnet_holes : false;

    union() {
        hanger_plate(
            variant=variant,
            plate_thickness=plate_thickness,
            hanger_units=get_hanger_units_from_width(nominal_width),
            hanger_tolerance=hanger_tolerance,
            plate_side_tolerance=sides ? 0 : plate_side_tolerance,
        );

        translate([(width - total_plate_width) * -0.5, 0, 0]) {
            difference() {
                for (row = [0 : gridx - 1]) {
                    baseplate_x_offset = (row * base_width) + (base_width / 2);
                    for (column = [0 : gridy - 1]) {
                        baseplate_y_offset = plate_total_thickness + rear_offset + (column * base_width) + base_width / 2;
                        translate([baseplate_x_offset, baseplate_y_offset, 0])
                            gridfinity_base(
                                base_thickness=base_thickness,
                                skeletonized=skeletonized,
                                magnet_hole=magnet_hole,
                                magnet_hole_crush_ribs=magnet_hole_crush_ribs,
                                magnet_hole_chamfer=magnet_hole_chamfer
                            );
                    }
                }
                if (!sides) {
                    translate([0, plate_total_thickness + rear_offset + baseplate_depth, 0])
                        rotate([180, 0, 0])
                            rounding_edge_mask(l=total_baseplate_height, r=4, anchor=TOP);
                    translate([width, plate_total_thickness + rear_offset + baseplate_depth, 0])
                        rotate([0, 0, 180])
                            rounding_edge_mask(l=total_baseplate_height, r=4, anchor=BOTTOM);
                }
            }

            translate([0, plate_total_thickness, 0])
                cuboid(
                    [total_plate_width, rear_offset, total_baseplate_height],
                    anchor=BOTTOM+FRONT+LEFT,
                    edges=[BACK]
                );
        }

        translate([x_offset, plate_total_thickness, total_baseplate_height]) {
            fillet(l=total_plate_width, r=min(rear_offset, max_rear_offset_fillet), orient=LEFT);
        }

        if (sides) {
            side_offset = (total_plate_width - total_width) / 2;
            side_depth = front ? base_depth + plate_thickness + front_thickness : base_depth + plate_thickness;
            translate([side_offset, hanger_total_thickness, 0])
                cuboid(
                    [side_thickness, side_depth, side_height],
                    anchor=FRONT+LEFT+BOTTOM,
                );

            translate([side_offset + total_plate_width + side_thickness, hanger_total_thickness, 0])
                cuboid(
                    [side_thickness, side_depth, side_height],
                    anchor=FRONT+LEFT+BOTTOM,
                );

        }

        if (front) {
            translate([0, base_depth + plate_total_thickness, 0])
                cuboid(
                    [width, front_thickness, front_height],
                    anchor=FRONT+LEFT+BOTTOM,
                );
        }
    }
}


gridfinity_shelf(
    gridx=gridx,
    gridy=gridy,
    rear_offset=rear_offset,
    max_rear_offset_fillet=max_rear_offset_fillet,
    plate_thickness=plate_thickness,
    base_thickness=base_thickness,
    skeletonized=skeletonized,
    sides=sides,
    side_thickness=side_thickness,
    side_height=side_height,
    front=front,
    front_thickness=front_thickness,
    front_height=front_height,
    magnet_holes=magnet_holes,
    magnet_hole_crush_ribs=magnet_hole_crush_ribs,
    magnet_hole_chamfer=magnet_hole_chamfer,
    hanger_tolerance=hanger_tolerance,
    variant=variant
);
