#!/bin/bash
# Windows MSYS2 CI simulation script
# This exactly mimics the Windows CI workflow with MSYS2 Python and externally managed environment

set -e

echo "=== Windows MSYS2 CI Simulation ==="
echo "This simulates the Windows MSYS2 workflow with externally managed Python environment"

# Check if we're in the right directory
if [[ ! -f "setup.py" ]]; then
    echo "Error: Must run from RMNpy root directory"
    exit 1
fi

echo "Step 1: Download dependencies (simulated)"
mkdir -p lib
if [[ ! -f "lib/libOCTypes.a" ]]; then
    echo "Downloading OCTypes library..."
    touch lib/libOCTypes.a
fi

if [[ ! -f "lib/libSITypes.a" ]]; then
    echo "Downloading SITypes library..."
    touch lib/libSITypes.a
fi

echo "Step 2: Install Python build tools (Windows MSYS2 style)"
echo "=== MinGW Environment Verification ==="
echo "Python version:"
python --version
echo "Using --break-system-packages for MSYS2 externally managed environment"

# Simulate the MSYS2 package installation (would fail on macOS)
echo "Would run: pacman --noconfirm -S --needed mingw-w64-x86_64-python-numpy"
echo "(Skipping pacman on macOS, using pip instead)"

# Install build tools with system override flag
python -m pip install --break-system-packages --upgrade pip setuptools wheel Cython 2>/dev/null || \
    python -m pip install --upgrade pip setuptools wheel Cython

echo "Step 3: Install Python dependencies (Windows MSYS2 style)"
echo "Installing test dependencies via pacman where possible..."
echo "Would run: pacman --noconfirm -S --needed mingw-w64-x86_64-python-pytest"
echo "(Skipping pacman on macOS, using pip instead)"

echo "Installing remaining dependencies via pip with --break-system-packages..."
python -m pip install --break-system-packages pytest pytest-cov pytest-xdist pytest-benchmark 2>/dev/null || \
    python -m pip install pytest pytest-cov pytest-xdist pytest-benchmark

echo "Installing project without test dependencies..."
python -m pip install --break-system-packages -e . --no-deps 2>/dev/null || \
    python -m pip install -e . --no-deps

echo "Step 4: Generate constants"
if command -v make >/dev/null 2>&1; then
    make generate-constants || python scripts/extract_si_constants.py
else
    python scripts/extract_si_constants.py
fi

echo "Step 5: Build Cython extension"
python setup.py build_ext --inplace

echo "Step 6: Test basic imports"
echo "Testing numpy import..."
python -c "import numpy; print('Numpy version: ' + numpy.__version__)"
echo "✓ Numpy import successful"

echo "Testing RMNpy import..."
python -c "import rmnpy; print('RMNpy imported successfully')"
echo "✓ RMNpy import successful"

echo "Step 7: Run tests"
python -m pytest --maxfail=1 --disable-warnings -q

echo "✓ Windows MSYS2 CI simulation completed successfully"
