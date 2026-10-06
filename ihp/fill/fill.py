# Metal fill with IHP's macros. The Metal macro is setup's copy in ~/flash/ihp/fill; -rd metal_lym=<name> picks it.
import os, pya
metal = globals().get("metal_lym", "sg13g2_filler_Metal_mid.lym")
base = os.environ["PDK_ROOT"] + "/" + os.environ["PDK"] + "/libs.tech/klayout/tech/macros/"
for name in ("sg13g2_filler_ActGatP.lym", metal, "sg13g2_filler_TopMetal.lym"):
    path = os.path.expanduser("~/flash/ihp/fill/" + name) if name == metal else base + name
    if not os.path.exists(path):
        raise RuntimeError("No fill macro " + path)
    print("Filling with", path)
    pya.Macro(path).run()
pya.CellView.active().layout().write(output_file)  # noqa: F821
