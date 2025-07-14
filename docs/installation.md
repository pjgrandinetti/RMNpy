# Installation

This guide covers different ways to install RMNpy on your system.

## Prerequisites

Before installing RMNpy, ensure you have:

* **Python 3.8 or later**
* **NumPy** (required for building and runtime)
* **C compiler** (gcc, clang, or MSVC on Windows)
* **Cython** (required for building from source)

You can install the Python prerequisites with:

```bash
pip install numpy cython
```

## Development Installation (Recommended)

Since RMNpy is currently under active development, we recommend installing from source:

### 1. Clone the Repository

```bash
git clone https://github.com/pjgrandinetti/RMNpy.git
cd RMNpy
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Build and Install in Development Mode

```bash
pip install -e .
```

This installs RMNpy in "editable" mode, so changes to the source code will be reflected immediately.

### 4. Verify Installation

```bash
python -c "import rmnpy; print(f'RMNpy version: {rmnpy.__version__}')"
```

## Building from Source

If you need to build from source manually:

### 1. Setup Build Dependencies

The package includes all necessary C libraries and headers, but you need build tools:

```bash
# Install build dependencies
pip install numpy cython setuptools wheel

# For development/testing
pip install pytest pytest-cov
```

### 2. Build the Package

```bash
python setup.py build_ext --inplace
```

### 3. Install

```bash
pip install .
```

## Platform-Specific Notes

### macOS

On macOS, you may need to install Xcode command line tools:

```bash
xcode-select --install
```

### Linux

On Ubuntu/Debian systems, install build essentials:

```bash
sudo apt-get update
sudo apt-get install build-essential python3-dev
```

On CentOS/RHEL/Fedora:

```bash
sudo yum groupinstall "Development Tools"
sudo yum install python3-devel
```

### Windows

On Windows, you'll need Microsoft Visual C++ Build Tools or Visual Studio with C++ support.

## Bundled Dependencies

RMNpy includes bundled static libraries and headers for:

* **RMNLib**: Core scientific dataset library
* **OCTypes**: Foundation types library  
* **SITypes**: SI units library

This design provides a zero-setup build experience - no separate installation of C dependencies is required.

## Troubleshooting

### Common Build Issues

**Error: "Microsoft Visual C++ 14.0 is required" (Windows)**
```bash
# Install Microsoft C++ Build Tools
# Download from: https://visualstudio.microsoft.com/visual-cpp-build-tools/
```

**Error: "numpy not found during build"**
```bash
pip install numpy
# Then retry the installation
```

**Error: "cython not found"**
```bash
pip install cython
# Then retry the installation
```

### Memory Issues

If you encounter hanging or memory issues during testing:

```python
# Test with a simple import
python -c "import rmnpy; print('Success')"

# Test with basic functionality
python -c "
import rmnpy
dataset = rmnpy.Dataset.create()
print(f'Dataset created: {dataset}')
"
```

### Development Setup

For development work, also install testing and documentation dependencies:

```bash
# Testing
pip install pytest pytest-cov pytest-benchmark

# Documentation (if building docs)
pip install sphinx sphinx-rtd-theme myst-parser

# Linting/formatting
pip install black flake8 mypy
```

## Verification

After installation, run the test suite to verify everything works:

```bash
# Quick test
python -m pytest tests/test_basic.py::TestImports -v

# Full test suite
python -m pytest tests/ -v

# With coverage
python -m pytest tests/ --cov=rmnpy --cov-report=html
```

## Next Steps

Once installed, proceed to the [quickstart guide](quickstart.md) to learn how to use RMNpy.
