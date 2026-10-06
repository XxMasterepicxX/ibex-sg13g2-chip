#!/bin/bash
# Tests a change list at slow, typ and fast in normal and scan mode, the same test the margin rounds run, and
# changes nothing in the design. Use it on a list you build by hand before you apply the list.
# For each corner and mode it prints one FLASH_EVAL line: the cells that leave a path under the floor (bad=),
# electrical and noise violations left, and the worst setup and hold slack. Then it prints the cells to drop,
# the endpoints still under the 0.09 ns hold floor, and the drivers of what is still over a limit, and last
# MARGIN_GATE PASS or FAIL.
# fc_pins.txt, optional, lists memory outputs you will buffer in Fusion Compiler: PrimeTime cannot judge the load
# of a buffer it has not placed, so the test leaves those pins over their limit and does not count them.
# usage: test_list.sh <run_folder> <changes.tcl> [fc_pins.txt]       work in <run_folder>/margin/test_<name>
RUN=$(readlink -f "$1"); LIST=$(readlink -f "$2"); PINS=${3:+$(readlink -f "$3")}
[ -f "$RUN/signoff/pt_policy.tcl" ] && [ -s "$LIST" ] || { echo "usage: test_list.sh <run_folder> <changes.tcl>, after signoff"; exit 1; }
C=$HOME/flash/chip
H=$RUN/margin/test_$(basename "$LIST" .tcl)
rm -rf "$H"; mkdir -p "$H" && cd "$H" || exit 1
source /apps/settings > /dev/null 2>&1
unset PYTHONHOME PYTHONPATH
export RUN_CFG=$RUN/signoff/executed_cfg.tcl SCRATCH=$H
python3 "$C/margin/make_pt_base.py" "$RUN/signoff/pt_policy.tcl" pt_base.tcl
cat pt_base.tcl "$C/margin/eval_tail.tcl" > pt_eval.tcl
cp "$LIST" list.tcl
if [ -n "$PINS" ]; then cp "$PINS" dout_pins.txt; else : > dout_pins.txt; fi
for c in slow typ fast; do
  floor=0.2; [ $c = slow ] && floor=0.6
  for m in func shift; do
    ( export CHANGE_LIST=$H/list.tcl CORNER=$c FLASH_SETUP_FLOOR=$floor PT_MODE=$m
      timeout 2400 pt_shell -f pt_eval.tcl < /dev/null > eval_${c}_$m.log 2>&1 ) &
  done
done
wait
grep -h "^FLASH_EVAL" eval_*_func.log eval_*_shift.log > list.eval
sed -E 's/FLASH_EVAL //; s/ changed=[0-9]+//; s/([0-9]\.[0-9]{3})[0-9]+/\1/g' list.eval
cat bad_cells_*.txt 2> /dev/null | sort -u | sed 's/^/DROP /'
grep -h "^FLASH_HOLD_END" eval_fast_*.log | sort -u
grep -h "^FLASH_NOISE_DRIVER\|^FLASH_DRC_DRIVER" eval_*.log | sort -u
python3 "$C/margin/gate.py" list.eval
