    drc { foreach t {max_transition max_capacitance} {
      if {[info exists ECO_BUFFERS]} {
        fix_eco_drc -type $t -methods {size_cell insert_buffer} -buffer_list $ECO_BUFFERS
      } else {
        fix_eco_drc -type $t -methods {size_cell}
      }
      fix_eco_drc -type $t -methods {size_cell} -cell_type clock_network
    } }
    manual {
      source $env(MANUAL_CHANGES)
      redirect -variable mc { report_constraint -all_violators -max_capacitance -max_transition -nosplit }
      set fh [open $R/manual_violators.rpt w]; puts $fh $mc; close $fh
      puts "FLASH_MANUAL_VIOLATORS [llength [regexp -all -inline -line {VIOLATED} $mc]]"
    }
