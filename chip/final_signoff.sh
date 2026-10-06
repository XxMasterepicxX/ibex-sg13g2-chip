#!/bin/bash
# The last full signoff, after sign.py: restamps the ATPG record, which signing changed, then runs every signoff
# step again, prints each check that is not PASS, and exits non-zero unless the new CHECK.txt is SIGNOFF CLEAN.
# usage: final_signoff.sh <run_folder>
RUN=$(readlink -f "$1"); [ -f "$RUN/run_cfg.tcl" ] || { echo "usage: final_signoff.sh <run_folder>"; exit 1; }
F=$HOME/flash/flow
export FLOW_DIR=$F
source /apps/settings > /dev/null 2>&1
unset PYTHONHOME PYTHONPATH
date +"START %F %T"
python3 "$F/check.py" --begin "$RUN" atpg && python3 "$F/check.py" --stamp "$RUN" atpg atpg 0 \
  || { echo "The ATPG record could not be restamped"; exit 1; }
echo ATPG_RESTAMPED
touch "$RUN/signoff/final_start"
"$F/signoff.sh" "$RUN"; echo "SIGNOFF_EXIT=$?"
[ "$RUN/signoff/CHECK.txt" -nt "$RUN/signoff/final_start" ] || { echo "Signoff wrote no new CHECK.txt"; exit 1; }
grep -v " PASS " "$RUN/signoff/CHECK.txt"
date +"END %F %T"
tail -1 "$RUN/signoff/CHECK.txt" | grep -q "SIGNOFF CLEAN"
