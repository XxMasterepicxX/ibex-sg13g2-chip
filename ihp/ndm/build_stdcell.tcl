create_workspace sg13g2_stdcell -flow normal -technology ~/flash/ihp/tech/ihp_sg13g2_skeleton.tf
read_lef -merge_action update $env(HOME)/flash/pdk/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_stdcell/lef/sg13g2_tech.lef
read_lef $env(HOME)/flash/pdk/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_stdcell/lef/sg13g2_stdcell.lef
read_db [list ~/flash/ihp/db/sg13g2_stdcell_slow_1p08V_125C.db ~/flash/ihp/db/sg13g2_stdcell_typ_1p20V_25C.db ~/flash/ihp/db/sg13g2_stdcell_fast_1p32V_m40C.db]
check_workspace
commit_workspace -output sg13g2_stdcell.ndm
exit
