#!/bin/bash
# Local Windows CI simulation script
# This mimics the key steps from the Windows workflow

set -e

echo "=== Local Windows CI Simulation ==="
echo "This simulates the Windows MSYS2 workflow locally on macOS"

# Check if we're in the right directory
if [[ ! -f "setup.py" ]]; then
    echo "Error: Must run from RMNpy root directory"
    exit 1
fi

echo "Step 1: Download dependencies (simulated)"
mkdir -p lib
if [[ ! -f "lib/libOCTypes.a" ]]; then
    echo "Downloading OCTypes library..."
    # Simulate library download
    curl -L -o lib/libOCTypes.zip https://github.com/pjgrandinetti/OCTypes/releases/latest/download/OCTypes-macos-x86_64.zip || echo "Using mock library"
    # For testing, create a mock library
    touch lib/libOCTypes.a
fi

if [[ ! -f "lib/libSITypes.a" ]]; then
    echo "Downloading SITypes library..."
    # Simulate library download
    curl -L -o lib/libSITypes.zip https://github.com/pjgrandinetti/SITypes/releases/latest/download/SITypes-macos-x86_64.zip || echo "Using mock library"
    # For testing, create a mock library
    touch lib/libSITypes.a
fi

echo "Step 2: Install Python dependencies"
# On macOS, we can install normally. On Windows CI, we'd need --break-system-packages
python -m pip install -e .[test]

echo "Step 3: Generate constants"
# On macOS, try the Makefile first, fallback to direct script
if command -v make >/dev/null 2>&1; then
    make generate-constants || python scripts/extract_si_constants.py
else
    python scripts/extract_si_constants.py
fi

echo "Step 4: Build Cython extension"
python setup.py build_ext --inplace

echo "Step 5: Test basic imports"
echo "Testing numpy import..."
python -c "import numpy; print('Numpy version: ' + numpy.__version__)"
echo "✓ Numpy import successful"

echo "Testing RMNpy import..."
python -c "import rmnpy; print('RMNpy imported successfully')"
echo "✓ RMNpy import successful"

echo "Step 6: Run tests"
python -m pytest --maxfail=1 --disable-warnings -q

echo "✓ Local Windows CI simulation completed successfully"
