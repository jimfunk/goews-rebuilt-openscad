include <BOSL2/std.scad>

include <constants.scad>
use <hanger.scad>


/* [Primary parameters] */
// Which variant to use
variant = 0; // [0: Original, 1: Thicker cleats]

// Added to hangers to allow for easier insertion and removal, as on other GOEWS parts
hanger_tolerance = 0.15;

/* [Pliers hanger parameters] */
// Nominal width of the tapered support at its base in mm
width = 24;

// Usable support depth from the plate face, excluding the front lip, in mm
depth = 25;

// Height of the tapered support in mm
height = 18;

// Width of the flat top of the support in mm; must be smaller than width
tip_width = 4;

// Extra front lip height in mm; 0 disables the lip
lip_height = 4;

// Front lip thickness along the depth in mm
lip_thickness = 3;

// Cross-section corner radius in mm; 0 leaves sharp corners
rounding = 1;


/* [Hidden] */
$fa=0.5;
$fs=0.5;


// A tapered support between the handles, not a fork with two open slots.
// The points describe the nominal envelope; rounding trims the corners inward.
module pliers_support_profile(width, height, tip_width, rounding) {
    offset(r=rounding)
        offset(delta=-rounding)
            polygon([
                [-width / 2, 0],
                [width / 2, 0],
                [tip_width / 2, height],
                [-tip_width / 2, height]
            ]);
}


module pliers_hanger(
    width=24,
    depth=25,
    height=18,
    tip_width=4,
    lip_height=4,
    lip_thickness=3,
    rounding=1,
    hanger_tolerance=0.15,
    variant=variant_original
) {
    assert(variant == variant_original || variant == variant_thicker_cleats,
        "variant must be Original (0) or Thicker cleats (1)");
    assert(width > 0 && depth > 0 && height > 0,
        "width, depth, and height must be positive");
    assert(tip_width > 0 && tip_width < width,
        "tip_width must be positive and smaller than width");
    assert(lip_height >= 0 && lip_thickness >= 0,
        "lip dimensions must not be negative");
    assert(lip_height == 0 || lip_thickness > 0,
        "lip_thickness must be positive when the lip is enabled");
    assert(rounding >= 0 && 2 * rounding < min(tip_width, height),
        "rounding must be nonnegative and less than half the tip width and height");
    assert(hanger_tolerance >= 0, "hanger_tolerance must not be negative");

    hanger_plate_offset = get_hanger_plate_offset(variant, hanger_tolerance);
    plate_total_thickness = hanger_thickness + hanger_plate_offset + default_plate_thickness;
    total_width = width + 2 * lip_height;
    hanger_units = get_hanger_units_from_width(total_width);
    x_center = get_hanger_plate_width(total_width) / 2;

    // Move the standard mount upward instead of changing its mating geometry.
    // Keep even the lip below the full bolt-head clearance envelope, not just
    // below the smaller notch in the plate. Dimensions remain relative to Z=0.
    bolt_clearance = 2;
    extend_bottom = max(
        0,
        height + lip_height + bolt_clearance
            - (plate_cutout_y_offset - hanger_bolt_notch_head_clearance_diameter / 2)
    );

    union() {
        hanger_plate(
            variant=variant,
            hanger_units=hanger_units,
            hanger_tolerance=hanger_tolerance,
            extend_bottom=extend_bottom
        );

        // Extrude the X/Z support profile toward the plate, overlapping it by
        // overcut so the joint is a solid union rather than touching faces.
        translate([x_center, plate_total_thickness + depth, 0])
            rotate([90, 0, 0])
                linear_extrude(height=depth + overcut)
                    pliers_support_profile(width, height, tip_width, rounding);

        // Wider and taller than the support, catching the handles before they
        // slide off the end. Setting lip_height=0 omits the entire lip.
        if (lip_height > 0)
            translate([x_center, plate_total_thickness + depth + lip_thickness, 0])
                rotate([90, 0, 0])
                    linear_extrude(height=lip_thickness + overcut)
                        pliers_support_profile(
                            total_width,
                            height + lip_height,
                            tip_width,
                            rounding
                        );
    }
}


pliers_hanger(
    width=width,
    depth=depth,
    height=height,
    tip_width=tip_width,
    lip_height=lip_height,
    lip_thickness=lip_thickness,
    rounding=rounding,
    hanger_tolerance=hanger_tolerance,
    variant=variant
);
