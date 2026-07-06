// Gridfinity Paper Organizer - fully gridfinity-compliant, fuzzy-skin compensated
//
// A paper tray on a 3x6 gridfinity base with asymmetric walls: tall rear, low front,
// straight sloped top edge between them. Body sits entirely within the standard bin
// envelope so organizers tile side-by-side on the grid.
//
// FUZZY SKIN COMPENSATION: printed with Bambu Studio fuzzy skin (Perlin, thickness
// 0.3, point distance 0.8, feature size 1, octaves 4, persistence 0.5, first layer
// off). Bambu's FuzzySkin.cpp computes displacement r = noise * thickness applied
// perpendicular to the wall, bidirectional: classic noise is uniform in [-1,1] (max
// +0.3mm outward) and libnoise Perlin octave sums are unnormalized but in practice
// stay within ~[-1,1]. So every exterior surface here - body AND feet - is inset
// fuzzy_allowance (0.3mm) from its standard gridfinity envelope; fuzzy peaks then
// just reach the envelope, preserving standard bin-to-bin and baseplate clearances.
// Feet are shrunk via the library's $clearance environment (0.5 + 2*allowance).
//
// Wall thickness is 3mm NOMINAL (fuzzy modulates the outer surface +-0.3). The
// interior is derived: envelope - 2*allowance - 2*wall. Interior heights are exact
// at the wall inner faces.
//
// Orientation: front (low wall) faces -Y, matching the snapshot camera convention.

include <modules/gridfinity_constants.scad>
use <modules/module_gridfinity.scad>

/* [Base] */
// gridfinity base cells across the width (X)
base_units_x = 2;
// gridfinity base cells along the depth (Y)
base_units_y = 6;

/* [Walls (mm)] */
// interior height of the rear wall, 7 inches
rear_height = 177.8;
// interior height of the front wall, 3 inches
front_height = 76.2;
// nominal wall thickness
wall = 3;
// floor thickness above the gridfinity feet
floor_t = 3;

/* [Fuzzy Skin] */
// per-side inset so fuzzy skin peaks stay inside the gridfinity envelope; equals the
// slicer's fuzzy skin thickness (max outward displacement, see header). 0 = no fuzzy.
fuzzy_allowance = 0.3;

/* [Hidden] */
$fa = 4;
$fs = 0.4;
fudge = 0.01;

// standard bin envelope for this base, then inset for fuzzy skin
base_w = base_units_x * gf_pitch;                    // 126
base_d = base_units_y * gf_pitch;                    // 252
ext_w = base_w - 0.5 - 2*fuzzy_allowance;            // 124.9
ext_d = base_d - 0.5 - 2*fuzzy_allowance;            // 250.9
interior_width = ext_w - 2*wall;                     // 118.9
interior_depth = ext_d - 2*wall;                     // 244.9

foot_top = gfBaseHeight() - 0.25;                    // 4.75, nominal top of the feet
cavity_z = foot_top + floor_t;                       // 7.75, top of the interior floor
rear_top = cavity_z + rear_height;                   // 185.55
front_top = cavity_z + front_height;                 // 83.95
total_h = rear_top;

corner_r = gf_cup_corner_radius - fuzzy_allowance;   // envelope corner is 3.75 nominal
corner_r_int = max(corner_r - wall, 0.5);

assert(fuzzy_allowance >= 0, "fuzzy_allowance must be >= 0");
assert(interior_width > 0 && interior_depth > 0, "interior collapsed - check base units / wall");
assert(rear_height >= front_height, "rear wall must be at least as tall as the front wall");
// full compliance: fuzzy peaks must not exceed the standard envelope
assert(ext_w + 2*fuzzy_allowance <= base_w - 0.5 + fudge, "width exceeds gridfinity envelope");
assert(ext_d + 2*fuzzy_allowance <= base_d - 0.5 + fudge, "depth exceeds gridfinity envelope");

echo(str("paper organizer: base ", base_units_x, "x", base_units_y,
  " | exterior ", ext_w, " x ", ext_d, " x ", total_h,
  " (envelope ", base_w - 0.5, " x ", base_d - 0.5, ", fuzzy allowance ", fuzzy_allowance, "/side)",
  " | interior ", interior_width, " x ", interior_depth,
  " | rear/front interior heights ", rear_height, "/", front_height));

paper_organizer();

// rounded-rectangle prism centered on the Z axis
module rrect(w, d, r, h) {
  linear_extrude(h)
    offset(r = r)
      square([w - 2*r, d - 2*r], center = true);
}

module paper_organizer() {
  union() {
    // gridfinity feet, inset by fuzzy_allowance via the clearance environment.
    // Pad tops are deliberately oversize (rise above foot_top, bulge outward) so
    // they interpenetrate the body, grid_block-style; trim the bulge to the body.
    intersection() {
      union() {
        $clearance = [0.5 + 2*fuzzy_allowance, 0.5 + 2*fuzzy_allowance, 0];
        translate([-base_w/2, -base_d/2, 0])
          pad_grid(base_units_x, base_units_y);
      }
      union() {
        translate([0, 0, foot_top/2 - 1])
          cube([base_w + 2, base_d + 2, foot_top + 2], center = true);
        body_solid();
      }
    }

    difference() {
      body_solid();

      // interior cavity
      translate([0, 0, cavity_z])
        rrect(interior_width, interior_depth, corner_r_int, rear_top);

      // slope cut: straight line from the rear wall's inner-face top down to the
      // front wall's inner-face top; each end wall stays flat across its thickness
      slope_cut();
    }
  }
}

// the solid outer body: straight prism on the (fuzzy-inset) bin envelope
module body_solid() {
  translate([0, 0, foot_top])
    rrect(ext_w, ext_d, corner_r, rear_top - foot_top);
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
