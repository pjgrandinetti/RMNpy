#!/usr/bin/env python3
"""
Debug script to isolate the monotonic dimension segfault
"""

import sys
import traceback

# Import must come after path modification
sys.path.insert(0, ".")

# flake8: noqa: E402
from rmnpy.wrappers.rmnlib.dimension import SIMonotonicDimension

if __name__ == "__main__":
    print("=== Testing Monotonic Dimension Creation ===")

    try:
        # Use the exact same data from the failing test
        coordinates = [1.0, 100.0, 1000.0, 1000000.0, 2.36518262e15]

        print(f"Creating monotonic dimension with coordinates: {coordinates}")

        dim = SIMonotonicDimension(
            coordinates=coordinates,
            quantity_name="length",  # Explicit quantity name
            description="Far far away.",
            label="distance",
        )

        print(f"SUCCESS! Created dimension: {dim}")
        print(f"Type: {dim.type}")
        print(f"Count: {dim.count}")
        print(f"Is quantitative: {dim.is_quantitative()}")

    except Exception as e:
        print(f"FAILED: {e}")
        traceback.print_exc()
        sys.exit(1)

    print("\n=== Monotonic dimension creation successful! ===")
