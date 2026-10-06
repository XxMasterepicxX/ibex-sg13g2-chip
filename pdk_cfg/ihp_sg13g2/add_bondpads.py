# Bond pads for an IHP sg13g2_io pad ring. IHP has not added bond pads to the PDK yet ("TODO bondpads need
# to be part of the PDK", libs.tech/librelane/sg13g2_io/config.tcl), so each pad cell gets IHP's own
# SG13_dev "bondpad" PCell: a 70 um square (librelane's PAD_BONDPAD size) centred on the pad, GAP um outside
# its outer edge, joined to the pad pin (70 um of every metal, 3 um deep) by a TopMetal2 bridge.
# Why the gap: overlapping the pad stacks the bond pad's TopVia1/TopVia2 arrays on the pad's (TV1.b, TV2.b).
# Abutting it, as librelane places it, puts the bond pad too close to the pad cell's Activ, which IHP's tapeout
# precheck reports (Pad.d1R), and gives every metal a 0 um exit where 7 um is recommended (Pad.fR_*).
# 12 um clears both.
# Run: klayout -n sg13g2 -zz -r add_bondpads.py -rd in_gds=.. -rd top=.. -rd out_gds=..
import pya

SIZE = 70.0
GAP = 12.0
TOPMETAL2 = (134, 0)
PAD_PREFIX = "sg13g2_IOPad"

ly = pya.Layout()
ly.technology_name = "sg13g2"  # SG13_dev is registered for this technology only
ly.read(in_gds)  # noqa: F821
top_cell = ly.cell(top)  # noqa: F821
die = top_cell.dbbox()
lib = pya.Library.library_by_name("SG13_dev", "sg13g2")
if lib is None:
    raise SystemExit("SG13_dev library not loaded; run with -n sg13g2 and KLAYOUT_PATH set to the IHP klayout dir")
bond = ly.create_cell("bondpad", "SG13_dev", {"shape": "square", "diameter": f"{int(SIZE)}u"})
if bond is None:
    raise SystemExit("could not create bondpad PCell")
bb = bond.dbbox()
if abs(bb.width() - SIZE) > 0.01 or abs(bb.height() - SIZE) > 0.01:
    raise SystemExit(f"bondpad PCell is {bb.width()}x{bb.height()}, expected {SIZE}")
tm2 = ly.layer(*TOPMETAL2)
half = SIZE / 2

placed = 0
for inst in top_cell.each_inst():
    name = inst.cell.name
    if not name.startswith(PAD_PREFIX):
        continue
    b = inst.dbbox()
    cx, cy = b.center().x, b.center().y
    eps = 0.01
    # Bond pad centre, and the bridge from the pad's outer edge to the bond pad's near edge.
    if abs(b.bottom - die.bottom) < eps:
        x, y = cx, b.bottom - GAP - half
        bridge = pya.DBox(cx - half, b.bottom - GAP, cx + half, b.bottom)
    elif abs(b.top - die.top) < eps:
        x, y = cx, b.top + GAP + half
        bridge = pya.DBox(cx - half, b.top, cx + half, b.top + GAP)
    elif abs(b.left - die.left) < eps:
        x, y = b.left - GAP - half, cy
        bridge = pya.DBox(b.left - GAP, cy - half, b.left, cy + half)
    elif abs(b.right - die.right) < eps:
        x, y = b.right + GAP + half, cy
        bridge = pya.DBox(b.right, cy - half, b.right + GAP, cy + half)
    else:
        raise SystemExit(f"pad {name} at {b} is not on a die edge {die}")
    top_cell.insert(pya.DCellInstArray(bond.cell_index(), pya.DTrans(x - bb.center().x, y - bb.center().y)))
    top_cell.shapes(tm2).insert(bridge)
    placed += 1
ly.write(out_gds)  # noqa: F821
print(f"ADD_BONDPADS placed={placed} size={SIZE} gap={GAP} die={die}")
