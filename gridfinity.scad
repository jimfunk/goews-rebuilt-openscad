include <BOSL2/std.scad>
include <BOSL2/shapes3d.scad>
include <gridfinity-rebuilt-openscad/gridfinity-rebuilt-baseplate.scad>

include <constants.scad>
use <hanger.scad>

default_hole_options=bundle_hole_options();

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
    base_thickness=5,
    skeletonized=true,
    magnet_holes=false,
    magnet_hole_crush_ribs=false,
    magnet_hole_chamfer=false,
    base_width=42,
    hanger_tolerance=0.15,
    variant=variant_original
) {
    hanger_plate_offset = get_hanger_plate_offset(variant, hanger_tolerance);
    hanger_total_thickness = hanger_thickness + hanger_plate_offset;
    plate_total_thickness = plate_thickness + hanger_total_thickness;

    width = base_width * gridx;
    // With the standard width of 42 the plate width is slightly smaller so we need to
    // adjust a bit. the baseplate will be slightly wider than the plate
    nominal_width = base_width == 42 ? (base_width * gridx) - 1 : (base_width * gridx);
    total_plate_width = get_hanger_plate_width(nominal_width);
    base_depth = base_width * gridy + rear_offset;
    baseplate_depth = base_width * gridy;
    total_baseplate_height = base_thickness + BASEPLATE_LIP_MAX.y;

    x_offset = get_hanger_plate_width(nominal_width) / 2;

    magnet_hole = base_thickness >= 4 ? magnet_holes : false;

    union() {
        hanger_plate(
            variant=variant,
            hanger_units=get_hanger_units_from_width(nominal_width),
            hanger_tolerance=hanger_tolerance
        );

        // Baseplate
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
                translate([0, plate_total_thickness + rear_offset + baseplate_depth, 0])
                    rotate([180, 0, 0])
                        rounding_edge_mask(l=total_baseplate_height, r=4, anchor=TOP);
                translate([width, plate_total_thickness + rear_offset + baseplate_depth, 0])
                    rotate([0, 0, 180])
                        rounding_edge_mask(l=total_baseplate_height, r=4, anchor=BOTTOM);
            }
        }

        // Rear offset filler
        translate([x_offset, plate_total_thickness, 0]) {
            cuboid(
                [total_plate_width, rear_offset, total_baseplate_height],
                anchor=BOTTOM+FRONT,
                edges=[BACK]
            );
        }

        // Rear fillet
        translate([x_offset, plate_total_thickness, total_baseplate_height]) {
            fillet(l=total_plate_width, r=rear_offset, orient=LEFT);
        }
    }
}
