//
//  SIScalar.h
//  SITypes
//
//  Created by philip on 6/14/17.
//  Copyright © 2017 PhySy Ltd. All rights reserved.
//

#ifndef SIScalar_h
#define SIScalar_h

#include "SILibrary.h"

/*!
 * @file SIScalar.h
 * @brief Interface for representing and manipulating scalar quantities in the SI system.
 *
 * The SIScalar API provides a comprehensive interface for **scalar physical quantities**
 * in the International System of Units (SI), supporting both real and complex values.
 *
 * ## Concepts and Rationale
 * - **Physical Quantity:** An SIScalar represents a numerical value paired with an SI unit,
 *   enabling type-safe, unit-aware calculations and dimensionality checking at runtime.
 * - **Element Types:** Supports single-precision, double-precision, and complex values to address
 *   a wide range of scientific and engineering applications.
 * - **Immutability and Mutability:** SIScalar objects are immutable by default to ensure safe sharing
 *   and thread safety. Mutable variants (`SIMutableScalarRef`) allow for in-place modifications where needed.
 * - **Units and Dimensionality:** All operations rigorously enforce unit compatibility. Arithmetic, conversion,
 *   and reduction routines ensure physically meaningful results.
 *
 * ## API Features
 * - **Object Model:** Opaque references are used for type safety and encapsulation.
 * - **Creation and Copying:** Functions with names containing `Create` or `Copy` return
 *   new OCType objects. **Ownership of these objects is transferred to the caller**,
 *   who is responsible for calling `OCRelease` when the object is no longer needed.
 * - **Access and Conversion:** Retrieve or modify scalar values in various numeric forms,
 *   convert units, and extract mathematical or physical properties (e.g., magnitude, phase).
 * - **Arithmetic:** Supports addition, subtraction, multiplication, division, exponentiation,
 *   and other operations, always enforcing correct unit handling.
 * - **Unit Simplification:** Functions to reduce or canonicalize units to the simplest or most
 *   standard form.
 * - **String Formatting:** Generate standard or custom string representations of scalars
 *   for logging, serialization, or debugging.
 * - **Comparison and Validation:** Functions to compare, test, and validate scalars, including
 *   strict and loose equality, dimensionality, and floating-point considerations.
 *
 * ## Usage Notes
 * - **Memory Management:** All functions with `Create` or `Copy` in the name return new objects
 *   owned by the caller, who must release them with `OCRelease` to prevent memory leaks.
 * - **Pointer Safety:** All pointer arguments must be valid and non-NULL unless specifically documented.
 * - **Thread Safety:** Operations on distinct scalar instances are thread-safe; concurrent mutation
 *   of the same instance is not.
 * - This API is intended for use in high-precision scientific and engineering software, providing
 *   robust unit-safety and extensibility for advanced numerical computations.
 *
 * @author Philip Grandinetti
 */

 /** @cond INTERNAL */
typedef union impl_SINumber
{
    float   floatValue;
    double  doubleValue;
    float complex floatComplexValue;
    double complex doubleComplexValue;
} impl_SINumber;
/** @endcond */

/** @brief Returns the unique type identifier for SIScalar objects. */
OCTypeID SIScalarGetTypeID(void);

#pragma mark Creators

/** @brief Creates a deep copy of a SIScalar object. */
SIScalarRef SIScalarCreateCopy(SIScalarRef theScalar);

/** @brief Creates a mutable deep copy of a SIScalar object. */
SIMutableScalarRef SIScalarCreateMutableCopy(SIScalarRef theScalar);


/**
 * @file SIScalar.h
 * @brief Convert between SIScalarRef and cJSON representations.
 */

cJSON *SIScalarCreateJSON(SIScalarRef scalar);

SIScalarRef SIScalarCreateFromJSON(cJSON *json);


/** @brief Creates an immutable SIScalar from a float value and SI unit. */
SIScalarRef SIScalarCreateWithFloat(float input_value, SIUnitRef unit);

/** @brief Creates a mutable SIScalar from a float value and SI unit. */
SIMutableScalarRef SIScalarCreateMutableWithFloat(float input_value, SIUnitRef unit);

/** @brief Creates an immutable SIScalar from a double value and SI unit. */
SIScalarRef SIScalarCreateWithDouble(double input_value, SIUnitRef unit);

/** @brief Creates a mutable SIScalar from a double value and SI unit. */
SIMutableScalarRef SIScalarCreateMutableWithDouble(double input_value, SIUnitRef unit);

/** @brief Creates an immutable SIScalar from a float complex value and SI unit. */
SIScalarRef SIScalarCreateWithFloatComplex(float complex input_value, SIUnitRef unit);

/** @brief Creates a mutable SIScalar from a float complex value and SI unit. */
SIMutableScalarRef SIScalarCreateMutableWithFloatComplex(float complex input_value, SIUnitRef unit);

/** @brief Creates an immutable SIScalar from a double complex value and SI unit. */
SIScalarRef SIScalarCreateWithDoubleComplex(double complex input_value, SIUnitRef unit);

/** @brief Creates a mutable SIScalar from a double complex value and SI unit. */
SIMutableScalarRef SIScalarCreateMutableWithDoubleComplex(double complex input_value, SIUnitRef unit);

/** @brief Creates a scalar from a string containing a single unit name. */
SIScalarRef SIScalarCreateWithStringContainingSingleUnitFromLibrary(OCStringRef theString);

#pragma mark Accessors

/** @brief Retrieves the numeric value of a SIScalar instance. */
impl_SINumber SIScalarGetValue(SIScalarRef theScalar);

/** @brief Sets the numeric value of a mutable scalar to a float. */
void SIScalarSetFloatValue(SIMutableScalarRef theScalar, float value);

/** @brief Sets the numeric value of a mutable scalar to a double. */
void SIScalarSetDoubleValue(SIMutableScalarRef theScalar, double value);

/** @brief Sets the numeric value of a mutable scalar to a float complex. */
void SIScalarSetFloatComplexValue(SIMutableScalarRef theScalar, float complex value);

/** @brief Sets the numeric value of a mutable scalar to a double complex. */
void SIScalarSetDoubleComplexValue(SIMutableScalarRef theScalar, double complex value);

/** @brief Sets the element type indicator for a mutable scalar. */
void SIScalarSetElementType(SIMutableScalarRef theScalar, SINumberType elementType);

/** @brief Retrieves the scalar’s value as a float. */
float SIScalarFloatValue(SIScalarRef theScalar);

/** @brief Retrieves the scalar’s value as a double. */
double SIScalarDoubleValue(SIScalarRef theScalar);

/** @brief Retrieves the scalar’s value as a float complex. */
float complex SIScalarFloatComplexValue(SIScalarRef theScalar);

/** @brief Retrieves the scalar’s value as a double complex. */
double complex SIScalarDoubleComplexValue(SIScalarRef theScalar);

/** @brief Computes the magnitude (absolute value) of the scalar. */
double SIScalarMagnitudeValue(SIScalarRef theScalar);

/** @brief Computes the argument (phase angle) of the scalar in radians. */
double SIScalarArgumentValue(SIScalarRef theScalar);

/** @brief Converts the scalar’s value to the specified unit and returns as float. */
float SIScalarFloatValueInUnit(SIScalarRef theScalar, SIUnitRef unit, bool *success);

/** @brief Converts the scalar’s value to the specified unit and returns as double. */
double SIScalarDoubleValueInUnit(SIScalarRef theScalar, SIUnitRef unit, bool *success);

/** @brief Converts the scalar’s value to the specified unit and returns as float complex. */
float complex SIScalarFloatComplexValueInUnit(SIScalarRef theScalar, SIUnitRef unit, bool *success);

/** @brief Converts the scalar’s value to the specified unit and returns as double complex. */
double complex SIScalarDoubleComplexValueInUnit(SIScalarRef theScalar, SIUnitRef unit, bool *success);

/** @brief Converts the scalar’s value to its coherent SI unit and returns as float. */
float SIScalarFloatValueInCoherentUnit(SIScalarRef theScalar);

/** @brief Converts the scalar’s value to its coherent SI unit and returns as double. */
double SIScalarDoubleValueInCoherentUnit(SIScalarRef theScalar);

/** @brief Converts the scalar’s value to its coherent SI unit and returns as float complex. */
float complex SIScalarFloatComplexValueInCoherentUnit(SIScalarRef theScalar);

/** @brief Converts the scalar’s value to its coherent SI unit and returns as double complex. */
double complex SIScalarDoubleComplexValueInCoherentUnit(SIScalarRef theScalar);

#pragma mark Operations

/** @brief Converts the numeric representation to a specified element type. */
SIScalarRef SIScalarCreateByConvertingToNumberType(SIScalarRef theScalar, SINumberType elementType);

/** @brief Replace the numeric value of a mutable scalar with one of its complex components. */
bool SIScalarTakeComplexPart(SIMutableScalarRef theScalar, complexPart part);

/** @brief Create a new SIScalar from a specified complex component of an existing scalar. */
SIScalarRef SIScalarCreateByTakingComplexPart(SIScalarRef theScalar, complexPart part);

/** @brief Parse a numeric string with unit and create a SIScalar. */
SIScalarRef SIScalarCreateFromExpression(OCStringRef string, OCStringRef *error);

/** @brief Create a new SIScalar with its unit exponents reduced to lowest integers. */
SIScalarRef SIScalarCreateByReducingUnit(SIScalarRef theScalar);

/** @brief Reduce a mutable scalar’s unit exponents in place to lowest integers. */
bool SIScalarReduceUnit(SIMutableScalarRef theScalar);

/** @brief Convert a mutable scalar’s value and unit to another compatible unit. */
bool SIScalarConvertToUnit(SIMutableScalarRef theScalar, SIUnitRef unit, OCStringRef *error);

/** @brief Create a new SIScalar by converting to another unit of the same dimensionality. */
SIScalarRef SIScalarCreateByConvertingToUnit(SIScalarRef theScalar, SIUnitRef unit, OCStringRef *error);

/** @brief Convert a mutable scalar to its coherent SI unit in place. */
bool SIScalarConvertToCoherentUnit(SIMutableScalarRef theScalar, OCStringRef *error);

/** @brief Create a new SIScalar by converting to its coherent SI unit. */
SIScalarRef SIScalarCreateByConvertingToCoherentUnit(SIScalarRef theScalar, OCStringRef *error);

/** @brief Create a new SIScalar by adding two scalars. */
SIScalarRef SIScalarCreateByAdding(SIScalarRef input1, SIScalarRef input2, OCStringRef *error);

/** @brief Adds another scalar into a mutable scalar in place. */
bool SIScalarAdd(SIMutableScalarRef target, SIScalarRef input2, OCStringRef *error);

/** @brief Create a new SIScalar by subtracting one scalar from another. */
SIScalarRef SIScalarCreateBySubtracting(SIScalarRef input1, SIScalarRef input2, OCStringRef *error);

/** @brief Subtracts a scalar from a mutable scalar in place. */
bool SIScalarSubtract(SIMutableScalarRef target, SIScalarRef input2, OCStringRef *error);

/** @brief Create a new SIScalar by multiplying two scalars without simplifying the unit. */
SIScalarRef SIScalarCreateByMultiplyingWithoutReducingUnit(SIScalarRef input1, SIScalarRef input2, OCStringRef *error);

/** @brief Multiplies a mutable scalar by another scalar without simplifying the unit. */
bool SIScalarMultiplyWithoutReducingUnit(SIMutableScalarRef target, SIScalarRef input2, OCStringRef *error);

/** @brief Create a new SIScalar by multiplying two scalars. */
SIScalarRef SIScalarCreateByMultiplying(SIScalarRef input1, SIScalarRef input2, OCStringRef *error);

/** @brief Multiplies a mutable scalar by another scalar in place. */
bool SIScalarMultiply(SIMutableScalarRef target, SIScalarRef input2, OCStringRef *error);

/** @brief Create a new SIScalar by dividing two scalars without simplifying the unit. */
SIScalarRef SIScalarCreateByDividingWithoutReducingUnit(SIScalarRef input1, SIScalarRef input2, OCStringRef *error);

/** @brief Divides a mutable scalar by another scalar in place without simplifying the unit. */
bool SIScalarDivideWithoutReducingUnit(SIMutableScalarRef target, SIScalarRef input2, OCStringRef *error);

/** @brief Create a new SIScalar by dividing two scalars. */
SIScalarRef SIScalarCreateByDividing(SIScalarRef input1, SIScalarRef input2, OCStringRef *error);

/** @brief Divides a mutable scalar by another scalar in place. */
bool SIScalarDivide(SIMutableScalarRef target, SIScalarRef input2, OCStringRef *error);

/** @brief Create a new SIScalar by raising a scalar to a power without simplifying the unit. */
SIScalarRef SIScalarCreateByRaisingToPowerWithoutReducingUnit(SIScalarRef theScalar, double power, OCStringRef *error);

/** @brief Raises a mutable scalar to a power without simplifying the unit in place. */
bool SIScalarRaiseToAPowerWithoutReducingUnit(SIMutableScalarRef theScalar, double power, OCStringRef *error);

/** @brief Create a new SIScalar by raising a scalar to a power. */
SIScalarRef SIScalarCreateByRaisingToPower(SIScalarRef theScalar, double power, OCStringRef *error);

/** @brief Raises a mutable scalar to a power in place. */
bool SIScalarRaiseToAPower(SIMutableScalarRef theScalar, double power, OCStringRef *error);

/** @brief Create a new SIScalar by taking the absolute value. */
SIScalarRef SIScalarCreateByTakingAbsoluteValue(SIScalarRef theScalar, OCStringRef *error);

/** @brief Replaces a mutable scalar’s value with its absolute value in place. */
bool SIScalarTakeAbsoluteValue(SIMutableScalarRef theScalar, OCStringRef *error);

/** @brief Create a new SIScalar by applying the Gamma function without simplifying the unit. */
SIScalarRef SIScalarCreateByGammaFunctionWithoutReducingUnit(SIScalarRef theScalar, OCStringRef *error);

/** @brief Create a new SIScalar by taking the Nth root. */
SIScalarRef SIScalarCreateByTakingNthRoot(SIScalarRef theScalar, uint8_t root, OCStringRef *error);

/** @brief Replaces a mutable scalar’s value with its Nth root in place. */
bool SIScalarTakeNthRoot(SIMutableScalarRef theScalar, uint8_t root, OCStringRef *error);

/** @brief Replaces a mutable scalar’s value with its base-10 logarithm in place. */
bool SIScalarTakeLog10(SIMutableScalarRef theScalar, OCStringRef *error);

#pragma mark Operations (Complex Parts)

/** @brief Create a new SIScalar by zeroing a specified component of its value. */
SIScalarRef SIScalarCreateByZeroingPart(SIScalarRef theScalar, complexPart part);

/** @brief Zeroes a specified component of a mutable scalar’s value in place. */
bool SIScalarZeroPart(SIMutableScalarRef theScalar, complexPart part);

/** @brief Multiplies a mutable scalar by a dimensionless real constant in place. */
bool SIScalarMultiplyByDimensionlessRealConstant(SIMutableScalarRef theScalar, double constant);

/** @brief Create a new SIScalar by multiplying by a dimensionless real constant. */
SIScalarRef SIScalarCreateByMultiplyingByDimensionlessRealConstant(SIScalarRef theScalar, double constant);

/** @brief Create a new SIScalar by multiplying by a dimensionless complex constant. */
SIScalarRef SIScalarCreateByMultiplyingByDimensionlessComplexConstant(SIScalarRef theScalar, double complex constant);

/** @brief Multiplies a mutable scalar by a dimensionless complex constant in place. */
bool SIScalarMultiplyByDimensionlessComplexConstant(SIMutableScalarRef theScalar, double complex constant);

/** @brief Create a new SIScalar by taking the complex conjugate. */
SIScalarRef SIScalarCreateByConjugation(SIScalarRef theScalar);

/** @brief Conjugates a mutable scalar in place. */
bool SIScalarConjugate(SIMutableScalarRef theScalar);

#pragma mark Strings and Archiving

/** @brief Prints a concise description of a scalar to the console. */
void SIScalarShow(SIScalarRef theScalar);

/** @brief Creates a string representation of a scalar including value and unit. */
OCStringRef SIScalarCreateStringValue(SIScalarRef theScalar);

/** @brief Creates a string representation of only the numeric part of a scalar. */
OCStringRef SIScalarCreateNumericStringValue(SIScalarRef theScalar);

/** @brief Creates a string representation of a specific component of a scalar. */
OCStringRef SIScalarCreateStringValueForPart(SIScalarRef theScalar, complexPart thePart);

/** @brief Creates a string representation of only the unit of a scalar. */
OCStringRef SIScalarCreateUnitString(SIScalarRef theScalar);

/** @brief Creates a formatted string representation of a scalar using a custom format. */
OCStringRef SIScalarCreateStringValueWithFormat(SIScalarRef theScalar, OCStringRef format);

/** @brief Creates a formatted string of the numeric part using a custom format. */
OCStringRef SIScalarCreateNumericStringValueWithFormat(SIScalarRef theScalar, OCStringRef format);

/** @brief Appends the scalar’s value and unit as a string to a mutable array. */
void SIScalarAddToArrayAsStringValue(SIScalarRef theScalar, OCMutableArrayRef array);

#pragma mark Tests

/** @brief Determines whether a scalar is a real number (imaginary part is zero). */
bool SIScalarIsReal(SIScalarRef theScalar);

/** @brief Determines whether a scalar is purely imaginary. */
bool SIScalarIsImaginary(SIScalarRef theScalar);

/** @brief Determines whether a scalar has a non-zero imaginary component. */
bool SIScalarIsComplex(SIScalarRef theScalar);

/** @brief Determines whether a scalar’s numeric value is exactly zero. */
bool SIScalarIsZero(SIScalarRef theScalar);

/** @brief Determines whether a scalar’s numeric value is infinite (±∞). */
bool SIScalarIsInfinite(SIScalarRef theScalar);

/** @brief Determines whether a scalar is a real, non-negative integer. */
bool SIScalarIsRealNonNegativeInteger(SIScalarRef theScalar);

/** @brief Validates whether a proposed string represents a scalar with the same dimensionality. */
bool SIScalarValidateProposedStringValue(SIScalarRef theScalar, OCStringRef proposedStringValue, OCStringRef *error);

/** @brief Tests whether two scalars are equal in value, unit, and metadata. */
bool SIScalarEqual(SIScalarRef input1, SIScalarRef input2);

/** @brief Compares two scalars and returns an ordering result. */
OCComparisonResult SIScalarCompare(SIScalarRef scalar, SIScalarRef otherScalar);

/** @brief Compares two scalars in reduced units and returns an ordering result. */
OCComparisonResult SIScalarCompareReduced(SIScalarRef theScalar, SIScalarRef theOtherScalar);

/** @brief Performs a “loose” comparison between two scalars and returns an ordering result. */
OCComparisonResult SIScalarCompareLoose(SIScalarRef theScalar, SIScalarRef theOtherScalar);

/** @brief Performs a “loose” comparison between two scalars in reduced units and returns an ordering result. */
OCComparisonResult SIScalarCompareLooseReduced(SIScalarRef theScalar, SIScalarRef theOtherScalar);

OCStringRef SIScalarCopyFormattingDescription(SIScalarRef scalar);


#pragma mark Best‐fit Unit Conversion

/*!
 @brief  Pick the “best” SI unit for this scalar (so the mantissa is ~1–1000)
 @param  theScalar   mutable scalar to rescale in-place
 @param  quantity    a quantity name (e.g. "time", "length", …)
 @param  outError    on failure, set to an OCStringRef describing the problem
 @return true on success, false (and *outError) otherwise
 */
bool SIScalarBestConversionForQuantity(SIMutableScalarRef theScalar,
                                       OCStringRef        quantity,
                                       OCStringRef       *outError);

/*!
 @brief  For a given scalar, return an array of alternate‐unit scalars and (optionally) string splits
 @param  theScalar      the input scalar
 @param  quantity       if non-NULL, only units for that quantity
 @param  outError       on failure, set to an OCStringRef
 @result an OCArray of SIScalarRef and OCStringRef entries
 */
OCArrayRef SIScalarCreateArrayOfConversionQuantitiesScalarsAndStringValues(SIScalarRef  theScalar,
                                                                            OCStringRef  quantity,
                                                                            OCStringRef *outError);

/*!
 @brief  Like above, but just returns the units themselves
 @param  theScalar      the input scalar
 @param  quantity       if non-NULL, only units for that quantity
 @param  outError       on failure, set to an OCStringRef
 @result an OCArray of SIUnitRef entries
 */
OCArrayRef SIScalarCreateArrayOfConversionQuantitiesAndUnits(SIScalarRef theScalar,
                                                             OCStringRef quantity,
                                                             OCStringRef *outError);

#endif /* SIScalar_h */
