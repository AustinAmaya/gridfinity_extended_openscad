// Spring Follower - printable compression spring + follower plate
// for the paper organizer (gridfinity_paper_organizer.scad).
//
// Keeps a stack of flat items pressed against a box wall so they stay standing.
// One end is a flat base plate that sits against the box interior wall; the other
// is a flat follower plate that presses the stack; between them, serpentine leaf
// springs provide compliance along Y.
//
// The whole unit is a single 2D profile extruded in Z: it prints standing, in
// place, with no supports, and every layer contains the full serpentine curve so
// flexing stress runs along the perimeter lines, never across layer bonds.
//
// Print a series of sizes to cover different gap ranges (see -Define examples in
// the repo docs): total_length 127 (5in), 101.6 (4in), 76.2 (3in). Use the size
// whose free length just exceeds your gap: printed PLA springs are happiest (and
// creep least) in the first ~half of their stroke. Nominal stroke is ~1in each.
//
// Stiffness knobs, strongest first: leaf_t (force ~ t^3; 0.6 = one 0.6mm-nozzle
// perimeter, 1.2 = two), amplitude (force ~ 1/A^2), height (force ~ h), columns.

/* [Size] */
// total free length from base plate back face to follower front face, in mm (127 = 5in, 101.6 = 4in, 76.2 = 3in)
total_length = 127;
// overall width across the box (X); box interior is 88.9, leave sliding clearance
width = 84;
// extrusion height (Z); also the follower height
height = 70;

/* [Plates] */
// follower plate thickness (the flat face that presses the stack)
follower_t = 3;
// base plate thickness (the flat face against the box wall)
base_t = 3;

/* [Spring] */
// leaf thickness; 0.6 = single perimeter with a 0.6 nozzle, 1.2 = two (8x stiffer)
leaf_t = 0.6;
// wave amplitude, each side of the column centerline
amplitude = 14;
// number of serpentine columns
columns = 2;
// target half-period length in mm (sets wave count; actual is rounded to fit)
half_period_target = 18;
// how far the leaf ends embed into the plates
embed = 1.5;

/* [Hidden] */
$fa = 4;
$fs = 0.4;

spring_len = total_length - base_t - follower_t;
half_periods = max(3, round(spring_len / half_period_target));
col_spacing = columns > 1 ? (width - 2*(amplitude + leaf_t + 6)) / (columns - 1) : 0;

assert(spring_len > 20, "total_length leaves too little room for the spring");
assert(columns >= 1, "columns must be >= 1");
assert(amplitude + leaf_t/2 + 2 < width/2, "amplitude too large for width");

echo(str("spring follower: total ", total_length, " x ", width, " x ", height,
  " mm | spring length ", spring_len, ", ", half_periods, " half-periods, leaf ",
  leaf_t, "mm, amplitude ", amplitude, "mm, ", columns, " column(s)"));

linear_extrude(height) profile2d();

// serpentine path for one column: x offset as a function of y in [0, spring_len]
function wave(y) = amplitude * sin(180 * half_periods * y / spring_len);

module profile2d() {
  union() {
    // base plate, back face at y=0
    plate2d(base_t/2);
    // follower plate, front face at y=total_length
    plate2d(total_length - follower_t/2);

    // serpentine columns, alternating phase so lateral forces cancel
    for (c = [0 : columns - 1]) {
      cx = columns > 1 ? -col_spacing*(columns-1)/2 + c*col_spacing : 0;
      phase = (c % 2 == 0) ? 1 : -1;
      translate([cx, 0])
        scale([phase, 1])
          leaf2d();
    }
  }
}

module plate2d(cy) {
  r = 1;
  translate([0, cy])
    offset(r = r)
      square([width - 2*r, (cy < total_length/2 ? base_t : follower_t) - 2*r], center = true);
}

// one leaf as a thick polyline: hull-chain of circles along the sine path,
// with straight end segments embedded into the plates
module leaf2d() {
  steps = 20 * half_periods;
  pts = concat(
    [[0, base_t - embed]],
    [for (i = [0 : steps]) [wave(i/steps * spring_len), base_t + i/steps * spring_len]],
    [[0, base_t + spring_len + embed]]
  );
  for (i = [0 : len(pts) - 2])
    hull() {
      translate(pts[i]) circle(d = leaf_t);
      translate(pts[i+1]) circle(d = leaf_t);
    }
}
