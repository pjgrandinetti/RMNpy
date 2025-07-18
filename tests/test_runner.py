#!/usr/bin/env python3
"""
Quick test runner for Phase 1-4 integration tests.
Runs key tests to verify functionality without pytest configuration issues.
"""

import sys
import numpy as np

# Add the src directory to path
sys.path.insert(0, 'src')

try:
    import rmnpy
    from rmnpy.sitypes import SIScalar, SIUnit, SIDimensionality
    from rmnpy.exceptions import RMNLibValidationError
    print("✅ Successfully imported all RMNpy modules")
except ImportError as e:
    print(f"❌ Import error: {e}")
    sys.exit(1)

def test_phase1_dimensionality():
    """Test Phase 1: SIDimensionality functionality."""
    print("\n🧪 Testing Phase 1: SIDimensionality")
    
    try:
        # Test creation from quantities
        length_dim = SIDimensionality.from_quantity('length')
        time_dim = SIDimensionality.from_quantity('time')
        print(f"   ✅ Created dimensionalities: {length_dim}, {time_dim}")
        
        # Test arithmetic
        velocity_dim = length_dim / time_dim
        print(f"   ✅ Dimensionality arithmetic: {length_dim} / {time_dim} = {velocity_dim}")
        
        # Test comparison
        length2 = SIDimensionality.from_quantity('length')
        assert length_dim == length2
        print(f"   ✅ Dimensionality equality works")
        
        return True
    except Exception as e:
        print(f"   ❌ Phase 1 test failed: {e}")
        return False

def test_phase2_units():
    """Test Phase 2: SIUnit functionality."""
    print("\n🧪 Testing Phase 2: SIUnit")
    
    try:
        # Test unit creation
        meter_result = SIUnit.from_expression('m')
        hz_result = SIUnit.from_expression('Hz')
        print(f"   ✅ Created units: {meter_result[0]}, {hz_result[0]}")
        
        # Test unit properties
        meter_unit = meter_result[0]
        meter_dim = meter_unit.dimensionality()
        print(f"   ✅ Unit dimensionality access: {meter_dim}")
        
        return True
    except Exception as e:
        print(f"   ❌ Phase 2 test failed: {e}")
        return False

def test_phase3_scalars():
    """Test Phase 3: SIScalar functionality."""
    print("\n🧪 Testing Phase 3: SIScalar")
    
    try:
        # Test scalar creation
        freq1 = SIScalar.from_value_and_unit(100.0, 'MHz')
        freq2 = SIScalar.from_value_and_unit(50.0, 'MHz')
        print(f"   ✅ Created scalars: {freq1}, {freq2}")
        
        # Test arithmetic
        freq_sum = freq1 + freq2
        freq_diff = freq1 - freq2
        freq_ratio = freq1 / freq2
        print(f"   ✅ Scalar arithmetic: sum={freq_sum}, diff={freq_diff}, ratio={freq_ratio}")
        
        # Check specific values
        assert freq_ratio.value == 2.0, f"Expected ratio 2.0, got {freq_ratio.value}"
        print(f"   ✅ Arithmetic results correct")
        
        return True
    except Exception as e:
        print(f"   ❌ Phase 3 test failed: {e}")
        return False

def test_phase4_integration():
    """Test Phase 4: RMNLib integration."""
    print("\n🧪 Testing Phase 4: Integration")
    
    try:
        data = np.array([1.0, 2.0, 3.0, 4.0])
        
        # Test string units (backward compatibility)
        dep_var_str = rmnpy.DependentVariable.create(
            data=data,
            name='test_string',
            units='MHz',
            description='String units test'
        )
        print(f"   ✅ DependentVariable with string units: {dep_var_str.name}")
        
        # Test SIUnit object
        freq_unit = SIUnit.from_expression('MHz')[0]
        dep_var_obj = rmnpy.DependentVariable.create(
            data=data,
            name='test_object',
            units=freq_unit,
            description='SIUnit object test'
        )
        print(f"   ✅ DependentVariable with SIUnit object: {dep_var_obj.name}")
        
        # Test SIUnit tuple
        freq_unit_tuple = SIUnit.from_expression('MHz')
        dep_var_tuple = rmnpy.DependentVariable.create(
            data=data,
            name='test_tuple',
            units=freq_unit_tuple,
            description='SIUnit tuple test'
        )
        print(f"   ✅ DependentVariable with SIUnit tuple: {dep_var_tuple.name}")
        
        return True
    except Exception as e:
        print(f"   ❌ Phase 4 test failed: {e}")
        return False

def test_scientific_workflow():
    """Test complete scientific workflow."""
    print("\n🧪 Testing Scientific Workflow")
    
    try:
        # Create measurement data
        voltage_data = np.array([1.2, 1.5, 1.8, 2.1, 2.4])
        current_data = np.array([0.5, 0.6, 0.7, 0.8, 0.9])
        
        # Create units
        voltage_unit = SIUnit.from_expression('mV')[0]
        current_unit = SIUnit.from_expression('mA')[0]
        
        # Create dependent variables with units
        voltage_depvar = rmnpy.DependentVariable.create(
            data=voltage_data,
            name='voltage_measurement',
            units=voltage_unit,
            description='Voltage measurements with SI units'
        )
        
        current_depvar = rmnpy.DependentVariable.create(
            data=current_data,
            name='current_measurement',
            units=current_unit,
            description='Current measurements with SI units'
        )
        
        print(f"   ✅ Created voltage measurements: {voltage_depvar.name}")
        print(f"   ✅ Created current measurements: {current_depvar.name}")
        
        # Test unit calculations
        freq1 = SIScalar.from_value_and_unit(100.0, 'MHz')
        freq2 = SIScalar.from_value_and_unit(50.0, 'MHz')
        time_val = SIScalar.from_value_and_unit(2.0, 'ms')
        
        # Physics calculations
        freq_sum = freq1 + freq2
        freq_product = freq1 * time_val
        freq_ratio = freq1 / freq2
        
        print(f"   ✅ Physics calculations: sum={freq_sum}, product={freq_product}, ratio={freq_ratio}")
        
        return True
    except Exception as e:
        print(f"   ❌ Scientific workflow test failed: {e}")
        return False

def main():
    """Run all tests and report results."""
    print("🚀 Running Phase 1-4 Integration Tests")
    print("=" * 60)
    
    tests = [
        test_phase1_dimensionality,
        test_phase2_units,
        test_phase3_scalars,
        test_phase4_integration,
        test_scientific_workflow
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        if test():
            passed += 1
    
    print("\n" + "=" * 60)
    print(f"🏆 Test Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 ALL TESTS PASSED! Phase 1-4 integration is working correctly!")
        print("\n✅ Phase 1: SIDimensionality - VERIFIED")
        print("✅ Phase 2: SIUnit - VERIFIED") 
        print("✅ Phase 3: SIScalar - VERIFIED")
        print("✅ Phase 4: Integration - VERIFIED")
        print("✅ Scientific Workflows - VERIFIED")
        print("\n🚀 Ready for Phase 5: Advanced Features!")
    else:
        print(f"❌ {total - passed} tests failed. Review the errors above.")
        sys.exit(1)

if __name__ == "__main__":
    main()
