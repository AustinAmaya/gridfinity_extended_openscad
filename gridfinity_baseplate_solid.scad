// Solid gridfinity baseplate - a sturdy, filled-body baseplate built on the ostat
// generator. Magnets in every cell corner, a center hold-down screw per cell, a flat
// (untapered) underside, no weight cavities. Center screws force a solid floor beneath
// the sockets, so the plate is a solid slab rather than the hollow "efficient" frame.
//
// Defaults: 6x3 grid. Change num_x / num_y for other sizes. GPL-3.0 (inherits the
// ostat library license).

include <modules/gridfinity_constants.scad>
use <modules/module_gridfinity_baseplate.scad>

/* [Grid] */
// cells across X
num_x = 6;
// cells across Y
num_y = 3;

/* [Features] */
// corner magnets in every cell: [diameter, height]. [0,0] to disable.
magnet_size = [6.5, 2.4];
// center hold-down screw per cell (also forces a solid floor under the sockets)
center_screw = true;
// corner screws under the magnets
corner_screw = false;
// weight-fill cavities on the underside
weighted = false;
// flatten the underside (remove the printed-in bottom taper); Austin prefers taper ON
remove_bottom_taper = false;

/* [Hidden] */
$fa = 4;
$fs = 0.5;

echo(str("solid baseplate: ", num_x, "x", num_y, " (", num_x*gf_pitch, " x ", num_y*gf_pitch,
  " mm) | magnets ", magnet_size, ", center_screw ", center_screw,
  ", flat_bottom ", remove_bottom_taper));

gridfinity_baseplate(
  num_x = num_x,
  num_y = num_y,
  magnetSize = magnet_size,
  centerScrewEnabled = center_screw,
  cornerScrewEnabled = corner_screw,
  weightedEnable = weighted,
  remove_bottom_taper = remove_bottom_taper,
  plateOptions = "default");
