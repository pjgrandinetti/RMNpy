#!/usr/bin/env python3
"""Quick test for SIScalar functionality."""

import sys
sys.path.insert(0, 'src')

try:
    import rmnpy
    print("✓ Successfully imported rmnpy")
    
    # Test basic SIScalar creation
    scalar = rmnpy.SIScalar.from_value_and_unit(1.0, "Hz")
    print(f"✓ Created SIScalar from value and unit: {scalar}")
    print(f"  Value: {scalar.value}")
    
    # Test simple expression parsing
    scalar2 = rmnpy.SIScalar.from_expression("2.5 m")
    print(f"✓ Created SIScalar from expression: {scalar2}")
    print(f"  Value: {scalar2.value}")
    
    # Test dimensionless scalar
    scalar3 = rmnpy.SIScalar.from_value_and_unit(42.0, None)
    print(f"✓ Created dimensionless SIScalar: {scalar3}")
    print(f"  Value: {scalar3.value}")
    
    # Test helper functions
    from rmnpy.siscalar import py_to_siscalar_ref, siscalar_ref_to_py
    
    ref = py_to_siscalar_ref(5.0)
    value = siscalar_ref_to_py(ref)
    print(f"✓ Helper functions work: {value}")
    
    ref2 = py_to_siscalar_ref("3.0 Hz") 
    value2 = siscalar_ref_to_py(ref2)
    print(f"✓ Helper with expression: {value2}")
    
    print("\n🎉 All basic tests passed!")
    
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
