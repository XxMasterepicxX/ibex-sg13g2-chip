#!/bin/bash
# The fix loop for any finished run: PrimeTime proposes or tests changes, Fusion Compiler applies them, and signoff
# decides whether they stay.
#   - PrimeTime times with the run's own signoff script, signoff/pt_policy.tcl: same derate and RC corners.
#   - drc fixes transition and capacitance one type at a time, data cells and clock cells, resizing or adding
#     buffers from ECO_BUFFERS in pdk.tcl.
#   - type manual applies a hand-written change list, MANUAL_CHANGES, through the same PrimeTime step.
#   - Resized cells are released before legalization, and the placement must be legal afterwards.
#   - A failed attempt's log is kept in eco_rejected_*, never as a top-level fc_*.log.
#   - The ECO is undone if any check that passed before fails after it.
#   - TRY_ONLY=1 runs only the PrimeTime step and reports, so a hand-written list can be tested first.
#   - type fc applies FC_CHANGES, a hand-written Fusion Compiler script, for edits PrimeTime cannot make, such as
#     swapping a cell for one with different pins. It skips PrimeTime and keeps the same checks and undo.
#   - ECO_MODE=shift fixes the scan-shift timing mode instead of the functional one, for hold on the scan chains.
#   - FLOW_DIR picks the flow scripts, ~/flash/flow by default.
#   - AFTER_FC is a command run in the run folder between Fusion Compiler and signoff, such as chip finishing,
#     so signoff checks a finished chip built from the new layout. chip/ is saved and restored with the run.
# usage: [FLOW_DIR=dir] [TRY_ONLY=1] [MANUAL_CHANGES=file] [FC_CHANGES=file] [AFTER_FC=cmd] eco_fixed.sh <run_dir> <corner> <setup|hold|drc|noise|manual|fc>
# Braced so bash parses the whole script before running it.
{
RUN=$(readlink -f "$1"); C=${2:-slow}; T=${3:-setup}
FLOW_DIR=${FLOW_DIR:-$HOME/flash/flow}
[ -f "$RUN/signoff/pt_policy.tcl" ] || { echo "FLASH_ECO_FAILED run signoff.sh first: no signoff/pt_policy.tcl"; exit 1; }
[ -f "$RUN/signoff/CHECK.txt" ] || { echo "FLASH_ECO_FAILED run signoff.sh first: no signoff/CHECK.txt"; exit 1; }
if [ "$T" = manual ]; then
  [ -s "$MANUAL_CHANGES" ] || { echo "FLASH_ECO_FAILED type manual needs MANUAL_CHANGES, a file of size_cell lines"; exit 1; }
  export MANUAL_CHANGES=$(readlink -f "$MANUAL_CHANGES")
fi
if [ "$T" = fc ]; then
  [ -s "$FC_CHANGES" ] || { echo "FLASH_ECO_FAILED type fc needs FC_CHANGES, a Fusion Compiler script"; exit 1; }
fi
source /apps/settings >/dev/null 2>&1
export RUN_CFG=$RUN/run_cfg.tcl
M=${ECO_MODE:-func}
N=eco_pt_${C}_$T$([ "$M" = shift ] && echo _shift)
D=$RUN/signoff/$N
rm -rf "$D"; mkdir -p "$D"
if [ "$T" = fc ]; then
  cp "$FC_CHANGES" "$D/eco_changes.tcl"
else
python3 - "$RUN/signoff/pt_policy.tcl" "$D/pt_eco.tcl" "$(dirname "$(readlink -f "$0")")/eco_drc_branch.tcl" <<'PY'
import re, sys
s = open(sys.argv[1]).read()
m = re.search(r'\n    drc \{.*?\n(?=    noise \{)', s, re.S)
if not m:
    sys.exit("FLASH_ECO_FAILED signoff/pt_policy.tcl has no drc branch before the noise branch; update eco_fixed.sh")
open(sys.argv[2], "w").write(s[:m.start()] + "\n" + open(sys.argv[3]).read() + s[m.end():])
PY
[ -s "$D/pt_eco.tcl" ] || exit 1
(cd "$D" && CORNER=$C PT_ECO=1 PT_ECO_TYPE=$T PT_MODE=$M pt_shell -f "$D/pt_eco.tcl" < /dev/null > pt.log 2>&1)
grep "^FLASH_PT_ECO\|^FLASH_MANUAL" "$D/pt.log" || { echo "FLASH_ECO_FAILED PrimeTime wrote no ECO line, see $D/pt.log"; exit 1; }
# TRY_ONLY=1: stop here. PrimeTime has shown what the changes would do; the design is untouched.
if [ -n "$TRY_ONLY" ]; then
  [ -f "$D/manual_violators.rpt" ] && grep VIOLATED "$D/manual_violators.rpt"
  echo "FLASH_ECO_TRY_ONLY nothing applied; see $D/pt.log"; exit 0
fi
fi
[ -s "$D/eco_changes.tcl" ] || { echo "FLASH_ECO_NONE no changes to apply"; exit 0; }
# Clock tree cells are fixed after CTS, and place_eco_cells skips fixed cells with only warning EPL-024: upsized
# clock buffers then overlapped their neighbours. Release every resized cell, and require a legal placement.
NSIZED=$(grep -c '^size_cell ' "$D/eco_changes.tcl")
{
  echo "set flash_eco_sized [get_cells -quiet [list $(sed -n 's/^size_cell {\{0,1\}\([^} ]*\)}\{0,1\} .*/{\1}/p' "$D/eco_changes.tcl" | tr '\n' ' ')]]"
  echo "puts \"FLASH_ECO_RELEASED [sizeof_collection \$flash_eco_sized] of $NSIZED\""
  [ "$NSIZED" -gt 0 ] && echo 'set_placement_status placed $flash_eco_sized'
  echo 'proc flash_eco_after {} {'
  echo '  global OUT'
  echo '  check_legality -verbose > $OUT/rpt/eco_legality.rpt'
  echo '  set f [open $OUT/rpt/eco_legality.rpt]; set r [read $f]; close $f'
  echo '  if {![regexp {TOTAL[[:space:]]+0[[:space:]]+Violations\.} $r]} { error "FLASH_ECO_ILLEGAL placement after the ECO" }'
  echo '  puts FLASH_ECO_LEGALITY_PASS'
  echo '}'
} >> "$D/eco_changes.tcl"
passed() { awk '$2 == "PASS" {print $1}' "$1" | sort; }
passes() { tail -1 "$1" 2>/dev/null | grep -oE "[0-9]+ of [0-9]+" | cut -d' ' -f1; }
BEFORE=$(passes "$RUN/signoff/CHECK.txt")
passed "$RUN/signoff/CHECK.txt" > "$D/passed_before.txt"
STATE="$(cd "$RUN" && ls -d *.nlib out rpt signoff fc_final.log fc_command.log fc_output.txt chip 2>/dev/null | tr '\n' ' ')"
KEEP=$RUN/.eco_prev
R=$RUN/eco_rejected_$N
restore() { (cd "$RUN" && rm -rf $STATE && mv "$KEEP"/* . && rmdir "$KEEP"); }
rm -rf "$KEEP"; mkdir "$KEEP"
(cd "$RUN" && cp -a $STATE "$KEEP"/) || { rm -rf "$KEEP"; echo "FLASH_ECO_FAILED could not save the run first"; exit 1; }
ECO_CHANGES="$D/eco_changes.tcl" START_AT=final $FLOW_DIR/run_fc.sh "$RUN" || {
  rm -rf "$R"; mkdir -p "$R"; cp -a "$D" "$RUN/fc_final.log" "$R"/; restore
  echo "FLASH_ECO_FAILED Fusion Compiler, see $R/fc_final.log; restored the run"; exit 1; }
grep "^FLASH_ECO_\(APPLIED\|RELEASED\|LEGALITY_PASS\)" "$RUN/fc_final.log"
if [ -n "$AFTER_FC" ] && ! (cd "$RUN" && eval "$AFTER_FC") > "$D/after_fc.log" 2>&1; then
  rm -rf "$R"; mkdir -p "$R"; cp -a "$D" "$RUN/fc_final.log" "$R"/; restore
  echo "FLASH_ECO_FAILED AFTER_FC, see $R/$N/after_fc.log; restored the run"; exit 1
fi
touch "$D/signoff_start"
$FLOW_DIR/signoff.sh "$RUN"
# A signoff that stops early leaves the old CHECK.txt behind; only a new one counts.
AFTER=$([ "$RUN/signoff/CHECK.txt" -nt "$D/signoff_start" ] && passes "$RUN/signoff/CHECK.txt")
LOST=$(comm -23 "$D/passed_before.txt" <(passed "$RUN/signoff/CHECK.txt") | tr '\n' ' ')
if [ -z "$AFTER" ] || [ "$AFTER" -lt "${BEFORE:-0}" ] || [ -n "$LOST" ]; then
  rm -rf "$R"; mkdir -p "$R"
  cp -a "$D" "$RUN/signoff/CHECK.txt" "$RUN/fc_final.log" "$R"/
  restore
  echo "FLASH_ECO_REJECTED ${AFTER:-no} checks pass against $BEFORE before; newly failing: ${LOST:-none}; restored the run, the attempt is in $R"
  exit 0
fi
rm -rf "$KEEP"
echo "FLASH_ECO_KEPT $AFTER checks pass against $BEFORE before"
exit
}
