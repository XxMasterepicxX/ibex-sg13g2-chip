#!/bin/bash
# Builds the libraries Synopsys tools read, from IHP's open kit, with your own licenses. Each step skips itself once its output exists.
#   ihp/db        Liberty to .db for the standard cells and IO cells (Library Compiler)
#   ihp/sram_db   the same for the 1024x32 SRAM
#   ihp/ndm       Fusion Compiler reference libraries: standard cells, SRAM and IO cells (Library Manager)
#   ihp/rc        StarRC wire models for the typical, worst and best corners, from text ITF files (grdgenxo)
set -e
source /apps/settings > /dev/null 2>&1 || true
unset PYTHONHOME PYTHONPATH
I=$HOME/flash/ihp
P=$HOME/flash/pdk/IHP-Open-PDK/ihp-sg13g2/libs.ref

lc() { (cd "$1" && lc_shell -f "$2" < /dev/null > lc_output.txt 2>&1); }
lm() { (cd "$1" && rm -rf "$3" && lm_shell -f "$2" < /dev/null > lm_output.txt 2>&1 && test -d "$3"); }

[ "$(ls "$I"/db/*.db 2>/dev/null | wc -l)" = 9 ] || lc "$I/db" compile_libs.tcl
[ "$(ls "$I"/sram_db/*.db 2>/dev/null | wc -l)" = 3 ] || lc "$I/sram_db" compile.tcl
DBS="db/sg13g2_stdcell_slow_1p08V_125C db/sg13g2_stdcell_slow_1p35V_125C db/sg13g2_stdcell_typ_1p20V_25C
  db/sg13g2_stdcell_typ_1p50V_25C db/sg13g2_stdcell_fast_1p32V_m40C db/sg13g2_stdcell_fast_1p65V_m40C
  db/sg13g2_io_slow_1p08V_3p0V_125C db/sg13g2_io_typ_1p2V_3p3V_25C db/sg13g2_io_fast_1p32V_3p6V_m40C
  sram_db/RM_IHPSG13_1P_1024x32_c2_bm_bist_slow_1p08V_125C sram_db/RM_IHPSG13_1P_1024x32_c2_bm_bist_typ_1p20V_25C
  sram_db/RM_IHPSG13_1P_1024x32_c2_bm_bist_fast_1p32V_m55C"
for f in $DBS; do test -s "$I/$f.db"; done
echo "DB_OK $(echo $DBS | wc -w) libraries"

[ -d "$I/ndm/sg13g2_stdcell.ndm" ] || lm "$I/ndm" build_stdcell.tcl sg13g2_stdcell.ndm
[ -d "$I/sram_ndm/sg13g2_sram.ndm" ] || lm "$I/sram_ndm" build.tcl sg13g2_sram.ndm
[ -d "$I/io_ndm/sg13g2_io.ndm" ] || lm "$I/io_ndm" build.tcl sg13g2_io.ndm
echo "NDM_OK"

# Each wire model: a .nxtgrd for StarRC and a .tluplus for Fusion Compiler, from the same ITF. grdgenxo names the
# .nxtgrd after the ITF's TECHNOLOGY line, so it is renamed after the corner.
grd() {
  local d=$1 itf=$2 base=${2%.itf}
  [ -f "$d/$base.nxtgrd" ] && [ -f "$d/$base.tluplus" ] && return 0
  local tech=$(awk '$1 == "TECHNOLOGY" {print $3}' "$d/$itf")
  # grdgenxo's exit code is not reliable, so each step is judged by the file it writes; under set -e its exit
  # code must not end the step.
  (cd "$d" && { [ -s "$base.tluplus" ] || grdgenxo -itf2TLUPlus -i "$itf" -o "$base.tluplus" > tluplus.log 2>&1 || true; }
     grdgenxo "$itf" > nxtgrd.log 2>&1 || true; if [ -s "$tech.nxtgrd" ]; then mv "$tech.nxtgrd" "$base.nxtgrd"; fi)
  test -s "$d/$base.nxtgrd" && test -s "$d/$base.tluplus"
}
grd "$I/rc" sg13g2_typ.itf &
grd "$I/rc/rcmax" sg13g2_spec_rcmax.itf &
grd "$I/rc/rcmin" sg13g2_spec_rcmin.itf &
wait
for f in rc/sg13g2_typ rc/rcmax/sg13g2_spec_rcmax rc/rcmin/sg13g2_spec_rcmin; do
  test -s "$I/$f.nxtgrd" && test -s "$I/$f.tluplus"
done
echo "RC_OK"
