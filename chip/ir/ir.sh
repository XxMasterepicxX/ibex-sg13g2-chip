#!/bin/bash
# Static IR drop and DC electromigration on the final layout with RedHawk-SC. Five cases:
#   pads       one source per supply pad, on the strap next to it. Pessimistic: the pad ring rail carries nothing.
#   straps     one source on every strap from the pad ring. Optimistic: the pad ring rail is ideal.
#   saif       pads, with switching activity recorded while t_work runs on the gate netlist instead of 10%
#   emcontrol  pads with every EM limit cut 1000 times. Must report EM failures, or the EM check is not working.
#   defect     pads with all but one VDD Metal5 stripe removed. Must show more drop, or the IR check is not working.
# RedHawk-SC needs an Ansys license: set ANSYSLMD_LICENSE_FILE first. REDHAWK_SC overrides the program path.
# usage: ir.sh <run_folder>       results in <run_folder>/ir/<case>/baseline
RUN=$(readlink -f "$1"); [ -f "$RUN/run_cfg.tcl" ] || { echo "usage: ir.sh <run_folder>"; exit 1; }
[ -n "$ANSYSLMD_LICENSE_FILE" ] || { echo "Set ANSYSLMD_LICENSE_FILE to your Ansys license server first."; exit 1; }
I=$HOME/flash/chip/ir
W=$RUN/ir
mkdir -p "$W" && cd "$W" || exit 1
source /apps/settings > /dev/null 2>&1
unset PYTHONHOME PYTHONPATH

# Switching activity from t_work on the gate netlist, for the saif case.
D=$HOME/flash/designs/flash_soc
CV=$HOME/flash/pdk/IHP-Open-PDK/ihp-sg13g2/libs.ref
rm -rf saif_sim
SIM_CELLS="$CV/sg13g2_stdcell/verilog/sg13g2_stdcell.v $CV/sg13g2_stdcell/verilog/sg13g2_udp.v $CV/sg13g2_io/verilog/sg13g2_io.v" \
  VCS_DEFINES="+define+CHIP" SIM_ARGS=+saif \
  bash "$D/sim/run_sim.sh" saif_sim "$D/sw_suite/build/t_work/prog.hex" gate "$RUN/out/flash_chip.v" > saif_sim.log 2>&1
test -s saif_sim/activity.saif || { echo "no SAIF from the t_work simulation, see $W/saif_sim"; exit 1; }

python3 "$I/setup.py" "$RUN" "$W" saif_sim/activity.saif || exit 1
# IHP's published DC current limits for 11 years at 105 C, and the same limits cut 1000 times for the control.
ITF=$HOME/flash/pdk/IHP-Open-PDK/ihp-sg13g2/libs.tech/parasitics/itf/sg13g2_typ.itf
RT=${RHTECH:-/apps/syn/redhawk/bin/rhtech}
$RT -i "$ITF" -o ihp_em.tech -e em_limits.rhtech_em -f IHP -n 130 > rhtech.log 2>&1 || { echo "rhtech failed, see $W/rhtech.log"; exit 1; }
$RT -i "$ITF" -o ihp_control_em.tech -e em_control.rhtech_em -f IHP -n 130 > rhtech_control.log 2>&1 || { echo "rhtech failed, see $W/rhtech_control.log"; exit 1; }
for k in pads straps saif emcontrol defect; do
  python3 "$I/run.py" "$W" "$k"
done
for k in pads straps saif emcontrol defect; do
  f=$W/$k/baseline
  echo "$k worst_cell=$(sed -n 3p $f/static_voltage.rpt 2>/dev/null | awk '{print $3, $5}') em_wire_max=$(awk '!/^#/{print $8}' $f/em.rpt 2>/dev/null | sort -g | tail -1) em_via_max=$(awk '!/^#/{print $8}' $f/em_via.rpt 2>/dev/null | sort -g | tail -1) em_fail=$(awk '!/^#/ && $9!="pass"' $f/em.rpt 2>/dev/null | wc -l)"
done
echo IR_DONE
