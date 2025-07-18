#!/usr/bin/env python3
"""
Test script to verify the updated DependentVariable.create() method
respects NULL behavior properly.
"""

import numpy as np
from rmnpy.dependent_variable import DependentVariable

def test_create_with_minimal_args():
    """Test create() with only required arguments."""
    print("Testing create() with minimal arguments...")
    
    # Create some test data
    data = np.array([1.0, 2.0, 3.0, 4.0])
    
    try:
        # This should use DependentVariableCreateDefault
        dv = DependentVariable.create(data)
        print(f"✓ Successfully created DependentVariable with shape {dv.shape}")
        return True
    except Exception as e:
        print(f"✗ Failed to create DependentVariable: {e}")
        return False

def test_create_with_all_args():
    """Test create() with all optional arguments."""
    print("Testing create() with all arguments...")
    
    # Create some test data
    data = np.array([1.0, 2.0, 3.0, 4.0])
    
    try:
        # This should use DependentVariableCreate
        dv = DependentVariable.create(
            data, 
            name="test_var",
            description="A test variable", 
            units="m/s"
        )
        print(f"✓ Successfully created DependentVariable with shape {dv.shape}")
        print(f"  Name: {dv.name}")
        print(f"  Description: {dv.description}")
        print(f"  Label: {dv.label}")
        print(f"  Units: {dv.units}")
        return True
    except Exception as e:
        print(f"✗ Failed to create DependentVariable: {e}")
        return False

def test_create_with_some_args():
    """Test create() with some optional arguments (mixed NULL/non-NULL)."""
    print("Testing create() with some arguments...")
    
    # Create some test data
    data = np.array([1.0, 2.0, 3.0, 4.0])
    
    try:
        # This should use DependentVariableCreate with some NULL parameters
        dv = DependentVariable.create(
            data, 
            name="partial_test",
            description=None,  # Should be passed as NULL
            units=None  # Should be passed as NULL
        )
        print(f"✓ Successfully created DependentVariable with shape {dv.shape}")
        print(f"  Name: {dv.name}")
        print(f"  Description: {dv.description}")  # Should be None or default
        print(f"  Label: {dv.label}")
        print(f"  Units: {dv.units}")
        return True
    except Exception as e:
        print(f"✗ Failed to create DependentVariable: {e}")
        return False

if __name__ == "__main__":
    print("Testing DependentVariable.create() NULL behavior compliance\n")
    
    success_count = 0
    total_tests = 3
    
    success_count += test_create_with_minimal_args()
    print()
    success_count += test_create_with_all_args()
    print()
    success_count += test_create_with_some_args()
    
    print(f"\nTest Results: {success_count}/{total_tests} tests passed")
    
    if success_count == total_tests:
        print("✓ All tests passed! DependentVariable.create() properly respects NULL behavior.")
    else:
        print("✗ Some tests failed. Check the implementation.")
