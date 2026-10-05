# Slow corner: noise, transition and capacitance fixes that keep 1.0 ns of setup slack. Without -setup_margin,
# fix_eco_drc proceeds however much setup degrades; the plain noise fix took this run from +1.216 to -0.154 ns.
fix_eco_drc -type noise -methods {size_cell insert_buffer} -buffer_list $ECO_BUFFERS -setup_margin 1.0 -hold_margin 0.0
foreach t {max_transition max_capacitance} {
  fix_eco_drc -type $t -methods {size_cell insert_buffer} -buffer_list $ECO_BUFFERS -setup_margin 1.0 -hold_margin 0.0
}
