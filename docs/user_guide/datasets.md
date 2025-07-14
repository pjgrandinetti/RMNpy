# Working with Datasets

The `Dataset` class is the central component of RMNpy, representing complete scientific datasets with metadata, dimensions, and data variables.

## Creating Datasets

### Basic Dataset Creation

```python
from rmnpy import Dataset

# Create an empty dataset
dataset = Dataset.create()
print(f"Empty dataset: {dataset}")

# Create dataset with title
dataset = Dataset.create(title="My Experiment")
print(f"Titled dataset: {dataset}")

# Create dataset with full metadata
dataset = Dataset.create(
    title="1H NMR Spectrum",
    description="Benzene in CDCl3 at 298K"
)
print(f"Full dataset: {dataset}")
```

### Dataset Properties

```python
# Access dataset properties
dataset = Dataset.create(
    title="NMR Analysis", 
    description="Detailed spectroscopic analysis"
)

# Check properties
title = dataset.title
description = dataset.description

print(f"Title: {title}")
print(f"Description: {description}")

# Properties may be None if not set
if title is not None:
    print(f"Dataset is titled: {title}")
else:
    print("Dataset has no title")
```

## Dataset Types and Applications

### NMR Spectroscopy Datasets

```python
# 1D NMR spectrum
nmr_1d = Dataset.create(
    title="1H NMR Spectrum", 
    description="1H NMR of benzene in CDCl3, 400 MHz"
)

# 2D NMR spectrum  
nmr_2d = Dataset.create(
    title="2D COSY Spectrum",
    description="1H-1H correlation spectroscopy"
)

# 13C NMR spectrum
carbon_nmr = Dataset.create(
    title="13C NMR Spectrum",
    description="13C NMR with proton decoupling"
)
```

### Mass Spectrometry Datasets

```python
# Mass spectrum
mass_spec = Dataset.create(
    title="ESI-MS Spectrum",
    description="Electrospray ionization mass spectrum"
)

# MS/MS fragmentation
msms = Dataset.create(
    title="MS/MS Fragmentation",
    description="Collision-induced dissociation spectrum"
)
```

### Time-Series Data

```python
# Kinetic experiment
kinetics = Dataset.create(
    title="Reaction Kinetics",
    description="Time-resolved spectroscopic monitoring"
)

# Dynamic experiment
dynamics = Dataset.create(
    title="Dynamic NMR",
    description="Variable temperature NMR study"
)
```

## Dataset String Representation

```python
dataset = Dataset.create(
    title="Sample Analysis",
    description="Comprehensive spectroscopic characterization"
)

# String representations
print(str(dataset))    # Human-readable format
print(repr(dataset))   # Developer format

# Custom formatting
print(f"Dataset: {dataset}")
```

## Multiple Dataset Management

```python
# Create multiple datasets for comparison
datasets = []

# Create several related datasets
for i, sample in enumerate(["benzene", "toluene", "xylene"], 1):
    dataset = Dataset.create(
        title=f"Sample {i}: {sample}",
        description=f"1H NMR analysis of {sample}"
    )
    datasets.append(dataset)

# Display all datasets
for i, dataset in enumerate(datasets):
    print(f"Dataset {i+1}: {dataset}")
```

## Dataset Lifecycle

### Creation and Initialization

```python
# Step 1: Create dataset
dataset = Dataset.create(title="New Experiment")

# Step 2: Add metadata (planned feature)
# dataset.add_metadata("instrument", "Bruker 400 MHz")
# dataset.add_metadata("temperature", "298 K")

# Step 3: Add dimensions (see Dimensions guide)
# Step 4: Add dependent variables (see Dependent Variables guide)
# Step 5: Add data (see Data Points guide)
```

### Memory Management

```python
# Datasets are automatically managed
dataset = Dataset.create(title="Test")

# Memory is cleaned up when dataset goes out of scope
# No manual cleanup required in typical usage

# For long-running applications with many datasets:
import rmnpy
# ... create and use many datasets ...
rmnpy.shutdown()  # Clean up any remaining resources
```

## Common Dataset Patterns

### Experimental Series

```python
# Create datasets for a temperature series
temperatures = [273, 298, 323, 348]
temp_series = []

for temp in temperatures:
    dataset = Dataset.create(
        title=f"NMR at {temp}K",
        description=f"Variable temperature study at {temp} Kelvin"
    )
    temp_series.append(dataset)

print(f"Created {len(temp_series)} temperature datasets")
```

### Replicate Experiments

```python
# Multiple replicates of the same experiment
replicates = []

for rep in range(3):
    dataset = Dataset.create(
        title=f"Experiment Replicate {rep+1}",
        description="Independent experimental replicate"
    )
    replicates.append(dataset)

print(f"Created {len(replicates)} experimental replicates")
```

### Before/After Comparison

```python
# Before treatment
before = Dataset.create(
    title="Before Treatment",
    description="Baseline measurement before intervention"
)

# After treatment  
after = Dataset.create(
    title="After Treatment", 
    description="Measurement after intervention"
)

print(f"Before: {before}")
print(f"After: {after}")
```

## Advanced Dataset Features (Planned)

:::{note}
The following features are planned for future releases:

```python
# CSDM file I/O (planned)
# dataset = Dataset.load("spectrum.csdm")
# dataset.save("output.csdm")

# Metadata management (planned)
# dataset.set_metadata("acquisition_date", "2025-01-15")
# metadata = dataset.get_metadata()

# Dimension and variable attachment (planned)
# dataset.add_dimension(frequency_dim)
# dataset.add_dependent_variable(intensity_var)

# Data array operations (planned)
# dataset.set_data(numpy_array)
# data = dataset.get_data()
```
:::

## Error Handling with Datasets

```python
from rmnpy.exceptions import RMNLibError, RMNLibMemoryError

try:
    # Create dataset
    dataset = Dataset.create(title="Test Dataset")
    
    # Perform operations
    title = dataset.title
    
except RMNLibMemoryError as e:
    print(f"Memory error creating dataset: {e}")
    
except RMNLibError as e:
    print(f"Error with dataset: {e}")
```

## Best Practices

### Naming and Documentation

```python
# Good: Descriptive titles and descriptions
dataset = Dataset.create(
    title="1H NMR - Benzene in CDCl3",
    description="400 MHz 1H NMR spectrum, room temperature, 16 scans"
)

# Avoid: Vague or missing information
# dataset = Dataset.create(title="Test")  # Too vague
```

### Consistent Metadata

```python
# Use consistent naming conventions
datasets = [
    Dataset.create(
        title="Sample_001_1H_NMR",
        description="Sample 1: benzene derivative"
    ),
    Dataset.create(
        title="Sample_002_1H_NMR", 
        description="Sample 2: toluene derivative"
    ),
    Dataset.create(
        title="Sample_003_1H_NMR",
        description="Sample 3: xylene derivative"
    )
]
```

### Resource Management

```python
# For applications creating many datasets
def process_samples(sample_list):
    """Process multiple samples efficiently."""
    results = []
    
    for sample in sample_list:
        # Create dataset
        dataset = Dataset.create(
            title=f"Analysis of {sample}",
            description=f"Spectroscopic analysis"
        )
        
        # Process dataset
        # ... add your processing code ...
        
        results.append(dataset)
    
    return results

# Use the function
samples = ["benzene", "toluene", "xylene"]
datasets = process_samples(samples)
print(f"Processed {len(datasets)} samples")
```

## Next Steps

- Learn about **Dimensions** (coming soon) to add coordinate axes to your datasets
- Explore **Dependent Variables** (coming soon) for data variable management
- See **Data Points** (coming soon) for working with individual measurements
- Check [Examples](../examples/index.md) for real-world use cases
