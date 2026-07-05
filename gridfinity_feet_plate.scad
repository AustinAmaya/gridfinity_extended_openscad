// Gridfinity Feet Plate
// A bare flat plate carrying only the gridfinity foot pattern - no walls, no cavity.
// Tape (or glue) an existing box to the flat top face and it behaves like a gridfinity bin.
//
// Feet come from the library (pad_grid); the flat top slab is custom, joined to the feet
// grid_block-style (oversize pad tops embedded into the slab, then trimmed to its
// footprint) so the mesh renders as one solid piece instead of two touching shells.

include <modules/gridfinity_constants.scad>
use <modules/module_gridfinity.scad>
use <modules/utility/module_utility.scad>

/* [Base] */
// gridfinity base cells across X
base_units_x = 3;
// gridfinity base cells across Y
base_units_y = 6;

/* [Plate] */
// thickness of the flat top slab above the feet, in mm
plate_thickness = 3;

/* [Hidden] */
$fa = 4;
$fs = 0.4;
fudge = 0.01;

base_w = base_units_x * gf_pitch;   // e.g. 126 for 3 units
base_d = base_units_y * gf_pitch;   // e.g. 252 for 6 units
// standard non-overhanging bin footprint (same clearance inset pad_grid's feet use)
ext_w = base_w - 0.5;
ext_d = base_d - 0.5;

foot_top = gfBaseHeight() - 0.25;   // 4.75, nominal top of the feet
total_h = foot_top + plate_thickness;

corner_r = gf_cup_corner_radius;    // 3.75, matches standard bin footprint corners

assert(base_units_x > 0 && base_units_y > 0, "base_units_x/y must be positive");
assert(plate_thickness > 0, "plate_thickness must be positive");

echo(str("feet plate: ", base_units_x, "x", base_units_y, " units (", base_w, " x ", base_d,
  " mm) | exterior ", ext_w, " x ", ext_d, " x ", total_h, " mm"));

feet_plate();

module feet_plate() {
  union() {
    // gridfinity feet: pad tops are deliberately oversize (rise above foot_top and
    // bulge outward) so they interpenetrate the plate for a solid union; trim that
    // bulge to the plate's own footprint above foot_top
    intersection() {
      translate([-base_w/2, -base_d/2, 0])
        pad_grid(base_units_x, base_units_y);
      union() {
        translate([0, 0, foot_top/2 - 1])
          cube([base_w + 2, base_d + 2, foot_top + 2], center = true);
        plate_solid();
      }
    }

    plate_solid();
  }
}

module plate_solid() {
  translate([0, 0, foot_top])
    roundedCube(
      x = ext_w, y = ext_d, z = plate_thickness,
      topRadius = corner_r, bottomRadius = 0, sideRadius = corner_r,
      centerxy = true);
}
