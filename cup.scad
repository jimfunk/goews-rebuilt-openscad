include <BOSL2/std.scad>
include <BOSL2/shapes3d.scad>

include <constants.scad>
use <hanger.scad>


/* [Primary parameters] */
// Which variant to use
variant = 0; // [0: Original, 1: Thicker cleats]

// Added to hangers to allow for easier insertion and removal. This can be reduced to make hanger plates tighter to the tile. It reduces the tilt but makes them harder to insert and remove
hanger_tolerance = 0.15;

/* [Cup parameters] */
// Inner diameter in mm
inner_diameter = 37.5;

// Height in mm
height = 24.39;

// Wall thickness in mm
wall_thickness = 2;

// Bottom thickness in mm
bottom_thickness = 2;

// Inner rounding in mm
inner_rounding = 0.5;

// Outer rounding in mm
outer_rounding = 0.5;


/* [Hidden] */
$fa=0.5;
$fs=0.5;


module cup(
    inner_diameter=37.5,
    height=24.39,
    wall_thickness=2,
    bottom_thickness=2,
    inner_rounding=0.5,
    outer_rounding=0.5,
    hanger_tolerance=0.15,
    variant=variant_original
) {
    hanger_plate_offset = get_hanger_plate_offset(variant, hanger_tolerance);
    hanger_total_thickness = hanger_thickness + hanger_plate_offset;
    plate_total_thickness = default_plate_thickness + hanger_total_thickness;

    outer_diameter = inner_diameter + 2 * wall_thickness;
    rear_width = outer_diameter / 1.5;
    x_offset = get_hanger_plate_width(rear_width) / 2;
    y_offset = plate_total_thickness + outer_diameter / 2;

    bolt_notch = height > (plate_height - bolt_head_cutout_offset) ? false : true;
    plate_extend_bottom = height > plate_height ? height - plate_height : 0;

    union() {
        hanger_plate(
            variant=variant,
            hanger_units=get_hanger_units_from_width(rear_width),
            hanger_tolerance=hanger_tolerance,
            extend_bottom=plate_extend_bottom,
            bolt_notch=bolt_notch
        );


        difference() {
            // Outer cup
            hull() {
                translate([x_offset, y_offset, 0]) {
                    cyl(
                        l=height,
                        d=outer_diameter,
                        anchor=BOTTOM,
                        rounding=outer_rounding
                    );
                }
                translate([x_offset, plate_total_thickness - 1, 0])
                    cube([inner_diameter / 1.5, 1, height], anchor=CENTER+FRONT+BOTTOM);
            }

            // Inner cup
            translate([x_offset, y_offset, bottom_thickness]) {
                cyl(
                    l=height - bottom_thickness,
                    d=inner_diameter,
                    anchor=BOTTOM,
                    rounding1=inner_rounding,
                    rounding2=inner_rounding * -1
                );
            }
        }
    }
}


cup(
    inner_diameter=inner_diameter,
    height=height,
    wall_thickness=wall_thickness,
    bottom_thickness=bottom_thickness,
    inner_rounding=inner_rounding,
    outer_rounding=outer_rounding,
    hanger_tolerance=hanger_tolerance,
    variant=variant
);
