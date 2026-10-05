# Compare two GDS files shape for shape: each layer of a's top cell, flattened, against b's. Prints the database
# units, and the XOR area per layer; an empty XOR on every layer means the geometry is identical.
# usage: klayout -b -r gds_xor.py -rd a=... -rd ta=... -rd b=... -rd tb=...
import pya
la, lb = pya.Layout(), pya.Layout()
la.read(a)
lb.read(b)
print('DBU', la.dbu, lb.dbu)
ca, cb = la.cell(ta), lb.cell(tb)
layers = {(i.layer, i.datatype) for l in (la, lb) for i in l.layer_infos()}
diff = 0
for ln, dt in sorted(layers):
    ia, ib = la.find_layer(ln, dt), lb.find_layer(ln, dt)
    ra = pya.Region(ca.begin_shapes_rec(ia)) if ia is not None else pya.Region()
    rb = pya.Region(cb.begin_shapes_rec(ib)) if ib is not None else pya.Region()
    # Both at 1 nm: a's 0.1 nm units scaled by its dbu over b's.
    ra = ra.transformed(pya.ICplxTrans(la.dbu / lb.dbu))
    x = ra ^ rb
    if not x.is_empty():
        diff += 1
        print('XOR', ln, dt, 'area_um2', x.area() * lb.dbu * lb.dbu, 'polygons', x.count())
print('LAYERS', len(layers), 'DIFFERING', diff)
