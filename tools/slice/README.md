# tools/slice — prepare print files for the Bambu Lab H2D

Turn any rendered model into a **Bambu Studio project `.3mf`** (geometry + settings, ready to
open), using the saved template for the printer/process/filament/support config. You **open the
result in Bambu Studio, slice, and print** — we do *not* slice headlessly (the desktop GUI
re-slices CLI output on open anyway, so a headless slice buys nothing).

Pattern ported from `D:\202606-simpleBoxes\tools\slice\`.

## Why a template (the H2D wrinkle)

A bare STL carries no printer/filament setup, and the H2D is a **dual-nozzle** printer: opening
a bare STL leaves the filament→extruder mapping unset. A Bambu **project `.3mf`** carries the
`filament_map` + plate binding + full process config, so it opens **already configured** for
H2D + PLA (+ Support-for-PLA interface) + supports. We swap fresh meshes into the saved
template and reuse everything else.

## The template: `gridfinity-slicer-template.3mf` (repo root, version-tracked)

- **Single object at plate center (175, 160)** — unlike the simpleBoxes templates, this repo's
  models vary in footprint, so `swap_mesh.py` re-centers the incoming mesh in X/Y/Z and it
  lands at plate center whatever its size.
- **Provenance:** derived programmatically (2026-07-05) from simpleBoxes'
  `box-slicer-template.3mf` — its H2D + PLA + PLA-S-interface + supports project config,
  stripped to one object. That config includes a **0.6mm nozzle profile**.
- The config lives in `Metadata/project_settings.config` inside the `.3mf`; `swap_mesh.py`
  never touches it. **Whatever the template holds is what everything prints with.**

### Changing the config (GUI round-trip)
1. Open `gridfinity-slicer-template.3mf` directly in Bambu Studio.
2. Change settings in the Process/Filament panels. Don't slice — config saves regardless.
3. **Save Project As** → the same file (watch out: Bambu may append `_plate_1` to the name).
4. Commit it: the commit message is the changelog (the `.3mf` is binary).

## One command: .scad → print-ready .3mf

```powershell
.\tools\slice\print-prep.ps1 gridfinity_paper_organizer.scad
# -> print-ready\gridfinity_paper_organizer.3mf   (open in Bambu Studio, slice, print)

.\tools\slice\print-prep.ps1 gridfinity_basic_cup.scad -Name cup_2x3 -Define width=2,depth=3
```

This renders via `tools\render\render.ps1`, verifies the mesh is one connected shell
(`tools\check_stl_bbox.py`), swaps it into the template, and delivers to `print-ready\`
(git-ignored). To skip the render and just wrap an existing STL:

```powershell
.\tools\slice\prepare.ps1 -Parts out\model.stl -Output out\model.3mf
```

## Files
- `swap_mesh.py` — swap meshes into a template `.3mf`. Single part + single-object template →
  mesh re-centered in X/Y/Z (lands at the template's plate position). Multiple parts → parts
  must be pre-positioned; objects matched by Z-span order (simpleBoxes behavior).
- `prepare.ps1` — STL(s) → project `.3mf` + copy into `print-ready\`.
- `print-prep.ps1` — the full `.scad` → `print-ready\*.3mf` pipeline.
