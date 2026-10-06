#!/usr/bin/env python3
"""Gate-level Verilog with power pins -> flat CDL for LVS.

Pin order for each cell comes from the library cell CDL, so a missing or extra
connection is an error, not a silent guess.
usage: v2cdl.py <netlist.pg.v> <cells.cdl> <top> <out.cdl> [PIN=NET ...]
PIN=NET puts every cell pin named PIN on net NET, for decks that extract a body/substrate as its
own node instead of merging it through the tie cells.
Macro CDL pin names are matched to Verilog pins as A_ADDR<7> -> A_ADDR[7] and VDD! -> VDD (IHP SRAM style).
Hierarchical netlists, such as Design Compiler's, are flattened here: instances get their hierarchical
path as a name, and assign statements merge nets. A flat netlist comes out exactly as before.
"""
import re
import sys


def read_subckt_pins(cdl_path):
    """{cell: pins}, and the .GLOBAL net names."""
    # A continuation line may start with spaces before its +.
    pins, globs, lines = {}, set(), re.sub(r"\n[ \t]*\+", " ", open(cdl_path).read()).splitlines()
    for line in lines:
        m = re.match(r"\s*\.subckt\s+(\S+)\s+(.*)", line, re.I)
        if m:
            pins[m.group(1)] = m.group(2).split()
        m = re.match(r"\s*\.global\s+(.*)", line, re.I)
        if m:
            globs.update(g.rstrip("!") for g in m.group(1).split())
    return pins, globs


def strip_comments(text):
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//[^\n]*", "", text)


def ident(name):
    # "\esc_name [3]" is bit 3 of the escaped vector esc_name.
    name = name.strip()
    if name.startswith("\\"):
        name = name[1:]
    return re.sub(r"\s+(\[\d+\])$", r"\1", name)


def cdl_key(pin):
    """The Verilog name of a CDL pin: bus bits in <n> become [n]; a trailing global '!' is dropped."""
    return re.sub(r"<(\d+)>$", r"[\1]", pin).rstrip("!")


def is_constant(net):
    return re.fullmatch(r"\d*'[bBhHdD]\w+", net.strip()) is not None


def expand_bits(expr, ranges):
    """A Verilog net expression as a list of bit nets, most significant first."""
    expr = expr.strip()
    if expr.startswith("{"):
        bits = []
        for item in expr.strip("{} ").split(","):
            bits += expand_bits(item, ranges)
        return bits
    if is_constant(expr):
        raise ValueError(f"constant {expr}; LVS needs a real net")
    rng = re.fullmatch(r"(.+?)\s*\[(\d+):(\d+)\]", expr)
    if rng:
        base, msb, lsb = ident(rng.group(1)), int(rng.group(2)), int(rng.group(3))
        step = -1 if msb >= lsb else 1
        return [f"{base}[{b}]" for b in range(msb, lsb + step, step)]
    name = ident(expr)
    if name in ranges:
        msb, lsb = ranges[name]
        step = -1 if msb >= lsb else 1
        return [f"{name}[{b}]" for b in range(msb, lsb + step, step)]
    return [name]


def expand_ports(decls):
    ports = []
    for direction, rng, names in decls:
        for n in names:
            n = ident(n)
            if rng:
                msb, lsb = map(int, rng)
                step = -1 if msb >= lsb else 1
                ports += [f"{n}[{i}]" for i in range(msb, lsb + step, step)]
            else:
                ports.append(n)
    return ports


class Nets:
    """Union-find over net names; top-level ports win as the surviving name."""

    def __init__(self, keep):
        self.parent, self.keep = {}, set(keep)

    def find(self, n):
        p = self.parent.get(n, n)
        if p != n:
            p = self.find(p)
            self.parent[n] = p
        return p

    def union(self, a, b):
        a, b = self.find(a), self.find(b)
        if a == b:
            return
        if b in self.keep and a not in self.keep:
            a, b = b, a
        self.parent[b] = a


def main(vpath, cdl_path, top, out_path, *remaps):
    # Remaps: PIN=NET ties a CDL pin to a fixed net. CELL.PIN=CDLPIN is a netlist pin the CDL folds into another
    # pin, such as a supply pad's bond-pad pin that is the same node as its supply inside the pad. -CELL
    # leaves out a cell with no devices and no CDL, such as a metal-only IO filler.
    drop = {r[1:] for r in remaps if r.startswith("-")}
    # ~NET! makes a global net local to each cell, for a CDL that declares a cell's internal nodes global, which
    # joins them across every instance; in the layout each instance has its own.
    local = {r[1:] for r in remaps if r.startswith("~")}
    # +CELL writes the cell's devices straight into the top level. Where extraction pulls a small cell's devices up
    # into its parent, the schematic must match that.
    inline = {r[1:] for r in remaps if r.startswith("+")}
    alias = {tuple(k.split(".", 1)): v for k, v in (r.split("=", 1) for r in remaps if "=" in r and "." in r.split("=", 1)[0])}
    remap = dict(r.split("=", 1) for r in remaps if "=" in r and "." not in r.split("=", 1)[0])
    # A cell powered through .GLOBAL nets has no pins for them; the netlist's pins of those names join the
    # global nets.
    cell_pins, globs = read_subckt_pins(cdl_path)
    cell_folded = {c.lower(): c for c in cell_pins}
    text = strip_comments(open(vpath).read())
    modules = {m.group(1): m.group(2) for m in re.finditer(r"\bmodule\s+(\w+)\b(.*?)\bendmodule", text, re.S)}
    if top not in modules:
        sys.exit(f"module {top} not found")
    decl_re = re.compile(r"\b(input|output|inout)\s+(?:wire\s+)?(?:\[(\d+):(\d+)\]\s*)?([^;]+);")
    range_re = re.compile(r"\b(?:wire|input|output|inout)\s+(?:wire\s+)?\[(\d+):(\d+)\]\s*([^;]+);")
    module_ports, module_ranges = {}, {}
    for name, body in modules.items():
        decls = [(m.group(1), (m.group(2), m.group(3)) if m.group(2) is not None else None,
                  [n for n in m.group(4).split(",") if n.strip()]) for m in decl_re.finditer(body)]
        module_ports[name] = expand_ports(decls)
        # Declared vector ranges, so a whole-bus connection like .A_DOUT(imem_dout) maps bit for bit.
        module_ranges[name] = {ident(n): (int(a), int(b)) for a, b, names in range_re.findall(body)
                               for n in names.split(",") if n.strip()}
    ports = module_ports[top]

    # A match without named connections is not an instance (a module header or declaration) and is skipped.
    inst_re = re.compile(r"\b(\w+)\s+(\\\S+\s|\w+)\s*\((.*?)\)\s*;", re.S)
    # Port names can be escaped: Design Compiler writes .\cm_sp_offset_q[2] ( net ) for a scalar port.
    conn_re = re.compile(r"\.(\\\S+\s|\w+)\s*\(\s*([^()]*?)\s*\)")
    assign_re = re.compile(r"\bassign\s+(.+?)\s*=\s*(.+?)\s*;", re.S)
    nets = Nets(ports)
    out, errors, warnings = [], [], []

    def connections(where, cell, conns, pins, ranges, port_ranges=None):
        """{pin bit: local net} for one instance, or None after recording an error."""
        pinmap = {}
        port_ranges = port_ranges or {}
        try:
            for p, n in conn_re.findall(conns):
                p = ident(p)
                bits = expand_bits(n, ranges)
                if len(bits) == 1 and not n.strip().startswith("{"):
                    pinmap[p] = bits[0]
                elif p in port_ranges:
                    # Verilog connects by position, left to right along the port's declared range, which may
                    # ascend, as in [0:4].
                    left, right = port_ranges[p]
                    step = -1 if left >= right else 1
                    idx = list(range(left, right + step, step))
                    if len(idx) != len(bits):
                        raise ValueError(f"port {p}[{left}:{right}] gets {len(bits)} bits")
                    pinmap.update({f"{p}[{k}]": b for k, b in zip(idx, bits)})
                else:
                    pinmap.update({f"{p}[{len(bits) - 1 - i}]": b for i, b in enumerate(bits)})
        except ValueError as e:
            errors.append(f"{where} ({cell}): {e}")
            return None
        # SPICE pin names are case-insensitive, so a CDL pin matches a netlist pin of any case. An exact match wins.
        exact = {cdl_key(q) for q in pins}
        folded = {k.lower(): k for k in exact}
        pinmap = {p if p in exact else folded.get(p.lower(), p): n for p, n in pinmap.items()}
        # Whole-bus connections: bit pins X[n] take bit n of the net connected to X.
        width = {}
        for p in pins:
            b = re.fullmatch(r"(.+)\[(\d+)\]", cdl_key(p))
            if b:
                width[b.group(1)] = max(width.get(b.group(1), -1), int(b.group(2)))
        for bus, msb in width.items():
            if bus in pinmap and f"{bus}[{msb}]" not in pinmap:
                net = pinmap.pop(bus)
                if msb == 0 and net not in ranges:
                    # A one-bit bus port on a single-bit net, such as req_i[0:0] on req_i[0].
                    pinmap[f"{bus}[0]"] = net
                    continue
                if ranges.get(net) != (msb, 0):
                    errors.append(f"{where} ({cell}): bus {bus}[{msb}:0] on net {net} declared {ranges.get(net)}")
                    return None
                pinmap.update({f"{bus}[{i}]": f"{net}[{i}]" for i in range(msb + 1)})
        extra = set(pinmap) - {cdl_key(p) for p in pins} - {p for c, p in alias if c == cell} - globs
        if extra:
            errors.append(f"{where} ({cell}): pins {sorted(extra)} not in CDL")
        return pinmap

    def flatten(name, prefix, portmap):
        body, ranges = modules[name], module_ranges[name]
        glob = lambda n: portmap.get(n, prefix + n)
        for m in assign_re.finditer(body):
            try:
                lhs, rhs = expand_bits(m.group(1), ranges), expand_bits(m.group(2), ranges)
            except ValueError as e:
                errors.append(f"{prefix or name}: assign {m.group(1).strip()}: {e}")
                continue
            if len(lhs) != len(rhs):
                errors.append(f"{prefix or name}: assign widths {len(lhs)} and {len(rhs)} differ")
                continue
            for a, b in zip(lhs, rhs):
                nets.union(glob(a), glob(b))
        for m in inst_re.finditer(body):
            cell, inst, conns = m.group(1), ident(m.group(2)), m.group(3)
            # Subcircuit names are case-insensitive too.
            if cell not in cell_pins and cell not in module_ports:
                cell = cell_folded.get(cell.lower(), cell)
            path = prefix + inst
            if cell in drop:
                continue
            if cell in cell_pins:
                pinmap = connections(path, cell, conns, cell_pins[cell], ranges)
                if pinmap is None:
                    continue
                for g in [p for p in pinmap if p in globs and p not in {cdl_key(q) for q in cell_pins[cell]}]:
                    nets.union(glob(pinmap.pop(g)), g)
                for (c, p), target in alias.items():
                    if c == cell and p in pinmap:
                        net = pinmap.pop(p)
                        if target in pinmap:
                            nets.union(glob(net), glob(pinmap[target]))
                        else:
                            pinmap[target] = net
                row = []
                for p in cell_pins[cell]:
                    # CELL:PIN=NET ties one cell's CDL pin, ahead of a PIN=NET for every cell.
                    if f"{cell}:{p}" in remap:
                        row.append(remap[f"{cell}:{p}"])
                    elif p in remap:
                        row.append(remap[p])
                    elif cdl_key(p) in pinmap:
                        row.append(glob(pinmap[cdl_key(p)]))
                    else:
                        # An unused output, such as Q on a flop that only drives Q_N. It gets its own net;
                        # LVS compares it against the layout, where the pin is also left open.
                        warnings.append(f"{path} ({cell}): pin {p} unconnected")
                        row.append(f"__unconnected_{path}_{p}")
                out.append((path, cell, row))
            elif cell in module_ports:
                pinmap = connections(path, cell, conns, module_ports[cell], ranges, module_ranges[cell])
                if pinmap is None:
                    continue
                child = {p: glob(pinmap[p]) if p in pinmap else f"__unconnected_{path}_{p}"
                         for p in module_ports[cell]}
                flatten(cell, path + "/", child)
            elif conn_re.search(conns):
                errors.append(f"{path}: cell {cell} not in CDL")

    flatten(top, "", {p: p for p in ports})

    # SPICE names are case-insensitive. Design Compiler's N42 and n42 in one module are two nets, and LVS
    # would read them as one. A name that differs from an earlier one only by case gets a suffix; ports keep
    # theirs. A '*' or '$' starts a SPICE comment, so FC's tie net *Logic1*1 would cut its cell call short;
    # those characters become '_'.
    def uncase(names, fixed):
        seen, new = {n.lower(): n for n in fixed}, {n: n for n in fixed}
        for n in names:
            if n in new:
                continue
            base = re.sub(r"[*$]", "_", n)
            m, i = base, 0
            while m.lower() in seen:
                i += 1
                m = f"{base}__case{i}"
            seen[m.lower()] = n
            new[n] = m
        return new

    rows = [(path, cell, [nets.find(n) for n in row]) for path, cell, row in out]
    net_name = uncase(dict.fromkeys(n for _, _, row in rows for n in row), ports)
    inst_name = uncase([path for path, _, _ in rows], [])
    case_renamed = sum(k != v for d in (net_name, inst_name) for k, v in d.items())

    with open(out_path, "w") as f:
        # Cell subcircuits are inlined: KLayout's reader splits an unquoted .INCLUDE path at '-'.
        f.write(f"* {top} from {vpath}\n* cell subcircuits from {cdl_path}\n")
        # CDL writes subcircuit calls as "X... nets / cell"; KLayout's SPICE reader takes the "/" as a pin.
        cells = re.sub(r"^(X[^\n]*?)\s+/\s+(\S+)\s*$", r"\1 \2", open(cdl_path).read(), flags=re.M)
        for g in local:
            cells = re.sub(r"(?im)^(\s*\.global\b.*)$", lambda m: " ".join(t for t in m.group(1).split() if t != g), cells)
            cells = re.sub(r"(?<![\w!])" + re.escape(g) + r"(?![\w!])", g.rstrip("!") + "_local", cells)
        # Dropped and inlined cells lose their definitions, since an unused one is a schematic-only circuit that
        # fails LVS. An inlined cell's devices are written into the top below.
        for c in drop:
            cells = re.sub(r"(?ims)^\.subckt\s+" + re.escape(c) + r"\s[^\n]*\n.*?^\.ends[^\n]*\n?", "", cells)
        inline_body = {}
        for c in inline:
            m = re.search(r"(?ims)^\.subckt\s+" + re.escape(c) + r"\s+([^\n]*)\n(.*?)^\.ends[^\n]*\n?", cells)
            if m:
                inline_body[c] = (m.group(1).split(), m.group(2))
                cells = cells.replace(m.group(0), "")
        f.write(cells + "\n")
        f.write(f".SUBCKT {top} {' '.join(ports)}\n")
        lines = []
        for path, cell, row in rows:
            nets_row = [net_name[n] for n in row]
            if cell not in inline:
                lines.append(f"X{inst_name[path]} {' '.join(nets_row)} {cell}")
                continue
            pins, body = inline_body[cell]
            pin_map = dict(zip(pins, nets_row))
            for dev in (d for d in body.splitlines() if d.strip() and not d.lstrip().startswith("*")):
                t = dev.split()
                nodes = {"M": 4, "D": 2, "R": 2, "C": 2}.get(t[0][0].upper(), 0)
                t[1:1 + nodes] = [pin_map.get(n, f"{inst_name[path]}_{n}") for n in t[1:1 + nodes]]
                t[0] = f"{t[0][0]}{inst_name[path]}_{t[0][1:]}"
                lines.append(" ".join(t))
        f.write("\n".join(lines))
        f.write("\n.ENDS\n")
    print(f"V2CDL modules={len(modules)} instances={len(out)} ports={len(ports)} errors={len(errors)} "
          f"unconnected_pins={len(warnings)} case_renamed={case_renamed}")
    for w in warnings[:10]:
        print("V2CDL_WARNING", w)
    for e in errors[:50]:
        print("V2CDL_ERROR", e)
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main(*sys.argv[1:])
