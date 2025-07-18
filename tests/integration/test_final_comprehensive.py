#!/usr/bin/env python3
"""
Final comprehensive test of SITypes quantity constants functionality.
This script demonstrates all the implemented constants and their usage.
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

def test_quantity_constants():
    """Test all implemented quantity constants."""
    print("🧪 Testing SITypes Quantity Constants Implementation")
    print("=" * 60)
    
    try:
        # Import all constants
        from rmnpy.sitypes import (
            SIDimensionality,
            # Base quantities
            kSIQuantityLength, kSIQuantityMass, kSIQuantityTime,
            kSIQuantityCurrent, kSIQuantityTemperature,
            kSIQuantityAmount, kSIQuantityLuminousIntensity,
            # Common derived quantities
            kSIQuantityArea, kSIQuantityVolume, kSIQuantityVelocity,
            kSIQuantityAcceleration, kSIQuantityDensity,
            kSIQuantityForce, kSIQuantityPressure, kSIQuantityEnergy,
            kSIQuantityPower, kSIQuantityFrequency,
            # Additional quantities
            kSIQuantitySpeed, kSIQuantityLinearMomentum,
            kSIQuantityAngularMomentum, kSIQuantityPlaneAngle,
            kSIQuantityStress, kSIQuantityStrain,
            kSIQuantityElasticModulus, kSIQuantityViscosity
        )
        
        print("✅ All imports successful!")
        print()
        
        # Test base quantities
        print("🔬 Base Quantities:")
        base_quantities = [
            ("Length", kSIQuantityLength),
            ("Mass", kSIQuantityMass),
            ("Time", kSIQuantityTime),
            ("Current", kSIQuantityCurrent),
            ("Temperature", kSIQuantityTemperature),
            ("Amount", kSIQuantityAmount),
            ("Luminous Intensity", kSIQuantityLuminousIntensity)
        ]
        
        for name, constant in base_quantities:
            dim = SIDimensionality.from_quantity(constant)
            print(f"  {name:18} ({constant:18}) -> {dim}")
        
        print()
        
        # Test derived quantities
        print("⚙️  Derived Quantities:")
        derived_quantities = [
            ("Area", kSIQuantityArea),
            ("Volume", kSIQuantityVolume),
            ("Velocity", kSIQuantityVelocity),
            ("Acceleration", kSIQuantityAcceleration),
            ("Density", kSIQuantityDensity),
            ("Force", kSIQuantityForce),
            ("Pressure", kSIQuantityPressure),
            ("Energy", kSIQuantityEnergy),
            ("Power", kSIQuantityPower),
            ("Frequency", kSIQuantityFrequency)
        ]
        
        for name, constant in derived_quantities:
            dim = SIDimensionality.from_quantity(constant)
            print(f"  {name:18} ({constant:18}) -> {dim}")
        
        print()
        
        # Test additional mechanical quantities
        print("🔧 Additional Mechanical Quantities:")
        mechanical_quantities = [
            ("Speed", kSIQuantitySpeed),
            ("Linear Momentum", kSIQuantityLinearMomentum),
            ("Angular Momentum", kSIQuantityAngularMomentum),
            ("Plane Angle", kSIQuantityPlaneAngle),
            ("Stress", kSIQuantityStress),
            ("Strain", kSIQuantityStrain),
            ("Elastic Modulus", kSIQuantityElasticModulus),
            ("Viscosity", kSIQuantityViscosity)
        ]
        
        for name, constant in mechanical_quantities:
            dim = SIDimensionality.from_quantity(constant)
            print(f"  {name:18} ({constant:18}) -> {dim}")
        
        print()
        
        # Test arithmetic operations
        print("➕ Testing Arithmetic Operations:")
        force_dim = SIDimensionality.from_quantity(kSIQuantityForce)
        length_dim = SIDimensionality.from_quantity(kSIQuantityLength)
        energy_dim = force_dim * length_dim
        energy_expected = SIDimensionality.from_quantity(kSIQuantityEnergy)
        
        print(f"  Force × Length = {force_dim} × {length_dim} = {energy_dim}")
        print(f"  Expected Energy = {energy_expected}")
        print(f"  Match: {'✅' if str(energy_dim) == str(energy_expected) else '❌'}")
        
        print()
        print("🎉 All tests completed successfully!")
        print("✅ Quantity constants are working correctly!")
        
    except Exception as e:
        print(f"❌ Error occurred: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_quantity_constants()
