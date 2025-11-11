#!/bin/bash
set -e

# Extract version from pyproject.toml
BOOSTER_TAG=$(grep '^version = ' pyproject.toml | cut -d'"' -f2)

echo "Building booster-robotics-sdk wheels (version $BOOSTER_TAG)..."

# Build for both architectures and Python versions
for ARCH in x86_64 aarch64; do
    for PYTHON_VERSION in 3.8 3.10; do
        echo "Building for $ARCH with Python $PYTHON_VERSION..."
        docker buildx build --platform linux/$ARCH \
            --build-arg BOOSTER_TAG=$BOOSTER_TAG \
            --build-arg PYTHON_VERSION=$PYTHON_VERSION \
            -f ./Dockerfile \
            --output type=local,dest=./dist \
            .
    done
done

echo "Booster robotics wheels built successfully in dist/"
