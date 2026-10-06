# A PrimeTime script for margin tests, from a run's own signoff script: reports go to $SCRATCH instead of the
# signoff folder, and the SDF write and the exit are left off so a test can be appended.
# usage: make_pt_base.py <run>/signoff/pt_policy.tcl <out.tcl>
import sys
out = []
for l in open(sys.argv[1]).read().splitlines(True):
    if l.startswith('set R $S/pt_'):
        l = 'set R $env(SCRATCH)/$CORNER$TIMING_MODE\n'
    elif l.startswith('if {$eco} { set R $S/eco_pt_') or l.startswith('write_sdf ') or l.strip() == 'exit':
        continue
    out.append(l)
open(sys.argv[2], 'w').writelines(out)
