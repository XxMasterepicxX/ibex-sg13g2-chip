#!/bin/bash
# Signoff for one finished Fusion Compiler run: StarRC, PrimeTime SI at every corner, Formality,
# PrimePower, the PDK's DRC and LVS decks, then the log parser. PDK facts come from pdk_cfg/<PDK>/pdk.sh.
# usage: signoff.sh <run_dir> [step...]   steps: starrc pt ptshift fm pp lvsnet drc lvs chiplvs check
# Braced so bash parses the whole script before running it: editing this file mid-run cannot corrupt a live signoff.
{
RUN=$(readlink -f "$1"); shift
set -o pipefail
STEPS=${*:-starrc pt ptshift fm pp lvsnet drc lvs chiplvs check}
source /apps/settings >/dev/null 2>&1
unset PYTHONHOME PYTHONPATH
export RUN_CFG=$RUN/run_cfg.tcl
source $HOME/flash/flow/tools.sh
export PATH=$HOME/flash/tools/bin:$HOME/flash/tools/pyenv/bin:$STARRC_BIN:$PATH
DESIGN=$(awk '$2=="DESIGN"{print $3}' "$RUN_CFG")
PDK=$(awk '$2=="PDK"{print $3}' "$RUN_CFG")
[ -n "$PDK" ] || { echo "run_cfg must set PDK" >&2; exit 1; }
source $HOME/flash/pdk_cfg/$PDK/pdk.sh
export PDK_ROOT PDK_WORK PDK_CFG NDM_LIB DB_DIR TLUP NXTGRD RC_MAP TECH_LEF CELL_LEF CELL_CDL ICV_RUNSET
FLOW=$HOME/flash/flow
# Hard macro views, optional in run_cfg: EXTRA_LEF for StarRC, EXTRA_CDL and EXTRA_LVS_REMAP for LVS.
cfg() { echo "source {$RUN_CFG}; if {[info exists $1]} { puts [join \$$1 { }] }" | tclsh; }
EXTRA_LEF=$(cfg EXTRA_LEF); EXTRA_CDL=$(cfg EXTRA_CDL); EXTRA_LVS_REMAP=$(cfg EXTRA_LVS_REMAP)
LVS_BLACKBOX=$(cfg LVS_BLACKBOX)
S=$RUN/signoff
mkdir -p "$S"
SNAP=$S/flow_snapshot
mkdir -p "$SNAP"
cp "$FLOW/check.py" "$SNAP/check.py"
cp "$FLOW/make_pt_policy.py" "$SNAP/make_pt_policy.py"
cp "$FLOW/constraints.tcl" "$SNAP/constraints.tcl"
cp "$FLOW/pt_signoff.tcl" "$SNAP/pt_signoff.tcl"
cp "$FLOW/pp_power.tcl" "$SNAP/pp_power.tcl"
cp "$FLOW/tools.sh" "$SNAP/tools.sh"
sed '/report_failing_points > /a report_dont_verify_points > $R/dont_verify.rpt' "$FLOW/fm_verify.tcl" > "$SNAP/fm_verify.tcl"
# Every analysis launch uses the frozen shared constraints and the frozen source scripts.
sed -i -e "s#source .*flash/flow/constraints.tcl#source {$SNAP/constraints.tcl}#" "$SNAP/pp_power.tcl"
CHECKER=$SNAP/check.py
export CORNER_NAMES
printf 'source {%s}\nset OUT {%s}\n' "$RUN/run_cfg.tcl" "$RUN" > "$S/executed_cfg.tcl"
export RUN_CFG=$S/executed_cfg.tcl
python3 "$CHECKER" --prepare "$RUN" || exit 1
if [ -f "$S/provenance/fc_producer.json" ]; then
  python3 "$CHECKER" --bind-fc "$RUN" || echo FLASH_FC_PROVENANCE_UNBOUND_REQUIRES_CURRENT_PRODUCER
fi
begin() { python3 "$CHECKER" --begin "$RUN" "$1"; }
stamp() { python3 "$CHECKER" --stamp "$RUN" "$1" "$2" "$3"; }
# Keep the policy script with the run, including its coverage reports and frozen constraints source.
python3 "$SNAP/make_pt_policy.py" "$SNAP/pt_signoff.tcl" "$S/pt_policy.tcl"
sed -i -e "s#source .*flash/flow/constraints.tcl#source {$SNAP/constraints.tcl}#" \
  -e '/check_timing -verbose/a report_analysis_coverage -status_details {untested} -nosplit > $R/analysis_coverage.rpt\nreport_disable_timing -nosplit > $R/disabled_timing.rpt' "$S/pt_policy.tcl"
PT_SCRIPT=$S/pt_policy.tcl
python3 "$CHECKER" --record-deps "$RUN" || exit 1

has() { [[ " $STEPS " == *" $1 "* ]]; }

if has starrc; then
  for rc in nominal cmax cmin; do
  SUB=starrc; GRID=$NXTGRD; TEMP=25
  if [ "$rc" != nominal ]; then
    SUB=starrc_$rc
    V=RC_${rc^^}_GRID; GRID=${!V}
    [ "$rc" = cmax ] && TEMP=125 || TEMP=-40
  fi
  mkdir -p "$S/$SUB"
  cat > "$S/$SUB/star.cmd" <<EOF
BLOCK: $DESIGN
LEF_FILE: $TECH_LEF
LEF_FILE: $CELL_LEF
$(for l in $EXTRA_LEF; do echo "LEF_FILE: $l"; done)
TOP_DEF_FILE: $RUN/out/$DESIGN.def
TCAD_GRD_FILE: $GRID
MAPPING_FILE: $RC_MAP
EXTRACTION: RC
COUPLE_TO_GROUND: NO
REDUCTION: NO_EXTRA_LOOPS
NETLIST_FORMAT: SPEF
NETLIST_FILE: $S/$SUB/$DESIGN.spef
OPERATING_TEMPERATURE: $TEMP
NUM_CORES: 8
STAR_DIRECTORY: $S/$SUB/star
SUMMARY_FILE: $DESIGN.star_sum
EOF
  begin "$SUB" || exit 1
  if [ "$rc" != nominal ] && { [ "$GRID" = "$NXTGRD" ] || [ ! -f "$GRID" ] || cmp -s "$GRID" "$NXTGRD"; }; then
    echo "ERROR: real $rc grid unavailable; nominal substitution forbidden" > "$S/$SUB/starrc.log"
    echo STARRC_EXIT=1 >> "$S/$SUB/starrc.log"
    stamp "$SUB" "$SUB" 1
    continue
  fi
  (cd "$S/$SUB" && echo "FLASH_STARRC_LAUNCH script=$S/$SUB/star.cmd grid=$GRID" > starrc.log; StarXtract star.cmd < /dev/null >> starrc.log 2>&1; X=$?; echo "STARRC_EXIT=$X" >> starrc.log; exit "$X")
  X=$?; stamp "$SUB" "$SUB" "$X"
  done
fi

if has pt; then
  for c in $CORNER_NAMES; do
    begin "pt_$c" || { echo "FLASH_PT_UNAVAILABLE corner=$c missing required qualified extraction"; continue; }
    mkdir -p "$S/pt_$c"
    RC_DIR=starrc
    [ "$c" = slow ] && RC_DIR=starrc_cmax
    [ "$c" = fast ] && RC_DIR=starrc_cmin
    SPEF="$S/$RC_DIR/$DESIGN.spef"
    (cd "$S/pt_$c" && echo "FLASH_PT_LAUNCH script=$PT_SCRIPT spef=$SPEF netlist=$RUN/out/$DESIGN.v" > pt.log; CORNER=$c pt_shell -f $PT_SCRIPT < /dev/null >> pt.log 2>&1; X=$?; echo "PT_EXIT=$X" >> pt.log; exit "$X")
    X=$?; stamp "pt_$c" "pt_$c,noise_$c" "$X"
  done
fi

# Scan shift at every corner, for designs with scan chains: hold on the chains is the usual shift-mode failure.
if has ptshift && { [ -n "$(cfg SCANDEF)" ] || [ -n "$(cfg DFT_SETUP)" ]; }; then
  for c in $CORNER_NAMES; do
    mkdir -p "$S/pt_${c}_shift"
    begin "pt_${c}_shift" || { echo "FLASH_PT_UNAVAILABLE corner=$c mode=shift missing required qualified extraction"; continue; }
    RC_DIR=starrc
    [ "$c" = slow ] && RC_DIR=starrc_cmax
    [ "$c" = fast ] && RC_DIR=starrc_cmin
    SPEF="$S/$RC_DIR/$DESIGN.spef"
    (cd "$S/pt_${c}_shift" && echo "FLASH_PT_LAUNCH script=$PT_SCRIPT spef=$SPEF netlist=$RUN/out/$DESIGN.v mode=shift" > pt.log; CORNER=$c PT_MODE=shift pt_shell -f $PT_SCRIPT < /dev/null >> pt.log 2>&1; X=$?; echo "PT_EXIT=$X" >> pt.log; exit "$X")
    X=$?; stamp "pt_${c}_shift" "pt_${c}_shift,noise_${c}_shift" "$X"
  done
fi

if has fm; then
  mkdir -p "$S/formality"
  # Formality O-2018 cannot parse SystemVerilog-2009 macros with default arguments (lowRISC prim_assert,
  # common_cells assertions.svh; FMR_VLOG-536 and -527), so multi-file SV projects, those that set INC_DIRS, give
  # Formality a reference preprocessed by sv2v. FC still reads the original SystemVerilog.
  unset FM_RTL
  if [ -n "$(cfg INC_DIRS)" ]; then
    $HOME/flash/tools/bin/sv2v -DSYNTHESIS $(for d in $(cfg DEFINES); do echo "-D$d"; done) \
      $(for i in $(cfg INC_DIRS); do echo "-I$i"; done) $(cfg RTL_FILES) > "$S/formality/rtl_sv2v.v" 2> "$S/formality/sv2v.log" \
      && export FM_RTL="$S/formality/rtl_sv2v.v"
  fi
  begin formality || exit 1
  (cd "$S/formality" && echo "FLASH_FM_LAUNCH script=$SNAP/fm_verify.tcl netlist=$RUN/out/$DESIGN.v" > fm.log; $FM_SHELL -f "$SNAP/fm_verify.tcl" < /dev/null >> fm.log 2>&1; X=$?; echo "FM_EXIT=$X" >> fm.log; exit "$X")
  X=$?; stamp formality formality "$X"
fi

if has pp; then
  mkdir -p "$S/primepower"
  begin primepower || exit 1
  (cd "$S/primepower" && echo "FLASH_PP_LAUNCH script=$SNAP/pp_power.tcl spef=$S/starrc/$DESIGN.spef netlist=$RUN/out/$DESIGN.v" > pp.log; pt_shell -f "$SNAP/pp_power.tcl" < /dev/null >> pp.log 2>&1; X=$?; echo "PP_EXIT=$X" >> pp.log; exit "$X")
  X=$?; stamp primepower primepower "$X"
fi

if has lvsnet; then
  mkdir -p "$S/lvs"
  cat "$CELL_CDL" $EXTRA_CDL > "$S/lvs/cells.cdl"
  python3 $FLOW/v2cdl.py "$RUN/out/$DESIGN.pg.v" "$S/lvs/cells.cdl" "$DESIGN" "$S/lvs/$DESIGN.cdl" ${LVS_PIN_REMAP:-} $EXTRA_LVS_REMAP > "$S/lvs/v2cdl.log" 2>&1
  echo "V2CDL_EXIT=$?" >> "$S/lvs/v2cdl.log"
fi

# DRC, LVS and whole-chip LVS read only the finished layouts and netlists and write their own folders, so they
# run at once. Each is a single KLayout job that uses one core; whole-chip LVS is the longest.
drc_step() {
  begin drc || exit 1
  rm -rf "$S/drc"
  # A design with an IO ring is a chip: its density rules are judged on the filled chip, not here.
  DRC_CHIP=$([ -n "$(cfg IO_RING)" ] && echo 1)
  DRC_CHIP=$DRC_CHIP drc_run "$RUN/out/$DESIGN.gds" "$DESIGN" "$S/drc" < /dev/null > "$S/drc.log" 2>&1
  X=$?; echo "DRC_EXIT=$X" >> "$S/drc.log"
  # KLayout's run_drc.py exits 1 when it finds markers, the same code as a crash. A finished run logs its run time
  # and writes its result databases; the drc row then judges the markers, chip-only rules on the filled chip.
  [ "$X" = 1 ] && grep -q "Total DRC Run time" "$S/drc.log" && ls "$S"/drc/*.lyrdb > /dev/null 2>&1 && X=0
  stamp drc drc "$X"
}

lvs_step() {
  begin lvs || exit 1
  rm -rf "$S/lvs/run" "$S/lvs/extract"
  if [ -n "$LVS_BLACKBOX" ]; then
    # Foundry macros in LVS_BLACKBOX keep their pins and lose their contents on both sides, so the compare
    # checks every connection to them and nothing inside. --no_simplify keeps simplification from purging
    # the boxes' floating pins; with it, a planted swap of two SRAM address nets fails as it should.
    {
      lvs_run "$RUN/out/$DESIGN.gds" "$S/lvs/$DESIGN.cdl" "$DESIGN" "$S/lvs/extract" --net_only
      python3 $FLOW/lvs_blackbox.py "$S/lvs/extract/${DESIGN}_extracted.cir" "$S/lvs/layout_bb.cir" \
        "$S/lvs/$DESIGN.cdl" "$S/lvs/schematic_bb.cdl" "$DESIGN" $LVS_BLACKBOX &&
      lvs_run "$RUN/out/$DESIGN.gds" "$S/lvs/schematic_bb.cdl" "$DESIGN" "$S/lvs/run" --layout_netlist="$S/lvs/layout_bb.cir" --no_simplify
    } < /dev/null > "$S/lvs.log" 2>&1
  else
    lvs_run "$RUN/out/$DESIGN.gds" "$S/lvs/$DESIGN.cdl" "$DESIGN" "$S/lvs/run" < /dev/null > "$S/lvs.log" 2>&1
  fi
  X=$?; echo "LVS_EXIT=$X" >> "$S/lvs.log"
  stamp lvs lvs "$X"
}

chiplvs_step() {
  begin chip_lvs || exit 1
  "$FLOW/lvs_chip.sh" "$RUN" "$RUN/chip/chip_filled.gds" "chip_$DESIGN"
  X=$(sed -n 's/^LVS_EXIT=//p' "$S/lvs_chip/lvs.log" | tail -1)
  stamp chip_lvs chip_lvs "${X:-1}"
}
has drc && drc_step &
has lvs && lvs_step &
has chiplvs && [ -d "$RUN/chip" ] && chiplvs_step &
wait
if has check; then
  python3 "$CHECKER" "$RUN" | tee "$S/CHECK.txt"
  X=${PIPESTATUS[0]}
  echo "SIGNOFF_CHECK_EXIT=$X" > "$S/signoff.done"
  exit "$X"
fi
echo SIGNOFF_STAGES_DONE_CHECK_NOT_REQUESTED > "$S/signoff.done"
exit 0
}
