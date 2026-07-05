#!/usr/bin/env bash
# In-container: render PNG snapshots of a .scad from standard named directions.
# PNG export needs a GL context, so OpenSCAD runs under xvfb (virtual framebuffer).
#
# Usage: snapshot INPUT.scad OUTDIR [views] [-D key=value ...]
#   views: comma-separated subset of: iso,front,back,left,right,top,bottom (default: iso,front,right,top)
# Env: IMGSIZE=WxH (default 1000x750), RENDER=1 to do a full CGAL render (slower, exact).
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: snapshot INPUT.scad OUTDIR [views=iso,front,right,top] [-D k=v ...]" >&2
  exit 2
fi
input="$1"; outdir="$2"; shift 2

views="iso,front,right,top"
if [[ $# -gt 0 && "$1" != -* ]]; then views="$1"; shift; fi
mkdir -p "$outdir"

size="${IMGSIZE:-1000,750}"; size="${size/x/,}"
base="$(basename "${input%.scad}")"
# NOTE: --render takes a value in OpenSCAD 2026 CLI; bare --render swallows the next arg.
render_flag=(); [[ "${RENDER:-0}" == "1" ]] && render_flag=(--render=true)

# Re-quote bare string -D values (same convention as render.sh).
defs=()
while [[ $# -gt 0 ]]; do
  if [[ "$1" == "-D" && $# -ge 2 ]]; then
    kv="$2"; shift 2; key="${kv%%=*}"; val="${kv#*=}"
    if [[ "$val" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || [[ "$val" == true || "$val" == false || "$val" == undef ]] \
       || [[ "$val" == \[* ]] || [[ "$val" == \"* ]]; then
      defs+=(-D "$key=$val")
    else
      defs+=(-D "$key=\"$val\"")
    fi
  else defs+=("$1"); shift; fi
done

# Vector camera presets: eyex,eyey,eyez, centerx,centery,centerz (eye looks at origin).
# Unambiguous: eye on +Z => top, eye on -Y => front, etc. --viewall auto-fits distance.
# Convention: front = -Y face, back = +Y, right = +X, left = -X, top = +Z, bottom = -Z.
camera_for() {
  D=300
  case "$1" in
    iso)    echo "$D,-$D,$D,0,0,0";;
    front)  echo "0,-$D,0,0,0,0";;
    back)   echo "0,$D,0,0,0,0";;
    right)  echo "$D,0,0,0,0,0";;
    left)   echo "-$D,0,0,0,0,0";;
    top)    echo "0,0,$D,0,0,0";;
    bottom) echo "0,0,-$D,0,0,0";;
    *)      echo "$D,-$D,$D,0,0,0";;
  esac
}

echo "== $(openscad --version 2>&1) =="
IFS=',' read -ra vlist <<< "$views"
for v in "${vlist[@]}"; do
  cam="$(camera_for "$v")"
  out="$outdir/$base.$v.png"
  echo "snapshot [$v] camera=$cam -> $out"
  xvfb-run -a openscad -o "$out" --backend=manifold \
    --imgsize="$size" --viewall --autocenter --camera="$cam" \
    --colorscheme=Tomorrow "${render_flag[@]}" "${defs[@]}" "$input"
done
echo "done -> $outdir"
