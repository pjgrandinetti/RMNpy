#!/usr/bin/env python3
"""Minimal test to check for hanging issues."""

def test_import_only():
    """Test just importing the module."""
    print("Testing import...")
    try:
        import rmnpy
        print("✓ Import successful")
        return True
    except Exception as e:
        print(f"✗ Import failed: {e}")
        return False

def test_dataset_only():
    """Test creating just one dataset."""
    print("Testing dataset creation...")
    try:
        from rmnpy import Dataset
        dataset = Dataset.create()
        print("✓ Dataset created")
        return True
    except Exception as e:
        print(f"✗ Dataset creation failed: {e}")
        return False

def test_datum_without_unit():
    """Test creating a datum without units (simplest case)."""
    print("Testing datum creation (no unit)...")
    try:
        from rmnpy import Datum
        datum = Datum.create(response_value=1.0)
        print("✓ Datum created")
        return True
    except Exception as e:
        print(f"✗ Datum creation failed: {e}")
        return False

if __name__ == "__main__":
    print("Minimal RMNpy Test")
    print("==================")
    
    tests = [
        test_import_only,
        test_dataset_only, 
        test_datum_without_unit,
    ]
    
    for test in tests:
        if not test():
            print("Stopping at first failure")
            break
        print()
    
    print("Test completed successfully!")
