#!/usr/bin/env python3
"""Minimal test to debug SIScalarCreateWithDouble."""

import sys
sys.path.insert(0, 'src')

try:
    # Import the low-level function directly
    from rmnpy.core import SIScalarCreateWithDouble, SIScalarDoubleValueInCoherentUnit
    print("✓ Imported SIScalar functions from core")
    
    # Test calling SIScalarCreateWithDouble directly
    result = SIScalarCreateWithDouble(42.0, None)
    print(f"SIScalarCreateWithDouble result: {result}")
    
    if result is not None:
        value = SIScalarDoubleValueInCoherentUnit(result)
        print(f"Value from scalar: {value}")
    else:
        print("❌ SIScalarCreateWithDouble returned NULL")
    
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
