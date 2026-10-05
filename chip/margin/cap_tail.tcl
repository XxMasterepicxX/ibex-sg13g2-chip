# Appended to a copy of pt_policy.tcl: capacitance slack on every SRAM output pin, smallest first.
set rows {}
foreach_in_collection p [get_pins -hierarchical -filter "direction == out && lib_pin_name =~ A_DOUT*"] {
  set limit [get_attribute -quiet $p max_capacitance]
  set load [get_attribute -quiet [get_nets -of_objects $p] total_capacitance_max]
  if {$limit ne "" && $load ne ""} { lappend rows [list [expr {$limit - $load}] [get_object_name $p] $load $limit] }
}
foreach r [lrange [lsort -real -index 0 $rows] 0 11] { puts "FLASH_CAP [format %.4f [lindex $r 0]] [lindex $r 1] load=[lindex $r 2] limit=[lindex $r 3]" }
exit
