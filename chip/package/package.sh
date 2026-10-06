#!/bin/bash
# Builds the IHP Open-Silicon release package from a signed-off run and checks it:
#   1. fills a copy of IHP__RVSoC8787: the release GDS with the top cell renamed and IHP's save options, the LVS
#      netlist with the same top name, the gate netlist, timing and parasitics, RTL, test programs and the signoff
#      summary. Nothing from the kit is copied in.
#   2. compares the release GDS with the signed-off chip, shape for shape and label for label
#   3. runs IHP's pre-check on the release GDS exactly as it would be submitted
# usage: package.sh <run_folder>       the package lands in <run_folder>/package/IHP__RVSoC8787
set -e
RUN=$(readlink -f "$1"); [ -f "$RUN/run_cfg.tcl" ] || { echo "usage: package.sh <run_folder>"; exit 1; }
grep -q "SIGNOFF CLEAN" <(tail -1 "$RUN/signoff/CHECK.txt") || { echo "Sign off first: $RUN/signoff/CHECK.txt is not SIGNOFF CLEAN"; exit 1; }
K=$HOME/flash/chip/package
N=RVSoC8787
P=$RUN/package/IHP__$N
V=$P/release/v.1.0.0
M=$P/$N-main
D=$HOME/flash/designs/flash_soc
export PATH=$HOME/flash/tools/bin:$HOME/flash/tools/pyenv/bin:$PATH
rm -rf "$RUN/package"; mkdir -p "$RUN/package"
cp -r "$K/IHP__$N" "$P"
mkdir -p "$V/gds" "$V/netlist"

klayout -b -r "$K/release_gds.py" -rd in_gds="$RUN/chip/chip_filled.gds" -rd top=chip_flash_chip -rd name=$N -rd out_gds="$V/gds/$N.gds"
# The chip LVS schematic: the block's netlist plus a pinless top holding the block, renamed to the IP name.
sed "s/^\.SUBCKT chip_flash_chip\$/.SUBCKT $N/" "$RUN/signoff/lvs_chip/chip.cdl" > "$V/netlist/$N.cdl"
grep -q "^\.SUBCKT $N\$" "$V/netlist/$N.cdl"
cp "$RUN/out/flash_chip.v" "$V/netlist/flash_chip.v"
mkdir -p "$M/rtl" "$M/PlaceAndRoute/def" "$M/PlaceAndRoute/timing/sdf" "$M/PlaceAndRoute/parasitics/spef" "$M/testbenches" "$M/verification/sta"
cp "$D"/rtl/*.v "$M/rtl/"
cp "$RUN/out/flash_chip.def" "$M/PlaceAndRoute/def/"
for c in slow typ fast; do cp "$RUN/signoff/pt_$c/flash_chip.$c.sdf" "$M/PlaceAndRoute/timing/sdf/"; done
for x in starrc:typ starrc_cmax:cmax starrc_cmin:cmin; do
  cp "$RUN/signoff/${x%:*}/flash_chip.spef" "$M/PlaceAndRoute/parasitics/spef/flash_chip.${x#*:}.spef"
done
cp "$D/tb/tb_flash_soc.sv" "$M/testbenches/"
cp "$D"/sw_suite/*.c "$D/sw_suite/build_all.sh" "$D/sw_suite/run_suite.sh" "$M/testbenches/"
cp "$RUN/signoff/CHECK.txt" "$M/verification/sta/CHECK.txt"
(cd "$V" && sha256sum gds/$N.gds netlist/$N.cdl netlist/flash_chip.v > SHA256SUMS)
echo PACKAGE_DONE

# The release GDS must hold the same shapes and labels as the chip that was signed off.
A=$RUN/chip/chip_filled.gds
B=$V/gds/$N.gds
klayout -b -r "$K/gds_xor.py" -rd a="$A" -rd ta=chip_flash_chip -rd b="$B" -rd tb=$N > "$RUN/package/xor.txt"
klayout -b -r "$K/gds_texts.py" -rd a="$A" -rd ta=chip_flash_chip -rd b="$B" -rd tb=$N > "$RUN/package/texts.txt"
grep -h "^XOR\|^LAYERS\|^TEXTS" "$RUN/package/xor.txt" "$RUN/package/texts.txt"

# IHP's pre-check, the rule set IHP runs at tapeout.
export PDK_ROOT=$HOME/flash/pdk/IHP-Open-PDK PDK=ihp-sg13g2 KLAYOUT_PATH=$HOME/flash/pdk/IHP-Open-PDK/ihp-sg13g2/libs.tech/klayout
O=$RUN/package/precheck
set +e
python3 "$KLAYOUT_PATH/tech/drc/run_drc.py" --path="$B" --topcell=$N --run_dir="$O" --precheck_drc --mp=8 > "$O.log" 2>&1
X=$?
echo "PRECHECK_EXIT=$X" | tee -a "$O.log"
# The exit code alone does not say the layout is clean: count the markers in every result database.
MARKS=$(python3 -c "import glob, xml.etree.ElementTree as E; print(sum(1 for d in glob.glob('$O/*.lyrdb') for i in E.parse(d).getroot().iter('item')))")
echo "PRECHECK_MARKERS=$MARKS"
# A layer can differ only in zero-area leftovers, which gds_xor.py lists with area 0.0 and 0 polygons.
[ "$(awk '$1 == "XOR" && ($5 != 0 || $7 != 0)' "$RUN/package/xor.txt" | wc -l)" = 0 ] && grep -q "ONLY_A 0 ONLY_B 0$" "$RUN/package/texts.txt" && [ $X = 0 ] && [ "$MARKS" = 0 ] \
  && echo "PACKAGE_OK $P" || { echo PACKAGE_FAIL; exit 1; }
