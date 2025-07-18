"""
Test script for SIUnit arithmetic operations (fixed version).
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
    
    # Test complex expressions (fixed)
    print("\n5. Testing complex expressions:")
    try:
        # Create force unit: kg * m / s^2
        velocity, _ = meter / second
        acceleration, _ = velocity / second
        force, _ = kilogram * acceleration
        print(f"   ✅ Force (kg*m/s^2): {force}")
    except Exception as e:
        print(f"   ❌ Complex expression failed: {e}")
    
    # Test energy unit: kg * m^2 / s^2
    try:
        area, _ = meter ** 2
        energy, _ = kilogram * area
        energy_per_time_sq, _ = energy / (second ** 2)[0]
        print(f"   ✅ Energy (kg*m^2/s^2): {energy_per_time_sq}")
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

    # Test chaining operations
    print("\n7. Testing chained operations:")
    try:
        # acceleration = m/s^2
        accel, _ = meter / (second ** 2)[0]
        print(f"   ✅ Acceleration (m/s^2): {accel}")
        
        # Newton = kg*m/s^2
        newton, _ = kilogram * accel
        print(f"   ✅ Newton (kg*m/s^2): {newton}")
        
        # Watt = J/s = kg*m^2/s^3
        watt, _ = SIUnit.from_expression("W")
        print(f"   ✅ Watt: {watt}")
    except Exception as e:
        print(f"   ❌ Chained operations failed: {e}")

if __name__ == "__main__":
    test_unit_arithmetic()
