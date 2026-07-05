#!/usr/bin/env python3
"""Check an STL's bounding box and connectivity against expectations.

Usage: python tools/check_stl_bbox.py MODEL.stl EXPECTED_X EXPECTED_Y EXPECTED_Z [TOL_MM]

Fails (nonzero exit) if any bbox axis deviates by more than TOL_MM (default 0.1),
or if the mesh is not a SINGLE connected shell. The shell check matters: OpenSCAD's
"manifold / genus 0" render status does NOT catch disjoint shells (e.g. a base
accidentally severed from the walls by a subtraction).

Handles both ASCII and binary STL.
"""
import re
import struct
import sys
from collections import defaultdict


def stl_triangles(path):
    """Yield triangles as 3-tuples of (x, y, z) vertex tuples."""
    with open(path, "rb") as f:
        head = f.read(5)
        f.seek(0)
        data = f.read()
    if head == b"solid" and b"facet" in data[:1000]:
        cur = []
        for m in re.finditer(rb"vertex\s+(\S+)\s+(\S+)\s+(\S+)", data):
            cur.append(tuple(float(g) for g in m.groups()))
            if len(cur) == 3:
                yield tuple(cur)
                cur = []
    else:
        (count,) = struct.unpack_from("<I", data, 80)
        for i in range(count):
            off = 84 + i * 50 + 12  # skip normal
            v = struct.unpack_from("<9f", data, off)
            yield (v[0:3], v[3:6], v[6:9])


def find(parent, a):
    while parent[a] != a:
        parent[a] = parent[parent[a]]
        a = parent[a]
    return a


def main():
    if len(sys.argv) < 5:
        sys.exit(__doc__)
    path = sys.argv[1]
    expected = [float(a) for a in sys.argv[2:5]]
    tol = float(sys.argv[5]) if len(sys.argv) > 5 else 0.1

    verts = []
    vmap = {}
    parent = []
    ntris = 0
    for tri in stl_triangles(path):
        ntris += 1
        idx = []
        for v in tri:
            key = tuple(round(c, 6) for c in v)
            if key not in vmap:
                vmap[key] = len(verts)
                verts.append(key)
                parent.append(len(parent))
            idx.append(vmap[key])
        for a, b in ((idx[0], idx[1]), (idx[1], idx[2])):
            ra, rb = find(parent, a), find(parent, b)
            if ra != rb:
                parent[ra] = rb
    if not verts:
        sys.exit(f"FAIL: no vertices found in {path}")

    ok = True

    # bounding box
    lo = [min(v[i] for v in verts) for i in range(3)]
    hi = [max(v[i] for v in verts) for i in range(3)]
    size = [hi[i] - lo[i] for i in range(3)]
    for axis, s, e in zip("XYZ", size, expected):
        delta = s - e
        status = "ok" if abs(delta) <= tol else "FAIL"
        if status == "FAIL":
            ok = False
        print(f"{axis}: {s:9.3f} mm  (expected {e:9.3f}, delta {delta:+.3f})  {status}")
    print(f"bbox: [{lo[0]:.3f},{lo[1]:.3f},{lo[2]:.3f}] .. [{hi[0]:.3f},{hi[1]:.3f},{hi[2]:.3f}]  ({len(verts)} vertices, {ntris} triangles)")

    # connectivity: must be exactly one shell
    comps = defaultdict(list)
    for i, v in enumerate(verts):
        comps[find(parent, i)].append(v)
    if len(comps) == 1:
        print("shells: 1  ok")
    else:
        ok = False
        print(f"shells: {len(comps)}  FAIL — mesh is not one connected solid:")
        for vs in sorted(comps.values(), key=len, reverse=True):
            zs = [v[2] for v in vs]
            xs = [v[0] for v in vs]
            ys = [v[1] for v in vs]
            print(f"  shell: {len(vs):5d} verts  x[{min(xs):.3f},{max(xs):.3f}] y[{min(ys):.3f},{max(ys):.3f}] z[{min(zs):.3f},{max(zs):.3f}]")

    if not ok:
        sys.exit("FAIL")
    print("PASS")


if __name__ == "__main__":
    main()
