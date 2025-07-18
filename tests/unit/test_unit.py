"""
Test script to check which SIUnit functions are available and working.
"""

from rmnpy.sitypes.unit import SIUnit

def test_basic_functionality():
    """Test the basic functionality that's known to work"""
    print("=== Basic SIUnit Functionality Test ===")
    
    # Test from_expression
    print("\n1. Testing from_expression:")
    try:
        unit, multiplier = SIUnit.from_expression("Hz")
        print(f"   ✅ Hz: {unit} (multiplier: {multiplier})")
    except Exception as e:
        print(f"   ❌ Hz failed: {e}")
    
    try:
        unit, multiplier = SIUnit.from_expression("m/s^2")
        print(f"   ✅ m/s^2: {unit} (multiplier: {multiplier})")
    except Exception as e:
        print(f"   ❌ m/s^2 failed: {e}")
    
    try:
        unit, multiplier = SIUnit.from_expression("kg*m/s^2")
        print(f"   ✅ kg*m/s^2: {unit} (multiplier: {multiplier})")
    except Exception as e:
        print(f"   ❌ kg*m/s^2 failed: {e}")
    
    # Test symbol property
    print("\n2. Testing symbol property:")
    unit, _ = SIUnit.from_expression("Hz")
    print(f"   ✅ Symbol: '{unit.symbol}'")
    
    # Test string representation
    print("\n3. Testing string representation:")
    print(f"   ✅ str(unit): '{str(unit)}'")
    print(f"   ✅ repr(unit): '{repr(unit)}'")

if __name__ == "__main__":
    test_basic_functionality()
