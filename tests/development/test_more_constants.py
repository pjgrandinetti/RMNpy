#!/usr/bin/env python3

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

try:
    from rmnpy.sitypes import SIDimensionality, kSIQuantityLength, kSIQuantityMass, kSIQuantityTime
    print("Testing base quantities:")
    print(f"Length: {kSIQuantityLength} -> {SIDimensionality.from_quantity(kSIQuantityLength)}")
    print(f"Mass: {kSIQuantityMass} -> {SIDimensionality.from_quantity(kSIQuantityMass)}")
    print(f"Time: {kSIQuantityTime} -> {SIDimensionality.from_quantity(kSIQuantityTime)}")
    
    print("\nTesting derived quantities:")
    from rmnpy.sitypes import kSIQuantityArea, kSIQuantityVolume, kSIQuantityVelocity, kSIQuantityAcceleration
    print(f"Area: {kSIQuantityArea} -> {SIDimensionality.from_quantity(kSIQuantityArea)}")
    print(f"Volume: {kSIQuantityVolume} -> {SIDimensionality.from_quantity(kSIQuantityVolume)}")
    print(f"Velocity: {kSIQuantityVelocity} -> {SIDimensionality.from_quantity(kSIQuantityVelocity)}")
    print(f"Acceleration: {kSIQuantityAcceleration} -> {SIDimensionality.from_quantity(kSIQuantityAcceleration)}")
    
    print("\n✅ All tests passed!")
    
except Exception as e:
    print(f"❌ Error occurred: {e}")
    import traceback
    traceback.print_exc()
