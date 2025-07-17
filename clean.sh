#!/bin/bash
# Complete cleanup script for RMNpy generated files

echo "🧹 Cleaning RMNpy generated files..."

# Clean build artifacts
echo "Cleaning build artifacts..."
python setup.py clean --all 2>/dev/null || true
rm -rf build/
rm -rf dist/
rm -rf *.egg-info/

# Clean Cython generated files
echo "Cleaning Cython generated files..."
rm -f src/rmnpy/*.c
find . -name "*.so" -delete

# Clean Python cache files
echo "Cleaning Python cache files..."
find . -name "*.pyc" -delete
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Clean test and coverage artifacts
echo "Cleaning test and coverage artifacts..."
rm -rf .pytest_cache/
rm -rf htmlcov/
rm -f .coverage
rm -f coverage.xml

# Clean temporary test files and working documents
echo "Cleaning temporary test files..."
rm -f ../test_*.py 2>/dev/null || true
rm -f ../*_improvement*.md 2>/dev/null || true

echo "✅ Cleanup complete!"
echo ""
echo "Remaining source files:"
ls -la src/rmnpy/
