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
// Number of slots in the shelf
slots = 4;

// Shelf thickness
thickness = 4;

// Slot length in mm
slot_length = 40;

// Slot width in mm
slot_width = 10;

// Slot corner rounding in mm
slot_rounding = 1;

// Gap between slots in mm
gap = 10;

// Gap between front of shelf and slots in mm
front_gap = 5;

// Gap between rear of shelf and slots in mm
rear_gap = 10;

// Gap between side of shelf and slots in mm
side_gap = 5;

// Shelf rear fillet radius in mm
rear_fillet_radius = 1;

// Shelf rounding on the front edges in mm
rounding = 0.5;


/* [Hidden] */
$fa=0.5;
$fs=0.5;


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


slot_shelf(
    thickness=thickness,
    slots=slots,
    slot_length=slot_length,
    slot_width=slot_width,
    slot_rounding=slot_rounding,
    gap=gap,
    front_gap=front_gap,
    rear_gap=rear_gap,
    side_gap=side_gap,
    rear_fillet_radius=rear_fillet_radius,
    rounding=rounding,
    hanger_tolerance=hanger_tolerance,
    variant=variant
);
