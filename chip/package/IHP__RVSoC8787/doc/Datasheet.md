# RVSoC8787 datasheet

A small RISC-V system on chip in IHP SG13G2: the lowRISC Ibex core, 4 KB of instruction SRAM and 4 KB of data SRAM,
a serial program loader, eight GPIO outputs and a scan chain for manufacturing test. Programs are loaded through
the serial pins, then the core runs them from SRAM.

## Physical

| Item | Value |
|---|---|
| Die, with seal ring | 1708 x 1753 um, 2.99 mm2 |
| Pads | 25: 8 inputs, 9 outputs, 4 core supply, 4 IO supply |
| SRAM | 2 x RM_IHPSG13_1P_1024x32_c2_bm_bist, 1024 words of 32 bits |
| Core supply | VDD 1.2 V |
| IO supply | IOVDD 3.3 V |
| Clock | 50 MHz on `clk`, 20 ns period |
| Metal fill | IHP fill at 1.0 um on Metal2 to Metal5; density 44.6% to 55.0% on every metal |

## Pins

Positions are the pad cell origins in the block's own frame. The finished die adds the seal ring margin around it.

| Pad instance | Cell | Side | x um | y um | Signal |
|---|---|---|---|---|---|
| u_pvss0 | sg13g2_IOPadVss | bottom | 233.0 | 0.0 | VSS |
| u_pvdd0 | sg13g2_IOPadVdd | bottom | 366.0 | 0.0 | VDD 1.2 V |
| u_prst | sg13g2_IOPadIn | bottom | 499.0 | 0.0 | rst_n |
| u_piovss0 | sg13g2_IOPadIOVss | bottom | 632.0 | 0.0 | IOVSS |
| u_pload | sg13g2_IOPadIn | bottom | 765.0 | 0.0 | load_en |
| u_piovdd0 | sg13g2_IOPadIOVdd | bottom | 898.0 | 0.0 | IOVDD 3.3 V |
| u_pclk | sg13g2_IOPadIn | bottom | 1031.0 | 0.0 | clk |
| u_pgpio4 | sg13g2_IOPadOut16mA | left | 0.0 | 258.0 | gpio_o[4] |
| u_pgpio5 | sg13g2_IOPadOut16mA | left | 0.0 | 417.0 | gpio_o[5] |
| u_pgpio6 | sg13g2_IOPadOut16mA | left | 0.0 | 575.0 | gpio_o[6] |
| u_pgpio7 | sg13g2_IOPadOut16mA | left | 0.0 | 734.0 | gpio_o[7] |
| u_pscout | sg13g2_IOPadOut16mA | left | 0.0 | 892.0 | scan_out |
| u_piovdd1 | sg13g2_IOPadIOVdd | left | 0.0 | 1051.0 | IOVDD 3.3 V |
| u_pvss1 | sg13g2_IOPadVss | right | 1164.0 | 258.0 | VSS |
| u_ptest | sg13g2_IOPadIn | right | 1164.0 | 417.0 | test_mode |
| u_psdi | sg13g2_IOPadIn | right | 1164.0 | 575.0 | sdi |
| u_psclk | sg13g2_IOPadIn | right | 1164.0 | 734.0 | sclk |
| u_pscin | sg13g2_IOPadIn | right | 1164.0 | 892.0 | scan_in |
| u_pscen | sg13g2_IOPadIn | right | 1164.0 | 1051.0 | scan_en |
| u_pgpio0 | sg13g2_IOPadOut16mA | top | 252.0 | 1209.0 | gpio_o[0] |
| u_pgpio1 | sg13g2_IOPadOut16mA | top | 404.0 | 1209.0 | gpio_o[1] |
| u_piovss1 | sg13g2_IOPadIOVss | top | 556.0 | 1209.0 | IOVSS |
| u_pgpio2 | sg13g2_IOPadOut16mA | top | 708.0 | 1209.0 | gpio_o[2] |
| u_pgpio3 | sg13g2_IOPadOut16mA | top | 860.0 | 1209.0 | gpio_o[3] |
| u_pvdd1 | sg13g2_IOPadVdd | top | 1012.0 | 1209.0 | VDD 1.2 V |

## Bring-up

1. Tie `test_mode`, `scan_en` and `scan_in` low. The input pads have no pull resistors.
2. Apply VDD 1.2 V and IOVDD 3.3 V. Start a 50 MHz clock on `clk`.
3. Hold `rst_n` low for at least 5 clock cycles, then raise `rst_n` and `load_en` together.
4. Send each program word as a 42-bit frame on `sdi`, most significant bit first: the 10-bit word address, then
   the 32-bit data. The chip samples `sdi` on the rising edge of `sclk`. `sclk` and `sdi` each pass through their
   own synchronizer into the `clk` domain, so change `sdi` only while `sclk` is low and at least 4 `clk` cycles
   away from either `sclk` edge, and keep each `sclk` half period at least 4 `clk` cycles, as the testbench does.
5. Lower `load_en`. The core starts at address 0.
6. The test programs report on the GPIO pins: `gpio_o` reads 0x80 for pass. Bit 7 high with other bits set means
   fail, and the other bits say which test failed.

## Test programs

All in `RVSoC8787-main/testbenches`. Each one checks its own results and reports on the GPIO pins.

| Program | What it checks |
|---|---|
| main | The original self-check program |
| t_isa | Every RV32I instruction type against known answers |
| t_muldiv | Every RV32M multiply and divide, including divide by zero and overflow |
| t_mem | March C- test of data SRAM, address-in-address and checkerboard; constants read from instruction SRAM; GPIO readback |
| t_work | A prime sieve, a sort and a Fibonacci table folded into checksums |
| t_muldiv_plant | Control: built to fail. It must report fail, which shows that a failing program is caught |

## Signoff results of the reference build

From the reference build on 2026-10-03. A package built from another run carries that run's own checks in
`RVSoC8787-main/verification/sta/CHECK.txt`; read the results there. Fusion Compiler built it for an 18 ns clock; it is signed off at 20 ns. Timing uses worst and best wire models we derived from the
sheet and via resistance ranges in IHP's process spec, with thicknesses kept typical, since IHP publishes only a typical model, with a 5% cell and wire delay derate.

| Check | Result |
|---|---|
| Setup, slow / typ / fast | +1.012 / +7.66 / +11.55 ns |
| Hold, slow / typ / fast | +0.382 / +0.229 / +0.140 ns |
| Hold in scan shift, slow / typ / fast | +0.382 / +0.229 / +0.140 ns |
| Electrical limits, all corners and modes | 0 violations |
| Formality, RTL against the final netlist | Succeeded, 2188 points, none unmatched |
| DRC on the filled chip, with antenna | 0 |
| IHP tapeout precheck | 0 |
| LVS of the block, and of the filled chip | Match |
| Gate-level simulation with SDF delays at slow, typ and fast | Every program passes; the control fails |
| Scan test | 645 stuck-at patterns, 96.61% test coverage, 0 mismatches in parallel and fully serial replay |
| Static voltage drop, RedHawk-SC | 13 mV, 1.1% of 1.2 V, with the switching activity of the t_work program and current entering only next to the 4 core supply pads; 27 mV, 2.3%, with a flat 10% toggle rate |
| Clock domain crossings, SpyGlass CDC | sclk, sdi and load_en each enter through a multi-flop synchronizer; rst_n is synchronized with asynchronous assert and synchronous release; no unsynchronized crossing |
| Supply grid electromigration | Worst wire 62% and worst via 36% of IHP's published DC limits, 11 years at 105 C |
| Power, PrimePower | 3.79 mW |

## Known limits

- Chip LVS treats the SRAM and IHP's IO pad cells as sealed boxes and checks every connection to them. These
  vendor cells fail IHP's own LVS deck even when checked alone.
- At the fast corner the SRAM's Verilog model flags address changes 0.87 ns after the clock against a fixed 1 ns
  hold. IHP's characterized library hold there is 0.32 to 0.34 ns, which timing meets.
- The scan test does not reach inside the SRAMs. Their BIST port is tied off.
- The voltage-drop analysis does not model the pad ring rail or the package. The two bounds are 9.5 mV, with
  every strap fed, and 27 mV, with only the straps next to the supply pads fed.
