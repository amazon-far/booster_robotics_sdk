#!/bin/bash
set -e

# NOTE: This builds local wheels tagged `linux_*` (not PyPI-publishable). For
# PyPI, use the cibuildwheel GitHub Actions workflow instead — see PUBLISHING.md.

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    LIB_ARCH="x86_64"
    PLATFORM_TAG="linux_x86_64"
elif [ "$ARCH" = "aarch64" ]; then
    LIB_ARCH="aarch64"
    PLATFORM_TAG="linux_aarch64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

echo "Building for $ARCH"

# Clean and build SDK
mkdir -p build

# Install dependencies first
chmod +x install.sh
sed -i 's/apt install/apt install -y/g' install.sh
sed -i 's/sudo //g' install.sh
./install.sh

# Build Booster SDK
echo "Building Booster SDK..."
mkdir -p build && cd build
PYBIND11_INCLUDE=$(python3 -c "import pybind11; print(pybind11.get_include())")
PYTHON_EXEC=$(which python3)
cmake .. \
    -DBUILD_PYTHON_BINDING=on \
    -DCMAKE_BUILD_TYPE=Release \
    -DPython3_EXECUTABLE="${PYTHON_EXEC}" \
    -DPYTHON_EXECUTABLE="${PYTHON_EXEC}" \
    -DCMAKE_CXX_FLAGS="-I${PYBIND11_INCLUDE}" \
    -DPYBIND11_INCLUDE_DIR="${PYBIND11_INCLUDE}" \
    -DCMAKE_BUILD_RPATH_USE_ORIGIN=ON \
    -DCMAKE_INSTALL_RPATH='$ORIGIN'
make -j$(nproc)
cd ..

# Create package directory
mkdir -p booster_robotics_sdk

# Copy Booster libraries to package directory
find build -name "*.cpython-*.so" -exec cp {} booster_robotics_sdk/ \;
cp lib/$LIB_ARCH/*.so* booster_robotics_sdk/ 2>/dev/null || true
cp third_party/lib/$LIB_ARCH/*.so* booster_robotics_sdk/ 2>/dev/null || true

# Booster's libfastrtps was built against libtinyxml2.so.9 so we need to pull this for
# compatibility with Ubuntu24
if [ "$LIB_ARCH" = "x86_64" ]; then
    DEB_ARCH="amd64"
    REPO_URL="http://archive.ubuntu.com/ubuntu"
else
    DEB_ARCH="arm64"
    REPO_URL="http://ports.ubuntu.com/ubuntu-ports"
fi
wget -q ${REPO_URL}/pool/universe/t/tinyxml2/libtinyxml2-9_9.0.0+dfsg-3_${DEB_ARCH}.deb
dpkg-deb -x libtinyxml2-9_9.0.0+dfsg-3_${DEB_ARCH}.deb temp_extract/
cp temp_extract/usr/lib/${LIB_ARCH}-linux-gnu/libtinyxml2.so.9 booster_robotics_sdk/
rm -rf temp_extract libtinyxml2-9_9.0.0+dfsg-3_${DEB_ARCH}.deb

# Remove any .so files from the root directory to avoid duplicates
rm -f *.so

# If no .so files were copied, the build failed
if ! ls booster_robotics_sdk/*.cpython-*.so 1> /dev/null 2>&1; then
    echo "Error: No booster_robotics_sdk .so files found in build directory"
    echo "Build directory contents:"
    find build -name "*.so" 2>/dev/null || echo "No .so files found"
    exit 1
fi

# Create versioned symlinks for FastRTPS libraries
cd booster_robotics_sdk
if [ -f libfastrtps.so ]; then
    ln -sf libfastrtps.so libfastrtps.so.2.13
fi
if [ -f libfastcdr.so ]; then
    ln -sf libfastcdr.so libfastcdr.so.2
fi
cd ..

# Fix RPATH
for so in booster_robotics_sdk/*.so*; do
    patchelf --set-rpath '$ORIGIN' "$so" 2>/dev/null || true
done

# Build wheel
python3 -m build --wheel

# Get Python version for wheel naming
PYTHON_VERSION=$(python3 -c "import sys; print(f'cp{sys.version_info.major}{sys.version_info.minor}')")
echo "Using Python tag: $PYTHON_VERSION"

# Rename wheel to use correct Python/ABI tags
cd dist
for wheel in *.whl; do
    if [[ "$wheel" == *"-py3-none-any.whl" ]]; then
        new_name="${wheel/-py3-none-any.whl/-$PYTHON_VERSION-$PYTHON_VERSION-$PLATFORM_TAG.whl}"
        mv "$wheel" "$new_name"
        echo "Renamed wheel to: $new_name"
    fi
done
