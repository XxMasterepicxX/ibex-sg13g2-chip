# Runs analyze.py in RedHawk-SC for one case, with a one-hour limit.
# usage: run.py <workdir> <case>       results in <workdir>/<case>/baseline
import hashlib, json, os, subprocess, sys, time
from pathlib import Path
W, key = Path(sys.argv[1]), sys.argv[2]
case = W / key
folder = case / 'baseline'
folder.mkdir(exist_ok=True)
exe = os.environ.get('REDHAWK_SC', '/apps/syn/seascape/current/linux_x86_64_rhel8_ece/bin/redhawk_sc')
script = str(Path(__file__).resolve().parent / 'analyze.py')
env = dict(os.environ, IR_CASE_DIR=str(case))
with (folder / 'run.log').open('w') as out:
    p = subprocess.Popen([exe, '-n', '--license_time_out_secs', '30', script], cwd=folder, env=env, stdout=out, stderr=subprocess.STDOUT)
    print('IR_STARTED', key, p.pid, flush=True)
    try:
        code = p.wait(timeout=3600)
    except subprocess.TimeoutExpired:
        p.terminate()
        code = p.wait(timeout=30)
    (folder / 'done.json').write_text(json.dumps({'exit_code': code, 'completed': (folder / 'completed.json').exists(), 'ended': time.time(),
                                                  'def_sha256': hashlib.sha256((case / 'baseline.def').read_bytes()).hexdigest()}))
    print('IR_DONE', key, code, flush=True)
