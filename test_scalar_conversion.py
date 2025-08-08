#!/usr/bin/env python3
"""
Test SIScalar conversion functions for RMNpy.

This script tests the various conversion functions:
1. py_list_to_siscalar_ocarray
"""

import sys

sys.path.insert(0, "/Users/philip/Github/Software/OCTypes-SITypes/RMNpy/src")


def test_scalar_conversions() -> None:
    """Test scalar conversion functions."""
    try:
        from rmnpy.helpers.octypes import py_list_to_siscalar_ocarray

        print("=== Testing Scalar Conversion Functions ===")

        # Test: List to SIScalar OCArray conversion
        print("\n1. Testing py_list_to_siscalar_ocarray...")
        coordinates = [0.0, 0.5, 1.0, 1.5, 2.0]
        print(f"  Converting coordinate list: {coordinates}")

        try:
            coords_ptr = py_list_to_siscalar_ocarray(coordinates, "1")
            print(f"  Created coordinate array pointer: {coords_ptr}")
            print("  ✓ py_list_to_siscalar_ocarray works!")

        except Exception as e:
            print(f"  ERROR: {e}")

        print("\nAll available scalar conversion functions tested!")

    except ImportError as e:
        print(f"Import error: {e}")
    except Exception as e:
        print(f"Test failed with error: {e}")


if __name__ == "__main__":
    test_scalar_conversions()
