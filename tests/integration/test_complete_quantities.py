#!/usr/bin/env python3
"""
Test script to verify the complete quantity constants implementation.
"""

import sys
import os

# Add the src directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

try:
    from rmnpy.sitypes import (
        SIDimensionality,
        QUANTITY_PRESSURE, QUANTITY_ENERGY, QUANTITY_FORCE, QUANTITY_VELOCITY,
        QUANTITY_ELECTRIC_CHARGE, QUANTITY_MAGNETIC_FLUX, QUANTITY_LUMINOUS_FLUX,
        QUANTITY_CATALYTIC_ACTIVITY, QUANTITY_ABSORBED_DOSE, QUANTITY_THERMAL_CONDUCTIVITY,
        QUANTITY_FIRST_HYPERPOLARIZABILITY, QUANTITY_GYROMAGNETIC_RATIO,
        QUANTITY_FINE_STRUCTURE_CONSTANT, QUANTITY_DIMENSIONLESS
    )
    
    print("✓ Successfully imported SIDimensionality and quantity constants")
    
    # Test a few key quantities
    test_quantities = [
        (QUANTITY_PRESSURE, "pressure"),
        (QUANTITY_ENERGY, "energy"),
        (QUANTITY_FORCE, "force"),
        (QUANTITY_VELOCITY, "velocity"),
        (QUANTITY_ELECTRIC_CHARGE, "electric charge"),
        (QUANTITY_MAGNETIC_FLUX, "magnetic flux"),
        (QUANTITY_LUMINOUS_FLUX, "luminous flux"),
        (QUANTITY_CATALYTIC_ACTIVITY, "catalytic activity"),
        (QUANTITY_ABSORBED_DOSE, "absorbed dose"),
        (QUANTITY_THERMAL_CONDUCTIVITY, "thermal conductivity"),
        (QUANTITY_FIRST_HYPERPOLARIZABILITY, "first hyperpolarizability"),
        (QUANTITY_GYROMAGNETIC_RATIO, "gyromagnetic ratio"),
        (QUANTITY_FINE_STRUCTURE_CONSTANT, "fine structure constant"),
        (QUANTITY_DIMENSIONLESS, "dimensionless")
    ]
    
    print(f"\nTesting {len(test_quantities)} quantity constants...")
    
    for constant, expected_name in test_quantities:
        try:
            print(f"  Testing {constant}...")
            
            # Verify the constant has the expected value
            if constant != expected_name:
                print(f"    ✗ Constant value mismatch: expected '{expected_name}', got '{constant}'")
                continue
            
            # Test from_quantity method
            dim = SIDimensionality.from_quantity(constant)
            print(f"    ✓ Created dimensionality: {dim}")
            
            # Test direct string usage
            dim2 = SIDimensionality.from_quantity(expected_name)
            print(f"    ✓ Direct string also works: {dim2}")
            
            # They should be equal
            if dim.symbol != dim2.symbol:
                print(f"    ✗ Dimensionalities don't match: {dim.symbol} != {dim2.symbol}")
            else:
                print(f"    ✓ Both methods give same result")
                
        except Exception as e:
            print(f"    ✗ Error testing {constant}: {e}")
    
    print("\n✓ All tests completed!")
    
except ImportError as e:
    print(f"✗ Import error: {e}")
    sys.exit(1)
except Exception as e:
    print(f"✗ Unexpected error: {e}")
    sys.exit(1)
