# Timing constraints shared by Fusion Compiler and PrimeTime.
# PERIOD_NS is the signoff clock period. Fusion Compiler tightens it by PNR_MARGIN,
# so place and route is pushed harder and signed off at the real target. PrimeTime and
# PrimePower unset PNR_MARGIN.
set clk_period $PERIOD_NS
if {[info exists PNR_MARGIN]} { set clk_period [expr {$PERIOD_NS * (1.0 - $PNR_MARGIN)}] }

create_clock -name clk -period $clk_period [get_ports $CLK_PORT]
# I/O is timed against a virtual clock, the external flop's clock, which has no tree. With I/O on clk,
# Fusion Compiler and PrimeTime disagree on the clock latency an output port sees after CTS.
create_clock -name vclk -period $clk_period
set_clock_uncertainty -setup [expr {0.05 * $PERIOD_NS}] [get_clocks {clk vclk}]
# Hold gets the same treatment. Fusion Compiler fixes hold to about 0 slack, and PrimeTime SI with
# StarRC can read it slightly worse, so a fixed guard band.
set hold_uncertainty 0.05
if {[info exists PNR_MARGIN]} { set hold_uncertainty [expr {$hold_uncertainty + 0.05}] }
set_clock_uncertainty -hold $hold_uncertainty [get_clocks {clk vclk}]
set_clock_transition 0.15 [get_clocks clk]
# OCV_DERATE, optional in pdk.tcl or run_cfg: {early late}, a flat on-chip-variation derate on cell delays for kits
# with no AOCV or POCV data, in Fusion Compiler and PrimeTime alike, so place and route closes what signoff checks.
# Clock reconvergence pessimism removal goes with it.
if {[info exists OCV_DERATE]} {
  lassign $OCV_DERATE early late
  set_timing_derate -cell_delay -early $early
  set_timing_derate -cell_delay -late $late
  set_timing_derate -net_delay -early $early
  set_timing_derate -net_delay -late $late
  if {$synopsys_program_name eq "fc_shell"} {
    set_app_options -name time.remove_clock_reconvergence_pessimism -value true
  } else {
    set_app_var timing_remove_clock_reconvergence_pessimism true
  }
}

set data_in  [remove_from_collection [all_inputs] [get_ports $CLK_PORT]]
set_input_delay  [expr {0.2 * $PERIOD_NS}] -clock vclk $data_in
set_output_delay [expr {0.2 * $PERIOD_NS}] -clock vclk [all_outputs]
# Functional timing holds test pins at their inactive values, optional in run_cfg: CASE_ANALYSIS {port value ...}.
# TIMING_MODE shift, set by Fusion Compiler's shift scenarios and PrimeTime's ptshift step, times scan shift
# instead: SHIFT_CASE_ANALYSIS from run_cfg, else test_mode and scan_en at 1.
set case_values {}
if {[info exists TIMING_MODE] && $TIMING_MODE eq "shift"} {
  set case_values [expr {[info exists SHIFT_CASE_ANALYSIS] ? $SHIFT_CASE_ANALYSIS : {test_mode 1 scan_en 1}}]
} elseif {[info exists CASE_ANALYSIS]} {
  set case_values $CASE_ANALYSIS
}
foreach {p v} $case_values { set_case_analysis $v [get_ports $p] }
if {[info exists IO_RING] && [llength $IO_RING]} {
  # A chip's ports are bond pads, driven and loaded by the board, not by core cells. A core buffer driving a pad
  # at the core voltage mismatches the IO library's supply at every corner (PVT-034). Board edge and load,
  # overridable in run_cfg: IO_INPUT_TRANSITION ns, IO_OUTPUT_LOAD pF.
  set_input_transition [expr {[info exists IO_INPUT_TRANSITION] ? $IO_INPUT_TRANSITION : 1.0}] [all_inputs]
  set_load [expr {[info exists IO_OUTPUT_LOAD] ? $IO_OUTPUT_LOAD : 5.0}] [all_outputs]
} else {
  set_driving_cell -lib_cell $DRIVE_CELL $data_in
  set_load 0.01 [all_outputs]
}
# SDC_EXTRA, optional in run_cfg: a design's own SDC, sourced last, for what one clock cannot say: more clocks,
# generated clocks, clock groups and exceptions. It may use CLK_PORT.
if {[info exists SDC_EXTRA]} { source $SDC_EXTRA }
