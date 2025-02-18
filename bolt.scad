include <BOSL2/std.scad>
include <BOSL2/masks3d.scad>
include <BOSL2/threading.scad>

include <constants.scad>


module bolt(length=10, socket_width=8.4) {
    // Main bolt
    translate([0, 0, bolt_head_thickness]) {
        threaded_rod(
            d=thread_diameter - thread_tolerance,
            length=length,
            pitch=thread_pitch,
            internal=false,
            blunt_start=false,
            anchor=BOTTOM
        );
    }

    // Head
    difference() {
        // Main head
        cylinder(
            d=bolt_head_outer_diameter,
            h=bolt_head_thickness
        );

        // Cutouts
        for (i = [0:2]) {
            rotate([0, 0, i * 120]) {
                translate([bolt_head_cutout_offset, 0, 0]) {
                    cylinder(
                        r=bolt_head_cutout_radius,
                        h=bolt_head_thickness,
                        center=false
                    );
                }
            }
        }

        // Cutout rounding
        for (i = [0:2]) {
            rotate([0, 0, (i * 120) + 30]) {
                translate([(bolt_head_outer_diameter / 2) + 0.5, 0, 0]) {
                    rotate([0, 0, (i + 1 * 60) + 50])
                        rounding_edge_mask(l=bolt_head_thickness, r=2, anchor=BOTTOM);
                }
            }
        }
        for (i = [0:2]) {
            rotate([0, 0, (i * 120) - 30]) {
                translate([(bolt_head_outer_diameter / 2) + 0.5, 0, 0]) {
                    rotate([0, 0, (i + 1 * 60) + 100])
                        rounding_edge_mask(l=bolt_head_thickness, r=2, anchor=BOTTOM);
                }
            }
        }

        // Socket
        rotate([0, 0, 30])
            regular_prism(n=6, h=bolt_head_thickness, id=socket_width, center=false, chamfer1=-0.5);
    }
}
