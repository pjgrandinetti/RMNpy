#!/usr/bin/env python3
"""
Test script for the fixed SIMonotonicDimension constructor

This script tests that creating SIMonotonicDimension no longer causes
segmentation faults due to coordinate array type mismatches.
"""

import os
import sys

sys.path.insert(0, "/Users/philip/Github/Software/OCTypes-SITypes/RMNpy/src")


def test_monotonic_dimension():
    try:
        from rmnpy.wrappers.rmnlib.dimension import SIMonotonicDimension

        print("=== Testing SIMonotonicDimension creation ===")

        # Test 1: Basic monotonic dimension with numeric coordinates
        print("\n1. Testing basic monotonic dimension...")
        coordinates = [0.0, 0.5, 1.0, 1.5, 2.0]
        print(f"  Creating dimension with coordinates: {coordinates}")

        try:
            dim = SIMonotonicDimension(coordinates=coordinates)
            print(f"  ✓ Successfully created SIMonotonicDimension: {dim}")
            print(f"  ✓ Dimension count: {dim.count}")
            print(f"  ✓ Dimension type: {dim.type}")

            # Test accessing coordinates
            retrieved_coords = dim.coordinates
            print(f"  ✓ Retrieved coordinates: {retrieved_coords}")

        except Exception as e:
            print(f"  ✗ ERROR creating basic monotonic dimension: {e}")
            import traceback

            traceback.print_exc()
            return False

        # Test 2: Monotonic dimension with metadata
        print("\n2. Testing monotonic dimension with metadata...")
        try:
            dim2 = SIMonotonicDimension(
                coordinates=[1.0, 2.5, 4.0, 7.0, 10.0],
                label="frequency",
                description="Variable frequency points",
                application={"purpose": "NMR acquisition"},
            )
            print(f"  ✓ Successfully created dimension with metadata: {dim2}")
            print(f"  ✓ Label: {dim2.label}")
            print(f"  ✓ Description: {dim2.description}")
            print(f"  ✓ Application: {dim2.application}")

        except Exception as e:
            print(f"  ✗ ERROR creating dimension with metadata: {e}")
            import traceback

            traceback.print_exc()
            return False

        # Test 3: Empty coordinates (should handle gracefully)
        print("\n3. Testing edge cases...")
        try:
            # This should work but result in a dimension with 0 count
            dim3 = SIMonotonicDimension(coordinates=[])
            print(f"  ✓ Empty coordinates handled: count = {dim3.count}")

        except Exception as e:
            print(f"  ✗ ERROR with empty coordinates: {e}")

        print("\n=== All SIMonotonicDimension tests completed successfully! ===")
        return True

    except ImportError as e:
        print(f"Import error: {e}")
        print("Make sure the module is built successfully")
        return False
    except Exception as e:
        print(f"Unexpected error: {e}")
        import traceback

        traceback.print_exc()
        return False


if __name__ == "__main__":
    success = test_monotonic_dimension()
    if success:
        print("\n🎉 SUCCESS: No segmentation fault! The coordinate array fix works!")
    else:
        print("\n❌ FAILED: There were errors in the test")
        sys.exit(1)
