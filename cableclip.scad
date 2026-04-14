include <BOSL2/std.scad>

include <constants.scad>
use <hanger.scad>


/* [Primary parameters] */
// Which variant to use
variant = 0; // [0: Original, 1: Thicker cleats]

// Added to hangers to allow for easier insertion and removal. This can be reduced to make hanger plates tighter to the tile. It reduces the tilt but makes them harder to insert and remove
hanger_tolerance = 0.15;

/* [Cable clip parameters] */
// Orientation of the clip
orientation = cable_clip_orientation_vertical;

// Diameter of the cable in mm
cable_diameter = 5;

// Width of the clip in mm
width = 6;

// Height of the clip in mm, not including the base thickness
height = 8;

// Thickness of the clip in mm
thickness = 3;

// Thickness of the lip in mm
lip_thickness = 2;

// Rounding of the clip in mm
rounding = 0.5;

// Number of clips to make
clips = 1;

// Gap between clips in mm
gap = 10;


/* [Hidden] */
$fa=0.5;
$fs=0.5;


module clip(
    cable_diameter,
    width,
    height,
    thickness,
    lip_thickness,
    rounding,
) {
    // Shank
    cuboid(
        size=[width, cable_diameter, thickness],
        anchor=BOTTOM+FRONT+LEFT,
        rounding=rounding,
        edges=["Y"]
    );

    // Post
    translate([0, cable_diameter, 0])
        cuboid(
            [width, thickness, height+thickness],
            anchor=BOTTOM+FRONT+LEFT,
            rounding=rounding,
            edges=[
                "Y",
                TOP,
                BACK
            ]
        );
    if (lip_thickness) {
        translate([width / 2, cable_diameter, height + thickness - lip_thickness - rounding])
            difference() {
                xcyl(width - rounding * 2, r=lip_thickness);
                cube(size=[width, lip_thickness, lip_thickness * 2], anchor=FRONT);
            }
    }
}

module cableclip(
    orientation=cable_clip_orientation_vertical,
    cable_diameter=5,
    width=6,
    height=7,
    thickness=3,
    lip_thickness=2,
    rounding=0.5,
    clips=1,
    gap=10,
    hanger_tolerance=0.15,
    variant=variant_original,
) {
    hanger_plate_offset = get_hanger_plate_offset(variant, hanger_tolerance);
    hanger_total_thickness = hanger_thickness + hanger_plate_offset;
    plate_total_thickness = default_plate_thickness + hanger_total_thickness;

    clip_width = orientation == cable_clip_orientation_vertical ? width : height + thickness;
    total_width = (clip_width * clips) + (gap * (clips - 1));

    x_offset = (get_hanger_plate_width(total_width) - total_width) / 2;
    y_offset = plate_total_thickness;


    union() {
        hanger_plate(
            variant=variant,
            hanger_units=get_hanger_units_from_width(total_width),
            hanger_tolerance=hanger_tolerance
        );

        translate([x_offset, y_offset, 0]) {
            for (i = [0:clips - 1]) {
                if (orientation == cable_clip_orientation_vertical) {
                    translate([(clip_width + gap) * i, 0, 0]) {
                        clip(
                            cable_diameter=cable_diameter,
                            width=width,
                            height=height,
                            thickness=thickness,
                            lip_thickness=lip_thickness,
                            rounding=rounding
                        );
                    }
                } else if (orientation == cable_clip_orientation_horizontal_left) {
                    translate([(clip_width + gap) * i, 0, width]) {
                        rotate([0, 90, 0]) {
                            clip(
                                cable_diameter=cable_diameter,
                                width=width,
                                height=height,
                                thickness=thickness,
                                lip_thickness=lip_thickness,
                                rounding=rounding
                            );
                        }
                    }
                } else if (orientation == cable_clip_orientation_horizontal_right) {
                    translate([((clip_width + gap) * i) + clip_width, 0, 0]) {
                        rotate([0, 270, 0]) {
                            clip(
                                cable_diameter=cable_diameter,
                                width=width,
                                height=height,
                                thickness=thickness,
                                lip_thickness=lip_thickness,
                                rounding=rounding
                            );
                        }
                    }
                }
            }
        }
    }
}


cableclip(
    orientation=orientation,
    cable_diameter=cable_diameter,
    width=width,
    height=height,
    thickness=thickness,
    lip_thickness=lip_thickness,
    rounding=rounding,
    clips=clips,
    gap=gap,
    hanger_tolerance=hanger_tolerance,
    variant=variant
);
