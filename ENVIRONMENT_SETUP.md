# Environment Setup Guide

This guide explains how to recreate the development environment for RMNpy on a new computer.

## Prerequisites

- **Miniconda or Anaconda** installed
- **Git** for cloning the repository
- **C compiler** (Xcode Command Line Tools on macOS, gcc on Linux, MSVC on Windows)

## Quick Setup (Recommended)

1. **Clone the repository:**
   ```bash
   git clone <your-repo-url>
   cd RMNpy
   ```

2. **Create the conda environment:**
   ```bash
   conda env create -f environment.yml
   ```

3. **Activate the environment:**
   ```bash
   conda activate rmnpy
   ```

4. **Install the package in development mode:**
   ```bash
   pip install -e .
   ```

5. **Run tests to verify setup:**
   ```bash
   pytest
   ```

## Alternative Setup Methods

### Method 1: Manual Environment Creation

If `environment.yml` doesn't work on your platform:

```bash
# Create new environment with Python 3.11
conda create -n rmnpy python=3.11

# Activate environment
conda activate rmnpy

# Install core dependencies
conda install -c conda-forge cython numpy pytest pytest-cov

# Install additional dependencies
pip install -r requirements.txt

# Install package in development mode
pip install -e .
```

### Method 2: Using pip only

```bash
# Create virtual environment
python -m venv rmnpy-env

# Activate (Linux/macOS)
source rmnpy-env/bin/activate
# OR Windows
# rmnpy-env\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Install package
pip install -e .
```

## Required System Libraries

The project depends on external C libraries that must be built separately:

### OCTypes Library
```bash
cd ../OCTypes
make
```

### SITypes Library
```bash
cd ../SITypes
make
```

### RMNLib Library
```bash
cd ../RMNLib
make
```

## Verification

After setup, verify everything works:

```bash
# Test imports
python -c "import rmnpy; print('RMNpy imported successfully')"

# Run basic functionality test
python -c "from rmnpy.wrappers.sitypes import Dimensionality; print('SITypes integration working')"

# Run full test suite
pytest
```

## Development Environment

For development, you may also want:

```bash
# Development tools
conda install -c conda-forge black isort mypy sphinx

# Jupyter for notebooks
conda install -c conda-forge jupyter
```

## Troubleshooting

### Common Issues

1. **Compilation errors**: Ensure C libraries (OCTypes, SITypes, RMNLib) are built first
2. **Import errors**: Verify environment is activated and package installed with `pip install -e .`
3. **Test failures**: Check that all dependencies are correctly installed

### Platform-Specific Notes

- **macOS**: Requires Xcode Command Line Tools: `xcode-select --install`
- **Linux**: Requires build essentials: `sudo apt-get install build-essential`
- **Windows**: Requires Visual Studio Build Tools or MSVC

## Environment Files

- `environment.yml`: Complete conda environment specification
- `requirements.txt`: Pip-installable packages only
- `pyproject.toml`: Project configuration and build requirements

## Current Status

- **Phase 2A**: Dimensionality wrapper - ✅ Complete (100% tests passing)
- **Phase 2B**: SIUnit wrapper - 🟡 Functional (72% tests passing)
- **Phase 2C**: SIScalar wrapper - ⏳ Planned
- **Phase 3**: RMNLib integration - ⏳ Planned
