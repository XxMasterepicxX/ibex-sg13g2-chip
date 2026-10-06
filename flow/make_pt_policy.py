# The PrimeTime signoff policy: a 5% cell and net derate and each corner's own extraction, the worst wire model at
# slow and the best at fast, fitted to the constraints line of pt_signoff.tcl. Both the
# normal and the ECO launch read the corner's extraction, never an older diagnostic one.
import re
import sys
from pathlib import Path

s = Path(sys.argv[1]).read_text()
src = "source $env(HOME)/flash/flow/constraints.tcl"
if s.count(src) != 1:
    sys.exit("private policy: constraints line not found exactly once")
policy = "\n".join([
    "set OCV_DERATE {0.95 1.05}",
    src,
    "set_timing_derate -net_delay -early 0.95",
    "set_timing_derate -net_delay -late 1.05",
    "set rc_corner nominal",
    'if {$CORNER eq "slow"} {set rc_corner cmax}',
    'if {$CORNER eq "fast"} {set rc_corner cmin}',
    'puts "FLASH_PT_POLICY rc=$rc_corner early=0.95 late=1.05 scope=cell_net"',
])
s = s.replace(src, policy)
m = re.search(r"if \{\$eco\} \{\n  read_parasitics[^\n]*\n\} else \{\n  read_parasitics[^\n]*\n\}", s)
if not m:
    sys.exit("private policy: parasitics block not found")
s = s.replace(m.group(), "\n".join([
    "set extraction_dir starrc",
    'if {$rc_corner ne "nominal"} {set extraction_dir starrc_$rc_corner}',
    'if {![file exists $S/$extraction_dir/$DESIGN.spef]} {error "Required $rc_corner SPEF missing"}',
    "read_parasitics -format spef -keep_capacitive_coupling $S/$extraction_dir/$DESIGN.spef",
]))
Path(sys.argv[2]).write_text(s)
