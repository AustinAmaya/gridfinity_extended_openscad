"""Swap freshly-rendered meshes into a Bambu Studio template .3mf.

Reuses the template's proven plate / printer / process / filament / support config
(H2D dual-nozzle: the project .3mf carries filament_map + plate binding, which a bare
STL cannot), replacing each object's mesh bytes and re-seating it on the bed.

Adapted from D:\\202606-simpleBoxes\\tools\\slice\\swap_mesh.py for gridfinity models of
ARBITRARY footprint: with a single part and a single template object, the incoming mesh
is re-centered in X/Y/Z, so it lands wherever the template placed its object (plate
center) regardless of size. With multiple parts, meshes keep their X/Y (parts must be
pre-positioned on the plate) and objects are matched to parts by Z-span order.

Usage: python swap_mesh.py <template.3mf> <out.3mf> <part1.stl> [<part2.stl> ...]
"""
import re
import struct
import sys
import zipfile


def stl_vertices_triangles(path):
    """Read ASCII or binary STL -> (verts list, tris list of index triples)."""
    with open(path, "rb") as f:
        head = f.read(5)
        f.seek(0)
        data = f.read()
    verts, tris, vmap, cur = [], [], {}, []

    def add(v):
        if v not in vmap:
            vmap[v] = len(verts)
            verts.append(v)
        cur.append(vmap[v])
        if len(cur) == 3:
            tris.append(tuple(cur))
            cur.clear()

    if head == b"solid" and b"facet" in data[:1000]:
        for m in re.finditer(rb"vertex\s+(\S+)\s+(\S+)\s+(\S+)", data):
            add(tuple(float(g) for g in m.groups()))
    else:
        (count,) = struct.unpack_from("<I", data, 80)
        for i in range(count):
            off = 84 + i * 50 + 12
            v = struct.unpack_from("<9f", data, off)
            add(v[0:3]); add(v[3:6]); add(v[6:9])
    return verts, tris


def part_mesh(path, center_xy):
    verts, tris = stl_vertices_triangles(path)
    xs = [v[0] for v in verts]; ys = [v[1] for v in verts]; zs = [v[2] for v in verts]
    zspan = max(zs) - min(zs)
    cx = (min(xs) + max(xs)) / 2.0 if center_xy else 0.0
    cy = (min(ys) + max(ys)) / 2.0 if center_xy else 0.0
    cz = (min(zs) + max(zs)) / 2.0
    vx = "".join('<vertex x="%.6f" y="%.6f" z="%.6f"/>' % (v[0] - cx, v[1] - cy, v[2] - cz) for v in verts)
    tx = "".join('<triangle v1="%d" v2="%d" v3="%d"/>' % t for t in tris)
    mesh = "<mesh><vertices>%s</vertices><triangles>%s</triangles></mesh>" % (vx, tx)
    return zspan, zspan / 2.0, mesh


def model_zspan(data):
    zs = [float(v) for v in re.findall(r'z="(-?[\d.eE+]+)"', data)]
    return (max(zs) - min(zs)) if zs else 0.0


def main(template, out, *parts):
    zt = zipfile.ZipFile(template)
    items = {n: zt.read(n) for n in zt.namelist()}
    asm = items["3D/3dmodel.model"].decode("utf-8", "ignore")

    # map object_N.model -> its parent assembly object id (which the build <item> references)
    parent_of = {}
    for mo in re.finditer(r'<object id="(\d+)"[^>]*>\s*<components>?\s*<component p:path="/3D/Objects/([^"]+)"', asm, re.S):
        parent_of[mo.group(2)] = mo.group(1)

    tmpl = []  # (zip name, filename, zspan, parent id)
    for name in items:
        m = re.match(r"3D/Objects/(object_\d+\.model)$", name)
        if m:
            fn = m.group(1)
            tmpl.append((name, fn, model_zspan(items[name].decode("utf-8", "ignore")), parent_of.get(fn)))

    center_xy = len(parts) == 1 and len(tmpl) == 1
    parts_info = [(p,) + part_mesh(p, center_xy) for p in parts]  # (path, zspan, halfZ, mesh)

    tmpl_sorted = sorted(tmpl, key=lambda o: -o[2])
    parts_sorted = sorted(parts_info, key=lambda p: -p[1])
    if len(parts_sorted) == 1:
        pairs = [(t, parts_sorted[0]) for t in tmpl_sorted]           # broadcast
    elif len(parts_sorted) == len(tmpl_sorted):
        pairs = list(zip(tmpl_sorted, parts_sorted))                  # match by Z-order
    else:
        sys.exit("part count %d != template object count %d" % (len(parts_sorted), len(tmpl_sorted)))

    for (zname, fn, _z, pid), (ppath, _pz, halfz, mesh) in pairs:
        d = items[zname].decode("utf-8", "ignore")
        d = re.sub(r"<mesh>.*?</mesh>", lambda m: mesh, d, count=1, flags=re.S)
        items[zname] = d.encode("utf-8")
        # re-seat this object on the bed: set the build item's Z translate (last transform value)
        asm = re.sub(
            r'(<item objectid="%s"[^>]*?transform="[^"]*\s)([-\d.eE+]+)(")' % pid,
            lambda m: m.group(1) + ("%.6f" % halfz) + m.group(3), asm, count=1)
        print("  %s <- %s%s" % (fn, ppath, " (xy-centered)" if center_xy else ""))
    items["3D/3dmodel.model"] = asm.encode("utf-8")

    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zo:
        for n, data in items.items():
            zo.writestr(n, data)
    print("wrote", out)


if __name__ == "__main__":
    if len(sys.argv) < 4:
        sys.exit("usage: python swap_mesh.py <template.3mf> <out.3mf> <part1.stl> [...]")
    main(*sys.argv[1:])
