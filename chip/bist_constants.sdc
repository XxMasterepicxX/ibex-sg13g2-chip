# The SRAM self-test ports are tied low in designs/flash_soc/rtl_v2/flash_soc.v and self-test is never used.
# Stating the constant lets timing tools see these clock pins as tied, not as unclocked registers.
# Found by pin name: in the flat netlist "u_soc/u_imem" is one instance name, not a hierarchy path.
set flash_bist_clk [get_pins -quiet -hierarchical -filter "lib_pin_name == A_BIST_CLK"]
if {[sizeof_collection $flash_bist_clk] != 2} { puts "FLASH_BIST_CONSTANT_PINS [sizeof_collection $flash_bist_clk]" }
if {[sizeof_collection $flash_bist_clk]} { set_case_analysis 0 $flash_bist_clk }
