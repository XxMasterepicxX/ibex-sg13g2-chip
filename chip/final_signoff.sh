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
touch "$RUN/signoff/final_start"; rm -f "$RUN/signoff/release_files.md5"
"$F/signoff.sh" "$RUN"; echo "SIGNOFF_EXIT=$?"
[ "$RUN/signoff/CHECK.txt" -nt "$RUN/signoff/final_start" ] || { echo "Signoff wrote no new CHECK.txt"; exit 1; }
grep -v " PASS " "$RUN/signoff/CHECK.txt"
date +"END %F %T"
tail -1 "$RUN/signoff/CHECK.txt" | grep -q "SIGNOFF CLEAN" || exit 1
# The release package also ships the LVS netlist, the SDFs and the SPEFs, which CHECK.txt does not hash.
# package.sh ships them only if they still match these hashes, taken at a clean signoff.
(cd "$RUN" && md5sum signoff/lvs_chip/chip.cdl signoff/pt_slow/flash_chip.slow.sdf signoff/pt_typ/flash_chip.typ.sdf \
  signoff/pt_fast/flash_chip.fast.sdf signoff/starrc/flash_chip.spef signoff/starrc_cmax/flash_chip.spef \
  signoff/starrc_cmin/flash_chip.spef) > "$RUN/signoff/release_files.md5.tmp" \
  && mv "$RUN/signoff/release_files.md5.tmp" "$RUN/signoff/release_files.md5" \
  || { rm -f "$RUN/signoff/release_files.md5.tmp"; echo "Could not hash the release files"; exit 1; }
