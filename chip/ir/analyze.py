# RedHawk-SC script for one case, run by run.py. IR_CASE_DIR is <workdir>/<case>; results go to its baseline folder.
# Power comes from a 10% toggle rate, or from the case's SAIF when its config.json names one.
import os, json, traceback
from pathlib import Path
case = Path(os.environ['IR_CASE_DIR'])
folder = case / 'baseline'
folder.mkdir(exist_ok=True)
c = json.loads((case / 'config.json').read_text())
def status(s):
    (folder / 'progress.json').write_text(json.dumps({'stage': s}))
    print('IR_STAGE', s, flush=True)
try:
    status('configure')
    options = gp.get_default_options()
    launcher = gp.create_local_launcher('ir_local')
    gp.register_default_launcher(launcher, min_num_workers=2, max_num_workers=2)
    db = gp.open_db(str(folder / 'db'), force_delete=False)
    status('liberty')
    lv = db.create_liberty_view(c['libs'], tag='lv', options=options)
    status('technology')
    tech = db.create_technology_view(c['itf'], tag='tech', options=options)
    status('design')
    dv = db.create_design_view(top_cell_name=c['top'], def_files=[c['def']], lef_files=c['lefs'], lib_views={'typ': lv}, tech_view=tech, tech_layer_map_file=c['map'], tag='dv', options=options)
    status('sources')
    mdv = db.create_modified_design_view(dv, eco_commands=package.parse_ploc_func(str(case / 'sources.ploc')), tag='mdv', options=options)
    status('extract')
    ev = db.create_extract_view(mdv, tech_view=tech, tech_layer_map_file=c['map'], tag='ev', options=options, settings={'calculate_spr': True, 'detail_extraction_net_type': 'pg', 'extract_temperature': 25.0})
    status('timing')
    sdc = folder / 'redhawk.sdc'
    sdc.write_text('create_clock -name main -period ' + str(c['period_ns']) + ' [get_ports ' + c['clock_port'] + ']\n')
    tv = db.create_timing_view(mdv, process_corner='typ', sdc_files=[{'file_name': str(sdc), 'time_unit': 1e-9}], tag='tv', options=options)
    status('power')
    pvt = {'voltage_levels': {'VDD': c['vdd'], 'VSS': 0.0}, 'temperature': 25.0, 'process_corner': 'typ'}
    if 'saif' in c:
        swa = db.create_switching_activity_view(timing_view=tv, saif_files=[{'file_name': c['saif'], 'preamble': 'tb_flash_soc/dut'}], settings={'annotate_net_in_saif': True}, tag='swa', options=options)
    else:
        swa = db.create_switching_activity_view(timing_view=tv, settings={'object_settings': {'design_values': {'sequential_output_pin_toggle_rate': 0.1, 'combinational_pin_toggle_rate': 0.1}}}, tag='swa', options=options)
    power = db.create_power_view(switching_activity_view=swa, extract_view=ev, timing_view=tv, settings={'pvt': pvt}, tag='power', options=options)
    power.write_instance_power_file(str(folder / 'instance_power.ipf'))
    (folder / 'total_power.json').write_text(json.dumps({str(n): v for n, v in power.get_total_power().items()}, default=str))
    status('static_scenario')
    scn = db.create_scenario_view(tv, ev, power_view=power, tag='static', options=options, settings={'scenario_type': 'Static', 'pvt': pvt})
    status('simulation')
    sv = db.create_simulation_view(ev, tag='sv', options=options)
    av = db.create_analysis_view(sv, scn, tag='static_av', options=options, settings={'keep_stats_level': 'Full'})
    status('report')
    data = emir_reports.get_instance_voltage_data(av)
    emir_reports.write_instance_voltage_report(data, av, output_file=str(folder / 'static_voltage.rpt'))
    status('em')
    em = db.create_electromigration_view(av, tag='em', options=options)
    emir_reports.write_em_violation_report(emir_reports.get_em_violation_data(em), em, output_file=str(folder / 'em.rpt'))
    emir_reports.write_em_violation_report(emir_reports.get_em_violation_data(em, settings={'object_type': 'via'}), em, output_file=str(folder / 'em_via.rpt'))
    status('finished')
    (folder / 'completed.json').write_text(json.dumps({'assumptions': c['source_strategy'], 'power': 'saif' if 'saif' in c else 'toggle rate 0.1', 'period_ns': c['period_ns'], 'clock_port': c['clock_port'], 'temperature_C': 25, 'def': c['def']}))
    print('IR_ANALYSIS_FINISHED', flush=True)
except Exception as e:
    (folder / 'error.json').write_text(json.dumps({'error_type': type(e).__name__, 'error': str(e)}))
    traceback.print_exc()
    raise
