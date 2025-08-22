# RMNpy Environment Setup Guide

This guide explains how to recreate the development environment for RMNpy on a new computer.

> **📍 Repository**: This assumes you're cloning from the main OCTypes-SITypes repository which contains RMNpy as a subdirectory along with the required C libraries.

## Prerequisites

- **Miniconda or Anaconda** installed ([Download here](https://docs.conda.io/en/latest/miniconda.html))
- **Git** for cloning the repository
- **C compiler**:
  - **macOS**: Xcode Command Line Tools → `xcode-select --install`
  - **Linux**: Build essentials → `sudo apt-get install build-essential`
  - **Windows**: Use WSL2 with Linux development environment

## 🚨 Common First-Time Issues

**If you get "No such file or directory" errors during Python setup:**
- ✅ Did you build the C libraries first? (OCTypes, SITypes, RMNLib)
- ✅ Are you in the correct directory? (should be in `OCTypes-SITypes/RMNpy`)

**If conda environment creation fails:**
- Try the manual setup method below
- Check that you have conda/miniconda installed and in your PATH

## Quick Setup (Recommended)

> **⚠️ IMPORTANT**: You must build the C libraries FIRST before Python setup will work!

### Step 1: Clone and Build C Libraries

```bash
# Clone the main repository containing all components
git clone https://github.com/pjgrandinetti/OCTypes-SITypes.git
cd OCTypes-SITypes

# Build OCTypes library (REQUIRED)
cd OCTypes
make
make install
cd ..

# Build SITypes library (REQUIRED)
cd SITypes
make
make synclib
make install
cd ..

# Build RMNLib library (REQUIRED)
cd RMNLib
make
make synclib
make install
cd ..
```

### Step 2: Set Up Python Environment

```bash
# Navigate to RMNpy directory
cd RMNpy

# Create the conda environment from the saved configuration
conda env create -f environment.yml

# Activate the environment
conda activate rmnpy

# Install RMNpy in development mode
pip install -e .
```

### Step 3: Verify Everything Works

```bash
# Test basic imports
python -c "import rmnpy; print('✅ RMNpy imported successfully')"

# Test SITypes integration
python -c "from rmnpy.wrappers.sitypes import Dimensionality; print('✅ SITypes integration working')"

# Run the test suite (should show ~86 tests with most passing)
pytest
```

**Expected Result**: You should see tests running with Phase 2A (Dimensionality) at 100% and Phase 2B (SIUnit) at ~72% completion.

## ✅ What Success Looks Like

When everything is working correctly, you should see:

```
pytest
========================= test session starts =========================
...
tests/test_helpers/test_octypes.py ............                   [ 13%]
tests/test_sitypes/test_dimensionality.py ........................ [ 41%]
tests/test_unit.py ..F.F..FF..FF.F.F..FF..FF....F...FF..F.FF.F....FFF [100%]

================== 22 failed, 64 passed in 2.36s ==================
```

- **86 total tests collected**
- **64 tests passing** (Phase 2A Dimensionality: 22/22, Phase 2B SIUnit: 36/50, OCTypes helpers: 6/6)
- **22 tests failing** (all in Phase 2B SIUnit - this is expected, development in progress)

If you see significantly different results, check the troubleshooting section below.

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

# Activate environment
source rmnpy-env/bin/activate

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
- **Windows**: Use WSL2 with Linux development tools (follow Linux instructions within WSL2)

## Environment Files

- `environment.yml`: Complete conda environment specification
- `requirements.txt`: Pip-installable packages only
- `pyproject.toml`: Project configuration and build requirements

## Current Status

- **Phase 2A**: Dimensionality wrapper - ✅ Complete (100% tests passing)
- **Phase 2B**: SIUnit wrapper - 🟡 Functional (72% tests passing)
- **Phase 2C**: SIScalar wrapper - ⏳ Planned
- **Phase 3**: RMNLib integration - ⏳ Planned
