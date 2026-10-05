#!/usr/bin/env python3
"""Black-box named subcircuits in the layout and schematic netlists for chip-level LVS.

Each named subcircuit loses its body on both sides, so the comparison checks every connection to the box
pins and nothing inside, which is the foundry's to verify. IHP's RM_IHPSG13 SRAM and its sg13g2_io cells
fail IHP's own LVS deck even alone, so they are boxed. Subcircuits no longer reachable from the top are dropped.

The two sides describe a box's pins differently, and the pin lists are reconciled before comparing:
- The layout splits a pin whose rail pieces meet only outside the cell (iovss, iovss$1, iovss$2). The pieces
  are merged into one pin, and an instance that ties them to different nets is an error, not merged.
- The layout's unnamed pins ($1) are the substrate; the schematic's substrate is the global sub!.
- A rail that crosses a cell without touching a device is lifted into the parent, so the layout has no pin
  for it (vdd and iovdd across an IO filler). Only pins named on both sides are kept.
usage: lvs_blackbox.py <layout.cir> <layout_out.cir> <schematic.cdl> <schematic_out.cdl> <top> <subckt>...
"""
import re
import sys


def logical_lines(text):
    """Joins '+' continuation lines, keeping each logical line's original physical lines."""
    out = []
    for line in text.splitlines():
        if line.startswith("+") and out:
            out[-1].append(line)
        else:
            out.append([line])
    return out


def tokens(phys):
    return " ".join(p.lstrip("+") for p in phys).split()


def parse(path):
    blocks, outside, cur = {}, [], None
    for phys in logical_lines(open(path, errors="replace").read()):
        head = phys[0].strip()
        m = re.match(r"\.subckt\s+(\S+)", head, re.I)
        if m:
            cur = m.group(1)
            blocks[cur] = [phys]
        elif re.match(r"\.ends\b", head, re.I) and cur:
            blocks[cur].append(phys)
            cur = None
        elif cur:
            blocks[cur].append(phys)
        else:
            outside.append(phys)
    return blocks, outside


def instance(phys):
    """(name, nets, cell, params) of an X line, or None."""
    toks = tokens(phys)
    if not toks or toks[0][0] not in "xX":
        return None
    params = [t for t in toks[1:] if "=" in t]
    names = [t for t in toks[1:] if "=" not in t and t != "/"]
    return toks[0], names[:-1], names[-1], params


def pin_names(header):
    return [t for t in tokens(header)[2:] if "=" not in t]


def canonical(pin):
    """Layout pin name without its split suffix, or None for an unnamed (substrate) pin."""
    p = pin.lstrip("\\")
    return None if p.startswith("$") else re.sub(r"\$\d+$", "", p).lower()


def main(lay_in, lay_out, sch_in, sch_out, top, *boxes):
    lay, lay_outside = parse(lay_in)
    sch, sch_outside = parse(sch_in)
    # The extracted layout holds only the cells it uses, while the schematic file may define a whole library. A box
    # the layout lacks is unused here; if the schematic does place one, the compare reports the missing instance.
    unused = [b for b in boxes if b not in lay]
    if unused:
        print(f"LVS_BLACKBOX_UNUSED {unused}")
    boxes = [b for b in boxes if b not in unused]
    missing = [b for b in boxes if b not in lay or b not in sch]
    if top not in lay or top not in sch or missing:
        sys.exit(f"LVS_BLACKBOX_ERROR top={top in lay and top in sch} missing={missing}")

    # For each box: the kept pins in schematic order, and for each side, which positions feed each kept pin.
    keep_pins, pos = {}, {}
    for b in boxes:
        lp, sp = pin_names(lay[b][0]), pin_names(sch[b][0])
        lcanon = [canonical(p) for p in lp]
        kept = [p for p in sp if p.lower() in lcanon]
        dropped = sorted(set(p.lower() for p in sp) ^ set(c for c in lcanon if c))
        keep_pins[b] = kept
        pos[b] = {"lay": [[i for i, c in enumerate(lcanon) if c == p.lower()] for p in kept],
                  "sch": [[sp.index(p)] for p in kept]}
        print(f"LVS_BLACKBOX_PINS {b}: kept={kept} dropped={dropped}")

    errors = []

    def rewrite(blocks, side):
        for name, blk in blocks.items():
            if name in boxes:
                hdr = tokens(blk[0])
                blocks[name] = [[" ".join(hdr[:2] + keep_pins[name])], blk[-1]]
                continue
            for k, phys in enumerate(blk[1:-1], 1):
                inst = instance(phys)
                if not inst or inst[2] not in boxes:
                    continue
                iname, nets, cell, params = inst
                new = []
                for group in pos[cell][side]:
                    tied = sorted(set(nets[i] for i in group))
                    if len(tied) > 1:
                        errors.append(f"{side} {name}/{iname} ({cell}) ties one pin to {tied}")
                    new.append(nets[group[0]])
                blk[k] = [" ".join([iname] + new + [cell] + params)]

    rewrite(lay, "lay")
    rewrite(sch, "sch")
    if errors:
        for e in errors[:20]:
            print("LVS_BLACKBOX_SPLIT_PIN", e)
        sys.exit(f"LVS_BLACKBOX_ERROR {len(errors)} instances tie a split pin to different nets")

    for blocks, outside, dst in ((lay, lay_outside, lay_out), (sch, sch_outside, sch_out)):
        keep, todo = set(), [top]
        while todo:
            n = todo.pop()
            if n in keep or n not in blocks:
                continue
            keep.add(n)
            todo.extend(i[2] for i in map(instance, blocks[n][1:-1]) if i)
        with open(dst, "w") as f:
            for phys in outside:
                f.write("\n".join(phys) + "\n")
            for name, blk in blocks.items():
                if name in keep:
                    for phys in blk:
                        f.write("\n".join(phys) + "\n")
        print(f"LVS_BLACKBOX {dst}: boxed={len(boxes)} kept={len(keep)} dropped={len(blocks) - len(keep)}")


if __name__ == "__main__":
    main(*sys.argv[1:])
