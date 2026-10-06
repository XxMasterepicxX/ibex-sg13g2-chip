# Chip finishing for IHP SG13G2: wrap a routed block in a new top cell with IHP's own seal ring
# (SG13_dev "sealring" PCell). IHP's filler only fills inside EdgeSeal, so this comes before fill.
# Run: klayout -n sg13g2 -zz -r chip_finish.py -rd in_gds=.. -rd top=.. -rd out_gds=.. [-rd margin=30]
import math
import pya

margin = float(globals().get("margin", "30"))
tech = globals().get("tech", "sg13g2")
ly = pya.Layout()
ly.technology_name = tech  # SG13_dev is registered for this technology only
ly.read(in_gds)  # noqa: F821  (set by -rd)
blk = ly.cell(top)  # noqa: F821
bb = blk.dbbox()

lib = pya.Library.library_by_name("SG13_dev", tech)
if lib is None:
    raise SystemExit(f"SG13_dev library not loaded; run with -n {tech} and KLAYOUT_PATH set to the IHP klayout dir")

# Seal ring Lmin/Wmin is 150 um.
# Whole micrometres: the PCell parses "200u" but rejects "200.000u".
L = max(math.ceil(bb.width() + 2 * margin), 150)
W = max(math.ceil(bb.height() + 2 * margin), 150)
seal = ly.create_cell("sealring", "SG13_dev", {"l": f"{L}u", "w": f"{W}u"})
if seal is None:
    raise SystemExit("could not create sealring PCell")
sb = seal.dbbox()

chip = ly.create_cell(f"chip_{top}")  # noqa: F821
chip.insert(pya.DCellInstArray(seal.cell_index(), pya.DTrans(0, 0)))
dx = sb.center().x - bb.center().x
dy = sb.center().y - bb.center().y
chip.insert(pya.DCellInstArray(blk.cell_index(), pya.DTrans(dx, dy)))
ly.write(out_gds)  # noqa: F821
print(f"CHIP_FINISH block {bb.width():.2f}x{bb.height():.2f} seal {sb.width():.2f}x{sb.height():.2f} "
      f"block offset ({dx:.2f},{dy:.2f}) top chip_{top}")  # noqa: F821
