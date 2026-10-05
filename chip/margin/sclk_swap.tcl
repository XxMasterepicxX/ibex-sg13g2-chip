# u_soc/sclk_s_reg[2] uses only Q_N, so its Q pin drives nothing and misses the 1 fF minimum load at every corner.
# The register becomes the Q-only flop, keeping its name for Formality, and an inverter makes the old Q_N net.
set ff [get_cells {u_soc/sclk_s_reg[2]}]
set qn [get_nets -of_objects [get_pins {u_soc/sclk_s_reg[2]/Q_N}]]
set q [get_nets -quiet -of_objects [get_pins {u_soc/sclk_s_reg[2]/Q}]]
disconnect_net -net $qn [get_pins {u_soc/sclk_s_reg[2]/Q_N}]
if {![sizeof_collection $q]} {
  set q [create_net sclk_s2_q]
  connect_net -net $q [get_pins {u_soc/sclk_s_reg[2]/Q}]
}
set_reference $ff -to_block sg13g2_dfrbpq_1
create_cell sclk_s2_qn sg13g2_inv_1
connect_net -net $q [get_pins sclk_s2_qn/A]
connect_net -net $qn [get_pins sclk_s2_qn/Y]
puts "FLASH_SCLK_SWAP [get_attribute $ff ref_name] [get_object_name [get_nets -of_objects [get_pins sclk_s2_qn/Y]]]"
