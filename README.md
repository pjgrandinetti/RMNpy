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

## Quick Start

```python
import rmnpy

# Example usage will be added as we implement the wrappers
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
