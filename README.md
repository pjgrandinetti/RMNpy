# RMNpy

> **⚠️ DEVELOPMENT STATUS**: This project is currently under active development. Many features described in this documentation are not yet implemented and the API is subject to change. This is a work-in-progress wrapper for the RMNLib C library.

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

## Documentation

Comprehensive documentation is available:

📖 **[Online Documentation](https://pjgrandinetti.github.io/RMNpy/)** (GitHub Pages)

### Local Documentation

Build and view documentation locally:

```bash
# Install documentation dependencies
pip install -r docs/requirements.txt

# Build HTML documentation
cd docs
make html

# Open in browser (macOS)
open _build/html/index.html
```

### Documentation Structure

- **[Installation Guide](docs/installation.md)**: Setup and installation
- **[Quickstart Tutorial](docs/quickstart.md)**: Get started in minutes
- **[User Guide](docs/user_guide/index.md)**: Comprehensive usage guide
- **[API Reference](docs/api_reference/index.md)**: Complete API documentation
- **[Examples](docs/examples/index.md)**: Real-world usage examples
- **[Changelog](docs/changelog.md)**: Version history and updates

## Dependencies

RMNpy includes the required C libraries for convenient building:

- **RMNLib**: Core scientific dataset library (bundled)
- **OCTypes**: Foundation types library - strings, arrays, dictionaries, memory management (bundled)
- **SITypes**: SI units library - scalars, units, physical quantities (bundled)

*Note: Header files and static libraries are included in the repository to provide a zero-setup build experience. No separate installation of dependencies is required.*

## Installation

> **⚠️ IMPORTANT**: RMNpy is currently under development. While the build system is functional, many of the API examples shown in this documentation are not yet implemented. Only basic `Dataset` and `Datum` functionality is currently working.

### Prerequisites

- Python 3.8+
- NumPy
- Cython (for building)
- C compiler (gcc, clang, or MSVC)
- Built libraries: libRMN.a, libOCTypes.a, libSITypes.a

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

> **📋 STATUS**: Only the "Basic Usage" section below is currently functional. The `Dimension` and `DependentVariable` examples show the planned API but are not yet implemented.

### Basic Usage

```python
import rmnpy
import numpy as np

# Create a new dataset
dataset = rmnpy.Dataset.create()
print(f"Dataset has {dataset.num_datums} datums")

# Create a datum
datum = rmnpy.Datum.create(response_value=1.5, coordinates=[100.0, 50.0])
print(f"Created datum with response: {datum.response_value}")

# Work with NumPy arrays (data setting to be implemented)
data = np.array([1.0, 2.0, 3.0, 4.0, 5.0])
# datum.set_data(data)  # Coming soon
```

### Creating Dimensions

```python
import rmnpy
from rmnpy.types import DimensionType, ScalingType

# Create a linear dimension (e.g., for frequency axis)
linear_dim = rmnpy.LinearDimension.create(
    label="Chemical Shift",
    description="1H NMR chemical shift",
    count=1024,
    increment=0.1,  # Hz per point
    unit="ppm",
    origin=0.0,
    scaling=ScalingType.NMR
)
print(f"Created linear dimension with {linear_dim.count} points")

# Create a labeled dimension (e.g., for categorical data)
labels = ["Sample A", "Sample B", "Sample C", "Control"]
labeled_dim = rmnpy.LabeledDimension.create(
    label="Sample Type",
    description="Different sample conditions",
    coordinate_labels=labels
)
print(f"Created labeled dimension with {len(labeled_dim.coordinate_labels)} labels")

# Create a monotonic dimension (e.g., for irregular time points)
time_points = [0.0, 0.1, 0.25, 0.5, 1.0, 2.0, 5.0, 10.0]  # seconds
monotonic_dim = rmnpy.MonotonicDimension.create(
    label="Time",
    description="Variable time intervals",
    coordinates=time_points,
    unit="s"
)
print(f"Created monotonic dimension with {len(monotonic_dim.coordinates)} points")
```

### Creating Dependent Variables

```python
import rmnpy
import numpy as np
from rmnpy.types import DataType

# Create a simple dependent variable for real-valued data
real_data = np.random.random(1024)
real_dv = rmnpy.DependentVariable.create(
    name="Intensity",
    description="NMR signal intensity",
    unit="V",
    data_type=DataType.FLOAT64,
    data=real_data
)
print(f"Created real DV with {len(real_dv.data)} points")

# Create a complex dependent variable for NMR/spectroscopy
complex_data = np.random.random(512) + 1j * np.random.random(512)
complex_dv = rmnpy.DependentVariable.create(
    name="FID",
    description="Free Induction Decay",
    unit="V",
    data_type=DataType.COMPLEX128,
    data=complex_data,
    components=["real", "imaginary"]
)
print(f"Created complex DV with {len(complex_dv.data)} points")

# Create a multi-component dependent variable
multicomponent_data = np.random.random((3, 1024))  # 3 components
multi_dv = rmnpy.DependentVariable.create(
    name="Vector Field",
    description="3D magnetic field measurements",
    unit="T",
    data_type=DataType.FLOAT64,
    data=multicomponent_data,
    components=["Bx", "By", "Bz"]
)
print(f"Created multi-component DV with {len(multi_dv.components)} components")
```

### Complete Dataset Example

```python
import rmnpy
import numpy as np

# Create dimensions
freq_dim = rmnpy.LinearDimension.create(
    label="Frequency",
    count=512,
    increment=100.0,  # Hz
    unit="Hz",
    origin=0.0
)

time_dim = rmnpy.LinearDimension.create(
    label="Time",
    count=64,
    increment=0.01,  # seconds
    unit="s",
    origin=0.0
)

# Create dependent variable
spectrum_data = np.random.random((64, 512))  # time x frequency
spectrum_dv = rmnpy.DependentVariable.create(
    name="2D NMR Spectrum",
    description="Two-dimensional NMR spectrum",
    unit="intensity",
    data_type=DataType.FLOAT64,
    data=spectrum_data
)

# Create complete dataset
dataset = rmnpy.Dataset.create(
    title="2D NMR Experiment",
    description="COSY spectrum of organic compound",
    dimensions=[time_dim, freq_dim],
    dependent_variables=[spectrum_dv]
)

print(f"Created 2D dataset: {dataset.title}")
print(f"Dimensions: {len(dataset.dimensions)}")
print(f"Dependent variables: {len(dataset.dependent_variables)}")
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
- `Dataset.create(title, description, dimensions, dependent_variables)` - Create dataset with components

**Properties:**
- `title` - Dataset title string
- `description` - Dataset description
- `dimensions` - List of Dimension objects
- `dependent_variables` - List of DependentVariable objects

#### `Datum`  
Represents an individual data element within a dataset.

**Methods:**
- `Datum.create(response_value, coordinates, response_unit)` - Create datum with response and coordinates

**Properties:**
- `response_value` - The measured response value
- `coordinates` - List of coordinate values
- `component_index` - Component index within dependent variable
- `dependent_variable_index` - Index of associated dependent variable

#### `LinearDimension`
Represents a uniformly spaced coordinate dimension.

**Methods:**
- `LinearDimension.create(label, count, increment, unit, origin, scaling)` - Create linear dimension

**Properties:**
- `label` - Dimension label
- `description` - Dimension description  
- `count` - Number of points
- `increment` - Spacing between points
- `unit` - Physical unit
- `origin` - Starting coordinate value

#### `LabeledDimension`
Represents a dimension with discrete categorical labels.

**Methods:**
- `LabeledDimension.create(label, description, coordinate_labels)` - Create labeled dimension

**Properties:**
- `label` - Dimension label
- `description` - Dimension description
- `coordinate_labels` - List of coordinate labels

#### `MonotonicDimension`
Represents a dimension with non-uniform but monotonic coordinates.

**Methods:**
- `MonotonicDimension.create(label, description, coordinates, unit)` - Create monotonic dimension

**Properties:**
- `label` - Dimension label
- `description` - Dimension description
- `coordinates` - List of coordinate values
- `unit` - Physical unit

#### `DependentVariable`
Represents a data variable with values and metadata.

**Methods:**
- `DependentVariable.create(name, description, unit, data_type, data, components)` - Create dependent variable

**Properties:**
- `name` - Variable name
- `description` - Variable description
- `unit` - Physical unit
- `data_type` - Data type (float64, complex128, etc.)
- `data` - NumPy array of data values
- `components` - List of component names (for multi-component data)

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

**Error: "Cannot find libRMN.a"**  
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

## ⚠️ Development Status

**This is an early development version of RMNpy.** 

**The examples in the Quick Start section that involve Dimensions and DependentVariables are for illustration of the planned API and will not work until those classes are implemented.**

See the [Roadmap](#roadmap) section for current status and planned features.
