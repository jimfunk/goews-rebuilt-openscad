include <BOSL2/std.scad>

include <constants.scad>
use <hanger.scad>


module hook(
    width=10,
    shank_length=10,
    shank_thickness=8,
    post_height=18,
    post_thickness=6,
    rounding=0.5,
    hanger_tolerance=0.15,
    variant=variant_original
) {
    hanger_plate_offset = get_hanger_plate_offset(variant, hanger_tolerance);
    hanger_total_thickness = hanger_thickness + hanger_plate_offset;
    plate_total_thickness = plate_thickness + hanger_total_thickness;

    x_offset = (get_hanger_plate_width(width) - width) / 2;
    y_offset = plate_total_thickness;

    union() {
        hanger_plate(
            variant=variant,
            hanger_units=get_hanger_units_from_width(width),
            hanger_tolerance=hanger_tolerance
        );

        translate([x_offset, y_offset, 0])
            cuboid(
                size=[width, shank_length, shank_thickness],
                anchor=BOTTOM+FRONT+LEFT,
                rounding=rounding,
                edges=["Y"]
            );

        translate([x_offset, y_offset + shank_length, 0])
            cuboid(
                [width, post_thickness, post_height],
                anchor=BOTTOM+FRONT+LEFT,
                rounding=rounding,
                edges=[
                    "Y",
                    TOP,
                    BACK
                ]
            );
    }
}
