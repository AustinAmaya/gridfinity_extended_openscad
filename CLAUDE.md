# Custom Gridfinity (fork of ostat/gridfinity_extended_openscad)

Fork: `AustinAmaya/gridfinity_extended_openscad` (origin) / `ostat/...` (upstream), GPL-3.0.
Custom work lives on the `custom` branch; keep `main` clean for upstream sync.

## What's custom here vs upstream

- `tools/render/` — dockerized OpenSCAD render + PNG-snapshot pipeline (ported from
  D:\202606-simpleBoxes). No local OpenSCAD needed, just Docker. See `tools/render/README.md`.
- `tools/slice/` — Bambu Studio print-prep: swaps rendered meshes into the version-tracked
  `gridfinity-slicer-template.3mf` (H2D + PLA + Support-for-PLA config). See `tools/slice/README.md`.
- `tools/check_stl_bbox.py` — STL bounding-box + shell-connectivity verification.
- `gridfinity_paper_organizer.scad` — custom model (pattern below).
- Everything else is upstream library code. Entry `.scad` files live at repo root;
  all real logic is in `modules/`.

## Render & verify workflow (Claude: use this loop for any geometry change)

```powershell
# PNG snapshots for visual verification — Claude reads these images
.\tools\render\snapshot.ps1 <model>.scad out\<name> -Views "iso,front,right,top,bottom"

# Mesh render (proves manifold) then dimension + connectivity check
.\tools\render\render.ps1 <model>.scad out\<name>.stl
python tools\check_stl_bbox.py out\<name>.stl <X> <Y> <Z>
```

**Always run check_stl_bbox.py** — besides the bbox it verifies the mesh is ONE connected
shell. OpenSCAD's "manifold / Genus 0" render status does NOT catch disjoint shells (a
subtraction once severed the walls from the base and OpenSCAD still reported genus 0).
For joints/seams, also render a close-up: intersect the model with a small cube around the
joint in a throwaway .scad (see git history for out\_inspect_corner.scad) and snapshot it.

The deliverable for a finished model is a **print-ready Bambu project .3mf**:

```powershell
.\tools\slice\print-prep.ps1 <model>.scad            # render + verify + template swap
# -> print-ready\<model>.3mf : Austin opens it in Bambu Studio, slices, prints
```

- Views are calibrated: front = −Y, back = +Y, right = +X, top = +Z (fixture: `tools/render/_orient.scad`).
- Model your parts with the front facing −Y so "front" snapshots mean what they say.
- `out/` is git-ignored; renders are ephemeral.
- `-Define key=val` overrides customizer params on either script.

## Fuzzy skin compensation (Austin prints containers with fuzzy skin)

Bambu Studio fuzzy skin (FuzzySkin.cpp) displaces the outer wall by r = noise * thickness,
bidirectional, perpendicular to the wall. Classic noise is uniform [-1,1] → max outward =
full thickness; Perlin octave sums are unnormalized but practically within ~[-1,1]. Austin's
profile: Perlin, thickness 0.3 → allow **0.3mm/side**. For gridfinity-compliant parts, inset
EVERY exterior surface by that allowance from its standard envelope — body walls AND feet
(feet via `$clearance = [0.5 + 2*allowance, 0.5 + 2*allowance, 0]` around the pad_grid call).
Fuzzy peaks then just reach the standard envelope; bin-to-bin and baseplate clearances hold.
Wall thickness stays nominal (fuzzy modulates the surface); interior dims are derived.

## Pattern: custom body on a gridfinity base

The library does NOT support a body that overhangs its base or asymmetric wall heights.
The working pattern (see `gridfinity_paper_organizer.scad`):

1. `include <modules/gridfinity_constants.scad>` + `use <modules/module_gridfinity.scad>`.
2. Feet: `pad_grid(num_x, num_y)` — spans `[0, 42*num_x] × [0, 42*num_y]`, translate to center.
   Nominal foot top is `gfBaseHeight() - 0.25` = 4.75mm. Pad tops are deliberately OVERSIZE
   (rise to ~5.2mm, bulge outward) so they interpenetrate the body: start the body at 4.75,
   let the pad tops embed into it, and trim the bulge by intersecting the feet with
   (below-4.75 prism ∪ body solid). Do NOT clip the feet at 4.75 and butt the body against
   them — near-coincident faces make crack artifacts and fragile seams.
3. Body: any custom solid centered over the feet. If it overhangs the base footprint
   (max strictly < 21mm/side), a flat horizontal underside is FINE — Austin's H2D prints
   horizontal overhangs cleanly with dedicated support material (see "Printer" below). Only
   add a chamfer skirt when it looks better. If you do use a chamfer: the interior floor must
   sit at or above the chamfer's top, else the cavity subtraction severs the walls from the
   base (the exterior below the chamfer top is narrower than the interior).
   Feet footprint is `42*n − 0.5` (clearance inset).
4. Key constants: `gf_pitch=42`, `gf_cup_corner_radius=3.75`, `gfBaseHeight()=5`.
5. Put `assert()`s for hard constraints and an `echo()` of computed exterior dims in the model —
   they print on every render.

## Printer

Bambu Lab H2D: dual nozzle, build volume 300 × 320 × 325mm (dual-nozzle). PLA with
"Support for PLA" as dedicated support material — horizontal overhangs print well with
supports, so don't design around them unless aesthetics call for it.

## Paper organizer spec (current: fully gridfinity-compliant)

Base 2×6 units, body inside the standard bin envelope minus 0.3mm/side fuzzy allowance:
exterior 82.9 × 250.9 × 185.55mm, walls/floor 3mm nominal, interior derived 76.9 × 244.9mm.
Rear wall 7in (177.8) / front wall 3in (76.2) interior heights at the inner faces, straight
sloped top edge between them. No overhang, no chamfer skirt (both were v1, superseded when
Austin required full compliance). Companion `spring_follower.scad` (PC, 73mm wide) presses
stacks against a wall; sizes 3/4/5in via -Define total_length. Its serpentine columns
auto-fall-back to in-phase when the unit is too narrow for mirrored phases to clear.
