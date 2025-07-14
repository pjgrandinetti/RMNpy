"""
Installation and Basic Usage
============================

This example demonstrates how to verify your RMNpy installation and use the basic functionality.

Prerequisites
-------------
- Python 3.8 or later  
- RMNpy installed (see installation guide)
"""

# %%
# Installation Verification
# -------------------------
# 
# Let's start by verifying that RMNpy is properly installed:

import sys
print(f"Python version: {sys.version}")

try:
    import rmnpy
    print(f"✓ RMNpy imported successfully")
    print(f"✓ RMNpy version: {rmnpy.__version__}")
except ImportError as e:
    print(f"✗ Import failed: {e}")
    print("Please check your RMNpy installation")

# %%
# Core Classes Import
# -------------------
#
# RMNpy provides several core classes for scientific data handling:

from rmnpy import Dataset, Datum, Dimension, DependentVariable
from rmnpy.exceptions import RMNLibError, RMNLibMemoryError

print("✓ Core classes imported successfully:")
print(f"  - Dataset: {Dataset}")
print(f"  - Datum: {Datum}")
print(f"  - Dimension: {Dimension}")
print(f"  - DependentVariable: {DependentVariable}")
print("✓ Exception classes imported successfully")

# %%
# Creating Your First Dataset
# ----------------------------
#
# A ``Dataset`` is the primary container for scientific data in RMNpy:

# Create a simple dataset
dataset = Dataset.create(
    title="My First Dataset",
    description="Learning RMNpy basics"
)

print(f"Dataset created: {dataset}")
print(f"Title: {dataset.title}")
print(f"Description: {dataset.description}")

# %%
# Working with Dimensions
# -----------------------
#
# Dimensions define the coordinate axes for your data:

# Create a linear dimension (e.g., frequency axis)
frequency_dim = Dimension.create_linear(
    label="frequency",
    description="NMR frequency axis",
    count=256,
    start=0.0,
    increment=10.0,
    unit="Hz"
)

print(f"Dimension created: {frequency_dim}")
print(f"Label: {frequency_dim.label}")
print(f"Count: {frequency_dim.count}")
print(f"Type: {frequency_dim.type}")

# %%
# Creating Dependent Variables
# ----------------------------
#
# Dependent variables represent the measured quantities:

# Create a signal intensity variable
intensity = DependentVariable.create(
    name="signal_intensity",
    description="NMR signal intensity",
    unit="arbitrary_units"
)

print(f"Variable created: {intensity}")
print(f"Name: {intensity.name}")
print(f"Description: {intensity.description}")
print(f"Unit: {intensity.unit}")

# %%
# Working with Data Points
# ------------------------
#
# Individual data points are represented by ``Datum`` objects:

# Create individual data points
data_points = []
values = [1.0, 2.5, 4.1, 3.2, 1.8]

for i, value in enumerate(values):
    datum = Datum.create(response_value=value)
    data_points.append(datum)
    print(f"Data point {i+1}: {datum} (value={value})")

print(f"\nCreated {len(data_points)} data points")

# %%
# Error Handling
# --------------
#
# Proper error handling is important when working with RMNpy:

def safe_dataset_creation(title, description=None):
    """Safely create a dataset with error handling."""
    try:
        dataset = Dataset.create(title=title, description=description)
        print(f"✓ Successfully created dataset: {dataset}")
        return dataset
        
    except RMNLibMemoryError as e:
        print(f"✗ Memory error: {e}")
        return None
        
    except RMNLibError as e:
        print(f"✗ RMNLib error: {e}")
        return None
        
    except Exception as e:
        print(f"✗ Unexpected error: {e}")
        return None

# Test error handling
test_dataset = safe_dataset_creation("Error Handling Test", "Demonstrating safe dataset creation")

# %%
# Putting It All Together
# -----------------------
#
# Let's create a complete example combining all the elements:

def create_complete_example():
    """Create a complete dataset with all components."""
    
    print("=== Creating Complete Example ===")
    
    # 1. Create main dataset
    dataset = Dataset.create(
        title="Complete Example Dataset",
        description="Demonstration of all RMNpy basic components"
    )
    print(f"1. Dataset: {dataset}")
    
    # 2. Create dimension
    time_dim = Dimension.create_linear(
        label="time",
        description="Time axis",
        count=10,
        start=0.0,
        increment=0.1,
        unit="s"
    )
    print(f"2. Dimension: {time_dim}")
    
    # 3. Create variable
    signal = DependentVariable.create(
        name="amplitude",
        description="Signal amplitude",
        unit="V"
    )
    print(f"3. Variable: {signal}")
    
    # 4. Create data points
    import math
    data_points = []
    for i in range(10):
        # Create a sine wave
        value = math.sin(2 * math.pi * i / 10)
        datum = Datum.create(response_value=value)
        data_points.append(datum)
    
    print(f"4. Created {len(data_points)} data points")
    
    return {
        'dataset': dataset,
        'dimension': time_dim,
        'variable': signal,
        'data': data_points
    }

# Create the complete example
example = create_complete_example()

print("\n🎉 Complete example created successfully!")
print(f"Dataset title: {example['dataset'].title}")
print(f"Dimension label: {example['dimension'].label}")
print(f"Variable name: {example['variable'].name}")
print(f"Number of data points: {len(example['data'])}")

# %%
# Summary
# -------
#
# In this example, you learned:
#
# 1. **Installation verification** - How to check if RMNpy is properly installed
# 2. **Core classes** - Dataset, Dimension, DependentVariable, and Datum
# 3. **Basic operations** - Creating and inspecting objects
# 4. **Error handling** - Proper exception handling with RMNpy
# 5. **Complete example** - Putting all components together
#
# Next Steps
# ----------
#
# - Try the NMR Spectroscopy Examples
# - Explore Advanced Data Manipulation  
# - Read the User Guide for detailed documentation
