#!/bin/bash
# Builds every test in this folder into build/<name>/prog.hex, plus the PLANT_FAIL control of t_muldiv.
# Uses the SoC's own startup code and linker script from ../sw.
set -e
S=$(dirname "$(readlink -f "$0")")
SW=$S/../sw
T=/apps/riscv-toolchain/bin/riscv64-unknown-elf
build() { # name source extra-flags...
  local n=$1 src=$2; shift 2
  local O=$S/build/$n; mkdir -p $O
  $T-gcc -march=rv32imc -mabi=ilp32 -O2 -nostdlib -nostartfiles -ffreestanding -T $SW/link.ld "$@" \
    $SW/crt0.S $src -o $O/prog.elf
  $T-objdump -d $O/prog.elf > $O/prog.dis
  $T-objcopy -O binary --only-section=.vectors --only-section=.text --only-section=.data $O/prog.elf $O/prog.bin
  python3 - $O/prog.bin $O/prog.hex <<'PY'
import struct, sys
data = open(sys.argv[1], "rb").read()
data += b"\0" * (-len(data) % 4)
if len(data) > 4096:
    sys.exit(f"image is {len(data)} bytes, IMEM holds 4096")
with open(sys.argv[2], "w") as f:
    for i in range(0, len(data), 4):
        f.write("%08x\n" % struct.unpack("<I", data[i:i + 4])[0])
print(f"{sys.argv[2]}: {len(data) // 4} words")
PY
}
build t_isa        $S/t_isa.c -march=rv32im
build t_muldiv     $S/t_muldiv.c
build t_mem        $S/t_mem.c
build t_work       $S/t_work.c
build t_muldiv_plant $S/t_muldiv.c -DPLANT_FAIL
build main         $SW/main.c
