# RMNpy

A Python wrapper for the RMNLib C library, providing access to Core Scientific Dataset Model (CSDM) functionality from Python.

## Overview

RMNpy is a Cython-based Python package that wraps the RMNLib C library, allowing Python developers to work with scientific datasets using the Core Scientific Dataset Model (CSDM) format. The package provides clean, Pythonic interfaces to RMNLib's Dataset functionality while maintaining the performance of the underlying C implementation.

## Features

- **Dataset Management**: Create and manipulate scientific datasets
- **Datum Operations**: Work with individual data elements within datasets  
- **Memory Safety**: Automatic memory management with proper cleanup
- **NumPy Integration**: Seamless integration with NumPy arrays
- **Error Handling**: Comprehensive exception hierarchy for robust error handling
- **Performance**: Direct access to optimized C library functions

## Dependencies

RMNpy depends on three C libraries that must be built before installation:

- **RMNLib**: Core scientific dataset library
- **OCTypes**: Foundation types library (strings, arrays, dictionaries, memory management)
- **SITypes**: SI units library (scalars, units, physical quantities)

## Installation

### Prerequisites

- Python 3.8+
- NumPy
- Cython (for building)
- C compiler (gcc, clang, or MSVC)
- Built libraries: libRMNLib.a, libOCTypes.a, libSITypes.a

### Building from Source

1. **Clone or extract the RMNpy project:**
   ```bash
   cd /path/to/RMNpy
   ```

2. **Setup dependencies (copies headers and libraries):**
   ```bash
   python3 build_deps.py --base-path /path/to/OCTypes-SITypes
   ```

3. **Build using the build script:**
   ```bash
   ./build.sh --setup-deps
   ```

   Or manually:
   ```bash
   pip install -r requirements.txt
   python setup.py build_ext --inplace
   pip install -e .
   ```

### Verify Installation

```python
import rmnpy
print("RMNpy imported successfully!")

# Test basic functionality
dataset = rmnpy.Dataset.create()
print(f"Created dataset with {dataset.num_datums} datums")
```

## Quick Start

### Basic Usage

```python
import rmnpy
import numpy as np

# Create a new dataset
dataset = rmnpy.Dataset.create()
print(f"Dataset has {dataset.num_datums} datums")

# Create a datum
datum = rmnpy.Datum.create()
print("Created new datum")

# Work with NumPy arrays (data setting to be implemented)
data = np.array([1.0, 2.0, 3.0, 4.0, 5.0])
# datum.set_data(data)  # Coming soon
```

### Error Handling

```python
from rmnpy.exceptions import RMNError, RMNMemoryError, RMNLibraryError

try:
    dataset = rmnpy.Dataset.create()
    # ... operations ...
except RMNMemoryError as e:
    print(f"Memory allocation failed: {e}")
except RMNLibraryError as e:
    print(f"RMNLib error: {e}")
except RMNError as e:
    print(f"General RMN error: {e}")
```

## API Reference

### Classes

#### `Dataset`
Represents a scientific dataset following the CSDM model.

**Methods:**
- `Dataset.create()` - Create a new empty dataset
- `num_datums` - Property returning the number of datums in the dataset

#### `Datum`  
Represents an individual data element within a dataset.

**Methods:**
- `Datum.create()` - Create a new empty datum

### Exceptions

- `RMNError` - Base exception for all RMN-related errors
- `RMNMemoryError` - Memory allocation/management errors  
- `RMNLibraryError` - Errors from the underlying RMNLib C library

## Development

### Project Structure

```
RMNpy/
├── src/rmnpy/           # Python package source
│   ├── __init__.py      # Package interface
│   ├── core.pyx         # Main Cython implementation  
│   ├── core.pxd         # C API declarations
│   ├── exceptions.py    # Exception hierarchy
│   └── types.py         # Type definitions
├── include/             # C header files
│   ├── RMNLib/          # RMNLib headers
│   ├── OCTypes/         # OCTypes headers  
│   └── SITypes/         # SITypes headers
├── lib/                 # Static libraries
├── tests/               # Test suite
├── examples/            # Usage examples
├── setup.py             # Build configuration
├── pyproject.toml       # Modern Python packaging
└── requirements.txt     # Dependencies
```

### Building for Development

```bash
# Setup development environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Setup dependencies and build
python3 build_deps.py --verbose
python setup.py build_ext --inplace --debug

# Install in development mode  
pip install -e .

# Run tests
python -m pytest tests/ -v
```

### Running Tests

```bash
# Run all tests
python -m pytest tests/ -v

# Run specific test file
python -m pytest tests/test_basic.py -v

# Run with coverage
pip install pytest-cov
python -m pytest tests/ --cov=rmnpy --cov-report=html
```

### Memory Management

RMNpy uses RAII (Resource Acquisition Is Initialization) patterns for memory management:

- C objects are automatically retained when wrapped
- Automatic cleanup occurs when Python objects are garbage collected
- Manual cleanup is available but not required
- Reference counting ensures proper memory lifecycle

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality  
5. Ensure all tests pass
6. Submit a pull request

## License

This project is licensed under the same terms as the underlying RMNLib library. See the LICENSE file for details.

## Troubleshooting

### Build Issues

**Error: "Cannot find RMNLib headers"**
- Ensure `build_deps.py` was run successfully
- Check that the base path to OCTypes-SITypes is correct
- Verify that RMNLib, OCTypes, and SITypes are built

**Error: "Cannot find libRMNLib.a"**  
- Build the required libraries first:
  ```bash
  cd /path/to/RMNLib && make
  cd /path/to/OCTypes && make  
  cd /path/to/SITypes && make
  ```
- Run `build_deps.py` to copy libraries to the correct location

**Error: "Cython compilation failed"**
- Install/upgrade Cython: `pip install --upgrade cython`
- Install NumPy: `pip install numpy`
- Check that a C compiler is available

### Runtime Issues

**Import Error: "No module named rmnpy"**
- Ensure the package was installed: `pip install -e .`
- Check that you're using the correct Python environment

**Segmentation Fault**
- This usually indicates a memory management issue
- Check that all required libraries are compatible versions
- Enable debug builds for more detailed error information

## Roadmap

### Current Status (v0.1.0)
- ✅ Basic Dataset and Datum creation
- ✅ Memory management and cleanup
- ✅ Error handling infrastructure  
- ✅ Build system and packaging

### Planned Features
- 🔄 Data setting and retrieval methods
- 🔄 NumPy array integration
- 🔄 Dimension manipulation
- 🔄 File I/O operations
- 🔄 Comprehensive test coverage
- 🔄 Documentation and examples
- 🔄 Performance optimization

### Future Enhancements  
- Advanced CSDM features
- Porting over all RMN capabilities, i.e., Signal Processing, Import, etc.
- Integration with other scientific Python packages

## Support

For issues, questions, or contributions:

1. Check the troubleshooting section above
2. Review existing issues in the repository
3. Create a new issue with detailed information about your problem
4. Include system information, error messages, and steps to reproduce

---

**Note**: This is an early version of RMNpy. Some functionality is still being implemented. See the roadmap above for current status and planned features.
