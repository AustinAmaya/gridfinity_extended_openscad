// Gridfinity Paper Organizer
// A paper tray whose body overhangs its gridfinity base.
//
// The gridfinity foot pattern comes from this library (pad_grid); the body is custom
// because the library does not support a body wider than its base, nor asymmetric
// front/rear wall heights. The body is centered on the base and joined to the feet
// with a >=45 degree chamfer skirt so the overhang prints without supports.
//
// Orientation: front (low wall) faces -Y, rear (tall wall) faces +Y, matching the
// tools/render snapshot camera convention (front view = camera at -Y).

include <modules/gridfinity_constants.scad>
use <modules/module_gridfinity.scad>

/* [Interior Dimensions (mm)] */
// interior width, 3.5 inches
interior_width = 88.9;
// interior depth (front to rear), 8.5 inches
interior_depth = 215.9;
// interior height of the rear wall, 7 inches
rear_height = 177.8;
// interior height of the front wall, 3 inches
front_height = 76.2;

/* [Construction] */
// wall thickness
wall = 3;
// floor thickness above the gridfinity feet
floor_t = 3;
// gridfinity base cells across the width (X)
base_units_x = 2;
// gridfinity base cells along the depth (Y)
base_units_y = 5;

/* [Hidden] */
$fa = 4;
$fs = 0.4;
fudge = 0.01;

// --- derived dimensions ---
ext_w = interior_width + 2*wall;            // 94.9
ext_d = interior_depth + 2*wall;            // 221.9
base_w = base_units_x * gf_pitch;           // 84
base_d = base_units_y * gf_pitch;           // 210
// feet are inset from the cell grid by the standard clearance
base_skirt_w = base_w - 0.5;
base_skirt_d = base_d - 0.5;
overhang_x = (ext_w - base_w) / 2;          // 5.45
overhang_y = (ext_d - base_d) / 2;          // 5.95
// chamfer skirt must rise at least as much as the widest overhang run (>=45 deg)
skirt_run = max((ext_w - base_skirt_w)/2, (ext_d - base_skirt_d)/2);
skirt_h = ceil(skirt_run * 2) / 2 + 0.3;    // 6.5

foot_top = gfBaseHeight() - 0.25;           // 4.75, nominal top of the feet
body_z0 = foot_top - 0.05;                  // slight overlap for a clean union
cavity_z = foot_top + floor_t;              // 7.75, top of the interior floor
rear_top = cavity_z + rear_height;          // 185.55
front_top = cavity_z + front_height;        // 83.95
total_h = rear_top;

corner_r = gf_cup_corner_radius;            // 3.75
corner_r_int = max(corner_r - wall, 0.5);

// --- requirement checks ---
assert(ext_w < 3 * gf_pitch,
  str("exterior width ", ext_w, " must be strictly less than 3 gridfinity units (", 3*gf_pitch, ")"));
assert(overhang_x < gf_pitch/2,
  str("width overhang per side ", overhang_x, " must be strictly less than half a unit (", gf_pitch/2, ")"));
assert(overhang_y < gf_pitch/2,
  str("depth overhang per side ", overhang_y, " must be strictly less than half a unit (", gf_pitch/2, ")"));
assert(rear_height >= front_height, "rear wall must be at least as tall as the front wall");

echo(str("exterior: ", ext_w, " x ", ext_d, " x ", total_h,
  " | base: ", base_units_x, "x", base_units_y, " (", base_w, " x ", base_d, ")",
  " | overhang per side: x=", overhang_x, " y=", overhang_y));

paper_organizer();

// rounded-rectangle prism centered on the Z axis
module rrect(w, d, r, h) {
  linear_extrude(h)
    offset(r = r)
      square([w - 2*r, d - 2*r], center = true);
}

module paper_organizer() {
  union() {
    // gridfinity feet, clipped at their nominal top (pad tops are oversize for joining)
    intersection() {
      translate([-base_w/2, -base_d/2, 0])
        pad_grid(base_units_x, base_units_y);
      translate([0, 0, foot_top/2])
        cube([base_w + 2, base_d + 2, foot_top], center = true);
    }

    difference() {
      // body: chamfer skirt lofting from the base footprint out to the full
      // exterior, then straight walls up to the rear top
      union() {
        hull() {
          translate([0, 0, body_z0])
            rrect(base_skirt_w, base_skirt_d, corner_r, fudge);
          translate([0, 0, body_z0 + skirt_h])
            rrect(ext_w, ext_d, corner_r, fudge);
        }
        translate([0, 0, body_z0 + skirt_h])
          rrect(ext_w, ext_d, corner_r, rear_top - body_z0 - skirt_h);
      }

      // interior cavity
      translate([0, 0, cavity_z])
        rrect(interior_width, interior_depth, corner_r_int, rear_top);

      // slope cut: straight line from the rear wall's inner-face top down to the
      // front wall's inner-face top; each end wall stays flat across its thickness
      slope_cut();
    }
  }
}

module slope_cut() {
  y_front_in = -interior_depth/2;  // inner face of the front wall
  y_rear_in  =  interior_depth/2;  // inner face of the rear wall
  y_ext = ext_d/2 + 1;
  z_top = rear_top + 10;
  // polygon in (y, z), extruded across the full width (+X)
  translate([-(ext_w/2 + 1), 0, 0])
    rotate([90, 0, 90])
      linear_extrude(ext_w + 2)
        polygon([
          [-y_ext,     front_top],
          [y_front_in, front_top],
          [y_rear_in,  rear_top],
          [y_ext,      rear_top],
          [y_ext,      z_top],
          [-y_ext,     z_top]
        ]);
}
