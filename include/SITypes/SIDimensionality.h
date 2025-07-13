//
//  SIDimensionality.h
//  SITypes
//
//  Created by philip on 6/7/17.
//  Copyright © 2017 PhySy Ltd. All rights reserved.
//

#ifndef SIDIMENSIONALITY_H
#define SIDIMENSIONALITY_H

#include "SILibrary.h"

void SITypesShutdown(void);

/*!
 * @file SIDimensionality.h
 * @brief Interface for representing and manipulating SI physical dimensionalities.
 *
 * The SIDimensionality API provides an immutable interface for physical dimensionalities,
 * supporting all seven SI base dimensions: length, mass, time, electric current, temperature,
 * amount of substance, and luminous intensity. Dimensionalities may be combined,
 * reduced, raised to powers, parsed from strings, and tested for equality or compatibility.
 *
 * ## Concepts and Rationale
 * - **Dimensionality Model:** Each SIDimensionality encodes a rational exponent for each SI base dimension.
 * - **Base and Derived:** Represents base (fundamental) dimensionalities and all derived/compound types.
 * - **Immutability:** All objects are immutable and may be safely shared between threads.
 * - **Parsing:** Expressions like `"L^2*M/T^2"` or `"T^-2"` are parsed and canonicalized.
 * - **Compatibility:** Provides strict equality, reduced-form (physical) compatibility, and classification (base/derived).
 *
 * ## API Features
 * - **Accessors:** Query exponents, canonical symbols, and indices.
 * - **Parsing:** Create dimensionalities from string expressions or known quantity names.
 * - **Algebra:** Combine, divide, reduce, raise to powers, or take roots.
 * - **Tests:** Compare for strict equality or reduced (physical) compatibility, and test for special types (dimensionless, base, derived).
 * - **Constants:** Defines hundreds of named dimensionalities for physical quantities.
 *
 * ## Usage Notes
 * - **Memory Management:** All returned SIDimensionalityRef objects are immutable and managed by the library.
 *   Do **not** retain or release them unless explicitly stated.
 * - **Thread Safety:** All operations are thread-safe on distinct objects.
 * - **Pointer Safety:** All pointers must be non-NULL unless documented.
 *
 * @author Philip Grandinetti
 */

#ifdef __cplusplus
extern "C" {
#endif

/** @cond INTERNAL */
/** @brief Index constants for the seven SI base dimensions. */
typedef enum {
    kSILengthIndex = 0,
    kSIMassIndex = 1,
    kSITimeIndex = 2,
    kSICurrentIndex = 3,
    kSITemperatureIndex = 4,
    kSIAmountIndex = 5,
    kSILuminousIntensityIndex = 6,
} SIBaseDimensionIndex;
/** @endcond */

/** @brief Parse an SI dimensionality expression into a cached, immutable object. */
SIDimensionalityRef SIDimensionalityParseExpression(OCStringRef expression, OCStringRef *error);

#pragma mark Accessors

/** @brief Returns the unique type identifier for SIDimensionality objects. */
OCTypeID SIDimensionalityGetTypeID(void);

/** @brief Gets the canonical symbol representation of a dimensionality. */
OCStringRef SIDimensionalityGetSymbol(SIDimensionalityRef theDim);

/** @brief Gets the numerator of the rational exponent for a base dimension. */
uint8_t SIDimensionalityGetNumExpAtIndex(SIDimensionalityRef theDim, SIBaseDimensionIndex index);

/** @brief Gets the denominator of the rational exponent for a base dimension. */
uint8_t SIDimensionalityGetDenExpAtIndex(SIDimensionalityRef theDim, SIBaseDimensionIndex index);

/** @brief Gets the reduced exponent (num - den) for a base dimension. */
int8_t SIDimensionalityReducedExponentAtIndex(SIDimensionalityRef theDim, SIBaseDimensionIndex index);

/**
 * @brief Create a JSON representation of an SIDimensionality.
 *
 * The returned JSON is a string node containing the canonical symbol,
 * e.g., "m/s^2". Caller owns the returned cJSON object.
 *
 * @param dim An SIDimensionalityRef instance.
 * @return A cJSON string object, or cJSON null on failure.
 */
cJSON *SIDimensionalityCreateJSON(SIDimensionalityRef dim);

/**
 * @brief Create an SIDimensionality object from a JSON string node.
 *
 * The input must be a JSON string representing a valid dimensionality symbol,
 * e.g., "m/s^2". If parsing fails, returns NULL.
 *
 * @param json A cJSON string object.
 * @return An SIDimensionalityRef or NULL on failure.
 */
SIDimensionalityRef SIDimensionalityFromJSON(cJSON *json);

#pragma mark Tests

/** @brief Returns true if two dimensionalities are strictly equal. */
bool SIDimensionalityEqual(SIDimensionalityRef theDim1, SIDimensionalityRef theDim2);

/** @brief Returns true if dimensionality is physically dimensionless. */
bool SIDimensionalityIsDimensionless(SIDimensionalityRef theDim);

/** @brief Returns true if dimensionality is derived. */
bool SIDimensionalityIsDerived(SIDimensionalityRef theDim);

/** @brief Returns true if dimensionless and not derived by cancellation. */
bool SIDimensionalityIsDimensionlessAndNotDerived(SIDimensionalityRef theDim);

/** @brief Returns true if dimensionless by cancellation of base symbols. */
bool SIDimensionalityIsDimensionlessAndDerived(SIDimensionalityRef theDim);

/** @brief Returns true if dimensionality matches exactly one SI base dimension. */
bool SIDimensionalityIsBaseDimensionality(SIDimensionalityRef theDim);

/** @brief Returns true if two dimensionalities have the same reduced exponents. */
bool SIDimensionalityHasSameReducedDimensionality(SIDimensionalityRef theDim1, SIDimensionalityRef theDim2);

/** @brief Returns true if dimensionality has the specified reduced exponents. */
bool SIDimensionalityHasReducedExponents(SIDimensionalityRef theDim,
                                         int8_t length_exponent,
                                         int8_t mass_exponent,
                                         int8_t time_exponent,
                                         int8_t current_exponent,
                                         int8_t temperature_exponent,
                                         int8_t amount_exponent,
                                         int8_t luminous_intensity_exponent);

#pragma mark Operations

/** @brief Returns the canonical dimensionless dimensionality. */
SIDimensionalityRef SIDimensionalityDimensionless(void);

/** @brief Returns the dimensionality for a given base dimension index. */
SIDimensionalityRef SIDimensionalityForBaseDimensionIndex(SIBaseDimensionIndex index);

/** @brief Returns the dimensionality for a single-character base symbol. */
SIDimensionalityRef SIDimensionalityWithBaseDimensionSymbol(OCStringRef symbol, OCStringRef *error);

/** @brief Maps a quantity name to its dimensionality. */
SIDimensionalityRef SIDimensionalityForQuantity(OCStringRef quantity, OCStringRef *error);

/** @brief Returns a dimensionality with all exponents reduced to lowest terms. */
SIDimensionalityRef SIDimensionalityByReducing(SIDimensionalityRef theDimensionality);

/** @brief Returns the nth-root of a dimensionality, or NULL and error if invalid. */
SIDimensionalityRef SIDimensionalityByTakingNthRoot(SIDimensionalityRef theDim, uint8_t root, OCStringRef *error);

/** @brief Multiplies two dimensionalities and reduces to lowest terms. */
SIDimensionalityRef SIDimensionalityByMultiplying(SIDimensionalityRef theDim1, SIDimensionalityRef theDim2, OCStringRef *error);

/** @brief Multiplies two dimensionalities without reducing exponents. */
SIDimensionalityRef SIDimensionalityByMultiplyingWithoutReducing(SIDimensionalityRef theDim1, SIDimensionalityRef theDim2, OCStringRef *error);

/** @brief Divides one dimensionality by another, reduces result. */
SIDimensionalityRef SIDimensionalityByDividing(SIDimensionalityRef theDim1, SIDimensionalityRef theDim2);

/** @brief Divides one dimensionality by another, does not reduce exponents. */
SIDimensionalityRef SIDimensionalityByDividingWithoutReducing(SIDimensionalityRef theDim1, SIDimensionalityRef theDim2);

/** @brief Raises a dimensionality to a real power, reduces exponents. */
SIDimensionalityRef SIDimensionalityByRaisingToPower(SIDimensionalityRef theDim, double power, OCStringRef *error);

/** @brief Raises a dimensionality to a real power, without reducing exponents. */
SIDimensionalityRef SIDimensionalityByRaisingToPowerWithoutReducing(SIDimensionalityRef theDim, double power, OCStringRef *error);

/** @brief Returns all quantity names matching this dimensionality exactly. */
OCArrayRef SIDimensionalityCreateArrayOfQuantities(SIDimensionalityRef theDim);

/** @brief Returns all quantity names with the same reduced dimensionality. */
OCArrayRef SIDimensionalityCreateArrayOfQuantitiesWithSameReducedDimensionality(SIDimensionalityRef theDim);

/** @brief Returns all built-in dimensionalities with the same reduced dimensionality. */
OCArrayRef SIDimensionalityCreateArrayWithSameReducedDimensionality(SIDimensionalityRef theDim);

/** @brief Returns an array of quantity names mapped to the given dimensionality. */
OCArrayRef SIDimensionalityCreateArrayOfQuantityNames(SIDimensionalityRef dim);

/** @brief Returns all quantity names associated with dimensionalities that reduce to the same form as the input. */
OCArrayRef SIDimensionalityCreateArrayOfQuantityNamesWithSameReducedDimensionality(SIDimensionalityRef dim);

#pragma mark String Output

/** @brief Prints a concise representation of the dimensionality to stdout. */
void SIDimensionalityShow(SIDimensionalityRef theDim);

/** @brief Prints a detailed, annotated report of the dimensionality to stdout. */
void SIDimensionalityShowFull(SIDimensionalityRef theDim);

/**
 * @defgroup SIQuantities Physical Quantity Macros
 * @brief Dimensionality constants for various physical quantities.
 *
 * These constants are used as quantity names for mapping to specific dimensionalities.
 * They are string constants (OCStringRef) for use in the API.
 *
 * Example:
 * ```
 * OCStringRef error = NULL;
 * SIDimensionalityRef dim = SIDimensionalityForQuantity(kSIQuantityPressure, &error);
 * if (error) {
 *     // Handle error
 *     OCRelease(error);
 * }
 * ```
 *
 * @{
 */
#define kSIQuantityDimensionless                        STR("dimensionless")
#define kSIQuantityLength                               STR("length")
#define kSIQuantityInverseLength                        STR("inverse length")
#define kSIQuantityWavenumber                           STR("wavenumber")
#define kSIQuantityLengthRatio                          STR("length ratio")
#define kSIQuantityPlaneAngle                           STR("plane angle")
#define kSIQuantityMass                                 STR("mass")
#define kSIQuantityInverseMass                          STR("inverse mass")
#define kSIQuantityMassRatio                            STR("mass ratio")
#define kSIQuantityTime                                 STR("time")
#define kSIQuantityInverseTime                          STR("inverse time")
#define kSIQuantityFrequency                            STR("frequency")
#define kSIQuantityRadioactivity                        STR("radioactivity")
#define kSIQuantityTimeRatio                            STR("time ratio")
#define kSIQuantityFrequencyRatio                       STR("frequency ratio")
#define kSIQuantityInverseTimeSquared                   STR("inverse time squared")
#define kSIQuantityCurrent                              STR("current")
#define kSIQuantityInverseCurrent                       STR("inverse current")
#define kSIQuantityCurrentRatio                         STR("current ratio")
#define kSIQuantityTemperature                          STR("temperature")
#define kSIQuantityInverseTemperature                   STR("inverse temperature")
#define kSIQuantityTemperatureRatio                     STR("temperature ratio")
#define kSIQuantityTemperatureGradient                  STR("temperature gradient")
#define kSIQuantityAmount                               STR("amount")
#define kSIQuantityInverseAmount                        STR("inverse amount")
#define kSIQuantityAmountRatio                          STR("amount ratio")
#define kSIQuantityLuminousIntensity                    STR("luminous intensity")
#define kSIQuantityInverseLuminousIntensity             STR("inverse luminous intensity")
#define kSIQuantityLuminousIntensityRatio               STR("luminous intensity ratio")
#define kSIQuantityArea                                 STR("area")
#define kSIQuantityInverseArea                          STR("inverse area")
#define kSIQuantityAreaRatio                            STR("area ratio")
#define kSIQuantitySolidAngle                           STR("solid angle")
#define kSIQuantityVolume                               STR("volume")
#define kSIQuantityInverseVolume                        STR("inverse volume")
#define kSIQuantityVolumeRatio                          STR("volume ratio")
#define kSIQuantitySpeed                                STR("speed")
#define kSIQuantityVelocity                             STR("velocity")
#define kSIQuantityLinearMomentum                       STR("linear momentum")
#define kSIQuantityAngularMomentum                      STR("angular momentum")
#define kSIQuantityMomentOfInertia                      STR("moment of inertia")
#define kSIQuantityAcceleration                         STR("acceleration")
#define kSIQuantityMassFlowRate                         STR("mass flow rate")
#define kSIQuantityMassFlux                             STR("mass flux")
#define kSIQuantityDensity                              STR("density")
#define kSIQuantitySpecificGravity                      STR("specific gravity")
#define kSIQuantitySpecificSurfaceArea                  STR("specific surface area")
#define kSIQuantitySurfaceAreaToVolumeRatio             STR("surface area to volume ratio")
#define kSIQuantitySurfaceDensity                       STR("surface density")
#define kSIQuantitySpecificVolume                       STR("specific volume")
#define kSIQuantityCurrentDensity                       STR("current density")
#define kSIQuantityMagneticFieldStrength                STR("magnetic field strength")
#define kSIQuantityLuminance                            STR("luminance")
#define kSIQuantityRefractiveIndex                      STR("refractive index")
#define kSIQuantityFluidity                             STR("fluidity")
#define kSIQuantityMomentOfForce                        STR("moment of force")
#define kSIQuantitySurfaceTension                       STR("surface tension")
#define kSIQuantitySurfaceEnergy                        STR("surface energy")
#define kSIQuantityAngularSpeed                         STR("angular speed")
#define kSIQuantityAngularVelocity                      STR("angular velocity")
#define kSIQuantityAngularAcceleration                  STR("angular acceleration")
#define kSIQuantityHeatFluxDensity                      STR("heat flux density")
#define kSIQuantityIrradiance                           STR("irradiance")
#define kSIQuantitySpectralRadiantFluxDensity           STR("spectral radiant flux density")
#define kSIQuantityHeatCapacity                         STR("heat capacity")
#define kSIQuantityEntropy                              STR("entropy")
#define kSIQuantitySpecificHeatCapacity                 STR("specific heat capacity")
#define kSIQuantitySpecificEntropy                      STR("specific entropy")
#define kSIQuantitySpecificEnergy                       STR("specific energy")
#define kSIQuantityThermalConductance                   STR("thermal conductance")
#define kSIQuantityThermalConductivity                  STR("thermal conductivity")
#define kSIQuantityEnergyDensity                        STR("energy density")
#define kSIQuantityElectricFieldStrength                STR("electric field strength")
#define kSIQuantityElectricFieldGradient                STR("electric field gradient")
#define kSIQuantityElectricChargeDensity                STR("electric charge density")
#define kSIQuantitySurfaceChargeDensity                 STR("surface charge density")
#define kSIQuantityElectricFlux                         STR("electric flux")
#define kSIQuantityElectricFluxDensity                  STR("electric flux density")
#define kSIQuantityElectricDisplacement                 STR("electric displacement")
#define kSIQuantityPermittivity                         STR("permittivity")
#define kSIQuantityPermeability                         STR("permeability")
#define kSIQuantityMolarEnergy                          STR("molar energy")
#define kSIQuantityMolarEntropy                         STR("molar entropy")
#define kSIQuantityMolarHeatCapacity                    STR("molar heat capacity")
#define kSIQuantityMolarMass                            STR("molar mass")
#define kSIQuantityMolality                             STR("molality")
#define kSIQuantityDiffusionFlux                        STR("diffusion flux")
#define kSIQuantityMassToChargeRatio                    STR("mass to charge ratio")
#define kSIQuantityChargeToMassRatio                    STR("charge to mass ratio")
#define kSIQuantityRadiationExposure                    STR("radiation exposure")
#define kSIQuantityAbsorbedDoseRate                     STR("absorbed dose rate")
#define kSIQuantityRadiantIntensity                     STR("radiant intensity")
#define kSIQuantitySpectralRadiantIntensity             STR("spectral radiant intensity")
#define kSIQuantityRadiance                             STR("radiance")
#define kSIQuantitySpectralRadiance                     STR("spectral radiance")
#define kSIQuantityPorosity                             STR("porosity")
#define kSIQuantityAngularFrequency                     STR("angular frequency")
#define kSIQuantityForce                                STR("force")
#define kSIQuantityTorque                               STR("torque")
#define kSIQuantityPressure                             STR("pressure")
#define kSIQuantityStress                               STR("stress")
#define kSIQuantityElasticModulus                       STR("elastic modulus")
#define kSIQuantityCompressibility                      STR("compressibility")
#define kSIQuantityStressOpticCoefficient               STR("stress-optic coefficient")
#define kSIQuantityPressureGradient                     STR("pressure gradient")
#define kSIQuantityEnergy                               STR("energy")
#define kSIQuantitySpectralRadiantEnergy                STR("spectral radiant energy")
#define kSIQuantityPower                                STR("power")
#define kSIQuantitySpectralPower                        STR("spectral power")
#define kSIQuantityVolumePowerDensity                   STR("volume power density")
#define kSIQuantitySpecificPower                        STR("specific power")
#define kSIQuantityRadiantFlux                          STR("radiant flux")
#define kSIQuantityElectricCharge                       STR("electric charge")
#define kSIQuantityAmountOfElectricity                  STR("amount of electricity")
#define kSIQuantityElectricPotentialDifference          STR("electric potential difference")
#define kSIQuantityElectromotiveForce                   STR("electromotive force")
#define kSIQuantityElectricPolarizability               STR("electric polarizability")
#define kSIQuantityElectricDipoleMoment                 STR("electric dipole moment")
#define kSIQuantityVoltage                              STR("voltage")
#define kSIQuantityCapacitance                          STR("capacitance")
#define kSIQuantityElectricResistance                   STR("electric resistance")
#define kSIQuantityElectricResistancePerLength          STR("electric resistance per length")
#define kSIQuantityElectricResistivity                  STR("electric resistivity")
#define kSIQuantityElectricConductance                  STR("electric conductance")
#define kSIQuantityElectricConductivity                 STR("electric conductivity")
#define kSIQuantityElectricalMobility                   STR("electrical mobility")
#define kSIQuantityMolarConductivity                    STR("molar conductivity")
#define kSIQuantityMagneticDipoleMoment                 STR("magnetic dipole moment")
#define kSIQuantityMagneticDipoleMomentRatio            STR("magnetic dipole moment ratio")
#define kSIQuantityMagneticFlux                         STR("magnetic flux")
#define kSIQuantityMagneticFluxDensity                  STR("magnetic flux density")
#define kSIQuantityMolarMagneticSusceptibility          STR("molar magnetic susceptibility")
#define kSIQuantityInverseMagneticFluxDensity           STR("inverse magnetic flux density")
#define kSIQuantityMagneticFieldGradient                STR("magnetic field gradient")
#define kSIQuantityInductance                           STR("inductance")
#define kSIQuantityLuminousFlux                         STR("luminous flux")
#define kSIQuantityLuminousFluxDensity                  STR("luminous flux density")
#define kSIQuantityLuminousEnergy                       STR("luminous energy")
#define kSIQuantityIlluminance                          STR("illuminance")
#define kSIQuantityAbsorbedDose                         STR("absorbed dose")
#define kSIQuantityDoseEquivalent                       STR("dose equivalent")
#define kSIQuantityCatalyticActivity                    STR("catalytic activity")
#define kSIQuantityCatalyticActivityConcentration       STR("catalytic activity concentration")
#define kSIQuantityCatalyticActivityContent             STR("catalytic activity content")
#define kSIQuantityAction                               STR("action")
#define kSIQuantityReducedAction                        STR("reduced action")
#define kSIQuantityKinematicViscosity                   STR("kinematic viscosity")
#define kSIQuantityDiffusionCoefficient                 STR("diffusion coefficient")
#define kSIQuantityCirculation                          STR("circulation")
#define kSIQuantityDynamicViscosity                     STR("dynamic viscosity")
#define kSIQuantityAmountConcentration                  STR("amount concentration")
#define kSIQuantityMassConcentration                    STR("mass concentration")
#define kSIQuantityChargePerAmount                      STR("charge per amount")
#define kSIQuantityGravitationalConstant                STR("gravitational constant")
#define kSIQuantityLengthPerVolume                      STR("distance per volume")
#define kSIQuantityVolumePerLength                      STR("volume per length")
#define kSIQuantityVolumetricFlowRate                   STR("volumetric flow rate")
#define kSIQuantityFrequencyPerMagneticFluxDensity      STR("frequency per magnetic flux density")
#define kSIQuantityPowerPerLuminousFlux                 STR("power per luminous flux")
#define kSIQuantityLuminousEfficacy                     STR("luminous efficacy")
#define kSIQuantityRockPermeability                     STR("rock permeability")
#define kSIQuantityGyromagneticRatio                    STR("gyromagnetic ratio")
#define kSIQuantityHeatTransferCoefficient              STR("heat transfer coefficient")
#define kSIQuantityGasPermeance                         STR("gas permeance")
#define kSIQuantityPowerPerAreaPerTemperatureToFourthPower        STR("stefan-boltzmann constant")
#define kSIQuantityFirstHyperPolarizability             STR("first hyperpolarizability")
#define kSIQuantitySecondHyperPolarizability            STR("second hyperpolarizability")
#define kSIQuantityElectricQuadrupoleMoment             STR("electric quadrupole moment")
#define kSIQuantityMagnetizability                      STR("magnetizability")
#define kSIQuantitySecondRadiationConstant              STR("second radiation constant")
#define kSIQuantityWavelengthDisplacementConstant       STR("wavelength displacement constant")
#define kSIQuantityFineStructureConstant                STR("fine structure constant")
#define kSIQuantityRatePerAmountConcentrationPerTime    STR("inverse amount concentration inverse time")

/** @} */ // end of SIQuantities group

#ifdef __cplusplus
}
#endif

#endif /* SIDIMENSIONALITY_H */