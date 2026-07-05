// Trivial fixture to smoke-test the dockerized renderer end to end.
// render: tools/render/render.ps1 tools\render\smoketest.scad out\smoketest.stl
$fn = 32;
difference() {
    cube([20, 20, 10], center = true);
    cylinder(h = 12, r = 6, center = true);
}
