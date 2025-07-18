#!/usr/bin/env python3
"""Quick test for SIScalar functionality - testing dimensionless first."""

import sys
sys.path.insert(0, 'src')

try:
    import rmnpy
    print("✓ Successfully imported rmnpy")
    
    # Test dimensionless scalar first (should work without unit parsing)
    scalar = rmnpy.SIScalar.from_value_and_unit(42.0, None)
    print(f"✓ Created dimensionless SIScalar: {scalar}")
    print(f"  Value: {scalar.value}")
    
    # Test helper functions with numeric values
    from rmnpy.siscalar import py_to_siscalar_ref, siscalar_ref_to_py
    
    ref = py_to_siscalar_ref(5.0)
    value = siscalar_ref_to_py(ref)
    print(f"✓ Helper functions work with numbers: {value}")
    
    print("\n🎉 Basic dimensionless tests passed!")
    
    # Now try with units
    print("\nTesting units...")
    try:
        scalar_with_unit = rmnpy.SIScalar.from_value_and_unit(1.0, "Hz")
        print(f"✓ Created SIScalar with unit: {scalar_with_unit}")
    except Exception as e:
        print(f"❌ Unit creation failed: {e}")
    
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
