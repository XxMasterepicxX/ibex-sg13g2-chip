#!/usr/bin/env python3
"""Global density per layer (drawing plus filler datatypes) over the top cell's bounding box.
usage: density.py <gds> <topcell>
"""
import sys
import klayout.db as db

LAYERS = {"Activ": [(1, 0), (1, 22)], "GatPoly": [(5, 0), (5, 22)], "Metal1": [(8, 0), (8, 22)],
          "Metal2": [(10, 0), (10, 22)], "Metal3": [(30, 0), (30, 22)], "Metal4": [(50, 0), (50, 22)],
          "Metal5": [(67, 0), (67, 22)], "TopMetal1": [(126, 0), (126, 22)], "TopMetal2": [(134, 0), (134, 22)]}
ly = db.Layout()
ly.read(sys.argv[1])
top = ly.cell(sys.argv[2])
box = top.dbbox()
area = box.area()
print(f"bbox {box} area {area:.0f} um2")
for name, specs in LAYERS.items():
    parts = []
    total = db.Region()
    for l, d in specs:
        li = ly.find_layer(l, d)
        if li is None:
            continue
        r = db.Region(top.begin_shapes_rec(li)).merged()
        parts.append(f"{d}:{r.area() * ly.dbu * ly.dbu / area * 100:.1f}%")
        total += r
    dens = total.merged().area() * ly.dbu * ly.dbu / area * 100
    print(f"{name:<10} {dens:6.1f}%   {' '.join(parts)}")
