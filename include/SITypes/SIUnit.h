//
//  SIUnit.h
//  SITypes
//
//  Created by philip on 6/7/17.
//  Copyright © 2017 PhySy Ltd. All rights reserved.
//

#ifndef SIUnit_h
#define SIUnit_h

#include "SILibrary.h"

/*!
 * @file SIUnit.h
 * @brief Interface for defining, manipulating, and comparing SI and derived units.
 *
 * The SIUnit API provides a comprehensive, type-safe interface for immutable
 * **physical unit definitions** in the International System of Units (SI), including
 * support for both SI base units and coherent derived units, as well as common non-SI units.
 *
 * ## Concepts and Rationale
 * - **Unit Object Model:** An SIUnit represents a physical unit, including its symbol,
 *   SI prefix, dimensional exponents (for the seven SI base quantities), and scale factor.
 *   Units are opaque and immutable references.
 * - **Dimensional Analysis:** Every SIUnit encodes full dimensionality, allowing
 *   for strict unit checking and compatibility enforcement at runtime.
 * - **Prefixes and Composition:** Supports all standard SI prefixes and algebraic
 *   unit composition (multiplication, division, powers, and roots).
 * - **Canonicalization:** Derived and composite units are always simplified to a
 *   canonical form for robust comparison, formatting, and conversion.
 *
 * ## API Features
 * - **Accessors:** Retrieve unit symbol, name, dimensionality, and other metadata.
 * - **Parsing and Formatting:** Parse units from strings or symbols and generate
 *   human-readable names and formatted symbols.
 * - **Unit Arithmetic:** Compose units by multiplication, division, exponentiation,
 *   or reduction to lowest terms.
 * - **Comparison and Equivalence:** Test for dimensional equivalence, full equality
 *   (including prefix and symbol), and conversion factors.
 * - **Unit Collections:** Query units by dimensionality or physical quantity.
 * - **Constants:** Provides standard symbols and physical constants as macros.
 * - **Library Management:** Manage the global registry of units and library-scoped settings
 *   (e.g., US vs. UK volume units).
 *
 * ## Usage Notes
 * - **Immutability:** All SIUnit objects are immutable and may be safely shared
 *   between threads.
 * - **Memory Management:** Functions with `Create` or `Copy` in the name return
 *   new OCType objects. **Ownership of these objects is transferred to the caller,**
 *   who must call `OCRelease` when the object is no longer needed.
 *   All other functions return non-owned references unless otherwise stated.
 * - **Pointer Safety:** All pointer arguments must be non-NULL unless documented.
 * - **Thread Safety:** All functions are thread-safe when operating on distinct units
 *   or library objects.
 * - **Intended Use:** This interface is designed for scientific, engineering, or
 *   educational software requiring precise, robust, and extensible unit handling.
 *
 * @author Philip Grandinetti
 */

/** @cond INTERNAL */
/** @brief SI Prefix enumeration. */
typedef enum {
    kSIPrefixYocto = -24,
    kSIPrefixZepto = -21,
    kSIPrefixAtto = -18,
    kSIPrefixFemto = -15,
    kSIPrefixPico = -12,
    kSIPrefixNano = -9,
    kSIPrefixMicro = -6,
    kSIPrefixMilli = -3,
    kSIPrefixCenti = -2,
    kSIPrefixDeci = -1,
    kSIPrefixNone = 0,
    kSIPrefixDeca = 1,
    kSIPrefixHecto = 2,
    kSIPrefixKilo = 3,
    kSIPrefixMega = 6,
    kSIPrefixGiga = 9,
    kSIPrefixTera = 12,
    kSIPrefixPeta = 15,
    kSIPrefixExa = 18,
    kSIPrefixZetta = 21,
    kSIPrefixYotta = 24
} SIPrefix;

#define kSIUnitMeter             STR("meter")
#define kSIUnitMeters            STR("meters")
#define kSIUnitGram              STR("gram")
#define kSIUnitGrams             STR("grams")
#define kSIUnitSecond            STR("second")
#define kSIUnitSeconds           STR("seconds")
#define kSIUnitAmpere            STR("ampere")
#define kSIUnitAmperes           STR("amperes")
#define kSIUnitKelvin            STR("kelvin")
#define kSIUnitMole              STR("mole")
#define kSIUnitMoles             STR("moles")
#define kSIUnitCandela           STR("candela")
#define kSIUnitCandelas          STR("candelas")

#define kSIMinute       60.
#define kSIHour         3600
#define kSIDay          86400
#define kSIWeek         604800
#define kSIMonth        2629800
#define kSIYear         31557600
#define kSIDecade       315576000
#define kSICentury      3155760000
#define kSIMillennium   31557600000

#define kSIPi                       3.141592653589793
#define kSIEulersNumber             2.718281828459045

#define kSISpeedOfLight             299792458
#define kSIElementaryCharge         1.602176634e-19
#define kSIPlanckConstant           6.62607015e-34
#define kSIBoltmannConstant         1.380649e-23
#define kSIAvogadroConstant         6.02214076e23
#define kSIStefanBoltzmannConstant  5.670374419e-8
#define kSIWeinDisplacementConstant 2.897771955e-3
#define kSIElectronMass             9.109383701528e-31
#define kSIProtonMass               1.6726219236951e-27
#define kSINeutronMass              1.6749274980495e-27
#define kSIMuonMass                 1.883531627459132e-28
#define kSIAtomicMassConstant       1.6605390666050e-27
#define kSIAlphaParticleMass        6.64465723082e-27
#define kSIGravitationalConstant     6.6743015e-11

#define kSIElectricConstant         8.854187817620389e-12  // Defined as 1/sqrt(c_0^2*µ_0)

// Above updated for 2019 mass definitions

#define kSIElectronMagneticMoment   -928.4764620e-26
#define kSIElectronGFactor          -2.00231930436182

#define kSIProtonMagneticMoment     1.4106067873e-26
#define kSIProtonGFactor            5.585694702

#define kSINeutronMagneticMoment    -0.96623650e-26
#define kSINeutronGFactor           -3.82608545

#define kSIMuonMagneticMoment       -4.49044826e-26
#define kSIMuonGFactor              -2.0023318418

#define kSIGravityAcceleration      9.80665

/** @endcond */

#pragma mark Accessors

/** @brief Returns the unique type identifier for SIUnit objects. */
OCTypeID SIUnitGetTypeID(void);

cJSON *SIUnitCreateJSON(SIUnitRef unit);

/** @brief Gets the physical dimensionality for a unit. */
SIDimensionalityRef SIUnitGetDimensionality(SIUnitRef theUnit);

/** @brief Gets the SI prefix in the numerator for a given base dimension. */
SIPrefix SIUnitGetNumeratorPrefixAtIndex(SIUnitRef theUnit, uint8_t index);

/** @brief Gets the SI prefix in the denominator for a given base dimension. */
SIPrefix SIUnitGetDenominatorPrefixAtIndex(SIUnitRef theUnit, uint8_t index);

/** @brief Copies the base (singular) name for a unit. */
OCStringRef SIUnitCopyRootName(SIUnitRef theUnit);

/** @brief Copies the plural base name for a unit. */
OCStringRef SIUnitCopyRootPluralName(SIUnitRef theUnit);

/** @brief Copies the base symbol for a unit. */
OCStringRef SIUnitCopyRootSymbol(SIUnitRef theUnit);

/** @brief Checks if the unit’s root symbol may be modified by an SI prefix. */
bool SIUnitAllowsSIPrefix(SIUnitRef theUnit);

/** @brief Gets the default SI prefix for the unit’s base symbol. */
SIPrefix SIUnitGetRootSymbolPrefix(SIUnitRef theUnit);

/** @brief Checks if the unit’s root symbol is a special-case SI symbol. */
bool SIUnitGetIsSpecialSISymbol(SIUnitRef theUnit);

#pragma mark Tests

/** @brief Returns true if unit is a coherent SI base unit. */
bool SIUnitIsCoherentSIBaseUnit(SIUnitRef theUnit);

/** @brief Returns true if unit is a base root unit (no prefix). */
bool SIUnitIsSIBaseRootUnit(SIUnitRef theUnit);

/** @brief Returns true if unit is a base unit or prefix variant. */
bool SIUnitIsSIBaseUnit(SIUnitRef theUnit);

/** @brief Returns true if unit is a coherent SI derived unit. */
bool SIUnitIsCoherentDerivedUnit(SIUnitRef theUnit);

/** @brief Returns true if unit is the dimensionless underived unit. */
bool SIUnitIsDimensionlessAndUnderived(SIUnitRef theUnit);

/** @brief Returns true if unit has no net physical dimension. */
bool SIUnitIsDimensionless(SIUnitRef theUnit);

/** @brief Returns true if both units are equivalent without scaling. */
bool SIUnitAreEquivalentUnits(SIUnitRef theUnit1, SIUnitRef theUnit2);

/** @brief Returns true if both units are fully equal. */
bool SIUnitEqual(SIUnitRef theUnit1, SIUnitRef theUnit2);

#pragma mark Operations

/** @brief Returns the SI unit for the dimensionless, underived quantity. */
SIUnitRef SIUnitDimensionlessAndUnderived(void);

/** @brief Creates an array of all units strictly equivalent to a given unit. */
OCArrayRef SIUnitCreateArrayOfEquivalentUnits(SIUnitRef theUnit);

/** @brief Returns equivalent unit with the shortest symbol. */
SIUnitRef SIUnitFindEquivalentUnitWithShortestSymbol(SIUnitRef theUnit);

/** @brief Creates an array of units for a given quantity. */
OCArrayRef SIUnitCreateArrayOfUnitsForQuantity(OCStringRef quantity);

/** @brief Creates an array of units for a given dimensionality. */
OCArrayRef SIUnitCreateArrayOfUnitsForDimensionality(SIDimensionalityRef theDimensionality);

/** @brief Creates an array of units with same reduced dimensionality. */
OCArrayRef SIUnitCreateArrayOfUnitsForSameReducedDimensionality(SIDimensionalityRef theDimensionality);

/** @brief Creates an array of units dimensionally equivalent to a given unit. */
OCArrayRef SIUnitCreateArrayOfConversionUnits(SIUnitRef theUnit);

/** @brief Gets the scale factor to convert a non-SI root unit to coherent SI. */
double SIUnitGetScaleNonSIToCoherentSI(SIUnitRef theUnit);

/** @brief Creates the full human-readable name for a unit. */
OCStringRef SIUnitCreateName(SIUnitRef theUnit);

/** @brief Creates the plural name for a unit. */
OCStringRef SIUnitCreatePluralName(SIUnitRef theUnit);

/** @brief Copies the symbol for a unit, including any prefix. */
OCStringRef SIUnitCopySymbol(SIUnitRef theUnit);

/** @brief Gets scale factor to convert value in this unit to coherent SI unit. */
double SIUnitScaleToCoherentSIUnit(SIUnitRef theUnit);

/** @brief Creates the symbol for a unit. */
OCStringRef SIUnitCreateSymbol(SIUnitRef theUnit);

/** @brief Finds a coherent SI unit for a given dimensionality. */
SIUnitRef SIUnitFindCoherentSIUnitWithDimensionality(SIDimensionalityRef theDimensionality);

/** @brief Finds coherent SI unit for an arbitrary unit, updating multiplier. */
SIUnitRef SIUnitFindCoherentSIUnit(SIUnitRef input, double *unit_multiplier);

/** @brief Returns the Nth root of a unit, updating multiplier, with error. */
SIUnitRef SIUnitByTakingNthRoot(SIUnitRef input, uint8_t root, double *unit_multiplier, OCStringRef *error);

/** @brief Returns the reduced (lowest integer exponents) form of a unit. */
SIUnitRef SIUnitByReducing(SIUnitRef theUnit, double *unit_multiplier);

/** @brief Multiplies two units, reduces result, updates multiplier, with error. */
SIUnitRef SIUnitByMultiplying(SIUnitRef theUnit1, SIUnitRef theUnit2, double *unit_multiplier, OCStringRef *error);

/** @brief Multiplies two units, does not reduce exponents, with error. */
SIUnitRef SIUnitByMultiplyingWithoutReducing(SIUnitRef theUnit1, SIUnitRef theUnit2, double *unit_multiplier, OCStringRef *error);

/** @brief Divides one unit by another, reduces result, updates multiplier. */
SIUnitRef SIUnitByDividing(SIUnitRef theUnit1, SIUnitRef theUnit2, double *unit_multiplier);

/** @brief Divides one unit by another, does not reduce exponents. */
SIUnitRef SIUnitByDividingWithoutReducing(SIUnitRef theUnit1, SIUnitRef theUnit2, double *unit_multiplier);

/** @brief Raises a unit to a power, reduces exponents, updates multiplier, with error. */
SIUnitRef SIUnitByRaisingToPower(SIUnitRef input, double power, double *unit_multiplier, OCStringRef *error);

/** @brief Raises a unit to a power without reducing exponents, with error. */
SIUnitRef SIUnitByRaisingToPowerWithoutReducing(SIUnitRef input, double power, double *unit_multiplier, OCStringRef *error);

/** @brief Finds a unit by canonical name. */
SIUnitRef SIUnitFindWithName(OCStringRef input);

/** @brief Finds a unit by underived (base) symbol. */
SIUnitRef SIUnitFindWithUnderivedSymbol(OCStringRef symbol);

/** @brief Parses a symbol and returns the corresponding unit, updating multiplier. */
SIUnitRef SIUnitFromExpression(OCStringRef expression, double *unit_multiplier, OCStringRef *error);

/** @brief Creates array of all units defined for a given quantity. */
OCArrayRef SIUnitCreateArrayForQuantity(OCStringRef quantity);

/** @brief Creates dictionary of units for a given dimensionality. */
OCDictionaryRef SIUnitCreateDictionaryOfUnitsWithDimensionality(SIDimensionalityRef theDimensionality);

/** @brief Creates dictionary of units with the same reduced dimensionality. */
OCDictionaryRef SIUnitCreateDictionaryOfUnitsWithSameReducedDimensionality(SIDimensionalityRef theDimensionality);

/** @brief Computes the conversion factor between two compatible units. */
double SIUnitConversion(SIUnitRef initialUnit, SIUnitRef finalUnit);

#pragma mark Strings and Archiving

/** @brief Prints a one-line summary of the unit. */
void SIUnitShow(SIUnitRef theUnit);

/** @brief Prints a multi-line, detailed report of the unit. */
void SIUnitShowFull(SIUnitRef theUnit);

#pragma mark Library

/** @brief Returns true if library uses US volume units, false for UK/Imperial. */
bool SIUnitsLibraryImperialVolumes(void);

/** @brief Sets library to use US or UK/Imperial volume symbols. */
void SIUnitsLibrarySetImperialVolumes(bool value);

/** @brief Returns a mutable copy of the current units library. */
OCMutableDictionaryRef SIUnitGetUnitsLib(void);

/** @brief Replaces the global units library. */
void SIUnitSetLibrary(OCMutableDictionaryRef newUnitsLibrary);

/** @brief Prints a one-line summary of each unit in the library. */
void SIUnitLibraryShow(void);

/** @brief Prints a multi-line description of each unit in the library. */
void SIUnitLibraryShowFull(void);

/** @brief Returns all units sorted by printed name length. */
OCArrayRef SIUnitGetUnitsSortedByNameLength(void);

/** @brief Returns all root units, ordered alphabetically by name. */
OCArrayRef SIUnitCreateArrayOfRootUnits(void);

/** @brief Returns root units for a quantity; sets error on failure. */
OCArrayRef SIUnitCreateArrayOfRootUnitsForQuantity(OCStringRef quantity, OCStringRef *error);


/**
 * @brief Returns a commonly recognized quantity name associated with the given unit.
 *
 * This function uses the unit's dimensionality to look up known quantity names
 * (e.g., "length", "velocity", "acceleration"). If one or more matches are found,
 * the first is returned. If no matches are found, the dimensionality's symbolic
 * representation is returned (e.g., "L T⁻¹").
 *
 * The result is a borrowed reference and must not be released by the caller.
 *
 * @param theUnit The unit for which to determine an appropriate quantity name.
 * @return A borrowed OCStringRef representing the guessed quantity name or
 *         the dimensionality symbol if no match is found.
 *         Returns NULL only if the unit has no dimensionality or an internal error occurs.
 *
 */
OCStringRef SIUnitGuessQuantityName(SIUnitRef theUnit);

/** @cond INTERNAL */
/** @brief Cleans up all static and global unit dictionaries. */
void cleanupUnitsLibraries(void);
/** @endcond */

#endif /* SIUnit_h */
