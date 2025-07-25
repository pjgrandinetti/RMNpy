# RMNpy

Python bindings for OCTypes, SITypes, and RMNLib C libraries.

> **🚀 Setting up on a new computer?** See **[docs/development/NEW_COMPUTER_SETUP.md](docs/development/NEW_COMPUTER_SETUP.md)** for quick setup or **[docs/development/ENVIRONMENT_SETUP.md](docs/development/ENVIRONMENT_SETUP.md)** for detailed instructions.

## Overview

RMNpy provides Python access to three scientific computing C libraries:

- **OCTypes**: Objective-C style data structures and memory management
- **SITypes**: Scientific units and dimensional analysis
- **RMNLib**: High-level analysis and computation tools

## Features

- Type-safe conversion between Python and C data structures
- Scientific units and dimensional analysis
- High-performance numerical computations
- Memory-safe interface to C libraries

## Installation

### For Development (Recommended)

See **[docs/development/ENVIRONMENT_SETUP.md](docs/development/ENVIRONMENT_SETUP.md)** for complete instructions.

Quick version:
```bash
# Clone the repo with all C libraries
git clone https://github.com/pjgrandinetti/OCTypes-SITypes.git
cd OCTypes-SITypes

# Build required C libraries first
cd OCTypes && make && make install && cd ..
cd SITypes && make && make synclib && make install && cd ..
cd RMNLib && make && make synclib && make install && cd ..

# Set up Python environment
cd RMNpy
conda env create -f environment.yml
conda activate rmnpy
pip install -e .
```

### For End Users (When Available)

```bash
pip install rmnpy
```

### Windows (MSYS2/Mingw-w64 Python)

To install RMNpy with C99-based Cython extensions on Windows you must use the MSYS2 MINGW64 Python runtime:

1. Install [MSYS2](https://www.msys2.org/) and open the **MSYS2 MinGW64** shell.
2. Update packages and install dependencies:

   ```bash
   pacman -Syu             # first-time update
   pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-python-pip \
                mingw-w64-x86_64-openblas mingw-w64-x86_64-lapack \
                mingw-w64-x86_64-curl mingw-w64-x86_64-make
   ```

3. Create and activate a virtual environment (so pip can install into it):

   ```bash
   python -m pip install --upgrade pip virtualenv
   python -m virtualenv venv
   source venv/bin/activate
   ```

4. Install RMNpy and test extras:

   ```bash
   pip install numpy pytest pytest-cov
   pip install -e .[test]
   ```

5. Run your scripts or pytest from this venv; it uses MinGW-built extensions compatible with Windows.

#### Using Conda-forge MSYS2 Environment (Optional)
If you prefer managing dependencies with conda, you can provision an MSYS2 toolchain via conda-forge:

```bash
conda create -n rmnpy-win python=3.12 pip m2-msys2-runtime m2-gcc m2-gcc-fortran m2-openblas m2-lapack m2-curl m2-make virtualenv -c conda-forge
conda activate rmnpy-win
# (Optional) isolate further via virtualenv within conda env:
python -m venv venv
source venv/bin/activate
pip install -e .[test]
```

## Quick Start

```python
from rmnpy.wrappers.sitypes import Scalar, Unit, Dimensionality

# === Flexible Scalar Creation ===

# Single string expressions (value + unit)
energy = Scalar("100 J")           # 100 Joules
velocity = Scalar("25 m/s")        # 25 meters per second

# Single numeric values (dimensionless)
ratio = Scalar(0.75)               # 0.75 (dimensionless)
count = Scalar(42)                 # 42 (dimensionless)
impedance = Scalar(3+4j)           # Complex number

# Value and unit pairs
distance = Scalar(100, "m")        # 100 meters
power = Scalar(2.5, "W")           # 2.5 Watts
current = Scalar(3+4j, "A")        # Complex current

# Named parameters
unit_meter = Scalar(expression="m")                  # 1 meter
force = Scalar(value=9.8, expression="kg*m/s^2")    # 9.8 Newtons

# === Scientific Calculations with Automatic Units ===

# Basic physics calculations
time = Scalar(2, "s")
speed = distance / time             # Result: 50 m/s (automatic unit derivation)
acceleration = Scalar(9.8, "m/s^2")
force = Scalar(5, "kg") * acceleration  # Result: 49 N (automatic units)

# Unit conversions
speed_kmh = speed.convert_to("km/h")     # Convert to km/h
speed_si = speed.to_coherent_si()        # Convert to SI base units

# === Dimensional Analysis & Safety ===

# Automatic dimensional validation
try:
    invalid = distance + time        # Error: cannot add length + time
except RMNError:
    print("Dimensional mismatch caught!")

# Complex calculations with unit tracking
kinetic_energy = 0.5 * Scalar(2, "kg") * speed**2  # Result: 2500 J

# === Unit and Dimensionality Operations ===

# Create and manipulate units
meter = Unit("m")
second = Unit("s")
velocity_unit = meter / second       # Result: m/s

# Dimensional analysis
length_dim = Dimensionality("L")
time_dim = Dimensionality("T")
velocity_dim = length_dim / time_dim # Result: L/T

print(f"Speed: {speed}")             # "50 m/s"
print(f"Unit: {speed.unit.symbol}")  # "m/s"
print(f"Dimensionality: {speed.dimensionality.symbol}")  # "L/T"
```

## Development

This package is built using Cython to provide efficient bindings to the underlying C libraries.

### Setting up the development environment

1. **Create conda environment:**

   ```bash
   conda env create -f environment-dev.yml
   conda activate rmnpy
   ```

2. **Sync libraries from local development:**

   ```bash
   make synclib  # Copy libraries from local ../OCTypes, ../SITypes, ../RMNLib
   ```

3. **Install in development mode:**

   ```bash
   pip install -e .
   ```

### Building from source

```bash
git clone https://github.com/pjgrandinetti/RMNpy.git
cd RMNpy
conda env create -f environment.yml
conda activate rmnpy
make synclib  # Copy libraries from local development
pip install -e .
```

### Makefile targets

- `make synclib` - Copy libraries from local ../OCTypes, ../SITypes, ../RMNLib directories
- `make download-libs` - Download libraries from GitHub releases (future feature)
- `make clean` - Remove generated C files and build artifacts
- `make clean-libs` - Remove local libraries to force re-download
- `make rebuild` - Clean libraries and rebuild Python package
- `make test` - Run the test suite
- `make status` - Check library status

See **[docs/development/DEVELOPMENT.md](docs/development/DEVELOPMENT.md)** for complete development workflows.

## Documentation

### User Documentation

- **API Documentation**: [Read the Docs](https://rmnpy.readthedocs.io) (when available)

### Development Documentation

- **[docs/development/README.md](docs/development/README.md)** - Navigation guide for all development docs
- **[docs/development/NEW_COMPUTER_SETUP.md](docs/development/NEW_COMPUTER_SETUP.md)** - Quick setup guide
- **[docs/development/ENVIRONMENT_SETUP.md](docs/development/ENVIRONMENT_SETUP.md)** - Detailed setup + troubleshooting
- **[docs/development/DEVELOPMENT.md](docs/development/DEVELOPMENT.md)** - Development workflow
- **[docs/development/RMNpy_Implementation_Plan.md](docs/development/RMNpy_Implementation_Plan.md)** - Project plan & progress

## License

See LICENSE file for details.

## Contributing

Contributions are welcome! Please see the development documentation for guidelines.
