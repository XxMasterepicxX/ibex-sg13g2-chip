# IHP sg13g2_io pad cells as a Fusion Compiler reference library. The LEF gives the corner cell
# CLASS PAD SPACER, so it is marked as a corner here; create_io_corner_cell needs design_type corner.
set H $env(HOME)
create_workspace sg13g2_io -flow normal -technology $H/flash/ihp/tech/ihp_sg13g2_skeleton.tf
read_lef -merge_action update $H/flash/pdk/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_stdcell/lef/sg13g2_tech.lef
read_lef $H/flash/pdk/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_io/lef/sg13g2_io.lef
read_db [list $H/flash/ihp/db/sg13g2_io_slow_1p08V_3p0V_125C.db $H/flash/ihp/db/sg13g2_io_typ_1p2V_3p3V_25C.db $H/flash/ihp/db/sg13g2_io_fast_1p32V_3p6V_m40C.db]
puts "FLASH_BEFORE [get_attribute -quiet [get_lib_cells */sg13g2_Corner] design_type]"
set_attribute -objects [get_lib_cells */sg13g2_Corner] -name design_type -value corner
puts "FLASH_AFTER [get_attribute -quiet [get_lib_cells */sg13g2_Corner] design_type]"
# The IO LEF has no antenna data, so Zroute skipped every net into an output pad (ZRT-311). In IHP's CDL, c2p
# drives two sg13g2_LevelUpInv inputs, each with thin-oxide gates 2.75u and 4.75u wide at 0.13u long: 1.95 um2.
# Their thick-oxide gate is left out, which makes FC's check stricter; the foundry deck judges the real pad.
set ga {}
foreach l {Metal1 Metal2 Metal3 Metal4 Metal5 TopMetal1 TopMetal2} { lappend ga oxide1 $l 1.95 }
set_attribute -objects [get_lib_pins {*/sg13g2_IOPadOut4mA/c2p */sg13g2_IOPadOut16mA/c2p */sg13g2_IOPadOut30mA/c2p}] -name gate_area -value $ga
puts "FLASH_C2P_GATE_AREA [get_attribute [index_collection [get_lib_pins */sg13g2_IOPadOut4mA/c2p] 0] gate_area]"
check_workspace
commit_workspace -force -output sg13g2_io.ndm
exit
