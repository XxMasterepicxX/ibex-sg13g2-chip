#!/bin/bash
# Runs IHP's KLayout DRC, run_drc.py, so that no run can hang or pass by accident:
#   - The deep-mode maximal deck now and then stalls on one check for hours, and the same layout then runs again in
#     the usual time. A run past DRC_TIME_LIMIT minutes, 100 by default or twice a normal run, is stopped and run
#     once more. KLayout catches SIGTERM, so the run gets its own process group and the whole group gets SIGKILL.
#   - run_drc.py logs a deck that fails as "generated an exception" and still judges the decks that finished.
# usage: drc.sh <gds> <topcell> <run_dir> <log> [run_drc.py options...]
# exit: 124 after two runs past the limit, 3 when a deck failed, else run_drc.py's own code (1 also means markers).
G=$1 TOP=$2 D=$3 L=$4; shift 4
export PDK_ROOT=$HOME/flash/pdk/IHP-Open-PDK PDK=ihp-sg13g2 KLAYOUT_PATH=$HOME/flash/pdk/IHP-Open-PDK/ihp-sg13g2/libs.tech/klayout
export PATH=$HOME/flash/tools/bin:$HOME/flash/tools/pyenv/bin:$PATH
trap 'kill -KILL -- -$P 2> /dev/null; kill $W 2> /dev/null; exit 130' INT TERM HUP
for try in 1 2; do
  rm -f "$D.timeout"
  setsid python3 "$KLAYOUT_PATH/tech/drc/run_drc.py" --path="$G" --topcell="$TOP" --run_dir="$D" "$@" > "$L" 2>&1 &
  P=$!
  ( trap 'kill $S 2> /dev/null; wait $S; exit 0' TERM
    sleep "$(awk "BEGIN {print ${DRC_TIME_LIMIT:-100} * 60}")" & S=$!; wait $S
    touch "$D.timeout"; kill -KILL -- -$P 2> /dev/null ) &
  W=$!
  X=0; wait $P || X=$?
  kill $W 2> /dev/null; wait $W 2> /dev/null
  # Workers left behind by a launcher that died would keep files open in the run folder.
  kill -KILL -- -$P 2> /dev/null
  if [ -f "$D.timeout" ]; then X=124; elif grep -q "generated an exception" "$L"; then X=3; fi
  [ $X = 124 ] && [ $try = 1 ] || break
  rm -rf "$D.timed_out" "$L.timed_out"
  mv "$D" "$D.timed_out" 2> /dev/null; mv "$L" "$L.timed_out"
done
exit $X
