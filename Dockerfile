FROM ubuntu:22.04 AS builder

ARG PYTHON_VERSION=3.10

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    python3-pip \
    python3-pybind11 \
    pybind11-dev \
    patchelf \
    lsb-release \
    wget \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Add deadsnakes PPA for Python 3.8 if needed
RUN if [ "$PYTHON_VERSION" = "3.8" ]; then \
        add-apt-repository ppa:deadsnakes/ppa -y && \
        apt-get update; \
    fi

RUN apt-get update && apt-get install -y \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-dev \
    python${PYTHON_VERSION}-venv \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/python${PYTHON_VERSION} /usr/bin/python \
    && ln -sf /usr/bin/python${PYTHON_VERSION} /usr/bin/python3

# Set environment variables for CMake to find the correct Python
ENV Python3_EXECUTABLE=/usr/bin/python${PYTHON_VERSION}
ENV PYTHON_EXECUTABLE=/usr/bin/python${PYTHON_VERSION}

RUN python -m pip install build pybind11 pybind11-stubgen

WORKDIR /work
COPY . .

ARG CONFIG_FILE=pyproject.toml
ARG BOOSTER_TAG
RUN if [ "$CONFIG_FILE" != "pyproject.toml" ]; then cp $CONFIG_FILE pyproject.toml; fi

RUN ./build.sh

FROM scratch AS output
COPY --from=builder /work/dist/*.whl /
