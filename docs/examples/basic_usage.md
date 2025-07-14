# Basic Usage Examples

Complete examples demonstrating fundamental RMNpy operations.

## Installation Verification

First, verify that RMNpy is installed and working correctly:

```python
#!/usr/bin/env python3
"""
Verify RMNpy installation and basic functionality.
"""
import sys

def test_installation():
    """Test RMNpy installation and basic imports."""
    
    print("Testing RMNpy installation...")
    print(f"Python version: {sys.version}")
    
    try:
        # Test basic import
        import rmnpy
        print(f"✓ RMNpy imported successfully")
        print(f"✓ RMNpy version: {rmnpy.__version__}")
        
        # Test class imports
        from rmnpy import Dataset, Datum, Dimension, DependentVariable
        print("✓ Core classes imported successfully")
        
        # Test exception imports
        from rmnpy.exceptions import RMNLibError, RMNLibMemoryError
        print("✓ Exception classes imported successfully")
        
        return True
        
    except ImportError as e:
        print(f"✗ Import failed: {e}")
        return False

def test_basic_functionality():
    """Test basic object creation and operations."""
    
    from rmnpy import Dataset, Datum, Dimension, DependentVariable
    
    print("\nTesting basic functionality...")
    
    try:
        # Test Dataset creation
        dataset = Dataset.create(title="Test Dataset")
        print(f"✓ Dataset created: {dataset}")
        
        # Test Datum creation
        datum = Datum.create(response_value=42.0)
        print(f"✓ Datum created: {datum}")
        
        # Test Dimension creation
        dimension = Dimension.create_linear(label="test_dim", count=100)
        print(f"✓ Dimension created: {dimension}")
        
        # Test DependentVariable creation
        dep_var = DependentVariable.create(name="test_var")
        print(f"✓ DependentVariable created: {dep_var}")
        
        return True
        
    except Exception as e:
        print(f"✗ Functionality test failed: {e}")
        return False

if __name__ == "__main__":
    success = test_installation()
    if success:
        success = test_basic_functionality()
    
    if success:
        print("\n🎉 RMNpy is working correctly!")
    else:
        print("\n❌ There are issues with your RMNpy installation")
        sys.exit(1)
```

## Creating and Working with Datasets

### Simple Dataset Creation

```python
#!/usr/bin/env python3
"""
Basic dataset creation examples.
"""
from rmnpy import Dataset

def create_basic_datasets():
    """Demonstrate basic dataset creation patterns."""
    
    print("=== Basic Dataset Creation ===")
    
    # Empty dataset
    empty_dataset = Dataset.create()
    print(f"Empty dataset: {empty_dataset}")
    
    # Dataset with title only
    titled_dataset = Dataset.create(title="My Experiment")
    print(f"Titled dataset: {titled_dataset}")
    
    # Dataset with full metadata
    full_dataset = Dataset.create(
        title="NMR Spectroscopy Analysis",
        description="1H NMR spectrum of benzene in deuterated chloroform"
    )
    print(f"Full dataset: {full_dataset}")
    
    return [empty_dataset, titled_dataset, full_dataset]

def inspect_dataset_properties():
    """Show how to access dataset properties."""
    
    print("\n=== Dataset Property Access ===")
    
    dataset = Dataset.create(
        title="Sample Analysis",
        description="Comprehensive spectroscopic characterization"
    )
    
    # Access properties
    title = dataset.title
    description = dataset.description
    
    print(f"Dataset title: {title}")
    print(f"Dataset description: {description}")
    
    # Handle None values gracefully
    empty_dataset = Dataset.create()
    empty_title = empty_dataset.title
    
    if empty_title is not None:
        print(f"Empty dataset title: {empty_title}")
    else:
        print("Empty dataset has no title")

def create_experimental_series():
    """Create a series of related datasets."""
    
    print("\n=== Experimental Series ===")
    
    # Temperature series
    temperatures = [273, 298, 323, 348]
    temp_datasets = []
    
    for temp in temperatures:
        dataset = Dataset.create(
            title=f"NMR Analysis at {temp}K",
            description=f"Variable temperature NMR study at {temp} Kelvin"
        )
        temp_datasets.append(dataset)
        print(f"Created: {dataset}")
    
    print(f"Total datasets in series: {len(temp_datasets)}")
    return temp_datasets

if __name__ == "__main__":
    datasets = create_basic_datasets()
    inspect_dataset_properties()
    series = create_experimental_series()
```

## Working with Dimensions

### Creating Different Dimension Types

```python
#!/usr/bin/env python3
"""
Dimension creation and manipulation examples.
"""
from rmnpy import Dimension

def create_spectroscopy_dimensions():
    """Create dimensions common in spectroscopy."""
    
    print("=== Spectroscopy Dimensions ===")
    
    # NMR frequency dimension
    frequency_dim = Dimension.create_linear(
        label="frequency",
        description="1H NMR frequency axis",
        count=256,
        start=0.0,
        increment=10.0,
        unit="Hz"
    )
    print(f"Frequency dimension: {frequency_dim}")
    
    # Chemical shift dimension (decreasing)
    chemical_shift_dim = Dimension.create_linear(
        label="chemical_shift",
        description="1H chemical shift",
        count=512,
        start=10.0,
        increment=-0.02,
        unit="ppm"
    )
    print(f"Chemical shift dimension: {chemical_shift_dim}")
    
    # Time dimension
    time_dim = Dimension.create_linear(
        label="time",
        description="Evolution time",
        count=128,
        start=0.0,
        increment=0.001,
        unit="s"
    )
    print(f"Time dimension: {time_dim}")
    
    return [frequency_dim, chemical_shift_dim, time_dim]

def inspect_dimension_properties():
    """Demonstrate dimension property access."""
    
    print("\n=== Dimension Properties ===")
    
    dim = Dimension.create_linear(
        label="mass_to_charge",
        description="Mass-to-charge ratio",
        count=1000,
        start=50.0,
        increment=1.0,
        unit="m/z"
    )
    
    # Access all properties
    label = dim.label
    description = dim.description
    count = dim.count
    dim_type = dim.type
    
    print(f"Label: {label}")
    print(f"Description: {description}")
    print(f"Count: {count}")
    print(f"Type: {dim_type}")

def create_multi_dimensional_setup():
    """Create dimensions for multi-dimensional experiments."""
    
    print("\n=== Multi-Dimensional Setup ===")
    
    # 2D NMR experiment dimensions
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
    
    print(f"F1 dimension: {f1_dim}")
    print(f"F2 dimension: {f2_dim}")
    
    # 3D experiment with time
    time_dim = Dimension.create_linear(
        label="mixing_time",
        description="Mixing time for 3D experiment",
        count=16,
        unit="ms"
    )
    
    print(f"Time dimension: {time_dim}")
    
    return [f1_dim, f2_dim, time_dim]

if __name__ == "__main__":
    spectro_dims = create_spectroscopy_dimensions()
    inspect_dimension_properties()
    multi_dims = create_multi_dimensional_setup()
```

## Working with Data Variables

### Creating Dependent Variables

```python
#!/usr/bin/env python3
"""
Dependent variable creation and usage examples.
"""
from rmnpy import DependentVariable

def create_signal_variables():
    """Create variables for different types of signals."""
    
    print("=== Signal Variables ===")
    
    # Basic intensity variable
    intensity = DependentVariable.create(
        name="signal_intensity",
        description="Raw signal intensity",
        unit="arbitrary_units"
    )
    print(f"Intensity variable: {intensity}")
    
    # Complex signal components
    real_signal = DependentVariable.create(
        name="real_component",
        description="Real part of complex signal",
        unit="V"
    )
    
    imaginary_signal = DependentVariable.create(
        name="imaginary_component",
        description="Imaginary part of complex signal",
        unit="V"
    )
    
    print(f"Real signal: {real_signal}")
    print(f"Imaginary signal: {imaginary_signal}")
    
    return [intensity, real_signal, imaginary_signal]

def create_measurement_variables():
    """Create variables for different measurement types."""
    
    print("\n=== Measurement Variables ===")
    
    # Physical measurements
    temperature = DependentVariable.create(
        name="temperature",
        description="Sample temperature",
        unit="K"
    )
    
    pressure = DependentVariable.create(
        name="pressure", 
        description="Sample pressure",
        unit="Pa"
    )
    
    concentration = DependentVariable.create(
        name="concentration",
        description="Analyte concentration",
        unit="mol/L"
    )
    
    print(f"Temperature: {temperature}")
    print(f"Pressure: {pressure}")
    print(f"Concentration: {concentration}")
    
    return [temperature, pressure, concentration]

def inspect_variable_properties():
    """Demonstrate variable property access."""
    
    print("\n=== Variable Properties ===")
    
    var = DependentVariable.create(
        name="absorbance",
        description="UV-Vis absorbance measurement",
        unit="AU"
    )
    
    # Access properties
    name = var.name
    description = var.description
    unit = var.unit
    
    print(f"Variable name: {name}")
    print(f"Description: {description}")
    print(f"Unit: {unit}")

if __name__ == "__main__":
    signal_vars = create_signal_variables()
    measurement_vars = create_measurement_variables()
    inspect_variable_properties()
```

## Working with Data Points

### Creating and Managing Data Points

```python
#!/usr/bin/env python3
"""
Data point creation and manipulation examples.
"""
from rmnpy import Datum

def create_simple_data_points():
    """Create basic data points."""
    
    print("=== Simple Data Points ===")
    
    # Single data points
    data_points = []
    
    for i, value in enumerate([1.5, 2.3, 4.1, 3.7, 2.9], 1):
        datum = Datum.create(response_value=value)
        data_points.append(datum)
        print(f"Data point {i}: {datum}")
    
    return data_points

def create_measurement_series():
    """Create a series of related measurements."""
    
    print("\n=== Measurement Series ===")
    
    # Simulate NMR peak intensities
    peak_intensities = [0.1, 0.5, 1.0, 2.3, 4.1, 5.2, 3.8, 2.1, 0.8, 0.2]
    
    measurement_data = []
    
    for i, intensity in enumerate(peak_intensities):
        datum = Datum.create(response_value=intensity)
        measurement_data.append(datum)
        print(f"Measurement {i+1}: intensity = {intensity}")
    
    print(f"Total measurements: {len(measurement_data)}")
    return measurement_data

def demonstrate_data_point_usage():
    """Show practical data point usage patterns."""
    
    print("\n=== Data Point Usage Patterns ===")
    
    # Create data points for different experiments
    experiments = {
        "control": [1.2, 1.1, 1.3, 1.0, 1.2],
        "treatment_a": [2.1, 2.3, 2.0, 2.4, 2.2],
        "treatment_b": [3.5, 3.2, 3.8, 3.4, 3.6]
    }
    
    experiment_data = {}
    
    for exp_name, values in experiments.items():
        data_points = []
        for value in values:
            datum = Datum.create(response_value=value)
            data_points.append(datum)
        
        experiment_data[exp_name] = data_points
        print(f"Experiment '{exp_name}': {len(data_points)} data points")
    
    return experiment_data

if __name__ == "__main__":
    simple_data = create_simple_data_points()
    series_data = create_measurement_series()
    exp_data = demonstrate_data_point_usage()
```

## Complete Example: Building a Dataset

### Comprehensive Dataset Construction

```python
#!/usr/bin/env python3
"""
Complete example showing how to build a comprehensive dataset.
"""
from rmnpy import Dataset, Datum, Dimension, DependentVariable

def build_nmr_dataset():
    """Build a complete NMR dataset with all components."""
    
    print("=== Building Complete NMR Dataset ===")
    
    # 1. Create the main dataset
    dataset = Dataset.create(
        title="1H NMR Analysis of Benzene",
        description="400 MHz 1H NMR spectrum in CDCl3 at 298K"
    )
    print(f"1. Dataset created: {dataset}")
    
    # 2. Create chemical shift dimension
    chemical_shift = Dimension.create_linear(
        label="chemical_shift",
        description="1H chemical shift axis",
        count=512,
        start=10.0,
        increment=-0.02,
        unit="ppm"
    )
    print(f"2. Chemical shift dimension: {chemical_shift}")
    
    # 3. Create signal intensity variable
    intensity = DependentVariable.create(
        name="signal_intensity",
        description="NMR signal intensity",
        unit="arbitrary_units"
    )
    print(f"3. Intensity variable: {intensity}")
    
    # 4. Create some representative data points
    # Simulate benzene peak at ~7.3 ppm
    peak_data = []
    for i in range(5):
        # Create data points around the benzene peak
        datum = Datum.create(response_value=1.0 + i * 0.2)
        peak_data.append(datum)
    
    print(f"4. Created {len(peak_data)} data points")
    
    return {
        'dataset': dataset,
        'dimension': chemical_shift,
        'variable': intensity,
        'data': peak_data
    }

def build_2d_nmr_dataset():
    """Build a 2D NMR dataset."""
    
    print("\n=== Building 2D NMR Dataset ===")
    
    # Main dataset
    dataset = Dataset.create(
        title="2D COSY Experiment", 
        description="1H-1H correlation spectroscopy"
    )
    
    # F1 dimension
    f1_dim = Dimension.create_linear(
        label="f1_frequency",
        description="First frequency dimension",
        count=128,
        unit="Hz"
    )
    
    # F2 dimension
    f2_dim = Dimension.create_linear(
        label="f2_frequency",
        description="Second frequency dimension",
        count=256,
        unit="Hz"
    )
    
    # Real and imaginary components
    real_var = DependentVariable.create(
        name="real_signal",
        description="Real component of 2D signal",
        unit="arbitrary_units"
    )
    
    imag_var = DependentVariable.create(
        name="imaginary_signal",
        description="Imaginary component of 2D signal", 
        unit="arbitrary_units"
    )
    
    print(f"2D Dataset: {dataset}")
    print(f"F1 dimension: {f1_dim}")
    print(f"F2 dimension: {f2_dim}")
    print(f"Real variable: {real_var}")
    print(f"Imaginary variable: {imag_var}")
    
    return {
        'dataset': dataset,
        'f1_dimension': f1_dim,
        'f2_dimension': f2_dim,
        'real_variable': real_var,
        'imaginary_variable': imag_var
    }

def demonstrate_error_handling():
    """Show proper error handling techniques."""
    
    print("\n=== Error Handling Example ===")
    
    from rmnpy.exceptions import RMNLibError, RMNLibMemoryError
    
    try:
        # Normal operations
        dataset = Dataset.create(title="Error Handling Test")
        dimension = Dimension.create_linear(label="test", count=100)
        variable = DependentVariable.create(name="test_var")
        datum = Datum.create(response_value=42.0)
        
        print("✓ All objects created successfully")
        
        # Access properties
        title = dataset.title
        label = dimension.label
        name = variable.name
        
        print(f"✓ Properties accessed: dataset='{title}', dim='{label}', var='{name}'")
        
    except RMNLibMemoryError as e:
        print(f"✗ Memory error: {e}")
        
    except RMNLibError as e:
        print(f"✗ RMNLib error: {e}")
        
    except Exception as e:
        print(f"✗ Unexpected error: {e}")

if __name__ == "__main__":
    # Build example datasets
    nmr_1d = build_nmr_dataset()
    nmr_2d = build_2d_nmr_dataset()
    
    # Demonstrate error handling
    demonstrate_error_handling()
    
    print("\n🎉 Example completed successfully!")
    print("All RMNpy components working together.")
```

## Running the Examples

Save any of these examples as `.py` files and run them:

```bash
# Save the installation verification example
python installation_test.py

# Save and run the dataset example
python dataset_example.py

# Save and run the comprehensive example
python complete_example.py
```

## Next Steps

These basic examples show the fundamental patterns for using RMNpy. For more advanced usage, see:

- **NMR Spectroscopy Examples** (coming soon)
- **Data Analysis Examples** (coming soon)
- [User Guide](../user_guide/index.md)
