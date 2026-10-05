# Drop the changes that touch a bad cell from a PrimeTime change list, plus any later change that refers to a cell or
# net a dropped change created.
# usage: filter_changes.py <changes.tcl> <out.tcl> <bad_cells.txt>...
import re, sys
src, dst, *bad_files = sys.argv[1:]
bad = {line.split()[0] for f in bad_files for line in open(f) if line.strip()}
kept, dropped = [], 0
created = set()
for line in open(src):
    names = set(re.findall(r'new_cell_names \{([^}]+)\}', line)) | set(re.findall(r'^size_cell \{([^}]+)\}', line))
    nets = set(re.findall(r'new_net_names \{([^}]+)\}', line))
    words = set(re.findall(r'[\w/\[\].]+', line))
    if names & bad or words & created:
        created |= names | nets
        dropped += 1
        continue
    kept.append(line)
open(dst, 'w').writelines(kept)
print('FILTER bad_cells', len(bad), 'dropped', dropped, 'kept', sum(1 for l in kept if l.startswith(('insert_buffer', 'size_cell'))))
