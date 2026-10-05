#!/bin/bash
# One-time setup on a Linux server with the Synopsys and Ansys tools in /apps and their licenses set by /apps/settings.
# The repository must live in ~/flash: every script finds its files there. Each step skips itself once done.
#   1. IHP's open kit, pinned to the commit this flow was signed off with
#   2. sv2v, a Python environment and KLayout, built from source
#   3. the Synopsys-format libraries and wire models, built from IHP's kit with your own tool licenses
# Expect about two hours, most of it the KLayout build and the wire models. Log: ~/flash/setup/setup.log
set -o pipefail
R=$HOME/flash
if [ "$(readlink -f "$(dirname "$(readlink -f "$0")")/..")" != "$(readlink -f "$R")" ]; then
  echo "Clone this repository to ~/flash first: git clone <url> ~/flash"; exit 1
fi
{
  date +"SETUP_START %F %T"
  bash "$R/setup/get_pdk.sh" || { echo SETUP_FAIL get_pdk; exit 1; }
  bash "$R/setup/install_tools.sh" || { echo SETUP_FAIL install_tools; exit 1; }
  bash "$R/setup/build_libs.sh" || { echo SETUP_FAIL build_libs; exit 1; }
  # KLayout with IHP's technology loaded, as the chip finishing and DRC run it.
  echo 'print("KIT_LOADS")' > /tmp/kit_check_$$.py
  K=$(PDK_ROOT=$R/pdk/IHP-Open-PDK PDK=ihp-sg13g2 KLAYOUT_PATH=$R/pdk/IHP-Open-PDK/ihp-sg13g2/libs.tech/klayout \
      "$R/tools/bin/klayout" -n sg13g2 -zz -r /tmp/kit_check_$$.py 2>&1); rm -f /tmp/kit_check_$$.py
  echo "$K" | grep -q "^KIT_LOADS" && ! echo "$K" | grep -q "ERROR" || { echo "$K"; echo SETUP_FAIL kit_check; exit 1; }
  echo KIT_OK
  date +"SETUP_DONE %F %T"
} 2>&1 | tee -a "$R/setup/setup.log"
