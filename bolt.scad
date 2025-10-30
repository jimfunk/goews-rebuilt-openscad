include <BOSL2/std.scad>
include <BOSL2/masks3d.scad>
include <BOSL2/screw_drive.scad>
include <BOSL2/threading.scad>

include <constants.scad>


default_phillips_2_depth = 4.429;
default_phillips_3_depth = 5.314;

module bolt(
    length=10,  // Length of bolt not including head
    head_type=bolt_head_type_original,  // Head type
    head_recess_type=bolt_head_recess_type_hex,  // Recess type
    head_recess_depth=0,  // Recess depth. If 0 a default based on the type will be used
    hex_socket_width=8.4,  // Width of hex socket recess
    slot_recess_width=2,  // Width of slot recess
    slot_recess_length=10,  // Length of slot recess
) {
    difference() {
        union() {
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

                translate([0, 0, -0.1]) {
                    // Head type
                    if (head_type == bolt_head_type_original) {
                        // Cutouts
                        for (i = [0:2]) {
                            rotate([0, 0, i * 120]) {
                                translate([bolt_head_cutout_offset, 0, 0]) {
                                    cylinder(
                                        r=bolt_head_cutout_radius,
                                        h=bolt_head_thickness + 0.2,
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
                                        rounding_edge_mask(l=bolt_head_thickness + 0.2, r=2, anchor=BOTTOM);
                                }
                            }
                        }
                        for (i = [0:2]) {
                            rotate([0, 0, (i * 120) - 30]) {
                                translate([(bolt_head_outer_diameter / 2) + 0.5, 0, 0]) {
                                    rotate([0, 0, (i + 1 * 60) + 100])
                                        rounding_edge_mask(l=bolt_head_thickness + 0.2, r=2, anchor=BOTTOM);
                                }
                            }
                        }
                    }
                }
            }
        }

        // Recess
        translate([0, 0, -0.1]) {
            if (head_recess_type == bolt_head_recess_type_hex) {
                depth = head_recess_depth ? head_recess_depth : bolt_head_thickness;
                rotate([0, 0, 30])
                    regular_prism(n=6, h=depth + 0.1, id=hex_socket_width, center=false, chamfer1=-0.5);
            } else if (head_recess_type == bolt_head_recess_type_slot) {
                depth = head_recess_depth ? head_recess_depth : bolt_head_thickness;
                cube([slot_recess_length, slot_recess_width, depth + 0.1], anchor=BOTTOM);
            } else if (head_recess_type == bolt_head_recess_type_philips_2) {
                depth = head_recess_depth > default_phillips_2_depth ? head_recess_depth - default_phillips_2_depth : 0;
                translate([0, 0, depth])
                    phillips_mask(size=2, anchor=TOP, orient=DOWN);
                    zcyl(d=6, h=depth + 0.1, anchor=BOTTOM);
            } else if (head_recess_type == bolt_head_recess_type_philips_3) {
                depth = head_recess_depth > default_phillips_3_depth ? head_recess_depth - default_phillips_3_depth : 0;
                translate([0, 0, depth])
                    phillips_mask(size=3, anchor=TOP, orient=DOWN);
                    zcyl(d=8, h=depth + 0.1, anchor=BOTTOM);
            }
        }
    }
}
