# Settings for one build of the chip. chip/new_run.sh copies this into a new run folder and fills in @HOME@ and @RUN@.
# Core 900 x 945: 945 um is 250 rows of 3.78 um, so with a 222 um offset the die edges (1344 x 1389) are
# whole microns, and pads snapped to whole microns leave gaps that IHP 1 um fillers close.
set DESIGN     flash_chip
set RTL_FILES  [list @HOME@/flash/designs/flash_soc/rtl/flash_chip.v @HOME@/flash/designs/flash_soc/rtl/flash_soc.v @HOME@/flash/designs/flash_soc/rtl/ibex_nogate.v @HOME@/flash/designs/flash_soc/rtl/prim_clock_gating_ihp.v]
set INC_DIRS   {}
set DEFINES    {}
set CLK_PORT   clk
set PERIOD_NS  20.0
set PNR_MARGIN 0.10
set UTIL       0.5
set MAX_LAYER  Metal5
set OUT        @RUN@
set PDK        ihp_sg13g2
set CORE_SIZE    {900 945}
set CORE_OFFSET  222
set EXTRA_NDM    [list @HOME@/flash/ihp/sram_ndm/sg13g2_sram.ndm @HOME@/flash/ihp/io_ndm/sg13g2_io.ndm]
set EXTRA_GDS    [list @HOME@/flash/pdk/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_sram/gds/RM_IHPSG13_1P_1024x32_c2_bm_bist.gds @HOME@/flash/pdk/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_io/gds/sg13g2_io.gds]
set EXTRA_LEF    [list @HOME@/flash/ihp/sram_lef/RM_IHPSG13_1P_1024x32_c2_bm_bist.lef @HOME@/flash/pdk/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_io/lef/sg13g2_io.lef]
set EXTRA_CDL    [list @HOME@/flash/pdk/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_sram/cdl/RM_IHPSG13_1P_1024x32_c2_bm_bist.cdl @HOME@/flash/pdk/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_io/cdl/sg13g2_io.cdl]
set MACRO_DB     [dict create slow [list @HOME@/flash/ihp/sram_db/RM_IHPSG13_1P_1024x32_c2_bm_bist_slow_1p08V_125C.db @HOME@/flash/ihp/db/sg13g2_io_slow_1p08V_3p0V_125C.db] typ [list @HOME@/flash/ihp/sram_db/RM_IHPSG13_1P_1024x32_c2_bm_bist_typ_1p20V_25C.db @HOME@/flash/ihp/db/sg13g2_io_typ_1p2V_3p3V_25C.db] fast [list @HOME@/flash/ihp/sram_db/RM_IHPSG13_1P_1024x32_c2_bm_bist_fast_1p32V_m55C.db @HOME@/flash/ihp/db/sg13g2_io_fast_1p32V_3p6V_m40C.db]]
set MACROS       {u_soc/u_imem 244 810.54 R0 u_soc/u_dmem 684.64 810.54 R0}
set MACRO_PG     {VDDARRAY VDD vdd VDD vss VSS iovdd IOVDD iovss IOVSS}
set PLACE_BLOCKAGES {{{222 800.54} {1122 1167}}}
set IO_RING {bottom {u_piovss0 u_pvss0 u_pclk u_prst u_pload u_pvdd0 u_piovdd0} right {u_psclk u_psdi u_ptest u_pscen u_pscin u_pvss1} top {u_pgpio0 u_pgpio1 u_pgpio2 u_pgpio3 u_pvdd1 u_piovss1} left {u_pgpio4 u_pgpio5 u_pgpio6 u_pgpio7 u_pscout u_piovdd1}}
set CASE_ANALYSIS  {test_mode 0 scan_en 0}
set FM_CONSTANTS   {test_mode 0 scan_en 0}
set FM_DONT_VERIFY {scan_out}
set LVS_BLACKBOX   {RM_IHPSG13_1P_1024x32_c2_bm_bist sg13g2_IOPadIn sg13g2_IOPadOut16mA sg13g2_IOPadVdd sg13g2_IOPadVss sg13g2_IOPadIOVdd sg13g2_IOPadIOVss sg13g2_Corner sg13g2_Filler200 sg13g2_Filler400 sg13g2_Filler1000 sg13g2_Filler4000 sg13g2_Filler10000}

set OCV_DERATE {0.95 1.05}
set DFT_SETUP {@HOME@/flash/flow/dft_setup.tcl}
set IO_OUTPUT_LOAD 5.0
set SDC_EXTRA      @HOME@/flash/chip/bist_constants.sdc
