if {[llength [info commands flash_values_equal]] == 0} {

proc flash_values_equal {want got} {
  if {$want eq $got} { return 1 }
  if {[string is boolean -strict $want] && [string is boolean -strict $got]} {
    return [expr {bool($want) == bool($got)}]
  }
  if {[string is double -strict $want] && [string is double -strict $got]} {
    return [expr {abs(double($want)-double($got)) <= 1e-9 * max(1.0,abs(double($want)))}]
  }
  return 0
}

}
# Settings that live in the Fusion Compiler session, not the saved block, so every session sources this:
# setup, each resumed stage and the repair ladder.

# Every session needs this, including the repair ladder, which sources only this file.
proc lib_cells_named {names} {
  set pats {}
  foreach n $names { lappend pats */$n }
  return [get_lib_cells $pats]
}

# In-design IC Validator repair, the "ICV in design" Greg described (M3 30:21): FC runs the foundry deck and
# reroutes what it flags. Called at the end of routing and as the repair ladder's last rung.
proc icv_fix_drc {} {
  global ICV_RUNSET GDS_MAP GDS_CELLS EXTRA_GDS OUT
  save_block
  set_app_options -name signoff.check_drc.runset -value $ICV_RUNSET
  set_app_options -name signoff.physical.layer_map_file -value $GDS_MAP
  set_app_options -name signoff.physical.merge_stream_files -value [concat $GDS_CELLS [expr {[info exists EXTRA_GDS] ? $EXTRA_GDS : {}}]]
  set_app_options -name signoff.check_drc.user_defined_options -value {-host_init 4}
  set_app_options -name signoff.fix_drc.user_defined_options -value {-host_init 4}
  set_app_options -name signoff.fix_drc.run_dir -value $OUT/icv_fix
  # Up to three repair loops: on saed_ibex7 one loop left 4 of 627, three left 2.
  # signoff_fix_drc can fail outright on a heavily congested block (sq4 M5 at 85%: ZRT-049, 1347 FC DRCs), and an
  # uncaught error ended the whole run. The repair is an improvement step, so a failure is reported and routing
  # stands as it was; signoff still judges the result.
  if {[catch {signoff_fix_drc -max_number_repair_loop 3} err]} {
    puts "FLASH_ICV_FIX failed: [string range $err 0 200]"
    return -1
  }
  set fh [open $OUT/icv_fix/result_summary.rpt]
  # With nothing to repair the summary has no TOTAL row (saed_ibex8).
  set targeted 0; set remaining 0
  regexp {TOTAL\s*:\s*:\s*:\s*(\d+)\s*:\s*(\d+)} [read $fh] -> targeted remaining
  close $fh
  puts "FLASH_ICV_FIX targeted=$targeted remaining=$remaining"
  check_routes > $OUT/rpt/check_routes_after_icv_fix.rpt
  return $remaining
}

# Hold fixing: by default FC skips any hold violation that needs more than 20 buffers (OPT-209). The IHP SRAM
# needs 0.33 ns of hold at the fast corner, and fast-corner buffers are short, so its loader inputs were left
# failing (flash_soc: -0.098 ns in FC, -0.067 ns in PrimeTime). Synopsys documents this override.
# A single check can only be changed once the design has a policy (NDMUI-925 "Configuration not set").
set_early_data_check_policy -policy normal -if_not_exists
set_early_data_check_policy -policy tolerate -checks opt.sanity_check.large_hold -strategy report_only

# Cells the flow needs that a library locks, optional in pdk.tcl: UNLOCK_CELLS. SAED32 marks its tie cells and
# antenna diode dont_use and dont_touch. Without tie cells FC wired every constant input straight to the VSS rail
# (saed_counter3: 65 pins on 33 cells) and add_tie_cells found none (OPT-200); without the diode, Zroute
# turned diode insertion off (ZRT-302).
if {[info exists UNLOCK_CELLS] && [llength $UNLOCK_CELLS]} {
  set_attribute [lib_cells_named $UNLOCK_CELLS] dont_use false
  set_dont_touch [lib_cells_named $UNLOCK_CELLS] false
}
# Cells that fail the PDK's own signoff deck on their own, optional in pdk.tcl: AVOID_CELLS. Synthesis and
# optimization do without them.
if {[info exists AVOID_CELLS] && [llength $AVOID_CELLS]} {
  set_attribute [lib_cells_named $AVOID_CELLS] dont_use true
}
# RUN_AVOID_CELLS, optional in run_cfg: more cells to do without in one run, for experiments.
if {[info exists RUN_AVOID_CELLS] && [llength $RUN_AVOID_CELLS]} {
  set_attribute [lib_cells_named $RUN_AVOID_CELLS] dont_use true
}

# With no scan chain, FC may still map flops to scan cells and use their scan mux as logic; placement then counts
# them as stitched and stops for want of a scan DEF (sq6 SKY130 Ibex, PLACE-042). There is no chain to reorder.
if {![info exists SCANDEF] && ![info exists DFT_SETUP]} {
  set_early_data_check_policy -checks place.coarse.missing_scan_def -policy tolerate
}

# Optimization may merge the nets of two ports into one Verilog assign, and StarRC then names the SPEF port after
# the net, so the second port loses its parasitics. DC had buffered CVA6's ports, 0 assigns, and FC's optimization
# put 3,021 back, 200 PARA-006, even with set_fix_multiple_port_nets; this option makes it buffer them instead.
set_app_options -name opt.port.eliminate_verilog_assign -value true

# Router app options, name and value pairs: ROUTE_OPTIONS in pdk.tcl for what a PDK needs, RUN_ROUTE_OPTIONS in
# run_cfg for experiments. Some are block scoped, so they are set here, where a block is always open.
# RUN_APP_OPTIONS, optional in run_cfg: any other app options, name and value pairs, for knob sweeps.
foreach v {ROUTE_OPTIONS RUN_ROUTE_OPTIONS RUN_APP_OPTIONS} {
  if {[info exists $v]} { foreach {name value} [set $v] {
    set_app_options -name $name -value $value
    if {$v eq {RUN_APP_OPTIONS}} {
      if {[catch {get_app_option_value -name $name} actual] || ![flash_values_equal $value $actual]} { error "FLASH_SETTING_REJECTED name=$name requested=$value actual=$actual" }
      puts "FLASH_SETTING_APPLIED name=$name value=$actual"
    }
  } }
}

if {$ANTENNA_AWARE} {
  # Antenna rules: define_antenna_rule is not saved with the block. The foundry deck stays the judge.
  lassign $ANT_GLOBAL metal_ratio cut_ratio
  define_antenna_rule -mode $ANTENNA_MODE -diode_mode $ANT_DIODE_MODE -metal_ratio $metal_ratio -cut_ratio $cut_ratio
  foreach {l ratio diode_ratio} $ANT_LAYER_RULES {
    define_antenna_layer_rule -mode $ANTENNA_MODE -layer $l -ratio $ratio -diode_ratio $diode_ratio
  }
  set_app_options -name route.detail.antenna -value true
  set_app_options -name route.detail.hop_layers_to_fix_antenna -value true
  set_app_options -name route.detail.insert_diodes_during_routing -value true
  set_app_options -name route.detail.diode_libcell_names -value $DIODE_CELL
  # Without gate data on ports, Zroute skips every net that touches one (ZRT-311) and reports 0.
  # Gate size 0 gives the port no area and no protection, which is how the foundry deck sees it.
  set_app_options -name route.detail.default_port_external_gate_size -value 0.0
  set_app_options -name route.detail.default_port_external_nwell_size -value 0.0
}

# IO cells whose bond-pad pin, the pin on a port's net, lies farther from the die edge than the cell's centre:
# the cell faces the core. FC's place_io assumes a pad library draws its bond pad at the cell's bottom edge;
# SKY130 draws it at the top, and sky130_chip_v1 was built with every IO cell turned toward the core.
proc io_facing_errors {} {
  lassign [get_attribute [current_block] boundary_bbox] dll dur
  lassign $dll x0 y0
  lassign $dur x1 y1
  set bad {}
  foreach_in_collection pin [get_pins -quiet -of_objects [get_nets -quiet -of_objects [get_ports -quiet -filter "port_type == signal"]] -filter "is_hierarchical == false"] {
    set c [get_cells -of_objects $pin]
    if {![get_attribute $c is_io]} continue
    lassign [get_attribute $c boundary_bbox] cl cu
    lassign [get_attribute $pin bbox] pl pu
    set cx [expr {([lindex $cl 0] + [lindex $cu 0]) / 2.0}]; set cy [expr {([lindex $cl 1] + [lindex $cu 1]) / 2.0}]
    set px [expr {([lindex $pl 0] + [lindex $pu 0]) / 2.0}]; set py [expr {([lindex $pl 1] + [lindex $pu 1]) / 2.0}]
    set dc [list [expr {$cy - $y0}] [expr {$x1 - $cx}] [expr {$y1 - $cy}] [expr {$cx - $x0}]]
    set dp [list [expr {$py - $y0}] [expr {$x1 - $px}] [expr {$y1 - $py}] [expr {$px - $x0}]]
    set side [lsearch -exact $dc [tcl::mathfunc::min {*}$dc]]
    if {[lindex $dp $side] > [lindex $dc $side]} { lappend bad [get_object_name $c] }
  }
  return [lsort -unique $bad]
}

# Turns each cell 180 degrees within its own footprint.
proc io_rotate_180 {cells} {
  set r180 {R0 R180 R180 R0 R90 R270 R270 R90 MX MY MY MX MXR90 MYR90 MYR90 MXR90}
  foreach_in_collection c $cells {
    lassign [lindex [get_attribute $c boundary_bbox] 0] x y
    set_cell_location $c -coordinates [list $x $y] -orientation [dict get $r180 [get_attribute $c orientation]] -ignore_fixed -fixed
    lassign [lindex [get_attribute $c boundary_bbox] 0] nx ny
    if {abs($nx - $x) > 1e-4 || abs($ny - $y) > 1e-4} {
      set_cell_location $c -coordinates [list [expr {2 * $x - $nx}] [expr {2 * $y - $ny}]] -ignore_fixed -fixed
    }
  }
}
