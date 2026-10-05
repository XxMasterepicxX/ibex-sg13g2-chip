# PrimePower at the typical corner. Without a VCD this is vectorless: every data input
# toggles at TOGGLE_RATE per clock, so the number is an estimate, not a measurement.
source $env(RUN_CFG)
# Signoff is at the real clock period; the place and route margin only applies inside Fusion Compiler.
unset -nocomplain PNR_MARGIN
if {![info exists PDK]} { error "run_cfg must set PDK" }
source $env(HOME)/flash/pdk_cfg/$PDK/pdk.tcl
foreach {c v t db} $CORNERS { set LIB($c) $db }
set R $OUT/signoff/primepower
file mkdir $R
set_app_var power_enable_analysis true
set_app_var search_path [list . $DB_DIR]
set_app_var link_path   [list * $LIB($POWER_CORNER).db]
# Hard macro timing libraries, optional in run_cfg: MACRO_DB {corner {db ...} ...}.
if {[info exists MACRO_DB] && [dict exists $MACRO_DB $POWER_CORNER]} { set_app_var link_path [concat $link_path [dict get $MACRO_DB $POWER_CORNER]] }

read_verilog $OUT/out/$DESIGN.v
current_design $DESIGN
link_design
source $env(HOME)/flash/flow/constraints.tcl
set_propagated_clock [all_clocks]
read_parasitics -format spef $OUT/signoff/starrc/$DESIGN.spef
if {[info exists env(SAIF)]} {
  read_saif -strip_path $env(SAIF_STRIP) $env(SAIF)
  set mode "saif"
} elseif {[info exists env(VCD)]} {
  read_vcd -strip_path $env(VCD_STRIP) $env(VCD)
  set mode "vcd"
} else {
  set_switching_activity -static_probability 0.5 -toggle_rate 0.2 -base_clock clk \
    [remove_from_collection [all_inputs] [get_ports $CLK_PORT]]
  set mode "vectorless_toggle0.2"
}
update_power
report_switching_activity -list_not_annotated > $R/activity.rpt
report_power -nosplit > $R/power.rpt
report_power -hierarchy -nosplit > $R/power_hier.rpt
puts "FLASH_PP mode=$mode total=[get_attribute [current_design] total_power]"
exit
