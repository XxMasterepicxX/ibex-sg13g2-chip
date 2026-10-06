# Worst and best wire models from IHP's process spec

IHP publishes only a typical wire model, `ihp/rc/sg13g2_typ.itf`. Timing signoff needs a worst case for setup and
a best case for hold, so these two models were derived from the ranges in IHP's public SG13G2 process
specification, revision 1.2, in the kit at `ihp-sg13g2/libs.doc/doc`. They are ours, not IHP's, and they are not
foundry-qualified corners.

- `rcmax` uses the maximum sheet resistance of every metal, the maximum resistance of every via and contact, and
  the top of the dielectric constant ranges in the spec's stack drawing: oxide 4.1 +/- 0.1 and the top nitride
  6.6 +/- 0.1.
- `rcmin` uses the minimums.
- Every thickness is the same as in the typical model. The spec lists only target thicknesses for the metal and
  dielectric layers, so no thickness or width was varied.

| Layer | Parameter | Spec section | Min | Max |
|---|---|---|---:|---:|
| Metal1 | RSMET1 | 2.13 | 0.085 | 0.135 |
| Metal2 | RSMET2 | 2.13 | 0.073 | 0.103 |
| Metal3 | RSMET3 | 2.13 | 0.073 | 0.103 |
| Metal4 | RSMET4 | 2.13 | 0.073 | 0.103 |
| Metal5 | RSMET5 | 2.13 | 0.073 | 0.103 |
| TopMetal1 | RSTM1 | 2.13 | 0.015 | 0.021 |
| TopMetal2 | RSTM2 | 2.13 | 0.0075 | 0.0145 |
| Via1 | RVIA1 | 2.14 | 5.0 | 20.0 |
| Via2 | RVIA2 | 2.14 | 5.0 | 20.0 |
| Via3 | RVIA3 | 2.14 | 5.0 | 20.0 |
| Via4 | RVIA4 | 2.14 | 5.0 | 20.0 |
| TopVia1 | RTV1 | 2.14 | 1.0 | 4.0 |
| TopVia2 | RTV2 | 2.14 | 0.5 | 2.2 |
| Cont | RCM1NPLY | 2.14 | 8.0 | 20.0 |
| ContIntActiv | RCM1NSD | 2.14 | 8.0 | 22.0 |

Sheet resistance is in ohms per square, converted from the spec's milliohms. Via and contact values are ohms per
cut.

IHP's ITF declares the name oxTopMetal2 twice, and grdgenxo rejects that. All three models rename the second
declaration oxTopMetal2_b. Both layers are kept with their original values.

Source ITF SHA256: 780ce0ad3373c1d05645e0bf500cd1fc9a84d31bee220903599d65810720ce79
Source PDF SHA256: 974d505886ee62932a50c52c22fbc290db4a70d8a7ce129c0ca8d7934aee160e
