#!/bin/bash
# The tools the flow needs besides the Synopsys and Ansys ones in /apps:
#   sv2v 0.0.13, which turns SystemVerilog into Verilog for Formality
#   a Python 3.11 environment with the packages in requirements.txt
#   KLayout 0.30.5 with Python 3.11 and Ruby 3.1, for IHP's DRC, LVS and fill scripts. The system's own Ruby and
#   Qt headers are too old or missing, so the build uses Rocky Linux 8 packages unpacked into tools/sysroot,
#   without root access.
set -e
T=$HOME/flash/tools
mkdir -p "$T/bin"

if [ ! -x "$T/sv2v_dist/sv2v-Linux/sv2v" ]; then
  curl -fsSL -o "$T/sv2v.zip" https://github.com/zachjs/sv2v/releases/download/v0.0.13/sv2v-Linux.zip
  rm -rf "$T/sv2v_dist" && mkdir -p "$T/sv2v_dist" && (cd "$T/sv2v_dist" && unzip -q "$T/sv2v.zip")
fi
echo "SV2V_OK $("$T/bin/sv2v" --version 2>&1)"

if [ ! -x "$T/pyenv/bin/python" ]; then
  /usr/bin/python3.11 -m venv "$T/pyenv"
fi
"$T/pyenv/bin/pip" install --quiet -r "$HOME/flash/setup/requirements.txt"
echo "PYENV_OK $("$T/pyenv/bin/python" -c 'import klayout.db, docopt, yaml; print("klayout", klayout.db.__version__)')"

if [ ! -x "$T/klayout-0.30.5-rb31/klayout" ]; then
  mkdir -p "$T/rpms" "$T/sysroot"
  # Rocky Linux 8 builds of RHEL 8 packages, pinned to the exact builds used, from Rocky's mirror. The vault keeps
  # them once a newer build replaces them.
  for n in $(cat "$HOME/flash/setup/rpms.txt"); do
    f=$n.rpm; l=$(echo "$n" | cut -c1)
    [ -s "$T/rpms/$f" ] && continue
    curl -fsSL -o "$T/rpms/$f" "https://dl.rockylinux.org/pub/rocky/8/AppStream/x86_64/os/Packages/$l/$f" \
      || curl -fsSL -o "$T/rpms/$f" "https://dl.rockylinux.org/vault/rocky/8.10/AppStream/x86_64/os/Packages/$l/$f" \
      || { echo "RPM_FAIL $f"; exit 1; }
  done
  for r in "$T"/rpms/*.rpm; do (cd "$T/sysroot" && rpm2cpio "$r" | cpio -idm --quiet); done
  S=$T/sysroot/usr
  # qmake must take headers and libraries from the sysroot, not from /usr.
  printf '[Paths]\nPrefix=%s\nHeaders=include/qt5\nLibraries=lib64\nBinaries=lib64/qt5/bin\nArchData=lib64/qt5\nData=share/qt5\nHostPrefix=%s\nHostBinaries=lib64/qt5/bin\nHostLibraries=lib64\nHostData=lib64/qt5\n' \
    "$S" "$S" > "$S/lib64/qt5/bin/qt.conf"
  # The devel packages' link names point at Qt libraries that only the system has, the same 5.15.3 build.
  for l in "$S"/lib64/libQt5*.so; do
    t=$(readlink "$l")
    [ -e "$S/lib64/$t" ] || { [ -e "/usr/lib64/$t" ] && ln -sfn "/usr/lib64/$t" "$l"; } || { echo "QT_LIB_FAIL /usr/lib64/$t"; exit 1; }
  done
  # python3.11-devel's pyconfig.h includes pyconfig-64.h, which comes with the installed python3.11-libs.
  cp /usr/include/python3.11/pyconfig-64.h "$S/include/python3.11/"
  mkdir -p "$T/src"
  [ -f "$T/src/klayout-0.30.5.tar.gz" ] || curl -fsSL -o "$T/src/klayout-0.30.5.tar.gz" https://www.klayout.org/downloads/source/klayout-0.30.5.tar.gz
  [ -d "$T/src/klayout-0.30.5" ] || tar -xzf "$T/src/klayout-0.30.5.tar.gz" -C "$T/src"
  bash "$HOME/flash/setup/build_klayout.sh" > "$T/src/build.log" 2>&1
  grep -q BUILD_EXIT=0 "$T/src/build.log" || { echo "KLAYOUT_BUILD_FAIL see $T/src/build.log"; exit 1; }
fi
ln -sf "$T/klayout.sh" "$T/bin/klayout"
echo "KLAYOUT_OK $("$T/bin/klayout" -b -v 2>&1)"
