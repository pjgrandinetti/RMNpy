"""
SIDimensionality Constants Usage Example

This example demonstrates how to use the kSIQuantity* constants with 
SIDimensionality.from_quantity() to avoid typos and improve code readability.
"""

from rmnpy.sitypes import SIDimensionality
from rmnpy.sitypes import (
    # Base quantities
    kSIQuantityLength, kSIQuantityMass, kSIQuantityTime, kSIQuantityCurrent,
    kSIQuantityTemperature,
    
    # Derived quantities
    kSIQuantityForce, kSIQuantityEnergy, kSIQuantityPower, kSIQuantityVelocity,
    kSIQuantityAcceleration, kSIQuantityPressure, kSIQuantityDensity,
    kSIQuantityFrequency, kSIQuantityArea, kSIQuantityVolume
)


def main():
    print("=== SIDimensionality Quantity Constants Example ===\n")
    
    print("1. Using kSIQuantity* constants (recommended approach):")
    print("   Advantages: IDE autocomplete, typo prevention, cleaner code")
    
    # Create dimensionalities using constants
    force_dim = SIDimensionality.from_quantity(kSIQuantityForce)
    energy_dim = SIDimensionality.from_quantity(kSIQuantityEnergy)
    power_dim = SIDimensionality.from_quantity(kSIQuantityPower)
    velocity_dim = SIDimensionality.from_quantity(kSIQuantityVelocity)
    
    print(f"   Force:    {force_dim}")
    print(f"   Energy:   {energy_dim}")
    print(f"   Power:    {power_dim}")
    print(f"   Velocity: {velocity_dim}")
    print()
    
    print("2. Available quantity constants:")
    constants = [
        # Base quantities
        ("kSIQuantityLength", kSIQuantityLength),
        ("kSIQuantityMass", kSIQuantityMass),
        ("kSIQuantityTime", kSIQuantityTime),
        ("kSIQuantityCurrent", kSIQuantityCurrent),
        ("kSIQuantityTemperature", kSIQuantityTemperature),
        
        # Derived quantities
        ("kSIQuantityArea", kSIQuantityArea),
        ("kSIQuantityVolume", kSIQuantityVolume),
        ("kSIQuantityVelocity", kSIQuantityVelocity),
        ("kSIQuantityAcceleration", kSIQuantityAcceleration),
        ("kSIQuantityDensity", kSIQuantityDensity),
        ("kSIQuantityForce", kSIQuantityForce),
        ("kSIQuantityPressure", kSIQuantityPressure),
        ("kSIQuantityEnergy", kSIQuantityEnergy),
        ("kSIQuantityPower", kSIQuantityPower),
        ("kSIQuantityFrequency", kSIQuantityFrequency)
    ]
    
    for name, constant in constants:
        try:
            dim = SIDimensionality.from_quantity(constant)
            print(f"   {name:<25} -> {dim}")
        except Exception as e:
            print(f"   {name:<25} -> Error: {e}")
    print()
    
    print("3. Comparison with direct string usage:")
    print("   Direct strings are error-prone and lack IDE support")
    print("   Constants version:")
    print(f"      time = SIDimensionality.from_quantity(kSIQuantityTime)")
    print("   Direct string version:")
    print(f"      time = SIDimensionality.from_quantity('time')  # Could typo as 'tiem'")
    print()
    
    # Demonstrate actual usage
    time = SIDimensionality.from_quantity(kSIQuantityTime)
    length = SIDimensionality.from_quantity(kSIQuantityLength)
    
    # Create derived dimensionalities through operations
    area = length * length  # L²
    volume = area * length  # L³
    velocity_derived = length / time  # LT⁻¹
    
    print("4. Creating derived dimensionalities:")
    print(f"   Length:         {length}")
    print(f"   Time:           {time}")
    print(f"   Area (L²):      {area}")
    print(f"   Volume (L³):    {volume}")
    print(f"   Velocity:       {velocity_derived}")
    print()
    
    print("5. Verifying constant equivalence:")
    velocity_constant = SIDimensionality.from_quantity(kSIQuantityVelocity)
    print(f"   From constant:  {velocity_constant}")
    print(f"   From operation: {velocity_derived}")
    print(f"   Are equal:      {velocity_constant == velocity_derived}")


if __name__ == "__main__":
    main()
