# Metal fill with IHP macros. The Metal macro is a local copy with filler spacing at IHP's 0.42 um MFil.b
# minimum; -rd metal_lym=<name> picks which local copy. -rd prefix=sg13cmos5l fills with SG13CMOS5L's macros,
# whose Metal macro also fills TopMetal1 and which has no TopMetal macro.
import os, pya
prefix = globals().get("prefix", "sg13g2")
metal = globals().get("metal_lym", prefix + "_filler_Metal_dense.lym")
base = os.environ["PDK_ROOT"] + "/" + os.environ["PDK"] + "/libs.tech/klayout/tech/macros/"
for name in (prefix + "_filler_ActGatP.lym", metal, prefix + "_filler_TopMetal.lym"):
    path = os.path.expanduser("~/flash/ihp/fill/" + name) if name == metal else base + name
    if not os.path.exists(path):
        print("No macro", path)
        continue
    print("Filling with", path)
    pya.Macro(path).run()
pya.CellView.active().layout().write(output_file)  # noqa: F821
