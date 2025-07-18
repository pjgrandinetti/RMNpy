#!/usr/bin/env python3
"""
Test script to demonstrate using C constants directly in Python.
"""

# Test using the C constants directly
from rmnpy.sitypes import SIDimensionality, kSIQuantityPressure, kSIQuantityElectricQuadrupoleMoment

print("Testing C constants used directly in Python:")

# Test with pressure
print(f"\n1. Testing kSIQuantityPressure:")
print(f"   Constant value: {kSIQuantityPressure}")
try:
    dim1 = SIDimensionality.from_quantity(kSIQuantityPressure)
    print(f"   ✓ kSIQuantityPressure -> {dim1}")
except Exception as e:
    print(f"   ✗ Error: {e}")

# Test with electric quadrupole moment
print(f"\n2. Testing kSIQuantityElectricQuadrupoleMoment:")
print(f"   Constant value: {kSIQuantityElectricQuadrupoleMoment}")
try:
    dim2 = SIDimensionality.from_quantity(kSIQuantityElectricQuadrupoleMoment)
    print(f"   ✓ kSIQuantityElectricQuadrupoleMoment -> {dim2}")
except Exception as e:
    print(f"   ✗ Error: {e}")

# Test with string fallback
print(f"\n3. Testing string fallback:")
try:
    dim3 = SIDimensionality.from_quantity("pressure")
    print(f"   ✓ String 'pressure' -> {dim3}")
except Exception as e:
    print(f"   ✗ Error: {e}")

print("\nAll tests completed!")
