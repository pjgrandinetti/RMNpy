# Windows development environment simulation
# This mimics the MSYS2/MinGW-w64 setup used in GitHub Actions

FROM ubuntu:22.04

# Install dependencies that mirror MSYS2 environment
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    wget \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set up Python environment similar to MSYS2
RUN ln -s /usr/bin/python3 /usr/bin/python

# Create workspace
WORKDIR /workspace

# Copy project files
COPY . .

# Install Python dependencies
RUN python -m pip install --upgrade pip
RUN python -m pip install -e .[test]

# Default command to run tests
CMD ["python", "-m", "pytest", "--maxfail=1", "--disable-warnings", "-q"]
