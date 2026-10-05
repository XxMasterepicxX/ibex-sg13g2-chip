# Targeted changes for what PrimeTime's own fix lists leave behind, read from the last evaluation's logs:
#   a noise victim       buf_2 after the driver of the victim's net
#   a pin over its limit the driver one size up, or buf_2 after it if it has no larger size
#   fast hold under 0.09 a delay cell in front of the endpoint
# SRAM outputs in dout_pins.txt are skipped: Fusion Compiler buffers those after the check.
# usage: targeted.py <prefix> <dout_pins.txt>       prints the new change lines
import glob, re, sys
prefix, dout = sys.argv[1], set(open(sys.argv[2]).read().split())
lines, seen = [], set()
def add(key, text):
    if key not in seen:
        seen.add(key)
        lines.append(text)
for f in sorted(glob.glob('eval_*.log')):
    for l in open(f):
        w = l.split()
        if l.startswith('FLASH_NOISE_DRIVER') and len(w) == 4:
            add(w[1], f"insert_buffer [get_pins {{{w[1]}}}] sg13g2_buf_2 -new_net_names {{net_{prefix}_N{len(lines) + 1}}} -new_cell_names {{U_{prefix}_N{len(lines) + 1}}}")
        elif l.startswith('FLASH_DRC_DRIVER') and len(w) == 5 and w[1] not in dout and w[2] not in dout:
            pin, cell, ref = w[2], w[3], w[4]
            if ref.endswith('_1'):
                add(cell, f"size_cell {{{cell}}} {{{ref[:-1]}2}}")
            else:
                add(pin, f"insert_buffer [get_pins {{{pin}}}] sg13g2_buf_2 -new_net_names {{net_{prefix}_D{len(lines) + 1}}} -new_cell_names {{U_{prefix}_D{len(lines) + 1}}}")
        elif l.startswith('FLASH_HOLD_END') and f.startswith('eval_fast') and '/' in w[1]:
            add(w[1], f"insert_buffer [get_pins {{{w[1]}}}] sg13g2_dlygate4sd1_1 -new_net_names {{net_{prefix}_H{len(lines) + 1}}} -new_cell_names {{U_{prefix}_H{len(lines) + 1}}}")
print('\n'.join(lines))
