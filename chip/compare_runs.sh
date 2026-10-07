#!/bin/bash
# Place-and-route results of several runs side by side: routing errors, total wire length, Fusion Compiler's worst
# setup and hold slack against its own target, cell utilization, and the placement's first global-route overflow,
# which is how crowded the wiring looked before the router repaired it.
# usage: compare_runs.sh <run> [run...]       run names under ~/flash/runs, or run folders
[ -n "$1" ] || { echo "usage: compare_runs.sh <run> [run...]"; exit 1; }
printf "%-12s %5s %10s %9s %8s %6s %9s\n" run DRCs wire_um setup_ns hold_ns util overflow
for r in "$@"; do
  d=$r; [ -d "$d" ] || d=$HOME/flash/runs/$r
  p=$d/rpt
  drc=$(grep -h "Total number of DRCs =" $p/check_routes.rpt 2>/dev/null | tail -1 | awk '{print $NF}')
  wire=$(grep -h "Total Wire Length" $p/check_routes.rpt 2>/dev/null | tail -1 | awk '{print $(NF-1)}')
  setup=$(awk '$1 == "Design" && $2 == "(Setup)" {print $3}' $p/final_qor.rpt 2>/dev/null)
  hold=$(awk '$1 == "Design" && $2 == "(Hold)" {print $3}' $p/final_qor.rpt 2>/dev/null)
  util=$(awk '/Utilization Ratio/ {print $3}' $p/utilization_final.rpt 2>/dev/null)
  ovf=$(grep -h "^Initial. Both Dirs: Overflow" $p/place_congestion.rpt 2>/dev/null | head -1 | awk '{print $6}')
  printf "%-12s %5s %10s %9s %8s %6s %9s\n" "$(basename "$d")" "${drc:--}" "${wire:--}" "${setup:--}" "${hold:--}" \
    "${util:--}" "${ovf:--}"
done
