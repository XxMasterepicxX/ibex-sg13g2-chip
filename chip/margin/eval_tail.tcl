# Appended to a copy of pt_policy.tcl: apply a change list, then name the changed cells that sit on a setup path
# under FLASH_SETUP_FLOOR or drive a pin over its transition or capacitance limit, and count every electrical and
# noise violation left, changed cell or not.
set changes [open $env(CHANGE_LIST)]; set text [read $changes]; close $changes
set changed {}
foreach {all name} [regexp -all -inline {new_cell_names \{([^\}]+)\}} $text] { lappend changed $name }
foreach {all name} [regexp -all -inline {(?n)^size_cell \{([^\}]+)\}} $text] { lappend changed $name }
# A new net has no extracted parasitics. With a wire load model PrimeTime gave the net of a buffer inserted on an
# SRAM pin 0.14 pF, more than twice the routed original; Fusion Compiler places such a buffer at the pin. New nets
# count pin loads only here, and the final signoff extracts the real wires.
catch {set_app_var auto_wire_load_selection false}
catch {remove_wire_load_model [current_design]}
source $env(CHANGE_LIST)
update_timing -full
set floor $env(FLASH_SETUP_FLOOR)
set bad [dict create]
foreach_in_collection p [get_timing_paths -delay_type max -slack_lesser_than $floor -max_paths 20000 -nworst 4] {
  foreach_in_collection pt [get_attribute $p points] {
    set c [get_object_name [get_cells -quiet -of_objects [get_attribute $pt object]]]
    if {$c in $changed} { dict set bad $c setup }
  }
}
redirect -variable drc { report_constraint -all_violators -max_transition -max_capacitance -nosplit }
set drc_viol [regexp -all {\(VIOLATED} $drc]
foreach line [split $drc \n] {
  if {[regexp {^\s*(\S+)\s+\S+\s+\S+\s+\S+\s+\(VIOLATED} $line all pin]} {
    set net [get_nets -quiet -of_objects [get_pins -quiet $pin]]
    if {[sizeof_collection $net]} {
      foreach_in_collection d [get_pins -quiet -leaf -of_objects $net -filter "direction == out"] {
        set c [get_object_name [get_cells -of_objects $d]]
        if {$c in $changed} { dict set bad $c drc }
      }
    }
  }
}
update_noise
redirect -variable nz { report_noise -all_violators -nosplit }
set noise_viol [llength [regexp -all -inline -line {\s-\d+\.\d+\s*$} $nz]]
foreach line [split $drc \n] { if {[string match "*(VIOLATED*" $line]} { puts "FLASH_DRC_VIOL $line" } }
foreach line [split $nz \n] { if {[regexp {\s-\d+\.\d+\s*$} $line]} { puts "FLASH_NOISE_VIOL $line" } }
# What margin_fix.sh needs for targeted fixes: the driver of each noise victim's net and of each pin over its
# limit, and every endpoint under the 0.09 ns hold floor.
proc flash_driver {pin} {
  set d [get_pins -quiet -leaf -of_objects [get_nets -quiet -of_objects [get_pins -quiet $pin]] -filter "direction == out"]
  if {[sizeof_collection $d]} { return "[get_object_name $d] [get_object_name [get_cells -of_objects $d]] [get_attribute [get_cells -of_objects $d] ref_name]" }
  return ""
}
foreach line [split $nz \n] {
  if {[regexp {^\s*(\S+)\s+\(\S+\).*\s-\d+\.\d+\s*$} $line all pin]} { puts "FLASH_NOISE_DRIVER [flash_driver $pin]" }
}
foreach line [split $drc \n] {
  if {[regexp {^\s*(\S+)\s+\S+\s+\S+\s+\S+\s+\(VIOLATED} $line all pin]} { puts "FLASH_DRC_DRIVER $pin [flash_driver $pin]" }
}
foreach_in_collection p [get_timing_paths -delay_type min -slack_lesser_than 0.09 -max_paths 50 -nworst 1] {
  puts "FLASH_HOLD_END [get_object_name [get_attribute $p endpoint]] [format %.3f [get_attribute $p slack]]"
}
set fh [open $env(SCRATCH)/bad_cells_${CORNER}_$TIMING_MODE.txt w]
dict for {c why} $bad { puts $fh "$c $why" }
close $fh
puts "FLASH_EVAL corner=$CORNER mode=$TIMING_MODE changed=[llength $changed] bad=[dict size $bad] drc_viol=$drc_viol noise_viol=$noise_viol setup_wns=[get_attribute [get_timing_paths -delay_type max] slack] hold_wns=[get_attribute [get_timing_paths -delay_type min] slack]"
exit
