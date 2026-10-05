# Raise hold slack to 0.15 ns at this corner in both timing modes, in one PrimeTime session so the changes form one
# list: functional first, then scan shift with test_mode and scan_en at 1, then back to functional for the reports.
# Each fix keeps at least 0.5 ns of setup slack here; the slow corner is checked separately with the change list.
set flash_hold_fix {fix_eco_timing -type hold -hold_margin 0.15 -slack_lesser_than 0.15 -setup_margin 0.5 -methods {size_cell insert_buffer} -buffer_list $ECO_HOLD_BUFFERS}
eval $flash_hold_fix
set_case_analysis 1 [get_ports {test_mode scan_en}]
eval $flash_hold_fix
puts "FLASH_HOLD_SHIFT hold_wns=[get_attribute [get_timing_paths -delay_type min] slack]"
set_case_analysis 0 [get_ports {test_mode scan_en}]
