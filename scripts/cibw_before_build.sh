#!/bin/bash
# cibuildwheel before-build hook for far-booster-sdk.
#
# Runs inside the manylinux_2_34 (AlmaLinux 9) container in the per-wheel Python
# environment. Compiles the pybind11 extension, then stages it together with the
# vendored FastDDS libraries (and libtinyxml2.so.9, which libfastrtps needs) into
# the booster_robotics_sdk/ package so setuptools packages them and auditwheel
# can bundle + repair the wheel.
set -euo pipefail

PROJECT="${1:?usage: cibw_before_build.sh <project_dir>}"
cd "$PROJECT"

ARCH="$(uname -m)"
echo "[before-build] arch=$ARCH python=$(python -c 'import sys; print(sys.version)')"

# tomli is the read backport of the stdlib `tomllib`, which only exists on
# Python 3.11+. cibuildwheel runs this hook inside every target interpreter
# (cp38–cp312), so on 3.8–3.10 `import tomllib` fails; install tomli as a
# fallback. (pip is happy to install it everywhere; it's tiny and pure-Python.)
pip install "pybind11>=2.10" pybind11-stubgen tomli

PYBIND11_DIR="$(python -c 'import pybind11; print(pybind11.get_cmake_dir())')"
PYBIND11_INCLUDE="$(python -c 'import pybind11; print(pybind11.get_include())')"
PY_EXE="$(command -v python)"

# Read distribution name/version from pyproject so we can satisfy the
# project(${SKBUILD_PROJECT_NAME} VERSION ${SKBUILD_PROJECT_VERSION}) call
# without depending on scikit-build-core being the active build frontend.
# Use stdlib tomllib (3.11+) when available, else the tomli backport installed
# above — this hook runs under every target interpreter, including 3.8–3.10.
read -r SK_NAME SK_VERSION <<EOF
$(python - <<'PY'
try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib
proj = tomllib.load(open("pyproject.toml", "rb"))["project"]
print(proj["name"], proj["version"])
PY
)
EOF

# The CMakeLists links the vendored static + DDS libs by bare name, so they must
# be on the linker search path. install.sh keys off lsb_release (Ubuntu only)
# and won't work in AlmaLinux, so copy the arch-specific libs to /usr/local/lib
# directly. Headers go to /usr/local/include for the compile.
cp -rv include/* /usr/local/include/ 2>/dev/null || true
cp -rv third_party/include/* /usr/local/include/ 2>/dev/null || true
cp -v "lib/$ARCH/"*.a /usr/local/lib/ 2>/dev/null || true
cp -v "third_party/lib/$ARCH/"*.so* /usr/local/lib/ 2>/dev/null || true
cp -v "third_party/lib/$ARCH/"*.a /usr/local/lib/ 2>/dev/null || true
ldconfig || true

# Clean any stale extension modules so we package exactly this build.
rm -f booster_robotics_sdk/*.so booster_robotics_sdk/*.so.*

BUILD_DIR="build_cibw"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cmake -S . -B "$BUILD_DIR" \
    -DBUILD_PYTHON_BINDING=on \
    -DSKBUILD_PROJECT_NAME="$SK_NAME" \
    -DSKBUILD_PROJECT_VERSION="$SK_VERSION" \
    -DCMAKE_BUILD_TYPE=Release \
    -DPython3_EXECUTABLE="$PY_EXE" \
    -DPYTHON_EXECUTABLE="$PY_EXE" \
    -Dpybind11_DIR="$PYBIND11_DIR" \
    -DPYBIND11_INCLUDE_DIR="$PYBIND11_INCLUDE" \
    -DCMAKE_CXX_FLAGS="-I${PYBIND11_INCLUDE}" \
    -DCMAKE_BUILD_RPATH_USE_ORIGIN=ON \
    -DCMAKE_INSTALL_RPATH='$ORIGIN'
# Only build the python binding target; the example executables are not needed
# for the wheel and pull in extra link requirements.
cmake --build "$BUILD_DIR" --target booster_robotics_sdk_python -j"$(nproc)"

# Stage the freshly compiled extension module.
find "$BUILD_DIR" -name "booster_robotics_sdk_python.cpython-*.so" -exec cp -v {} booster_robotics_sdk/ \;

# Stage vendored DDS runtime libraries for this architecture.
cp -v "third_party/lib/$ARCH/"*.so* booster_robotics_sdk/ 2>/dev/null || true

# libfastrtps was built against libtinyxml2.so.9. The AlmaLinux 9 manylinux
# image ships tinyxml2 v10, so fetch the v9 .so portably (no dpkg-deb) from
# Ubuntu's archive and stage it for auditwheel to bundle.
if [ "$ARCH" = "x86_64" ]; then
    DEB_ARCH="amd64"; REPO_URL="http://archive.ubuntu.com/ubuntu"
else
    DEB_ARCH="arm64"; REPO_URL="http://ports.ubuntu.com/ubuntu-ports"
fi
# Modern .deb archives compress data.tar with zstd, which the AlmaLinux 9
# manylinux image lacks. Ensure zstd is available before extracting.
if ! command -v zstd >/dev/null 2>&1; then
    (yum install -y zstd || dnf install -y zstd) >/dev/null 2>&1 || true
fi
TXML_DEB="libtinyxml2-9_9.0.0+dfsg-3_${DEB_ARCH}.deb"
TXML_OK=0
if curl -fsSL -o "/tmp/$TXML_DEB" "${REPO_URL}/pool/universe/t/tinyxml2/${TXML_DEB}"; then
    if ( cd /tmp && ar x "$TXML_DEB" && tar xf data.tar.* ); then
        find /tmp/usr -name "libtinyxml2.so.9*" -exec cp -v {} booster_robotics_sdk/ \; && TXML_OK=1
    fi
    rm -rf "/tmp/$TXML_DEB" /tmp/data.tar.* /tmp/control.tar.* /tmp/debian-binary /tmp/usr
fi
if [ "$TXML_OK" != "1" ]; then
    echo "[before-build] ERROR: failed to obtain libtinyxml2.so.9 (needed by libfastrtps)" >&2
    exit 1
fi

# Recreate the versioned FastRTPS/FastCDR symlinks matching the SONAMEs.
( cd booster_robotics_sdk
  [ -f libfastrtps.so ] && ln -sf libfastrtps.so libfastrtps.so.2.13 || true
  [ -f libfastcdr.so ]  && ln -sf libfastcdr.so  libfastcdr.so.2     || true
)

# Stage the type stub. The authoritative, hand-maintained stub lives at
# python/booster_robotics_sdk_python.pyi and is the source of truth for the public
# API — prefer it so the wheel is reproducible and does not depend on
# pybind11-stubgen succeeding inside the manylinux container (importing the freshly
# linked extension there is fragile: it needs the staged DDS deps + libtinyxml2.so.9
# on the loader path). pybind11-stubgen is only a fallback for a checkout that
# somehow lacks the committed stub, and it must actually produce the file — no
# silent skip.
if [ -f python/booster_robotics_sdk_python.pyi ]; then
    cp -v python/booster_robotics_sdk_python.pyi booster_robotics_sdk/booster_robotics_sdk_python.pyi
    echo "[before-build] staged committed stub python/booster_robotics_sdk_python.pyi"
elif PYTHONPATH="booster_robotics_sdk:${PYTHONPATH:-}" \
     LD_LIBRARY_PATH="$PWD/booster_robotics_sdk:${LD_LIBRARY_PATH:-}" \
     pybind11-stubgen -o "$BUILD_DIR/stubs" booster_robotics_sdk_python \
     && [ -f "$BUILD_DIR/stubs/booster_robotics_sdk_python.pyi" ]; then
    cp -v "$BUILD_DIR/stubs/booster_robotics_sdk_python.pyi" booster_robotics_sdk/booster_robotics_sdk_python.pyi
    echo "[before-build] staged stubgen-generated stub"
else
    echo "[before-build] ERROR: no booster_robotics_sdk_python.pyi available (committed stub missing and stubgen failed)" >&2
    exit 1
fi

# Ship py.typed ONLY alongside a real .pyi. A py.typed marker without a stub makes
# mypy treat the compiled extension as a typed-but-empty module and report
# `attr-defined` on every symbol downstream (exactly the holosoma CI break this
# fixes) — worse than shipping no type info at all. Fail loudly rather than
# regress that.
if [ ! -f booster_robotics_sdk/booster_robotics_sdk_python.pyi ]; then
    echo "[before-build] ERROR: refusing to write py.typed without a .pyi stub" >&2
    exit 1
fi
touch booster_robotics_sdk/py.typed
echo "[before-build] staged files:"
ls -la booster_robotics_sdk/
