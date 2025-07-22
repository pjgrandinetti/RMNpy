#!/usr/bin/env python3

import sys
import os
sys.path.insert(0, 'src')

def test_scalar_methods():
    try:
        # Fresh import
        from rmnpy.wrappers.sitypes.scalar import Scalar
        print("✓ Import successful")
        
        # Check what methods are available
        all_methods = [name for name in dir(Scalar) if not name.startswith('_')]
        from_methods = [name for name in all_methods if name.startswith('from_')]
        print(f"All public methods: {all_methods}")
        print(f"From methods: {from_methods}")
        
        # Test basic creation
        try:
            s1 = Scalar(5.0, 'm')
            print(f"✓ Basic constructor: {s1.value} {s1.unit.symbol}")
        except Exception as e:
            print(f"✗ Basic constructor failed: {e}")
        
        # Test from_string
        try:
            s2 = Scalar.from_string("9.81 m/s^2")
            print(f"✓ from_string: {s2.value} {s2.unit.symbol}")
        except Exception as e:
            print(f"✗ from_string failed: {e}")
        
        # Test from_value_and_unit if available
        if hasattr(Scalar, 'from_value_and_unit'):
            try:
                s3 = Scalar.from_value_and_unit(3.0, 'kg')
                print(f"✓ from_value_and_unit: {s3.value} {s3.unit.symbol}")
            except Exception as e:
                print(f"✗ from_value_and_unit failed: {e}")
        else:
            print("✗ from_value_and_unit not found")
            
        # Test from_value_unit alias if available
        if hasattr(Scalar, 'from_value_unit'):
            try:
                s4 = Scalar.from_value_unit(2.0, 's')
                print(f"✓ from_value_unit: {s4.value} {s4.unit.symbol}")
            except Exception as e:
                print(f"✗ from_value_unit failed: {e}")
        else:
            print("✗ from_value_unit not found")
            
    except Exception as e:
        print(f"✗ Import or test failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_scalar_methods()
