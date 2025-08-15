"""
SI Quantity Names - Auto-generated from SIDimensionality.h

This file contains all SI quantity name constants extracted from the C header file.
Do not edit manually - regenerate using extract_si_constants.py.

Generated from: SIDimensionality.h
"""

# Import the C API to get OCStringRef constants

from rmnpy._c_api.sitypes cimport *


# Define STR function to return Python string
cdef inline object STR(const char* cStr):
    return cStr.decode('utf-8')

# All quantity name constants as Python strings
kSIQuantityAbsorbedDose = STR("absorbed dose")
kSIQuantityAbsorbedDoseRate = STR("absorbed dose rate")
kSIQuantityAcceleration = STR("acceleration")
kSIQuantityAction = STR("action")
kSIQuantityAmount = STR("amount")
kSIQuantityAmountConcentration = STR("amount concentration")
kSIQuantityAmountOfElectricity = STR("amount of electricity")
kSIQuantityAmountRatio = STR("amount ratio")
kSIQuantityAngularAcceleration = STR("angular acceleration")
kSIQuantityAngularFrequency = STR("angular frequency")
kSIQuantityAngularMomentum = STR("angular momentum")
kSIQuantityAngularSpeed = STR("angular speed")
kSIQuantityAngularVelocity = STR("angular velocity")
kSIQuantityArea = STR("area")
kSIQuantityAreaRatio = STR("area ratio")
kSIQuantityCapacitance = STR("capacitance")
kSIQuantityCatalyticActivity = STR("catalytic activity")
kSIQuantityCatalyticActivityConcentration = STR("catalytic activity concentration")
kSIQuantityCatalyticActivityContent = STR("catalytic activity content")
kSIQuantityChargePerAmount = STR("charge per amount")
kSIQuantityChargeToMassRatio = STR("charge to mass ratio")
kSIQuantityCirculation = STR("circulation")
kSIQuantityCompressibility = STR("compressibility")
kSIQuantityCurrent = STR("current")
kSIQuantityCurrentDensity = STR("current density")
kSIQuantityCurrentRatio = STR("current ratio")
kSIQuantityDensity = STR("density")
kSIQuantityDiffusionCoefficient = STR("diffusion coefficient")
kSIQuantityDiffusionFlux = STR("diffusion flux")
kSIQuantityDimensionless = STR("dimensionless")
kSIQuantityDoseEquivalent = STR("dose equivalent")
kSIQuantityDynamicViscosity = STR("dynamic viscosity")
kSIQuantityElasticModulus = STR("elastic modulus")
kSIQuantityElectricCharge = STR("electric charge")
kSIQuantityElectricChargeDensity = STR("electric charge density")
kSIQuantityElectricConductance = STR("electric conductance")
kSIQuantityElectricConductivity = STR("electric conductivity")
kSIQuantityElectricDipoleMoment = STR("electric dipole moment")
kSIQuantityElectricDisplacement = STR("electric displacement")
kSIQuantityElectricFieldGradient = STR("electric field gradient")
kSIQuantityElectricFieldStrength = STR("electric field strength")
kSIQuantityElectricFlux = STR("electric flux")
kSIQuantityElectricFluxDensity = STR("electric flux density")
kSIQuantityElectricPolarizability = STR("electric polarizability")
kSIQuantityElectricPotentialDifference = STR("electric potential difference")
kSIQuantityElectricQuadrupoleMoment = STR("electric quadrupole moment")
kSIQuantityElectricResistance = STR("electric resistance")
kSIQuantityElectricResistancePerLength = STR("electric resistance per length")
kSIQuantityElectricResistivity = STR("electric resistivity")
kSIQuantityElectricalMobility = STR("electrical mobility")
kSIQuantityElectromotiveForce = STR("electromotive force")
kSIQuantityEnergy = STR("energy")
kSIQuantityEnergyDensity = STR("energy density")
kSIQuantityEntropy = STR("entropy")
kSIQuantityFineStructureConstant = STR("fine structure constant")
kSIQuantityFirstHyperPolarizability = STR("first hyperpolarizability")
kSIQuantityFluidity = STR("fluidity")
kSIQuantityForce = STR("force")
kSIQuantityFrequency = STR("frequency")
kSIQuantityFrequencyPerMagneticFluxDensity = STR("frequency per magnetic flux density")
kSIQuantityFrequencyRatio = STR("frequency ratio")
kSIQuantityGasPermeance = STR("gas permeance")
kSIQuantityGravitationalConstant = STR("gravitational constant")
kSIQuantityGyromagneticRatio = STR("gyromagnetic ratio")
kSIQuantityHeatCapacity = STR("heat capacity")
kSIQuantityHeatFluxDensity = STR("heat flux density")
kSIQuantityHeatTransferCoefficient = STR("heat transfer coefficient")
kSIQuantityIlluminance = STR("illuminance")
kSIQuantityInductance = STR("inductance")
kSIQuantityInverseAmount = STR("inverse amount")
kSIQuantityInverseArea = STR("inverse area")
kSIQuantityInverseCurrent = STR("inverse current")
kSIQuantityInverseLength = STR("inverse length")
kSIQuantityInverseLuminousIntensity = STR("inverse luminous intensity")
kSIQuantityInverseMagneticFluxDensity = STR("inverse magnetic flux density")
kSIQuantityInverseMass = STR("inverse mass")
kSIQuantityInverseTemperature = STR("inverse temperature")
kSIQuantityInverseTime = STR("inverse time")
kSIQuantityInverseTimeSquared = STR("inverse time squared")
kSIQuantityInverseVolume = STR("inverse volume")
kSIQuantityIrradiance = STR("irradiance")
kSIQuantityKinematicViscosity = STR("kinematic viscosity")
kSIQuantityLength = STR("length")
kSIQuantityLengthPerVolume = STR("distance per volume")
kSIQuantityLengthRatio = STR("length ratio")
kSIQuantityLinearMomentum = STR("linear momentum")
kSIQuantityLuminance = STR("luminance")
kSIQuantityLuminousEfficacy = STR("luminous efficacy")
kSIQuantityLuminousEnergy = STR("luminous energy")
kSIQuantityLuminousFlux = STR("luminous flux")
kSIQuantityLuminousFluxDensity = STR("luminous flux density")
kSIQuantityLuminousIntensity = STR("luminous intensity")
kSIQuantityLuminousIntensityRatio = STR("luminous intensity ratio")
kSIQuantityMagneticDipoleMoment = STR("magnetic dipole moment")
kSIQuantityMagneticDipoleMomentRatio = STR("magnetic dipole moment ratio")
kSIQuantityMagneticFieldGradient = STR("magnetic field gradient")
kSIQuantityMagneticFieldStrength = STR("magnetic field strength")
kSIQuantityMagneticFlux = STR("magnetic flux")
kSIQuantityMagneticFluxDensity = STR("magnetic flux density")
kSIQuantityMagnetizability = STR("magnetizability")
kSIQuantityMass = STR("mass")
kSIQuantityMassConcentration = STR("mass concentration")
kSIQuantityMassFlowRate = STR("mass flow rate")
kSIQuantityMassFlux = STR("mass flux")
kSIQuantityMassRatio = STR("mass ratio")
kSIQuantityMassToChargeRatio = STR("mass to charge ratio")
kSIQuantityMolality = STR("molality")
kSIQuantityMolarConductivity = STR("molar conductivity")
kSIQuantityMolarEnergy = STR("molar energy")
kSIQuantityMolarEntropy = STR("molar entropy")
kSIQuantityMolarHeatCapacity = STR("molar heat capacity")
kSIQuantityMolarMagneticSusceptibility = STR("molar magnetic susceptibility")
kSIQuantityMolarMass = STR("molar mass")
kSIQuantityMomentOfForce = STR("moment of force")
kSIQuantityMomentOfInertia = STR("moment of inertia")
kSIQuantityPermeability = STR("permeability")
kSIQuantityPermittivity = STR("permittivity")
kSIQuantityPlaneAngle = STR("plane angle")
kSIQuantityPorosity = STR("porosity")
kSIQuantityPower = STR("power")
kSIQuantityPowerPerAreaPerTemperatureToFourthPower = STR("stefan-boltzmann constant")
kSIQuantityPowerPerLuminousFlux = STR("power per luminous flux")
kSIQuantityPressure = STR("pressure")
kSIQuantityPressureGradient = STR("pressure gradient")
kSIQuantityRadiance = STR("radiance")
kSIQuantityRadiantFlux = STR("radiant flux")
kSIQuantityRadiantIntensity = STR("radiant intensity")
kSIQuantityRadiationExposure = STR("radiation exposure")
kSIQuantityRadioactivity = STR("radioactivity")
kSIQuantityRatePerAmountConcentrationPerTime = STR("inverse amount concentration inverse time")
kSIQuantityReducedAction = STR("reduced action")
kSIQuantityRefractiveIndex = STR("refractive index")
kSIQuantityRockPermeability = STR("rock permeability")
kSIQuantitySecondHyperPolarizability = STR("second hyperpolarizability")
kSIQuantitySecondRadiationConstant = STR("second radiation constant")
kSIQuantitySolidAngle = STR("solid angle")
kSIQuantitySpecificEnergy = STR("specific energy")
kSIQuantitySpecificEntropy = STR("specific entropy")
kSIQuantitySpecificGravity = STR("specific gravity")
kSIQuantitySpecificHeatCapacity = STR("specific heat capacity")
kSIQuantitySpecificPower = STR("specific power")
kSIQuantitySpecificSurfaceArea = STR("specific surface area")
kSIQuantitySpecificVolume = STR("specific volume")
kSIQuantitySpectralPower = STR("spectral power")
kSIQuantitySpectralRadiance = STR("spectral radiance")
kSIQuantitySpectralRadiantEnergy = STR("spectral radiant energy")
kSIQuantitySpectralRadiantFluxDensity = STR("spectral radiant flux density")
kSIQuantitySpectralRadiantIntensity = STR("spectral radiant intensity")
kSIQuantitySpeed = STR("speed")
kSIQuantityStress = STR("stress")
kSIQuantityStressOpticCoefficient = STR("stress-optic coefficient")
kSIQuantitySurfaceAreaToVolumeRatio = STR("surface area to volume ratio")
kSIQuantitySurfaceChargeDensity = STR("surface charge density")
kSIQuantitySurfaceDensity = STR("surface density")
kSIQuantitySurfaceEnergy = STR("surface energy")
kSIQuantitySurfaceTension = STR("surface tension")
kSIQuantityTemperature = STR("temperature")
kSIQuantityTemperatureGradient = STR("temperature gradient")
kSIQuantityTemperatureRatio = STR("temperature ratio")
kSIQuantityThermalConductance = STR("thermal conductance")
kSIQuantityThermalConductivity = STR("thermal conductivity")
kSIQuantityTime = STR("time")
kSIQuantityTimeRatio = STR("time ratio")
kSIQuantityTorque = STR("torque")
kSIQuantityVelocity = STR("velocity")
kSIQuantityVoltage = STR("voltage")
kSIQuantityVolume = STR("volume")
kSIQuantityVolumePerLength = STR("volume per length")
kSIQuantityVolumePowerDensity = STR("volume power density")
kSIQuantityVolumeRatio = STR("volume ratio")
kSIQuantityVolumetricFlowRate = STR("volumetric flow rate")
kSIQuantityWavelengthDisplacementConstant = STR("wavelength displacement constant")
kSIQuantityWavenumber = STR("wavenumber")

__all__ = [
    "kSIQuantityAbsorbedDose",
    "kSIQuantityAbsorbedDoseRate",
    "kSIQuantityAcceleration",
    "kSIQuantityAction",
    "kSIQuantityAmount",
    "kSIQuantityAmountConcentration",
    "kSIQuantityAmountOfElectricity",
    "kSIQuantityAmountRatio",
    "kSIQuantityAngularAcceleration",
    "kSIQuantityAngularFrequency",
    "kSIQuantityAngularMomentum",
    "kSIQuantityAngularSpeed",
    "kSIQuantityAngularVelocity",
    "kSIQuantityArea",
    "kSIQuantityAreaRatio",
    "kSIQuantityCapacitance",
    "kSIQuantityCatalyticActivity",
    "kSIQuantityCatalyticActivityConcentration",
    "kSIQuantityCatalyticActivityContent",
    "kSIQuantityChargePerAmount",
    "kSIQuantityChargeToMassRatio",
    "kSIQuantityCirculation",
    "kSIQuantityCompressibility",
    "kSIQuantityCurrent",
    "kSIQuantityCurrentDensity",
    "kSIQuantityCurrentRatio",
    "kSIQuantityDensity",
    "kSIQuantityDiffusionCoefficient",
    "kSIQuantityDiffusionFlux",
    "kSIQuantityDimensionless",
    "kSIQuantityDoseEquivalent",
    "kSIQuantityDynamicViscosity",
    "kSIQuantityElasticModulus",
    "kSIQuantityElectricCharge",
    "kSIQuantityElectricChargeDensity",
    "kSIQuantityElectricConductance",
    "kSIQuantityElectricConductivity",
    "kSIQuantityElectricDipoleMoment",
    "kSIQuantityElectricDisplacement",
    "kSIQuantityElectricFieldGradient",
    "kSIQuantityElectricFieldStrength",
    "kSIQuantityElectricFlux",
    "kSIQuantityElectricFluxDensity",
    "kSIQuantityElectricPolarizability",
    "kSIQuantityElectricPotentialDifference",
    "kSIQuantityElectricQuadrupoleMoment",
    "kSIQuantityElectricResistance",
    "kSIQuantityElectricResistancePerLength",
    "kSIQuantityElectricResistivity",
    "kSIQuantityElectricalMobility",
    "kSIQuantityElectromotiveForce",
    "kSIQuantityEnergy",
    "kSIQuantityEnergyDensity",
    "kSIQuantityEntropy",
    "kSIQuantityFineStructureConstant",
    "kSIQuantityFirstHyperPolarizability",
    "kSIQuantityFluidity",
    "kSIQuantityForce",
    "kSIQuantityFrequency",
    "kSIQuantityFrequencyPerMagneticFluxDensity",
    "kSIQuantityFrequencyRatio",
    "kSIQuantityGasPermeance",
    "kSIQuantityGravitationalConstant",
    "kSIQuantityGyromagneticRatio",
    "kSIQuantityHeatCapacity",
    "kSIQuantityHeatFluxDensity",
    "kSIQuantityHeatTransferCoefficient",
    "kSIQuantityIlluminance",
    "kSIQuantityInductance",
    "kSIQuantityInverseAmount",
    "kSIQuantityInverseArea",
    "kSIQuantityInverseCurrent",
    "kSIQuantityInverseLength",
    "kSIQuantityInverseLuminousIntensity",
    "kSIQuantityInverseMagneticFluxDensity",
    "kSIQuantityInverseMass",
    "kSIQuantityInverseTemperature",
    "kSIQuantityInverseTime",
    "kSIQuantityInverseTimeSquared",
    "kSIQuantityInverseVolume",
    "kSIQuantityIrradiance",
    "kSIQuantityKinematicViscosity",
    "kSIQuantityLength",
    "kSIQuantityLengthPerVolume",
    "kSIQuantityLengthRatio",
    "kSIQuantityLinearMomentum",
    "kSIQuantityLuminance",
    "kSIQuantityLuminousEfficacy",
    "kSIQuantityLuminousEnergy",
    "kSIQuantityLuminousFlux",
    "kSIQuantityLuminousFluxDensity",
    "kSIQuantityLuminousIntensity",
    "kSIQuantityLuminousIntensityRatio",
    "kSIQuantityMagneticDipoleMoment",
    "kSIQuantityMagneticDipoleMomentRatio",
    "kSIQuantityMagneticFieldGradient",
    "kSIQuantityMagneticFieldStrength",
    "kSIQuantityMagneticFlux",
    "kSIQuantityMagneticFluxDensity",
    "kSIQuantityMagnetizability",
    "kSIQuantityMass",
    "kSIQuantityMassConcentration",
    "kSIQuantityMassFlowRate",
    "kSIQuantityMassFlux",
    "kSIQuantityMassRatio",
    "kSIQuantityMassToChargeRatio",
    "kSIQuantityMolality",
    "kSIQuantityMolarConductivity",
    "kSIQuantityMolarEnergy",
    "kSIQuantityMolarEntropy",
    "kSIQuantityMolarHeatCapacity",
    "kSIQuantityMolarMagneticSusceptibility",
    "kSIQuantityMolarMass",
    "kSIQuantityMomentOfForce",
    "kSIQuantityMomentOfInertia",
    "kSIQuantityPermeability",
    "kSIQuantityPermittivity",
    "kSIQuantityPlaneAngle",
    "kSIQuantityPorosity",
    "kSIQuantityPower",
    "kSIQuantityPowerPerAreaPerTemperatureToFourthPower",
    "kSIQuantityPowerPerLuminousFlux",
    "kSIQuantityPressure",
    "kSIQuantityPressureGradient",
    "kSIQuantityRadiance",
    "kSIQuantityRadiantFlux",
    "kSIQuantityRadiantIntensity",
    "kSIQuantityRadiationExposure",
    "kSIQuantityRadioactivity",
    "kSIQuantityRatePerAmountConcentrationPerTime",
    "kSIQuantityReducedAction",
    "kSIQuantityRefractiveIndex",
    "kSIQuantityRockPermeability",
    "kSIQuantitySecondHyperPolarizability",
    "kSIQuantitySecondRadiationConstant",
    "kSIQuantitySolidAngle",
    "kSIQuantitySpecificEnergy",
    "kSIQuantitySpecificEntropy",
    "kSIQuantitySpecificGravity",
    "kSIQuantitySpecificHeatCapacity",
    "kSIQuantitySpecificPower",
    "kSIQuantitySpecificSurfaceArea",
    "kSIQuantitySpecificVolume",
    "kSIQuantitySpectralPower",
    "kSIQuantitySpectralRadiance",
    "kSIQuantitySpectralRadiantEnergy",
    "kSIQuantitySpectralRadiantFluxDensity",
    "kSIQuantitySpectralRadiantIntensity",
    "kSIQuantitySpeed",
    "kSIQuantityStress",
    "kSIQuantityStressOpticCoefficient",
    "kSIQuantitySurfaceAreaToVolumeRatio",
    "kSIQuantitySurfaceChargeDensity",
    "kSIQuantitySurfaceDensity",
    "kSIQuantitySurfaceEnergy",
    "kSIQuantitySurfaceTension",
    "kSIQuantityTemperature",
    "kSIQuantityTemperatureGradient",
    "kSIQuantityTemperatureRatio",
    "kSIQuantityThermalConductance",
    "kSIQuantityThermalConductivity",
    "kSIQuantityTime",
    "kSIQuantityTimeRatio",
    "kSIQuantityTorque",
    "kSIQuantityVelocity",
    "kSIQuantityVoltage",
    "kSIQuantityVolume",
    "kSIQuantityVolumePerLength",
    "kSIQuantityVolumePowerDensity",
    "kSIQuantityVolumeRatio",
    "kSIQuantityVolumetricFlowRate",
    "kSIQuantityWavelengthDisplacementConstant",
    "kSIQuantityWavenumber",
]
