# Dockerized OpenSCAD renderer

Programmatic, reproducible rendering of `.scad` files to printable meshes and PNG snapshots —
**no local OpenSCAD install required**, just Docker. Ported from `D:\202606-simpleBoxes`
(source is bind-mounted at run time, so editing a `.scad` needs no image rebuild).

## Files
- `Dockerfile` — `openscad/openscad` (pinned nightly) + xvfb + the entrypoint scripts. Build once.
- `render.sh` — in-container mesh entrypoint: `render INPUT.scad OUTPUT.ext [openscad args]`.
- `render.ps1` — host wrapper (Windows/PowerShell): builds the image on first use, mounts the
  repo, renders a mesh. **This is the entrypoint you call.**
- `snapshot.sh` / `snapshot.ps1` — same, but multi-view PNG snapshots for visual verification.
- `smoketest.scad` — trivial fixture to verify the pipeline end to end.
- `_orient.scad` — RGB-axis fixture the camera presets were calibrated against
  (red = +X, green = +Y, blue = +Z).

## Usage (PowerShell)
```powershell
# Smoke test
.\tools\render\render.ps1 tools\render\smoketest.scad out\smoketest.stl

# Render a model from this repo
.\tools\render\render.ps1 gridfinity_paper_organizer.scad out\paper_organizer.stl

# Parametric override
.\tools\render\render.ps1 gridfinity_paper_organizer.scad out\po.stl -Define wall=3,base_units_y=5

# Raw OpenSCAD passthrough (e.g. binary STL, ~3x smaller)
.\tools\render\render.ps1 src\box.scad out\box.stl -OpenscadArg '--export-format=binstl'
```
Output format is inferred from the extension: `.stl`, `.3mf`, `.off`, `.csg`.
Renders use `--backend=manifold` and land in `out\` (git-ignored).

## Usage (raw docker, any shell)
```bash
docker build -t gfx-render tools/render
docker run --rm -v "$PWD:/work" -w /work gfx-render \
    gridfinity_paper_organizer.scad out/paper_organizer.stl -D wall=3
```

## Visual evaluation (PNG snapshots)
`snapshot.ps1` renders PNGs from standard named directions so a render can be **visually
checked** (including by Claude, who can view the images). The image carries `xvfb` so
OpenSCAD can export PNG headlessly (PNG needs a GL context).
```powershell
.\tools\render\snapshot.ps1 gridfinity_paper_organizer.scad out\paper_organizer -Views "iso,front,right,top,bottom"
```
- **Views:** `iso, front, back, left, right, top, bottom`. Vector cameras (eye→origin),
  calibrated: front = −Y, back = +Y, right = +X, left = −X, top = +Z, bottom = −Z.
- `-ImgSize 760x600` sets resolution; `-FullRender` does an exact render (slower) vs
  the default fast preview.
- `-Define key=val` works the same as render.ps1; string values are auto-quoted.
- **Contact sheet** for a quick overview (ImageMagick on the host):
  ```powershell
  magick montage out\paper_organizer\*.png -label '%t' -tile 4x2 -geometry 360x288+6+6 -background white out\sheet.png
  ```

## Notes
- Force an image rebuild with `docker rmi gfx-render`; override the OpenSCAD version with
  `docker build --build-arg OPENSCAD_TAG=... tools/render`.
- OpenSCAD 2026 exports ASCII STL by default; slicers read both. Use
  `-OpenscadArg '--export-format=binstl'` for binary.
- This repo's `.scad` files use repo-relative includes, so the single `/work` mount suffices
  (the `OPENSCADPATH=/libs` mechanism is still in the image if an external library is ever needed).
