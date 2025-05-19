include <BOSL2/std.scad>
include <BOSL2/shapes3d.scad>

include <constants.scad>
use <hanger.scad>


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

module hole_shelf(
    thickness=4,
    columns=3,
    rows=1,
    hole_radius=3.5,
    column_gap=15,
    row_gap=15,
    front_gap=15,
    rear_gap=15,
    side_gap=15,
    stagger=false,
    rear_fillet_radius=1,
    rounding=0.5,
    hanger_tolerance=0.15,
    variant=variant_original
) {
    hanger_plate_offset = get_hanger_plate_offset(variant, hanger_tolerance);
    hanger_total_thickness = hanger_thickness + hanger_plate_offset;
    plate_total_thickness = default_plate_thickness + hanger_total_thickness;

    offset_width = stagger ? column_gap / 2 + hole_radius : 0;
    width = (side_gap * 2) + (columns * hole_radius * 2) + ((columns - 1) * column_gap) + offset_width;
    depth = front_gap + rear_gap + (rows * hole_radius * 2) + ((rows - 1) * row_gap);

    x_offset = get_hanger_plate_width(width) / 2;
    y_offset = plate_total_thickness;

    union() {
        hanger_plate(
            variant=variant,
            hanger_units=get_hanger_units_from_width(width),
            hanger_tolerance=hanger_tolerance
        );

        // Shelf
        difference() {
            translate([x_offset, y_offset, 0]) {
                cuboid(
                    [width, depth, thickness],
                    anchor=BOTTOM+FRONT,
                    rounding=rounding,
                    edges=[BACK]
                );
            }

            // Holes
            holes_x_offset = (get_hanger_plate_width(width) - width) / 2;
            translate([holes_x_offset, y_offset, 0]) {
                for (row = [0 : rows - 1]) {
                    row_offset = row % 2 == 1 ? offset_width + side_gap : side_gap;
                    hole_y = rear_gap + row * (row_gap + 2 * hole_radius) + hole_radius;
                    for (col = [0 : columns - 1]) {
                        hole_x = row_offset + col * (column_gap + 2 * hole_radius) + hole_radius;
                        translate([hole_x, hole_y, 0])
                            cylinder(h = thickness, r = hole_radius);
                    }
                }
            }
        }

        // Rear fillet
        translate([x_offset, y_offset, thickness]) {
            fillet(l=width, r=rear_fillet_radius, orient=LEFT);
        }

    }
}


module slot_shelf(
    thickness=4,
    slots=4,
    slot_length=40,
    slot_width=10,
    slot_rounding=1,
    gap=10,
    front_gap=5,
    rear_gap=10,
    side_gap=5,
    rear_fillet_radius=1,
    rounding=0.5,
    hanger_tolerance=0.15,
    variant=variant_original
) {
    hanger_plate_offset = get_hanger_plate_offset(variant, hanger_tolerance);
    hanger_total_thickness = hanger_thickness + hanger_plate_offset;
    plate_total_thickness = default_plate_thickness + hanger_total_thickness;

    width = (side_gap * 2) + (slots * slot_width) + ((slots - 1) * gap);
    depth = front_gap + rear_gap + slot_length;

    x_offset = get_hanger_plate_width(width) / 2;
    y_offset = plate_total_thickness;

    union() {
        hanger_plate(
            variant=variant,
            hanger_units=get_hanger_units_from_width(width),
            hanger_tolerance=hanger_tolerance
        );

        // Shelf
        difference() {
            translate([x_offset, y_offset, 0]) {
                cuboid(
                    [width, depth, thickness],
                    anchor=BOTTOM+FRONT,
                    rounding=rounding,
                    edges=[BACK]
                );
            }

            shelf_x_offset = ((get_hanger_plate_width(width) - width) / 2);
            translate([shelf_x_offset, y_offset, 0]) {
                for (slot = [0 : slots - 1]) {
                    slot_x = side_gap + slot * (slot_width + gap) + slot_width / 2;
                    translate([slot_x, rear_gap, 0])
                        cuboid(
                            [slot_width, slot_length, thickness],
                            rounding=slot_rounding,
                            edges="Z",
                            anchor=BOTTOM+FRONT
                        );
                }
            }
        }

        // Rear fillet
        translate([x_offset, y_offset, thickness]) {
            fillet(l=width, r=rear_fillet_radius, orient=LEFT);
        }
    }
}
