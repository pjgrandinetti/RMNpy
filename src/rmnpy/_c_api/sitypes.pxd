# cython: language_level=3
"""
SITypes C API declarations for RMNpy

This file contains Cython declarations for the SITypes C library,
focusing on dimensional analysis and unit conversion systems.

Phase 2A: SIDimensionality (foundation component - no dependencies)
Phase 2B: SIUnit (depends on SIDimensionality)
Phase 2C: SIQuantity & SIScalar (depend on both above)

NOTE: All API declarations are based on actual SITypes headers
"""

# Import OCTypes dependencies

from libc.stdint cimport int8_t, uint8_t

from rmnpy._c_api.octypes cimport *

# ====================================================================================
# SITypes Core Types and Constants (from SITypes.h)
# ====================================================================================

# Forward declarations from SITypes.h
ctypedef void* SIDimensionalityRef
ctypedef void* SIUnitRef
ctypedef void* SIQuantityRef
ctypedef void* SIMutableQuantityRef
ctypedef void* SIScalarRef
ctypedef void* SIMutableScalarRef

# ====================================================================================
# SIDimensionality API (Foundation Component)
# ====================================================================================

# Base dimension indices (from SIDimensionality.h)
ctypedef enum SIBaseDimensionIndex:
    kSIMassIndex = 0
    kSILengthIndex = 1
    kSITimeIndex = 2
    kSICurrentIndex = 3
    kSITemperatureIndex = 4
    kSIAmountIndex = 5
    kSILuminousIntensityIndex = 6

cdef extern from "SITypes/SIDimensionality.h":

    # Parsing
    SIDimensionalityRef SIDimensionalityFromExpression(OCStringRef expression, OCStringRef *error)

    # Type system
    OCTypeID SIDimensionalityGetTypeID()

    # Accessors
    OCStringRef SIDimensionalityCopySymbol(SIDimensionalityRef theDim)

    # JSON support (commented out - not needed for Phase 2A)
    # cJSON *SIDimensionalityCreateJSON(SIDimensionalityRef dim)
    # SIDimensionalityRef SIDimensionalityFromJSON(cJSON *json)

    # Tests
    bint SIDimensionalityEqual(SIDimensionalityRef theDim1, SIDimensionalityRef theDim2)
    bint SIDimensionalityIsDimensionless(SIDimensionalityRef theDim)
    bint SIDimensionalityIsDerived(SIDimensionalityRef theDim)
    bint SIDimensionalityIsDimensionlessAndNotDerived(SIDimensionalityRef theDim)
    bint SIDimensionalityIsDimensionlessAndDerived(SIDimensionalityRef theDim)
    bint SIDimensionalityIsBaseDimensionality(SIDimensionalityRef theDim)
    bint SIDimensionalityHasSameReducedDimensionality(SIDimensionalityRef theDim1, SIDimensionalityRef theDim2)
    bint SIDimensionalityHasReducedExponents(SIDimensionalityRef theDim,
                                           int8_t length_exponent,
                                           int8_t mass_exponent,
                                           int8_t time_exponent,
                                           int8_t current_exponent,
                                           int8_t temperature_exponent,
                                           int8_t amount_exponent,
                                           int8_t luminous_intensity_exponent)
    bint SIDimensionalityCanBeReduced(SIDimensionalityRef theDim)

    # Operations
    SIDimensionalityRef SIDimensionalityDimensionless()
    SIDimensionalityRef SIDimensionalityForBaseDimensionIndex(SIBaseDimensionIndex index)
    SIDimensionalityRef SIDimensionalityWithBaseDimensionSymbol(OCStringRef symbol, OCStringRef *error)
    SIDimensionalityRef SIDimensionalityForQuantity(OCStringRef quantity, OCStringRef *error)
    SIDimensionalityRef SIDimensionalityByReducing(SIDimensionalityRef theDimensionality)
    SIDimensionalityRef SIDimensionalityByTakingNthRoot(SIDimensionalityRef theDim, uint8_t root, OCStringRef *error)
    SIDimensionalityRef SIDimensionalityByMultiplying(SIDimensionalityRef theDim1, SIDimensionalityRef theDim2, OCStringRef *error)
    SIDimensionalityRef SIDimensionalityByMultiplyingWithoutReducing(SIDimensionalityRef theDim1, SIDimensionalityRef theDim2, OCStringRef *error)
    SIDimensionalityRef SIDimensionalityByDividing(SIDimensionalityRef theDim1, SIDimensionalityRef theDim2)
    SIDimensionalityRef SIDimensionalityByDividingWithoutReducing(SIDimensionalityRef theDim1, SIDimensionalityRef theDim2)
    SIDimensionalityRef SIDimensionalityByRaisingToPower(SIDimensionalityRef theDim, double power, OCStringRef *error)
    SIDimensionalityRef SIDimensionalityByRaisingToPowerWithoutReducing(SIDimensionalityRef theDim, double power, OCStringRef *error)

    # Array operations
    OCArrayRef SIDimensionalityCreateArrayOfQuantities(SIDimensionalityRef theDim)
    OCArrayRef SIDimensionalityCreateArrayOfQuantitiesWithSameReducedDimensionality(SIDimensionalityRef theDim)
    OCArrayRef SIDimensionalityCreateArrayWithSameReducedDimensionality(SIDimensionalityRef theDim)
    OCArrayRef SIDimensionalityCreateArrayOfQuantityNames(SIDimensionalityRef dim)
    OCArrayRef SIDimensionalityCreateArrayOfQuantityNamesWithSameReducedDimensionality(SIDimensionalityRef dim)

    # Display
    void SIDimensionalityShow(SIDimensionalityRef theDim)
    void SIDimensionalityShowFull(SIDimensionalityRef theDim)

# ====================================================================================
# SIUnit API (Depends on SIDimensionality)
# ====================================================================================

cdef extern from "SITypes/SIUnit.h":

    # Type definitions
    ctypedef enum SIPrefix:
        kSIPrefixYocto = -24
        kSIPrefixZepto = -21
        kSIPrefixAtto = -18
        kSIPrefixFemto = -15
        kSIPrefixPico = -12
        kSIPrefixNano = -9
        kSIPrefixMicro = -6
        kSIPrefixMilli = -3
        kSIPrefixCenti = -2
        kSIPrefixDeci = -1
        kSIPrefixNone = 0
        kSIPrefixDeca = 1
        kSIPrefixHecto = 2
        kSIPrefixKilo = 3
        kSIPrefixMega = 6
        kSIPrefixGiga = 9
        kSIPrefixTera = 12
        kSIPrefixPeta = 15
        kSIPrefixExa = 18
        kSIPrefixZetta = 21
        kSIPrefixYotta = 24

    # Type ID
    OCTypeID SIUnitGetTypeID()

    # Parsing
    SIUnitRef SIUnitFromExpression(OCStringRef expression, double *unit_multiplier, OCStringRef *error)

    # Memory management - Note: SIUnitRef are immutable references managed by the library

    # Properties - Basic
    SIDimensionalityRef SIUnitGetDimensionality(SIUnitRef theUnit)
    OCStringRef SIUnitCopySymbol(SIUnitRef theUnit)
    OCStringRef SIUnitCopyName(SIUnitRef theUnit)
    OCStringRef SIUnitCopyPluralName(SIUnitRef theUnit)

    # Type checking
    bint SIUnitIsDimensionless(SIUnitRef theUnit)
    bint SIUnitIsCoherentUnit(SIUnitRef theUnit)
    bint SIUnitIsSIUnit(SIUnitRef theUnit)
    bint SIUnitIsCGSUnit(SIUnitRef theUnit)
    bint SIUnitIsImperialUnit(SIUnitRef theUnit)
    bint SIUnitIsAtomicUnit(SIUnitRef theUnit)
    bint SIUnitIsPlanckUnit(SIUnitRef theUnit)
    bint SIUnitIsConstant(SIUnitRef theUnit)

    # Comparison
    bint SIUnitEqual(SIUnitRef unit1, SIUnitRef unit2)
    bint SIUnitAreEquivalentUnits(SIUnitRef unit1, SIUnitRef unit2)

    # Scale and conversion
    double SIUnitGetScaleToCoherentSI(SIUnitRef theUnit)
    double SIUnitScaleToCoherentSIUnit(SIUnitRef theUnit)

    # Unit creation and finding
    SIUnitRef SIUnitDimensionlessAndUnderived()
    SIUnitRef SIUnitFindWithName(OCStringRef input)
    SIUnitRef SIUnitWithSymbol(OCStringRef symbol)
    SIUnitRef SIUnitCoherentUnitFromDimensionality(SIDimensionalityRef theDimensionality)

    # Unit conversion
    double SIUnitConversion(SIUnitRef initialUnit, SIUnitRef finalUnit)

    # Unit arithmetic - Basic (reducing)
    SIUnitRef SIUnitByMultiplying(SIUnitRef theUnit1, SIUnitRef theUnit2, double *unit_multiplier, OCStringRef *error)
    SIUnitRef SIUnitByDividing(SIUnitRef theUnit1, SIUnitRef theUnit2, double *unit_multiplier)
    SIUnitRef SIUnitByRaisingToPower(SIUnitRef input, double power, double *unit_multiplier, OCStringRef *error)
    SIUnitRef SIUnitByTakingNthRoot(SIUnitRef input, uint8_t root, double *unit_multiplier, OCStringRef *error)

    # Unit arithmetic - Advanced (non-reducing)
    SIUnitRef SIUnitByMultiplyingWithoutReducing(SIUnitRef theUnit1, SIUnitRef theUnit2, double *unit_multiplier, OCStringRef *error)
    SIUnitRef SIUnitByDividingWithoutReducing(SIUnitRef theUnit1, SIUnitRef theUnit2, double *unit_multiplier, OCStringRef *error)
    SIUnitRef SIUnitByRaisingToPowerWithoutReducing(SIUnitRef input, double power, double *unit_multiplier, OCStringRef *error)

    # Unit reduction and conversion
    SIUnitRef SIUnitByReducing(SIUnitRef theUnit, double *unit_multiplier)

    # Unit analysis and discovery
    OCArrayRef SIUnitCreateArrayOfUnitsForQuantity(OCStringRef quantity)
    OCArrayRef SIUnitCreateArrayOfUnitsForDimensionality(SIDimensionalityRef theDim)
    OCArrayRef SIUnitCreateArrayOfUnitsForSameReducedDimensionality(SIDimensionalityRef theDim)
    OCArrayRef SIUnitCreateArrayOfConversionUnits(SIUnitRef theUnit)
    OCArrayRef SIUnitCreateArrayOfEquivalentUnits(SIUnitRef theUnit)

# ====================================================================================
#  SIQuantity & SIScalar API (depends on both above)
# ====================================================================================

# SINumber types and structures
ctypedef enum SINumberType:
    kSINumberFloat32Type = 31  # from OCNumber types
    kSINumberFloat64Type = 32
    kSINumberComplex64Type = 33
    kSINumberComplex128Type = 34

ctypedef enum complexPart:
    kSIRealPart
    kSIImaginaryPart
    kSIMagnitudePart
    kSIArgumentPart

cdef extern from "SITypes/SIScalar.h":

    # Union for numeric values (must match C definition exactly)
    ctypedef union impl_SINumber:
        float floatValue
        double doubleValue
        float complex floatComplexValue
        double complex doubleComplexValue

    # Type system
    OCTypeID SIScalarGetTypeID()

    # Creators
    SIScalarRef SIScalarCreateCopy(SIScalarRef theScalar)
    SIMutableScalarRef SIScalarCreateMutableCopy(SIScalarRef theScalar)
    SIScalarRef SIScalarCreateWithFloat(float input_value, SIUnitRef unit)
    SIMutableScalarRef SIScalarCreateMutableWithFloat(float input_value, SIUnitRef unit)
    SIScalarRef SIScalarCreateWithDouble(double input_value, SIUnitRef unit)
    SIMutableScalarRef SIScalarCreateMutableWithDouble(double input_value, SIUnitRef unit)
    SIScalarRef SIScalarCreateWithFloatComplex(float complex input_value, SIUnitRef unit)
    SIMutableScalarRef SIScalarCreateMutableWithFloatComplex(float complex input_value, SIUnitRef unit)
    SIScalarRef SIScalarCreateWithDoubleComplex(double complex input_value, SIUnitRef unit)
    SIMutableScalarRef SIScalarCreateMutableWithDoubleComplex(double complex input_value, SIUnitRef unit)
    SIScalarRef SIScalarCreateFromExpression(OCStringRef expression, OCStringRef *error)

    # Accessors
    impl_SINumber SIScalarGetValue(SIScalarRef theScalar)
    void SIScalarSetFloatValue(SIMutableScalarRef theScalar, float value)
    void SIScalarSetDoubleValue(SIMutableScalarRef theScalar, double value)
    void SIScalarSetFloatComplexValue(SIMutableScalarRef theScalar, float complex value)
    void SIScalarSetDoubleComplexValue(SIMutableScalarRef theScalar, double complex value)
    void SIScalarSetNumericType(SIMutableScalarRef theScalar, SINumberType numericType)
    float SIScalarFloatValue(SIScalarRef theScalar)
    double SIScalarDoubleValue(SIScalarRef theScalar)
    float complex SIScalarFloatComplexValue(SIScalarRef theScalar)
    double complex SIScalarDoubleComplexValue(SIScalarRef theScalar)

    # Unit conversions
    bint SIScalarConvertToUnit(SIMutableScalarRef theScalar, SIUnitRef unit, OCStringRef *error)
    SIScalarRef SIScalarCreateByConvertingToUnit(SIScalarRef theScalar, SIUnitRef unit, OCStringRef *error)
    bint SIScalarConvertToUnitWithString(SIMutableScalarRef theScalar, OCStringRef unitString, OCStringRef *error)
    SIScalarRef SIScalarCreateByConvertingToUnitWithString(SIScalarRef theScalar, OCStringRef unitString, OCStringRef *error)
    bint SIScalarConvertToCoherentUnit(SIMutableScalarRef theScalar, OCStringRef *error)
    SIScalarRef SIScalarCreateByConvertingToCoherentUnit(SIScalarRef theScalar, OCStringRef *error)

    # Arithmetic operations
    SIScalarRef SIScalarCreateByAdding(SIScalarRef input1, SIScalarRef input2, OCStringRef *error)
    bint SIScalarAdd(SIMutableScalarRef target, SIScalarRef input2, OCStringRef *error)
    SIScalarRef SIScalarCreateBySubtracting(SIScalarRef input1, SIScalarRef input2, OCStringRef *error)
    bint SIScalarSubtract(SIMutableScalarRef target, SIScalarRef input2, OCStringRef *error)
    SIScalarRef SIScalarCreateByMultiplying(SIScalarRef input1, SIScalarRef input2, OCStringRef *error)
    bint SIScalarMultiply(SIMutableScalarRef target, SIScalarRef input2, OCStringRef *error)
    SIScalarRef SIScalarCreateByDividing(SIScalarRef input1, SIScalarRef input2, OCStringRef *error)
    bint SIScalarDivide(SIMutableScalarRef target, SIScalarRef input2, OCStringRef *error)

    # Dimensionless constant operations
    SIScalarRef SIScalarCreateByMultiplyingByDimensionlessRealConstant(SIScalarRef theScalar, double constant)
    SIScalarRef SIScalarCreateByMultiplyingByDimensionlessComplexConstant(SIScalarRef theScalar, double complex constant)
    bint SIScalarMultiplyByDimensionlessRealConstant(SIMutableScalarRef theScalar, double constant)
    bint SIScalarMultiplyByDimensionlessComplexConstant(SIMutableScalarRef theScalar, double complex constant)

    SIScalarRef SIScalarCreateByRaisingToPower(SIScalarRef theScalar, double power, OCStringRef *error)
    bint SIScalarRaiseToAPower(SIMutableScalarRef theScalar, double power, OCStringRef *error)
    SIScalarRef SIScalarCreateByTakingAbsoluteValue(SIScalarRef theScalar, OCStringRef *error)
    bint SIScalarTakeAbsoluteValue(SIMutableScalarRef theScalar, OCStringRef *error)
    SIScalarRef SIScalarCreateByTakingNthRoot(SIScalarRef theScalar, uint8_t root, OCStringRef *error)
    bint SIScalarTakeNthRoot(SIMutableScalarRef theScalar, uint8_t root, OCStringRef *error)
    SIScalarRef SIScalarCreateByTakingComplexPart(SIScalarRef theScalar, complexPart part)

    # Unit reduction
    SIScalarRef SIScalarCreateByReducingUnit(SIScalarRef theScalar)
    bint SIScalarReduceUnit(SIMutableScalarRef theScalar)

    # String representations
    void SIScalarShow(SIScalarRef theScalar)
    OCStringRef SIScalarCreateStringValue(SIScalarRef theScalar)
    OCStringRef SIScalarCreateNumericStringValue(SIScalarRef theScalar)
    OCStringRef SIScalarCopyUnitSymbol(SIScalarRef theScalar)
    OCStringRef SIScalarCreateStringValueWithFormat(SIScalarRef theScalar, OCStringRef format)

    # Tests
    bint SIScalarIsReal(SIScalarRef theScalar)
    bint SIScalarIsImaginary(SIScalarRef theScalar)
    bint SIScalarIsComplex(SIScalarRef theScalar)
    bint SIScalarIsZero(SIScalarRef theScalar)
    bint SIScalarIsInfinite(SIScalarRef theScalar)
    bint SIScalarEqual(SIScalarRef input1, SIScalarRef input2)
    OCComparisonResult SIScalarCompare(SIScalarRef scalar, SIScalarRef otherScalar)
    OCComparisonResult SIScalarCompareLoose(SIScalarRef scalar, SIScalarRef otherScalar)

cdef extern from "SITypes/SIQuantity.h":

    # SIQuantity accessors and tests
    SIUnitRef SIQuantityGetUnit(SIQuantityRef quantity)
    bint SIQuantitySetUnit(SIMutableQuantityRef quantity, SIUnitRef unit)
    SIDimensionalityRef SIQuantityGetUnitDimensionality(SIQuantityRef quantity)
    SINumberType SIQuantityGetNumericType(SIQuantityRef quantity)
    int SIQuantityElementSize(SIQuantityRef quantity)
    bint SIQuantityHasNumericType(SIQuantityRef quantity, SINumberType numericType)
    bint SIQuantityIsComplexType(SIQuantityRef theQuantity)
    bint SIQuantityHasDimensionality(SIQuantityRef quantity, SIDimensionalityRef theDimensionality)
    bint SIQuantityHasSameDimensionality(SIQuantityRef input1, SIQuantityRef input2)
    bint SIQuantityHasSameReducedDimensionality(SIQuantityRef input1, SIQuantityRef input2)
    SINumberType SIQuantityLargerNumericType(SIQuantityRef input1, SIQuantityRef input2)
    SINumberType SIQuantitySmallerNumericType(SIQuantityRef input1, SIQuantityRef input2)
