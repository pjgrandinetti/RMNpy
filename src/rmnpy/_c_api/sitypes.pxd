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
from rmnpy._c_api.octypes cimport *
from libc.stdint cimport uint8_t, int8_t

# ====================================================================================
# SITypes Core Types and Constants (from SILibrary.h)
# ====================================================================================

# Forward declarations from SILibrary.h
ctypedef void* SIDimensionalityRef
ctypedef void* SIUnitRef
ctypedef void* SIQuantityRef  
ctypedef void* SIScalarRef
ctypedef void* SIMutableScalarRef

# ====================================================================================
# Phase 2A: SIDimensionality API (Foundation Component)
# ====================================================================================

# Base dimension indices (from SIDimensionality.h)
ctypedef enum SIBaseDimensionIndex:
    kSILengthIndex = 0
    kSIMassIndex = 1  
    kSITimeIndex = 2
    kSICurrentIndex = 3
    kSITemperatureIndex = 4
    kSIAmountIndex = 5
    kSILuminousIntensityIndex = 6

cdef extern from "SITypes/SIDimensionality.h":
    
    # Parsing
    SIDimensionalityRef SIDimensionalityParseExpression(OCStringRef expression, OCStringRef *error)
    
    # Type system
    OCTypeID SIDimensionalityGetTypeID()
    
    # Accessors
    OCStringRef SIDimensionalityGetSymbol(SIDimensionalityRef theDim)
    
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
# Placeholder sections for Phase 2B and 2C (will be implemented later)
# ====================================================================================

# Phase 2B: SIUnit API (depends on SIDimensionality)
# This section will be implemented after Phase 2A completion

# Phase 2C: SIQuantity & SIScalar API (depends on both above)  
# This section will be implemented after Phase 2B completion
