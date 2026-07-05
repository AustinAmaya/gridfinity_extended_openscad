#!/usr/bin/env python3
"""Check an STL's bounding box against expected dimensions.

Usage: python tools/check_stl_bbox.py MODEL.stl EXPECTED_X EXPECTED_Y EXPECTED_Z [TOL_MM]

Exits nonzero (loudly) if any axis deviates by more than TOL_MM (default 0.1).
Handles both ASCII and binary STL.
"""
import re
import struct
import sys


def stl_vertices(path):
    with open(path, "rb") as f:
        head = f.read(5)
        f.seek(0)
        data = f.read()
    if head == b"solid" and b"facet" in data[:1000]:
        for m in re.finditer(rb"vertex\s+(\S+)\s+(\S+)\s+(\S+)", data):
            yield tuple(float(g) for g in m.groups())
    else:
        (count,) = struct.unpack_from("<I", data, 80)
        for i in range(count):
            off = 84 + i * 50 + 12  # skip normal
            vals = struct.unpack_from("<9f", data, off)
            yield vals[0:3]
            yield vals[3:6]
            yield vals[6:9]


def main():
    if len(sys.argv) < 5:
        sys.exit(__doc__)
    path = sys.argv[1]
    expected = [float(a) for a in sys.argv[2:5]]
    tol = float(sys.argv[5]) if len(sys.argv) > 5 else 0.1

    lo = [float("inf")] * 3
    hi = [float("-inf")] * 3
    n = 0
    for v in stl_vertices(path):
        n += 1
        for i in range(3):
            lo[i] = min(lo[i], v[i])
            hi[i] = max(hi[i], v[i])
    if n == 0:
        sys.exit(f"FAIL: no vertices found in {path}")

    size = [hi[i] - lo[i] for i in range(3)]
    ok = True
    for axis, s, e in zip("XYZ", size, expected):
        delta = s - e
        status = "ok" if abs(delta) <= tol else "FAIL"
        if status == "FAIL":
            ok = False
        print(f"{axis}: {s:9.3f} mm  (expected {e:9.3f}, delta {delta:+.3f})  {status}")
    print(f"bbox: [{lo[0]:.3f},{lo[1]:.3f},{lo[2]:.3f}] .. [{hi[0]:.3f},{hi[1]:.3f},{hi[2]:.3f}]  ({n} vertices)")
    if not ok:
        sys.exit("FAIL: bounding box does not match expected dimensions")
    print("PASS")


if __name__ == "__main__":
    main()
