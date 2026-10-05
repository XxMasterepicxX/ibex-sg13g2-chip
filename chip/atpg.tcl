# TestMAX ATPG for one fault model on a finished scan netlist. Run by chip/atpg.sh.
# env: NETLIST SPF OUTDIR TOP LIBS BLACKBOX MODEL(stuck|transition)
set M $env(MODEL)
set O $env(OUTDIR)
foreach f $env(LIBS) { read_netlist -library $f }
read_netlist $env(NETLIST)
foreach b $env(BLACKBOX) { set_build -black_box $b }
run_build_model $env(TOP)
if {$M eq "transition"} {
  # Launch on capture with one at-speed clock: scan_en is a slow pad signal, and the tester cannot
  # change inputs or strobe outputs at speed through the IO ring.
  set_delay -launch_cycle system_clock
  set_delay -common_launch_capture_clock
  set_delay -nopi_changes
  set_delay -nopo_measures
}
run_drc $env(SPF)
report_rules -fail > $O/drc_rules_$M.rpt
report_violations -all > $O/drc_violations_$M.rpt
set_faults -model $M -summary verbose
add_faults -all
set_atpg -abort_limit 100
run_atpg -auto_compression
report_summaries > $O/summary_$M.rpt
report_summaries
write_faults $O/faults_$M.txt -all -uncollapsed -replace
write_patterns $O/patterns_$M.stil -format stil -replace
report_licenses
puts "FLASH_ATPG_DONE"
exit -force
