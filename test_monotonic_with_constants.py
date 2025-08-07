#!/usr/bin/env python3
"""
Test SIMonotonicDimension with explicit quantity constants
"""

import os
import sys

sys.path.insert(0, "/Users/philip/Github/Software/OCTypes-SITypes/RMNpy/src")


def test_monotonic_dimension_with_constants():
    try:
        from rmnpy.constants import kSIQuantityDimensionless
        from rmnpy.wrappers.rmnlib.dimension import SIMonotonicDimension

        print("=== Testing SIMonotonicDimension with quantity constants ===")

        # Test coordinates - simple dimensionless values
        coordinates = [0.0, 0.5, 1.0, 1.5, 2.0]

        print(f"Creating monotonic dimension with:")
        print(f"  - coordinates: {coordinates}")
        print(f"  - quantity_name: kSIQuantityDimensionless")
        print(f"  - offset: 0.0")
        print(f"  - origin: 0.0")
        print(f"  - periodic: False")

        try:
            # Use the constant directly instead of string
            monotonic_dim = SIMonotonicDimension(
                coordinates=coordinates,
                quantity_name=kSIQuantityDimensionless,  # Use the OCStringRef constant
                offset=0.0,
                origin=0.0,
                periodic=False,
            )

            print(f"✓ Success! Created SIMonotonicDimension: {monotonic_dim}")

            # Test basic properties
            print(f"  - Size: {monotonic_dim.size}")
            print(f"  - Coordinates: {monotonic_dim.coordinates}")

        except Exception as e:
            print(f"✗ Error creating SIMonotonicDimension: {e}")
            import traceback

            traceback.print_exc()

        return True

    except ImportError as e:
        print(f"Import error: {e}")
        return False
    except Exception as e:
        print(f"Unexpected error: {e}")
        import traceback

        traceback.print_exc()
        return False


if __name__ == "__main__":
    test_monotonic_dimension_with_constants()
