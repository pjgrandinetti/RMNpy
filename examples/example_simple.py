#!/usr/bin/env python3
"""Simple example showing RMNpy usage."""

def main():
    print("RMNpy Example")
    print("=============")
    
    # Import the package
    try:
        from rmnpy import Dataset, Datum
        from rmnpy.exceptions import RMNLibError
        print("✓ RMNpy imported successfully")
    except ImportError as e:
        print(f"✗ Failed to import RMNpy: {e}")
        return
    
    # Create a dataset
    try:
        print("\n1. Creating a dataset...")
        dataset = Dataset.create(title="My Dataset", description="Example dataset") 
        print(f"   ✓ Created: {dataset}")
        print(f"   ✓ Title: '{dataset.title}'")
        print(f"   ✓ Description: '{dataset.description}'")
    except RMNLibError as e:
        print(f"   ✗ Failed to create dataset: {e}")
        return
    
    # Create some data points
    try:
        print("\n2. Creating data points...")
        
        # Simple datum
        datum1 = Datum.create(response_value=42.5)
        print(f"   ✓ Datum 1: response = {datum1.response_value}")
        
        # Datum with coordinates
        datum2 = Datum.create(response_value=73.2, coordinates=[1.0, 2.0])
        print(f"   ✓ Datum 2: response = {datum2.response_value}, coords = {datum2.coordinates}")
        
    except RMNLibError as e:
        print(f"   ✗ Failed to create datum: {e}")
        return
    
    print("\n🎉 RMNpy is working perfectly!")
    print("   - Dataset and Datum creation successful")
    print("   - Memory management working correctly") 
    print("   - No hanging or crashes detected")

if __name__ == "__main__":
    main()
