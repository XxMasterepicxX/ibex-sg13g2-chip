#!/bin/bash
# Builds KLayout 0.30.5 against Ruby 3.1 and Python 3.11 from tools/sysroot. Called by install_tools.sh.
T=$HOME/flash/tools
S=$T/sysroot
export LD_LIBRARY_PATH=$S/usr/lib64
export PATH=$S/usr/lib64/qt5/bin:$PATH
cd "$T/src/klayout-0.30.5" || exit 1
rm -rf "$T/src/kl-build"
./build.sh -release -qmake "$S/usr/lib64/qt5/bin/qmake" \
  -rbinc "$S/usr/include" -rbinc2 "$S/usr/include" -rblib "$S/usr/lib64/libruby.so.3.1" -rbvers 30107 \
  -pyinc "$S/usr/include/python3.11" -pylib /usr/lib64/libpython3.11.so.1.0 -python /usr/bin/python3.11 \
  -without-qtbinding -nolibgit2 -build "$T/src/kl-build" -bin "$T/klayout-0.30.5-rb31" -option -j"$(nproc)"
echo BUILD_EXIT=$?
