# Quickstart Guide

This tutorial will get you up and running with RMNpy in just a few minutes.

## Basic Imports

Start by importing the main RMNpy classes:

```python
import rmnpy
from rmnpy import Dataset, Datum, Dimension, DependentVariable
```

## Creating Your First Dataset

The `Dataset` class represents a complete scientific dataset:

```python
# Create a basic dataset
dataset = Dataset.create()
print(f"Empty dataset: {dataset}")

# Create a dataset with metadata
dataset = Dataset.create(
    title="My NMR Experiment",
    description="1H NMR spectrum of benzene"
)
print(f"Dataset with metadata: {dataset}")
```

## Working with Dimensions

Dimensions represent coordinate axes in your dataset:

```python
# Create a frequency dimension
frequency_dim = Dimension.create_linear(
    label="frequency",
    description="1H NMR frequency axis", 
    count=256,
    start=0.0,
    increment=10.0,
    unit="Hz"
)

print(f"Frequency dimension: {frequency_dim}")
print(f"  Label: {frequency_dim.label}")
print(f"  Count: {frequency_dim.count}")
print(f"  Type: {frequency_dim.type}")
```

### Different Dimension Types

```python
# Chemical shift dimension (ppm)
chemical_shift = Dimension.create_linear(
    label="chemical_shift",
    count=512,
    start=10.0,
    increment=-0.02,  # Decreasing for chemical shift
    unit="ppm"
)

# Time dimension
time_dim = Dimension.create_linear(
    label="time",
    count=128,
    start=0.0,
    increment=0.001,
    unit="s"
)

print(f"Chemical shift: {chemical_shift}")
print(f"Time dimension: {time_dim}")
```

## Working with Dependent Variables

Dependent variables represent the data values in your dataset:

```python
# Create a signal intensity variable
intensity = DependentVariable.create(
    name="signal_intensity",
    description="NMR signal amplitude",
    unit="arbitrary_units"
)

# Create complex signal components
real_signal = DependentVariable.create(
    name="real",
    description="Real component of complex signal",
    unit="V"
)

imaginary_signal = DependentVariable.create(
    name="imaginary", 
    description="Imaginary component of complex signal",
    unit="V"
)

print(f"Intensity: {intensity}")
print(f"Real signal: {real_signal}")
print(f"Imaginary signal: {imaginary_signal}")
```

## Working with Data Points

Individual data points are represented by the `Datum` class:

```python
# Create simple data points
datum1 = Datum.create(response_value=1.5)
datum2 = Datum.create(response_value=2.3)

print(f"Data point 1: {datum1}")
print(f"Data point 2: {datum2}")

# Data points with coordinates (for future implementation)
# datum_with_coords = Datum.create(
#     response_value=4.2,
#     coordinates=[100.0, 5.5]  # frequency, chemical shift
# )
```

## Building a Complete Dataset

Here's how to create a more complex dataset with multiple dimensions and variables:

```python
# Create dimensions for a 2D NMR experiment
f1_dim = Dimension.create_linear(
    label="f1",
    description="First frequency dimension",
    count=128,
    unit="Hz"
)

f2_dim = Dimension.create_linear(
    label="f2", 
    description="Second frequency dimension",
    count=256,
    unit="Hz"
)

# Create dependent variables for complex data
real_var = DependentVariable.create(
    name="real_signal",
    description="Real component",
    unit="V"
)

imag_var = DependentVariable.create(
    name="imag_signal",
    description="Imaginary component", 
    unit="V"
)

# Create the main dataset
nmr_dataset = Dataset.create(
    title="2D NMR COSY Experiment",
    description="2D correlation spectroscopy of organic compound"
)

print("=== 2D NMR Dataset ===")
print(f"Dataset: {nmr_dataset}")
print(f"F1 dimension: {f1_dim}")
print(f"F2 dimension: {f2_dim}")
print(f"Real data: {real_var}")
print(f"Imaginary data: {imag_var}")
```

## Error Handling

RMNpy provides comprehensive error handling:

```python
from rmnpy.exceptions import RMNLibError, RMNLibMemoryError, RMNLibValidationError

try:
    # Your RMNpy operations here
    dataset = Dataset.create(title="Test Dataset")
    
except RMNLibMemoryError as e:
    print(f"Memory error: {e}")
    
except RMNLibValidationError as e:
    print(f"Validation error: {e}")
    
except RMNLibError as e:
    print(f"General RMNLib error: {e}")
```

## Memory Management

RMNpy handles memory management automatically, but you can also explicitly clean up:

```python
# Memory is automatically managed
dataset = Dataset.create()
dimension = Dimension.create_linear(label="test", count=100)

# Objects are automatically cleaned up when they go out of scope
# No manual memory management required!

# For explicit cleanup in long-running applications:
rmnpy.shutdown()  # Clean up any remaining resources
```

## Quick Testing Script

Here's a complete script to test your RMNpy installation:

```python
#!/usr/bin/env python3
"""
RMNpy quickstart test script.
"""
import rmnpy
from rmnpy import Dataset, Datum, Dimension, DependentVariable

def main():
    print(f"RMNpy version: {rmnpy.__version__}")
    print("=" * 50)
    
    # Test basic functionality
    print("1. Creating dataset...")
    dataset = Dataset.create(title="Test Dataset")
    print(f"   ✓ {dataset}")
    
    print("2. Creating dimension...")
    dim = Dimension.create_linear(label="frequency", count=256, unit="Hz")
    print(f"   ✓ {dim}")
    
    print("3. Creating dependent variable...")
    var = DependentVariable.create(name="intensity", unit="counts")
    print(f"   ✓ {var}")
    
    print("4. Creating data point...")
    datum = Datum.create(response_value=42.0)
    print(f"   ✓ {datum}")
    
    print("\n✓ All basic functionality working!")
    print("RMNpy is ready to use.")

if __name__ == "__main__":
    main()
```

Save this as `test_rmnpy.py` and run it:

```bash
python test_rmnpy.py
```

## What's Next?

Now that you've got the basics, explore:

* **[User Guide](user_guide/index.md)**: Comprehensive documentation of all features
* **[API Reference](api_reference/index.md)**: Complete API documentation
* **[Examples](examples/index.md)**: Real-world usage examples

### Coming Soon

* **Developer Guide**: Contributing to RMNpy

## Current Limitations

:::{note}
**Development Status**: RMNpy is under active development. Current limitations include:

* Placeholder implementations for some methods
* Limited data array support (planned for future releases)
* CSDM file I/O not yet implemented
* Advanced mathematical operations not yet available

Check the [project status](https://github.com/pjgrandinetti/RMNpy/blob/main/docs/PROJECT_STATUS.md) for the latest updates.
:::

Happy coding with RMNpy! 🚀
