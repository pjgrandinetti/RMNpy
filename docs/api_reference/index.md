# API Reference

Complete API documentation for all RMNpy classes and functions.

```{toctree}
:maxdepth: 2

core
exceptions
types
```

## Module Overview

RMNpy provides a clean, object-oriented interface to the RMNLib C library through several key modules:

### Core Module (`rmnpy.core`)

The core module contains the main classes for working with scientific datasets:

- `Dataset`: Complete scientific dataset with metadata and structure
- `Datum`: Individual data points with coordinates and response values  
- `Dimension`: Coordinate axes (labeled, SI, monotonic, linear)
- `DependentVariable`: Data variables with units and metadata

### Exceptions Module (`rmnpy.exceptions`)

Comprehensive exception hierarchy for robust error handling:

- `RMNLibError`: Base exception for all RMNLib errors
- `RMNLibMemoryError`: Memory allocation and management errors
- `RMNLibValidationError`: Input validation and constraint errors

### Types Module (`rmnpy.types`)

Type definitions and enumerations for RMNpy:

- `DimensionType`: Enumeration of dimension types (linear, logarithmic, etc.)
- `ScalingType`: Enumeration of scaling methods

## Quick Reference

### Import Patterns

```python
# Standard import
import rmnpy

# Individual class imports
from rmnpy import Dataset, Datum, Dimension, DependentVariable

# Exception imports
from rmnpy.exceptions import RMNLibError, RMNLibMemoryError

# Type imports
from rmnpy.types import DimensionType, ScalingType
```

### Class Hierarchy

```
Dataset
├── title: str | None
├── description: str | None
└── create(title=None, description=None) -> Dataset

Datum  
├── response_value: float
└── create(response_value: float) -> Datum

Dimension
├── label: str | None
├── description: str | None  
├── count: int | None
├── type: str | None
└── create_linear(...) -> Dimension

DependentVariable
├── name: str | None
├── description: str | None
├── unit: str | None
└── create(...) -> DependentVariable
```

### Exception Hierarchy

```
RMNLibError
├── RMNLibMemoryError
└── RMNLibValidationError
```

## Usage Examples

### Basic Usage

```python
import rmnpy

# Create dataset
dataset = rmnpy.Dataset.create(title="NMR Analysis")

# Create dimension  
freq_dim = rmnpy.Dimension.create_linear(
    label="frequency", 
    count=256, 
    unit="Hz"
)

# Create dependent variable
intensity = rmnpy.DependentVariable.create(
    name="signal_intensity",
    unit="arbitrary_units"
)

# Create data point
datum = rmnpy.Datum.create(response_value=42.0)
```

### Error Handling

```python
from rmnpy.exceptions import RMNLibError, RMNLibMemoryError

try:
    dataset = rmnpy.Dataset.create()
except RMNLibMemoryError as e:
    print(f"Memory error: {e}")
except RMNLibError as e:
    print(f"General error: {e}")
```

## Implementation Status

:::{note}
**Current Implementation Status**:

✅ **Implemented**: Dataset, Datum, Dimension, DependentVariable basic functionality  
✅ **Implemented**: Exception hierarchy and error handling  
✅ **Implemented**: Memory management and cleanup  
⚠️ **Partial**: Property access (some properties return placeholder values)  
🚧 **Planned**: CSDM file I/O operations  
🚧 **Planned**: Data array manipulation  
🚧 **Planned**: Advanced mathematical operations  
:::

## Development Guidelines

When extending the RMNpy API:

1. **Consistency**: Follow existing naming conventions
2. **Error Handling**: Use appropriate exception types
3. **Documentation**: Include comprehensive docstrings
4. **Memory Safety**: Ensure proper cleanup of C resources
5. **Testing**: Add comprehensive test coverage

## Performance Considerations

- RMNpy objects are lightweight wrappers around C structures
- Memory management is automatic but explicit cleanup available
- Large datasets should use appropriate data structures
- Bulk operations are more efficient than individual operations

See the [Performance Guide](../user_guide/index.md) for optimization tips.
