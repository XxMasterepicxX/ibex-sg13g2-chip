#!/usr/bin/env python3
"""One pass/fail verdict per signoff check, each backed by the line it came from.

A check with no evidence file is MISSING, never PASS.
usage: check.py <run_dir>
"""
import glob
import os
import re
import sys
import xml.etree.ElementTree as ET


import hashlib
import json
import subprocess
import shutil
import time
from pathlib import Path
import hashlib
import json
import math
import re
import subprocess
from collections import Counter
from pathlib import Path


def sha256(path):
    result = hashlib.sha256()
    with Path(path).open('rb') as stream:
        for block in iter(lambda: stream.read(1048576), b''):
            result.update(block)
    return result.hexdigest()


def bound_file(path, expected):
    if not expected or sha256(path) != expected:
        raise ValueError('Stale or unbound evidence: ' + str(path))


def markers(path):
    rule, details, header, first = None, False, False, False
    pattern = re.compile(r'^\S+\s+\(\s*([-\d.]+),\s*([-\d.]+)\)\s+\(\s*([-\d.]+),\s*([-\d.]+)\)')
    for line in Path(path).open():
        if 'ERROR DETAILS' in line:
            details = True
        if not details:
            continue
        if line.startswith('-----'):
            header = not header
            first = header
            continue
        if header:
            if first and line.strip():
                rule = line.split()[0].rstrip(':')
                first = False
            continue
        match = pattern.match(line)
        if match and rule:
            box = tuple(map(float, match.groups()))
            if not all(math.isfinite(v) for v in box) or box[0] > box[2] or box[1] > box[3]:
                raise ValueError('Invalid marker geometry')
            yield rule, box


def instance_box(def_file, instance, cell, source_box):
    text = Path(def_file).read_text()
    units = re.search(r'UNITS DISTANCE MICRONS (\d+)\s*;', text)
    section = re.search(r'\bCOMPONENTS\s+\d+\s*;(.*?)END COMPONENTS', text, re.S)
    if not units or not section:
        raise ValueError('Missing DEF component geometry')
    entries = re.findall(r'^\s*-\s+' + re.escape(instance) + r'\s+' + re.escape(cell) + r'\s+(.*?);', section.group(1), re.M | re.S)
    if len(entries) != 1:
        raise ValueError('Instance is missing or ambiguous: ' + instance)
    placed = re.search(r'\+\s+(?:FIXED|PLACED)\s+\(\s*(-?\d+)\s+(-?\d+)\s*\)\s+(\w+)', entries[0])
    if not placed:
        raise ValueError('Instance lacks fixed placement')
    x, y = [int(v) / int(units.group(1)) for v in placed.groups()[:2]]
    transforms = {'N': lambda a,b:(a,b), 'S': lambda a,b:(-a,-b),
                  'W': lambda a,b:(-b,a), 'E': lambda a,b:(b,-a),
                  'FN': lambda a,b:(-a,b), 'FS': lambda a,b:(a,-b),
                  'FW': lambda a,b:(-b,-a), 'FE': lambda a,b:(b,a)}
    transform = transforms.get(placed.group(3))
    if not transform:
        raise ValueError('Unsupported DEF orientation')
    points = [transform(a,b) for a in [source_box[0],source_box[2]] for b in [source_box[1],source_box[3]]]
    # DEF placement is the lower-left of the oriented cell boundary.
    width = max(a for a,b in points) - min(a for a,b in points)
    height = max(b for a,b in points) - min(b for a,b in points)
    return [x, y, x + width, y + height]


def source_box(path, cell):
    python = Path.home() / 'flash/tools/pyenv/bin/python'
    script = 'import gdstk,json,sys; l=gdstk.read_gds(sys.argv[1],unit=1e-6); c=[c for c in l.cells if c.name==sys.argv[2]]; assert len(c)==1; b=c[0].bounding_box(); print(json.dumps([*b[0],*b[1]]))'
    return json.loads(subprocess.check_output([str(python), '-c', script, str(path), cell], universal_newlines=True))


def region_waiver(run, report, total, contract_path, geometry_reader=source_box):
    contract = json.loads(Path(contract_path).read_text())
    if not contract.get('reviewed_by') or not contract.get('reviewed_on') or not contract.get('reason'):
        raise ValueError('Region waiver has no review or reason')
    design = contract['design']
    final = run / ('chip/chip_filled.gds' if (run / 'chip').is_dir() else 'out/' + design + '.gds')
    bound_file(final, contract['gds_sha256'])
    bound_file(report, contract['marker_report_sha256'])
    def_file = run / ('out/' + design + '.def')
    bound_file(def_file, contract['def_sha256'])
    summary = Path(report).with_suffix('.RESULTS')
    bound_file(summary, contract['summary_sha256'])
    waivers = contract['waivers']
    if not waivers or len({(w['instance'], w['rule']) for w in waivers}) != len(waivers):
        raise ValueError('Missing or repeated instance/rule waivers')
    cache = {}
    for waiver in waivers:
        proof = Path(waiver['proof'])
        source = Path(waiver['source_gds'])
        bound_file(proof, waiver['proof_sha256'])
        bound_file(source, waiver['source_gds_sha256'])
        text = proof.read_text()
        called = re.search(r'Called as:.*? -i (\S+).*? -c (\S+)', text)
        if not called or Path(called.group(1)).resolve() != source.resolve() or called.group(2) != waiver['source_cell']:
            raise ValueError('Standalone proof did not check the source cell')
        skipped = re.search(r'(\d+) rules? NOT EXECUTED', text)
        counts = re.findall(r'^' + re.escape(waiver['rule']) + r'(?:[^\n]*?)?\s+v\s*=\s*(\d+)\s*$', text, re.M)
        count = int(counts[0]) if len(counts) == 1 else None
        if not skipped or int(skipped.group(1)) or count is None or count != waiver['expected_markers'] or count <= 0:
            raise ValueError('Incomplete standalone vendor-rule proof')
        key = (str(source), waiver['source_cell'])
        if key not in cache:
            cache[key] = geometry_reader(source, waiver['source_cell'])
        actual = instance_box(def_file, waiver['instance'], waiver['source_cell'], cache[key])
        proposed = waiver['region_um']
        if len(proposed) != 4 or any(not math.isfinite(v) or abs(v-a) > 1e-6 for v,a in zip(proposed,actual)):
            raise ValueError('Region differs from the exact placed vendor-cell boundary')
    contained, outside, raw = Counter(), Counter(), 0
    for rule, box in markers(report):
        raw += 1
        matches = [w for w in waivers if w['rule'] == rule and box[0] >= w['region_um'][0]-1e-6 and box[1] >= w['region_um'][1]-1e-6 and box[2] <= w['region_um'][2]+1e-6 and box[3] <= w['region_um'][3]+1e-6]
        if len(matches) == 1:
            contained[(matches[0]['instance'], matches[0]['rule'])] += 1
        else:
            outside[rule] += 1
    if raw != total or raw != contract['raw_markers']:
        raise ValueError('Marker parser did not account for every reported violation')
    if any(contained[(w['instance'], w['rule'])] != w['expected_markers'] for w in waivers):
        raise ValueError('Region marker count differs from standalone defect: ' + str([(w['instance'], w['rule'], contained[(w['instance'], w['rule'])], w['expected_markers']) for w in waivers if contained[(w['instance'], w['rule'])] != w['expected_markers']]))
    return {'raw': raw, 'waived': sum(contained.values()), 'remaining': sum(outside.values()),
            'contained': {instance + ':' + rule: count for (instance, rule), count in contained.items()},
            'outside': dict(outside)}


def atpg_check(run):
    directory = run / 'signoff/atpg'
    contract = json.loads((directory / 'evidence.json').read_text())
    if not all(contract.get(k) for k in ['reviewed_by','reviewed_on','scope']):
        raise ValueError('ATPG scope and coverage threshold require review')
    minimum = contract['minimum_test_coverage_percent']
    if not isinstance(minimum, (int,float)) or not math.isfinite(minimum) or not 0 < minimum <= 100:
        raise ValueError('Invalid coverage acceptance threshold')
    required = ['summary.rpt','drc_rules.rpt','tmax.log','parallel.log','fullserial.log','input.v','input.gds','input.spf']
    for name in required:
        bound_file(directory / name, contract['artifact_sha256'][name])
    design = contract['design']
    for local, current in [('input.v', run / ('out/' + design + '.v')),
                           ('input.gds', run / ('chip/chip_filled.gds' if (run / 'chip').is_dir() else 'out/' + design + '.gds'))]:
        if sha256(directory / local) != sha256(current):
            raise ValueError('ATPG input differs from current final ' + local)
    summary = (directory / 'summary.rpt').read_text()
    classes = re.findall(r'^\s*(?:Detected|Possibly detected|Undetectable|ATPG untestable|Not detected)\s+(DT|PT|UD|AU|ND)\s+(\d+)\s*$', summary, re.M)
    faults = {code:int(count) for code,count in classes}
    total = re.findall(r'^\s*total faults\s+(\d+)\s*$', summary, re.M)
    coverage = re.findall(r'^\s*test coverage\s+([\d.]+)%', summary, re.M)
    patterns = re.findall(r'^\s*#internal patterns\s+(\d+)\s*$', summary, re.M)
    if len(classes) != 5 or set(faults) != {'DT','PT','UD','AU','ND'} or len(total) != 1 or len(coverage) != 1 or len(patterns) != 1:
        raise ValueError('Incomplete or ambiguous ATPG fault denominator')
    total = int(total[0])
    patterns = int(patterns[0])
    if total != sum(faults.values()) or total-faults['UD'] <= 0 or faults['DT'] <= 0 or patterns <= 0:
        raise ValueError('ATPG fault counts do not reconcile')
    measured = float(coverage[0])
    calculated = 100*(faults['DT'] + 0.5*faults['PT'])/(total-faults['UD'])
    if abs(measured-calculated) > 0.02 or measured < minimum:
        raise ValueError('ATPG coverage fails denominator or threshold check')
    drc = (directory / 'drc_rules.rpt').read_text()
    rows = re.findall(r'^\s*(\w+)\s+(warning|error|fatal)\s+(\d+)\s+(.+)$', drc, re.M | re.I)
    warnings = {code:int(count) for code,severity,count,description in rows if severity.lower() == 'warning'}
    if not rows or any(int(count) for code,severity,count,description in rows if severity.lower() != 'warning'):
        raise ValueError('ATPG DRC fatal/error rules failed or report is unparsed')
    if warnings != contract.get('reviewed_drc_warnings'):
        raise ValueError('ATPG DRC warning counts differ from reviewed model limitations')
    if not contract.get('drc_warning_reason'):
        raise ValueError('Missing ATPG model limitation explanation')
    log = (directory / 'tmax.log').read_text()
    if contract.get('tool_exit') != 0 or re.search(r'^Error:|^Fatal:', log, re.M):
        raise ValueError('ATPG tool failed')
    for name in ['parallel.log','fullserial.log']:
        log = (directory / name).read_text()
        replay = re.findall(r'XTB: Simulation of (\d+) patterns completed with (\d+) mismatches', log)
        if len(replay) != 1 or tuple(map(int,replay[0])) != (patterns,0) or re.search(r'XTB Error:|Mismatch at', log):
            raise ValueError('Incomplete or mismatching ATPG replay: ' + name)
    return {'patterns':patterns, 'test_coverage_percent':measured, 'total_faults':total,
            'fault_classes':faults, 'scope':contract['scope']}


def digest(path):
    h = hashlib.md5()
    with open(path, 'rb') as f:
        for block in iter(lambda: f.read(1048576), b''):
            h.update(block)
    return h.hexdigest()


DEPENDENCY_MANIFEST = 'signoff/provenance/dependencies.json'


def _expanded_path(value, replacements):
    value = value.strip().strip('{}"')
    for name, replacement in replacements.items():
        value = value.replace(name, str(replacement))
    return Path(value).expanduser()


def dependency_files(run):
    """Return the static inputs that every signoff launch must freeze."""
    cfg = cfg_values(run)
    root = Path.home() / 'flash'
    pdk = cfg.get('PDK', '')
    pdk_cfg = root / 'pdk_cfg' / pdk
    files = set()
    required_paths = [
        root / 'flow/constraints.tcl', root / 'flow/pt_signoff.tcl',
        root / 'flow/pp_power.tcl', root / 'flow/fm_verify.tcl',
        root / 'flow/tools.sh', root / 'flow/v2cdl.py', root / 'flow/lvs_blackbox.py', pdk_cfg / 'pdk.sh', pdk_cfg / 'pdk.tcl', run / 'run_cfg.tcl',
    ]
    files.update(path.resolve() for path in required_paths)
    for path in [pdk_cfg / 'drc_waivers.txt', pdk_cfg / 'pg_drc_waivers.txt', pdk_cfg / 'chip_only_rules.txt']:
        if path.is_file():
            files.add(path.resolve())
    for relative in ('fc_flow.tcl', 'session.tcl', 'constraints.tcl'):
        path = run / 'flow_snapshot' / relative
        if path.is_file():
            files.add(path.resolve())
    for relative in ('check.py', 'make_pt_policy.py', 'constraints.tcl', 'pt_signoff.tcl', 'pp_power.tcl', 'fm_verify.tcl', 'tools.sh'):
        path = run / 'signoff/w1_flow' / relative
        if path.is_file():
            files.add(path.resolve())
    policy = run / 'signoff/executed_cfg.tcl'
    if policy.is_file():
        files.add(policy.resolve())
    policy = run / 'signoff/pt_policy.tcl'
    if policy.is_file():
        files.add(policy.resolve())

    replacements = {
        '$env(HOME)': Path.home(), '$HOME': Path.home(),
        '$PDK_ROOT': '', '$PDK_WORK': str(root / pdk), '$PDK_CFG': str(pdk_cfg),
    }
    pdk_text = (pdk_cfg / 'pdk.tcl').read_text(errors='replace') if (pdk_cfg / 'pdk.tcl').is_file() else ''
    scalar = {}
    for line in pdk_text.splitlines():
        match = re.match(r'\s*set\s+(PDK_ROOT|PDK_WORK|PDK_CFG|DB_DIR|NXTGRD|RC_MAP|TECH_LEF|CELL_LEF|ICV_RUNSET)\s+(.+?)\s*$', line)
        if match:
            scalar[match.group(1)] = match.group(2)
    replacements.update({
        '$PDK_ROOT': _expanded_path(scalar.get('PDK_ROOT', str(pdk_cfg)), replacements),
        '$PDK_WORK': _expanded_path(scalar.get('PDK_WORK', str(root / pdk)), replacements),
        '$PDK_CFG': _expanded_path(scalar.get('PDK_CFG', str(pdk_cfg)), replacements),
    })
    for key in ('DB_DIR', 'NXTGRD', 'RC_MAP', 'TECH_LEF', 'CELL_LEF', 'ICV_RUNSET'):
        value = scalar.get(key)
        if not value:
            continue
        path = _expanded_path(value, replacements)
        if path.is_dir() and key == 'DB_DIR':
            continue
        if path.is_file():
            files.add(path.resolve())
        elif path.is_dir():
            files.update(p.resolve() for p in path.glob('*.db') if p.is_file())
        else:
            files.add(path.resolve())
    db_dir = _expanded_path(scalar.get('DB_DIR', ''), replacements)
    if db_dir.is_dir():
        files.update(p.resolve() for p in db_dir.glob('*.db') if p.is_file())
        corners = re.search(r'(?ms)^\s*set\s+CORNERS\s+\{(.*?)\n\s*\}', pdk_text)
        if corners:
            tokens = corners.group(1).split()
            for index in range(0, len(tokens) - 3, 4):
                lib = db_dir / (tokens[index + 3] + '.db')
                if lib.is_file():
                    files.add(lib.resolve())
    files.update(p.resolve() for p in db_dir.glob('*.db') if p.is_file())
    nominal_grid = _expanded_path(scalar['NXTGRD'], replacements) if scalar.get('NXTGRD') else None
    if nominal_grid is not None:
        files.add(nominal_grid.resolve())
        for variant in ('Cmax', 'Cmin', 'cmax', 'cmin'):
            candidate = Path(str(nominal_grid).replace('nominal', variant))
            if candidate.is_file():
                files.add(candidate.resolve())
    work = replacements['$PDK_WORK']
    if isinstance(work, Path):
        icv = work / 'icv'
        if icv.is_dir():
            files.update(p.resolve() for p in icv.glob('*rules*') if p.is_file())
    for key, value in os.environ.items():
        if any(word in key.upper() for word in ('DECK', 'RUNSET', 'GRID', 'LIB')):
            for token in value.split():
                candidate = _expanded_path(token, replacements)
                if candidate.is_file():
                    files.add(candidate.resolve())
                elif candidate.is_dir():
                    files.update(p.resolve() for p in candidate.glob('*.db') if p.is_file())
    for name in ('SDC_EXTRA', 'RTL_FILES', 'EXTRA_SVF', 'UPF_FILE', 'FM_REF_NETLIST'):
        for token in cfg.get(name, '').split():
            path = _expanded_path(token, replacements)
            if path.is_file():
                files.add(path.resolve())
    return sorted(files, key=str)


def consumer_spef(run, name):
    if name.startswith(('pt_', 'noise_')):
        corner = name.split('_', 1)[1].removesuffix('_shift')
    elif name == 'primepower':
        corner = 'typ'
    else:
        return None
    rc = {'slow': 'cmax', 'typ': 'nominal', 'fast': 'cmin'}.get(corner)
    if not rc:
        return None
    design = cfg_values(run)['DESIGN']
    directory = 'starrc' if rc == 'nominal' else 'starrc_' + rc
    return run / f'signoff/{directory}/{design}.spef'


def dependency_manifest(run):
    path = run / DEPENDENCY_MANIFEST
    if not path.is_file():
        return None
    value = json.loads(path.read_text())
    if value.get('version') != 1 or not isinstance(value.get('files'), dict):
        raise ValueError('Invalid launch dependency manifest')
    return value


def record_dependency_manifest(run):
    path = run / DEPENDENCY_MANIFEST
    files = {str(p): (digest(p) if p.is_file() else None) for p in dependency_files(run)}
    existing = dependency_manifest(run)
    if existing is not None and existing['files'] == files:
        print('FLASH_DEPENDENCY_MANIFEST_UNCHANGED')
        return existing
    value = {'version': 1, 'generated': time.time(), 'files': files}
    atomic_json(path, value)
    print('FLASH_DEPENDENCY_MANIFEST_UPDATED')
    return value


def launch_inputs(run, name):
    result = {}
    if name.startswith('starrc'):
        command = run / ('signoff/' + name + '/star.cmd')
        result['extraction_command'] = digest(command) if command.is_file() else None
    if name == 'lvs':
        cdl = run / ('signoff/lvs/' + cfg_values(run)['DESIGN'] + '.cdl')
        result['lvs_schematic'] = digest(cdl) if cdl.is_file() else None
    if name.startswith(('pt_', 'noise_')) or name == 'primepower':
        spef = consumer_spef(run, name)
        consumer = name.split('_', 1)[1].removesuffix('_shift') if name.startswith(('pt_', 'noise_')) else 'typ'
        result['consumer_spef:' + consumer] = digest(spef) if spef and spef.is_file() else None
        rc = consumer
        rc = {'slow': 'cmax', 'typ': 'nominal', 'fast': 'cmin'}.get(rc, rc)
        producer = run / ('signoff/provenance/starrc.json' if rc == 'nominal' else f'signoff/provenance/starrc_{rc}.json')
        result['extraction_producer:' + consumer] = digest(producer) if producer.is_file() else None
        policy = run / 'signoff/pt_policy.tcl'
        result['analysis_policy_script:' + consumer] = digest(policy) if policy.is_file() else None
        design = cfg_values(run)['DESIGN']
        netlist = run / f'out/{design}.v'
        result['analysis_netlist:' + consumer] = digest(netlist) if netlist.is_file() else None
    if name == 'formality':
        generated = run / 'signoff/formality/rtl_sv2v.v'
        if generated.is_file():
            result['formality_generated_rtl'] = digest(generated)
        cfg = cfg_values(run)
        ref = cfg.get('FM_REF_NETLIST')
        if ref:
            path = Path(ref).expanduser()
            result['formality_reference_netlist'] = digest(path) if path.is_file() else None
    if name == 'primepower':
        cfg = cfg_values(run)
        for env_name in ('SAIF', 'VCD'):
            path = os.environ.get(env_name)
            if path:
                candidate = Path(path).expanduser()
                result['power_' + env_name] = digest(candidate) if candidate.is_file() else None
        result['power_activity_policy'] = digest(run / 'signoff/w1_flow/pp_power.tcl') if (run / 'signoff/w1_flow/pp_power.tcl').is_file() else None
    return result

def cfg_values(run):
    names = ['DESIGN', 'PDK', 'SCANDEF', 'DFT_SETUP', 'SDC_EXTRA', 'RTL_FILES', 'EXTRA_SVF',
             'UPF_FILE', 'FM_DONT_VERIFY', 'FM_REF_NETLIST']
    script = 'source {' + str(run / 'run_cfg.tcl') + '}\n'
    script += '\n'.join('if {[info exists '+n+']} {puts "'+n+'=$'+n+'"}' for n in names)
    return dict(line.split('=', 1) for line in subprocess.check_output(['tclsh'], input=script, universal_newlines=True).splitlines() if '=' in line)

def inputs(run, design):
    final = 'chip/chip_filled.gds' if (run / 'chip').is_dir() else f'out/{design}.gds'
    paths = [final, f'out/{design}.gds', f'out/{design}.v', f'out/{design}.pg.v', f'out/{design}.def', 'run_cfg.tcl']
    result = {p: digest(run / p) if (run / p).is_file() else None for p in sorted(set(paths))}
    extra = cfg_values(run).get('SDC_EXTRA')
    if extra:
        result['sdc_extra:' + extra] = digest(extra) if Path(extra).is_file() else None
    for index, stage in enumerate(['', '.setup', '.synth', '.floorplan', '.pg', '.place', '.cts', '.route', '.ladder', '.final']):
        path = run / ('out/' + design + stage + '.svf')
        if path.is_file():
            result['ordered_svf:' + str(index) + ':' + str(path.relative_to(run))] = digest(path)
    for name in ['RTL_FILES', 'EXTRA_SVF', 'UPF_FILE']:
        for path in cfg_values(run).get(name, '').split():
            path = path.strip('{}')
            result[name + ':' + path] = digest(path) if Path(path).is_file() else None
    return result

POLICY_FILES = {'signoff/formality_coverage.json', 'signoff/electrical_waivers.json', 'signoff/timing_waivers.json'}

def check_inputs(run, design, name):
    result = inputs(run, design)
    if not name.startswith('fc_'):
        dependency_path = run / DEPENDENCY_MANIFEST
        dependency = dependency_manifest(run)
        result['launch_dependency_manifest'] = digest(dependency_path) if dependency else None
        if dependency:
            for path in dependency['files']:
                candidate = Path(path)
                origin = recorded_origin(run, name)
                try:
                    candidate = run / candidate.relative_to(origin)
                except ValueError:
                    pass
                result['launch_dependency:' + path] = digest(candidate) if candidate.is_file() else None
    result.update(launch_inputs(run, name))
    policies = []
    if name == 'formality':
        policies = ['signoff/formality_coverage.json']
    elif name.startswith(('pt_', 'noise_')):
        policies = ['signoff/electrical_waivers.json', 'signoff/timing_waivers.json']
    elif name == 'drc':
        policies = ['signoff/drc_waiver_review.json']
    for policy in policies:
        path = run / policy
        if path.is_file():
            result[policy] = digest(path)
    return result

def relevant_recorded_inputs(values, expected):
    return {k:v for k,v in values.items() if k not in POLICY_FILES or k in expected}

def atomic_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + '.tmp')
    tmp.write_text(json.dumps(value, indent=2) + '\n')
    tmp.replace(path)

def manifest_for(run):
    cfg = cfg_values(run)
    corners = os.environ.get('CORNER_NAMES', 'slow typ fast').split()
    modes = ['func', 'shift'] if cfg.get('SCANDEF') or cfg.get('DFT_SETUP') else ['func']
    required = {
      'fc_flow': ['fc_*.log'], 'fc_route_drc': ['rpt/check_routes.rpt'],
      'fc_antenna': ['rpt/check_antenna.rpt'], 'fc_check_lvs': ['rpt/check_lvs.rpt'],
      'fc_pg_drc': ['rpt/pg_drc_final.rpt'], 'fc_pg_connectivity': ['rpt/pg_conn_final.rpt'],
      'starrc': ['signoff/starrc/starrc.log', 'signoff/starrc/star.cmd', 'signoff/starrc/*.spef'],
      'formality': ['signoff/formality/fm.log', 'signoff/formality/status.rpt', 'signoff/formality/unmatched.rpt', 'signoff/formality/dont_verify.rpt'],
      'primepower': ['signoff/primepower/pp.log'],
      'drc': ['signoff/drc.log', 'signoff/drc/*.RESULTS' if cfg['PDK'] in {'saed32', 'saed90'} else 'signoff/drc/*.lyrdb'],
      'lvs': ['signoff/lvs.log', 'signoff/lvs/v2cdl.log'] + (['signoff/lvs/run/*.RESULTS'] if cfg['PDK'] in {'saed32', 'saed90'} else [])}
    if cfg.get('SCANDEF') or cfg.get('DFT_SETUP'):
        required['atpg'] = ['signoff/atpg/' + x for x in ['evidence.json','summary.rpt','drc_rules.rpt','tmax.log','parallel.log','fullserial.log','input.v','input.gds','input.spf']]
    for corner in corners:
        for mode in modes:
            c = corner + ('_shift' if mode == 'shift' else '')
            required['pt_' + c] = [f'signoff/pt_{c}/{x}' for x in ['pt.log', 'violators.rpt', 'check_timing.rpt', 'parasitics_command.log', 'analysis_coverage.rpt', 'disabled_timing.rpt']]
            required['noise_' + c] = [f'signoff/pt_{c}/pt.log', f'signoff/pt_{c}/noise_violators.rpt']
        if corner in ('slow', 'fast'):
            rc = 'cmax' if corner == 'slow' else 'cmin'
            required['starrc_' + rc] = [f'signoff/starrc_{rc}/starrc.log', f'signoff/starrc_{rc}/star.cmd', f'signoff/starrc_{rc}/*.spef']
    if (run / 'chip').is_dir():
        required['chip_drc'] = ['chip/drc.log', 'chip/drc/*.RESULTS' if cfg['PDK'] in {'saed32', 'saed90'} else 'chip/drc/*.lyrdb']
        if cfg['PDK'] == 'saed32':
            required['chip_density'] = ['chip/density/*.RESULTS']
        else:
            required['chip_precheck'] = ['chip/precheck.log', 'chip/precheck/*.lyrdb']
        required['chip_lvs'] = ['signoff/lvs_chip/lvs.log']
    integration_scope = ({'block_density_fill': 'required_on_filled_chip',
                          'restriction': 'Filled-chip density and fill are mandatory for this chip run.',
                          'reviewed': True} if (run / 'chip').is_dir() else
                         {'block_density_fill': 'deferred_until_filled_chip',
                          'restriction': 'This reusable block is not a filled chip and cannot claim chip density or fill signoff.',
                          'reviewed': True})
    return {'version': 2, 'design': cfg['DESIGN'], 'pdk': cfg['PDK'], 'corners': corners, 'modes': modes,
            'required': required, 'rc_pairing': {'slow': 'cmax', 'fast': 'cmin', 'typ': 'nominal'},
            'ocv': {'early': 0.95, 'late': 1.05, 'scope': 'cell_delay and net_delay'},
            'ocv_basis': 'Educational flat 5 percent sensitivity margin. Not foundry qualified AOCV or POCV.',
            'power_scope': 'Successful finite nonnegative power estimate is required. No IR/EM or accepted power budget is implied.',
            'integration_scope': integration_scope}

def evidence_hashes(run, patterns):
    result = {}
    for pattern in patterns:
        matches = sorted(run.glob(pattern))
        if not matches:
            result[pattern] = None
        for p in matches:
            if p.is_file():
                result[str(p.relative_to(run))] = digest(p)
    return result

def compatible_evidence_manifest(old, proposed):
    corrected = json.loads(json.dumps(old))
    if corrected.get('version') != 2:
        return False
    if 'integration_scope' not in corrected:
        corrected['integration_scope'] = proposed['integration_scope']
    for name, expected in proposed['required'].items():
        if not name.startswith('pt_') or name not in corrected.get('required', {}):
            continue
        added = [p for p in expected if p.endswith(('analysis_coverage.rpt', 'disabled_timing.rpt'))]
        prior = [p for p in expected if p not in added]
        if corrected['required'][name] == prior:
            corrected['required'][name] = expected
    return corrected == proposed


def compatible_atpg_manifest(old, proposed):
    corrected = json.loads(json.dumps(old))
    if 'atpg' in corrected.get('required', {}) or 'atpg' not in proposed['required']:
        return False
    corrected['required']['atpg'] = proposed['required']['atpg']
    return corrected == proposed or compatible_saed90_manifest(corrected, proposed)

def compatible_saed90_manifest(old, proposed):
    if old.get('pdk') != 'saed90':
        return False
    corrected = json.loads(json.dumps(old))
    req = corrected.get('required', {})
    for name in ('drc', 'chip_drc'):
        if name in req:
            req[name] = [x.replace('*.lyrdb', '*.RESULTS') for x in req[name]]
    if 'lvs' in req and 'signoff/lvs/run/*.RESULTS' not in req['lvs']:
        req['lvs'].append('signoff/lvs/run/*.RESULTS')
    return corrected == proposed

def immutable_fc_inputs(run):
    cfg = cfg_values(run)
    values = inputs(run, cfg['DESIGN'])
    values = {k:v for k,v in values.items() if not k.startswith(('out/', 'chip/', 'ordered_svf:'))}
    for name in ('fc_flow.tcl', 'session.tcl', 'constraints.tcl'):
        path = run / 'flow_snapshot' / name
        values['flow_snapshot/' + name] = digest(path) if path.is_file() else None
    return values

def recorded_origin(run, group):
    path = Path(run) / ('signoff/provenance/' + group + '.json')
    if path.is_file():
        return json.loads(path.read_text()).get('origin_run', run)
    return run


if len(sys.argv) > 1 and sys.argv[1].startswith('--'):
    command, run = sys.argv[1], Path(sys.argv[2]).resolve()
    path = run / 'signoff/manifest.json'
    if command == '--prepare':
        proposed = manifest_for(run)
        if path.exists() and json.loads(path.read_text()) != proposed:
            old = json.loads(path.read_text())
            if old.get('version') == 1 or compatible_evidence_manifest(old, proposed) or compatible_saed90_manifest(old, proposed) or compatible_atpg_manifest(old, proposed):
                backup = path.with_name('manifest.pre_w1i.json')
                if not backup.exists():
                    shutil.copy2(path, backup)
                print('FLASH_MANIFEST_MIGRATED checker schema or backend requirements; prior matrix archived')
            else:
                raise SystemExit('Manifest differs from design requirements. Review and archive it before replacing.')
        atomic_json(path, proposed)
    elif command == '--record-deps':
        record_dependency_manifest(run)
    elif command == '--begin':
        manifest = json.loads(path.read_text())
        begin_inputs = check_inputs(run, manifest['design'], sys.argv[3])
        if any(value is None for value in begin_inputs.values()):
            raise SystemExit('Required launch dependency is missing for ' + sys.argv[3])
        atomic_json(run / ('signoff/provenance/' + sys.argv[3] + '.begin.json'),
                    {'inputs': begin_inputs, 'started': time.time()})
    elif command == '--stamp':
        manifest = json.loads(path.read_text())
        group = sys.argv[3]
        names = [x for x in sys.argv[4].split(',') if x in manifest['required']]
        begin = json.loads((run / ('signoff/provenance/' + group + '.begin.json')).read_text())
        current = check_inputs(run, manifest['design'], group)
        if relevant_recorded_inputs(begin['inputs'], current) != current:
            raise SystemExit('Inputs changed during ' + group)
        for name in names:
            value = {'schema': 2, 'origin_run': str(run), 'inputs': current,
                     'evidence': evidence_hashes(run, manifest['required'][name]),
                     'started': begin['started'], 'finished': time.time(), 'exit': int(sys.argv[5])}
            if group.startswith('starrc'):
                spef = sorted((run / 'signoff' / group).glob('*.spef'))
                if len(spef) != 1:
                    raise SystemExit('StarRC producer must emit exactly one SPEF for ' + group)
                value['producer'] = {'tool': 'StarXtract', 'output': str(spef[0].relative_to(run)),
                                     'sha256': sha256(spef[0]), 'exit': int(sys.argv[5])}
            atomic_json(run / ('signoff/provenance/' + name + '.json'), value)
    elif command == '--begin-fc':
        manifest = manifest_for(run)
        log = (run / sys.argv[3]).resolve()
        if log.parent != run or not log.name.startswith('fc_') or log.suffix != '.log':
            raise SystemExit('FC log must be a named run-local fc_*.log')
        atomic_json(run / 'signoff/provenance/fc_launch.json',
                    {'immutable_inputs': immutable_fc_inputs(run), 'started': time.time(),
                     'log': log.name, 'start_at': os.environ.get('START_AT', 'setup')})
    elif command == '--record-fc':
        manifest = json.loads(path.read_text())
        launch_file = run / 'signoff/provenance/fc_launch.json'
        launch = json.loads(launch_file.read_text()) if launch_file.is_file() else None
        log_path = run / (sys.argv[3] if len(sys.argv) > 3 else (launch['log'] if launch else 'fc_final.log'))
        if launch:
            if launch['immutable_inputs'] != immutable_fc_inputs(run):
                raise SystemExit('Immutable FC inputs changed during the tool run')
            if launch['log'] != log_path.name:
                raise SystemExit('FC result log does not match the recorded launch')
        log = log_path.read_text()
        errors = [x for x in log.splitlines() if x.startswith('Error:') and 'script has expired' not in x]
        if 'FLASH_FLOW_DONE' not in log or 'FC_EXIT=0' not in log or errors:
            raise SystemExit('Cannot certify unsuccessful final FC stage')
        identity = inputs(run, manifest['design'])
        if (run / 'chip').is_dir():
            identity.pop('chip/chip_filled.gds', None)
        names = [x for x in manifest['required'] if x.startswith('fc_')]
        atomic_json(run / 'signoff/provenance/fc_producer.json',
                    {'inputs': identity, 'evidence': {x:evidence_hashes(run,manifest['required'][x]) for x in names},
                     'recorded':time.time(), 'launch':launch, 'scope':'FC judges the routed block. Final fill is judged by chip checks.'})
    elif command == '--bind-fc':
        manifest = json.loads(path.read_text())
        producer = json.loads((run / 'signoff/provenance/fc_producer.json').read_text())
        current = inputs(run, manifest['design'])
        block = dict(current)
        block.pop('chip/chip_filled.gds', None)
        if relevant_recorded_inputs(producer['inputs'], block) != block:
            raise SystemExit('Routed design changed after producer evidence was captured')
        for name, ev in producer['evidence'].items():
            if ev != evidence_hashes(run, manifest['required'][name]):
                raise SystemExit('FC report changed after producer capture')
            atomic_json(run / ('signoff/provenance/' + name + '.json'),
                        {'inputs':current,'evidence':ev,'started':producer['recorded'], 'finished':time.time(),
                         'exit':0,'judged_gds':f"out/{manifest['design']}.gds",'scope':producer['scope']})
    else:
        raise SystemExit('Unknown command ' + command)
    raise SystemExit(0)

run = os.path.abspath(sys.argv[1])
rows = []


def read(path):
    return open(path, errors="replace").read() if os.path.exists(path) else None


def add(name, ok, evidence):
    rows.append((name, "MISSING" if ok is None else ("PASS" if ok else "FAIL"), evidence))


def last(pattern, text, flags=0):
    found = re.findall(pattern, text or "", flags)
    return found[-1] if found else None


def complete_tool_report(text, kind):
    if not text:
        return False
    required = [rf'^\s*Report\s*:\s*{kind}\s*$', r'^Design\s*:', r'^Version\s*:', r'^Date\s*:']
    if not all(re.search(pattern, text, re.M) for pattern in required):
        return False
    return bool(re.fullmatch(r'\s*\d+\s*', text.rstrip().splitlines()[-1]))


def complete_parasitic_report(text):
    if not text or not re.search(r'^\s*Report\s*:\s*read_parasitics\s+\S+', text, re.M):
        return False, 'missing read_parasitics header'
    if not re.search(r'^\s*Format is SPEF\s*$', text, re.M) or not re.search(r'^\s*\d+ error\(s\)\s*$', text, re.M):
        return False, 'missing SPEF completion or error count'
    if len(re.findall(r'^\s*Report\s*:\s*annotated_parasitics\s*$', text, re.M)) < 2:
        return False, 'missing complete internal and boundary annotation tables'
    sections = re.findall(r'(?ms)^\s*Report\s*:\s*annotated_parasitics\s*$.*?(?=^\s*Report\s*:|\Z)', text)
    table_rows = []
    table_totals = []
    for section in sections[:2]:
        rows = []
        for line in section.splitlines():
            if not re.match(r'^\s*- (?:Pin to pin|Driverless|Loadless) nets\s*\|', line):
                continue
            fields = [x.strip() for x in line.split('|')]
            if len(fields) != 8 or not all(re.fullmatch(r'\d+', field) for field in fields[1:7]):
                return False, 'malformed parasitic annotation row'
            rows.append([int(x) for x in fields[1:7]])
        summary = re.findall(r'^\s*\|\s*(\d+(?:\s*\|\s*\d+){5})\s*\|\s*$', section, re.M)
        if not rows or not summary:
            return False, 'missing parasitic table rows or total'
        totals = [int(x.strip()) for x in summary[-1].split('|')]
        if totals[0] != sum(row[0] for row in rows) or totals[-1] != sum(row[-1] for row in rows):
            return False, 'parasitic table totals do not reconcile'
        table_rows.append(rows)
        table_totals.append(totals)
    if [len(rows) for rows in table_rows] != [6, 2]:
        return False, 'expected six internal and two pin-to-pin annotation rows'
    annotated = last(r'^\s*Annotated nets\s*:\s*(\d+)', text, re.M)
    if annotated is None or int(annotated) <= 0:
        return False, 'missing annotated-net total'
    return True, f'annotated_nets={annotated} rows={sum(len(rows) for rows in table_rows)}'


def analysis_coverage(text):
    if not text or not re.search(r'^\s*Report\s*:\s*analysis_coverage\s*$', text, re.M):
        raise ValueError('missing analysis_coverage tool header')
    summary = re.search(r'^All Checks\s+(\d+)\s+(\d+)\s+\(\s*\d+%\)\s+(\d+)\s+\(\s*\d+%\)\s+(\d+)\s+\(\s*\d+%\)\s*$', text, re.M)
    if not summary:
        raise ValueError('missing analysis coverage totals')
    total, met, violated, untested = map(int, summary.groups())
    if total != met + violated + untested:
        raise ValueError('analysis coverage totals do not reconcile')
    reason_counts = Counter()
    reason_types = Counter()
    signatures = Counter()
    # PrimeTime Y-2026.03 adds a Condition column, such as - or sdf_cond(...), before the status.
    for endpoint, related, clock, check_type, reason in re.findall(r'^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(?:\S+\s+)?untested\s+(\S+)\s*$', text, re.M):
        reason_counts[reason] += 1
        reason_types[f'{check_type}:{reason}'] += 1
        signatures[f'{endpoint}|{related}|{clock}|{check_type}|{reason}'] += 1
    if sum(reason_counts.values()) != untested:
        raise ValueError('analysis coverage untested rows do not reconcile')
    return {'total': total, 'met': met, 'violated': violated, 'untested': untested,
            'reasons': dict(sorted(reason_counts.items())),
            'reason_types': dict(sorted(reason_types.items())),
            'signatures': dict(sorted(signatures.items()))}


def disabled_timing_coverage(text):
    if not text or not re.search(r'^\s*Report\s*:\s*disable_timing\s*$', text, re.M):
        raise ValueError('missing disabled timing report header')
    if not re.search(r'^Cell or Port\s+From\s+To\s+Sense\s+Flag\s+Reason\s*$', text, re.M):
        raise ValueError('missing disabled timing table header')
    rows = []
    for line in text.splitlines():
        fields = line.split()
        if len(fields) >= 6 and fields[4] in set('cCdf lLmpuU'.replace(' ', '')):
            rows.append((fields[0], fields[1], fields[2], fields[3], fields[4]))
    flags = Counter(row[-1] for row in rows)
    signatures = Counter('|'.join(row) for row in rows)
    return {'total': len(rows), 'flags': dict(sorted(flags.items())),
            'signatures': dict(sorted(signatures.items()))}


def reviewed_coverage(run, corner, actual):
    path = run / 'signoff/timing_coverage.json'
    if not path.is_file():
        raise ValueError('missing reviewed timing coverage contract')
    contract = json.loads(path.read_text())
    if contract.get('version') != 1 or not contract.get('reviewed_by') or not contract.get('reviewed_on'):
        raise ValueError('timing coverage contract is not reviewed')
    expected = contract.get('corners', {}).get(corner)
    if not isinstance(expected, dict) or expected != actual:
        raise ValueError('analysis coverage counts or reviewed reasons differ for ' + corner)
    return 'reviewed reasons=' + ','.join(f'{k}:{v}' for k, v in sorted(actual['reasons'].items()))


def lvs_execution(text):
    if not text:
        return None
    run = re.findall(r'(\d+)\s+total rules? were run\.', text, re.I)
    skipped = re.findall(r'(\d+)\s+rules? NOT EXECUTED\.', text, re.I)
    return (int(run[-1]), int(skipped[-1])) if run and skipped else None

def klayout_counts(dbs):
    """Markers per rule in KLayout result databases, split into required and recommended-only."""
    per_rule, recommended = {}, set()
    for db in dbs:
        root = ET.parse(db).getroot()
        # A rule the deck describes as "recommended" (IHP's Pad.d1R, Pad.fR_M3, ...) is guidance, not a
        # requirement: reported, but it does not fail the check.
        for cat in root.iter("category"):
            name = (cat.findtext("name") or "").strip("'\"")
            if "recommended" in (cat.findtext("description") or "").lower():
                recommended.add(name)
        for item in root.iter("item"):
            cat = (item.findtext("category") or "?").strip("'\"")
            per_rule[cat] = per_rule.get(cat, 0) + 1
    required = {k: v for k, v in per_rule.items() if k not in recommended}
    return required, sum(v for k, v in per_rule.items() if k in recommended)



# Fusion Compiler
# A resumed run (START_AT, repair ladder) has one log per session, so errors count across all of them.
logs = sorted(glob.glob(f"{run}/fc_*.log"), key=os.path.getmtime)
fc = "".join(read(p) for p in logs) if logs else None
if fc is None:
    add("fc_flow", None, "no fc_*.log")
else:
    errs = [l for l in fc.splitlines() if l.startswith("Error:") and "script has expired" not in l]
    add("fc_flow", "FLASH_FLOW_DONE" in fc and not errs,
        f"done={'FLASH_FLOW_DONE' in fc} errors={len(errs)}" + (f" first: {errs[0][:110]}" if errs else ""))

cr = read(f"{run}/rpt/check_routes.rpt")
n = last(r"Total number of DRCs\s*=\s*(\d+)", cr)
add("fc_route_drc", None if n is None else int(n) == 0, f"Total number of DRCs = {n}")

# ZRT-311: Zroute skips antenna analysis on any net touching a port without gate data and still
# reports 0, which hid clk_i at ratio 250 of 200 from every run until 2026-09-21.
ant = read(f"{run}/rpt/check_antenna.rpt")
if ant is None:
    add("fc_antenna", None, "no check_antenna.rpt: antenna rules not mapped for this PDK")
else:
    v = (last(r"Total number of antenna violations\s*=\s*(.+)", ant) or "").strip()
    skipped_nets = set(re.findall(r"Skipping antenna analysis for net (\S+?)\.", ant))
    # The one skip that is sound: a net whose only reason is an IO cell's pad pin, the bond-pad side, where there
    # is no gate to protect (chip_v6_noise2: rst_n, sclk, scan_en ... on sg13g2_IOPadIn). Each is named.
    pad_nets = set(re.findall(r"Skipping antenna analysis for net (\S+?)\. The pin pad on cell \S+", ant, re.I))
    other = {n for n in skipped_nets if n not in pad_nets or
             re.search(rf"net {re.escape(n)}\. (?!The pin pad on cell)", ant, re.I)}
    # A ZRT-311 line in any other form still fails.
    if ant.count("ZRT-311") > ant.count("Skipping antenna analysis for net"):
        other.add("unparsed_ZRT-311")
    ptxt = f"; io pad side, no gate: {','.join(sorted(pad_nets - other))}" if pad_nets - other else ""
    add("fc_antenna", v == "0" and not other,
        f"violations={v} nets skipped (ZRT-311)={len(other)}{ptxt}")

lvs_fc = read(f"{run}/rpt/check_lvs.rpt")
if lvs_fc is None:
    add("fc_check_lvs", None, "no check_lvs.rpt")
else:
    counts = re.findall(r"Total number of (short violations|open nets|floating route violations) is (\d+)", lvs_fc)
    bad = [f"{k}={v}" for k, v in counts if int(v) > 0]
    add("fc_check_lvs", bool(counts) and not bad, "; ".join(f"{k}={v}" for k, v in counts)[:160] or "no counts parsed")

pg = read(f"{run}/rpt/pg_drc_final.rpt")
pg_split = last(r"FLASH_PG_DRC outside_io=(\d+) inside_io=(\d+)", read(f"{run}/rpt/pg_drc_final_split.rpt") or "")
if pg is None:
    add("fc_pg_drc", None, "no report")
elif "No errors found." in pg:
    add("fc_pg_drc", True, "No errors found.")
elif pg_split:
    # Errors wholly inside foundry IO cells are judged by the foundry DRC deck on the real GDS.
    out, io = pg_split
    # Error types proven to be library-abstract artifacts are waived by name in pdk_cfg/<pdk>/pg_drc_waivers.txt,
    # "type | reason", and only when every error found is of a waived type.
    types = re.findall(r"^\s+(\d+) (\S.*?)\s*$", pg.split("Total number of errors found", 1)[-1].split("----", 1)[0], re.M)
    reported_total = last(r"Total number of errors found\s*[:=]?\s*(\d+)", pg)
    typed_total = sum(int(count) for count, _ in types)
    pdk_name = last(r"^set PDK\s+(\S+)", read(f"{run}/run_cfg.tcl") or "", re.M)
    waivers = dict(l.split("|", 1) for l in (read(os.path.expanduser(f"~/flash/pdk_cfg/{pdk_name}/pg_drc_waivers.txt")) or "").splitlines()
                   if "|" in l and not l.startswith("#"))
    waivers = {k.strip(): v.strip() for k, v in waivers.items()}
    reconciled = reported_total is not None and int(reported_total) == typed_total and int(out) + int(io) == int(reported_total)
    if out != "0" and types and reconciled and all(ty in waivers for _, ty in types):
        add("fc_pg_drc", True, f"outside IO cells={out}, all waived: " + "; ".join(f"{n} {ty}" for n, ty in types))
    else:
        add("fc_pg_drc", out == "0" and reconciled, f"outside IO cells={out}; inside IO cells={io}, total={reported_total}, typed={typed_total}")
else:
    add("fc_pg_drc", False, (last(r"[^\n]*[Ee]rror[^\n]*", pg) or "errors reported")[:140])

pgc = read(f"{run}/rpt/pg_conn_final.rpt")
if pgc is None:
    add("fc_pg_connectivity", None, "no report")
else:
    floating = re.findall(r"Number of floating [^:\n]+:\s*(\d+)", pgc)
    add("fc_pg_connectivity", bool(floating) and all(int(x) == 0 for x in floating),
        "floating counts " + ",".join(floating))

# StarRC
st = read(f"{run}/signoff/starrc/starrc.log")
if st is None:
    add("starrc", None, "no log")
else:
    ex = last(r"STARRC_EXIT=(\d+)", st)
    errs = re.findall(r"^ERROR.*$", st, re.M)
    origin = recorded_origin(run, 'starrc')
    launch = f"FLASH_STARRC_LAUNCH script={origin}/signoff/starrc/star.cmd"
    add("starrc", ex == "0" and not errs and launch in st and os.path.exists(glob.glob(f"{run}/signoff/starrc/*.spef")[0] if glob.glob(f"{run}/signoff/starrc/*.spef") else ""),
        f"exit={ex} errors={len(errs)}" + (f" first: {errs[0][:100]}" if errs else ""))

# PrimeTime
for c in sorted(corner + ('_shift' if mode == 'shift' else '') for corner in manifest_for(Path(run))['corners'] for mode in manifest_for(Path(run))['modes']):
    pt = read(f"{run}/signoff/pt_{c}/pt.log")
    m = re.search(r"FLASH_PT corner=\S+ period=([\d.]+) setup_wns=(-?[\d.eE+-]+) hold_wns=(-?[\d.eE+-]+)", pt or "")
    if not m:
        add(f"pt_{c}", None, "no FLASH_PT line")
        add(f"analysis_launch_{c}", False, "missing PT launch binding")
        add(f"noise_{c}", None, "missing PT noise analysis")
        continue
    s, h = float(m.group(2)), float(m.group(3))
    # Without a SPEF, PrimeTime times the design with no wire RC and still prints slack. The SKY130
    # counter passed that way on 2026-09-21, so every net must carry StarRC parasitics.
    # Nets with no driver or no load carry no timing, so only pin-to-pin nets must be annotated.
    # FC's DEF names each unconnected input port's net _dummynetN, which the Verilog lacks, and
    # PrimeTime reports exactly 2 errors per such net; any other error breaks the accounting.
    violator_report = read(f"{run}/signoff/pt_{c}/violators.rpt") or ""
    constraints_complete = complete_tool_report(violator_report, 'constraint')
    para = read(f"{run}/signoff/pt_{c}/parasitics_command.log") or ""
    parasitic_complete, parasitic_detail = complete_parasitic_report(para)
    errs = int(last(r"(\d+) error\(s\)", para) or -1)
    nets = int(last(r"Annotated nets\s*:\s*(\d+)", para) or 0)
    missing = sum(int(r) for r in re.findall(r"^\s+- Pin to pin nets\s*\|(?:\s*\d+\s*\|){5}\s*(\d+)\s*\|", para, re.M))
    # Runs since 9-25 also list those nets by name. A SYNOPSYS_UNCONNECTED net holds one unconnected inout pin,
    # which reads as driver and load, so it counts as pin to pin with no wire: 51 on the SKY130 chip, all
    # the gpiov2 pads' analog PAD_A_ESD_0_H, PAD_A_ESD_1_H and PAD_A_NOESD_H.
    listed = re.findall(r"^\s*\d+\.\s+(\S+) \(driver", para, re.M)
    unconnected = sum(n.startswith("SYNOPSYS_UNCONNECTED") for n in listed)
    if "-list_not_annotated" in para:
        missing = len(listed) - unconnected
    dummies = sum(len(re.findall(r"\+ NET _dummynet\d+", read(d) or "")) for d in glob.glob(f"{run}/out/*.def"))
    other = [l for l in para.splitlines() if l.startswith("Error:") and "_dummynet" not in l]
    annotated = nets > 0 and missing == 0 and not other and errs == 2 * dummies and parasitic_complete
    add(f"pt_{c}", annotated and constraints_complete and s >= 0 and h >= 0,
        f"period={m.group(1)}ns setup_wns={s:.3f} hold_wns={h:.3f} spef_nets={nets} pin_to_pin_not_annotated={missing}" + (f" unconnected_pins={unconnected}" if unconnected else "")
        + ("" if annotated else f" PARASITICS INCOMPLETE ({parasitic_detail}) errors={errs} dummy_nets={dummies}")
        + ("" if constraints_complete else " CONSTRAINT REPORT INCOMPLETE"))
    spef_path = consumer_spef(Path(run), 'pt_' + c)
    design_name = cfg_values(Path(run))['DESIGN']
    origin = recorded_origin(run, 'pt_' + c)
    origin_spef = Path(origin) / spef_path.relative_to(run)
    launch = f"FLASH_PT_LAUNCH script={origin}/signoff/pt_policy.tcl spef={origin_spef} netlist={origin}/out/{design_name}.v"
    add(f"analysis_launch_{c}", launch in (pt or ''), 'executed PT script and exact SPEF are recorded' if launch in (pt or '') else 'missing PT launch binding')
    # Crosstalk glitch check, in runs signed off since it was added.
    nm = re.search(r"FLASH_PT_NOISE corner=\S+ worst_slack=(\S+) violators=(\d+)", pt or "")
    noise_report = read(f"{run}/signoff/pt_{c}/noise_violators.rpt") or ""
    noise_ok = bool(nm) and complete_tool_report(noise_report, 'noise') and int(nm.group(2)) == 0
    add(f"noise_{c}", noise_ok, f"worst_slack={nm.group(1) if nm else 'missing'} violators={nm.group(2) if nm else 'missing'}" + ("" if noise_ok else " report incomplete"))

# Formality
fm = read(f"{run}/signoff/formality/fm.log")
if fm is None:
    add("formality", None, "no log")
else:
    ok = "Verification SUCCEEDED" in fm
    stat = read(f"{run}/signoff/formality/status.rpt") or ""
    pts = [(k, n) for n, k in re.findall(r"(\d+) (Passing|Failing|Aborted|Unverified) compare points", stat)]
    add("formality", ok, ("SUCCEEDED" if ok else last(r"Verification \w+", fm) or "no verdict")
        + " " + " ".join(f"{k}={v}" for k, v in pts[:4]))

# PrimePower
pp = read(f"{run}/signoff/primepower/pp.log")
m = re.search(r"FLASH_PP mode=(\w\S*) total=([\d.eE+-]+)", pp or "")
add("primepower", None if not m else True, f"mode={m.group(1)} total={m.group(2)} W" if m else "no FLASH_PP line")

# DRC. IC Validator writes <top>.RESULTS; KLayout writes result databases, counted marker by marker.
dbs = glob.glob(f"{run}/signoff/drc/*.lyrdb")
icv = [r for r in glob.glob(f"{run}/signoff/drc/*.RESULTS")]
if icv:
    res = read(icv[0])
    total = int(last(r"There (?:are|is) (\d+) total violations?", res) or -1)
    skipped_raw = last(r"(\d+) rules? NOT EXECUTED", res)
    skipped = int(skipped_raw) if skipped_raw is not None else -1
    rules = re.findall(r"^(\S+)\s+v = (\d+)", res, re.M)
    # Deck bugs proven by a planted test are waived by name in pdk_cfg/<pdk>/drc_waivers.txt, never silently.
    pdk = last(r"^set PDK\s+(\S+)", read(f"{run}/run_cfg.tcl"), re.M)
    wfile = read(os.path.expanduser(f"~/flash/pdk_cfg/{pdk}/drc_waivers.txt")) or ""
    waivable = {l.split()[0] for l in wfile.splitlines() if l.strip() and not l.startswith("#")}
    waived = [(k, v) for k, v in rules if k in waivable]
    total -= sum(int(v) for k, v in waived)
    region_file = Path(run) / 'signoff/drc/region_waivers.json'
    if region_file.is_file():
        try:
            if waived:
                raise ValueError('Region proof cannot be mixed with blanket rule waivers')
            proof = region_waiver(Path(run), Path(icv[0]).with_suffix('.LAYOUT_ERRORS'), total, region_file)
            total = proof['remaining']
            add('drc_region_waiver', True, 'raw=' + str(proof['raw']) + ' waived=' + str(proof['waived']) + ' remaining=' + str(total) + '; exact vendor boundaries, full marker accounting')
        except (ValueError, KeyError, OSError, subprocess.CalledProcessError, TypeError) as exc:
            add('drc_region_waiver', False, str(exc))
    top = ", ".join([f"{k}:{v}" for k, v in sorted(rules, key=lambda x: -int(x[1])) if k not in waivable][:8])
    wtxt = " waived=" + ",".join(f"{k}:{v}" for k, v in waived) if waived else ""
    add("drc", total == 0 and skipped == 0, f"icv violations={total} {top} not_executed={skipped}{wtxt}")
elif not dbs:
    add("drc", None, "no DRC results")
else:
    required, rec = klayout_counts(dbs)
    # Rules that apply to a finished chip only, pdk_cfg/<pdk>/chip_only_rules.txt: IHP's global density floors,
    # which a block's own GDS can never meet. They are set aside here only when the filled chip was checked below.
    pdk = last(r"^set PDK\s+(\S+)", read(f"{run}/run_cfg.tcl") or "", re.M)
    lines = (read(os.path.expanduser(f"~/flash/pdk_cfg/{pdk}/chip_only_rules.txt")) or "").splitlines()
    chip_only = set(" ".join(l for l in lines if not l.startswith("#")).split())
    chip_done = os.path.exists(f"{run}/chip/done")
    deferred = {k: v for k, v in required.items() if chip_done and k in chip_only}
    required = {k: v for k, v in required.items() if k not in deferred}
    total = sum(required.values())
    top = ", ".join(f"{k}:{v}" for k, v in sorted(required.items(), key=lambda x: -x[1])[:8])
    dtxt = f" chip_level={','.join(sorted(deferred))}, judged on the filled chip" if deferred else ""
    add("drc", total == 0, f"klayout violations={total} {top} recommended_only={rec}{dtxt}")

# The filled chip, from pdk_cfg/<pdk>/chip_fill.sh: seal ring, fill, full DRC and the foundry's tapeout precheck.
if os.path.exists(f"{run}/chip/done") and glob.glob(f"{run}/chip/drc/*.RESULTS"):
    # IC Validator fill step, pdk_cfg/saed32/chip_fill.sh. Rules judged "across chip" only mean something on a
    # real chip, one with a pad ring; on a block they are reported and deferred, as the chip-only rules are.
    is_chip = re.search(r"(?m)^\s*set\s+IO_RING\s+\{\s*\S", read(f"{run}/run_cfg.tcl") or "") is not None
    for name, sub in (("chip_density", "density"), ("chip_drc", "drc")):
        res = read((glob.glob(f"{run}/chip/{sub}/*.RESULTS") or [""])[0]) if glob.glob(f"{run}/chip/{sub}/*.RESULTS") else None
        if res is None:
            add(name, None, "no result")
            continue
        errs = read(glob.glob(f"{run}/chip/{sub}/*.LAYOUT_ERRORS")[0]) or ""
        hits = re.findall(r"\n\s*(\S+)[^\n]*\n(?:[^\n]*\n)??\s+\S+ \.+ (\d+) violations? found", errs)
        hits = [(r, int(n)) for r, n in hits if int(n)]
        chip_only = [(r, n) for r, n in hits if not is_chip and re.search(r"across chip", errs.split(r, 1)[1][:120], re.I)]
        total = sum(n for _, n in hits) - sum(n for _, n in chip_only)
        dtxt = " chip_level=" + ",".join(f"{r}:{n}" for r, n in chip_only) + ", deferred on a block" if chip_only else ""
        top = ", ".join(f"{r}:{n}" for r, n in hits if (r, n) not in chip_only)
        add(name, total == 0, f"icv violations={total} {top}{dtxt} on the filled layout")
elif os.path.exists(f"{run}/chip/done"):
    for name, sub in (("chip_drc", "drc"), ("chip_precheck", "precheck")):
        cdbs = glob.glob(f"{run}/chip/{sub}/*.lyrdb")
        if not cdbs:
            add(name, None, "no result database")
            continue
        req, crec = klayout_counts(cdbs)
        tot = sum(req.values())
        ctop = ", ".join(f"{k}:{v}" for k, v in sorted(req.items(), key=lambda x: -x[1])[:8])
        add(name, tot == 0, f"klayout violations={tot} {ctop} recommended_only={crec}")

# LVS, from the IC Validator or KLayout log
lv = read(f"{run}/signoff/lvs.log")
cdl = read(f"{run}/signoff/lvs/v2cdl.log")
if cdl is not None and "V2CDL_EXIT=0" not in cdl:
    add("lvs_netlist", False, last(r"V2CDL[^\n]*", cdl))
if lv is None:
    add("lvs", None, "no log")
else:
    icv_res = glob.glob(f"{run}/signoff/lvs/run/*.RESULTS")
    if icv_res:
        lv = read(icv_res[0]) + lv
    match = re.search(r"Congratulations! Netlists match|LVS Compare Result: PASS", lv) is not None
    boxed = re.findall(r"LVS_BLACKBOX \S+: boxed=\[([^\]]*)\]", lv)
    note = f", black-boxed {boxed[0]}" if boxed else ""
    add("lvs", match, f"netlists match{note}" if match else (last(r"[^\n]*(?:don't match|mismatch|ERROR)[^\n]*", lv, re.I) or "no match line")[:140])


# A fixed required matrix prevents a missing directory from reducing the denominator.
rp = Path(run)
mp = rp / 'signoff/manifest.json'
if not mp.is_file():
    add('manifest', False, 'missing signoff/manifest.json; historical results are not certified')
else:
    manifest = json.loads(mp.read_text())
    proposed = manifest_for(rp)
    if compatible_saed90_manifest(manifest, proposed) and manifest != proposed:
        rows.append(('manifest', 'UNRECORDED', 'older SAED90 backend selector; rerun wrapper migrates archived manifest'))
        manifest = proposed
    else:
        add('manifest', manifest == proposed, 'fixed expected corners=' + ','.join(manifest['corners']) + ' modes=' + ','.join(manifest['modes']))
    scope = manifest.get('integration_scope', {})
    scope_ok = (scope.get('reviewed') is True and bool(scope.get('restriction')) and
                scope.get('block_density_fill') in {'deferred_until_filled_chip', 'required_on_filled_chip'})
    add('integration_scope', scope_ok, scope.get('restriction', 'missing density/fill integration restriction'))
    pdk_waiver_path = Path(os.path.expanduser(f"~/flash/pdk_cfg/{manifest.get('pdk', '')}/drc_waivers.txt"))
    waiver_lines = [line for line in (read(str(pdk_waiver_path)) or '').splitlines() if line.strip() and not line.lstrip().startswith('#')]
    review_path = rp / 'signoff/drc_waiver_review.json'
    if waiver_lines:
        try:
            review = json.loads(review_path.read_text())
            names = [line.split()[0] for line in waiver_lines]
            review_ok = (review.get('reviewed_by') and review.get('reviewed_on') and review.get('path') == str(pdk_waiver_path) and
                         review.get('sha256') == sha256(pdk_waiver_path) and review.get('rules') == names)
            add('drc_waiver_review', review_ok, 'reviewed global DRC waiver hash and rule list required')
        except (OSError, json.JSONDecodeError, AttributeError):
            add('drc_waiver_review', False, 'missing or malformed reviewed global DRC waiver record')
    else:
        add('drc_waiver_review', True, 'no global DRC rule waivers configured')
    identity = inputs(rp, manifest['design'])
    add('final_artifacts', all(v is not None for v in identity.values()), str(identity))
    by_name = {r[0]: r for r in rows}
    for name, patterns in manifest['required'].items():
        # chip_lvs and atpg report their verdicts as chip_lvs_completion and atpg_coverage.
        if name not in by_name and not name.startswith('starrc_') and name not in ('chip_lvs', 'atpg'):
            add(name, False, 'required check absent')
        missing_files = [p for p in patterns if not glob.glob(f'{run}/{p}')]
        add('reports_' + name, not missing_files, 'missing=' + ','.join(missing_files) if missing_files else 'required evidence present')
        pp = rp / ('signoff/provenance/' + name + '.json')
        if not pp.is_file():
            if missing_files:
                rows.append(('provenance_' + name, 'MISSING', 'evidence missing; no runtime fingerprint'))
            else:
                rows.append(('provenance_' + name, 'UNRECORDED', 'older or uninstrumented flow: runtime fingerprint not recorded; rerun required'))
        else:
            prov = json.loads(pp.read_text())
            ev = evidence_hashes(rp, patterns)
            expected_inputs = check_inputs(rp, manifest['design'], name)
            recorded_inputs = relevant_recorded_inputs(prov.get('inputs', {}), expected_inputs)
            recorded_evidence = prov.get('evidence', {})
            if manifest['pdk'] == 'saed90':
                obsolete = {'signoff/drc/*.lyrdb', 'chip/drc/*.lyrdb'}
                recorded_evidence = {k:v for k,v in recorded_evidence.items() if not (k in obsolete and v is None)}
            changed_inputs = [k for k,v in recorded_inputs.items() if k not in expected_inputs or expected_inputs[k] != v]
            changed_evidence = [k for k,v in recorded_evidence.items() if k not in ev or ev[k] != v]
            missing_inputs = sorted(set(expected_inputs) - set(recorded_inputs))
            missing_fingerprints = sorted(set(ev) - set(recorded_evidence))
            missing_input_values = sorted(k for k, v in expected_inputs.items() if v is None)
            if missing_files or any(v is None for v in ev.values()) or missing_input_values:
                rows.append(('provenance_' + name, 'MISSING', 'required evidence missing'))
            elif changed_inputs or changed_evidence:
                add('provenance_' + name, False, 'stale or changed fingerprints: inputs=' + ','.join(changed_inputs) + ' evidence=' + ','.join(changed_evidence))
            elif prov.get('exit') != 0:
                add('provenance_' + name, False, 'recorded tool exit=' + str(prov.get('exit')))
            elif missing_inputs or missing_fingerprints:
                rows.append(('provenance_' + name, 'UNRECORDED', 'older fingerprint schema lacks inputs=' + ','.join(missing_inputs) + ' evidence=' + ','.join(missing_fingerprints)))
            else:
                add('provenance_' + name, True, 'matching input/evidence MD5 and exit=0')
    for corner in manifest['corners']:
        for mode in manifest['modes']:
            c = corner + ('_shift' if mode == 'shift' else '')
            v = read(f'{run}/signoff/pt_{c}/violators.rpt')
            violations = []
            timing_violations = []
            section = ''
            for line in (v or '').splitlines():
                heading = re.match(r'^\s*((?:max|min|clock)_\w+(?:/\w+)?)\s*(?:\(.*\))?\s*$', line)
                if heading:
                    section = heading.group(1)
                if '(VIOLATED' in line:
                    record = (section, line.split()[0], line.strip())
                    if section in {'max_capacitance', 'max_transition', 'min_transition', 'max_fanout'}:
                        violations.append(record)
                    else:
                        timing_violations.append(record)
            wf = rp / 'signoff/electrical_waivers.json'
            waiver_data = json.loads(wf.read_text()) if wf.is_file() else {}
            waivers = waiver_data.get('waivers', []) if waiver_data.get('reviewed_by') and waiver_data.get('reviewed_on') else []
            allowed = {(x['corner_mode'], x['constraint'], x['pin']) for x in waivers if x.get('reason')}
            bad = [(k,p,l) for k,p,l in violations if (c,k,p) not in allowed]
            add('electrical_' + c, complete_tool_report(v, 'constraint') and not bad, f'unwaived={len(bad)} waived={len(violations)-len(bad)}' + (' first=' + bad[0][2] if bad else ''))
            add('timing_constraints_' + c, complete_tool_report(v, 'constraint') and not timing_violations, f'violations={len(timing_violations)}' + (' first=' + timing_violations[0][2] if timing_violations else ''))
            log = read(f'{run}/signoff/pt_{c}/pt.log') or ''
            ex = last(r'PT_EXIT=(\d+)', log)
            errors = re.findall(r'^Error:.*$', log, re.M)
            add('pt_exit_' + c, ex == '0' and not errors, f'exit={ex} tool_errors={len(errors)}')
            rc = manifest['rc_pairing'].get(corner, 'nominal')
            expected = f'FLASH_PT_POLICY rc={rc} early=0.95 late=1.05 scope=cell_net'
            add('analysis_policy_' + c, expected in log, 'requires ' + expected)
            ct = read(f'{run}/signoff/pt_{c}/check_timing.rpt')
            coverage_bad = re.findall(r'Warning:.*(?:no clock|unconstrained|unexpandable|loops)', ct or '', re.I)
            tw = rp / 'signoff/timing_waivers.json'
            timing_waivers = json.loads(tw.read_text()) if tw.is_file() else {}
            if timing_waivers.get('reviewed_by') and timing_waivers.get('reviewed_on'):
                inactive = timing_waivers.get('inactive_clocks', [])
                allowed_pins = {x['pin'] for x in inactive if x.get('reason') and x.get('proof')}
                section = (ct or '').split("Checking 'no_clock'.", 1)
                clock_text = section[1].split('Information:',1)[0] if len(section)>1 else ''
                clock_pins = set(re.findall(r'^\s*(\S+/\S+)\s*$',clock_text,re.M))
                count = last(r'There are (\d+) register clock pins with no clock', clock_text)
                if count is not None and len(clock_pins) == int(count) and clock_pins <= allowed_pins:
                    coverage_bad = [x for x in coverage_bad if 'with no clock' not in x]
            add('clock_coverage_' + c, ct is not None and not coverage_bad, '; '.join(coverage_bad) or 'no uncovered clock warnings')
            coverage_report = read(f'{run}/signoff/pt_{c}/analysis_coverage.rpt')
            if coverage_report is None:
                add('pt_report_analysis_coverage_' + c, None, 'missing analysis_coverage.rpt')
            else:
                try:
                    actual = analysis_coverage(coverage_report)
                    disabled_report = read(f'{run}/signoff/pt_{c}/disabled_timing.rpt')
                    actual['disabled_timing'] = disabled_timing_coverage(disabled_report)
                    reason = reviewed_coverage(Path(run), c, actual)
                    add('pt_report_analysis_coverage_' + c, actual['violated'] == 0, reason + f" total={actual['total']} untested={actual['untested']}")
                except (ValueError, KeyError, TypeError, json.JSONDecodeError) as exc:
                    add('pt_report_analysis_coverage_' + c, False, str(exc))
    for rc in ('cmax', 'cmin'):
        st = read(f'{run}/signoff/starrc_{rc}/starrc.log')
        ex = last(r'STARRC_EXIT=(\d+)', st)
        add('starrc_' + rc, st is not None and ex == '0' and not re.search(r'^ERROR', st, re.M), f'exit={ex} required real {rc} process grid')
    pp = read(f'{run}/signoff/primepower/pp.log') or ''
    value = last(r'FLASH_PP mode=\S+ total=([\d.eE+-]+)', pp)
    import math
    design_name = cfg_values(Path(run))['DESIGN']
    origin = recorded_origin(run, 'primepower')
    pp_launch = f'FLASH_PP_LAUNCH script={origin}/signoff/w1_flow/pp_power.tcl spef={origin}/signoff/starrc/{design_name}.spef netlist={origin}/out/{design_name}.v'
    add('primepower_launch', pp_launch in pp, 'executed PP script and exact SPEF are recorded' if pp_launch in pp else 'missing PP launch binding')
    add('primepower_completion', value is not None and math.isfinite(float(value)) and float(value) >= 0 and last(r'PP_EXIT=(\d+)', pp) == '0' and not re.search(r'^Error:', pp, re.M), 'finite nonnegative power and successful tool exit required')
    fm = read(f'{run}/signoff/formality/fm.log') or ''
    stat = read(f'{run}/signoff/formality/status.rpt') or ''
    unfinished = sum(int(n) for n in re.findall(r'(\d+) (?:Failing|Aborted|Unverified) compare points', stat))
    add('formality_completion', last(r'FM_EXIT=(\d+)', fm) == '0' and last(r'Verification (SUCCEEDED|FAILED)', fm) == 'SUCCEEDED' and unfinished == 0, f'unfinished={unfinished}; latest verdict and successful exit required')
    origin = recorded_origin(run, 'formality')
    fm_launch = f'FLASH_FM_LAUNCH script={origin}/signoff/w1_flow/fm_verify.tcl netlist={origin}/out/{design_name}.v'
    add('formality_launch', fm_launch in fm, 'executed FM script and netlist are recorded' if fm_launch in fm else 'missing FM launch binding')
    coverage_file = rp / 'signoff/formality_coverage.json'
    coverage = json.loads(coverage_file.read_text()) if coverage_file.is_file() else {}
    passed = int(last(r'(\d+) Passing compare points',stat) or -1)
    excluded = int(last(r"^\s*Don't verify\s+.*?\s+(\d+)\s*$",stat,re.M) or 0)
    clock_gate = int(last(r'^\s*Clock-gate LAT\s+.*?\s+(\d+)\s*$',stat,re.M) or 0)
    unmatched = read(f'{run}/signoff/formality/unmatched.rpt') or ''
    dont = read(f'{run}/signoff/formality/dont_verify.rpt') or ''
    # report_dont_verify_points prefixes each point with its type, such as (Port); without that prefix in the pattern
    # no excluded point was read, so the review could not name them.
    excluded_names = set(re.findall(r'^[ \t]*(?:\(\w+\)[ \t]+)?([ri]:/\S+)',dont,re.M))
    excluded_names = {x.strip() for x in excluded_names}
    waived = {x['point'] for x in coverage.get('excluded',[]) if x.get('reason')}
    unmatched_clean = bool(re.search(r'(?:No unmatched|0 unmatched)',unmatched,re.I))
    actual_unmatched = re.findall(r'^\s*(Impl|Ref)\s+(\S+)\s+([ir]:/\S+)', unmatched, re.M)
    allowed_gates = {x['point'] for x in coverage.get('unmatched_clock_gates', []) if x.get('reason') and x.get('proof')}
    summary = re.search(r'(\d+) Unmatched points \((\d+) reference, (\d+) implementation\)', unmatched)
    if allowed_gates and summary:
        unmatched_clean = int(summary.group(2)) == 0 and int(summary.group(1)) == int(summary.group(3)) == len(actual_unmatched) and all(side == 'Impl' and kind == 'LATCG' for side,kind,point in actual_unmatched) and {point for side,kind,point in actual_unmatched} == allowed_gates
    coverage_ok = bool(coverage.get('reviewed_by') and coverage.get('reviewed_on')) and passed > 0 and passed == coverage.get('expected_passing') and excluded == coverage.get('expected_excluded') and clock_gate == coverage.get('expected_clock_gate_latches') and excluded_names == waived and unmatched_clean
    add('formality_coverage', coverage_ok, f'passing={passed} excluded={excluded} clock_gate_latches={clock_gate}; requires reviewed exact exclusions, expected counts and no unmatched points')
    for name, location in [('drc', 'signoff/drc'), ('chip_drc','chip/drc'), ('chip_density','chip/density')]:
        if name not in manifest['required']:
            continue
        results = glob.glob(f'{run}/{location}/*.RESULTS')
        for file in results:
            res = read(file)
            total = last(r'There (?:are|is) (\d+) total violations?', res)
            skipped = last(r'(\d+) rules? NOT EXECUTED', res)
            # Preserve explicitly recorded block deck waivers, but never accept an unparsed chip count.
            add('icv_completion_' + name, total is not None and skipped == '0' and (name == 'drc' or total == '0'), f'total={total} not_executed={skipped}')
    if 'atpg' in manifest['required']:
        try:
            proof = atpg_check(rp)
            add('atpg_coverage', True, 'patterns=' + str(proof['patterns']) + ' test_coverage=' + str(proof['test_coverage_percent']) + ' total_faults=' + str(proof['total_faults']) + ' ' + proof['scope'])
        except (ValueError, KeyError, OSError, TypeError) as exc:
            add('atpg_coverage', False, str(exc))
    for name, path in [('lvs','signoff/lvs.log'), ('chip_lvs','signoff/lvs_chip/lvs.log')]:
        if name not in manifest['required']:
            continue
        lv = read(f'{run}/{path}') or ''
        if name == 'lvs':
            results = glob.glob(f'{run}/signoff/lvs/run/*.RESULTS')
            if results:
                lv = (read(results[0]) or '') + lv
        verdicts = re.findall(r'Congratulations! Netlists match|Netlists don.t match|LVS Compare Result: (?:PASS|FAIL)', lv, re.I)
        execution = lvs_execution(lv)
        ok = bool(verdicts) and ('Netlists match' in verdicts[-1] or verdicts[-1].endswith('PASS')) and last(r'LVS_EXIT=(\d+)', lv) == '0' and not re.search(r'Traceback|^ERROR|^Error:', lv, re.M)
        if name == 'lvs' and glob.glob(f'{run}/signoff/lvs/run/*.RESULTS'):
            ok = ok and execution is not None and execution[0] > 0 and execution[1] == 0
        detail = 'latest match verdict and successful exit required'
        if name == 'lvs' and glob.glob(f'{run}/signoff/lvs/run/*.RESULTS'):
            detail += f'; executed={execution[0] if execution else None} not_executed={execution[1] if execution else None}'
        add(name + '_completion', ok, detail)

vc_report = rp / 'signoff/vcstatic/summary.rpt'
vc_required = cfg_values(rp).get('VC_STATIC_REQUIRED') == '1'
if vc_required or vc_report.is_file():
    vc_text = read(str(vc_report))
    total = re.findall(r'^\s*Total\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*$', vc_text or '', re.M)
    if len(total) != 1:
        add('vcstatic_summary', None if vc_text is None else False, 'missing or ambiguous management summary totals')
    else:
        fatals, errors, warnings, infos = map(int, total[0])
        limited = bool(re.search(r'detailed reports have been limited', vc_text, re.I))
        add('vcstatic_summary', fatals == errors == warnings == 0,
            f'fatals={fatals} errors={errors} warnings={warnings} infos={infos} details_limited={limited}; summary totals govern')

width = max(len(r[0]) for r in rows)
for name, status, ev in rows:
    print(f'{name:<{width}}  {status:<7}  {ev}')
fails = [r for r in rows if r[1] != 'PASS']
verdict = {'clean': not fails, 'passed': len(rows)-len(fails), 'total': len(rows),
           'physical_failures': [n for n,s,e in rows if s == 'FAIL' and not n.startswith(('provenance_', 'reports_')) and n not in {'manifest','final_artifacts'}],
           'evidence_failures': [n for n,s,e in rows if s in {'FAIL','MISSING'} and n.startswith(('provenance_', 'reports_'))],
           'unrecorded_fingerprints': [n for n,s,e in rows if s == 'UNRECORDED'],
           'checks': [{'name': n, 'status': s, 'evidence': e} for n,s,e in rows]}
atomic_json(rp / 'signoff/verdict.json', verdict)
print(f"SIGNOFF {'CLEAN' if not fails else 'NOT CLEAN'}: {len(rows)-len(fails)} of {len(rows)} checks pass")
sys.exit(1 if fails else 0)
