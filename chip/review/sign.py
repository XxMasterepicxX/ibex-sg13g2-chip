# Signs the four review records with your name and today's date and installs them in the run's signoff folder.
# Sign only after reading verify.py's output and agreeing with every basis below. If the evidence says something
# else, do not sign: find out why. A signed record changes the signoff inputs, so run chip/final_signoff.sh after.
# usage: sign.py <run_folder> "<Your Name>"
import datetime, json, shutil, sys
from pathlib import Path
R = Path(sys.argv[1]).resolve()
who = sys.argv[2].strip()
assert who, 'reviewer name required'
when = datetime.date.today().isoformat()
D, S = R / 'review', R / 'signoff'
basis = {
    'timing_waivers.json': 'check_timing lists only u_soc/u_imem/A_BIST_CLK and u_soc/u_dmem/A_BIST_CLK as unclocked register pins at every corner and mode. In out/flash_chip.v every A_BIST_CLK, A_BIST_EN and A_BIST_MEN pin of both SRAMs is driven by a sg13g2_tielo cell.',
    'timing_coverage.json': 'Untested checks per corner: SCD and SCE scan pins held by test_mode and scan_en in functional mode, and D pins in shift mode; RESET_B min pulse width with no clock on the reset net, while recovery and removal on those pins are checked; RESET_B of non-resettable flops, SRAM BIST and A_BM pins held constant; SRAM BIST conditional arcs; constant pins. No setup or hold endpoint is untested for lack of a clock.',
    'formality_coverage.json': 'One point excluded on both sides, scan_out: the RTL ties it to 0 and scan insertion connects it to the last scan flop. ATPG replay through the pads covers it. No point is unmatched.',
}
for name, why in basis.items():
    d = json.loads((D / name).read_text())
    d['reviewed_by'], d['reviewed_on'], d['review_basis'] = who, when, why
    (D / name).write_text(json.dumps(d, indent=2))
    shutil.copy2(D / name, S / name)
    print('SIGNED', name)
e = S / 'atpg/evidence.json'
d = json.loads(e.read_text())
d['reviewed_by'], d['reviewed_on'] = who, when
d['drc_warning_reason'] = ('All are vendor model limitations, none a design defect. N2: specify blocks in sg13g2_stdcell.v. N16, N21: '
                           'UDP notation in sg13g2_udp.v. B6, B13: pad cell supply pins, which ATPG does not model. B8: the input of '
                           'the sg13g2_antennanp diode model, which drives nothing. B9, B10: flop model notifier nets and net names '
                           'the netlist declares without driver or load.')
e.write_text(json.dumps(d, indent=2))
print('SIGNED atpg/evidence.json')
