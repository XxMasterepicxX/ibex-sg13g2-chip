# Formality: RTL against the routed netlist.
source $env(RUN_CFG)
set R $OUT/signoff/formality
if {![info exists PDK]} { error "run_cfg must set PDK" }
source $env(HOME)/flash/pdk_cfg/$PDK/pdk.tcl
foreach {c v t db} $CORNERS { set LIB($c) $db }
file mkdir $R
# Default limit of 20 hid failing points in the old runs.
set_app_var verification_failing_point_limit 2000
set_app_var synopsys_auto_setup true
# Every Fusion Compiler session's guidance, in flow order. $DESIGN.svf is the single-file layout of older runs.
# EXTRA_SVF, optional in run_cfg: guidance from tools ahead of Fusion Compiler, such as Design Compiler.
# FM_REF_NETLIST, optional in run_cfg: a gate netlist, such as Design Compiler's, as the reference instead of the RTL,
# for designs whose RTL this Formality cannot parse; the check then covers what place and route changed, so only
# Fusion Compiler's guidance applies. CVA6: Y-2026.03 stops on standalone generate blocks in its vendored RTL.
set svfs [expr {[info exists EXTRA_SVF] && ![info exists FM_REF_NETLIST] ? $EXTRA_SVF : {}}]
foreach s {"" .setup .synth .floorplan .pg .place .cts .route .ladder .final} {
  if {[file exists $OUT/out/$DESIGN$s.svf]} { lappend svfs $OUT/out/$DESIGN$s.svf }
}
puts "FLASH_FM_SVF $svfs"
set_svf -ordered {*}$svfs

read_db -technology_library $DB_DIR/$LIB($POWER_CORNER).db
if {[info exists MACRO_DB] && [dict exists $MACRO_DB $POWER_CORNER]} {
  foreach db [dict get $MACRO_DB $POWER_CORNER] { read_db -technology_library $db }
}
# `include files resolve through search_path, the way FC resolves them through INC_DIRS. Without it Formality lost
# common_cells/registers.svh on ext_cv32e40p and ext_common_cells, and had no reference design.
if {[info exists INC_DIRS] && [llength $INC_DIRS]} { set_app_var search_path [concat $INC_DIRS [get_app_var search_path]] }
# FC defines SYNTHESIS when it reads RTL; Formality does not, so assertion macro libraries (lowRISC prim_assert,
# common_cells assertions.svh) fed this 2018 parser syntax it cannot read, and there was no reference design.
if {[info exists FM_REF_NETLIST]} {
  read_verilog -r -netlist $FM_REF_NETLIST
} elseif {[info exists ::env(FM_RTL)]} {
  read_sverilog -r $::env(FM_RTL)
} else {
  read_sverilog -r -define [concat SYNTHESIS $DEFINES] $RTL_FILES
}
set_top r:/WORK/$DESIGN
read_verilog -i $OUT/out/$DESIGN.v
set_top i:/WORK/$DESIGN
# The router's antenna diodes have one input and no logic, so Formality lists their inputs as unmatched black-box
# pins. LVS checks the diodes; Formality's implementation copy leaves them out.
if {[info exists DIODE_CELL]} {
  set fh [open $OUT/out/$DESIGN.v]
  set diodes [regexp -all -inline -line [format {^\s*%s\s+(\S+)\s*\(} $DIODE_CELL] [read $fh]]
  close $fh
  current_design i:/WORK/$DESIGN
  foreach {line name} $diodes { remove_cell [string trimleft $name {\\}] }
  puts "FLASH_FM_DIODES_REMOVED [expr {[llength $diodes] / 2}]"
}
# A design with a UPF: its power intent on each side, the original on the RTL and Fusion Compiler's saved one on
# the netlist. Without it, the level shifters are unlinked power cells and 2000 points failed (saed_ibex_mv5).
if {[info exists UPF_FILE]} {
  load_upf -r $UPF_FILE
  load_upf -i $OUT/out/$DESIGN.upf
}
# FM_CONSTANTS, optional in run_cfg: ports held on both sides, such as test pins in functional mode.
if {[info exists FM_CONSTANTS]} {
  foreach {p v} $FM_CONSTANTS {
    set_constant -type port r:/WORK/$DESIGN/$p $v
    set_constant -type port i:/WORK/$DESIGN/$p $v
  }
}
# FM_DONT_VERIFY, optional in run_cfg: test-only outputs whose functional value changes by design. The RTL
# ties scan_out to 0; after scan insertion it carries the chain's last flop even in functional mode.
# An entry with a / is a black-box pin: a supply pad's supply pins, which the netlist Formality reads leaves out
# and LVS checks, or the scan-out pad's input (gf180 chip on 2026: 16 and 1 of 17 failing points, 9-25).
if {[info exists FM_DONT_VERIFY]} {
  foreach p $FM_DONT_VERIFY {
    if {[string first / $p] >= 0} {
      set_dont_verify_points [list r:/WORK/$DESIGN/$p i:/WORK/$DESIGN/$p]
    } else {
      set_dont_verify_points -type port [list r:/WORK/$DESIGN/$p i:/WORK/$DESIGN/$p]
    }
  }
}
match
report_unmatched_points > $R/unmatched.rpt
set ok [verify]
report_status > $R/status.rpt
report_failing_points > $R/failing.rpt
puts "FLASH_FM verified=$ok"
exit
