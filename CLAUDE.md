# Custom Gridfinity (fork of ostat/gridfinity_extended_openscad)

Fork: `AustinAmaya/gridfinity_extended_openscad` (origin) / `ostat/...` (upstream), GPL-3.0.
Custom work lives on the `custom` branch; keep `main` clean for upstream sync.

## What's custom here vs upstream

- `tools/render/` — dockerized OpenSCAD render + PNG-snapshot pipeline (ported from
  D:\202606-simpleBoxes). No local OpenSCAD needed, just Docker. See `tools/render/README.md`.
- `tools/check_stl_bbox.py` — STL bounding-box verification.
- `gridfinity_paper_organizer.scad` — custom model (pattern below).
- Everything else is upstream library code. Entry `.scad` files live at repo root;
  all real logic is in `modules/`.

## Render & verify workflow (Claude: use this loop for any geometry change)

```powershell
# PNG snapshots for visual verification — Claude reads these images
.\tools\render\snapshot.ps1 <model>.scad out\<name> -Views "iso,front,right,top,bottom"

# Mesh render (proves manifold) then dimension check
.\tools\render\render.ps1 <model>.scad out\<name>.stl
python tools\check_stl_bbox.py out\<name>.stl <X> <Y> <Z>
```

- Views are calibrated: front = −Y, back = +Y, right = +X, top = +Z (fixture: `tools/render/_orient.scad`).
- Model your parts with the front facing −Y so "front" snapshots mean what they say.
- `out/` is git-ignored; renders are ephemeral.
- `-Define key=val` overrides customizer params on either script.

## Pattern: custom body on a gridfinity base

The library does NOT support a body that overhangs its base or asymmetric wall heights.
The working pattern (see `gridfinity_paper_organizer.scad`):

1. `include <modules/gridfinity_constants.scad>` + `use <modules/module_gridfinity.scad>`.
2. Feet: `pad_grid(num_x, num_y)` — spans `[0, 42*num_x] × [0, 42*num_y]`, translate to center.
   Nominal foot top is `gfBaseHeight() - 0.25` = 4.75mm; pad tops above that are deliberately
   oversize for union-joining — clip at 4.75 (intersection) and overlap your body slightly below it.
3. Body: any custom solid centered over the feet. If it overhangs the base footprint
   (max strictly < 21mm/side), join with a ≥45° chamfer skirt so it prints support-free.
   Feet footprint is `42*n − 0.5` (clearance inset).
4. Key constants: `gf_pitch=42`, `gf_cup_corner_radius=3.75`, `gfBaseHeight()=5`.
5. Put `assert()`s for hard constraints and an `echo()` of computed exterior dims in the model —
   they print on every render.

## Paper organizer spec (the proof-of-concept)

Interior 3.5in × 8.5in (88.9 × 215.9mm); rear wall 7in (177.8), front wall 3in (76.2),
straight sloped top edge between the inner faces; walls/floor 3mm; base 2×5 units, no magnets;
exterior 94.9 × 221.9 × 185.55mm (must stay strictly < 126mm wide = 3 units).
