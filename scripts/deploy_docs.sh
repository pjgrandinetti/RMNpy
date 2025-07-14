#!/bin/bash
# Deploy documentation script for RMNpy

set -e  # Exit on any error

echo "=== RMNpy Documentation Deployment ==="

# Check if we're in the right directory
if [ ! -f "docs/conf.py" ]; then
    echo "Error: Please run this script from the RMNpy root directory"
    exit 1
fi

# Install documentation dependencies
echo "Installing documentation dependencies..."
pip install -r docs/requirements.txt

# Ensure RMNpy is installed in development mode
echo "Installing RMNpy in development mode..."
pip install -e .

# Test that RMNpy can be imported
echo "Testing RMNpy import..."
python -c "import rmnpy; print(f'RMNpy version: {rmnpy.__version__}')" || {
    echo "Error: RMNpy cannot be imported. Please check your installation."
    exit 1
}

# Build documentation
echo "Building documentation..."
cd docs

# Clean any previous builds
make clean

# Build with strict mode (warnings as errors) for quality check
echo "Building with strict mode (warnings as errors)..."
make strict || {
    echo "Warning: Strict build failed. Trying regular build..."
    make html
}

echo "Documentation built successfully!"

# Check if we should open the documentation
if command -v open >/dev/null 2>&1; then
    echo "Opening documentation in browser..."
    open _build/html/index.html
elif command -v xdg-open >/dev/null 2>&1; then
    echo "Opening documentation in browser..."
    xdg-open _build/html/index.html
else
    echo "Documentation is available at: docs/_build/html/index.html"
fi

echo "=== Deployment Complete ==="
echo ""
echo "Next steps:"
echo "1. Review the built documentation"
echo "2. Commit your changes to git"
echo "3. Push to GitHub to trigger automatic deployment"
echo ""
echo "Local documentation: file://$(pwd)/_build/html/index.html"
echo "Online documentation: https://pjgrandinetti.github.io/RMNpy/"
