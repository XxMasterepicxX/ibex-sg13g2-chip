#!/bin/bash
# usage: [START_AT=stage] run_fc.sh <run_dir>   (run_dir must contain run_cfg.tcl)
# Fusion Compiler reads the script as it runs, so each run executes its own frozen copy.
# Braced so bash parses the whole script before running it.
{
RUN=$(readlink -f "$1")
cd "$RUN" || exit 1
# A copied run_cfg keeps its source's OUT and would write into that run (gf180_chip_v5, sv_ibex_v2 on 9-23).
OUT_DIR=$(echo "source {$RUN/run_cfg.tcl}; puts \$OUT" | tclsh)
[ "$(readlink -f "$OUT_DIR")" = "$RUN" ] || { echo "run_cfg OUT is $OUT_DIR, not $RUN" >&2; exit 1; }
mkdir -p "$RUN/flow_snapshot"
# An ECO session takes the current scripts, so flow fixes reach runs made before them; the old copy is kept.
if [ -n "$ECO_CHANGES" ] && [ -f "$RUN/flow_snapshot/fc_flow.tcl" ]; then
  KEEP=$RUN/flow_snapshot/before_eco_$(date +%m%d_%H%M%S)
  mkdir -p "$KEEP" && cp "$RUN"/flow_snapshot/*.tcl "$KEEP/"
  cp $HOME/flash/flow/{fc_flow.tcl,constraints.tcl,session.tcl} "$RUN/flow_snapshot/"
fi
[ -f "$RUN/flow_snapshot/fc_flow.tcl" ] || cp $HOME/flash/flow/{fc_flow.tcl,constraints.tcl,session.tcl} "$RUN/flow_snapshot/"
source /apps/settings >/dev/null 2>&1
unset PYTHONHOME PYTHONPATH
source $HOME/flash/flow/tools.sh
if [ -n "$FC_PRELOAD" ]; then export LD_PRELOAD="$FC_PRELOAD"; else unset LD_PRELOAD; fi
export SYNOPSYS_LC_ROOT=/apps/syn/lc
echo "FLASH_TOOLS $(cat $RUN/.tools) $FC_BIN" >&2
export RUN_CFG=$RUN/run_cfg.tcl FLOW_DIR=$RUN/flow_snapshot
# The in-design IC Validator (ICV_RUNSET) finds its install through ICV_HOME_DIR.
export ICV_HOME_DIR=$ICV_HOME
LOG=fc_${START_AT:-setup}.log
# Fusion Compiler seats are shared with other users and run out; with none free, fc_shell stops at once.
# Wait and try again, up to 12 times, 5 minutes apart.
for try in $(seq 1 12); do
  START_AT=${START_AT:-setup} python3 "$HOME/flash/flow/check.py" --begin-fc "$RUN" "$LOG" || exit 1
  START_AT=${START_AT:-setup} $FC_BIN -f $RUN/flow_snapshot/fc_flow.tcl < /dev/null > $LOG 2>&1
  echo "FC_EXIT=$?" >> $LOG
  grep -q "Unable to get shell start-up license keys" $LOG || break
  echo "FLASH_NO_LICENSE try $try, waiting" >&2
  sleep 300
done
# fc_shell exits 0 even when the script stops on an error, so success means the flow reached its end.
# A STOP_AFTER checkpoint is a deliberate stop, so it counts as success too.
grep -qE "^(FLASH_FLOW_DONE|FLASH_STOPPED_AFTER)" $LOG || exit 1
if grep -q '^FLASH_FLOW_DONE' "$LOG"; then
  python3 "$HOME/flash/flow/check.py" --prepare "$RUN" || exit 1
  python3 "$HOME/flash/flow/check.py" --record-fc "$RUN" "$LOG" || exit 1
  if [ ! -d "$RUN/chip" ]; then
    python3 "$HOME/flash/flow/check.py" --bind-fc "$RUN" || exit 1
  fi
fi
exit 0
}
