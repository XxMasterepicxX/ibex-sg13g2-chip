# The margin gate: every corner and mode evaluated, no changed cell flagged, no noise violation, slow setup at or
# above +0.6 ns in normal mode and +0.5 ns in scan mode, and fast hold at or above +0.09 ns. The only electrical
# violations allowed are on the SRAM outputs that Fusion Compiler buffers after this check.
# usage: gate.py <candN.eval>       run in the round folder; prints MARGIN_GATE PASS or FAIL
import glob, re, sys
rows = open(sys.argv[1]).read().splitlines()
get = lambda l, k: float(re.search(k + r'=([-0-9.]+)', l).group(1))
ok = len(rows) == 6 and all(' bad=0 ' in l and ' noise_viol=0 ' in l for l in rows)
dout = set(open('dout_pins.txt').read().split())
for f in glob.glob('eval_*.log'):
    for l in open(f):
        if l.startswith('FLASH_DRC_VIOL') and l.split()[1] not in dout:
            ok = False
            print('UNFIXED', f, l.strip())
for l in rows:
    if 'corner=slow mode=func' in l and get(l, 'setup_wns') < 0.6: ok = False
    if 'corner=slow mode=shift' in l and get(l, 'setup_wns') < 0.5: ok = False
    if 'corner=fast' in l and get(l, 'hold_wns') < 0.09: ok = False
print('MARGIN_GATE', 'PASS' if ok else 'FAIL')
