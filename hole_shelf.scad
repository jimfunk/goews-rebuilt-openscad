include <BOSL2/std.scad>
include <BOSL2/shapes3d.scad>

include <constants.scad>
use <hanger.scad>


/* [Primary parameters] */
// Which variant to use
variant = 0; // [0: Original, 1: Thicker cleats]

// Added to hangers to allow for easier insertion and removal. This can be reduced to make hanger plates tighter to the tile. It reduces the tilt but makes them harder to insert and remove
hanger_tolerance = 0.15;

/* [Shelf parameters] */
// Number of columns in the shelf
columns = 3;

// Number of rows in the shelf
rows = 1;

// Shelf thickness
thickness = 4;

// Hole radius in mm
hole_radius = 3.5;

// Gap between holes in a column in mm
column_gap = 15;

// Gap between holes in a row in mm
row_gap = 15;

// Gap between front of shelf and the front holes in mm
front_gap = 15;

// Gap between back of shelf and the rear holes in mm
rear_gap = 15;

// Gap between side of shelf and the side holes in mm
side_gap = 15;

// Stagger rows
stagger = false;

// Shelf rear fillet radius in mm
rear_fillet_radius = 1;

// Shelf rounding on the front edges in mm
rounding = 0.5;


/* [Hidden] */
$fa=0.5;
$fs=0.5;


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


hole_shelf(
    thickness=thickness,
    columns=columns,
    rows=rows,
    hole_radius=hole_radius,
    column_gap=column_gap,
    row_gap=row_gap,
    front_gap=front_gap,
    rear_gap=rear_gap,
    side_gap=side_gap,
    stagger=stagger,
    rear_fillet_radius=rear_fillet_radius,
    rounding=rounding,
    hanger_tolerance=hanger_tolerance,
    variant=variant
);
