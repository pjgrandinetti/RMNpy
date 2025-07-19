"""
The sitypes submodule for RMNpy contains wrappers for SITypes library.

This includes:
- SIScalar: Scalar SI quantities with value and units
- SIDimensionality: Physical dimensionalities with quantity constants
- SIUnit: Unit definitions and operations
"""

from .scalar import SIScalar
from .dimensionality import SIDimensionality
from .unit import SIUnit

# Since the C constants are #define macros using STR(), we can't directly expose them
# Instead, we'll create Python constants with the same string values
# These can be used with the from_quantity() method

# Base quantity constants (matching the C macro strings)
kSIQuantityLength = "length"
kSIQuantityMass = "mass"
kSIQuantityTime = "time"
kSIQuantityCurrent = "current"
kSIQuantityTemperature = "temperature"

# Common derived quantity constants
kSIQuantityArea = "area"
kSIQuantityVolume = "volume"
kSIQuantityVelocity = "velocity"
kSIQuantityAcceleration = "acceleration"
kSIQuantityDensity = "density"
kSIQuantityForce = "force"
kSIQuantityPressure = "pressure"
kSIQuantityEnergy = "energy"
kSIQuantityPower = "power"
kSIQuantityFrequency = "frequency"
kSIQuantityElectricPotential = "electric_potential"

__all__ = [
    "SIScalar",
    "SIDimensionality",
    "SIUnit",
    # Base quantity constants for from_quantity() method
    "kSIQuantityLength", "kSIQuantityMass", "kSIQuantityTime",
    "kSIQuantityCurrent", "kSIQuantityTemperature",
    # Derived quantity constants for from_quantity() method
    "kSIQuantityArea", "kSIQuantityVolume", "kSIQuantityVelocity",
    "kSIQuantityAcceleration", "kSIQuantityDensity",
    "kSIQuantityForce", "kSIQuantityPressure", "kSIQuantityEnergy",
    "kSIQuantityPower", "kSIQuantityFrequency", "kSIQuantityElectricPotential"
]
