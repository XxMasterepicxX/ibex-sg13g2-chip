#!/bin/bash
# IHP-Open-PDK at the commit the chip was signed off with. Apache-2.0, from IHP's public repository.
# Also derives the metal fill macro the flow uses: IHP's own, with the fill kept 1.0 um from existing metal on
# Metal2 to Metal5 instead of 1.5 to 2 um. IHP's spacing left the chip's centre under 25% density on Metal2,
# Metal3 and Metal5.
set -e
P=$HOME/flash/pdk/IHP-Open-PDK
COMMIT=5e6d592e4002946a4616f798c357f0f3c06cf3b6
if [ "$(git -C "$P" rev-parse HEAD 2>/dev/null)" != "$COMMIT" ]; then
  mkdir -p "$(dirname "$P")"
  [ -d "$P/.git" ] || git clone --filter=blob:none https://github.com/IHP-GmbH/IHP-Open-PDK.git "$P"
  git -C "$P" fetch --quiet origin
  git -C "$P" checkout --quiet "$COMMIT"
fi
# KLayout loads IHP's PyCell library at start, and it needs these two submodules.
git -C "$P" submodule update --quiet --init ihp-sg13g2/libs.tech/klayout/python/pycell4klayout-api \
  ihp-sg13g2/libs.tech/klayout/python/pypreprocessor
test -d "$P/ihp-sg13g2/libs.tech/klayout/python/pycell4klayout-api/source/python/cni"
echo "PDK_OK $(git -C "$P" rev-parse HEAD)"

SRC=$P/ihp-sg13g2/libs.tech/klayout/tech/macros/sg13g2_filler_Metal.lym
OUT=$HOME/flash/ihp/fill/sg13g2_filler_Metal_mid.lym
sed -E "s/('distance_m[2-5]' => )[0-9.]+/\11.0/" "$SRC" > "$OUT"
[ "$(diff "$SRC" "$OUT" | grep -c "^>")" = 4 ] || { echo "FILL_MACRO_FAIL the IHP macro changed; check $OUT"; exit 1; }
echo "FILL_MACRO_OK $OUT"

# The SRAM LEF with its supply pins named VDD, VSS and VDDARRAY, as in its Liberty file and the chip's DEF, instead
# of VDD!, VSS! and VDDARRAY!. Nothing else changes.
L=$P/ihp-sg13g2/libs.ref/sg13g2_sram/lef/RM_IHPSG13_1P_1024x32_c2_bm_bist.lef
mkdir -p "$HOME/flash/ihp/sram_lef"
sed -e 's/\bVDD!/VDD/g' -e 's/\bVSS!/VSS/g' -e 's/\bVDDARRAY!/VDDARRAY/g' "$L" > "$HOME/flash/ihp/sram_lef/$(basename "$L")"
echo "SRAM_LEF_OK"
