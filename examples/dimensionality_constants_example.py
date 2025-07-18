#!/usr/bin/env python3
"""
Example: Using SIDimensionality with quantity constants

This example demonstrates how to use the QUANTITY_* constants with 
SIDimensionality.from_quantity() to avoid typos and improve code readability.
"""

from rmnpy.sitypes import SIDimensionality
from rmnpy.sitypes import (
    # Base quantities
    QUANTITY_LENGTH, QUANTITY_MASS, QUANTITY_TIME, QUANTITY_CURRENT,
    QUANTITY_TEMPERATURE, QUANTITY_AMOUNT, QUANTITY_LUMINOUS_INTENSITY,
    
    # Mechanical quantities
    QUANTITY_FORCE, QUANTITY_ENERGY, QUANTITY_POWER, QUANTITY_VELOCITY,
    QUANTITY_ACCELERATION, QUANTITY_PRESSURE, QUANTITY_DENSITY,
    
    # Electrical quantities
    QUANTITY_VOLTAGE, QUANTITY_RESISTANCE, QUANTITY_CHARGE,
    
    # Dimensionless
    QUANTITY_DIMENSIONLESS
)

def main():
    print("=== SIDimensionality Quantity Constants Example ===\n")
    
    print("1. Using constants (recommended approach):")
    print("   Advantages: IDE autocomplete, typo prevention, cleaner code")
    
    # Create dimensionalities using constants
    force_dim = SIDimensionality.from_quantity(QUANTITY_FORCE)
    energy_dim = SIDimensionality.from_quantity(QUANTITY_ENERGY)
    power_dim = SIDimensionality.from_quantity(QUANTITY_POWER)
    velocity_dim = SIDimensionality.from_quantity(QUANTITY_VELOCITY)
    
    print(f"   Force:    {force_dim}")
    print(f"   Energy:   {energy_dim}")
    print(f"   Power:    {power_dim}")
    print(f"   Velocity: {velocity_dim}")
    print()
    
    print("2. Available quantity constants:")
    constants = [
        # Base quantities
        ("QUANTITY_LENGTH", QUANTITY_LENGTH),
        ("QUANTITY_MASS", QUANTITY_MASS),
        ("QUANTITY_TIME", QUANTITY_TIME),
        ("QUANTITY_CURRENT", QUANTITY_CURRENT),
        ("QUANTITY_TEMPERATURE", QUANTITY_TEMPERATURE),
        ("QUANTITY_AMOUNT", QUANTITY_AMOUNT),
        ("QUANTITY_LUMINOUS_INTENSITY", QUANTITY_LUMINOUS_INTENSITY),
        
        # Mechanical quantities
        ("QUANTITY_FORCE", QUANTITY_FORCE),
        ("QUANTITY_ENERGY", QUANTITY_ENERGY),
        ("QUANTITY_POWER", QUANTITY_POWER),
        ("QUANTITY_VELOCITY", QUANTITY_VELOCITY),
        ("QUANTITY_ACCELERATION", QUANTITY_ACCELERATION),
        ("QUANTITY_PRESSURE", QUANTITY_PRESSURE),
        ("QUANTITY_DENSITY", QUANTITY_DENSITY),
        
        # Electrical quantities
        ("QUANTITY_VOLTAGE", QUANTITY_VOLTAGE),
        ("QUANTITY_RESISTANCE", QUANTITY_RESISTANCE),
        ("QUANTITY_CHARGE", QUANTITY_CHARGE),
        
        # Dimensionless
        ("QUANTITY_DIMENSIONLESS", QUANTITY_DIMENSIONLESS),
    ]
    
    print("   Base quantities:")
    for name, value in constants[:7]:
        print(f"     {name:<30} = '{value}'")
    
    print("\n   Mechanical quantities:")
    for name, value in constants[7:14]:
        print(f"     {name:<30} = '{value}'")
    
    print("\n   Electrical quantities:")
    for name, value in constants[14:17]:
        print(f"     {name:<30} = '{value}'")
    
    print("\n   Dimensionless:")
    for name, value in constants[17:]:
        print(f"     {name:<30} = '{value}'")
    
    print("\n3. Mathematical operations with dimensionalities:")
    
    # Create some basic dimensions
    length = SIDimensionality.from_quantity(QUANTITY_LENGTH)
    mass = SIDimensionality.from_quantity(QUANTITY_MASS)
    time = SIDimensionality.from_quantity(QUANTITY_TIME)
    
    # Calculate derived quantities
    acceleration = length / (time ** 2)
    force_calculated = mass * acceleration
    
    print(f"   Length:                  {length}")
    print(f"   Mass:                    {mass}")
    print(f"   Time:                    {time}")
    print(f"   Acceleration (L/T²):     {acceleration}")
    print(f"   Force (M·L/T²):          {force_calculated}")
    
    print("\n4. Error handling:")
    try:
        # This will fail due to typo
        SIDimensionality.from_quantity("forse")  # Should be "force"
        print("   ERROR: Typo was not caught!")
    except Exception as e:
        print(f"   Good: Typo caught - {type(e).__name__}")
        print(f"   Message: {str(e)[:60]}...")
    
    print("\n5. Best practices:")
    print("   - Use QUANTITY_* constants instead of string literals")
    print("   - Import only the constants you need")
    print("   - IDE will provide autocomplete for constants")
    print("   - Constants prevent runtime errors from typos")
    
    print("\n=== Example completed successfully! ===")

if __name__ == "__main__":
    main()
