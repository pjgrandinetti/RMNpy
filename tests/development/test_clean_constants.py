#!/usr/bin/env python3
"""
Test script to verify the clean C constants implementation.
"""

# Test using the example from the user's feedback
from rmnpy.sitypes import SIDimensionality, QUANTITY_PRESSURE, QUANTITY_ELECTRIC_QUADRUPOLE_MOMENT

print("Testing the clean C constants approach:")

# Test with a basic quantity
print("\n1. Testing QUANTITY_PRESSURE:")
try:
    dim1 = SIDimensionality.from_quantity(QUANTITY_PRESSURE)
    print(f"   ✓ QUANTITY_PRESSURE -> {dim1}")
except Exception as e:
    print(f"   ✗ Error: {e}")

# Test with a more complex quantity
print("\n2. Testing QUANTITY_ELECTRIC_QUADRUPOLE_MOMENT:")
try:
    dim2 = SIDimensionality.from_quantity(QUANTITY_ELECTRIC_QUADRUPOLE_MOMENT)
    print(f"   ✓ QUANTITY_ELECTRIC_QUADRUPOLE_MOMENT -> {dim2}")
except Exception as e:
    print(f"   ✗ Error: {e}")

# Test with string fallback
print("\n3. Testing string fallback:")
try:
    dim3 = SIDimensionality.from_quantity("pressure")
    print(f"   ✓ String 'pressure' -> {dim3}")
except Exception as e:
    print(f"   ✗ Error: {e}")

print("\nAll tests completed!")
