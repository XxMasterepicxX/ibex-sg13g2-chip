create_workspace sg13g2_sram -flow normal -technology $env(HOME)/flash/ihp/tech/ihp_sg13g2_skeleton.tf
read_lef -merge_action update $env(HOME)/flash/pdk/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_stdcell/lef/sg13g2_tech.lef
read_lef $env(HOME)/flash/ihp/sram_lef/RM_IHPSG13_1P_1024x32_c2_bm_bist.lef
read_db [list $env(HOME)/flash/ihp/sram_db/RM_IHPSG13_1P_1024x32_c2_bm_bist_slow_1p08V_125C.db $env(HOME)/flash/ihp/sram_db/RM_IHPSG13_1P_1024x32_c2_bm_bist_typ_1p20V_25C.db $env(HOME)/flash/ihp/sram_db/RM_IHPSG13_1P_1024x32_c2_bm_bist_fast_1p32V_m55C.db]
check_workspace
commit_workspace -output sg13g2_sram.ndm
exit
