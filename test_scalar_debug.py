#!/usr/bin/env python3
"""
Debug script to test Scalar C reference passing
"""

import sys

# Import must come after path modification
sys.path.insert(0, ".")

# flake8: noqa: E402
from rmnpy.wrappers.sitypes.scalar import Scalar


def debug_scalar(s: "Scalar") -> None:
    """Debug a scalar object"""
    print(f"Scalar: {s}")
    print(f"Type: {type(s)}")
    print(f"Value: {s.value}")
    print(f"Is real: {s.is_real}")
    print(f"Is complex: {s.is_complex}")
    print(f"Isinstance Scalar: {isinstance(s, Scalar)}")

    # Try to access what would be the Cython attribute
    try:
        # This will fail but shows the structure
        print(f"Has _c_scalar: {hasattr(s, '_c_scalar')}")
    except Exception as e:
        print(f"Exception checking _c_scalar: {e}")


if __name__ == "__main__":
    s1 = Scalar("10.0")
    print("=== String scalar ===")
    debug_scalar(s1)

    s2 = Scalar(10.0)
    print("\n=== Numeric scalar ===")
    debug_scalar(s2)

    s3 = Scalar(10.0, "1")  # Dimensionless
    print("\n=== Dimensionless scalar ===")
    debug_scalar(s3)
