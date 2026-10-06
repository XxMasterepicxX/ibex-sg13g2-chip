# Digital flow in Fusion Compiler, RTL to routed GDS. PDK-independent: every layer name, cell name
# and rule value comes from pdk_cfg/<PDK>/pdk.tcl.
# Run config: DESIGN RTL_FILES INC_DIRS DEFINES CLK_PORT PERIOD_NS PNR_MARGIN UTIL MAX_LAYER OUT PDK.
source $env(RUN_CFG)
if {![info exists PDK]} { error "run_cfg must set PDK" }
source $env(HOME)/flash/pdk_cfg/$PDK/pdk.tcl
if {![info exists MAX_LAYER]}     { set MAX_LAYER $MAX_ROUTE_LAYER }
if {![info exists RING_W]}        { set RING_W 2.0 }
if {![info exists CORE_OFFSET]}   { set CORE_OFFSET 8 }
if {![info exists ANTENNA_AWARE]} { set ANTENNA_AWARE $ANT_ENABLE }
if {![info exists ANTENNA_MODE]}  { set ANTENNA_MODE $ANT_MODE }
if {[info exists NDM_OVERRIDE]} { set NDM_LIB $NDM_OVERRIDE }
# Hard macros, optional in run_cfg: EXTRA_NDM libraries, EXTRA_GDS layouts, MACROS {inst x y orient ...},
# MACRO_PG {pin net ...} for macro supply pins with their own names, MACRO_HALO keepout in um.
if {[info exists EXTRA_NDM]} { lappend NDM_LIB {*}$EXTRA_NDM }
foreach {v d} {EXTRA_GDS {} MACROS {} MACRO_PG {} MACRO_HALO 10.0 PLACE_BLOCKAGES {} HOTSPOT_BLOCKAGES {}} { if {![info exists $v]} { set $v $d } }
# Pad ring, optional in run_cfg: IO_RING {bottom {pads} right {pads} top {pads} left {pads}}, pad instance names
# in placement order. The pads' IO supply rails get their own nets, IOVDD and IOVSS.
if {![info exists IO_RING]} { set IO_RING {} }
# FC checks the core supplies. IO rails join around the ring only inside the corner cells' layout: the IHP corner
# LEF gives each supply two separate 2 um edge stubs, so FC's abstract shows every side as its own island.
# LVS on the real GDS judges the IO supply nets.
set PG_CHECK_NETS [concat {VDD VSS} [expr {[info exists VOLTAGE_AREAS] ? [lsort -unique [lmap {va net box} $VOLTAGE_AREAS {set net}]] : {}}]]
set FLOW $env(FLOW_DIR)

file mkdir $OUT/rpt $OUT/out
set_host_options -max_cores 8
set_app_options -name shell.common.report_default_significant_digits -value 3



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
proc flash_verify_requested_options {} {
  if {![info exists ::RUN_APP_OPTIONS]} { return }
  if {[llength $::RUN_APP_OPTIONS] % 2} { error "FLASH_SETTING_REJECTED odd RUN_APP_OPTIONS list" }
  foreach {name value} $::RUN_APP_OPTIONS {
    if {[catch {get_app_option_value -name $name} actual] || ![flash_values_equal $value $actual]} {
      error "FLASH_SETTING_REJECTED name=$name requested=$value actual=$actual"
    }
    puts "FLASH_SETTING_APPLIED name=$name value=$actual"
  }
}
proc flash_set_routing_layers {min max} {
  if {[catch {set_ignored_layers -min_routing_layer $min -max_routing_layer $max} err]} {
    error "FLASH_SETTING_REJECTED routing_layers min=$min max=$max reason=$err"
  }
  redirect -variable report { report_ignored_layers }
  puts "FLASH_ROUTING_LAYER_REPORT_BEGIN"
  puts $report
  puts "FLASH_ROUTING_LAYER_REPORT_END"
  foreach {kind value} [list min $min max $max] {
    set found 0
    foreach line [regexp -all -inline -line {^.*$} $report] {
      if {[regexp -nocase "$kind.*rout.*layer" $line] && [lsearch -exact [regexp -all -inline {[^[:space:]:=,]+} $line] $value] >= 0} { set found 1 }
    }
    if {!$found} { error "FLASH_SETTING_REJECTED routing_$kind requested=$value readback_not_found" }
  }
  puts "FLASH_ROUTING_LAYERS_APPLIED min=$min max=$max"
}

proc flash_set_checked_app_option {name value} {
  if {[catch {set_app_options -name $name -value $value} msg]} {
    error "FLASH_SETTING_REJECTED name=$name requested=$value reason=$msg"
  }
  if {[catch {get_app_option_value -name $name} actual] || ![flash_values_equal $value $actual]} {
    error "FLASH_SETTING_REJECTED name=$name requested=$value actual=$actual"
  }
  puts "FLASH_SETTING_APPLIED name=$name value=$actual"
}

set STAGES {setup synth floorplan pg place cts route final}
set START_AT [expr {[info exists env(START_AT)] ? $env(START_AT) : "setup"}]
# One guidance file per session, so a resumed session cannot overwrite the guidance of earlier ones.
set_svf $OUT/out/$DESIGN.$START_AT.svf
proc run_stage {name} {
  global STAGES START_AT OUT DESIGN
  set i [lsearch $STAGES $name]
  set s [lsearch $STAGES $START_AT]
  if {$i < $s} { return 0 }
  if {$i == $s && $s > 0} {
    open_lib $OUT/$DESIGN.nlib
    # An ECO resumes from the last final block, so it keeps every earlier ECO.
    if {!($START_AT eq "final" && [info exists ::env(ECO_CHANGES)] && ![catch {open_block $DESIGN/final}])} {
      open_block $DESIGN/[lindex $STAGES [expr {$s - 1}]]
    }
    current_scenario func_[lindex $::CORNERS 0]
    # Session-only settings (hold policy, antenna rules) are not saved with the block.
    uplevel #0 {source $FLOW/session.tcl}
  }
  return 1
}

proc stage_done {name} {
  global OUT DESIGN
  # An ECO session's block is already named final; if save_block -as rejects its own name, a plain save does it.
  if {[catch {save_block -as $DESIGN/$name}]} { save_block }
  report_qor -summary > $OUT/rpt/${name}_qor.rpt
  # A checkpoint: horizontal and vertical overflow per layer at each stage with a placement.
  if {$name in {place cts route}} { catch {report_congestion -rerun_global_router > $OUT/rpt/${name}_congestion.rpt} }
  flash_verify_requested_options
  puts "FLASH_STAGE_DONE $name"
  # STOP_AFTER=<stage> ends the session at that checkpoint; START_AT resumes from it.
  if {[info exists ::env(STOP_AFTER)] && $::env(STOP_AFTER) eq $name} { puts "FLASH_STOPPED_AFTER $name"; exit }
}

# Primary supply pins connect automatically; separate body pins, EXTRA_PG in pdk.tcl, do not.
# The pad ring: pads, IO fillers and corners.
proc io_ring_cells {} {
  global IO_FILLERS IO_CORNER
  get_cells -quiet -physical_context -filter "is_io == true || [join [lmap r [concat $IO_FILLERS $IO_CORNER] {set r "ref_name == $r"}] { || }]"
}

proc pg_connect {} {
  global EXTRA_PG MACRO_PG IO_RING IO_SUPPLY_PINS
  connect_pg_net -automatic
  foreach {pin net} [concat $EXTRA_PG $MACRO_PG] {
    set pins [get_pins -quiet -physical_context */$pin]
    if {[sizeof_collection $pins]} { connect_pg_net -net [get_nets $net] $pins }
  }
  # IO fillers and corners are created after the power intent maps the pads' supply pins, so the automatic
  # connection would give their supply pins no net or the core's.
  if {[llength $IO_RING] && [info exists IO_SUPPLY_PINS]} {
    set ring [io_ring_cells]
    foreach {pin net} $IO_SUPPLY_PINS {
      set pins [get_pins -quiet -of_objects $ring -filter "name == $pin"]
      if {[sizeof_collection $pins]} { connect_pg_net -net [get_nets $net] $pins }
    }
  }
}

# ---------------------------------------------------------------- setup
if {[run_stage setup]} {
  # NDM_LIB: the main library first (it carries the technology), then any physical-only libraries.
  create_lib $OUT/$DESIGN.nlib -use_technology_lib [lindex $NDM_LIB 0] -ref_libs $NDM_LIB
  set_app_options -name hdlin.elaborate.ff_infer_async_set_reset -value true
  set search_path [concat . $INC_DIRS]
  # NETLIST_IN, optional in run_cfg: a netlist already mapped, and scanned, by Design Compiler.
  if {[info exists NETLIST_IN]} {
    read_verilog -top $DESIGN $NETLIST_IN
    link_block
  } else {
    # A failed analyze leaves units from earlier runs in the WORK library, and elaborate would build from them.
    if {![analyze -format sverilog -define $DEFINES $RTL_FILES]} { puts "FLASH_ERROR analyze failed"; exit 1 }
    if {![elaborate $DESIGN]} { puts "FLASH_ERROR elaborate failed"; exit 1 }
    set_top_module $DESIGN
  }

  # UPF_FILE, optional in run_cfg: the power intent for a design with more than one domain. It must define
  # supply nets VDD and VSS for the top domain; SUPPLY_VOLTAGES gives the others their voltage per corner.
  if {[info exists UPF_FILE]} {
    load_upf $UPF_FILE
  } else {
    create_power_domain TOP
    create_supply_port VDD
    create_supply_port VSS
    create_supply_net VDD
    create_supply_net VSS
    connect_supply_net VDD -ports VDD
    connect_supply_net VSS -ports VSS
  }
  if {[llength $IO_RING]} {
    # Only the IO supplies the ring uses; an unused IOVDD or IOVSS port would be an extra net in LVS.
    foreach n {IOVDD IOVSS} {
      if {$n in [dict values $IO_SUPPLY_PINS]} { create_supply_port $n; create_supply_net $n; connect_supply_net $n -ports $n }
    }
    # The pads' IO supply pins join these nets in the power intent too. Otherwise FC gives them the core supply,
    # matches no IO library, and times every pad with the slow library at all corners.
    # IO_SUPPLY_PINS {pin net ...} comes from pdk.tcl.
    foreach {pin net} $IO_SUPPLY_PINS {
      connect_supply_net $net -ports [get_pins -of_objects [get_cells -filter is_io==true] -filter "name == $pin"]
    }
  }
  if {![info exists UPF_FILE]} { set_domain_supply_net TOP -primary_power_net VDD -primary_ground_net VSS }
  commit_upf

  read_parasitic_tech -tlup $TLUP -layermap $RC_MAP -name typ

  remove_scenarios -all
  remove_corners -all
  remove_modes -all
  create_mode func
  foreach {c v t db} $CORNERS {
    create_corner $c
    set_parasitic_parameters -corners $c -early_spec typ -late_spec typ
    set_voltage $v   -corners $c -object_list [get_supply_nets VDD]
    set_voltage 0.0  -corners $c -object_list [get_supply_nets VSS]
    if {[info exists SUPPLY_VOLTAGES]} {
      dict for {net vs} $SUPPLY_VOLTAGES { set_voltage [dict get $vs $c] -corners $c -object_list [get_supply_nets $net] }
    }
    if {[sizeof_collection [get_supply_nets -quiet IOVDD]]} { set_voltage [dict get $IO_VDD $c] -corners $c -object_list [get_supply_nets IOVDD] }
    if {[sizeof_collection [get_supply_nets -quiet IOVSS]]} { set_voltage 0.0 -corners $c -object_list [get_supply_nets IOVSS] }
    set_temperature $t -corners $c
    # FC picks each corner's library by process, voltage and temperature, and falls back to the nearest match when
    # no library has the process number. CORNER_PROCESS, optional in pdk.tcl, gives each corner its own.
    set_process_number [expr {[info exists CORNER_PROCESS] ? [dict get $CORNER_PROCESS $c] : 1}] -corners $c
    create_scenario -name func_$c -mode func -corner $c
    current_scenario func_$c
    set TIMING_MODE func
    source $FLOW/constraints.tcl
  }
  # Scan shift, for designs with scan chains: a hold-only scenario per corner, so optimization fixes the chains'
  # hold too.
  set shift_mode [expr {[info exists SCANDEF] || [info exists DFT_SETUP]}]
  if {$shift_mode} {
    create_mode shift
    foreach {c v t db} $CORNERS {
      create_scenario -name shift_$c -mode shift -corner $c
      current_scenario shift_$c
      set TIMING_MODE shift
      source $FLOW/constraints.tcl
    }
    set TIMING_MODE func
  }
  # First corner is the slowest (setup), last the fastest (hold); the power corner carries power.
  set corner_names {}
  foreach {c v t db} $CORNERS { lappend corner_names $c }
  foreach c $corner_names {
    set is_slow [expr {$c eq [lindex $corner_names 0]}]
    set is_fast [expr {$c eq [lindex $corner_names end]}]
    set is_pwr  [expr {$c eq $POWER_CORNER}]
    set_scenario_status func_$c -active true -setup [expr {!$is_fast}] -hold [expr {!$is_slow}] \
      -leakage_power $is_pwr -dynamic_power $is_pwr -max_transition true -max_capacitance true
  }
  if {$shift_mode} {
    foreach c $corner_names { set_scenario_status shift_$c -active true -setup false -hold true -leakage_power false -dynamic_power false }
  }
  current_scenario func_[lindex $corner_names 0]

  flash_set_routing_layers $ROUTE_MIN_LAYER $MAX_LAYER
  # Crosstalk-aware timing, routing and optimization, so Fusion Compiler sees what PrimeTime SI signs off.
  set_app_options -name time.si_enable_analysis -value true
  set_app_options -name route.global.crosstalk_driven -value true
  set_app_options -name route.track.crosstalk_driven -value true
  source $FLOW/session.tcl
  if {$ANTENNA_AWARE} { report_antenna_rules > $OUT/rpt/antenna_rules.rpt }
  report_scenarios > $OUT/rpt/scenarios.rpt
  report_corners  > $OUT/rpt/corners.rpt
  stage_done setup
}

# ---------------------------------------------------------------- synthesis
# Synthesize to real cells before sizing the floorplan: utilization is a ratio of
# mapped cell area to core area, and unmapped logic has no real area yet.
if {[run_stage synth]} {
  # One net on two ports: StarRC names a SPEF port after its DEF net, so the second port loses its parasitics in
  # PrimeTime (PARA-006). A buffer per port gives each its own net. It acts in compile_fusion only; session.tcl
  # keeps optimization from merging them.
  set_fix_multiple_port_nets -all -buffer_constants
  if {[info exists NETLIST_IN]} {
    # Already mapped. The scan DEF from Design Compiler lets placement reorder the chains.
    if {[info exists SCANDEF]} { read_def $SCANDEF }
  } else {
    # SAFETY_TMR, optional in run_cfg: {distance_um register_pattern ...}. Synthesis replaces each matching register
    # by three and a voter; placement keeps the three apart by the distance, and their clock and reset come from
    # separate tree branches. set_safety_register_rule asks for the replacement; mark_safety_register only records
    # redundancy that already exists.
    if {[info exists SAFETY_TMR]} {
      create_safety_register_rule -type triple_mode -name tmr -distance [lindex $SAFETY_TMR 0] -split_pin_types {clock reset}
      set regs {}
      foreach pat [lrange $SAFETY_TMR 1 end] {
        append_to_collection regs [get_cells -hierarchical -quiet -filter "is_sequential==true && full_name=~$pat"]
      }
      set_safety_register_rule -rule tmr -registers $regs
      puts "FLASH_TMR_REGISTERS [sizeof_collection $regs]"
    }
    set pads [get_cells -hierarchical -quiet -filter {ref_name =~ sg13g2_IOPad*}]
    set_dont_touch $pads true
    puts "FLASH_IHP_PADS_PRE_SYNTH [sizeof_collection $pads]"
    if {[sizeof_collection $pads] != 25} {error "Expected 25 IHP pads before synthesis"}
    compile_fusion -to logic_opto
    if {[info exists SAFETY_TMR]} {
      report_safety_register_groups > $OUT/rpt/safety_groups.rpt
      puts "FLASH_TMR_FLOPS [sizeof_collection [get_cells -hierarchical -filter is_sequential==true]]"
    }
  }
  # Scan insertion, in the order of the Synopsys RM compile step: DFT signals from the run's DFT_SETUP file,
  # test protocol, DFT DRC, preview, insert_dft, then a protocol per test mode for ATPG.
  if {[info exists DFT_SETUP]} {
    source $DFT_SETUP
    create_test_protocol
    dft_drc -test_mode all_dft > $OUT/rpt/dft_drc_pre.rpt
    preview_dft > $OUT/rpt/preview_dft.rpt
    insert_dft
    foreach mode [all_test_modes] {
      dft_drc -test_mode $mode > $OUT/rpt/dft_drc_$mode.rpt
      write_test_protocol -test_mode $mode -output $OUT/out/$DESIGN.$mode.synth.spf
    }
    report_scan_chain > $OUT/rpt/scan_chain_synth.rpt
    puts "FLASH_SCAN_REPORT $OUT/rpt/scan_chain_synth.rpt"
  }
  puts "FLASH_IHP_PADS_POST_DFT [sizeof_collection [get_cells -hierarchical -quiet -filter {ref_name =~ sg13g2_IOPad*}]]"
  write_verilog -exclude {pg_objects leaf_module_declarations physical_only_cells empty_modules} $OUT/out/$DESIGN.synth.v
  report_area > $OUT/rpt/area_synth.rpt
  report_timing -scenarios [all_scenarios] -max_paths 5 > $OUT/rpt/timing_synth.rpt
  report_qor -summary > $OUT/rpt/qor_synth.rpt
  stage_done synth
}

# ---------------------------------------------------------------- floorplan
if {[run_stage floorplan]} {
  # A fixed core size keeps macro coordinates meaningful; otherwise the core follows utilization.
  if {[info exists CORE_SIZE]} {
    initialize_floorplan -side_length $CORE_SIZE -core_offset $CORE_OFFSET
  } else {
    # ASPECT, optional in run_cfg: the core's side_ratio {1 ASPECT}; square without it.
    initialize_floorplan -core_utilization $UTIL -core_offset $CORE_OFFSET -shape R \
      {*}[expr {[info exists ASPECT] ? [list -side_ratio [list 1 $ASPECT]] : {}}]
  }
  # MACROS coordinates are die coordinates. A macro outside the core would sit in the pad ring.
  lassign [get_attribute [get_core_area] bbox] mcl mcu
  foreach {inst x y orient} $MACROS {
    set_cell_location [get_cells $inst] -coordinates [list $x $y] -orientation $orient -fixed
    lassign [get_attribute [get_cells $inst] boundary_bbox] ml mu
    if {[lindex $ml 0] < [lindex $mcl 0] || [lindex $ml 1] < [lindex $mcl 1] || [lindex $mu 0] > [lindex $mcu 0] || [lindex $mu 1] > [lindex $mcu 1]} {
      error "Macro $inst at $ml $mu lies outside the core $mcl $mcu"
    }
  }
  if {[info exists VOLTAGE_AREAS]} {
    # VA_GUARD, optional in run_cfg: a gap around each area in um. Without it a row's rail inside the area meets the
    # neighbouring rail of the other supply end to end.
    set guard [expr {[info exists VA_GUARD] ? [list -guard_band [list [list $VA_GUARD $VA_GUARD]]] : {}}]
    # The core rails run the full width of the core's bottom and top edges, so an area on either edge would have the
    # primary supply's rail under its edge row's pins, a short check_pg_connectivity reports only as floating cells.
    lassign [get_attribute [get_core_area] bbox] core_ll core_ur
    set cy0 [lindex $core_ll 1]
    set cy1 [lindex $core_ur 1]
    set g [expr {[info exists VA_GUARD] ? $VA_GUARD : 0}]
    foreach {va net box} $VOLTAGE_AREAS {
      lassign $box ll ur
      if {[lindex $ll 1] <= $cy0 + $g || [lindex $ur 1] >= $cy1 - $g} {
        error "voltage area $va $box must keep VA_GUARD off the core's bottom and top edges, $cy0 and $cy1"
      }
      create_voltage_area -power_domains $va -region [list $box] {*}$guard
    }
    report_voltage_areas > $OUT/rpt/voltage_areas.rpt
  }
  if {[llength $MACROS]} {
    set macro_cells [get_cells [lmap {i x y o} $MACROS {set i}]]
    create_keepout_margin -type hard -outer [list $MACRO_HALO $MACRO_HALO $MACRO_HALO $MACRO_HALO] $macro_cells
    puts "FLASH_MACROS [get_object_name $macro_cells]"
  }
  # Hard placement blockages, optional in run_cfg: PLACE_BLOCKAGES {{{llx lly} {urx ury}} ...}. Cells in the
  # strips beside a macro row would sit where rails are cut and no mesh stripe lands, and float.
  set i 0
  foreach box $PLACE_BLOCKAGES { create_placement_blockage -boundary $box -type hard -name flash_pb[incr i] }
  if {[llength $HOTSPOT_BLOCKAGES] % 2} {
    error "FLASH_HOTSPOT_BLOCKAGE_REJECTED odd box/percentage list"
  }
  set hs_requested [expr {[llength $HOTSPOT_BLOCKAGES] / 2}]
  set hs_i 0
  foreach {box pct} $HOTSPOT_BLOCKAGES {
    if {[catch {create_placement_blockage -boundary $box -type partial -blocked_percentage $pct -name flash_hs[incr hs_i]} hs_err]} {
      puts "FLASH_HOTSPOT_BLOCKAGE_REJECTED box=$box pct=$pct reason=$hs_err"
    }
  }
  set hs_created [sizeof_collection [get_placement_blockages -quiet flash_hs*]]
  if {$hs_created != $hs_requested} {
    error "FLASH_HOTSPOT_BLOCKAGE_COUNT_MISMATCH requested=$hs_requested created=$hs_created"
  }
  puts "FLASH_HOTSPOT_BLOCKAGES_APPLIED requested=$hs_requested created=$hs_created"
  puts "FLASH_TRACKS [sizeof_collection [get_tracks]]"
  # Every port, including the clock, gets a real location; an unplaced clock port
  # silently disables clock tree synthesis.
  if {[llength $IO_RING]} {
    # The chip's ports are the pads' pad pins, so the pads are placed, not the ports.
    set unringed [remove_from_collection [get_cells -filter is_io==true] [get_cells [concat {*}[dict values $IO_RING]]]]
    if {[sizeof_collection $unringed]} { error "IO cells missing from IO_RING: [get_object_name $unringed]" }
    create_io_ring -name io_ring
    foreach side {bottom right top left} { add_to_io_guide io_ring.$side [get_cells [dict get $IO_RING $side]] }
    # Otherwise scan reordering can wire the chain straight to the scan_out port and delete its pad.
    set_dont_touch [get_cells [concat {*}[dict values $IO_RING]]] true
    place_io
    # place_io spreads pads evenly, so gaps can be fractional, and IO fillers come in whole microns (DPI-089).
    # Pads and corners are whole microns wide, so snapping every pad to a whole-micron origin, on a die with
    # whole-micron edges, leaves gaps the fillers can close. The snap uses the placed bounding box, since a
    # rotated pad's origin is not its lower-left corner. IO_SNAP, optional in pdk.tcl, is the narrowest IO
    # filler, 1 um by default.
    if {![info exists IO_SNAP]} { set IO_SNAP 1.0 }
    # Only the coordinate along the side is snapped; the other keeps place_io's flush position against the die
    # edge.
    lassign [get_attribute [current_block] boundary_bbox] dll dur
    foreach side {bottom right top left} {
      foreach_in_collection pad [get_cells [dict get $IO_RING $side]] {
        lassign [lindex [get_attribute $pad boundary_bbox] 0] x y
        if {$side in {bottom top}} { set x [expr {round($x / $IO_SNAP) * $IO_SNAP}] } else { set y [expr {round($y / $IO_SNAP) * $IO_SNAP}] }
        set_cell_location $pad -coordinates [list $x $y] -ignore_fixed -fixed
      }
    }
    # IO_BONDPAD_TOP, optional in pdk.tcl: the library draws its bond pad at the cell's top edge, the reverse of what
    # place_io assumes, so each pad is turned 180 degrees within its footprint.
    set bondpad_top [expr {[info exists IO_BONDPAD_TOP] && $IO_BONDPAD_TOP}]
    if {$bondpad_top} { io_rotate_180 [get_cells [concat {*}[dict values $IO_RING]]] }
    set facing [io_facing_errors]
    if {[llength $facing]} { error "IO cells face the core: $facing" }
    foreach_in_collection pad [get_cells -filter is_io==true] {
      lassign [get_attribute $pad boundary_bbox] ll ur
      if {[lindex $ll 0] < [lindex $dll 0] || [lindex $ll 1] < [lindex $dll 1] ||
          [lindex $ur 0] > [lindex $dur 0] || [lindex $ur 1] > [lindex $dur 1]} {
        error "IO cell [get_object_name $pad] at $ll $ur lies outside the die $dll $dur"
      }
    }
    foreach {a b} {left top top right right bottom bottom left} {
      create_io_corner_cell -reference_cell $IO_CORNER [list io_ring.$a io_ring.$b]
    }
    # IO_CORNER_ORIENT, optional in pdk.tcl: {bl orient br orient tr orient tl orient}. FC orients a corner as if the
    # library drew it for the bottom left, which mirrors the rails of a corner drawn any other way.
    if {[info exists IO_CORNER_ORIENT]} {
      lassign $dll dx0 dy0; lassign $dur dx1 dy1
      foreach_in_collection c [get_cells -filter "ref_name == $IO_CORNER"] {
        lassign [get_attribute $c boundary_bbox] ll ur
        set k [expr {[lindex $ll 1] - $dy0 < $dy1 - [lindex $ur 1] ? "b" : "t"}][expr {[lindex $ll 0] - $dx0 < $dx1 - [lindex $ur 0] ? "l" : "r"}]
        set_cell_location $c -coordinates $ll -orientation [dict get $IO_CORNER_ORIENT $k] -ignore_fixed -fixed
        # Then flush to the die corner: a corner cell that is not square changes its extent when reoriented.
        lassign [get_attribute $c boundary_bbox] ll ur
        set w [expr {[lindex $ur 0] - [lindex $ll 0]}]; set h [expr {[lindex $ur 1] - [lindex $ll 1]}]
        set_cell_location $c -coordinates [list [expr {[string index $k 1] eq "l" ? $dx0 : $dx1 - $w}] [expr {[string index $k 0] eq "b" ? $dy0 : $dy1 - $h}]] -ignore_fixed -fixed
      }
    }
    create_io_filler_cells -reference_cells $IO_FILLERS
    # IO_BUS_NETS, optional in pdk.tcl: {pin net ...}, signal buses that run through every ring cell by abutment.
    # Left open, each cell's piece is its own net and every abutment is a short.
    if {[info exists IO_BUS_NETS]} {
      set ring [io_ring_cells]
      foreach {pin net} $IO_BUS_NETS {
        if {![sizeof_collection [get_nets -quiet $net]]} { create_net $net }
        set pins {}
        foreach_in_collection p [get_pins -quiet -of_objects $ring -filter "name == $pin"] {
          if {![sizeof_collection [get_nets -quiet -of_objects $p]]} { append_to_collection pins $p }
        }
        if {[sizeof_collection $pins]} { connect_net -net $net $pins }
        puts "FLASH_IO_BUS $net [sizeof_collection [get_pins -quiet -of_objects [get_nets $net]]]"
      }
    }
    if {$bondpad_top} {
      # A filler must face the way the pads on its side face, or its buses do not meet theirs.
      lassign $dll dx0 dy0; lassign $dur dx1 dy1
      foreach side {bottom right top left} { dict set side_orient $side [get_attribute [index_collection [get_cells [dict get $IO_RING $side]] 0] orientation] }
      set turned 0
      foreach_in_collection f [get_cells -quiet -filter [join [lmap r $IO_FILLERS {set r "ref_name == $r"}] " || "]] {
        lassign [get_attribute $f boundary_bbox] ll ur
        set d [dict create bottom [expr {[lindex $ll 1] - $dy0}] right [expr {$dx1 - [lindex $ur 0]}] top [expr {$dy1 - [lindex $ur 1]}] left [expr {[lindex $ll 0] - $dx0}]]
        set side [lindex [lsort -real -stride 2 -index 1 $d] 0]
        if {[get_attribute $f orientation] ne [dict get $side_orient $side]} { io_rotate_180 $f; incr turned }
      }
      puts "FLASH_IO_FILLERS_TURNED $turned"
    }
    puts "FLASH_IO_PADS [sizeof_collection [get_cells -quiet -filter is_io==true]]"
  } else {
    set_block_pin_constraints -self -allowed_layers $PIN_LAYERS -sides {1 2 3 4}
    # With macros present, place_pins global-routes, and refuses to while crosstalk-driven routing is on (DPPA-269).
    set xt [get_app_option_value -name route.global.crosstalk_driven]
    set_app_options -name route.global.crosstalk_driven -value false
    place_pins -self
    set_app_options -name route.global.crosstalk_driven -value $xt
  }
  if {$TAP_CELL ne ""} {
    # Libraries without built-in substrate ties need tap cells within the latch-up distance.
    create_tap_cells -lib_cell [lib_cells_named [list $TAP_CELL]] -distance $TAP_DIST -pattern stagger -skip_fixed_cells
    puts "FLASH_TAP_CELLS [sizeof_collection [get_cells -quiet -physical_context -filter ref_name==$TAP_CELL]]"
  }
  puts "FLASH_UNPLACED_PORTS [sizeof_collection [get_ports -quiet -filter {port_type == signal && physical_status == unplaced}]]"
  stage_done floorplan
}

# ---------------------------------------------------------------- power grid
if {[run_stage pg]} {
  pg_connect
  # A pattern's own -via_rule governs crossings inside that pattern (ring corners, mesh crossings);
  # compile_pg -via_rule governs crossings between patterns. Both are needed.
  set masters {}
  set i 0
  # PG_VIA_ARRAY, optional in pdk.tcl: {contact_code {columns rows} ...} caps an array's size. A rail-to-stripe
  # stack as wide as the stripe puts a bar on every layer between them, which can block signal tracks.
  if {![info exists PG_VIA_ARRAY]} { set PG_VIA_ARRAY {} }
  foreach {code spacing} $PG_VIA_RULES {
    set dim [expr {[dict exists $PG_VIA_ARRAY $code] ? [list -via_array_dimension [dict get $PG_VIA_ARRAY $code]] : {}}]
    set_pg_via_master_rule pgvia$i -contact_code $code -cut_spacing [list $spacing $spacing] {*}$dim
    lappend masters pgvia$i
    incr i
  }
  if {[llength $masters]} {
    set pgvias [list {intersection: all} [list via_master: $masters]]
  } else {
    set pgvias {{intersection: all} {via_master: default}}
  }
  create_pg_ring_pattern core_ring -horizontal_layer $RING_H_LAYER -vertical_layer $RING_V_LAYER \
    -horizontal_width $RING_W -vertical_width $RING_W -horizontal_spacing $RING_SPACING -vertical_spacing $RING_SPACING -via_rule $pgvias
  set_pg_strategy core_ring -core -pattern {{name: core_ring} {nets: {VDD VSS}} {offset: {1.5 1.5}}}
  # Stripe offsets place each stripe's centre, measured from the core edge; optional in pdk.tcl.
  if {![info exists MESH_V_OFFSET]} { set MESH_V_OFFSET 6.0 }
  if {![info exists MESH_H_OFFSET]} { set MESH_H_OFFSET 6.0 }
  set mesh_layers [list \
    [list [list vertical_layer: $MESH_V_LAYER]   [list width: $MESH_V_W] {spacing: interleaving} [list pitch: $MESH_PITCH] [list offset: $MESH_V_OFFSET]] \
    [list [list horizontal_layer: $MESH_H_LAYER] [list width: $MESH_H_W] {spacing: interleaving} [list pitch: $MESH_PITCH] [list offset: $MESH_H_OFFSET]]]
  # DENSITY_MESH, optional: {{layer vertical|horizontal width pitch offset} ...}, more mesh stripes on layers the
  # mesh does not use. IHP's global minimum metal density is 35% and its fill cannot reach it on Metal2 and Metal3
  # of a routed block, so the rest has to be drawn metal.
  if {[info exists DENSITY_MESH]} {
    foreach m $DENSITY_MESH {
      lassign $m dl dd dw dp doff
      lappend mesh_layers [list [list ${dd}_layer: $dl] [list width: $dw] {spacing: interleaving} [list pitch: $dp] [list offset: $doff]]
    }
  }
  create_pg_mesh_pattern core_mesh -layers $mesh_layers -via_rule $pgvias
  # The mesh stops at the core ring. With a pad ring, IO_CORE_STRAPS below carry the supplies to the pads.
  set mesh_stop outermost_ring
  set strategies {core_ring core_mesh cell_rails}
  create_pg_std_cell_conn_pattern cell_rails -layers [list $RAIL_LAYER] -rail_width $RAIL_W
  # RAIL_STRAPS, optional in pdk.tcl: {layer width pitch offset}. Thin straps just above the rails take one via to
  # each rail they cross, and the mesh reaches the rails only through them.
  if {[info exists RAIL_STRAPS]} {
    lassign $RAIL_STRAPS rs_layer rs_w rs_pitch rs_off
    create_pg_mesh_pattern rail_straps -layers [list [list [list vertical_layer: $rs_layer] [list width: $rs_w]       {spacing: interleaving} [list pitch: $rs_pitch] [list offset: $rs_off]]]
  }
  # VOLTAGE_AREAS, optional in run_cfg: {area primary_power_net {{llx lly} {urx ury}} ...}, one per power domain
  # of the UPF other than the top. The core's mesh, rails and straps stop at every area; each area gets its own,
  # on its primary supply.
  if {![info exists VOLTAGE_AREAS]} { set VOLTAGE_AREAS {} }
  set va_names [lmap {va net box} $VOLTAGE_AREAS {set va}]
  set mblock {}
  set rblock {}
  if {[llength $MACROS]} {
    # The mesh and rails stop at each macro's keepout. Horizontal straps on the mesh's upper layer cross
    # every macro and land on its long supply pins, then extend out to the nearest mesh stripe.
    set macro_names [lmap {i x y o} $MACROS {set i}]
    lappend mblock [list [list macros_with_keepout: $macro_names]]
    lappend rblock [list [list macros_with_keepout: $macro_names]]
    # Rails also stop at placement blockages; the mesh stays there, since the macro straps extend to it.
    if {[llength $PLACE_BLOCKAGES]} { lappend rblock [list {placement_blockages: all}] }
    # MACRO_CONN, optional in run_cfg: {scattered_pin {hor_layer ver_layer} {hor_w ver_w}}, for macros whose
    # supply pins are small shapes, not long pins. Extensions on the pins' own layer need no via onto them.
    # An optional fourth element limits which pin layers are used, for macros whose own vias would collide with
    # FC's vias onto their lower supply pins.
    if {[info exists MACRO_CONN]} {
      lassign $MACRO_CONN mtype mlayers mwidths mpins
      create_pg_macro_conn_pattern macro_straps -pin_conn_type $mtype -layers $mlayers -width $mwidths         {*}[expr {$mpins ne "" ? [list -pin_layers $mpins] : {}}]
    } else {
      create_pg_macro_conn_pattern macro_straps -pin_conn_type long_pin -nets {VDD VSS} -layers $MESH_H_LAYER       -direction horizontal -width $MESH_H_W -spacing interleaving -pitch $MESH_PITCH -via_rule $pgvias
    }
    set_pg_strategy macro_straps -macros $macro_names -pattern {{name: macro_straps} {nets: {VDD VSS}}}       -extension {{stop: first_target}}
    lappend strategies macro_straps
  }
  # An area's first and last rows share their outer rail with the row beyond the area. FC's voltage_areas: region
  # and blockage both leave that rail to the core, which would put the core's supply under those rows' pins. The
  # area's rails and straps therefore cover one rail width past its top and bottom, and the core's rails and straps
  # are blocked there and across VA_GUARD at the sides. VA_GUARD keeps the row beyond the edge rail empty.
  set va_poly {}
  if {[llength $va_names]} {
    lappend mblock [list [list voltage_areas: $va_names]]
    set g [expr {[info exists VA_GUARD] ? $VA_GUARD : 0}]
    foreach {va net box} $VOLTAGE_AREAS {
      lassign $box ll ur
      lassign $ll x0 y0
      lassign $ur x1 y1
      set y0 [expr {$y0 - $RAIL_W}]
      set y1 [expr {$y1 + $RAIL_W}]
      dict set va_poly $va [list [list $x0 $y0] [list $x1 $y0] [list $x1 $y1] [list $x0 $y1]]
      set bx0 [expr {$x0 - $g}]
      set bx1 [expr {$x1 + $g}]
      lappend rblock [list [list polygon: [list [list $bx0 $y0] [list $bx1 $y0] [list $bx1 $y1] [list $bx0 $y1]]]]
    }
  }
  set mopt [expr {[llength $mblock] ? [list -blockage $mblock] : {}}]
  set ropt [expr {[llength $rblock] ? [list -blockage $rblock] : {}}]
  set_pg_strategy core_mesh -core -pattern {{name: core_mesh} {nets: {VDD VSS}}} -extension [list [list stop: $mesh_stop]] {*}$mopt
  set_pg_strategy cell_rails -core -pattern {{name: cell_rails} {nets: {VDD VSS}}} {*}$ropt
  set nil_pairs {{core_mesh cell_rails} {core_ring cell_rails}}
  if {[info exists RAIL_STRAPS]} {
    set_pg_strategy rail_straps -core -pattern {{name: rail_straps} {nets: {VDD VSS}}} -extension {{stop: innermost_ring}} {*}$ropt
    lappend strategies rail_straps
  }
  foreach {va net box} $VOLTAGE_AREAS {
    set_pg_strategy ${va}_mesh -voltage_areas $va -pattern [list {name: core_mesh} [list nets: [list $net VSS]]]
    set_pg_strategy ${va}_rails -polygon [dict get $va_poly $va] -pattern [list {name: cell_rails} [list nets: [list $net VSS]]]
    lappend strategies ${va}_mesh ${va}_rails
    lappend nil_pairs [list ${va}_mesh ${va}_rails] [list core_ring ${va}_rails] [list core_mesh ${va}_rails]
    if {[info exists RAIL_STRAPS]} {
      set_pg_strategy ${va}_straps -polygon [dict get $va_poly $va] -pattern [list {name: rail_straps} [list nets: [list $net VSS]]]
      lappend strategies ${va}_straps
    }
    # VA_AON_MESH, optional in run_cfg: {area {net layer width pitch offset} ...}. Vertical stripes of an always-on
    # supply through a switched area, out to the core ring, for its power switches' inputs.
    if {[info exists VA_AON_MESH] && [dict exists $VA_AON_MESH $va]} {
      lassign [dict get $VA_AON_MESH $va] anet alayer aw apitch aoff
      create_pg_mesh_pattern ${va}_aon -layers [list [list [list vertical_layer: $alayer] [list width: $aw] [list pitch: $apitch] [list offset: $aoff]]]
      set_pg_strategy ${va}_aon -voltage_areas $va -pattern [list [list name: ${va}_aon] [list nets: $anet]] -extension {{stop: innermost_ring}}
      lappend strategies ${va}_aon
    }
  }
  if {[info exists RAIL_STRAPS]} {
    # With straps, the mesh and ring reach the rails only through them.
    set pgvias_compile [lmap p $nil_pairs {list [list [list strategies: [lindex $p 0]]] [list [list strategies: [lindex $p 1]]] {via_master: NIL}}]
    lappend pgvias_compile $pgvias
  } else {
    set pgvias_compile $pgvias
  }
  set_pg_strategy_via_rule pg_vias -via_rule $pgvias_compile
  # MACRO_STRAPS, optional in run_cfg: {{net layer y width} ...}, horizontal supply straps across the core from
  # ring to ring for macro pins to extend to, where the mesh is blocked over a row of macros.
  if {[info exists MACRO_STRAPS]} {
    lassign [get_attribute [get_core_area] bbox] mcl mcu
    foreach st $MACRO_STRAPS {
      lassign $st snet slayer sy swid
      create_pg_strap -layer $slayer -direction horizontal -width $swid -net $snet -start $sy \
        -low_end [expr {[lindex $mcl 0] - 10}] -high_end [expr {[lindex $mcu 0] + 10}] -via_rule $pgvias
    }
  }
  # compile_pg trims each vertical stripe back to its last crossing with the horizontal mesh. Where a placement
  # blockage edge falls between mesh stripes, the rows next to it get no stripes. A VDD and VSS strap on the
  # mesh's horizontal layer along every blockage edge that faces core rows gives the stripes a last crossing there.
  lassign [get_attribute [get_core_area] bbox] ecl ecu
  foreach box $PLACE_BLOCKAGES {
    lassign $box bl bu
    foreach {edge dir} [list [lindex $bl 1] -1 [lindex $bu 1] 1] {
      if {$edge <= [lindex $ecl 1] + 1 || $edge >= [lindex $ecu 1] - 1} continue
      set k 0
      foreach net {VSS VDD} {
        set y [expr {$dir < 0 ? $edge - 2.0 - ($k + 1) * ($MESH_H_W + 1.0) : $edge + 2.0 + $k * ($MESH_H_W + 1.0)}]
        create_pg_strap -layer $MESH_H_LAYER -direction horizontal -width $MESH_H_W -net $net -start $y \
          -low_end [lindex $ecl 0] -high_end [lindex $ecu 0] -via_rule $pgvias
        incr k
      }
    }
  }
  compile_pg -strategies $strategies -via_rule pg_vias
  # POWER_SWITCH_ARRAYS, optional in run_cfg: {switch area lib_cell x_pitch x_offset y_pitch sleep_port} ..., for a
  # switch strategy in the UPF. POWER_SWITCH_ALIGN {layer direction width} gives the straps that feed the switches'
  # supply inputs from the area's always-on stripes (VA_AON_MESH). Sleep inputs are chained from the sleep port.
  if {[info exists POWER_SWITCH_ARRAYS]} {
    foreach {sw va lc xp xo yp src} $POWER_SWITCH_ARRAYS {
      lassign [dict get $VA_AON_MESH $va] anet alayer
      create_power_switch_array -power_switch $sw -lib_cell $lc -voltage_area $va \
        -x_pitch $xp -x_offset $xo -y_pitch $yp -prefix ${sw}_
      connect_power_switch -source [get_ports $src] -port_name ${sw}_sleep -mode daisy -direction vertical -voltage_area $va
      puts "FLASH_POWER_SWITCHES $sw [sizeof_collection [get_cells -hierarchical -quiet -filter ref_name==$lc]]"
      # A switch's supply input can be a small Metal1 island that route_group leaves unconnected. An alignment strap
      # runs along each row of switches over the islands and crosses the stripes. The islands must sit clear of the
      # stripes, whose via stacks down to the strap would take their place, and between the area's rail straps.
      # The straps need the switches' supply pins connected first.
      pg_connect
      lassign $POWER_SWITCH_ALIGN al_layer al_dir al_w
      create_pg_special_pattern ${sw}_align -insert_power_switch_alignment_straps \
        [list [list lib_cells: $lc] [list layer: $al_layer] [list direction: $al_dir] [list width: $al_w]]
      set_pg_strategy ${sw}_align -voltage_areas $va -pattern [list [list name: ${sw}_align] [list nets: $anet]]
      compile_pg -strategies ${sw}_align
      # compile_pg drops the vias from the stripes once the strap is wide enough to take them, but leaves the pins
      # below, which run parallel to the strap. In its default mode create_pg_vias refuses those (PGR-051), so they
      # are made with check_but_no_fix.
      foreach {v n b} $VOLTAGE_AREAS { if {$v eq $va} { set vabox $b } }
      create_pg_vias -nets $anet -within_bbox $vabox -from_layers $al_layer -to_types pwrswitch_pin -allow_parallel_objects \
        -drc check_but_no_fix
      puts "FLASH_POWER_SWITCH_VIAS $sw [sizeof_collection [get_vias -quiet -within $vabox -filter owner.name==$anet]]"
    }
  }
  if {[llength $IO_RING]} {
    # Core supply from the pads. Each net gets straps on a layer where its pad rail is the one nearer the core
    # (IHP: VDD on Metal3, VSS on Metal4 and Metal5). A strap starts inside that rail, so it joins the rail on
    # its own layer, and ends at the core boundary, covering the core ring just outside it. Running further into
    # the core would cross the mesh's via stacks. The nets' straps are offset from each other so their via stacks
    # down to the core ring never meet.
    # A strap also keeps clear of the pads' signal pins: FC notches a strap around a pin it crosses, and the
    # notch is narrower than the wide-metal spacing. A strap that would come near one moves along the ring in
    # 5 um steps, and is left out if no spot within 45 um is clear.
    # IO_STRAP_W, optional in pdk.tcl, is the strap width, 10 um by default. IO_STRAP_GRID, optional, centres
    # straps on multiples of it from the die edge, the pad abutment lines, for pad abstracts that show their rails
    # as pins only at the pad edges. Straps then move in steps of the grid.
    # An IO_CORE_STRAPS entry may add {land_layer land_length}: for a rail with the other net's rail between it
    # and the core on every layer it has, the strap runs on a layer above the rails, and a patch of land_layer on
    # the rail, drawn over the rail's own metal, takes a via from it. -start is the strap's centre.
    lassign [get_attribute [current_block] boundary_bbox] dll dur
    lassign [get_attribute [get_core_area] bbox] cll cur
    lassign $dll dx0 dy0; lassign $dur dx1 dy1; lassign $cll cx0 cy0; lassign $cur cx1 cy1
    set sw [expr {[info exists IO_STRAP_W] ? $IO_STRAP_W : 10.0}]
    set grid [expr {[info exists IO_STRAP_GRID] ? $IO_STRAP_GRID : 0}]
    if {$grid} {
      set sp [expr {$grid * max(1, round(100.0 / $grid))}]
      set steps [list 0 $grid -$grid [expr {2 * $grid}] [expr {-2 * $grid}]]
    } else {
      set sp 100.0
      set steps {0 5 -5 10 -10 15 -15 20 -20 25 -25 30 -30 35 -35 40 -40 45 -45}
    }
    set pinboxes [lmap p [get_object_name [get_pins -of_objects [get_cells -filter is_io==true] -filter "port_type == signal"]] {
      get_attribute [get_pins $p] bbox
    }]
    set skipped 0
    foreach strap $IO_CORE_STRAPS {
      lassign $strap snet vlayer hlayer srail off land land_len
      # Per side: layer, direction, ends, range along the side, the die edge that range is measured from, and
      # the end that lies on the rail.
      foreach {layer dir lo hi a b base rend} [list \
          $vlayer vertical   [expr {$dy0 + $srail}] $cy0 [expr {$cx0 + $off}] [expr {$cx1 - 50}] $dx0 lo \
          $vlayer vertical   $cy1 [expr {$dy1 - $srail}] [expr {$cx0 + $off}] [expr {$cx1 - 50}] $dx0 hi \
          $hlayer horizontal [expr {$dx0 + $srail}] $cx0 [expr {$cy0 + $off}] [expr {$cy1 - 50}] $dy0 lo \
          $hlayer horizontal $cx1 [expr {$dx1 - $srail}] [expr {$cy0 + $off}] [expr {$cy1 - 50}] $dy0 hi] {
        set rail [expr {$rend eq "lo" ? $lo : $hi}]
        if {$land ne ""} {
          # The strap covers the whole patch.
          if {$rend eq "lo"} { set lo [expr {$lo - $land_len / 2.0}] } else { set hi [expr {$hi + $land_len / 2.0}] }
        }
        for {set pos $a} {$pos <= $b} {set pos [expr {$pos + $sp}]} {
          set placed 0
          foreach d $steps {
            set p [expr {$pos + $d}]
            if {$grid} { set p [expr {$base + round(($p - $base) / $grid) * $grid}] }
            # The strap's footprint with half a strap and 1 um to spare.
            set s0 [expr {$p - $sw - 1}]; set s1 [expr {$p + $sw + 1}]
            set clear 1
            foreach bb $pinboxes {
              lassign $bb pll pur
              lassign $pll px0 py0; lassign $pur px1 py1
              if {$dir eq "vertical"} {
                set hit [expr {$px1 > $s0 && $px0 < $s1 && $py1 > $lo - 1 && $py0 < $hi + 1}]
              } else {
                set hit [expr {$py1 > $s0 && $py0 < $s1 && $px1 > $lo - 1 && $px0 < $hi + 1}]
              }
              if {$hit} { set clear 0; break }
            }
            # IO_STRAP_OVER, optional in pdk.tcl: the ring cells a strap may cross. A pad's metal where the strap
            # lands may be another supply, which its abstract hides.
            if {$clear && [info exists IO_STRAP_OVER]} {
              set fp [expr {$dir eq "vertical" ? [list [list $s0 $lo] [list $s1 $hi]] : [list [list $lo $s0] [list $hi $s1]]}]
              foreach_in_collection c [get_cells -quiet -intersect $fp -filter "is_io == true || [join [lmap r [concat $IO_FILLERS $IO_CORNER] {set r "ref_name == $r"}] { || }]"] {
                if {[get_attribute $c ref_name] ni $IO_STRAP_OVER} { set clear 0; break }
              }
            }
            if {$clear} {
              create_pg_strap -layer $layer -direction $dir -width $sw -net $snet -start $p \
                -low_end $lo -high_end $hi -via_rule $pgvias
              if {$land ne ""} {
                set w0 [expr {$p - $sw / 2.0}]; set w1 [expr {$p + $sw / 2.0}]
                set r0 [expr {$rail - $land_len / 2.0}]; set r1 [expr {$rail + $land_len / 2.0}]
                set box [expr {$dir eq "vertical" ? [list [list $w0 $r0] [list $w1 $r1]] : [list [list $r0 $w0] [list $r1 $w1]]}]
                create_shape -shape_type rect -layer $land -boundary $box -net $snet -shape_use stripe
                create_pg_vias -nets $snet -from_layers $layer -to_layers $land -within_bbox $box
              }
              set placed 1
              break
            }
          }
          if {!$placed} { incr skipped }
        }
      }
    }
    puts "FLASH_IO_STRAPS_SKIPPED $skipped"
    # IO_PAD_STRAPS, optional in run_cfg: {cell net layer width ...}. One strap per pad of that cell, from the pad's
    # core edge to the core boundary, across the core ring, for pads whose core supply pin is a row of fingers on
    # their core edge below every ring rail. The strap overlaps the fingers by 0.3 um and takes vias where it
    # crosses its own net's ring.
    if {[info exists IO_PAD_STRAPS]} {
      set npad 0
      foreach {pcell pnet player pw} $IO_PAD_STRAPS {
        foreach_in_collection pad [get_cells -quiet -filter "ref_name == $pcell"] {
          lassign [get_attribute $pad boundary_bbox] pll pur
          lassign $pll px0 py0; lassign $pur px1 py1
          if {$py0 - $dy0 < 1.0} {
            set dir vertical;   set s [expr {($px0 + $px1) / 2.0}]; set lo [expr {$py1 - 0.3}]; set hi $cy0
          } elseif {$dy1 - $py1 < 1.0} {
            set dir vertical;   set s [expr {($px0 + $px1) / 2.0}]; set lo $cy1; set hi [expr {$py0 + 0.3}]
          } elseif {$px0 - $dx0 < 1.0} {
            set dir horizontal; set s [expr {($py0 + $py1) / 2.0}]; set lo [expr {$px1 - 0.3}]; set hi $cx0
          } else {
            set dir horizontal; set s [expr {($py0 + $py1) / 2.0}]; set lo $cx1; set hi [expr {$px0 + 0.3}]
          }
          create_pg_strap -layer $player -direction $dir -width $pw -net $pnet -start $s -low_end $lo -high_end $hi -via_rule $pgvias
          incr npad
        }
      }
      puts "FLASH_IO_PAD_STRAPS $npad"
    }
    # create_pg_strap drops vias only onto the next layer. A strap that crosses the core ring on a layer further
    # up gets no stack, so the stacks are made explicitly in the ring's zone outside each core edge.
    set rz [expr {2 * $RING_W + $RING_SPACING + 5.0}]
    # PGR-049 and PGR-050 say a box needs no new via; PGR-051, a via blocked by DRC, stays visible.
    suppress_message {PGR-049 PGR-050}
    set ring_vias 0
    foreach strap $IO_CORE_STRAPS {
      lassign $strap snet vlayer hlayer
      foreach {layer box} [list \
          $vlayer [list [list $cx0 [expr {$cy0 - $rz}]] [list $cx1 $cy0]] $vlayer [list [list $cx0 $cy1] [list $cx1 [expr {$cy1 + $rz}]]] \
          $hlayer [list [list [expr {$cx0 - $rz}] $cy0] [list $cx0 $cy1]] $hlayer [list [list $cx1 $cy0] [list [expr {$cx1 + $rz}] $cy1]]] {
        foreach rl [lsort -unique [list $RING_H_LAYER $RING_V_LAYER]] {
          set n0 [sizeof_collection [get_vias -quiet -within $box -filter owner.name==$snet]]
          # PGR-049, nothing of the net to stack onto in this box, is the normal case where the layers already meet.
          catch {create_pg_vias -nets $snet -from_layers $layer -to_layers $rl -within_bbox $box}
          incr ring_vias [expr {[sizeof_collection [get_vias -quiet -within $box -filter owner.name==$snet]] - $n0}]
        }
      }
    }
    puts "FLASH_IO_RING_VIAS $ring_vias"
    unsuppress_message {PGR-049 PGR-050}
    # The pads' supply rails are stacked on every metal with their own vias, which the pad abstract hides, so
    # FC's vias inside a pad land on top of them and break the via spacing rules. Every strap joins its
    # rail on its own layer, so it stays connected without them. IO_REMOVE_PG_VIAS 0 in pdk.tcl keeps them, for
    # pads whose rails sit on one metal with nothing below, where FC's vias are the only way in.
    if {![info exists IO_REMOVE_PG_VIAS]} { set IO_REMOVE_PG_VIAS 1 }
    set io_vias 0
    if {$IO_REMOVE_PG_VIAS} {
      foreach_in_collection c [get_cells -filter is_io==true] {
        set v [get_vias -quiet -within [get_attribute $c boundary_bbox] -filter "owner.name == VDD || owner.name == VSS"]
        incr io_vias [sizeof_collection $v]
        if {[sizeof_collection $v]} { remove_vias $v }
      }
    }
    puts "FLASH_IO_VIAS_REMOVED $io_vias"
    # IO supplies enter the chip at their supply pads, so each gets a terminal on those pads' supply pin.
    foreach {cell net pin} $IO_SUPPLY_CELLS {
      foreach_in_collection pad [get_cells -quiet -filter "ref_name == $cell"] {
        create_terminal -port [get_ports $net] -object [get_pins [get_object_name $pad]/$pin]
      }
    }
    puts "FLASH_IO_SUPPLY_TERMINALS [sizeof_collection [get_terminals -quiet -of_objects [get_ports {IOVDD IOVSS}]]]"
    foreach n {VDD VSS} {
      puts "FLASH_IO_CORE_STRAPS $n [sizeof_collection [get_shapes -quiet -filter "owner.name == $n && shape_use == stripe && width == $sw"]]"
    }
  }
  # PG_ROUTES, optional in run_cfg: {net {{layer x0 y0 x1 y1} ...} ...}. A supply's own path, drawn rectangle by
  # rectangle, for a net with no ring or mesh in the core: a PLL's 2.5 V analog supply, from the pad ring's IO rail
  # to the PLL's pin. Each rectangle on another layer than the one before it takes vias to it where they overlap.
  if {[info exists PG_ROUTES]} {
    foreach {net rects} $PG_ROUTES {
      set prev {}
      foreach r $rects {
        lassign $r layer x0 y0 x1 y1
        create_shape -shape_type rect -layer $layer -boundary [list [list $x0 $y0] [list $x1 $y1]] -net $net -shape_use stripe
        if {[llength $prev] && [lindex $prev 0] ne $layer} {
          lassign $prev player px0 py0 px1 py1
          set box [list [list [expr {max($x0, $px0)}] [expr {max($y0, $py0)}]] [list [expr {min($x1, $px1)}] [expr {min($y1, $py1)}]]]
          # Counted net-wide: a via's enclosure can reach past the overlap.
          set n0 [sizeof_collection [get_vias -quiet -filter owner.name==$net]]
          create_pg_vias -nets $net -from_layers $player -to_layers $layer -within_bbox $box
          puts "FLASH_PG_ROUTE_VIAS $net $player $layer [expr {[sizeof_collection [get_vias -quiet -filter owner.name==$net]] - $n0}]"
        }
        set prev $r
      }
    }
  }
  # PG_VIA_KEEPOUT, optional in pdk.tcl: {layer margin ...}. A rail via stack's pad on a layer it crosses the
  # wrong way gets a zero-spacing signal blockage, margin um larger, since the router treats these pads as cell
  # pin connections and can keep less than minimum spacing to them.
  if {[info exists PG_VIA_KEEPOUT]} {
    set nko 0
    foreach {layer margin} $PG_VIA_KEEPOUT {
      foreach_in_collection v [get_vias -quiet -filter "shape_use == lib_cell_pin_connect && (lower_layer_name == $layer || upper_layer_name == $layer)"] {
        lassign [get_attribute $v bbox] ll ur
        create_routing_blockage -layers [get_layers $layer] -net_types signal -zero_spacing -boundary [list \
          [list [expr {[lindex $ll 0] - $margin}] [expr {[lindex $ll 1] - $margin}]] \
          [list [expr {[lindex $ur 0] + $margin}] [expr {[lindex $ur 1] + $margin}]]]
        incr nko
      }
    }
    puts "FLASH_PG_VIA_KEEPOUTS $nko"
  }
  # Supply ports get real terminals so write_gds labels them; LVS compares top-level ports strictly and treats
  # an unlabeled supply as missing. VDD and VSS take a ring shape. A voltage area's supply has no ring, so it
  # takes one of its stripes.
  foreach n [lsort -unique [concat {VDD VSS} [lmap {va net box} $VOLTAGE_AREAS {set net}]]] {
    if {![sizeof_collection [get_ports -quiet $n]]} continue
    set shp [get_shapes -quiet -of_objects [get_nets $n] -filter "shape_use == ring && layer_name == $RING_H_LAYER"]
    if {![sizeof_collection $shp]} { set shp [get_shapes -quiet -of_objects [get_nets $n] -filter "shape_use == stripe"] }
    create_terminal -of_objects [index_collection $shp 0]
  }
  # Wide-metal spacing: a line next to a wide PG shape needs extra space. FC's route check does not apply
  # this between signal wires and PG stripes, so every
  # long edge of a wide PG shape gets a zero-spacing signal blockage of the required width.
  set keepouts 0
  set layer_filter [join [lmap l [dict keys $WIDE_STEPS] {format "layer_name == %s" $l}] " || "]
  set wide_pg [expr {[dict size $WIDE_STEPS] ? [get_shapes -filter "(shape_use == stripe || shape_use == ring) && ($layer_filter)"] : {}}]
  foreach_in_collection s $wide_pg {
    lassign [get_attribute $s bbox] ll ur
    lassign $ll x1 y1
    lassign $ur x2 y2
    set w [expr {min($x2 - $x1, $y2 - $y1)}]
    set L [get_attribute $s layer_name]
    set gap 0
    foreach {min_w space} [dict get $WIDE_STEPS $L] { if {$w > $min_w} { set gap $space } }
    if {$gap == 0} { continue }
    if {($y2 - $y1) > ($x2 - $x1)} {
      set rects [list [list [list [expr {$x1 - $gap}] $y1] [list $x1 $y2]] [list [list $x2 $y1] [list [expr {$x2 + $gap}] $y2]]]
    } else {
      set rects [list [list [list $x1 [expr {$y1 - $gap}]] [list $x2 $y1]] [list [list $x1 $y2] [list $x2 [expr {$y2 + $gap}]]]]
    }
    foreach r $rects {
      create_routing_blockage -layers $L -boundary $r -zero_spacing -net_types {signal clock reset scan tie_high tie_low} -name_prefix wide_pg_keepout
      incr keepouts
    }
  }
  puts "FLASH_WIDE_PG_KEEPOUTS $keepouts"
  puts "FLASH_PG_TERMINALS [sizeof_collection [get_terminals -of_objects [get_ports {VDD VSS}]]]"
  # Floating rails or stripes after PG mean rows the grid never reaches; stop here, not after placement.
  # The check runs once the supply terminals and pad straps exist; without a terminal, FC picks its own reference
  # and can call the whole grid floating.
  check_pg_connectivity -nets {VDD VSS} > $OUT/rpt/pg_conn_pg.rpt
  set pgfloat [regexp -all -inline {Number of floating wires: *(\d+)} [read [set fh [open $OUT/rpt/pg_conn_pg.rpt]]]]
  close $fh
  puts "FLASH_PG_FLOATING_WIRES [lmap {m n} $pgfloat {set n}]"
  # A cell row whose rail no stripe reaches can stay unpowered even with the edge straps, depending on where a
  # blockage edge falls on the row grid. Each floating rail gets a hard placement blockage over its two rows and
  # is removed, so no cell can land on an unpowered rail.
  set row_blocks 0
  catch {open_drc_error_data ${DESIGN}_floatingPG.err}
  if {[sizeof_collection [get_drc_error_data -quiet ${DESIGN}_floatingPG.err]]} {
    lassign [get_attribute [get_core_area] bbox] rcl rcu
    set rowh [expr {[lindex [get_attribute [index_collection [get_site_rows] 0] bbox] 1 1] - [lindex [get_attribute [index_collection [get_site_rows] 0] bbox] 0 1]}]
    set corew [expr {[lindex $rcu 0] - [lindex $rcl 0]}]
    foreach_in_collection e [get_drc_errors -quiet -error_data ${DESIGN}_floatingPG.err] {
      if {[get_attribute $e type_name] ne "Floating wire violation"} continue
      lassign [get_attribute $e bbox] el eu
      if {[lindex $eu 0] - [lindex $el 0] < 0.5 * $corew || [lindex $eu 1] - [lindex $el 1] > 1.0} continue
      set y [expr {([lindex $el 1] + [lindex $eu 1]) / 2.0}]
      set y0 [expr {max([lindex $rcl 1], $y - $rowh)}]; set y1 [expr {min([lindex $rcu 1], $y + $rowh)}]
      create_placement_blockage -boundary [list [list [lindex $rcl 0] $y0] [list [lindex $rcu 0] $y1]] -type hard -name flash_rowblk[incr row_blocks]
      set rail [get_shapes -quiet -intersect [list [list [lindex $el 0] [expr {$y - 0.01}]] [list [lindex $eu 0] [expr {$y + 0.01}]]] -filter "layer_name == $RAIL_LAYER && shape_use == lib_cell_pin_connect"]
      if {[sizeof_collection $rail]} { remove_shapes $rail }
    }
  }
  puts "FLASH_PG_ROW_BLOCKAGES $row_blocks"
  # Before routing every macro signal pin is unconnected, and each 0.26 um Metal2 SRAM pin square reads as a
  # min-area error. The final check keeps the default, where an unconnected pin is real.
  check_pg_drc -check_min_metal_area_on_pins false > $OUT/rpt/pg_drc_floorplan.rpt
  stage_done pg
}

# ---------------------------------------------------------------- placement
if {[run_stage place]} {
  # RUN_NDR, optional in run_cfg: {spacing S width W}, a routing rule with those multipliers on every signal net,
  # set before placement so placement sees the room it takes. For rules the router cannot see, widen
  # the route spacing or width. A bad value is logged and the run goes on without it.
  if {[info exists RUN_NDR]} {
    if {[catch {
      create_routing_rule flash_ndr -default_reference_rule -multiplier_spacing [dict get $RUN_NDR spacing] -multiplier_width [dict get $RUN_NDR width]
      set_routing_rule -rule flash_ndr [get_nets -hierarchical -filter "net_type == signal"]
    } err]} { puts "FLASH_NDR failed: $err" } else { puts "FLASH_NDR $RUN_NDR on [sizeof_collection [get_nets -hierarchical -filter {net_type == signal}]] signal nets" }
  }
  # A block input port has no driver inside the block, so its net has no diffusion to discharge
  # antenna charge, and IHP's antenna deck flags it. A buffer at
  # every signal input except the clock gives each long route a driver; magnet placement holds the
  # buffers against their ports so the undriven stub stays short.
  # Only ports that drive something: inputs synthesis left unused have no net.
  # Input pads already buffer each chip input, so a pad-ring design skips this.
  set in_ports {}
  if {![llength $IO_RING]} {
  foreach_in_collection p [get_ports -filter "direction == in && port_type == signal && name != $CLK_PORT"] {
    set n [get_nets -quiet -of_objects $p]
    if {[sizeof_collection $n] && [sizeof_collection [get_pins -quiet -of_objects $n -filter "direction == in"]]} {
      append_to_collection in_ports $p
    }
  }
  }
  if {[sizeof_collection $in_ports]} {
    set in_bufs [add_buffer -lib_cell [lib_cells_named [list $DRIVE_CELL]] $in_ports]
    set_dont_touch $in_bufs true
  } else {
    set in_bufs {}
  }
  puts "FLASH_INPUT_BUFFERS [sizeof_collection $in_bufs]"
  compile_fusion -from initial_place
  if {[sizeof_collection $in_ports]} { magnet_placement $in_ports }
  legalize_placement
  pg_connect
  # SECONDARY_PG_NETS, optional in run_cfg: supplies that reach cells through a secondary pin, as the second supply
  # of a level shifter or the always-on supply of a retention flop. They are routed like signals, right after
  # placement: once clock_opt has run its global route, FC skips route_group (ZRT-627).
  if {[info exists SECONDARY_PG_NETS]} {
    route_group -nets [get_nets $SECONDARY_PG_NETS]
    check_pg_connectivity -check_std_cell_pins all -nets $SECONDARY_PG_NETS > $OUT/rpt/pg_conn_secondary.rpt
  }
  check_legality -verbose > $OUT/rpt/legality_place.rpt
  check_pg_connectivity -check_std_cell_pins all -nets $PG_CHECK_NETS > $OUT/rpt/pg_conn_place.rpt
  check_pg_drc -check_min_metal_area_on_pins false > $OUT/rpt/pg_drc_place.rpt
  report_timing -scenarios [all_scenarios] -max_paths 5 > $OUT/rpt/timing_place.rpt
  stage_done place
}

# ---------------------------------------------------------------- clock tree
if {[run_stage cts]} {
  set_app_options -name cts.common.max_fanout -value 8
  set_app_options -name opt.common.max_fanout -value 8
  foreach name {cts.common.max_fanout opt.common.max_fanout} {
    if {[get_app_option_value -name $name] != 8} {error "Fanout option readback failed"}
  }
  set_max_fanout 8 [current_design]
  set pads [get_cells -hierarchical -filter "ref_name =~ *IOPadOut4mA*"]
  set padlib [lib_cells_named {sg13g2_IOPadOut16mA}]
  if {[sizeof_collection $pads] != 9 || [sizeof_collection $padlib] != 1} {error "Expected nine output pads and one 16mA physical reference"}
  foreach_in_collection pad $pads {size_cell $pad [get_object_name $padlib]}
  legalize_placement -incremental
  puts "FLASH_IHP_2026_ELECTRICAL fanout=8 pads16mA=9 board_load_pF=5"
  clock_opt
  # Decaps carry their own Metal1, so they go in before routing and the router works around them.
  # Inserted after routing they collide with Metal1 routes, get deleted, and the gaps they leave
  # break NWell notch rules (IHP NW.b).
  create_stdcell_fillers -lib_cells [lib_cells_named $DECAP_CELLS]
  pg_connect
  report_clock_qor > $OUT/rpt/clock_qor.rpt
  report_clock_qor -type latency > $OUT/rpt/clock_latency.rpt
  check_clock_trees > $OUT/rpt/check_clock_trees.rpt
  # The clock routes must be DRC clean here. They are the only detail
  # routes yet, so a plain check covers them; check_routes -nets on the clock nets reports "DRCs = not checked"
  # on this version. clock_opt can leave clock wires too close to the Metal1 rails, and the decaps above land their
  # own Metal1 near more. route_eco on the clock nets repairs them in place; route_group -all_clock_nets does not.
  route_eco -nets [get_nets -hierarchical -quiet -filter "net_type == clock"] -reroute modified_nets_first_then_others
  if {[catch {check_routes -open_net false > $OUT/rpt/check_routes_cts.rpt} err]} {
    puts "FLASH_CTS_ROUTE_DRC check_failed $err"
  } else {
    set fh [open $OUT/rpt/check_routes_cts.rpt]; set rpt [read $fh]; close $fh
    puts "FLASH_CTS_ROUTE_DRC [expr {[regexp {Total number of DRCs = (\d+)} $rpt -> n] ? $n : {unparsed}}]"
  }
  stage_done cts
}

# ---------------------------------------------------------------- routing
if {[run_stage route]} {
  route_auto
  route_opt
  # route_opt's ECO routing can leave DRCs that route_auto had cleared, and its own incremental pass does not
  # remove them. Ripping up the signal nets in the markers and rerouting them clears them: the repair ladder's
  # R2, run here up to three times. Supply nets are never ripped up.
  for {set pass 1} {$pass <= 3} {incr pass} {
    check_routes > $OUT/rpt/route_cleanup_$pass.rpt
    # check_routes' own count decides; the zroute.err error data can hold stale markers.
    set fh [open $OUT/rpt/route_cleanup_$pass.rpt]
    regexp {Total number of DRCs = (\d+)} [read $fh] -> drcs
    close $fh
    set errs {}
    catch {open_drc_error_data zroute.err}
    if {$drcs > 0} { set errs [get_drc_errors -quiet -error_data zroute.err] }
    if {$pass == 1} {
      set marker_fh [open $OUT/rpt/route_drc_markers.tsv w]
      puts $marker_fh "type\tlayer\tllx\tlly\turx\tury"
      if {$drcs > 0} {
        foreach_in_collection e $errs {
          set type ""; set layer ""; set llx ""; set lly ""; set urx ""; set ury ""
          catch {set type [get_attribute $e type_name]}
          catch {set layer [get_object_name [get_attribute $e layers]]}
          if {![catch {set bbox [get_attribute $e bbox]}] && [llength $bbox] == 2} {
            lassign $bbox ll ur
            if {[llength $ll] == 2 && [llength $ur] == 2} {
              lassign $ll llx lly
              lassign $ur urx ury
            }
          }
          puts $marker_fh [join [list $type $layer $llx $lly $urx $ury] "\t"]
        }
      }
      close $marker_fh
    }
    if {$drcs == 0} {
      puts "FLASH_ROUTE_CLEANUP pass=$pass drcs=0 signal_nets=0"
      break
    }
    set nets {}
    foreach_in_collection e $errs {
      foreach_in_collection o [get_attribute -quiet $e objects] {
        if {[get_attribute -quiet $o object_class] eq "net" && [get_attribute -quiet $o net_type] eq "signal"} {
          lappend nets [get_object_name $o]
        }
      }
    }
    set nets [lsort -unique $nets]
    puts "FLASH_ROUTE_CLEANUP pass=$pass drcs=$drcs markers=[sizeof_collection $errs] signal_nets=[llength $nets]"
    if {![llength $nets]} break
    # Rip-up fixes local damage. Hundreds of marker nets means the design is out of routing capacity, and more
    # repair only costs hours.
    if {[llength $nets] > 300} {
      puts "FLASH_ROUTE_INFEASIBLE signal_nets=[llength $nets]: out of routing capacity; relax a layer or area"
      break
    }
    remove_routes -nets [get_nets $nets] -global_route -detail_route
    route_eco -nets [get_nets $nets] -max_detail_route_iterations 80
  }
  # ICV_RUNSET, optional in pdk.tcl: the IC Validator DRC runset. Fusion Compiler runs it in-design and reroutes
  # what it flags, the signoff rules its own router does not know. The in-design check reads the design saved on
  # disk, so the block is saved first. It also skips some rules, so standalone ICV at signoff stays the check.
  # REDUNDANT_VIAS, optional in pdk.tcl: double single-cut vias where there is room, for yield. This runs before
  # the in-design ICV fix, so that check sees the doubled vias.
  if {[info exists REDUNDANT_VIAS] && $REDUNDANT_VIAS} {
    add_redundant_vias
    redirect -file $OUT/rpt/redundant_vias.rpt { report_design -routing }
  }
  if {[info exists ICV_RUNSET]} { icv_fix_drc }
  stage_done route
}

# ---------------------------------------------------------------- finish
if {[run_stage final]} {
  # ECO_CHANGES, optional in the environment, from flow/eco.sh: PrimeTime's fix_eco_timing changes, applied to the
  # routed block before the fillers, and the changed cells' nets rerouted.
  if {[info exists env(ECO_CHANGES)]} {
    # Resumed from an earlier final block: its fillers go first, and come back below.
    foreach lc [get_object_name [lib_cells_named $FILL_CELLS]] {
      set fl [get_cells -quiet -physical_context -filter "ref_name == [file tail $lc]"]
      if {[sizeof_collection $fl]} { remove_cells $fl }
    }
    set leaf [get_cells -quiet -hierarchical -filter "is_hierarchical == false"]
    set before [dict create]
    foreach n [get_object_name $leaf] r [get_attribute $leaf ref_name] o [get_attribute $leaf origin] { dict set before $n [list $r $o] }
    source $env(ECO_CHANGES)
    # A hold ECO inserts buffers PrimeTime could not place; they go next to the pins they drive.
    if {[sizeof_collection [get_cells -quiet -hierarchical -filter "physical_status == unplaced"]]} { place_eco_cells -unplaced_cells }
    # Only the resized, moved and new cells are legalized, on free sites first; a neighbour is pushed only when a cell would
    # move over 5 um. legalize_placement -incremental can move untouched cells far and stretch their nets.
    set eco {}
    set leaf [get_cells -quiet -hierarchical -filter "is_hierarchical == false"]
    foreach n [get_object_name $leaf] r [get_attribute $leaf ref_name] o [get_attribute $leaf origin] {
      if {![dict exists $before $n] || [dict get $before $n] ne [list $r $o]} { lappend eco $n }
    }
    puts "FLASH_ECO_CELLS [llength $eco]"
    # The CTS-stage decaps fill every gap, so with no free site the legalizer fails (ECO-126); a decap under a
    # changed cell is removed instead, and the fillers below close what is left.
    if {[llength $eco]} {
      place_eco_cells -cells [get_cells $eco] -legalize_only -legalize_mode minimum_physical_impact -displacement_threshold 5 \
        -remove_filler_references $DECAP_CELLS
    }
    route_eco -max_detail_route_iterations 20
    if {[llength [info procs flash_eco_after]]} { flash_eco_after }
    puts "FLASH_ECO_APPLIED [regexp -all -line {^.+$} [read [set fh [open $env(ECO_CHANGES)]]]]"
    close $fh
  }
  # Metal-free fillers close every remaining gap after routing.
  create_stdcell_fillers -lib_cells [lib_cells_named $FILL_CELLS]
  pg_connect
  remove_stdcell_fillers_with_violation > $OUT/rpt/fillers_removed.rpt
  check_legality -verbose > $OUT/rpt/legality_final.rpt
  check_routes > $OUT/rpt/check_routes.rpt
  if {$ANTENNA_AWARE} { check_routes -antenna true -drc false -open_net false > $OUT/rpt/check_antenna.rpt }
  check_lvs -max_errors 0 > $OUT/rpt/check_lvs.rpt
  check_pg_connectivity -check_std_cell_pins all -nets $PG_CHECK_NETS > $OUT/rpt/pg_conn_final.rpt
  check_pg_drc > $OUT/rpt/pg_drc_final.rpt
  # An error wholly inside an IO cell is in the foundry's cell, seen through its abstract (IHP's corner has
  # same-net VSS notches on TopMetal1); the foundry DRC on the real GDS judges those. Errors elsewhere are ours.
  open_drc_error_data DRC_report_by_check_pg_drc
  set iobb [lmap c [get_object_name [get_cells -quiet -filter is_io==true]] { get_attribute [get_cells $c] boundary_bbox }]
  set pg_out 0; set pg_io {}
  foreach_in_collection e [get_drc_errors -quiet -error_data DRC_report_by_check_pg_drc] {
    lassign [get_attribute $e bbox] ell eur
    lassign $ell ex0 ey0; lassign $eur ex1 ey1
    set inside 0
    foreach bb $iobb {
      lassign $bb cll cur
      if {$ex0 >= [lindex $cll 0] && $ey0 >= [lindex $cll 1] && $ex1 <= [lindex $cur 0] && $ey1 <= [lindex $cur 1]} { set inside 1; break }
    }
    if {$inside} { lappend pg_io "[get_attribute $e type_name] $ell $eur" } else { incr pg_out }
  }
  set f [open $OUT/rpt/pg_drc_final_split.rpt w]
  puts $f "FLASH_PG_DRC outside_io=$pg_out inside_io=[llength $pg_io]"
  foreach x $pg_io { puts $f "inside_io $x" }
  close $f
  report_timing -scenarios [all_scenarios] -delay_type max -max_paths 10 > $OUT/rpt/timing_setup_final.rpt
  report_timing -scenarios [all_scenarios] -delay_type min -max_paths 10 > $OUT/rpt/timing_hold_final.rpt
  report_constraints -all_violators -scenarios [all_scenarios] > $OUT/rpt/violators_final.rpt
  report_power -scenarios func_$POWER_CORNER > $OUT/rpt/power_final.rpt
  report_utilization > $OUT/rpt/utilization_final.rpt
  report_design -all > $OUT/rpt/design_final.rpt

  # Every port's net carries the port's name before anything is written. A level shifter on a port leaves the
  # port's name on the net before the shifter and a new net, ls_N, on the port. The Verilog then aliases the port
  # to ls_N with an assign, while the DEF, and so the SPEF, keep the port's name on the net before the shifter,
  # and PrimeTime would put those parasitics on the wrong net.
  set renamed 0
  set tied 0
  foreach_in_collection port [get_ports] {
    set pn [get_object_name $port]
    set net [get_nets -quiet -of_objects $port]
    # An unused input has no net, and write_def gives it one named _dummynetN. StarRC then names the SPEF port
    # after that net and PrimeTime cannot find it (PARA-124).
    if {![sizeof_collection $net] && ![sizeof_collection [get_nets -quiet $pn]]} {
      connect_net -net [create_net $pn] $port
      incr tied
      continue
    }
    if {![sizeof_collection $net] || [get_object_name $net] eq $pn} continue
    set other [get_nets -quiet $pn]
    if {[sizeof_collection $other]} { set_attribute $other name "[regsub -all {[][]} $pn _]_int" }
    set_attribute $net name $pn
    incr renamed
  }
  puts "FLASH_PORT_NETS_RENAMED $renamed FLASH_PORT_NETS_CREATED $tied"
  write_verilog -exclude {pg_objects leaf_module_declarations physical_only_cells empty_modules} $OUT/out/$DESIGN.v
  # Placement reorders the scan chains, so ATPG needs the protocol written from the final netlist.
  if {[info exists DFT_SETUP]} {
    foreach mode [all_test_modes] { write_test_protocol -test_mode $mode -output $OUT/out/$DESIGN.$mode.spf }
    report_scan_chain > $OUT/rpt/scan_chain_final.rpt
  }
  foreach p [concat {*}[dict values $IO_RING]] {
    if {![sizeof_collection [get_cells -quiet $p]]} { error "pad $p is missing from the finished chip" }
  }
  # A chip's signal ports are the pads' pad pins, so the ports themselves have no geometry. StarRC then infers
  # each port from the overlapping pad pin and can lose the top-level connection, which PrimeTime rejects
  # (PARA-006). A terminal on the pad pin gives every port its shape.
  if {[llength $IO_RING]} {
    set port_terms 0
    foreach_in_collection port [get_ports -quiet -filter "port_type == signal"] {
      set padpins {}
      foreach_in_collection pin [get_pins -quiet -of_objects [get_nets -quiet -of_objects $port]] {
        if {[get_attribute [get_cells -of_objects $pin] is_io]} { lappend padpins $pin }
      }
      if {[llength $padpins] != 1} continue
      # place_io leaves a terminal with no layer, which write_def drops; build it from the pin's own shape.
      set shp [index_collection [get_shapes -quiet -of_objects [lindex $padpins 0]] 0]
      if {![sizeof_collection $shp]} continue
      set oldt [get_terminals -quiet -of_objects $port]
      if {[sizeof_collection $oldt]} { remove_terminals $oldt }
      create_terminal -port $port -layer [get_attribute $shp layer_name] -boundary [get_attribute $shp bbox]
      incr port_terms
    }
    puts "FLASH_IO_PORT_TERMINALS $port_terms"
  }
  # LVS netlist: power connections plus fillers, decaps and diodes, which are in the GDS too. With -include,
  # pads, IO corners and IO fillers are left out unless named, and IHP's contain devices and substrate ties.
  write_verilog -include {pg_netlist physical_only_cells filler_cells diode_cells pad_cells corner_cells pad_spacer_cells} \
    $OUT/out/$DESIGN.pg.v
  write_def $OUT/out/$DESIGN.def
  if {[info exists UPF_FILE]} { save_upf $OUT/out/$DESIGN.upf }
  # GDS_UNITS, optional in pdk.tcl: database units per micron. FC's default, 10000, can put a library's 45-degree
  # shapes off the manufacturing grid; writing at the library's own units keeps them on it.
  write_gds -hierarchy all -long_names -lib_cell_view frame {*}[expr {[info exists GDS_UNITS] ? [list -units $GDS_UNITS] : {}}] \
    -merge_files [concat $GDS_CELLS $EXTRA_GDS] -merge_gds_top_cell $DESIGN -layer_map $GDS_MAP -output_pin all $OUT/out/$DESIGN.gds
  check_legality -verbose > $OUT/rpt/legality_final.rpt
  stage_done final
}
puts "FLASH_FLOW_DONE"
exit
