#!/bin/bash
# Build script for RMNpy

set -e  # Exit on any error

echo "RMNpy Build Script"
echo "=================="
echo

# Check if we're in the right directory
if [[ ! -f "setup.py" ]]; then
    echo "ERROR: setup.py not found. Please run this script from the RMNpy root directory."
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check dependencies
echo "Checking dependencies..."
if ! command_exists python3; then
    echo "ERROR: python3 not found. Please install Python 3."
    exit 1
fi

if ! command_exists pip; then
    echo "ERROR: pip not found. Please install pip."
    exit 1
fi

echo "✓ Python and pip found"

# Setup dependencies if needed
if [[ "$1" == "--setup-deps" ]]; then
    echo
    echo "Setting up dependencies..."
    python3 build_deps.py --verbose
    echo
fi

# Install Python dependencies
echo "Installing Python dependencies..."
pip install -r requirements.txt

# Clean previous builds
echo
echo "Cleaning previous builds..."
rm -rf build/
rm -rf src/rmnpy/*.c
rm -rf src/rmnpy/*.so
rm -rf *.egg-info

# Build the extension
echo
echo "Building Cython extension..."
python3 setup.py build_ext --inplace

# Install in development mode
echo
echo "Installing in development mode..."
pip install -e .

echo
echo "✓ Build completed successfully!"
echo
echo "You can now test the installation with:"
echo "  python3 -c \"import rmnpy; print('RMNpy imported successfully!')\""
