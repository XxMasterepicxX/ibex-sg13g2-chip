#!/bin/bash
# Every test program on the final netlist with PrimeTime's delays from signoff: slow and typ with the late values,
# fast with the early ones, where hold is tightest. Timing checks are on. The three corners run at once.
# usage: gls.sh <run_folder>       results in <run_folder>/gls
RUN=$(readlink -f "$1"); [ -f "$RUN/run_cfg.tcl" ] || { echo "usage: gls.sh <run_folder>"; exit 1; }
S=$HOME/flash/designs/flash_soc/sw_suite
G=$RUN/gls
rm -rf "$G"; mkdir -p "$G"
md5sum "$RUN/out/flash_chip.v" > "$G/netlist.md5"
# The SRAM model checks the whole A_ADDR bus against fixed 1.0 ns setup and hold. The SDF gives per-bit limits from
# IHP's library, 0.32 to 0.34 ns hold at fast, which VCS cannot map onto a bus check, so fast reports violations
# against the 1 ns placeholder. PrimeTime, with the library's limits, decides hold. +tchk+edge+match lets the
# per-edge SDF checks annotate where they can.
export EXTRA_DEFINES=+tchk+edge+match
P=""
for c in slow typ fast; do
  t=max; [ $c = fast ] && t=min
  SDF_TYPE=$t "$S/run_suite.sh" "$G/$c" gate "$RUN/out/flash_chip.v" "$RUN/signoff/pt_$c/flash_chip.$c.sdf" > "$G/$c.log" 2>&1 &
  P="$P $!"
done
BAD=0
for p in $P; do wait $p || BAD=1; done
for c in slow typ fast; do
  echo "== $c"
  cat "$G/$c/summary.txt"
  echo "timing check messages: $(cat "$G"/$c/*/sim.log | grep -ci 'timing violation')"
done
# A missing or short summary is a failure too: each corner must judge all six programs OK.
for c in slow typ fast; do [ "$(grep -c ' OK$' "$G/$c/summary.txt" 2>/dev/null)" = 6 ] || BAD=1; done
[ $BAD = 0 ] || { echo GLS_FAIL; exit 1; }
echo GLS_PASS
