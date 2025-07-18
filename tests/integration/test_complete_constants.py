#!/usr/bin/env python3
"""Test script to verify that all SITypes quantity constants are available."""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

try:
    # Try importing all the constants
    from rmnpy.sitypes import (
        SIDimensionality,
        kSIQuantityDimensionless, kSIQuantityLength, kSIQuantityInverseLength,
        kSIQuantityWavenumber, kSIQuantityLengthRatio, kSIQuantityPlaneAngle,
        kSIQuantityMass, kSIQuantityInverseMass, kSIQuantityMassRatio,
        kSIQuantityTime, kSIQuantityInverseTime, kSIQuantityFrequency,
        kSIQuantityRadioactivity, kSIQuantityTimeRatio, kSIQuantityFrequencyRatio,
        kSIQuantityInverseTimeSquared, kSIQuantityCurrent, kSIQuantityInverseCurrent,
        kSIQuantityCurrentRatio, kSIQuantityTemperature, kSIQuantityInverseTemperature,
        kSIQuantityTemperatureRatio, kSIQuantityTemperatureGradient, kSIQuantityAmount,
        kSIQuantityInverseAmount, kSIQuantityAmountRatio, kSIQuantityLuminousIntensity,
        kSIQuantityInverseLuminousIntensity, kSIQuantityLuminousIntensityRatio,
        kSIQuantityArea, kSIQuantityInverseArea, kSIQuantityAreaRatio, kSIQuantitySolidAngle,
        kSIQuantityVolume, kSIQuantityInverseVolume, kSIQuantityVolumeRatio, kSIQuantitySpeed,
        kSIQuantityVelocity, kSIQuantityLinearMomentum, kSIQuantityAngularMomentum, kSIQuantityMomentOfInertia,
        kSIQuantityAcceleration, kSIQuantityMassFlowRate, kSIQuantityMassFlux, kSIQuantityDensity,
        kSIQuantitySpecificGravity, kSIQuantitySpecificSurfaceArea, kSIQuantitySurfaceAreaToVolumeRatio,
        kSIQuantitySurfaceDensity, kSIQuantitySpecificVolume, kSIQuantityCurrentDensity,
        kSIQuantityMagneticFieldStrength, kSIQuantityLuminance, kSIQuantityRefractiveIndex,
        kSIQuantityFluidity, kSIQuantityMomentOfForce, kSIQuantitySurfaceTension, kSIQuantitySurfaceEnergy,
        kSIQuantityAngularSpeed, kSIQuantityAngularVelocity, kSIQuantityAngularAcceleration,
        kSIQuantityHeatFluxDensity, kSIQuantityIrradiance, kSIQuantitySpectralRadiantFluxDensity,
        kSIQuantityHeatCapacity, kSIQuantityEntropy, kSIQuantitySpecificHeatCapacity,
        kSIQuantitySpecificEntropy, kSIQuantitySpecificEnergy, kSIQuantityThermalConductance,
        kSIQuantityThermalConductivity, kSIQuantityEnergyDensity, kSIQuantityElectricFieldStrength,
        kSIQuantityElectricFieldGradient, kSIQuantityElectricChargeDensity, kSIQuantitySurfaceChargeDensity,
        kSIQuantityElectricFlux, kSIQuantityElectricFluxDensity, kSIQuantityElectricDisplacement,
        kSIQuantityPermittivity, kSIQuantityPermeability, kSIQuantityMolarEnergy, kSIQuantityMolarEntropy,
        kSIQuantityMolarHeatCapacity, kSIQuantityMolarMass, kSIQuantityMolality, kSIQuantityDiffusionFlux,
        kSIQuantityMassToChargeRatio, kSIQuantityChargeToMassRatio, kSIQuantityRadiationExposure,
        kSIQuantityAbsorbedDoseRate, kSIQuantityRadiantIntensity, kSIQuantitySpectralRadiantIntensity,
        kSIQuantityRadiance, kSIQuantitySpectralRadiance, kSIQuantityPorosity, kSIQuantityAngularFrequency,
        kSIQuantityForce, kSIQuantityTorque, kSIQuantityPressure, kSIQuantityStress, kSIQuantityElasticModulus,
        kSIQuantityCompressibility, kSIQuantityStressOpticCoefficient, kSIQuantityPressureGradient,
        kSIQuantityEnergy, kSIQuantitySpectralRadiantEnergy, kSIQuantityPower, kSIQuantitySpectralPower,
        kSIQuantityVolumePowerDensity, kSIQuantitySpecificPower, kSIQuantityRadiantFlux,
        kSIQuantityElectricCharge, kSIQuantityAmountOfElectricity, kSIQuantityElectricPotentialDifference,
        kSIQuantityElectromotiveForce, kSIQuantityElectricPolarizability, kSIQuantityElectricDipoleMoment,
        kSIQuantityVoltage, kSIQuantityCapacitance, kSIQuantityElectricResistance,
        kSIQuantityElectricResistancePerLength, kSIQuantityElectricResistivity, kSIQuantityElectricConductance,
        kSIQuantityElectricConductivity, kSIQuantityElectricalMobility, kSIQuantityMolarConductivity,
        kSIQuantityMagneticDipoleMoment, kSIQuantityMagneticDipoleMomentRatio, kSIQuantityMagneticFlux,
        kSIQuantityMagneticFluxDensity, kSIQuantityMolarMagneticSusceptibility, kSIQuantityInverseMagneticFluxDensity,
        kSIQuantityMagneticFieldGradient, kSIQuantityInductance, kSIQuantityLuminousFlux,
        kSIQuantityLuminousFluxDensity, kSIQuantityLuminousEnergy, kSIQuantityIlluminance,
        kSIQuantityAbsorbedDose, kSIQuantityDoseEquivalent, kSIQuantityCatalyticActivity,
        kSIQuantityCatalyticActivityConcentration, kSIQuantityCatalyticActivityContent, kSIQuantityAction,
        kSIQuantityReducedAction, kSIQuantityKinematicViscosity, kSIQuantityDiffusionCoefficient,
        kSIQuantityCirculation, kSIQuantityDynamicViscosity, kSIQuantityAmountConcentration,
        kSIQuantityMassConcentration, kSIQuantityChargePerAmount, kSIQuantityGravitationalConstant,
        kSIQuantityLengthPerVolume, kSIQuantityVolumePerLength, kSIQuantityVolumetricFlowRate,
        kSIQuantityFrequencyPerMagneticFluxDensity, kSIQuantityPowerPerLuminousFlux, kSIQuantityLuminousEfficacy,
        kSIQuantityRockPermeability, kSIQuantityGyromagneticRatio, kSIQuantityHeatTransferCoefficient,
        kSIQuantityGasPermeance, kSIQuantityPowerPerAreaPerTemperatureToFourthPower,
        kSIQuantityFirstHyperPolarizability, kSIQuantitySecondHyperPolarizability, kSIQuantityElectricQuadrupoleMoment,
        kSIQuantityMagnetizability, kSIQuantitySecondRadiationConstant, kSIQuantityWavelengthDisplacementConstant,
        kSIQuantityFineStructureConstant, kSIQuantityRatePerAmountConcentrationPerTime
    )
    
    print("✅ All SITypes quantity constants imported successfully!")
    
    # Test a few representative constants
    test_constants = [
        ("kSIQuantityPressure", kSIQuantityPressure),
        ("kSIQuantityElectricQuadrupoleMoment", kSIQuantityElectricQuadrupoleMoment),
        ("kSIQuantityLinearMomentum", kSIQuantityLinearMomentum),
        ("kSIQuantityKinematicViscosity", kSIQuantityKinematicViscosity),
        ("kSIQuantityGravitationalConstant", kSIQuantityGravitationalConstant),
        ("kSIQuantityFineStructureConstant", kSIQuantityFineStructureConstant),
    ]
    
    print("\n📋 Testing representative constants:")
    for name, constant in test_constants:
        try:
            dim = SIDimensionality.from_quantity(constant)
            print(f"  {name}: {dim.symbol}")
        except Exception as e:
            print(f"  {name}: ERROR - {e}")
    
    # Count total available constants
    import rmnpy.sitypes
    all_constants = [name for name in dir(rmnpy.sitypes) if name.startswith('kSIQuantity')]
    print(f"\n📊 Total available constants: {len(all_constants)}")
    
    # Test with string vs constant
    print("\n🔍 Testing string vs constant equivalence:")
    try:
        dim_str = SIDimensionality.from_quantity("pressure")
        dim_const = SIDimensionality.from_quantity(kSIQuantityPressure)
        print(f"  String 'pressure': {dim_str.symbol}")
        print(f"  Constant kSIQuantityPressure: {dim_const.symbol}")
        print(f"  Are equivalent: {dim_str.symbol == dim_const.symbol}")
    except Exception as e:
        print(f"  Error in comparison: {e}")
    
except ImportError as e:
    print(f"❌ Import error: {e}")
    sys.exit(1)
except Exception as e:
    print(f"❌ Error: {e}")
    sys.exit(1)
