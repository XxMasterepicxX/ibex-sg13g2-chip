#!/bin/bash
# Builds the chip from RTL to the point where a person must review, in one command. Each step must pass before the
# next one starts; the log names the step that stopped it.
#   1. a run folder, ~/flash/runs/<name>
#   2. Fusion Compiler: synthesis and scan, then floorplan through route
#   3. bond pads, seal ring, metal fill, chip DRC and IHP's pre-check
#   4. signoff with the derived worst and best wire models
#   5. margin rounds until timing, noise and electrical rows pass and fast hold reaches +0.09 ns, at most 3.
#      With MARGIN=hand it stops here instead and lists what to fix; fix it, then run the same command again.
#   6. the test programs on the gates, the scan test, clock crossings, and voltage drop and EM
#   7. unsigned review drafts in <run>/review
# Then: read the drafts, sign them with chip/review/sign.py, run chip/final_signoff.sh, then chip/package/package.sh.
# Takes most of a day. Run it under nohup; the log is <run>/make_chip.log.
# STOP_AT=synth|route|finish|signoff stops after that stage, so you can look at its results; run the same
# command again, with the next STOP_AT or none, to go on. Each stage logs the command it runs.
# usage: [MARGIN=hand] [STOP_AT=stage] make_chip.sh <name>
set -o pipefail
[ -n "$1" ] || { echo "usage: make_chip.sh <name>"; exit 1; }
C=$HOME/flash/chip
F=$HOME/flash/flow
RUN=$HOME/flash/runs/$1
[ -e "$RUN/run_cfg.tcl" ] || bash "$C/new_run.sh" "$1" > /dev/null || exit 1
exec > >(tee -a "$RUN/make_chip.log") 2>&1
log() { echo "$(date +'%F %T') $*"; }
stop() { log "STOPPED at $1. $2"; exit 1; }
at() { [ "$STOP_AT" = "$1" ] && { log "STOPPED_AT $1, as asked. $2"; exit 0; }; return 0; }
source /apps/settings > /dev/null 2>&1
unset PYTHONHOME PYTHONPATH
export RUN_CFG=$RUN/run_cfg.tcl FLOW_DIR=$F
log "START $RUN"

if ! grep -qs "^FLASH_STOPPED_AFTER synth" "$RUN/fc_setup.log"; then
  log "synthesis and scan: STOP_AFTER=synth $F/run_fc.sh $RUN"
  STOP_AFTER=synth "$F/run_fc.sh" "$RUN" || stop synthesis "See $RUN/fc_setup.log"
fi
grep -q "FLASH_IHP_PADS_POST_DFT 25" "$RUN/fc_setup.log" || stop synthesis "The netlist does not have 25 pads after scan insertion."
at synth "Look at $RUN/fc_setup.log and $RUN/rpt."
if ! grep -qs "^FLASH_FLOW_DONE" "$RUN/fc_floorplan.log"; then
  log "floorplan through route: START_AT=floorplan $F/run_fc.sh $RUN"
  START_AT=floorplan "$F/run_fc.sh" "$RUN" || stop "place and route" "See $RUN/fc_floorplan.log"
fi

at route "Look at $RUN/fc_floorplan.log, $RUN/rpt and the saved blocks in $RUN/flash_chip.nlib."
if [ ! -f "$RUN/chip/done" ]; then
  # Archive the block manifest so a check-only signoff writes the chip manifest and records the inputs the chip
  # DRC is stamped against.
  mkdir -p "$RUN/chip"
  if grep -qs deferred_until_filled_chip "$RUN/signoff/manifest.json"; then
    mv "$RUN/signoff/manifest.json" "$RUN/signoff/manifest.block_scope_fc.json"
  fi
  "$F/signoff.sh" "$RUN" check > "$RUN/signoff_inputs.log" 2>&1
  [ -f "$RUN/signoff/provenance/dependencies.json" ] || stop finishing "The signoff inputs were not recorded. See $RUN/signoff_inputs.log"
  log "finish the chip: METAL_FILL=mid bash $F/finish.sh $RUN 75 bondpads"
  METAL_FILL=mid bash "$F/finish.sh" "$RUN" 75 bondpads || stop finishing "See the logs in $RUN/chip"
fi
cat "$RUN/chip/density.txt"
at finish "Look at $RUN/chip: chip_filled.gds, density.txt and the drc and precheck folders."

# Rows a margin round can fix, and the fast hold floor.
MARGIN_ROWS="^(pt_(slow|typ|fast)(_shift)? |noise_|electrical_|timing_constraints_)"
needs_margin() {
  local K=$RUN/signoff/CHECK.txt
  # pt_report_analysis_coverage_* rows wait for a signed review record, which no margin round can supply.
  grep -E "$MARGIN_ROWS" "$K" | grep -qv " PASS " && return 0
  awk '$1 ~ /^pt_fast/ {for (i = 1; i <= NF; i++) if ($i ~ /^hold_wns=/) {split($i, a, "="); if (a[2] < 0.09) bad = 1}} END {exit !bad}' "$K"
}
if [ ! -f "$RUN/signoff/full_signoff.done" ]; then
  log "signoff: $F/signoff.sh $RUN"
  rm -f "$RUN/signoff/signoff.done"
  "$F/signoff.sh" "$RUN"
  # signoff.sh exits non-zero while review records are missing, so success means it reached its check step.
  grep -qs SIGNOFF_CHECK_EXIT "$RUN/signoff/signoff.done" || stop signoff "See $RUN/signoff"
  # Rows that only say a tool finished. If one fails, the next run of this command repeats signoff.
  for c in starrc starrc_cmax starrc_cmin pt_exit_slow pt_exit_typ pt_exit_fast pt_exit_slow_shift pt_exit_typ_shift \
      pt_exit_fast_shift formality_completion primepower_completion drc lvs_completion chip_lvs_completion; do
    grep -q "^$c .* PASS " "$RUN/signoff/CHECK.txt" || stop signoff "The $c row does not pass. See $RUN/signoff/CHECK.txt"
  done
  touch "$RUN/signoff/full_signoff.done"
fi
tail -1 "$RUN/signoff/CHECK.txt"
at signoff "Look at $RUN/signoff/CHECK.txt and the reports beside it."
if [ "$MARGIN" = hand ] && needs_margin; then
  grep -E "$MARGIN_ROWS" "$RUN/signoff/CHECK.txt" | grep -v " PASS "
  grep -h "^FLASH_PT corner" "$RUN"/signoff/pt_fast*/pt.log
  stop margin "MARGIN=hand: fix the rows above, and fast hold if it is under +0.09 ns, then run this again."
fi
for r in 1 2 3; do
  needs_margin || break
  log "margin round $r: bash $C/margin_fix.sh $RUN"
  bash "$C/margin_fix.sh" "$RUN" || stop "margin round $r" "See $RUN/margin"
done
needs_margin && stop margin "Three rounds were not enough. See $RUN/margin and $RUN/signoff/CHECK.txt"
for c in drc chip_drc chip_precheck lvs chip_lvs_completion formality; do
  grep -q "^$c .* PASS " "$RUN/signoff/CHECK.txt" || stop signoff "The $c row does not pass. See $RUN/signoff/CHECK.txt"
done

log "proofs: gls.sh, atpg.sh, cdc.sh and ir/ir.sh in $C"
bash "$C/gls.sh" "$RUN" > "$RUN/gls.log" 2>&1 &
G=$!
bash "$C/atpg.sh" "$RUN" > "$RUN/atpg.log" 2>&1 &
A=$!
bash "$C/cdc.sh" "$RUN" > "$RUN/cdc.log" 2>&1
if [ -n "$ANSYSLMD_LICENSE_FILE" ]; then
  bash "$C/ir/ir.sh" "$RUN" > "$RUN/ir.log" 2>&1
else
  echo "ANSYSLMD_LICENSE_FILE is not set: voltage drop and EM skipped. Set it and run chip/ir/ir.sh $RUN." > "$RUN/ir.log"
fi
wait $G; wait $A
tail -qn1 "$RUN/gls.log" "$RUN/atpg.log" "$RUN/cdc.log" "$RUN/ir.log"
grep -q GLS_PASS "$RUN/gls.log" || stop "gate-level programs" "See $RUN/gls.log"
grep -q ATPG_DONE "$RUN/atpg.log" || stop "scan test" "See $RUN/atpg.log"

log "review drafts"
python3 "$C/review/make_drafts.py" "$RUN" || stop "review drafts" ""
python3 "$C/review/verify.py" "$RUN" > "$RUN/review/EVIDENCE.txt" 2>&1
log "READY_FOR_REVIEW read $RUN/review/SUMMARY.txt and EVIDENCE.txt, then:"
echo "  python3 $C/review/sign.py $RUN \"Your Name\""
echo "  bash $C/final_signoff.sh $RUN"
echo "  bash $C/package/package.sh $RUN"
