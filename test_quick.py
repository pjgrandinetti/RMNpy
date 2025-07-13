#!/usr/bin/env python3
"""Quick test script for RMNpy functionality."""

import sys
import traceback

def test_import():
    """Test that RMNpy can be imported."""
    print("Testing RMNpy import...")
    try:
        import rmnpy
        print("✓ Successfully imported rmnpy")
        return True
    except Exception as e:
        print(f"✗ Failed to import rmnpy: {e}")
        traceback.print_exc()
        return False

def test_classes():
    """Test that main classes can be accessed."""
    print("Testing class access...")
    try:
        import rmnpy
        from rmnpy import Dataset, Datum
        from rmnpy.exceptions import RMNLibError, RMNLibMemoryError, RMNLibValidationError
        
        print("✓ Successfully imported Dataset, Datum, and exceptions")
        print(f"  Dataset: {Dataset}")
        print(f"  Datum: {Datum}")
        print(f"  RMNLibError: {RMNLibError}")
        return True
    except Exception as e:
        print(f"✗ Failed to import classes: {e}")
        traceback.print_exc()
        return False

def test_dataset_creation():
    """Test basic Dataset creation."""
    print("Testing Dataset creation...")
    try:
        from rmnpy import Dataset
        dataset = Dataset.create()
        print(f"✓ Successfully created dataset: {dataset}")
        
        # Test properties
        title = dataset.title
        description = dataset.description
        print(f"✓ Dataset title: '{title}'")
        print(f"✓ Dataset description: '{description}'")
        return True
    except Exception as e:
        print(f"✗ Failed to create dataset: {e}")
        traceback.print_exc()
        return False

def test_datum_creation():
    """Test basic Datum creation."""
    print("Testing Datum creation...")
    try:
        from rmnpy import Datum
        datum = Datum.create(response_value=42.0, coordinates=[1.0, 2.0, 3.0])
        print(f"✓ Successfully created datum: {datum}")
        
        # Test properties
        response = datum.response_value
        coords = datum.coordinates
        print(f"✓ Datum response value: {response}")
        print(f"✓ Datum coordinates: {coords}")
        return True
    except Exception as e:
        print(f"✗ Failed to create datum: {e}")
        traceback.print_exc()
        return False

def test_exceptions():
    """Test exception hierarchy."""
    print("Testing exceptions...")
    try:
        from rmnpy.exceptions import RMNLibError, RMNLibMemoryError, RMNLibValidationError
        
        # Test creating exceptions
        error = RMNLibError("test message")
        memory_error = RMNLibMemoryError("memory test")
        validation_error = RMNLibValidationError("validation test")
        
        # Test inheritance
        assert isinstance(memory_error, RMNLibError)
        assert isinstance(validation_error, RMNLibError)
        
        print("✓ Exception hierarchy working correctly")
        print(f"  RMNLibError: {RMNLibError}")
        print(f"  RMNLibMemoryError: {RMNLibMemoryError}")
        print(f"  RMNLibValidationError: {RMNLibValidationError}")
        return True
    except Exception as e:
        print(f"✗ Failed exception tests: {e}")
        traceback.print_exc()
        return False

def main():
    """Run all tests."""
    print("RMNpy Quick Test Suite")
    print("=" * 30)
    
    tests = [
        test_import,
        test_classes,
        test_dataset_creation,
        test_datum_creation,
        test_exceptions,
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
    
    print("=" * 30)
    print(f"Results: {passed} passed, {failed} failed")
    
    if failed == 0:
        print("🎉 All tests passed! RMNpy is working correctly.")
        return 0
    else:
        print("❌ Some tests failed. Check the output above.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
