# Fast corner: noise fixes that keep 0.5 ns of setup and 0.1 ns of hold slack.
fix_eco_drc -type noise -methods {size_cell insert_buffer} -buffer_list $ECO_BUFFERS -setup_margin 0.5 -hold_margin 0.1
