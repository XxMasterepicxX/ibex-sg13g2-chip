# Zero-area polygons, boxes and paths per layer in a GDS, counted in every cell, with the cells that hold them.
import pya
from collections import Counter
l = pya.Layout(); l.read(gds)
per_layer, per_cell = Counter(), Counter()
for cell in l.each_cell():
    for li in l.layer_indexes():
        for s in cell.shapes(li).each():
            if (s.is_polygon() or s.is_box() or s.is_path() or s.is_simple_polygon()) and s.polygon is not None and s.polygon.area() == 0:
                info = l.get_info(li)
                per_layer[(info.layer, info.datatype)] += 1
                per_cell[cell.name] += 1
print('ZERO_AREA', sum(per_layer.values()))
for k, v in sorted(per_layer.items()): print('LAYER', k, v)
for k, v in per_cell.most_common(10): print('CELL', k, v)
