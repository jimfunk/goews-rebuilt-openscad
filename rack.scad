include <BOSL2/std.scad>

include <constants.scad>
use <hanger.scad>


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
    plate_total_thickness = plate_thickness + hanger_total_thickness;

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
