#!/bin/bash
# Scan test for the chip: TestMAX stuck-at patterns on the final netlist, then a zero-delay VCS replay of every
# pattern, once in parallel and once fully serial through the scan pads. The inputs are copies of the final netlist,
# filled GDS and test protocol, so check.py can tie the result to the layout being built.
# evidence.json is written with reviewed_by and reviewed_on empty. A reviewer fills them, see chip/review.
# usage: atpg.sh <run_folder>       results in <run_folder>/signoff/atpg
set -u
RUN=$(readlink -f "$1"); [ -f "$RUN/run_cfg.tcl" ] || { echo "usage: atpg.sh <run_folder>"; exit 1; }
CHK=$HOME/flash/flow/check.py
O=$RUN/signoff/atpg
L=$HOME/flash/pdk/IHP-Open-PDK/ihp-sg13g2/libs.ref
set +u
source /apps/settings >/dev/null 2>&1
set -u
unset PYTHONHOME PYTHONPATH
export SYNOPSYS_TMAX=$(readlink -f /apps/syn/txs/current)
export PATH=$SYNOPSYS_TMAX/bin:$PATH
rm -rf "$O"; mkdir -p "$O"; cd "$O" || exit 1
cp "$RUN/out/flash_chip.v" input.v && cp "$RUN/chip/chip_filled.gds" input.gds && cp "$RUN/out/flash_chip.Internal_scan.spf" input.spf || exit 1
python3 "$CHK" --begin "$RUN" atpg || exit 1
export NETLIST=$O/input.v SPF=$O/input.spf OUTDIR=$O TOP=flash_chip MODEL=stuck
export LIBS="$L/sg13g2_stdcell/verilog/sg13g2_udp.v $L/sg13g2_stdcell/verilog/sg13g2_stdcell.v $L/sg13g2_io/verilog/sg13g2_io.v"
# The SRAMs have no ATPG model: black boxes for ATPG, behavioral models in the replay.
export BLACKBOX=RM_IHPSG13_1P_1024x32_c2_bm_bist
SIMLIBS="$LIBS $L/sg13g2_sram/verilog/RM_IHPSG13_1P_1024x32_c2_bm_bist.v $L/sg13g2_sram/verilog/RM_IHPSG13_1P_core_behavioral_bm_bist.v"
fail() { echo "ATPG_FAIL $1"; python3 "$CHK" --stamp "$RUN" atpg atpg 1; exit 1; }
timeout 5400 tmax -shell -tcl "$HOME/flash/chip/atpg.tcl" < /dev/null > tmax.log 2>&1
grep -q FLASH_ATPG_DONE tmax.log || fail "TestMAX did not finish, see $O/tmax.log"
mv summary_stuck.rpt summary.rpt; mv drc_rules_stuck.rpt drc_rules.rpt; mv patterns_stuck.stil patterns.stil
P=$(awk '/#internal patterns/{print $3}' summary.rpt)
stil2verilog patterns.stil pat_tb -replace > convert.log 2>&1 || fail "stil2verilog, see $O/convert.log"
vcs -full64 -sverilog +v2k -timescale=1ns/1ps +notimingcheck +nospecify +delay_mode_zero -o simv pat_tb.v input.v $SIMLIBS > compile.log 2>&1 || fail "vcs, see $O/compile.log"
timeout 1800 ./simv > parallel.log 2>&1 || fail "parallel replay"
timeout 7200 ./simv +tmax_serial="$P" > fullserial.log 2>&1 || fail "serial replay"
cmp -s input.v "$RUN/out/flash_chip.v" && cmp -s input.gds "$RUN/chip/chip_filled.gds" || fail "final netlist or GDS changed during ATPG"
python3 - "$O" <<'PY'
import json, hashlib, re, sys
from pathlib import Path
o = Path(sys.argv[1])
names = ['summary.rpt', 'drc_rules.rpt', 'tmax.log', 'parallel.log', 'fullserial.log', 'input.v', 'input.gds', 'input.spf']
rows = re.findall(r'^\s*(\w+)\s+(warning|error|fatal)\s+(\d+)\s+(.+)$', (o / 'drc_rules.rpt').read_text(), re.M | re.I)
record = {
    'reviewed_by': '',
    'reviewed_on': '',
    'minimum_test_coverage_percent': 95.0,
    'scope': 'Stuck-at manufacturing test of the standard-cell logic through the scan chains and pads. Zero-delay replay of every pattern, parallel and fully serial. SRAM interiors are black boxes and are not covered. Does not prove at-speed timing.',
    'reviewed_drc_warnings': {code: int(count) for code, severity, count, description in rows if severity.lower() == 'warning'},
    'drc_warning_reason': 'DRAFT: the reviewer confirms each TestMAX rule warning listed above after reading drc_rules.rpt.',
    'design': 'flash_chip',
    'tool_exit': 0,
    'artifact_sha256': {n: hashlib.sha256((o / n).read_bytes()).hexdigest() for n in names},
}
(o / 'evidence.json').write_text(json.dumps(record, indent=2))
PY
python3 "$CHK" --stamp "$RUN" atpg atpg 0
grep -h "XTB: Simulation of" parallel.log fullserial.log
grep -E "test coverage|#internal patterns" summary.rpt
echo ATPG_DONE
