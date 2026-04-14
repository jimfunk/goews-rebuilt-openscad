include <BOSL2/std.scad>
include <BOSL2/shapes3d.scad>
include <gridfinity-rebuilt-openscad/src/core/standard.scad>
include <gridfinity-rebuilt-openscad/src/core/gridfinity-rebuilt-holes.scad>
include <gridfinity-rebuilt-openscad/src/core/gridfinity-rebuilt-utility.scad>
use <gridfinity-rebuilt-openscad/src/core/bin.scad>
use <gridfinity-rebuilt-openscad/src/core/cutouts.scad>

include <constants.scad>
use <hanger.scad>


/* [Primary parameters] */
// Which variant to use
variant = 0; // [0: Original, 1: Thicker cleats]

// Added to hangers to allow for easier insertion and removal
hanger_tolerance = 0.15;

/* [Gridfinity bin parameters] */
// Number of grid units in the x direction
bin_gridx = 2;

// Number of grid units in the y direction
bin_gridy = 1;

// Bin height in 7mm increments (excludes stacking lip)
bin_gridz = 3;

// How gridz is used to calculate height [0:7mm excl lip, 1:Internal mm excl base&lip, 2:External mm excl lip, 3:External mm]
bin_gridz_define = 0;

// Overrides internal block height of bin (for solid containers). Leave zero for default. Units: mm
bin_height_internal = 0;

// Snap gridz height to nearest 7mm increment
bin_enable_zsnap = false;

// Add lip
bin_include_lip = true;

// Number of X divisions (set to 0 for solid bin)
bin_divx = 1;

// Number of Y divisions (set to 0 for solid bin)
bin_divy = 1;

// Use cylindrical cutouts instead of compartments
bin_cut_cylinders = false;

// Diameter of cylindrical cutouts in mm
bin_cd = 10.00;  // .01

// Chamfer around top rim of cylindrical holes in mm
bin_c_chamfer = 0.5;

// Tab style [0:Full, 1:Auto, 2:Left, 3:Center, 4:Right, 5:None]
bin_style_tab = 5;

// Which divisions have tabs [0:Everywhere, 1:Top-Left Division]
bin_place_tab = 0;

// Scoop weight percentage (0 disables, 1 is regular)
bin_scoop = 1;

// Only corners (faster printing)
bin_only_corners = false;

// Use gridfinity refined hole style (not compatible with magnet_holes)
bin_refined_holes = false;

// Add magnet holes
bin_magnet_holes = false;

// Add screw holes
bin_screw_holes = false;

// Magnet holes will have crush ribs to hold the magnet
bin_crush_ribs = true;

// Magnet/screw holes will have a chamfer to ease insertion
bin_chamfer_holes = false;

// Magnet holes will be printed so supports are not needed
bin_printable_hole_top = false;

// Enable "gridfinity-refined" thumbscrew hole
bin_enable_thumbscrew = false;

// Wall thickness in mm
bin_wall_thickness = 1.2;

// Bottom thickness in mm
bin_bottom_thickness = 1.2;


/* [Hidden] */
$fa=0.5;
$fs=0.5;


module gridfinity_bin(
    gridx=2,
    gridy=1,
    gridz=3,
    gridz_define=0,
    height_internal=0,
    enable_zsnap=false,
    include_lip=true,
    divx=1,
    divy=1,
    cut_cylinders=false,
    cd=10,
    c_chamfer=0.5,
    style_tab=5,
    place_tab=0,
    scoop=1,
    only_corners=false,
    refined_holes=false,
    magnet_holes=false,
    screw_holes=false,
    crush_ribs=true,
    chamfer_holes=false,
    printable_hole_top=false,
    enable_thumbscrew=false,
    wall_thickness=1.2,
    bottom_thickness=1.2,
    hanger_tolerance=0.15,
    variant=variant_original
) {
    hanger_plate_offset = get_hanger_plate_offset(variant, hanger_tolerance);
    // We skip the plate and only use the hanger
    hanger_total_thickness = hanger_thickness + hanger_plate_offset;

    // Gridfinity dimensions
    bin_width = gridx * GRID_DIMENSIONS_MM.x;
    bin_depth = gridy * GRID_DIMENSIONS_MM.y;

    // Calculate hanger plate width to match bin width
    hanger_units = get_hanger_units_from_width(bin_width);
    plate_width = get_hanger_plate_width(bin_width);

    // Calculate bin height using gridfinity height function
    bin_height_mm = height(gridz, gridz_define, enable_zsnap);

    // Calculate hanger vertical position and extension
    // Minimum offset clears gridfinity base profile (4.75mm)
    hanger_z_offset = 4.75;
    // Extend hanger downward if bin is taller than standard plate, making it
    // keep the hanger near the top like non-gridfinity bins
    extend_bottom = max(0, bin_height_mm - plate_height);

    hole_options = bundle_hole_options(
        refined_hole=refined_holes,
        magnet_hole=magnet_holes,
        screw_hole=screw_holes,
        crush_ribs=crush_ribs,
        chamfer=chamfer_holes,
        supportless=printable_hole_top
    );

    bin = new_bin(
        grid_size = [gridx, gridy],
        height_mm = bin_height_mm,
        fill_height = height_internal,
        include_lip = include_lip,
        hole_options = hole_options,
        only_corners = only_corners,
        thumbscrew = enable_thumbscrew,
        grid_dimensions = GRID_DIMENSIONS_MM,
        base_thickness = bottom_thickness
    );

    // Get bin dimensions for positioning from bounding box
    bin_bbox = bin_get_bounding_box(bin);
    bin_actual_depth = bin_bbox.y;

    union() {
        // Hanger plate without the plate
        translate([0, 0, hanger_z_offset]) {
            hanger_plate(
                variant=variant,
                hanger_units=hanger_units,
                hanger_tolerance=hanger_tolerance,
                plate_thickness=0,
                extend_bottom=extend_bottom
            );
        }

        // Gridfinity bin
        x_center = plate_width / 2;
        y_shift = hanger_total_thickness + bin_actual_depth / 2;

        translate([x_center, y_shift, 0]) {
            rotate([0, 0, 180]) {
                if (divx > 0 && divy > 0) {
                    bin_render(bin) {
                        bin_subdivide(bin, [divx, divy]) {
                            if (cut_cylinders) {
                                cut_chamfered_cylinder(cd/2, cgs().z, c_chamfer);
                            } else {
                                cut_compartment_auto(
                                    cgs(),
                                    style_tab,
                                    place_tab != 0,
                                    scoop
                                );
                            }
                        }
                    }
                } else {
                    bin_render(bin);
                }
            }
        }
    }
}


gridfinity_bin(
    gridx=bin_gridx,
    gridy=bin_gridy,
    gridz=bin_gridz,
    wall_thickness=bin_wall_thickness,
    bottom_thickness=bin_bottom_thickness,
    magnet_holes=bin_magnet_holes,
    screw_holes=bin_screw_holes,
    only_corners=bin_only_corners,
    include_lip=bin_include_lip,
    divx=bin_divx,
    divy=bin_divy,
    style_tab=bin_style_tab,
    scoop=bin_scoop,
    enable_thumbscrew=bin_enable_thumbscrew,
    gridz_define=bin_gridz_define,
    height_internal=bin_height_internal,
    enable_zsnap=bin_enable_zsnap,
    cut_cylinders=bin_cut_cylinders,
    cd=bin_cd,
    c_chamfer=bin_c_chamfer,
    place_tab=bin_place_tab,
    refined_holes=bin_refined_holes,
    crush_ribs=bin_crush_ribs,
    chamfer_holes=bin_chamfer_holes,
    printable_hole_top=bin_printable_hole_top,
    hanger_tolerance=hanger_tolerance,
    variant=variant
);
