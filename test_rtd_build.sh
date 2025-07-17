#!/bin/bash
# Test script for Read the Docs documentation build
# This mimics the RTD build environment locally

set -e  # Exit on any error

echo "=== Testing Read the Docs documentation build ==="

# Clean previous builds
echo "Cleaning previous build artifacts..."
cd docs
make clean

# Set RTD environment variable
export READTHEDOCS=True

# Install documentation dependencies
echo "Installing documentation dependencies..."
cd ..
pip install -e .[docs]

# Build documentation
echo "Building documentation..."
cd docs
make html

echo "=== Documentation build completed successfully! ==="
echo "Open docs/_build/html/index.html in your browser to view the result."
