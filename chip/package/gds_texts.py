# Label texts per layer in two GDS files, flattened from the top cell, with their strings and positions at 1 nm.
import pya
from collections import Counter
def texts(path, top):
    l = pya.Layout(); l.read(path)
    out = Counter()
    for li in l.layer_infos():
        it = l.cell(top).begin_shapes_rec(l.find_layer(li))
        while not it.at_end():
            s = it.shape()
            if s.is_text():
                t = s.text.transformed(it.trans())
                out[(li.layer, li.datatype, t.string, round(t.x * l.dbu, 3), round(t.y * l.dbu, 3))] += 1
            it.next()
    return out
A, B = texts(a, ta), texts(b, tb)
print('TEXTS', sum(A.values()), sum(B.values()), 'ONLY_A', sum((A - B).values()), 'ONLY_B', sum((B - A).values()))
for k in list((A - B))[:5]: print('ONLY_A', k)
