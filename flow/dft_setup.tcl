# Scan for flash_soc: one internal chain, mux-D scan flops, test_mode held at 1 during test.
# Signal types follow the RM TP_SCAN configuration (examples/scan_configuration.fc.tcl).
set_app_options -name dft.test_default_period -value 100
set_app_options -name dft.test_default_delay  -value 0
set_app_options -name dft.test_default_strobe -value 40
set_dft_signal -view existing_dft -type ScanClock -port clk -timing {45 55}
set_dft_signal -view existing_dft -type Reset     -port rst_n -active_state 0
set_dft_signal -view existing_dft -type Constant  -port test_mode -active_state 1
set_dft_signal -view spec -type ScanEnable  -port scan_en -active_state 1
set_dft_signal -view spec -type ScanDataIn  -port scan_in
set_dft_signal -view spec -type ScanDataOut -port scan_out
set_scan_configuration -chain_count 1 -clock_mixing no_mix

set_dft_signal -view spec -type ScanEnable -port scan_en -active_state 1 -hookup_pin u_pscen/p2c
set_dft_signal -view spec -type ScanDataIn -port scan_in -hookup_pin u_pscin/p2c
set_dft_signal -view spec -type ScanDataOut -port scan_out -hookup_pin u_pscout/c2p
