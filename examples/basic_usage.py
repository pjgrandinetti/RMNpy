"""Basic usage examples for RMNpy - demonstrating scientific workflows."""

import numpy as np
import rmnpy
from rmnpy import Dataset, Datum, Dimension, DependentVariable
from rmnpy.exceptions import RMNError
from rmnpy.sitypes import kSIQuantityTime, kSIQuantityFrequency, kSIQuantityElectricPotential


def example_complex_nmr_data():
    """Demonstrate complex NMR data generation matching RMNLib examples."""
    print("=== Complex NMR Data Example ===")
    
    try:
        # Generate damped complex oscillation data (typical NMR/ESR experiment)
        # This matches the RMNLib C API example
        count = 1024
        frequency = 100.0    # Hz
        decay_rate = 50.0    # s⁻¹ (decay constant)
        
        print(f"Generating {count} points of complex NMR data...")
        print(f"Frequency: {frequency} Hz, Decay rate: {decay_rate} s⁻¹")
        
        # Generate time axis and complex oscillating data
        time_axis = np.arange(count) * 1.0e-6  # 1 µs sampling interval
        amplitude = np.exp(-decay_rate * time_axis)
        phase = 2.0 * np.pi * frequency * time_axis
        complex_data = amplitude * (np.cos(phase) + 1j * np.sin(phase))
        
        print(f"Generated complex data with shape: {complex_data.shape}")
        print(f"Data type: {complex_data.dtype}")
        print(f"Max amplitude: {np.max(np.abs(complex_data)):.3f}")
        print(f"Final amplitude: {np.abs(complex_data[-1]):.6f}")
        
        # Create time dimension with proper physical quantities
        time_dim = Dimension.create_linear(
            label="time",
            count=count,
            increment="1.0 µs",           # String expression like C API
            quantity_name=kSIQuantityTime,   # Explicit quantity name
            description="Time axis for NMR acquisition"
        )
        
        # Create dependent variable for complex NMR signal
        signal_var = DependentVariable.create(
            data=complex_data,
            name="nmr_signal",
            description="Complex NMR signal with T2 decay",
            units="V",  # Voltage units
            quantity_name=kSIQuantityElectricPotential,  # Required for C API
            quantity_type="scalar",  # Required for C API
            element_type="complex128"  # Match C API kOCNumberComplex128Type
        )
        
        # Create complete dataset
        dataset = Dataset.create(
            title="Complex NMR Experiment",
            description="Damped oscillation typical of NMR/ESR spectroscopy",
            dimensions=[time_dim],
            dependent_variables=[signal_var]
        )
        
        print(f"✓ Created dataset: {dataset.title}")
        print(f"✓ Dimensions: {len(dataset.dimensions)}")
        print(f"✓ Dependent variables: {len(dataset.dependent_variables)}")
        
        return dataset
        
    except RMNError as e:
        print(f"RMN Error: {e}")
        return None
    except Exception as e:
        print(f"Unexpected error: {e}")
        return None


def example_t1_inversion_recovery():
    """Demonstrate T1 inversion recovery experiment matching RMNLib."""
    print("\n=== T1 Inversion Recovery Example ===")
    
    try:
        # T1 inversion recovery with non-uniform time spacing (6 orders of magnitude)
        # This matches the RMNLib monotonic dimension example
        recovery_times = [
            "10.0 µs", "50.0 µs", "100.0 µs", "500.0 µs",
            "1.0 ms", "5.0 ms", "10.0 ms", "50.0 ms", 
            "100.0 ms", "500.0 ms", "1.0 s", "5.0 s", "10.0 s"
        ]
        
        print(f"Creating T1 recovery experiment with {len(recovery_times)} time points")
        print(f"Time range: {recovery_times[0]} to {recovery_times[-1]} (6 orders of magnitude)")
        
        # Simulate T1 recovery magnetization data
        # M(t) = M0 * (1 - 2 * exp(-t/T1))
        M0 = 1.0           # Equilibrium magnetization
        T1_seconds = 0.5   # T1 relaxation time: 500 ms
        
        # Convert time strings to seconds for calculation
        time_values = []
        magnetization = []
        
        for time_str in recovery_times:
            # Simple parsing - in real implementation would use SIScalar
            if "µs" in time_str:
                t_sec = float(time_str.replace(" µs", "")) * 1e-6
            elif "ms" in time_str:
                t_sec = float(time_str.replace(" ms", "")) * 1e-3
            elif "s" in time_str:
                t_sec = float(time_str.replace(" s", ""))
            
            time_values.append(t_sec)
            # T1 inversion recovery equation
            mag = M0 * (1.0 - 2.0 * np.exp(-t_sec / T1_seconds))
            magnetization.append(mag)
        
        magnetization = np.array(magnetization)
        
        print(f"T1 relaxation time: {T1_seconds * 1000:.1f} ms")
        print(f"Magnetization range: {np.min(magnetization):.3f} to {np.max(magnetization):.3f}")
        
        # Create monotonic time dimension
        t1_recovery_dim = Dimension.create_monotonic(
            coordinates=recovery_times,
            label="recovery_time", 
            quantity_name=kSIQuantityTime,
            description="T1 inversion recovery time points"
        )
        
        # Create magnetization dependent variable
        magnetization_var = DependentVariable.create(
            data=magnetization,
            name="magnetization",
            description="Longitudinal magnetization recovery",
            units="dimensionless",  # Normalized magnetization  
            quantity_name=kSIQuantityElectricPotential,  # Using electric potential as default
            quantity_type="scalar",  # Required for C API
            element_type="float64"  # Required for C API
        )
        
        # Create T1 dataset
        t1_dataset = Dataset.create(
            title="T1 Inversion Recovery",
            description="Longitudinal relaxation time measurement",
            dimensions=[t1_recovery_dim],
            dependent_variables=[magnetization_var]
        )
        
        print(f"✓ Created T1 dataset: {t1_dataset.title}")
        
        return t1_dataset
        
    except RMNError as e:
        print(f"RMN Error: {e}")
        return None
    except Exception as e:
        print(f"Unexpected error: {e}")
        return None

def example_dataset_operations():
    """Demonstrate basic dataset operations and properties."""
    print("\n=== Dataset Operations Example ===")
    
    try:
        # Create multiple datasets with different properties
        datasets = []
        
        # Simple dataset
        simple_dataset = Dataset.create(
            title="Simple Dataset",
            description="Basic dataset for testing operations"
        )
        datasets.append(simple_dataset)
        
        # Dataset with metadata
        metadata_dataset = Dataset.create(
            title="Metadata Dataset", 
            description="Dataset with additional metadata properties"
        )
        datasets.append(metadata_dataset)
        
        print(f"Created {len(datasets)} datasets")
        
        # Display dataset properties
        for i, dataset in enumerate(datasets, 1):
            print(f"Dataset {i}: {dataset.title}")
            print(f"  Description: {dataset.description}")
            print(f"  Dimensions: {len(dataset.dimensions)}")
            print(f"  Dependent variables: {len(dataset.dependent_variables)}")
        
    except RMNError as e:
        print(f"RMN Error: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")


def example_error_handling():
    """Demonstrate error handling with scientific data."""
    print("\n=== Error Handling Example ===")
    
    try:
        # This should work - create valid scientific dataset
        dataset = Dataset.create(
            title="Error Handling Test",
            description="Testing proper error handling with scientific data"
        )
        print("✓ Dataset creation succeeded")
        
        # Try to access properties safely
        print(f"✓ Dataset title: {dataset.title}")
        print(f"✓ Dataset has {len(dataset.dimensions)} dimensions")
        print(f"✓ Dataset has {len(dataset.dependent_variables)} dependent variables")
        
    except rmnpy.RMNLibraryError as e:
        print(f"RMNLib Error: {e}")
    except rmnpy.RMNMemoryError as e:
        print(f"Memory Error: {e}")
    except rmnpy.RMNError as e:
        print(f"General RMN Error: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")


def example_numpy_integration():
    """Demonstrate NumPy data integration with scientific workflows."""
    print("\n=== NumPy Integration Example ===")
    
    try:
        print("Creating scientific data with NumPy...")
        
        # 1D frequency domain data (typical NMR spectrum)
        frequency_points = 2048
        chemical_shift_range = np.linspace(-10, 10, frequency_points)  # ppm
        # Simulate Lorentzian peak at 7.26 ppm (CHCl3)
        peak_position = 7.26  # ppm
        linewidth = 0.1       # ppm
        spectrum_1d = 1.0 / (1.0 + ((chemical_shift_range - peak_position) / linewidth)**2)
        print(f"Created 1D NMR spectrum with {len(spectrum_1d)} points")
        
        # 2D time-domain data (typical for 2D NMR)
        t1_points, t2_points = 64, 512
        data_2d = np.random.random((t1_points, t2_points)) * 0.1  # Add noise
        # Add some coherent signal
        t1_axis = np.arange(t1_points) * 0.001  # ms
        t2_axis = np.arange(t2_points) * 0.0001 # ms
        T1, T2 = np.meshgrid(t1_axis, t2_axis, indexing='ij')
        coherent_signal = np.exp(-T1/50.0 - T2/10.0) * np.cos(2*np.pi*100*T2)  # Damped oscillation
        data_2d += coherent_signal * 0.5
        print(f"Created 2D time-domain data with shape {data_2d.shape}")
        
        # Complex data (typical for NMR)
        complex_data = spectrum_1d + 1j * np.roll(spectrum_1d, 10)  # Add imaginary component
        print(f"Created complex spectrum with {len(complex_data)} elements")
        
        # For now, create basic dependent variables (full data setting to be implemented)
        spectrum_dv = DependentVariable.create(
            data=complex_data,
            name="nmr_spectrum",
            description="1D NMR spectrum",
            units="intensity",
            quantity_name=kSIQuantityElectricPotential,  # Required for C API
            quantity_type="scalar",  # Required for C API
            element_type="complex128"  # Match complex data
        )
        print("✓ Created 1D spectrum dependent variable")
        
        data_2d_dv = DependentVariable.create(
            data=data_2d,
            name="2d_nmr_data", 
            description="2D NMR time-domain data",
            units="intensity",
            quantity_name=kSIQuantityElectricPotential,  # Required for C API
            quantity_type="scalar",  # Required for C API
            element_type="float64"  # Match 2D data type
        )
        print("✓ Created 2D data dependent variable")
        
    except Exception as e:
        print(f"Error: {e}")


def main():
    """Run all scientific examples."""
    print("RMNpy Scientific Examples")
    print("=========================")
    print("Demonstrating consistency with RMNLib C API examples")
    
    # Run the scientific examples
    nmr_dataset = example_complex_nmr_data()
    t1_dataset = example_t1_inversion_recovery()
    
    # Run basic operations examples  
    example_dataset_operations()
    example_error_handling()  
    example_numpy_integration()
    
    print("\n=== Examples Complete ===")
    if nmr_dataset:
        print(f"✓ Created complex NMR dataset: {nmr_dataset.title}")
    if t1_dataset:
        print(f"✓ Created T1 recovery dataset: {t1_dataset.title}")
    print("✓ All examples demonstrate scientific workflows matching RMNLib")
    print("Note: These examples now align with RMNLib C API patterns and complexity.")


if __name__ == "__main__":
    main()
