# Ibex on IHP SG13G2

Scripts that take a small RISC-V system on chip from RTL to a signed-off, tapeout-ready layout in IHP's open
130 nm process, SG13G2, with Synopsys tools. The chip is the lowRISC Ibex core with 4 KiB of instruction SRAM,
4 KiB of data SRAM, a serial program loader, eight GPIO outputs, a scan chain and 25 pads.

The result of one build is IHP's release package for the Open-Silicon program: the GDS, the netlists, timing,
parasitics, the RTL, the test programs and the signoff report.

## What you need

- A Linux server with RHEL 8 or a compatible system, where the Synopsys and Ansys tools are installed under
  `/apps` and `/apps/settings` sets up their licenses.
- Licenses for Fusion Compiler, Library Compiler, Library Manager, StarRC, PrimeTime SI, Formality, PrimePower,
  TestMAX, VCS and SpyGlass. Ansys RedHawk-SC is needed only for the voltage drop check.
- `git`, `curl`, `unzip`, `rpm2cpio`, `cpio`, `make`, `g++` and `/usr/bin/python3.11`.
- glibc 2.34 in `/apps/glibc234` for sv2v, and a RISC-V GCC in `/apps/riscv-toolchain` only to rebuild the test
  programs, which are already built in the repository.
- About 5 GB of disk in your home folder: 3 GB for setup and about 2 GB per chip build.

The scripts were written for the tool releases and paths of one such server. Tool paths are in `flow/tools.sh`,
`flow/run_fc.sh`, `chip/atpg.sh`, `chip/ir/ir.sh`, `chip/ir/run.py`, `tools/bin/sv2v` and
`designs/flash_soc/sw_suite/build_all.sh`.

## Set up, once

The repository must be cloned to `~/flash`. Every script finds its files there.

```
git clone <this repository> ~/flash
bash ~/flash/setup/setup.sh
```

`setup.sh` takes about two hours. It downloads IHP's kit at the commit this chip was signed off with, builds
KLayout and installs sv2v and a Python environment in `~/flash/tools`, and builds the Synopsys-format libraries
and wire models from IHP's kit with your licenses. Its log is `~/flash/setup/setup.log`. Run it again to finish
an interrupted setup; each step skips itself once done.

## Build the chip

```
nohup bash ~/flash/chip/make_chip.sh my_chip > /dev/null 2>&1 &
```

This makes the run folder `~/flash/runs/my_chip` and runs every step up to the review: synthesis and scan
insertion, place and route, bond pads, seal ring and metal fill, signoff, margin rounds, the test programs on the
gates, the scan test, the clock crossing check, and the voltage drop and electromigration check. Each step must
pass before the next starts, except the clock crossing and voltage drop checks, which only report; read
`cdc.log` and `ir.log` in the run folder. Follow `~/flash/runs/my_chip/make_chip.log`; it names the step that
stopped it.

To learn the flow, run it one stage at a time: put `STOP_AT=synth`, then `route`, `finish`, `signoff` and
`proofs`, in front of the same command. Between stages, `chip/open_fc.sh <run> <step>` opens a saved step in Fusion Compiler and
`chip/open_klayout.sh <run>` opens the finished chip in KLayout. To fix the timing margin by hand instead of with
the automatic rounds, put `MARGIN=hand` in front; Stage 7.2 of `docs/ibex-flow.pdf` walks it, and its last section
has labs that change one setting at a time.

For the voltage drop check, set the Ansys license first. On the ECE servers it is port 1055 on the Synopsys
license server: `source /apps/settings; export ANSYSLMD_LICENSE_FILE=1055@${SNPSLMD_LICENSE_FILE#*@}`.

When the log ends with `READY_FOR_REVIEW`, a person reviews four records that a tool cannot judge:

```
R=~/flash/runs/my_chip
cat $R/review/SUMMARY.txt $R/review/EVIDENCE.txt
python3 ~/flash/chip/review/sign.py $R "Your Name"
bash ~/flash/chip/final_signoff.sh $R
bash ~/flash/chip/package/package.sh $R
```

`sign.py` lists the basis for each record. Sign only if the evidence agrees with it. The final signoff must end
with `SIGNOFF CLEAN`, and `package.sh` with `PACKAGE_OK`. The package is in `$R/package/IHP__RVSoC8787`.

## Documents

`docs/ibex-flow.pdf` walks every step above with the command, the check that must pass and a screenshot
from a fresh build of this repository.

## What is where

| Folder | Contents |
|---|---|
| `setup/` | One-time setup: the kit, the tools and the libraries |
| `flow/` | Fusion Compiler flow, signoff, the result checker, chip finishing and the fix loop |
| `pdk_cfg/ihp_sg13g2/` | IHP settings for the flow: layers, power grid, corners, bond pads and fill |
| `ihp/` | Scripts that build the Synopsys libraries, and the wire models |
| `designs/flash_soc/` | RTL, testbench, simulation scripts and test programs |
| `chip/` | The chip build, margin rounds, proofs, review records and the release package |
| `tools/` | Wrappers for KLayout and sv2v |

## Licenses

Apache-2.0. Ibex and IHP's kit are also Apache-2.0; see NOTICE for what comes from each. No Synopsys or Ansys
files are in this repository. The libraries those tools read are built on your server from IHP's kit.
