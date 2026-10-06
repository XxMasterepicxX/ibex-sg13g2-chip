#!/bin/bash
# VCS simulation of flash_soc running the self-checking program.
# usage: run_sim.sh <run_dir> <prog.hex> [rtl|gate <netlist.v> [sdf]]
# SIM_CELLS and SIM_MEMS replace the IHP cell and SRAM models, for another PDK.
# SDF_TYPE picks the SDF values for gate runs: max, the default, or min for a hold check at the fast corner.
# /apps/settings returns non-zero, so errors are checked explicitly rather than with set -e.
mkdir -p "$1"; RUN=$(readlink -f "$1"); HEX=$(readlink -f "$2"); MODE=${3:-rtl}; NET=${4:-}; SDF=${5:-}
D=$HOME/flash/designs
SRAM=$HOME/flash/pdk/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_sram/verilog
CV=$HOME/flash/pdk/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_stdcell/verilog
CELLS=${SIM_CELLS:-"$CV/sg13g2_stdcell.v $CV/sg13g2_udp.v"}
source /apps/settings >/dev/null 2>&1 || true
mkdir -p "$RUN" && cd "$RUN"
cp "$HEX" prog.hex
MEMS=${SIM_MEMS:-"$SRAM/RM_IHPSG13_1P_1024x32_c2_bm_bist.v $SRAM/RM_IHPSG13_1P_core_behavioral_bm_bist.v"}
if [ "$MODE" = rtl ]; then
    # RTL_SRC overrides the source list.
  SRC=${RTL_SRC:-"$D/flash_soc/rtl/flash_chip.v $D/flash_soc/rtl/flash_soc.v $D/flash_soc/rtl/ibex_nogate.v $D/flash_soc/rtl/prim_clock_gating_ihp.v"}
  OPTS="+notimingcheck +nospecify $CELLS ${VCS_DEFINES:-}"
else
  SRC="$NET $CELLS"
  OPTS="${VCS_DEFINES:-}"
  [ -n "$SDF" ] && OPTS="$OPTS -sdf ${SDF_TYPE:-max}:tb_flash_soc.dut:$SDF +neg_tchk" || OPTS="$OPTS +notimingcheck +nospecify"
fi
vcs -full64 -sverilog -timescale=1ns/1ps +v2k $OPTS -o simv $D/flash_soc/tb/tb_flash_soc.sv $SRC $MEMS > vcs_compile.log 2>&1 || { echo "TB_RESULT FAIL compile, see $RUN/vcs_compile.log"; exit 1; }
./simv ${SIM_ARGS:-} > sim.log 2>&1 || true
grep -E "TB:|TB_RESULT" sim.log
