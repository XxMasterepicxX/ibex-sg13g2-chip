#!/bin/bash
# The last full signoff, after the review records are signed. Signing added only review fields to the ATPG record,
# so its result is stamped again over the same files; then every signoff step runs again, since the signed records
# are inputs to the checker.
# usage: final_signoff.sh <run_folder>       prints the last line of <run_folder>/signoff/CHECK.txt
RUN=$(readlink -f "$1"); [ -f "$RUN/run_cfg.tcl" ] || { echo "usage: final_signoff.sh <run_folder>"; exit 1; }
F=$HOME/flash/flow
export FLOW_DIR=$F
export RC_CMAX_GRID=$HOME/flash/ihp/rc/w6_spec_sensitivity/rcmax/sg13g2_spec_rcmax.nxtgrd
export RC_CMIN_GRID=$HOME/flash/ihp/rc/w6_spec_sensitivity/rcmin/sg13g2_spec_rcmin.nxtgrd
source /apps/settings > /dev/null 2>&1
unset PYTHONHOME PYTHONPATH
date +"START %F %T"
python3 "$F/check.py" --begin "$RUN" atpg && python3 "$F/check.py" --stamp "$RUN" atpg atpg 0 && echo ATPG_RESTAMPED
"$F/signoff.sh" "$RUN"; echo "SIGNOFF_EXIT=$?"
grep -v " PASS " "$RUN/signoff/CHECK.txt"
date +"END %F %T"
