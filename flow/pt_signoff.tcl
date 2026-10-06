# PrimeTime SI signoff for one corner at the real clock period (no place and route margin).
source $env(RUN_CFG)
# Signoff is at the real clock period; the place and route margin only applies inside Fusion Compiler.
unset -nocomplain PNR_MARGIN
set CORNER $env(CORNER)
set S $OUT/signoff
if {![info exists PDK]} { error "run_cfg must set PDK" }
source $env(HOME)/flash/pdk_cfg/$PDK/pdk.tcl
foreach {c v t db} $CORNERS { set LIB($c) $db }
# The scan-shift run of signoff's ptshift step, PT_MODE=shift, writes beside the functional one.
set TIMING_MODE [expr {[info exists env(PT_MODE)] ? $env(PT_MODE) : "func"}]
set R $S/pt_$CORNER[expr {$TIMING_MODE eq "shift" ? "_shift" : ""}]
# PT_ECO=1, from flow/eco.sh: after timing, fix setup at this corner and write the changes for Fusion Compiler.
set eco [expr {[info exists env(PT_ECO)] && $env(PT_ECO)}]
set eco_type [expr {[info exists env(PT_ECO_TYPE)] ? $env(PT_ECO_TYPE) : "setup"}]
if {$eco} { set R $S/eco_pt_${CORNER}_$eco_type[expr {$TIMING_MODE eq "shift" ? "_shift" : ""}] }
file mkdir $R

set_app_var search_path [list . $DB_DIR]
set_app_var link_path   [list * $LIB($CORNER).db]
# Hard macro timing libraries, optional in run_cfg: MACRO_DB {corner {db ...} ...}.
if {[info exists MACRO_DB] && [dict exists $MACRO_DB $CORNER]} { set_app_var link_path [concat $link_path [dict get $MACRO_DB $CORNER]] }
set_app_var si_enable_analysis true
set_app_var timing_report_unconstrained_paths true

read_verilog $OUT/out/$DESIGN.v
current_design $DESIGN
link_design
# A design with its own UPF: Fusion Compiler's final power intent, and each supply's voltage at this corner, so
# every cell is timed with the library characterized at its own supply.
if {[file exists $OUT/out/$DESIGN.upf]} {
  load_upf $OUT/out/$DESIGN.upf
  foreach {c v t db} $CORNERS { if {$c eq $CORNER} { set_voltage $v -object_list [get_supply_nets VDD] } }
  set_voltage 0.0 -object_list [get_supply_nets VSS]
  if {[info exists SUPPLY_VOLTAGES]} {
    dict for {net vs} $SUPPLY_VOLTAGES { set_voltage [dict get $vs $CORNER] -object_list [get_supply_nets $net] }
  }
}
source $env(HOME)/flash/flow/constraints.tcl
set_propagated_clock [all_clocks]
if {$eco} {
  read_parasitics -format spef -keep_capacitive_coupling $OUT/diagnostic/fresh_nominal/$DESIGN.spef
} else {
  read_parasitics -format spef -keep_capacitive_coupling $S/starrc/$DESIGN.spef
}
report_annotated_parasitics -check > $R/annotation.rpt
# The pin-to-pin nets without parasitics, by name, in parasitics_command.log; check.py counts from this list.
report_annotated_parasitics -check -pin_to_pin_nets -list_not_annotated -max_nets 1000000 > /dev/null
update_timing -full
check_timing -verbose > $R/check_timing.rpt
report_global_timing > $R/global_timing.rpt
# -max_paths alone reports violators only, so a passing run showed no path at all; the slack limit lifts that.
report_timing -delay_type max -max_paths 20 -slack_lesser_than 1000 -nosplit -input_pins -transition_time -capacitance -crosstalk_delta > $R/setup.rpt
report_timing -delay_type min -max_paths 20 -slack_lesser_than 1000 -nosplit -input_pins -transition_time -capacitance -crosstalk_delta > $R/hold.rpt
report_constraint -all_violators -nosplit > $R/violators.rpt
report_si_bottleneck > $R/si_bottleneck.rpt
# Crosstalk glitches. SI above changes delays; this checks the bump an aggressor puts on a quiet net against the
# receiving pin's noise immunity, since a bump can flip a latch without any timing path failing.
update_noise
report_noise -all_violators -nosplit > $R/noise_violators.rpt
redirect -variable noise_rpt { report_noise -nosplit }
set noise_slacks [lmap {m v} [regexp -all -inline -line {\s(-?\d+\.\d+)\s*$} $noise_rpt] {set v}]
set noise_worst [expr {[llength $noise_slacks] ? [tcl::mathfunc::min {*}$noise_slacks] : "none"}]
set noise_viol [llength [regexp -all -inline -line {\s-\d+\.\d+\s*$} [read [set fh [open $R/noise_violators.rpt]]]]]
close $fh
puts "FLASH_PT_NOISE corner=$CORNER worst_slack=$noise_worst violators=$noise_viol"
set wns_setup [get_attribute [get_timing_paths -delay_type max] slack]
set wns_hold  [get_attribute [get_timing_paths -delay_type min] slack]
# A path into a latch, such as the Ibex clock-gate latch, reports slack 0 whenever it borrows, so the WNS above
# can read exactly 0. The worst edge-triggered endpoint shows the margin.
set wns_flops ""
foreach_in_collection p [get_timing_paths -delay_type max -max_paths 500 -slack_lesser_than 1000] {
  if {[get_attribute $p endpoint_is_level_sensitive]} { continue }
  set s [get_attribute $p slack]
  if {$wns_flops eq "" || $s < $wns_flops} { set wns_flops $s }
}
puts "FLASH_PT corner=$CORNER period=$PERIOD_NS setup_wns=$wns_setup hold_wns=$wns_hold setup_wns_flops=$wns_flops"
if {$eco} {
  # PT_ECO_TYPE setup, the default: cell sizing only, which moves no cell, so Fusion Compiler legalizes each
  # resized cell in place and reroutes only its nets. hold: sizing, plus delay buffers from ECO_HOLD_BUFFERS in
  # pdk.tcl if it names any; Fusion Compiler places those. drc: max transition and capacitance, by sizing.
  # noise: the glitch violators above, by upsizing the victim's driver, and by buffers from ECO_BUFFERS in
  # pdk.tcl if it names any, which split a victim net that sizing alone cannot fix. Every corner is signed off
  # again afterwards, so a loss elsewhere cannot hide.
  switch $eco_type {
    setup { fix_eco_timing -type setup -setup_margin 0.10 -methods {size_cell} }
    hold {
      if {[info exists ECO_HOLD_BUFFERS]} {
        fix_eco_timing -type hold -hold_margin 0.15 -methods {size_cell insert_buffer} -buffer_list $ECO_HOLD_BUFFERS
      } else {
        fix_eco_timing -type hold -methods {size_cell}
      }
    }
    drc { fix_eco_drc -type {max_transition max_capacitance} -methods {size_cell insert_buffer} -buffer_list $ECO_BUFFERS }
    noise {
      if {[info exists ECO_BUFFERS]} {
        fix_eco_drc -type noise -methods {size_cell insert_buffer} -buffer_list $ECO_BUFFERS
      } else {
        fix_eco_drc -type noise -methods {size_cell}
      }
    }
    default { error "PT_ECO_TYPE must be setup, hold, drc or noise, not $eco_type" }
  }
  write_changes -format icc2tcl -output $R/eco_changes.tcl
  set wns_eco [get_attribute [get_timing_paths -delay_type max] slack]
  set whs_eco [get_attribute [get_timing_paths -delay_type min] slack]
  update_noise
  redirect -variable noise_after { report_noise -all_violators -nosplit }
  set noise_viol_eco [llength [regexp -all -inline -line {\s-\d+\.\d+\s*$} $noise_after]]
  # write_changes writes no file when there is nothing to change.
  set changes 0
  if {[file exists $R/eco_changes.tcl]} {
    set changes [regexp -all -line {^.+$} [read [set fh [open $R/eco_changes.tcl]]]]
    close $fh
  }
  puts "FLASH_PT_ECO corner=$CORNER type=$eco_type mode=$TIMING_MODE setup_wns_before=$wns_setup setup_wns_after=$wns_eco hold_wns_before=$wns_hold hold_wns_after=$whs_eco noise_violators_before=$noise_viol noise_violators_after=$noise_viol_eco changes=$changes"
  exit
}
# Delays from the signoff extraction, for gate-level simulation with timing.
write_sdf -version 3.0 -context verilog $R/$DESIGN.$CORNER.sdf
exit
