# Types API Reference

## rmnpy.types

Type definitions and enumerations used throughout RMNpy.

```{eval-rst}
.. automodule:: rmnpy.types
   :members:
   :undoc-members:
   :show-inheritance:
```

## DimensionType

```{eval-rst}
.. autoclass:: rmnpy.types.DimensionType
   :members:
   :undoc-members:
   :show-inheritance:
```

Enumeration of dimension types supported by RMNpy.

**Values:**

- `LINEAR`: Linear spacing dimension (constant increment)
- `LOGARITHMIC`: Logarithmic spacing dimension  
- `LABELED`: Explicitly labeled dimension points
- `MONOTONIC`: Monotonically varying dimension

**Usage:**
```python
from rmnpy.types import DimensionType

# Check dimension type
if dimension_type == DimensionType.LINEAR:
    print("Linear dimension")
elif dimension_type == DimensionType.LOGARITHMIC:
    print("Logarithmic dimension")
```

## ScalingType

```{eval-rst}
.. autoclass:: rmnpy.types.ScalingType
   :members:
   :undoc-members:
   :show-inheritance:
```

Enumeration of scaling methods for data processing.

**Values:**

- `LINEAR`: Linear scaling
- `LOGARITHMIC`: Logarithmic scaling
- `EXPONENTIAL`: Exponential scaling
- `CUSTOM`: Custom scaling function

**Usage:**
```python
from rmnpy.types import ScalingType

# Apply scaling
if scaling == ScalingType.LOGARITHMIC:
    # Apply logarithmic scaling
    pass
```

## Type Checking Utilities

### isinstance_dimension_type()

Check if a value is a valid DimensionType.

**Parameters:**
- `value`: Value to check

**Returns:**
- `bool`: True if value is a DimensionType

**Example:**
```python
from rmnpy.types import DimensionType, isinstance_dimension_type

dim_type = DimensionType.LINEAR
if isinstance_dimension_type(dim_type):
    print("Valid dimension type")
```

### isinstance_scaling_type()

Check if a value is a valid ScalingType.

**Parameters:**
- `value`: Value to check

**Returns:**
- `bool`: True if value is a ScalingType

**Example:**
```python
from rmnpy.types import ScalingType, isinstance_scaling_type

scaling = ScalingType.LOGARITHMIC
if isinstance_scaling_type(scaling):
    print("Valid scaling type")
```

## Type Conversion

### to_dimension_type()

Convert string to DimensionType.

**Parameters:**
- `value` (str): String representation

**Returns:**
- `DimensionType`: Corresponding dimension type

**Raises:**
- `ValueError`: If string is not a valid dimension type

**Example:**
```python
from rmnpy.types import to_dimension_type

dim_type = to_dimension_type("linear")
assert dim_type == DimensionType.LINEAR
```

### to_scaling_type()

Convert string to ScalingType.

**Parameters:**
- `value` (str): String representation

**Returns:**
- `ScalingType`: Corresponding scaling type

**Raises:**
- `ValueError`: If string is not a valid scaling type

**Example:**
```python
from rmnpy.types import to_scaling_type

scaling = to_scaling_type("logarithmic")
assert scaling == ScalingType.LOGARITHMIC
```

## Constants

### DEFAULT_DIMENSION_TYPE

Default dimension type for new dimensions.

**Value:** `DimensionType.LINEAR`

### SUPPORTED_DIMENSION_TYPES

List of all supported dimension types.

**Value:** `[DimensionType.LINEAR, DimensionType.LOGARITHMIC, DimensionType.LABELED, DimensionType.MONOTONIC]`

### DEFAULT_SCALING_TYPE

Default scaling type for data processing.

**Value:** `ScalingType.LINEAR`

## Usage Examples

### Working with Dimension Types

```python
from rmnpy import Dimension
from rmnpy.types import DimensionType

# Create different dimension types
linear_dim = Dimension.create_linear(
    label="frequency",
    count=256
)

# Check dimension type (when implemented)
# dim_type = linear_dim.get_type()
# if dim_type == DimensionType.LINEAR:
#     print("This is a linear dimension")
```

### Type Validation

```python
from rmnpy.types import DimensionType, isinstance_dimension_type

def validate_dimension_type(dim_type):
    """Validate dimension type parameter."""
    if not isinstance_dimension_type(dim_type):
        raise ValueError(f"Invalid dimension type: {dim_type}")
    
    if dim_type not in [DimensionType.LINEAR, DimensionType.LOGARITHMIC]:
        raise ValueError(f"Unsupported dimension type: {dim_type}")
    
    return dim_type

# Usage
try:
    valid_type = validate_dimension_type(DimensionType.LINEAR)
    print(f"Valid type: {valid_type}")
except ValueError as e:
    print(f"Validation error: {e}")
```

### String Conversion

```python
from rmnpy.types import DimensionType, to_dimension_type

# Convert from string
dimension_types = ["linear", "logarithmic", "labeled"]

for type_str in dimension_types:
    try:
        dim_type = to_dimension_type(type_str)
        print(f"'{type_str}' -> {dim_type}")
    except ValueError as e:
        print(f"Invalid type string: {type_str}")

# Convert to string
dim_type = DimensionType.LINEAR
type_name = dim_type.name.lower()
print(f"{dim_type} -> '{type_name}'")
```

## Implementation Notes

### Current Status

:::{note}
**Implementation Status**: 

✅ **Implemented**: Basic type definitions and enumerations
⚠️ **Partial**: Type checking and validation utilities
🚧 **Planned**: Advanced type conversion and validation
🚧 **Planned**: Integration with core classes for type checking
:::

### Future Enhancements

Planned enhancements for the types system:

- **Runtime Type Checking**: Automatic validation of types in core classes
- **Type Hints**: Full typing support for better IDE integration  
- **Custom Types**: Support for user-defined dimension and scaling types
- **Type Serialization**: Save/load type information with datasets

### Performance Considerations

- Type checking is lightweight with minimal overhead
- Enumerations are memory efficient
- String conversions are cached for performance
- Type validation should be used judiciously in hot code paths

## See Also

- [Core API](core.md): Main classes that use these types
- [Exceptions API](exceptions.md): Type-related error handling
- [User Guide](../user_guide/index.md): Practical usage examples
