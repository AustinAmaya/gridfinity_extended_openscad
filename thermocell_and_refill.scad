// Thermocell and Refill - gridfinity module (3 wide x 6 deep)
//
// A flat gridfinity plate with two blind pockets: a round pocket for a Thermacell
// unit (4" dia) and a rectangular pocket for a refill box (4.25 x 3.13"), both 2"
// deep. Fully gridfinity-compliant (tiles on the grid, sits on standard baseplates):
// the body sits inside the standard bin envelope minus a fuzzy-skin allowance, and
// the feet are inset the same amount, so Perlin fuzzy-skin peaks just reach the
// envelope. See gridfinity_paper_organizer.scad for the same pattern.
//
// Orientation: rectangle pocket toward the front (-Y), cylinder toward the back (+Y).

include <modules/gridfinity_constants.scad>
use <modules/module_gridfinity.scad>

/* [Base] */
// gridfinity base cells across the width (X)
base_units_x = 3;
// gridfinity base cells along the depth (Y)
base_units_y = 6;

/* [Pockets (mm)] */
// round pocket diameter, 4 inches
cyl_diameter = 101.6;
// rectangular pocket, 4.25 inches wide (X)
rect_width = 107.95;
// rectangular pocket, 3.13 inches deep (Y)
rect_depth = 79.502;
// rounded inner corners on the rectangular pocket
rect_corner_r = 3;
// pocket depth, 2 inches
pocket_depth = 50.8;

/* [Construction] */
// solid floor thickness beneath the pockets
floor_t = 3;
// per-side inset so fuzzy-skin peaks stay inside the gridfinity envelope; equals the
// slicer's fuzzy skin thickness (max outward displacement). 0 = no fuzzy.
fuzzy_allowance = 0.3;

/* [Hidden] */
$fa = 3;
$fs = 0.4;
fudge = 0.01;

// standard bin envelope for this base, inset for fuzzy skin
base_w = base_units_x * gf_pitch;                    // 126
base_d = base_units_y * gf_pitch;                    // 252
ext_w = base_w - 0.5 - 2*fuzzy_allowance;            // 124.9
ext_d = base_d - 0.5 - 2*fuzzy_allowance;            // 250.9
corner_r = gf_cup_corner_radius - fuzzy_allowance;   // 3.45

foot_top = gfBaseHeight() - 0.25;                    // 4.75, nominal top of the feet
total_h = foot_top + floor_t + pocket_depth;         // top of the plate

// lay the two pockets along Y with equal margins/gap
pocket_span = cyl_diameter + rect_depth;
gap = (ext_d - pocket_span) / 3;
rect_cy = -ext_d/2 + gap + rect_depth/2;             // rectangle toward front
cyl_cy  =  ext_d/2 - gap - cyl_diameter/2;           // cylinder toward back

// requirement / sanity checks
assert(fuzzy_allowance >= 0, "fuzzy_allowance must be >= 0");
assert(cyl_diameter + 6 <= ext_w, "cylinder pocket too wide for the plate");
assert(rect_width + 6 <= ext_w, "rectangle pocket too wide for the plate");
assert(gap >= 3, "pockets leave too little material along the length; reduce a pocket or add depth");
assert(pocket_depth + floor_t + foot_top <= total_h + fudge, "pocket deeper than the plate");
assert(ext_w + 2*fuzzy_allowance <= base_w - 0.5 + fudge, "width exceeds gridfinity envelope");
assert(ext_d + 2*fuzzy_allowance <= base_d - 0.5 + fudge, "depth exceeds gridfinity envelope");

echo(str("thermocell and refill: base ", base_units_x, "x", base_units_y,
  " | exterior ", ext_w, " x ", ext_d, " x ", total_h,
  " | cylinder d", cyl_diameter, " @y", cyl_cy,
  " | rect ", rect_width, "x", rect_depth, " @y", rect_cy,
  " | pockets ", pocket_depth, " deep, gaps ", gap));

thermocell_and_refill();

// rounded-rectangle prism centered on the Z axis
module rrect(w, d, r, h) {
  linear_extrude(h)
    offset(r = r)
      square([w - 2*r, d - 2*r], center = true);
}

module thermocell_and_refill() {
  union() {
    // gridfinity feet, inset by fuzzy_allowance via the clearance environment; pad
    // tops are oversize and embed into the body, then get trimmed to its silhouette
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

      // round pocket (Thermacell unit)
      translate([0, cyl_cy, total_h - pocket_depth])
        cylinder(d = cyl_diameter, h = pocket_depth + fudge);

      // rectangular pocket (refill box)
      translate([0, rect_cy, total_h - pocket_depth])
        rrect(rect_width, rect_depth, rect_corner_r, pocket_depth + fudge);
    }
  }
}

// the solid outer body: a straight prism on the fuzzy-inset bin envelope
module body_solid() {
  translate([0, 0, foot_top])
    rrect(ext_w, ext_d, corner_r, total_h - foot_top);
}
