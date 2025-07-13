"""Basic usage examples for RMNpy."""

import numpy as np
import rmnpy
from rmnpy import Dataset, Datum
from rmnpy.exceptions import RMNError


def example_basic_usage():
    """Demonstrate basic Dataset and Datum creation."""
    print("=== Basic Usage Example ===")
    
    try:
        # Create a simple dataset
        print("Creating a new dataset...")
        dataset = Dataset.create()
        print(f"Created dataset with {dataset.num_datums} datums")
        
        # Create some test data
        print("\nCreating datum with test data...")
        test_data = np.array([1.0, 2.0, 3.0, 4.0, 5.0], dtype=np.float64)
        datum = Datum.create()
        
        print(f"Created datum with {len(test_data)} data points")
        
    except RMNError as e:
        print(f"RMN Error: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")


def example_dataset_operations():
    """Demonstrate dataset operations."""
    print("\n=== Dataset Operations Example ===")
    
    try:
        # Create multiple datasets
        datasets = []
        for i in range(3):
            dataset = Dataset.create()
            datasets.append(dataset)
            print(f"Created dataset {i+1}")
        
        print(f"\nTotal datasets created: {len(datasets)}")
        
        # Clean up explicitly (though __del__ will handle this)
        for i, dataset in enumerate(datasets):
            print(f"Dataset {i+1} has {dataset.num_datums} datums")
        
    except RMNError as e:
        print(f"RMN Error: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")


def example_error_handling():
    """Demonstrate error handling."""
    print("\n=== Error Handling Example ===")
    
    try:
        # This should work
        dataset = Dataset.create()
        print("✓ Dataset creation succeeded")
        
        # Try to access properties
        print(f"✓ Dataset has {dataset.num_datums} datums")
        
    except rmnpy.RMNLibraryError as e:
        print(f"RMNLib Error: {e}")
    except rmnpy.RMNMemoryError as e:
        print(f"Memory Error: {e}")
    except rmnpy.RMNError as e:
        print(f"General RMN Error: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")


def example_numpy_integration():
    """Demonstrate NumPy data integration."""
    print("\n=== NumPy Integration Example ===")
    
    try:
        # Create test data with NumPy
        print("Creating NumPy test data...")
        
        # 1D array
        data_1d = np.linspace(0, 10, 100)
        print(f"Created 1D array with {len(data_1d)} points")
        
        # 2D array  
        data_2d = np.random.random((10, 20))
        print(f"Created 2D array with shape {data_2d.shape}")
        
        # Complex data
        complex_data = np.array([1+2j, 3+4j, 5+6j])
        print(f"Created complex array with {len(complex_data)} elements")
        
        # For now, just create empty datums (we'll add data setting later)
        datum = Datum.create()
        print("✓ Created datum (data setting to be implemented)")
        
    except Exception as e:
        print(f"Error: {e}")


def main():
    """Run all examples."""
    print("RMNpy Examples")
    print("==============")
    
    example_basic_usage()
    example_dataset_operations()
    example_error_handling()  
    example_numpy_integration()
    
    print("\n=== Examples Complete ===")
    print("Note: Some functionality is still being implemented.")


if __name__ == "__main__":
    main()
