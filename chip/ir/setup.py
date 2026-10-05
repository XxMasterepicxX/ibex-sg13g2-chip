# Writes the five RedHawk-SC cases for one run: a config.json, a DEF and a sources.ploc in <workdir>/<case>.
# The core takes power through 10 um straps from the pad ring's supply rail, which RedHawk cannot see inside the pad
# cells. Two cases bound the real answer:
#   pads:   one source per supply pad, on the strap at or next to that pad. Pessimistic: the pad ring rail carries
#           no current to the other straps.
#   straps: one source on every strap. Optimistic: the pad ring rail is ideal.
# usage: setup.py <run_folder> <workdir> <activity.saif>
import hashlib, json, re, shutil, sys
from pathlib import Path

run, W, saif = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])
I = Path(__file__).resolve().parent
lib = Path.home() / 'flash/pdk/IHP-Open-PDK/ihp-sg13g2/libs.ref'
cfg = (run / 'run_cfg.tcl').read_text()
setting = lambda k: re.search(r'^set %s\s+(\S+)' % k, cfg, re.M).group(1)

src = run / 'out/flash_chip.def'
text = src.read_text()
die = [int(v) for v in re.findall(r'\d+', re.search(r'^DIEAREA .*$', text, re.M).group())]
die_w, die_h = max(die[0::2]), max(die[1::2])
special = text.split('\nSPECIALNETS', 1)[1].split('END SPECIALNETS', 1)[0]
# Straps: 10 um shapes that cross the core boundary, from the pad ring rail to the core grid.
straps = {}
for net in ('VDD', 'VSS'):
    rec = re.search(r'(?ms)^ - %s\b.*?(?=^ - |\Z)' % net, special).group()
    straps[net] = []
    for m in re.finditer(r'(Metal\d) 10000 \+ SHAPE STRIPE \( (\d+) (\d+) \) \( (\d+|\*) (\d+|\*) \)', rec):
        layer, x0, y0, x1, y1 = m.groups()
        x0, y0 = int(x0), int(y0)
        x1 = x0 if x1 == '*' else int(x1)
        y1 = y0 if y1 == '*' else int(y1)
        # The outer end, the one at the pad ring, moved 2 um along the strap so the source sits inside the shape.
        ends = [(x0, y0), (x1, y1)]
        outer = min(ends, key=lambda p: min(p[0], p[1], die_w - p[0], die_h - p[1]))
        inner = ends[1] if outer == ends[0] else ends[0]
        step = [2000 * ((i > o) - (i < o)) for i, o in zip(inner, outer)]
        straps[net].append((layer, (outer[0] + step[0]) / 1000, (outer[1] + step[1]) / 1000))
print('STRAPS', {k: len(v) for k, v in straps.items()})
# Points in um next to the core supply pads u_pvdd0, u_pvdd1, u_pvss0 and u_pvss1 of IO_RING in run_cfg.tcl. Each
# picks the strap nearest that pad. Change them if the pad ring changes.
pads = {'VDD': [(372.0, 169.0), (1072.0, 1220.0)], 'VSS': [(322.0, 170.0), (1174.0, 322.0)]}
cases = {}
for net in ('VDD', 'VSS'):
    picked = [min(straps[net], key=lambda s: abs(s[1] - px) + abs(s[2] - py)) for px, py in pads[net]]
    cases.setdefault('pads', []).extend((net,) + s for s in picked)
    cases.setdefault('straps', []).extend((net,) + s for s in straps[net])
# Controls and activity on the pessimistic case. emcontrol: every EM limit cut 1000 times, so EM must report
# violations. defect: all but the first VDD Metal5 mesh stripe removed, so the droop must rise.
for k in ('saif', 'emcontrol', 'defect'):
    cases[k] = cases['pads']

# The SRAM LEF from ihp/sram_lef names the supply pins VDD, VDDARRAY and VSS as the DEF does. The PDK's own LEF
# names them VDD!, VDDARRAY! and VSS!, and RedHawk then drops the SRAM current. Libraries: typ, at 1.2 V.
base = {
    'top': 'flash_chip',
    'vdd': 1.2,
    'clock_port': setting('CLK_PORT'),
    'period_ns': float(setting('PERIOD_NS')),
    'map': str(I / 'tech.map'),
    'units': 1000,
    'lefs': [str(lib / 'sg13g2_stdcell/lef/sg13g2_tech.lef'), str(lib / 'sg13g2_stdcell/lef/sg13g2_stdcell.lef'),
             str(lib / 'sg13g2_io/lef/sg13g2_io.lef'), str(Path.home() / 'flash/ihp/sram_lef/RM_IHPSG13_1P_1024x32_c2_bm_bist.lef')],
    'libs': [str(lib / 'sg13g2_stdcell/lib/sg13g2_stdcell_typ_1p20V_25C.lib'), str(lib / 'sg13g2_io/lib/sg13g2_io_typ_1p2V_3p3V_25C.lib'),
             str(lib / 'sg13g2_sram/lib/RM_IHPSG13_1P_1024x32_c2_bm_bist_typ_1p20V_25C.lib')],
    'itf': str(W / 'ihp_em.tech'),
    'em_limits': str(I / 'ihp_published_dc.em'),
}
limits = [l.split() for l in (I / 'ihp_published_dc.em').read_text().splitlines() if l.strip() and not l.startswith('#')]
(W / 'em_limits.rhtech_em').write_text(''.join('%s %s\n' % (n, v) for n, v in limits))
(W / 'em_control.rhtech_em').write_text(''.join('%s %g\n' % (n, float(v) / 1000) for n, v in limits))
strategy = {'pads': 'One ideal source per supply pad, on the strap at or next to it; pad ring rail carries nothing. Pessimistic bound.',
            'straps': 'One ideal source on every pad-ring strap; pad ring rail ideal. Optimistic bound.',
            'saif': 'pads case with switching activity from a gate-level SAIF of the t_work program',
            'emcontrol': 'Control: pads case with every EM limit cut 1000 times.',
            'defect': 'Control: pads case with all but the first VDD Metal5 mesh stripe removed.'}
for key, sources in cases.items():
    k = W / key
    if k.exists():
        shutil.rmtree(k)
    k.mkdir(parents=True)
    shutil.copy2(src, k / 'baseline.def')
    c = dict(base)
    c['run'] = str(run)
    c['def'] = str(k / 'baseline.def')
    c['source_def_sha256'] = hashlib.sha256(src.read_bytes()).hexdigest()
    c['sources'] = [{'net': n, 'layer': l, 'x': x, 'y': y} for n, l, x, y in sources]
    c['source_strategy'] = strategy[key]
    if key == 'saif':
        shutil.copy2(saif, k / 'activity.saif')
        c['saif'] = str(k / 'activity.saif')
    if key == 'emcontrol':
        c['itf'] = str(W / 'ihp_control_em.tech')
    if key == 'defect':
        rec = re.search(r'(?ms)^ - VDD\s.*?(?=\n - |\Z)', special).group()
        lines = rec.splitlines(True)
        idx = [i for i, l in enumerate(lines) if re.search(r'NEW Metal5 \d+ \+ SHAPE STRIPE', l)]
        assert len(idx) > 2, len(idx)
        (k / 'baseline.def').write_text(text.replace(rec, ''.join(l for i, l in enumerate(lines) if i not in set(idx[1:])), 1))
        c['defect_removed_stripes'] = len(idx) - 1
    (k / 'config.json').write_text(json.dumps(c, indent=2))
    (k / 'sources.ploc').write_text(''.join(f'IR_{n}_{i} {x} {y} {l} {n}\n' for i, (n, l, x, y) in enumerate(sources)))
    print(key, len(sources), 'sources')
