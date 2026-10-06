# Unsigned review drafts from a run's final reports, built with check.py's own parsers so the counts are the ones
# the checker compares. Drafts and SUMMARY.txt go to <run>/review. A person reads the evidence and signs with sign.py.
# usage: make_drafts.py <run_folder>
import json, re, sys
from pathlib import Path
run = Path(sys.argv[1]).resolve()
out = run / 'review'
out.mkdir(exist_ok=True)
sys.path.insert(0, str(Path(__file__).resolve().parent))
import checklib
chk = checklib.load()
manifest = json.loads((run / 'signoff/manifest.json').read_text())
summary = []

corners = {}
for corner in manifest['corners']:
    for mode in manifest['modes']:
        c = corner + ('_shift' if mode == 'shift' else '')
        actual = chk['analysis_coverage']((run / f'signoff/pt_{c}/analysis_coverage.rpt').read_text())
        actual['disabled_timing'] = chk['disabled_timing_coverage']((run / f'signoff/pt_{c}/disabled_timing.rpt').read_text())
        corners[c] = actual
        summary.append(f"{c}: total {actual['total']} met {actual['met']} violated {actual['violated']} untested {actual['untested']}; "
                       f"untested by reason {actual['reasons']}; disabled arcs {actual['disabled_timing']['total']} by flag {actual['disabled_timing']['flags']}")
(out / 'timing_coverage.json').write_text(json.dumps({'version': 1, 'reviewed_by': '', 'reviewed_on': '', 'corners': corners}, indent=2))

# Unclocked register pins. Only the SRAM self-test clocks are expected; anything else needs its own investigation.
lines = {'u_soc/u_imem': '178 to 179', 'u_soc/u_dmem': '190 to 191'}
inactive = []
for c in corners:
    t = (run / f'signoff/pt_{c}/check_timing.rpt').read_text()
    sec = t.split("Checking 'no_clock'.", 1)[1].split('Information:', 1)[0] if "Checking 'no_clock'." in t else ''
    for pin in re.findall(r'^\s*(\S+/\S+)\s*$', sec, re.M):
        if pin in {w['pin'] for w in inactive}:
            continue
        inst = pin.rsplit('/', 1)[0]
        if pin.endswith('/A_BIST_CLK') and inst in lines:
            inactive.append({'pin': pin,
                             'reason': 'The SRAM BIST port is unused. A_BIST_EN, A_BIST_CLK and A_BIST_MEN are tied low, so the macro always runs from A_CLK and this clock pin never toggles.',
                             'proof': f"designs/flash_soc/rtl/flash_soc.v lines {lines[inst]} tie A_BIST_CLK, A_BIST_EN and A_BIST_MEN to 1'b0. In out/flash_chip.v they are driven by sg13g2_tielo cells. PrimeTime holds the pin at 0 with set_case_analysis from chip/bist_constants.sdc."})
        else:
            summary.append(f'UNEXPECTED unclocked pin {pin} in {c}; not drafted, find out why it has no clock')
(out / 'timing_waivers.json').write_text(json.dumps({'reviewed_by': '', 'reviewed_on': '', 'inactive_clocks': sorted(inactive, key=lambda w: w['pin'])}, indent=2))
summary.append('unclocked pins drafted: ' + ' '.join(sorted(w['pin'] for w in inactive)))

stat = (run / 'signoff/formality/status.rpt').read_text()
dont = (run / 'signoff/formality/dont_verify.rpt').read_text()
passing = int(re.findall(r'(\d+) Passing compare points', stat)[-1])
excluded = re.findall(r"^\s*Don't verify\s+.*?\s+(\d+)\s*$", stat, re.M)
gates = re.findall(r'^\s*Clock-gate LAT\s+.*?\s+(\d+)\s*$', stat, re.M)
points = sorted({x.strip() for x in re.findall(r'^[ \t]*(?:\(\w+\)[ \t]+)?([ri]:/\S+)', dont, re.M)})
fm = {'reviewed_by': '', 'reviewed_on': '', 'expected_passing': passing,
      'expected_excluded': int(excluded[-1]) if excluded else 0,
      'expected_clock_gate_latches': int(gates[-1]) if gates else 0,
      'excluded': [{'point': p, 'reason': 'scan_out: the RTL ties it to 0; after scan insertion it carries the last scan flop even in functional mode. Test-only output, covered by ATPG.'} for p in points]}
(out / 'formality_coverage.json').write_text(json.dumps(fm, indent=2))
summary.append(f"formality: passing {passing}, excluded {fm['expected_excluded']} {points}, clock-gate latches {fm['expected_clock_gate_latches']}")
unmatched = (run / 'signoff/formality/unmatched.rpt').read_text()
summary.append('formality unmatched: ' + (re.findall(r'\d+ Unmatched points.*', unmatched) or ['none reported'])[0])
(out / 'SUMMARY.txt').write_text('\n'.join(summary) + '\n')
print('\n'.join(summary))
