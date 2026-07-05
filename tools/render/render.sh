#!/usr/bin/env bash
# In-container entrypoint: render a .scad file to a mesh.
# Output format is inferred from the OUTPUT extension (.stl/.3mf/.off/.csg).
#
# String -D values are auto-quoted, so callers pass clean key=value pairs with no shell
# quoting headaches (e.g. -D Part=bottom becomes the OpenSCAD define Part="bottom").
set -euo pipefail

if [[ $# -lt 2 ]]; then
  cat >&2 <<'EOF'
Usage: render INPUT.scad OUTPUT.(stl|3mf|off|csg) [-D key=value ...] [openscad args]

Examples:
  render reference/smkent-monoscad/rugged-box/rugged-box.scad out/box.stl
  render src/box.scad out/bottom.stl -D Part=bottom
  render src/box.scad out/box.stl -D Width=4 -D Length=3 -D Bottom_Height=2

Numeric/bool/vector/already-quoted values pass through unchanged; bare strings get
wrapped in quotes so OpenSCAD reads them as strings.
EOF
  exit 2
fi

input="$1"; output="$2"; shift 2
mkdir -p "$(dirname "$output")"

# Re-quote bare string -D values for OpenSCAD.
args=()
while [[ $# -gt 0 ]]; do
  if [[ "$1" == "-D" && $# -ge 2 ]]; then
    kv="$2"; shift 2
    key="${kv%%=*}"; val="${kv#*=}"
    if [[ "$val" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] \
       || [[ "$val" == "true" || "$val" == "false" || "$val" == "undef" ]] \
       || [[ "$val" == \[* ]] || [[ "$val" == \"* ]]; then
      args+=( -D "$key=$val" )          # numeric / bool / vector / already-quoted
    else
      args+=( -D "$key=\"$val\"" )      # bare string -> quote it
    fi
  else
    args+=( "$1" ); shift
  fi
done

echo "== $(openscad --version 2>&1) =="
echo "Rendering: $input -> $output ${args[*]:+[${args[*]}]}"
SECONDS=0
# --backend=manifold: explicitly use the fast Manifold backend (smkent recommends the
# fast-csg/manifold features; in OpenSCAD 2026.x fast-csg is superseded by this backend,
# which is already the default — pinned here so it can't regress).
openscad --backend=manifold --render -o "$output" "${args[@]}" "$input"
echo "OK: $output ($(du -h "$output" | cut -f1), ${SECONDS}s)"
