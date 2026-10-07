#!/bin/bash
# Adds timing margin to a signed-off build without breaking another corner. Run it when signoff shows fast hold
# under +0.09 ns, a noise violation, or an SRAM output near its load limit. Run it again if one pass is not enough.
#   1. PrimeTime proposes noise, transition and load fixes at slow and fast, and hold fixes at fast in both modes.
#      Nothing in the design changes.
#   2. Every SRAM output within 5 fF of its load limit gets a buffer. Fusion Compiler places those buffers, because
#      PrimeTime cannot judge the load of a wire it has not seen.
#   3. The list is tested at slow, typ and fast, in normal and scan mode. A changed cell that leaves a path under the
#      floor, +0.6 ns at slow and +0.2 ns at typ and fast, or that drives an electrical violation, is dropped, and
#      the shorter list is tested again until nothing is dropped. If the list still falls short, chip/margin/targeted.py
#      adds a buffer after each noise victim's driver, upsizes each driver over its limit, and puts a delay cell in
#      front of each endpoint under the fast hold floor, and the test repeats, up to three times.
#   4. The list is applied only if slow setup stays at or above +0.6 ns in normal mode and +0.5 ns in scan mode, and
#      fast hold reaches +0.09 ns. Fusion Compiler applies it, the chip is finished again and signed off, and the
#      round is undone if any check that passed before now fails.
# usage: margin_fix.sh <run_folder>
RUN=$(readlink -f "$1"); [ -f "$RUN/run_cfg.tcl" ] || { echo "usage: margin_fix.sh <run_folder>"; exit 1; }
C=$HOME/flash/chip
F=$HOME/flash/flow
E=$F/eco.sh
n=1; while [ -d "$RUN/margin/round$n" ]; do n=$((n + 1)); done
H=$RUN/margin/round$n
mkdir -p "$H" && cd "$H" || exit 1
log() { echo "$(date +'%F %T') $*"; }
source /apps/settings > /dev/null 2>&1
unset PYTHONHOME PYTHONPATH
export RUN_CFG=$RUN/signoff/executed_cfg.tcl SCRATCH=$H FLOW_DIR=$F
log "START $RUN round $n"

# PrimeTime scripts from this run's own signoff settings: reports go to the scratch folder, and the test is appended.
python3 "$C/margin/make_pt_base.py" "$RUN/signoff/pt_policy.tcl" pt_base.tcl
cat pt_base.tcl "$C/margin/eval_tail.tcl" > pt_eval.tcl
cat pt_base.tcl "$C/margin/cap_tail.tcl" > pt_cap.tcl

# 1. Proposals. Each manual run reuses signoff/eco_pt_<corner>_manual, so each list is copied out first.
CORNER=slow PT_MODE=func timeout 1800 pt_shell -f pt_cap.tcl < /dev/null > cap_slow.log 2>&1 &
TRY_ONLY=1 MANUAL_CHANGES=$C/margin/slow_fix.tcl $E "$RUN" slow manual > try_slow.log 2>&1
cp "$RUN/signoff/eco_pt_slow_manual/eco_changes.tcl" slow_list.tcl 2>/dev/null || : > slow_list.tcl
TRY_ONLY=1 MANUAL_CHANGES=$C/margin/fast_fix.tcl $E "$RUN" fast manual > try_fast.log 2>&1
cp "$RUN/signoff/eco_pt_fast_manual/eco_changes.tcl" fast_list.tcl 2>/dev/null || : > fast_list.tcl
TRY_ONLY=1 MANUAL_CHANGES=$C/margin/hold_both.tcl $E "$RUN" fast manual > try_hold.log 2>&1
cp "$RUN/signoff/eco_pt_fast_manual/eco_changes.tcl" hold_list.tcl 2>/dev/null || : > hold_list.tcl
wait
# 2. SRAM outputs near their load limit, buffered later in Fusion Compiler.
awk '/^FLASH_CAP/ && $2 < 0.005 {print $3}' cap_slow.log > dout_pins.txt
i=1; while read -r p; do
  echo "insert_buffer [get_pins {$p}] sg13g2_buf_2 -new_net_names {net_MF${n}_DOUT_NET$i} -new_cell_names {U_MF${n}_DOUT_BUF$i}"
  i=$((i + 1))
done < dout_pins.txt > dout_fc.tcl
# Each PrimeTime session numbers its new cells from 1, so each list gets its own prefix.
pfx() { sed -e "s/U_PTECO_/U_MF${n}$2_/g" -e "s/net_PTECO_/net_MF${n}$2_/g" "$1"; }
{ pfx slow_list.tcl S; pfx fast_list.tcl F; pfx hold_list.tcl H; } > cand0.tcl
log "cand0 changes: $(grep -c '^insert_buffer\|^size_cell' cand0.tcl)"

# 3. Test at every corner and mode, drop what hurts, test again.
evaluate() {
  rm -f bad_cells_*.txt
  for c in slow typ fast; do
    floor=0.2; [ $c = slow ] && floor=0.6
    for m in func shift; do
      ( export CHANGE_LIST=$H/$1 CORNER=$c FLASH_SETUP_FLOOR=$floor PT_MODE=$m
        timeout 2400 pt_shell -f pt_eval.tcl < /dev/null > eval_${c}_$m.log 2>&1 ) &
    done
  done
  wait
  grep -h "^FLASH_EVAL" eval_*_func.log eval_*_shift.log > "${1%.tcl}.eval"
  cat "${1%.tcl}.eval"
}
k=0; t=0
# An undone round leaves its noise report behind. Real routing found those victims where PrimeTime's estimate did
# not, so this round buffers their drivers from the start instead of repeating the same list.
cat "$RUN"/eco_rejected_*/pt_*_noise_violators.rpt 2> /dev/null \
  | awk '$2 ~ /^\(/ && $NF ~ /^-[0-9.]+$/ {print $1}' | sort -u > prior_victims.txt
# Each report is used once: this round keeps it, so a later round never buffers the same victims again.
for f in "$RUN"/eco_rejected_*/pt_*_noise_violators.rpt; do
  if [ -f "$f" ]; then mkdir -p prior_reports && mv "$f" "prior_reports/$(basename "$(dirname "$f")")_$(basename "$f")"; fi
done
if [ -s prior_victims.txt ]; then
  log "noise victims of the undone round: $(wc -l < prior_victims.txt)"
  FLASH_PRIOR_VICTIMS=$H/prior_victims.txt evaluate cand0.tcl > /dev/null
  python3 "$C/margin/targeted.py" "MF${n}P" dout_pins.txt > prior.tcl
  if [ -s prior.tcl ]; then
    log "prior victims pass: $(wc -l < prior.tcl) changes"
    { cat cand0.tcl; echo current_instance; cat prior.tcl; } > cand1.tcl
    k=1
  fi
fi
# When nothing is dropped but the gate still fails, targeted changes for what is left are added, up to 3 times.
while :; do
  evaluate cand$k.tcl
  cat bad_cells_*.txt > cand$k.bad 2> /dev/null
  if [ -s cand$k.bad ]; then
    [ $k -ge 20 ] && break
    python3 "$C/margin/filter_changes.py" cand$k.tcl cand$((k + 1)).tcl cand$k.bad
    k=$((k + 1)); continue
  fi
  python3 "$C/margin/gate.py" cand$k.eval > gate.txt
  grep -q "MARGIN_GATE PASS" gate.txt && break
  [ $t -ge 3 ] && break
  t=$((t + 1))
  python3 "$C/margin/targeted.py" "MF${n}T$t" dout_pins.txt > targeted$t.tcl
  [ -s targeted$t.tcl ] || break
  log "targeted pass $t: $(wc -l < targeted$t.tcl) changes"
  { cat cand$k.tcl; echo current_instance; cat targeted$t.tcl; } > cand$((k + 1)).tcl
  k=$((k + 1))
done
# 4. The gate. Only the SRAM outputs that Fusion Compiler buffers after this test may still show a violation.
python3 "$C/margin/gate.py" cand$k.eval > gate.txt
cat gate.txt
grep -q "MARGIN_GATE PASS" gate.txt || { log "STOP the list did not pass the gate; nothing was applied. See $H"; exit 1; }
# The flop swap goes in once, in the first round that is kept.
SWAP=; [ -f "$RUN/margin/sclk_swap.kept" ] || SWAP=$C/margin/sclk_swap.tcl
{ cat cand$k.tcl; echo current_instance; cat dout_fc.tcl; [ -n "$SWAP" ] && cat "$SWAP"; } > fix.tcl
export AFTER_FC="METAL_FILL=mid bash $F/finish.sh . 75 bondpads"
log "apply $(grep -c '^insert_buffer\|^size_cell' fix.tcl) changes"
FC_CHANGES=$H/fix.tcl $E "$RUN" slow fc > apply.log 2>&1
grep -E "FLASH_ECO_(APPLIED|LEGALITY|KEPT|REJECTED|FAILED)" apply.log
grep -q FLASH_ECO_KEPT apply.log && [ -n "$SWAP" ] && touch "$RUN/margin/sclk_swap.kept"
tail -1 "$RUN/signoff/CHECK.txt"
log DONE
