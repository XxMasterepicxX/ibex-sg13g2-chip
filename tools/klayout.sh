#!/bin/bash
# KLayout 0.30.5 built from source against Ruby 3.1 and Python 3.11 (RHEL 8 Rocky packages in sysroot).
K=$HOME/flash/tools/klayout-0.30.5-rb31
SR=$HOME/flash/tools/sysroot
# Only our own libraries: /apps/settings puts RedHawk's older Qt5 first on LD_LIBRARY_PATH, and KLayout then fails to load.
export LD_LIBRARY_PATH=$K:$SR/usr/lib64
export RUBYLIB=$SR/usr/share/ruby:$SR/usr/lib64/ruby:$SR/usr/share/gems/gems/json-2.6.1/lib:$SR/usr/lib64/gems/ruby/json-2.6.1
export RUBYOPT=--disable-gems
export QT_QPA_PLATFORM=offscreen
# tkinter (used by IHP PyCell API for a Tcl interpreter) and psutil come from the sysroot and the venv.
export KLAYOUT_PYTHONPATH=${KLAYOUT_PYTHONPATH:+$KLAYOUT_PYTHONPATH:}$HOME/flash/tools/pyenv/lib/python3.11/site-packages:$SR/usr/lib64/python3.11:$SR/usr/lib64/python3.11/lib-dynload
exec $K/klayout "$@"
