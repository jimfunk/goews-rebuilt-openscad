include <BOSL2/std.scad>
include <BOSL2/shapes3d.scad>
include <gridfinity-rebuilt-openscad/src/core/gridfinity-baseplate.scad>

include <constants.scad>
use <gridfinity_shelf_module.scad>
use <hanger.scad>


/* [Primary parameters] */
// Which variant to use
variant = 0; // [0: Original, 1: Thicker cleats]

// Added to hangers to allow for easier insertion and removal
hanger_tolerance = 0.15;

/* [Gridfinity shelf parameters] */
// Number of grid units in the x direction
gridx = 2;

// Number of grid units in the y direction
gridy = 1;

// Distance between plate and base in mm
rear_offset = 4.5;

// Maximum radius of the fillet between plate and base in mm
max_rear_offset_fillet = 10;

// Thickness of hanger plate
plate_thickness = 3;

// Additional base thickness in mm
base_thickness = 5;

// Skeletonized
skeletonized = true;

// Add sides
sides = false;

// Width of sides
side_thickness = 2;

// Height of sides
side_height = 20;

// Add front
front = false;

// Thickness of front
front_thickness = 2;

// Height of front
front_height = 10;

// Add magnet holes
magnet_holes = false;

// Add crush ribs
magnet_hole_crush_ribs = false;

// Add chamfer
magnet_hole_chamfer = false;


/* [Hidden] */
$fa=0.5;
$fs=0.5;


gridfinity_shelf(
    gridx=gridx,
    gridy=gridy,
    rear_offset=rear_offset,
    max_rear_offset_fillet=max_rear_offset_fillet,
    plate_thickness=plate_thickness,
    base_thickness=base_thickness,
    skeletonized=skeletonized,
    sides=sides,
    side_thickness=side_thickness,
    side_height=side_height,
    front=front,
    front_thickness=front_thickness,
    front_height=front_height,
    magnet_holes=magnet_holes,
    magnet_hole_crush_ribs=magnet_hole_crush_ribs,
    magnet_hole_chamfer=magnet_hole_chamfer,
    hanger_tolerance=hanger_tolerance,
    variant=variant
);
