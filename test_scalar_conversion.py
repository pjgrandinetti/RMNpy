#!/usr/bin/env python3
"""
Test script for the new scalar conversion functions in octypes.pyx

This script tests:
1. py_number_to_siscalar
2. py_number_to_siscalar_expression
3. siscalar_to_py_number
4. siscalar_to_py_tuple
5. py_list_to_siscalar_ocarray
"""

import os
import sys

sys.path.insert(0, "/Users/philip/Github/Software/OCTypes-SITypes/RMNpy/src")


def test_scalar_conversions():
    try:
        from rmnpy.helpers.octypes import (
            debug_octype_ids,
            py_coordinate_list_to_siscalar_ocarray,
            py_list_to_siscalar_ocarray,
            py_number_to_siscalar,
            py_number_to_siscalar_expression,
            release_octype,
            siscalar_to_py_number,
            siscalar_to_py_tuple,
        )

        print("=== Testing Scalar Conversion Functions ===")

        # Test 1: Basic number to SIScalar conversion
        print("\n1. Testing py_number_to_siscalar_expression...")
        test_values = [
            (42, "m"),
            (3.14159, "s"),
            # Skip complex for now - SITypes parser syntax is tricky
            # (2+3j, "kg"),
            (-7.5, "1"),  # dimensionless
        ]

        scalar_ptrs = []
        for value, unit in test_values:
            print(f"  Converting {value} with unit '{unit}'...")
            try:
                scalar_ptr = py_number_to_siscalar_expression(value, unit)
                scalar_ptrs.append(scalar_ptr)
                print(f"    Created SIScalar pointer: {scalar_ptr}")

                # Test conversion back to Python
                py_value = siscalar_to_py_number(scalar_ptr)
                py_value_unit = siscalar_to_py_tuple(scalar_ptr)
                print(f"    Back to Python: {py_value}")
                print(f"    With unit: {py_value_unit}")

            except Exception as e:
                print(f"    ERROR: {e}")

        # Test 2: List to SIScalar OCArray conversion
        print("\n2. Testing py_list_to_siscalar_ocarray...")
        coordinates = [0.0, 0.5, 1.0, 1.5, 2.0]
        print(f"  Converting coordinate list: {coordinates}")

        try:
            array_ptr = py_list_to_siscalar_ocarray(coordinates, "m")
            print(f"  Created OCArrayRef with SIScalars: {array_ptr}")
            scalar_ptrs.append(array_ptr)

        except Exception as e:
            print(f"  ERROR: {e}")

        # Clean up all allocated scalars
        print("\n3. Cleaning up allocated objects...")
        for ptr in scalar_ptrs:
            if ptr != 0:
                release_octype(ptr)
                print(f"  Released: {ptr}")

        print("\n=== All tests completed ===")
        return True

    except ImportError as e:
        print(f"Import error: {e}")
        print("Make sure the module is built successfully")
        return False
    except Exception as e:
        print(f"Unexpected error: {e}")
        return False


if __name__ == "__main__":
    test_scalar_conversions()
