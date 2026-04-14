include <BOSL2/std.scad>

include <constants.scad>
use <hanger.scad>


/* [Primary parameters] */
// Which variant to use
variant = 0; // [0: Original, 1: Thicker cleats]

// Added to hangers to allow for easier insertion and removal. This can be reduced to make hanger plates tighter to the tile. It reduces the tilt but makes them harder to insert and remove
hanger_tolerance = 0.15;

/* [Rack parameters] */
// Number of slots in the rack
slots = 7;

// Slot width in mm
slot_width = 6;

// Divider width in mm
divider_width = 10;

// Divider length in mm
divider_length = 80;

// Divider thickness in mm
divider_thickness = 6;

// Whether to include a lip at the front of the dividers
lip = false;

// Lip height in mm
lip_height = 8;

// Lip thickness in mm
lip_thickness = 4;

// Rounding on the outer corners of the divider and lip in mm
rounding = 0.5;


/* [Hidden] */
$fa=0.5;
$fs=0.5;


module rack(
    slots=7,
    slot_width=6,
    divider_width=10,
    divider_length=80,
    divider_thickness=6,
    lip=false,
    lip_height=8,
    lip_thickness=4,
    rounding=0.5,
    hanger_tolerance=0.15,
    variant=variant_original
) {
    hanger_plate_offset = get_hanger_plate_offset(variant, hanger_tolerance);
    hanger_total_thickness = hanger_thickness + hanger_plate_offset;
    plate_total_thickness = default_plate_thickness + hanger_total_thickness;

    total_width = (slot_width * slots) + (divider_width * (slots + 1));

    x_offset = (get_hanger_plate_width(total_width) - total_width) / 2;
    y_offset = plate_total_thickness;

    union() {
        hanger_plate(
            variant=variant,
            hanger_units=get_hanger_units_from_width(total_width),
            hanger_tolerance=hanger_tolerance
        );

        translate([x_offset, y_offset, 0]) {
            for (i = [0:slots]) {
                translate([(slot_width + divider_width) * i, 0, 0]) {
                    if (lip) {
                        // Divider
                        cuboid(
                            size=[divider_width, divider_length, divider_thickness],
                            anchor=BOTTOM+FRONT+LEFT,
                            rounding=rounding,
                            edges=["Y"]
                        );

                        // Lip
                        translate([0, divider_length, 0])
                            cuboid(
                                [divider_width, lip_thickness, lip_height],
                                anchor=BOTTOM+FRONT+LEFT,
                                rounding=rounding,
                                edges=[
                                    "Y",
                                    TOP,
                                    BACK
                                ]
                            );
                    } else {
                        // Without lip
                        cuboid(
                            size=[divider_width, divider_length, divider_thickness],
                            anchor=BOTTOM+FRONT+LEFT,
                            rounding=rounding,
                            edges=["Y", BACK]
                        );
                    }
                }
            }
        }
    }
}


rack(
    slots=slots,
    slot_width=slot_width,
    divider_width=divider_width,
    divider_length=divider_length,
    divider_thickness=divider_thickness,
    lip=lip,
    lip_height=lip_height,
    lip_thickness=lip_thickness,
    rounding=rounding,
    hanger_tolerance=hanger_tolerance,
    variant=variant
);
