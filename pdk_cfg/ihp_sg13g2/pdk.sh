# IHP SG13G2 values for the signoff shell script (StarRC, KLayout, LVS netlist).
PDK_ROOT=$HOME/flash/pdk/IHP-Open-PDK/ihp-sg13g2
PDK_WORK=$HOME/flash/ihp
TECH_LEF=$PDK_ROOT/libs.ref/sg13g2_stdcell/lef/sg13g2_tech.lef
CELL_LEF=$PDK_ROOT/libs.ref/sg13g2_stdcell/lef/sg13g2_stdcell.lef
CELL_CDL=$PDK_ROOT/libs.ref/sg13g2_stdcell/cdl/sg13g2_stdcell.cdl
NXTGRD=$PDK_WORK/rc/sg13g2_typ.nxtgrd
RC_MAP=$PDK_WORK/rc/tf_itf.map
KL_TECH=$PDK_ROOT/libs.tech/klayout/tech
CORNER_NAMES="slow typ fast"
# Official IHP decks. Antenna is off by default in IHP's DRC, so it is switched on.
drc_run() { python3 $KL_TECH/drc/run_drc.py --path="$1" --topcell="$2" --run_dir="$3" --antenna --mp=8 --run_mode=deep; }
lvs_run() { python3 $KL_TECH/lvs/run_lvs.py --layout="$1" --netlist="$2" --topcell="$3" --run_dir="$4" --run_mode=deep "${@:5}"; }

# Clock period for the counter regression.
REGRESS_PERIOD_NS=5.0
