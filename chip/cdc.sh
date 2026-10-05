#!/bin/bash
# SpyGlass clock-domain-crossing and reset check of flash_soc, the core without its pad ring, in functional mode.
# The loader inputs sclk, sdi and load_en come from the board with no timing relation to clk, so they belong to a
# separate virtual clock; rst_n is an asynchronous reset. The SRAM and the clock-gate cell come from Liberty.
# It checks the RTL, so it only needs to run again after an RTL change.
# usage: cdc.sh <run_folder>       results in <run_folder>/cdc
RUN=$(readlink -f "$1"); [ -f "$RUN/run_cfg.tcl" ] || { echo "usage: cdc.sh <run_folder>"; exit 1; }
O=$RUN/cdc
D=$HOME/flash/designs/flash_soc/rtl_v2
L=$HOME/flash/pdk/IHP-Open-PDK/ihp-sg13g2/libs.ref
rm -rf "$O"; mkdir -p "$O" && cd "$O" || exit 1
source /apps/settings > /dev/null 2>&1
cat > cdc.prj <<EOF
new_project flash_soc_cdc -projectwdir $O/work -force
read_file -type verilog $D/flash_soc.v
read_file -type verilog $D/ibex_nogate.v
read_file -type verilog $D/prim_clock_gating_ihp.v
read_file -type gateslib $L/sg13g2_sram/lib/RM_IHPSG13_1P_1024x32_c2_bm_bist_typ_1p20V_25C.lib
read_file -type gateslib $L/sg13g2_stdcell/lib/sg13g2_stdcell_typ_1p20V_25C.lib
read_file -type sgdc $HOME/flash/chip/flash_soc.sgdc
set_option top flash_soc
set_option enableSV09 yes
set_option language_mode mixed
current_methodology \$env(SPYGLASS_HOME)/GuideWare/latest/block/rtl_handoff
current_goal cdc/cdc_setup_check
run_goal
write_report moresimple > $O/setup_check.rpt
current_goal cdc/cdc_verify_struct
run_goal
write_report moresimple > $O/verify_struct.rpt
current_goal cdc/cdc_verify
run_goal
write_report moresimple > $O/verify.rpt
exit -force
EOF
sg_shell -tcl cdc.prj > sg_shell.log 2>&1
grep -h "Synchronized\|Unsynchronized\|Reset" verify.rpt | head -20
echo CDC_DONE
