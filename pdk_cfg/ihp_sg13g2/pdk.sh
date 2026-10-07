# IHP SG13G2 values for the signoff shell script (StarRC, KLayout, LVS netlist).
PDK_ROOT=$HOME/flash/pdk/IHP-Open-PDK/ihp-sg13g2
PDK_WORK=$HOME/flash/ihp
TECH_LEF=$PDK_ROOT/libs.ref/sg13g2_stdcell/lef/sg13g2_tech.lef
CELL_LEF=$PDK_ROOT/libs.ref/sg13g2_stdcell/lef/sg13g2_stdcell.lef
CELL_CDL=$PDK_ROOT/libs.ref/sg13g2_stdcell/cdl/sg13g2_stdcell.cdl
NXTGRD=$PDK_WORK/rc/sg13g2_typ.nxtgrd
# Worst and best wire models, from the ranges in IHP's process specification; see ihp/rc/DERIVATION.md.
RC_CMAX_GRID=${RC_CMAX_GRID:-$PDK_WORK/rc/rcmax/sg13g2_spec_rcmax.nxtgrd}
RC_CMIN_GRID=${RC_CMIN_GRID:-$PDK_WORK/rc/rcmin/sg13g2_spec_rcmin.nxtgrd}
RC_MAP=$PDK_WORK/rc/tf_itf.map
KL_TECH=$PDK_ROOT/libs.tech/klayout/tech
CORNER_NAMES="slow typ fast"
# IHP's LVS deck. DRC runs through flow/drc.sh.
lvs_run() { python3 $KL_TECH/lvs/run_lvs.py --layout="$1" --netlist="$2" --topcell="$3" --run_dir="$4" --run_mode=deep "${@:5}"; }

# Clock period for the counter regression.
REGRESS_PERIOD_NS=5.0
