// Calibration fixture: RGB axis arms to verify snapshot camera presets.
// Convention (universal CAD): RED = +X, GREEN = +Y, BLUE = +Z.
module arm(len) translate([0,-3,-3]) cube([len,6,6]);
color("dimgray") translate([-6,-6,-6]) cube(12);     // origin block
color("red")   arm(34);                  // +X  (RIGHT)
color("green") rotate([0,0,90])  arm(34);// +Y  (BACK)
color("blue")  rotate([0,-90,0]) arm(34);// +Z  (TOP)
// short stubs on negative axes so we can tell +/- apart
color("salmon")     rotate([0,0,180]) arm(12);  // -X
color("lightgreen") rotate([0,0,-90]) arm(12);  // -Y (FRONT)
color("lightblue")  rotate([0,90,0])  arm(12);  // -Z (BOTTOM)
