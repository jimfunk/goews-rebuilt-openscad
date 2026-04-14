include <BOSL2/std.scad>

include <constants.scad>
use <hanger.scad>


/* [Primary parameters] */
// Which variant to use
variant = 0; // [0: Original, 1: Thicker cleats]

// Added to hangers to allow for easier insertion and removal. This can be reduced to make hanger plates tighter to the tile. It reduces the tilt but makes them harder to insert and remove
hanger_tolerance = 0.15;

/* [Hook parameters] */
// Number of hooks
hooks = 1;

// Hook width in mm
width = 10;

// Gap between hooks when there is more than one
gap = 10;

// Hook shank length in mm
shank_length = 10;

// Hook shank thickness in mm
shank_thickness = 8;

// Hook post height in mm
post_height = 18;

// Hook post thickness in mm
post_thickness = 6;

// Hook rounding on the outer corners in mm
rounding = 0.5;

// Add a lip on top of the hook post. Set to 0 to disable
lip_thickness = 0;


/* [Hidden] */
$fa=0.5;
$fs=0.5;


module hook(
    width=10,
    shank_length=10,
    shank_thickness=8,
    post_height=18,
    post_thickness=6,
    lip_thickness=2,
    hooks=1,
    gap=10,
    rounding=0.5,
    hanger_tolerance=0.15,
    variant=variant_original
) {
    hanger_plate_offset = get_hanger_plate_offset(variant, hanger_tolerance);
    hanger_total_thickness = hanger_thickness + hanger_plate_offset;
    plate_total_thickness = default_plate_thickness + hanger_total_thickness;

    total_width = (width * hooks) + (gap * (hooks - 1));

    x_offset = (get_hanger_plate_width(total_width) - total_width) / 2;
    y_offset = plate_total_thickness;

    union() {
        hanger_plate(
            variant=variant,
            hanger_units=get_hanger_units_from_width(total_width),
            hanger_tolerance=hanger_tolerance
        );

        translate([x_offset, y_offset, 0]) {
            for (i = [0:hooks - 1]) {
                translate([(width + gap) * i, 0, 0]) {
                    if (post_height && post_thickness) {
                        // Shank
                        cuboid(
                            size=[width, shank_length, shank_thickness],
                            anchor=BOTTOM+FRONT+LEFT,
                            rounding=rounding,
                            edges=["Y"]
                        );

                        // Post
                        translate([0, shank_length, 0])
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
                        if (lip_thickness) {
                            translate([width / 2, shank_length, post_height - lip_thickness - rounding])
                                difference() {
                                    xcyl(width - rounding * 2, r=lip_thickness);
                                    cube(size=[width, lip_thickness, lip_thickness * 2], anchor=FRONT);
                                }
                        }
                    } else {
                        // Shank only
                        cuboid(
                            size=[width, shank_length, shank_thickness],
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


hook(
    hooks=hooks,
    width=width,
    gap=gap,
    shank_length=shank_length,
    shank_thickness=shank_thickness,
    post_height=post_height,
    post_thickness=post_thickness,
    lip_thickness=lip_thickness,
    rounding=rounding,
    hanger_tolerance=hanger_tolerance,
    variant=variant
);
