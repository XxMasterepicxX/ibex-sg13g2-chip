#!/bin/bash
# Makes a run folder for one build of the chip: ~/flash/runs/<name>/run_cfg.tcl, with OUT set to that folder.
# usage: new_run.sh <name>
set -e
[ -n "$1" ] || { echo "usage: new_run.sh <name>"; exit 1; }
RUN=$HOME/flash/runs/$1
[ -e "$RUN/run_cfg.tcl" ] && { echo "$RUN already has a run_cfg.tcl"; exit 1; }
mkdir -p "$RUN"
sed -e "s|@HOME@|$HOME|g" -e "s|@RUN@|$RUN|g" "$HOME/flash/chip/run_cfg.tcl" > "$RUN/run_cfg.tcl"
echo "$RUN"
