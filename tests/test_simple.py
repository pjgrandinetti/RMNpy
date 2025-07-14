#!/usr/bin/env python3
"""Simple test script that avoids loops and multiple object creation."""

import sys

def test_basic_import():
    """Test basic import only."""
    print("Testing basic import...")
    try:
        import rmnpy
        print("✓ RMNpy imported successfully")
        return True
    except Exception as e:
        print(f"✗ Import failed: {e}")
        return False

def test_single_dataset():
    """Test creating just one dataset."""
    print("Testing single dataset creation...")
    try:
        from rmnpy import Dataset
        dataset = Dataset.create()
        print(f"✓ Created dataset: {dataset}")
        
        # Test one property
        title = dataset.title
        print(f"✓ Dataset title: {title}")
        return True
    except Exception as e:
        print(f"✗ Dataset creation failed: {e}")
        return False

def test_single_datum():
    """Test creating just one datum."""
    print("Testing single datum creation...")
    try:
        from rmnpy import Datum
        datum = Datum.create(response_value=1.0)
        print(f"✓ Created datum: {datum}")
        
        # Test one property
        response = datum.response_value
        print(f"✓ Datum response: {response}")
        return True
    except Exception as e:
        print(f"✗ Datum creation failed: {e}")
        return False

def main():
    """Run simple tests without loops."""
    print("RMNpy Simple Test")
    print("=================")
    
    tests = [
        test_basic_import,
        test_single_dataset,
        test_single_datum,
    ]
    
    passed = 0
    failed = 0
    
    for test in tests:
        try:
            if test():
                passed += 1
            else:
                failed += 1
        except Exception as e:
            print(f"✗ Test {test.__name__} crashed: {e}")
            failed += 1
        print()
    
    print(f"Results: {passed} passed, {failed} failed")
    return failed == 0

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
