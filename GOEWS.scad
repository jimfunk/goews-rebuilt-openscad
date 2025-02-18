include <BOSL2/std.scad>
include <BOSL2/threading.scad>

include <constants.scad>
use <bolt.scad>
use <hanger.scad>
use <hook.scad>
use <parsers.scad>
use <tile.scad>

/* [Primary parameters] */
// Which part to build
part = 0; // [0: Tile, 1: Hook, 2: Bolt]

// Which variant to use
variant = 0; // [0: Original, 1: Thicker cleats]

// Added to hangers to allow for easier insertion and removal. This can be reduced to make hanger plates tighter to the tile. It reduces the tilt but makes them harder to insert and remove
hanger_tolerance = 0.15;

/* [Tile parameters] */
// Tile columns in units
tile_columns = 4;

// Tile rows in units
tile_rows = 4;

// List of tile positions to skip. Each entry is a pair of 1-based row and column coordinates with the origin at the lower left, eg: [1, 2], [3, 4]
tile_skip_list = "";

/* [Hook parameters] */
// Hook width in mm
hook_width = 10;

// Hook shank length in mm
hook_shank_length = 10;

// Hook shank thickness in mm
hook_shank_thickness = 8;

// Hook post height in mm
hook_post_height = 18;

// Hook post thickness in mm
hook_post_thickness = 6;

// Hook rounding on the outer corners in mm
hook_rounding = 0.5;

/* [Bolt parameters] */
// Bolt length in mm
bolt_length = 9;

// Bolt socket width in mm
bolt_socket_width = 8.4;

/* [Hidden] */
$fa=0.5;
$fs=0.5;


// The part to model
if (part == 0)
    tile(
        variant=variant,
        columns=tile_columns,
        rows=tile_rows,
        skiplist=parse_vector_list(tile_skip_list)
    );
else if (part == 1)
    hook(
        variant=variant,
        width=hook_width,
        shank_length=hook_shank_length,
        shank_thickness=hook_shank_thickness,
        post_height=hook_post_height,
        post_thickness=hook_post_thickness,
        hanger_tolerance=hanger_tolerance,
        rounding=hook_rounding
    );
else if (part == 2)
    bolt(
        length=bolt_length,
        socket_width=bolt_socket_width
    );
