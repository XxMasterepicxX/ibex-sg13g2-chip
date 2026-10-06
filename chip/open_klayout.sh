#!/bin/bash
# Opens the finished chip of a run in KLayout with IHP's layer colors. Tools, Marker Browser loads the DRC results
# from <run>/chip/drc. Needs an X display: ssh -X, MobaXterm or a VNC session.
# usage: open_klayout.sh <run_folder> [gds]       gds: chip/chip_filled.gds by default
RUN=$(readlink -f "$1"); G=${2:-$RUN/chip/chip_filled.gds}
[ -f "$G" ] || { echo "usage: open_klayout.sh <run_folder> [gds]   (no $G yet)"; exit 1; }
KLAYOUT_GUI=1 exec $HOME/flash/tools/bin/klayout \
  -l $HOME/flash/pdk/IHP-Open-PDK/ihp-sg13g2/libs.tech/klayout/tech/sg13g2.lyp "$G"
