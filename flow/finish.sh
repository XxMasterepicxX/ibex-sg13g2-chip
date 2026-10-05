#!/bin/bash
# IHP chip finishing: seal ring around the block, then IHP metal fill, density report and full DRC.
# usage: finish.sh <run_dir> <margin_um> [bondpads]
# bondpads: the design has an IHP pad ring; bond pads go on each pad before the seal ring.
# METAL_FILL=auto|dense|ihp picks the metal fill. auto and dense keep 0.42 um from existing metal, to lift
# small blocks past the 35% minimum. auto starts each pattern at its own region's corner and goes off the 5 nm
# grid when a region corner is off it (chip_v4: 558000 Offgrid markers); dense keeps one origin. Both pushed
# chip_v4 and chip_v5, with a pad ring, past the 60% maximum. ihp is IHP's own macro, 1.5 to 2 um away: under
# 60% everywhere, but the chip's centre 800 um window fell under 25% on M2, M3 and M5 (chip_v6). mid is IHP's
# macro at 1.0 um on M2 to M5.
set -e
R=$(readlink -f "$1"); M=$2; BP=${3:-}
DESIGN=$(awk '$2=="DESIGN"{print $3}' "$R/run_cfg.tcl")
F=$R/chip; mkdir -p $F
export PDK_ROOT=$HOME/flash/pdk/IHP-Open-PDK PDK=ihp-sg13g2 KLAYOUT_PATH=$HOME/flash/pdk/IHP-Open-PDK/ihp-sg13g2/libs.tech/klayout
export PATH=$HOME/flash/tools/bin:$HOME/flash/tools/pyenv/bin:$PATH
C=$HOME/flash/pdk_cfg/ihp_sg13g2
IN=$R/out/$DESIGN.gds
if [ "$BP" = bondpads ]; then
  klayout -n sg13g2 -zz -r $C/add_bondpads.py -rd in_gds=$IN -rd top=$DESIGN -rd out_gds=$F/with_bondpads.gds > $F/bondpads.log 2>&1
  IN=$F/with_bondpads.gds
fi
klayout -n sg13g2 -zz -r $C/chip_finish.py -rd in_gds=$IN -rd top=$DESIGN -rd out_gds=$F/chip.gds -rd margin=$M > $F/chip_finish.log 2>&1
klayout -n sg13g2 -zz -r $HOME/flash/ihp/fill/fill_dense.py -rd metal_lym=sg13g2_filler_Metal_${METAL_FILL:-auto}.lym -rd output_file=$F/chip_filled.gds $F/chip.gds > $F/fill.log 2>&1
python3 $C/density.py $F/chip_filled.gds chip_$DESIGN > $F/density.txt 2>&1
python3 "$HOME/flash/flow/check.py" --begin "$R" chip_drc
python3 $KLAYOUT_PATH/tech/drc/run_drc.py --path=$F/chip_filled.gds --topcell=chip_$DESIGN --run_dir=$F/drc --antenna --mp=8 > $F/drc.log 2>&1
X=$?; python3 "$HOME/flash/flow/check.py" --stamp "$R" chip_drc chip_drc "$X"
python3 "$HOME/flash/flow/check.py" --begin "$R" chip_precheck
# IHP's tapeout precheck: the rule subset IHP requires before accepting a design.
python3 $KLAYOUT_PATH/tech/drc/run_drc.py --path=$F/chip_filled.gds --topcell=chip_$DESIGN --run_dir=$F/precheck --precheck_drc --mp=8 > $F/precheck.log 2>&1
X=$?; python3 "$HOME/flash/flow/check.py" --stamp "$R" chip_precheck chip_precheck "$X"
echo DONE > $F/done
