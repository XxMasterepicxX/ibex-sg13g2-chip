#!/bin/bash
# Opens one saved stage of a run in Fusion Compiler, read-only, to look around: report_qor, report_timing,
# gui_start. The GUI needs an X display: ssh -X, MobaXterm or a VNC session.
# usage: open_fc.sh <run_folder> [block]       block: floorplan pg place cts route final, final by default
RUN=$(readlink -f "$1"); B=${2:-final}
DESIGN=$(awk '$2=="DESIGN"{print $3}' "$RUN/run_cfg.tcl" 2>/dev/null)
[ -d "$RUN/$DESIGN.nlib" ] || { echo "usage: open_fc.sh <run_folder> [block]   (no $DESIGN.nlib in that folder yet)"; exit 1; }
source /apps/settings > /dev/null 2>&1
source $HOME/flash/flow/tools.sh
export SYNOPSYS_LC_ROOT=/apps/syn/lc
mkdir -p "$RUN/look" && cd "$RUN/look" || exit 1
exec $FC_BIN -x "open_lib -read $RUN/$DESIGN.nlib; open_block $DESIGN/$B; puts {Opened $DESIGN/$B read-only. Try report_qor -summary, report_timing, gui_start.}"
