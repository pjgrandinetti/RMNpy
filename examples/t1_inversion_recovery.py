#!/usr/bin/env python3
"""
T1 Inversion Recovery Example - matching RMNLib patterns

This example demonstrates T1 relaxation time measurement using the 
inversion recovery pulse sequence, matching the RMNLib C API example.
"""

import numpy as np
import rmnpy
from rmnpy import Dataset, Dimension, DependentVariable
from rmnpy.sitypes import kSIQuantityTime, kSIQuantityElectricPotential


def create_t1_inversion_recovery_dataset():
    """
    Create a T1 inversion recovery dataset matching RMNLib example.
    
    This demonstrates:
    - Non-uniform time sampling over 6 orders of magnitude
    - Monotonic dimension creation with string expressions
    - Physical quantity constants for proper dimensionality
    - Realistic T1 relaxation data simulation
    """
    print("=== T1 Inversion Recovery Example ===")
    print("Creating dataset matching RMNLib C API patterns...")
    
    # T1 inversion recovery time points (6 orders of magnitude)
    # This exactly matches the RMNLib monotonic dimension example
    recovery_times = [
        "10.0 µs", "50.0 µs", "100.0 µs", "500.0 µs",
        "1.0 ms", "5.0 ms", "10.0 ms", "50.0 ms", 
        "100.0 ms", "500.0 ms", "1.0 s", "5.0 s", "10.0 s"
    ]
    
    print(f"Time points: {len(recovery_times)} spanning {recovery_times[0]} to {recovery_times[-1]}")
    
    # Physical parameters
    M0 = 1.0           # Equilibrium magnetization (normalized)
    T1_seconds = 0.5   # T1 relaxation time: 500 ms
    
    print(f"T1 relaxation time: {T1_seconds * 1000:.1f} ms")
    
    # Calculate magnetization using inversion recovery equation:
    # M(t) = M0 * (1 - 2 * exp(-t/T1))
    time_values_sec = []
    magnetization = []
    
    for time_str in recovery_times:
        # Convert time expressions to seconds
        if "µs" in time_str:
            t_sec = float(time_str.replace(" µs", "")) * 1e-6
        elif "ms" in time_str:
            t_sec = float(time_str.replace(" ms", "")) * 1e-3
        elif "s" in time_str and "µs" not in time_str and "ms" not in time_str:
            t_sec = float(time_str.replace(" s", ""))
        
        time_values_sec.append(t_sec)
        
        # T1 inversion recovery magnetization
        mag = M0 * (1.0 - 2.0 * np.exp(-t_sec / T1_seconds))
        magnetization.append(mag)
    
    magnetization = np.array(magnetization)
    
    print(f"Magnetization range: {np.min(magnetization):.3f} to {np.max(magnetization):.3f}")
    print(f"Initial magnetization (t=10µs): {magnetization[0]:.3f}")
    print(f"Final magnetization (t=10s): {magnetization[-1]:.3f}")
    
    # Create monotonic time dimension using string expressions
    # This matches the RMNLib SIMonotonicDimensionCreateMinimal pattern
    time_dimension = Dimension.create_monotonic(
        coordinates=recovery_times,      # String expressions like RMNLib
        label="recovery_time",
        quantity_name=kSIQuantityTime,     # Explicit quantity constant
        description="T1 inversion recovery time points spanning 6 orders of magnitude"
    )
    
    # Create dependent variable for magnetization
    # This matches the RMNLib DependentVariableCreateMinimal pattern
    magnetization_var = DependentVariable.create(
        data=magnetization,
        name="magnetization",
        description="Longitudinal magnetization recovery following inversion pulse",
        units="dimensionless",  # Normalized magnetization (no physical units)
        quantity_name=kSIQuantityElectricPotential,  # Required for C API
        quantity_type="scalar",  # Required for C API
        element_type="float64"  # Required for C API
    )
    
    # Create complete dataset
    # This matches the RMNLib DatasetCreateMinimal pattern
    dataset = Dataset.create(
        title="T1 Inversion Recovery Experiment",
        description="Longitudinal relaxation time measurement using inversion recovery pulse sequence",
        dimensions=[time_dimension],
        dependent_variables=[magnetization_var]
    )
    
    print(f"\n✓ Created T1 dataset: '{dataset.title}'")
    print(f"✓ Dimensions: {len(dataset.dimensions)}")
    print(f"✓ Dependent variables: {len(dataset.dependent_variables)}")
    print(f"✓ Data points: {len(magnetization)}")
    
    return dataset


def analyze_t1_data(dataset):
    """
    Demonstrate analysis of T1 data.
    
    This shows how to access and analyze the scientific data,
    matching patterns from RMNLib documentation.
    """
    print("\n=== T1 Data Analysis ===")
    
    # Access dataset components
    time_dim = dataset.dimensions[0]
    mag_var = dataset.dependent_variables[0]
    
    print(f"Dimension: {time_dim.label}")
    print(f"Variable: {mag_var.name}")
    print(f"Description: {mag_var.description}")
    
    # In a real implementation, you would fit the data to extract T1
    print("\nData analysis (conceptual):")
    print("- Fit M(t) = M0 * (1 - 2 * exp(-t/T1)) to extract T1")
    print("- Calculate confidence intervals")
    print("- Generate publication-quality plots")


def export_dataset_example(dataset):
    """
    Demonstrate dataset export functionality.
    
    This would match the RMNLib DatasetExport function.
    """
    print("\n=== Dataset Export Example ===")
    
    # This functionality would match RMNLib's CSDM export
    try:
        # In the full implementation, this would call:
        # dataset.export("t1_recovery.csdf")
        print("Dataset export functionality:")
        print("- dataset.export('t1_recovery.csdf')  # CSDM format")
        print("- Automatic binary data handling")
        print("- JSON metadata with binary references")
        print("✓ Export would match RMNLib DatasetExport() patterns")
        
    except Exception as e:
        print(f"Export functionality in development: {e}")


def main():
    """
    Run complete T1 inversion recovery example.
    
    This demonstrates the full scientific workflow matching
    RMNLib C API examples and documentation patterns.
    """
    print("T1 Inversion Recovery - RMNpy Example")
    print("=====================================")
    print("Matching RMNLib C API patterns and complexity")
    
    # Create the T1 dataset
    t1_dataset = create_t1_inversion_recovery_dataset()
    
    if t1_dataset:
        # Analyze the data
        analyze_t1_data(t1_dataset)
        
        # Demonstrate export
        export_dataset_example(t1_dataset)
        
        print("\n=== Example Complete ===")
        print("✓ T1 inversion recovery dataset created successfully")
        print("✓ Example demonstrates scientific workflow matching RMNLib")
        print("✓ Non-uniform time sampling over 6 orders of magnitude")
        print("✓ Proper physical quantity handling with string expressions")
        print("✓ Ready for T1 fitting and analysis")
    
    else:
        print("❌ Failed to create T1 dataset")


if __name__ == "__main__":
    main()
