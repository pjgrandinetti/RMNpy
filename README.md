# RMNpy

Python bindings for OCTypes, SITypes, and RMNLib C libraries.

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
conda env create -f environment-dev.yml
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

See the documentation for more details on development workflows.

## Documentation

Full documentation is available at [Read the Docs](https://rmnpy.readthedocs.io).

## License

See LICENSE file for details.

## Contributing

Contributions are welcome! Please see the development documentation for guidelines.
