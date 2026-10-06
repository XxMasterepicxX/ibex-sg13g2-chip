#!/bin/bash
# Runs every test in build/ on the chip, through the serial loader pins, in RTL or on a gate netlist.
# usage: run_suite.sh <out_dir> rtl
#        run_suite.sh <out_dir> gate <netlist.v> [sdf]
# Prints one line per test: name, expected result, TB_RESULT line, and OK or WRONG.
S=$(dirname "$(readlink -f "$0")")
OUT=$(readlink -m "$1"); MODE=$2; NET=${3:-}; SDF=${4:-}
D=$HOME/flash/designs/flash_soc
CV=$HOME/flash/pdk/IHP-Open-PDK/ihp-sg13g2/libs.ref
export SIM_CELLS="$CV/sg13g2_stdcell/verilog/sg13g2_stdcell.v $CV/sg13g2_stdcell/verilog/sg13g2_udp.v $CV/sg13g2_io/verilog/sg13g2_io.v"
export VCS_DEFINES="+define+CHIP ${EXTRA_DEFINES:-}"
export RTL_SRC="$D/rtl/flash_chip.v $D/rtl/flash_soc.v $D/rtl/ibex_nogate.v $D/rtl/prim_clock_gating_ihp.v"
mkdir -p "$OUT"
for t in main t_isa t_muldiv t_mem t_work t_muldiv_plant; do
  want=PASS; [ $t = t_muldiv_plant ] && want=FAIL
  if [ $MODE = rtl ]; then
    bash $D/sim/run_sim.sh $OUT/$t $S/build/$t/prog.hex rtl > $OUT/$t.out 2>&1
  else
    bash $D/sim/run_sim.sh $OUT/$t $S/build/$t/prog.hex gate $NET $SDF > $OUT/$t.out 2>&1
  fi
  got=$(grep -h "TB_RESULT" $OUT/$t/sim.log $OUT/$t.out 2>/dev/null | head -1)
  ok=WRONG; [[ "$got" == *"TB_RESULT $want"* ]] && ok=OK
  echo "$t want=$want got=[$got] $ok"
done | tee $OUT/summary.txt
