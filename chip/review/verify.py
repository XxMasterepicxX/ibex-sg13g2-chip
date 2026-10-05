# Prints the evidence behind each review record, from the run's own netlist and reports. Read it before sign.py.
# usage: verify.py <run_folder>
import collections, re, sys
from pathlib import Path
R = Path(sys.argv[1]).resolve()
S = R / 'signoff'

print('== 1. unclocked register pins, check_timing')
for c in ['slow', 'typ', 'fast', 'slow_shift', 'typ_shift', 'fast_shift']:
    t = (S / f'pt_{c}/check_timing.rpt').read_text()
    sec = t.split("Checking 'no_clock'.", 1)[1].split('Information:', 1)[0] if "Checking 'no_clock'." in t else ''
    print(c, re.findall(r'There are (\d+) register clock pins', sec), re.findall(r'^\s*(\S+/\S+)\s*$', sec, re.M))
net = (R / 'out/flash_chip.v').read_text()
for inst in ['u_soc/u_imem', 'u_soc/u_dmem']:
    blk = next(s for s in net.split(';') if '\\' + inst + ' (' in s)
    for pin in ['A_BIST_CLK', 'A_BIST_EN', 'A_BIST_MEN']:
        n = re.search(r'\.' + pin + r'\s*\(\s*(\S+)\s*\)', blk).group(1)
        drv = [s.split()[0] for s in net.split(';') if re.search(r'\(\s*' + re.escape(n) + r'\s*\)', s) and '\\' + inst not in s]
        print(inst, pin, 'net', n, 'driven by', drv)

print('== 2. untested timing checks, by check type, reason and pin kind')
for c in ['slow', 'slow_shift']:
    t = (S / f'pt_{c}/analysis_coverage.rpt').read_text()
    rows = re.findall(r'^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(?:\S+\s+)?untested\s+(\S+)\s*$', t, re.M)
    k = collections.Counter((ct, why, re.sub(r'.*/', '', ep).split('(')[0].rstrip('[]0123456789')) for ep, rel, clk, ct, why in rows)
    print(c, len(rows))
    for key, n in k.most_common(14):
        print('  ', n, key)
    noclk = [ep for ep, rel, clk, ct, why in rows if why == 'no_clock' and ct in ('setup', 'hold')]
    print('  no_clock setup/hold endpoints:', len(noclk), noclk[:6])

print('== 3. Formality')
print((R / 'review/SUMMARY.txt').read_text().strip().splitlines()[-2:])

print('== 4. ATPG rule warnings')
v = (S / 'atpg/drc_rules.rpt').read_text()
for code, severity, count, text in re.findall(r'^\s*(\w+)\s+(warning|error|fatal)\s+(\d+)\s+(.+)$', v, re.M | re.I):
    print(code, severity, count, text.strip())
