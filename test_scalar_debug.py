#!/usr/bin/env python3
"""
Test script for the original failing dimension creation case
"""

import sys

# Import must come after path modification
sys.path.insert(0, ".")

from rmnpy.wrappers.rmnlib.dimension import SILinearDimension

# flake8: noqa: E402
from rmnpy.wrappers.sitypes.scalar import Scalar

if __name__ == "__main__":
    print("=== Testing original failing case ===")

    try:
        # Create a 1-meter increment scalar
        increment = Scalar(1.0, "m")
        print(f"Created increment: {increment}")

        # Create a linear dimension (this was failing before)
        dim = SILinearDimension(
            count=100,
            increment=increment,
            label="distance",
            description="Linear distance dimension",
        )

        print(f"SUCCESS! Created dimension: {dim}")
        print(f"Dimension count: {dim.count}")
        print(f"Dimension increment: {dim.increment}")

    except Exception as e:
        print(f"FAILED: {e}")
        import traceback

        traceback.print_exc()
        sys.exit(1)

    print("\n=== Testing string increment ===")
    try:
        # Test with string increment
        dim2 = SILinearDimension(
            count=50,
            increment="0.5 m",  # String increment
            label="half_meter",
            description="Half meter increment",
        )
        print(f"SUCCESS! Created dimension with string increment: {dim2}")

    except Exception as e:
        print(f"FAILED with string increment: {e}")
        import traceback

        traceback.print_exc()
        sys.exit(1)

    print("\n=== All tests passed! ===")
    print("The cross-module Cython cdef attribute access issue has been resolved.")
