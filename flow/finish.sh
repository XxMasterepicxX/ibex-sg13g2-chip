#!/bin/bash
# IHP chip finishing: seal ring around the block, then IHP metal fill, density report and full DRC.
# usage: finish.sh <run_dir> <margin_um> [bondpads]
# bondpads: the design has an IHP pad ring; bond pads go on each pad before the seal ring.
# METAL_FILL picks ihp/fill/sg13g2_filler_Metal_<name>.lym. setup makes mid: IHP's macro with fill 1.0 um from
# existing metal on Metal2 to Metal5, which keeps this chip inside IHP's density limits.
set -e
R=$(readlink -f "$1"); M=$2; BP=${3:-}
DESIGN=$(awk '$2=="DESIGN"{print $3}' "$R/run_cfg.tcl")
F=$R/chip; mkdir -p $F; rm -f $F/done
export PDK_ROOT=$HOME/flash/pdk/IHP-Open-PDK PDK=ihp-sg13g2 KLAYOUT_PATH=$HOME/flash/pdk/IHP-Open-PDK/ihp-sg13g2/libs.tech/klayout
export PATH=$HOME/flash/tools/bin:$HOME/flash/tools/pyenv/bin:$PATH
C=$HOME/flash/pdk_cfg/ihp_sg13g2
IN=$R/out/$DESIGN.gds
if [ "$BP" = bondpads ]; then
  klayout -n sg13g2 -zz -r $C/add_bondpads.py -rd in_gds=$IN -rd top=$DESIGN -rd out_gds=$F/with_bondpads.gds > $F/bondpads.log 2>&1
  IN=$F/with_bondpads.gds
fi
klayout -n sg13g2 -zz -r $C/chip_finish.py -rd in_gds=$IN -rd top=$DESIGN -rd out_gds=$F/chip.gds -rd margin=$M > $F/chip_finish.log 2>&1
klayout -n sg13g2 -zz -r $HOME/flash/ihp/fill/fill.py -rd metal_lym=sg13g2_filler_Metal_${METAL_FILL:-mid}.lym -rd output_file=$F/chip_filled.gds $F/chip.gds > $F/fill.log 2>&1
python3 $C/density.py $F/chip_filled.gds chip_$DESIGN > $F/density.txt 2>&1
python3 "$HOME/flash/flow/check.py" --begin "$R" chip_drc
python3 "$HOME/flash/flow/check.py" --begin "$R" chip_precheck
# Whole-chip DRC and IHP's tapeout precheck, the rule subset IHP requires before accepting a design, read the same
# file and run at once, each through flow/drc.sh. Each spends most of its 50 minutes in the deep-mode maximal deck.
drc_job() {  # <name> <run_drc.py options...>
  local n=$1 X=0; shift
  bash $HOME/flash/flow/drc.sh $F/chip_filled.gds chip_$DESIGN $F/$n $F/$n.log "$@" || X=$?
  echo $X > $F/$n.exit
}
rm -f $F/drc.exit $F/precheck.exit
drc_job drc --antenna --mp=8 & D=$!
drc_job precheck --precheck_drc --mp=8 & Q=$!
XD=0; wait $D || XD=$?
XQ=0; wait $Q || XQ=$?
[ $XD = 0 ] && [ $XQ = 0 ] && [ -f $F/drc.exit ] && [ -f $F/precheck.exit ] \
  || { echo "A DRC job did not finish. See $F/drc.log and $F/precheck.log"; exit 1; }
python3 "$HOME/flash/flow/check.py" --stamp "$R" chip_drc chip_drc "$(cat $F/drc.exit)"
python3 "$HOME/flash/flow/check.py" --stamp "$R" chip_precheck chip_precheck "$(cat $F/precheck.exit)"
[ "$(cat $F/drc.exit)" = 0 ] && [ "$(cat $F/precheck.exit)" = 0 ] \
  || { echo "Chip DRC or the precheck did not pass. See $F/drc.log and $F/precheck.log"; exit 1; }
echo DONE > $F/done
