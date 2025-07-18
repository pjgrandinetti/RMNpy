"""
Test script for SIUnit arithmetic operations.
"""

from rmnpy.sitypes.unit import SIUnit

def test_unit_arithmetic():
    """Test SIUnit arithmetic operations similar to SIDimensionality"""
    print("=== SIUnit Arithmetic Operations Test ===")
    
    # Create base units
    print("\n1. Creating base units:")
    meter, _ = SIUnit.from_expression("m")
    second, _ = SIUnit.from_expression("s")
    kilogram, _ = SIUnit.from_expression("kg")
    
    print(f"   ✅ Meter: {meter}")
    print(f"   ✅ Second: {second}")
    print(f"   ✅ Kilogram: {kilogram}")
    
    # Test multiplication
    print("\n2. Testing multiplication:")
    try:
        result_unit, multiplier = meter * second
        print(f"   ✅ {meter} * {second} = {result_unit} (multiplier: {multiplier})")
    except Exception as e:
        print(f"   ❌ Multiplication failed: {e}")
    
    # Test division
    print("\n3. Testing division:")
    try:
        result_unit, multiplier = meter / second
        print(f"   ✅ {meter} / {second} = {result_unit} (multiplier: {multiplier})")
    except Exception as e:
        print(f"   ❌ Division failed: {e}")
    
    # Test power
    print("\n4. Testing powers:")
    try:
        result_unit, multiplier = meter ** 2
        print(f"   ✅ {meter} ** 2 = {result_unit} (multiplier: {multiplier})")
    except Exception as e:
        print(f"   ❌ Power failed: {e}")
    
    # Test complex expressions
    print("\n5. Testing complex expressions:")
    try:
        # Create force unit: kg * m / s^2
        velocity, _ = meter / second
        acceleration, _ = velocity[0] / second
        force, _ = kilogram * acceleration[0]
        print(f"   ✅ Force (kg*m/s^2): {force[0]}")
    except Exception as e:
        print(f"   ❌ Complex expression failed: {e}")
    
    # Test energy unit: kg * m^2 / s^2
    try:
        area, _ = meter ** 2
        energy, _ = kilogram * area[0]
        energy_per_time_sq, _ = energy[0] / (second ** 2)
        print(f"   ✅ Energy (kg*m^2/s^2): {energy_per_time_sq[0]}")
    except Exception as e:
        print(f"   ❌ Energy expression failed: {e}")
    
    # Test with composite units
    print("\n6. Testing with composite units:")
    try:
        hz, _ = SIUnit.from_expression("Hz")
        joule, _ = SIUnit.from_expression("J")
        
        # Planck constant units: J*s
        planck_units, _ = joule * second
        print(f"   ✅ Planck constant units (J*s): {planck_units}")
        
        # Energy/frequency units: J/Hz
        energy_freq, _ = joule / hz
        print(f"   ✅ Energy/frequency (J/Hz): {energy_freq}")
    except Exception as e:
        print(f"   ❌ Composite units failed: {e}")

if __name__ == "__main__":
    test_unit_arithmetic()
