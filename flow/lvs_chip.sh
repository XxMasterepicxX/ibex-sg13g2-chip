#!/bin/bash
# LVS of a finished chip GDS: seal ring, bond pads and fill around the routed block.
# usage: lvs_chip.sh <run_dir> <chip_gds> <chip_top>
RUN=$(readlink -f "$1"); GDS=$(readlink -f "$2"); CTOP=$3
source /apps/settings >/dev/null 2>&1
unset PYTHONHOME PYTHONPATH
export PATH=$HOME/flash/tools/bin:$HOME/flash/tools/pyenv/bin:$PATH
DESIGN=$(awk '$2=="DESIGN"{print $3}' "$RUN/run_cfg.tcl")
PDK=$(awk '$2=="PDK"{print $3}' "$RUN/run_cfg.tcl")
source $HOME/flash/pdk_cfg/$PDK/pdk.sh
FLOW=$HOME/flash/flow
LVS_BLACKBOX=$(echo "source {$RUN/run_cfg.tcl}; if {[info exists LVS_BLACKBOX]} { puts [join \$LVS_BLACKBOX { }] }" | tclsh)
S=$RUN/signoff; O=$S/lvs_chip
rm -rf $O; mkdir -p $O
# The chip top holds the block and pinless finishing cells, so its schematic is the block's netlist plus a pinless
# top with one instance of the block.
python3 - "$S/lvs/$DESIGN.cdl" "$O/chip.cdl" "$DESIGN" "$CTOP" <<'PY'
import sys, re
src, dst, top, ctop = sys.argv[1:]
text = open(src).read()
m = re.search(r"^\.SUBCKT\s+%s\b(.*?)(?=^[^+])" % re.escape(top), text, re.M | re.S | re.I)
pins = m.group(1).replace("\n+", " ").split()
open(dst, "w").write(text + f"\n.SUBCKT {ctop}\nXblock {' '.join(pins)} {top}\n.ENDS\n")
print(f"LVS_CHIP_WRAPPER pins={len(pins)}")
PY
{
  lvs_run "$GDS" "$O/chip.cdl" "$CTOP" "$O/extract" --net_only
  python3 $FLOW/lvs_blackbox.py "$O/extract/$(basename "$GDS" .gds)_extracted.cir" "$O/layout_bb.cir" \
    "$O/chip.cdl" "$O/schematic_bb.cdl" "$CTOP" $LVS_BLACKBOX &&
  lvs_run "$GDS" "$O/schematic_bb.cdl" "$CTOP" "$O/run" --layout_netlist="$O/layout_bb.cir" --no_simplify
} < /dev/null > "$O/lvs.log" 2>&1
echo "LVS_EXIT=$?" >> "$O/lvs.log"
