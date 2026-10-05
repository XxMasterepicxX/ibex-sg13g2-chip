#!/bin/bash
# Tool versions for one run, sourced by run_fc.sh and signoff.sh. A run keeps the release it started with, recorded
# in <run>/.tools, because Fusion Compiler opens designs saved by older releases but not newer ones. New runs get
# the release in FLASH_TOOLS, 2026 by default: the Y-2026.03-SP2 tools IT installed on 9-24. A run that already has
# Fusion Compiler logs but no .tools started before the switch and stays on 2023.
# PrimeTime and IC Validator come from /apps/syn/*/current, Y-2026.03-SP2 since 9-24 15:38, for every run.
if [ ! -f "$RUN/.tools" ]; then
  if ls "$RUN"/fc_*.log > /dev/null 2>&1; then echo 2023 > "$RUN/.tools"; else echo "${FLASH_TOOLS:-2026}" > "$RUN/.tools"; fi
fi
case $(cat "$RUN/.tools") in
  2023)
    FC_BIN=/apps/syn/fusioncompiler/V-2023.12/bin/fc_shell
    FC_PRELOAD="/lib64/libk5crypto.so.3 /lib64/libcrypto.so.1.1"
    STARRC_BIN=/apps/syn/starrc/V-2023.12-SP5-1/bin
    FM_SHELL=/apps/syn/formality/bin/fm_shell ;;
  *)
    # Y-2026.03 needs no preload; V-2023.12 needed it for a krb5 symbol mismatch.
    FC_BIN=/apps/syn/fusioncompiler/Y-2026.03-SP2/bin/fc_shell
    FC_PRELOAD=""
    STARRC_BIN=/apps/syn/starrc/Y-2026.03-SP2/bin
    FM_SHELL=/apps/syn/fm/Y-2026.03-SP2/bin/fm_shell ;;
esac
