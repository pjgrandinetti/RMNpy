# Core API Reference

## rmnpy.core

```{eval-rst}
.. automodule:: rmnpy.core
   :members:
   :undoc-members:
   :show-inheritance:
```

## Dataset

```{eval-rst}
.. autoclass:: rmnpy.core.Dataset
   :members:
   :undoc-members:
   :show-inheritance:
   
   .. automethod:: __init__
   .. automethod:: create
```

### Dataset Methods

The `Dataset` class provides the following methods:

#### create(title=None, description=None)

Create a new Dataset instance.

**Parameters:**
- `title` (str, optional): Dataset title
- `description` (str, optional): Dataset description

**Returns:**
- `Dataset`: New dataset instance

**Example:**
```python
from rmnpy import Dataset

# Basic dataset
dataset = Dataset.create()

# Dataset with metadata
dataset = Dataset.create(
    title="NMR Spectrum",
    description="1H NMR of benzene"
)
```

### Dataset Properties

#### title

Get the dataset title.

**Returns:**
- `str | None`: Dataset title or None if not set

#### description  

Get the dataset description.

**Returns:**
- `str | None`: Dataset description or None if not set

---

## Datum

```{eval-rst}
.. autoclass:: rmnpy.core.Datum
   :members:
   :undoc-members:
   :show-inheritance:
   
   .. automethod:: __init__
   .. automethod:: create
```

### Datum Methods

#### create(response_value)

Create a new Datum instance.

**Parameters:**
- `response_value` (float): The response value for this data point

**Returns:**
- `Datum`: New datum instance

**Example:**
```python
from rmnpy import Datum

# Create data points
datum1 = Datum.create(response_value=1.5)
datum2 = Datum.create(response_value=2.3)
```

---

## Dimension

```{eval-rst}
.. autoclass:: rmnpy.core.Dimension
   :members:
   :undoc-members:
   :show-inheritance:
   
   .. automethod:: __init__
   .. automethod:: create_linear
```

### Dimension Methods

#### create_linear(label=None, description=None, count=None, start=None, increment=None, unit=None)

Create a new linear Dimension instance.

**Parameters:**
- `label` (str, optional): Dimension label
- `description` (str, optional): Dimension description  
- `count` (int, optional): Number of points in dimension
- `start` (float, optional): Starting value
- `increment` (float, optional): Increment between points
- `unit` (str, optional): Physical unit

**Returns:**
- `Dimension`: New dimension instance

**Example:**
```python
from rmnpy import Dimension

# Frequency dimension
freq_dim = Dimension.create_linear(
    label="frequency",
    description="1H NMR frequency",
    count=256,
    start=0.0,
    increment=10.0,
    unit="Hz"
)

# Chemical shift dimension (decreasing)
cs_dim = Dimension.create_linear(
    label="chemical_shift", 
    count=512,
    start=10.0,
    increment=-0.02,
    unit="ppm"
)
```

### Dimension Properties

#### label

Get the dimension label.

**Returns:**
- `str | None`: Dimension label or None if not set

#### description

Get the dimension description.

**Returns:**
- `str | None`: Dimension description or None if not set

#### count

Get the number of points in the dimension.

**Returns:**
- `int | None`: Point count or None if not set

#### type

Get the dimension type.

**Returns:**
- `str | None`: Dimension type ("linear", "logarithmic", etc.) or None if not set

---

## DependentVariable

```{eval-rst}
.. autoclass:: rmnpy.core.DependentVariable
   :members:
   :undoc-members:
   :show-inheritance:
   
   .. automethod:: __init__
   .. automethod:: create
```

### DependentVariable Methods

#### create(name=None, description=None, unit=None)

Create a new DependentVariable instance.

**Parameters:**
- `name` (str, optional): Variable name
- `description` (str, optional): Variable description
- `unit` (str, optional): Physical unit

**Returns:**
- `DependentVariable`: New dependent variable instance

**Example:**
```python
from rmnpy import DependentVariable

# Signal intensity
intensity = DependentVariable.create(
    name="signal_intensity",
    description="NMR signal amplitude", 
    unit="arbitrary_units"
)

# Complex signal components
real_signal = DependentVariable.create(
    name="real",
    description="Real component",
    unit="V"
)

imaginary_signal = DependentVariable.create(
    name="imaginary",
    description="Imaginary component", 
    unit="V"
)
```

### DependentVariable Properties

#### name

Get the variable name.

**Returns:**
- `str | None`: Variable name or None if not set

#### description

Get the variable description.

**Returns:**
- `str | None`: Variable description or None if not set

#### unit

Get the variable unit.

**Returns:**
- `str | None`: Physical unit or None if not set

---

## Utility Functions

### shutdown()

Clean up any remaining RMNLib resources.

**Example:**
```python
import rmnpy

# ... use RMNpy objects ...

# Clean up resources (optional, usually automatic)
rmnpy.shutdown()
```

**Note:** This function is typically not needed as memory management is automatic. It's provided for applications that create many objects and want explicit cleanup control.

---

## Implementation Notes

### Memory Management

All RMNpy objects automatically manage their underlying C memory:

- Objects are automatically cleaned up when they go out of scope
- No manual memory management is required in typical usage
- The `shutdown()` function provides explicit cleanup for long-running applications

### Thread Safety

:::{warning}
**Thread Safety**: RMNpy objects are not thread-safe. Use appropriate synchronization if accessing objects from multiple threads.
:::

### Performance Characteristics

- Object creation: Fast (lightweight C wrapper)
- Property access: Fast (direct C structure access)  
- String operations: Moderate (C string conversion overhead)
- Memory usage: Low (minimal Python overhead)

### Current Limitations

:::{note}
**Implementation Status**: 

- All methods and properties are functional
- Some properties return placeholder values during development
- Data array operations not yet implemented
- CSDM file I/O operations planned for future release
:::

## See Also

- [Exceptions API](exceptions.md): Error handling classes
- [Types API](types.md): Type definitions and enumerations
- [User Guide](../user_guide/index.md): Comprehensive usage examples
