#!/usr/bin/env python3

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

try:
    print("Testing imports...")
    from rmnpy.sitypes import SIDimensionality, kSIQuantityPressure, kSIQuantityForce, kSIQuantityEnergy
    print("✓ Imports successful")
    
    print("\nTesting constants:")
    print(f"kSIQuantityPressure = {kSIQuantityPressure!r}")
    print(f"kSIQuantityForce = {kSIQuantityForce!r}")
    print(f"kSIQuantityEnergy = {kSIQuantityEnergy!r}")
    print("✓ Constants available")
    
    print("\nTesting from_quantity method:")
    print("Creating pressure dimensionality...")
    pressure_dim = SIDimensionality.from_quantity(kSIQuantityPressure)
    print(f"✓ Pressure dimensionality: {pressure_dim}")
    
    print("Creating force dimensionality...")
    force_dim = SIDimensionality.from_quantity(kSIQuantityForce)
    print(f"✓ Force dimensionality: {force_dim}")
    
    print("Creating energy dimensionality...")
    energy_dim = SIDimensionality.from_quantity(kSIQuantityEnergy)
    print(f"✓ Energy dimensionality: {energy_dim}")
    
    print("\n✅ All tests passed!")

except Exception as e:
    print(f"❌ Error occurred: {e}")
    import traceback
    traceback.print_exc()
