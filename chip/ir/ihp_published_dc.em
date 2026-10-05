# IHP SG13G2 DC EM limits, process spec rev 1.2 section 2.15, 11 years at 105 C.
# Metals: rhtech's form is em * (W_um - em_adjust) mA. The spec's flat limit for narrow lines, 0.36 mA on Metal1
# from 0.16 to 0.36 um and 0.6 mA on Metal2 to Metal5 from 0.2 to 0.3 um, is above the per-width line there, so
# using the per-width value at every width is stricter than the spec.
# Vias and contacts: mA per cut.
Metal1 1.0
Metal2 2.0
Metal3 2.0
Metal4 2.0
Metal5 2.0
TopMetal1 15.0
TopMetal2 16.0
Cont 0.3
Via1 0.4
Via2 0.4
Via3 0.4
Via4 0.4
TopVia1 1.4
TopVia2 10.0
