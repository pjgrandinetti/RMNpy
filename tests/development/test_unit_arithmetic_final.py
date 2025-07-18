#!/usr/bin/env python3
"""Test SIUnit arithmetic operations"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from rmnpy.sitypes.unit import SIUnit

def test_unit_arithmetic():
    print("=== SIUnit Arithmetic Operations Test ===\n")
    
    # Test 1: Create base units
    print("1. Creating base units:")
    try:
        meter, _ = SIUnit.from_expression("m")
        second, _ = SIUnit.from_expression("s")
        kilogram, _ = SIUnit.from_expression("kg")
        print(f"   ✅ Meter: {meter.symbol}")
        print(f"   ✅ Second: {second.symbol}")
        print(f"   ✅ Kilogram: {kilogram.symbol}")
    except Exception as e:
        print(f"   ❌ Failed to create base units: {e}")
        return
    
    # Test 2: Test multiplication
    print("\n2. Testing multiplication:")
    try:
        result = meter * second
        print(f"   ✅ m * s = {result.symbol}")
    except Exception as e:
        print(f"   ❌ Multiplication failed: {e}")
    
    # Test 3: Test division
    print("\n3. Testing division:")
    try:
        result = meter / second
        print(f"   ✅ m / s = {result.symbol}")
    except Exception as e:
        print(f"   ❌ Division failed: {e}")
    
    # Test 4: Test powers
    print("\n4. Testing powers:")
    try:
        result = meter ** 2
        print(f"   ✅ m ** 2 = {result.symbol}")
    except Exception as e:
        print(f"   ❌ Power failed: {e}")
    
    # Test 5: Test step-by-step complex expressions
    print("\n5. Testing step-by-step complex expressions:")
    try:
        # Build force step by step: kg * m / s^2
        step1 = kilogram * meter  # kg*m
        print(f"   Step 1 (kg*m): {step1.symbol}")
        
        step2 = second ** 2  # s^2
        print(f"   Step 2 (s^2): {step2.symbol}")
        
        force = step1 / step2  # (kg*m) / s^2
        print(f"   ✅ Force (kg*m/s^2): {force.symbol}")
        
    except Exception as e:
        print(f"   ❌ Complex expression failed: {e}")
    
    # Test 6: Test with direct expression creation
    print("\n6. Testing direct expression creation:")
    try:
        # Create units directly from expressions
        velocity, _ = SIUnit.from_expression("m/s")
        print(f"   ✅ Velocity: {velocity.symbol}")
        
        acceleration, _ = SIUnit.from_expression("m/s^2")
        print(f"   ✅ Acceleration: {acceleration.symbol}")
        
        force_direct, _ = SIUnit.from_expression("kg*m/s^2")
        print(f"   ✅ Force direct: {force_direct.symbol}")
        
    except Exception as e:
        print(f"   ❌ Direct expression failed: {e}")
    
    # Test 7: Test combining created units
    print("\n7. Testing combinations of created units:")
    try:
        # Create some units via arithmetic
        area = meter ** 2
        volume = area * meter
        print(f"   ✅ Area (m^2): {area.symbol}")
        print(f"   ✅ Volume (m^3): {volume.symbol}")
        
        # Create derived units
        velocity = meter / second
        acceleration = velocity / second
        print(f"   ✅ Velocity (m/s): {velocity.symbol}")
        print(f"   ✅ Acceleration (m/s^2): {acceleration.symbol}")
        
    except Exception as e:
        print(f"   ❌ Unit combinations failed: {e}")
    
    print("\n=== Test Complete ===")

if __name__ == "__main__":
    test_unit_arithmetic()
