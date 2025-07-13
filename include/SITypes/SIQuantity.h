/**
 * @file SIQuantity.h
 * @brief Declares the SIQuantity interface for representing and manipulating physical quantities.
 *
 * SIQuantity provides an abstract interface for physical quantities, associating a value (of a specific element type) with a unit and dimensionality.
 * The API is CoreFoundation-style, with explicit memory management and reference counting.
 *
 * SIQuantity objects are immutable by default; use SIMutableQuantityRef for mutable variants.
 *
 * This interface supports querying and manipulating the unit, dimensionality, and element type of a quantity, as well as type and dimensionality comparisons.
 *
 * @author Philip Grandinetti
 */

//
//  SIQuantity.h
//  SITypes
//
//  Created by Philip Grandinetti on 6/13/17.
//  Copyright © 2017 PhySy Ltd. All rights reserved.
//

#ifndef SIQuantity_h
#define SIQuantity_h

#include "SILibrary.h"

/**
 * @enum complexPart
 * @brief Parts of a complex number.
 */
typedef enum complexPart {
    kSIRealPart,        /**< Real part of complex number. */
    kSIImaginaryPart,   /**< Imaginary part of complex number. */
    kSIMagnitudePart,   /**< Magnitude part of complex number. */
    kSIArgumentPart,    /**< Argument part of complex number. */
} complexPart;

/**
 * @enum SINumberType
 * @brief valid number types for SIQuantity.
 * @ingroup SIQuantities
 */
typedef enum { // Anonymous enum
    kSINumberFloat32Type = kOCNumberUInt32Type,
    kSINumberFloat64Type = kOCNumberUInt64Type,
    kSINumberComplex64Type = kOCNumberComplex64Type,
    kSINumberComplex128Type = kOCNumberComplex128Type
} SINumberType;

#define kSINumberTypeInvalid 0

/** @cond INTERNAL */

/**
 * @typedef SIMutableQuantityRef
 * @brief Reference to a mutable SIQuantity object.
 */
typedef struct impl_SIQuantity * SIMutableQuantityRef;
/** @endcond */

/**
 * @brief Returns the quantity's unit.
 * @param quantity The quantity.
 * @return A SIUnit object.
 */
SIUnitRef SIQuantityGetUnit(SIQuantityRef quantity);

/**
 * @brief Sets the quantity's unit.
 * @param quantity The quantity.
 * @param unit The unit.
 */
bool SIQuantitySetUnit(SIMutableQuantityRef quantity, SIUnitRef unit);

/**
 * @brief Returns the quantity's dimensionality.
 * @param quantity The quantity.
 * @return A SIDimensionality object.
 */
SIDimensionalityRef SIQuantityGetUnitDimensionality(SIQuantityRef quantity);

/**
 * @brief Returns the type used by a quantity to store its values.
 * @param quantity The quantity.
 * @return The element type. Possible values are kSINumberFloatType, kSINumberDoubleType, kSINumberFloatComplexType, and kSINumberDoubleComplexType.
 */
SINumberType SIQuantityGetElementType(SIQuantityRef quantity);

/**
 * @brief Returns size (in bytes) of a quantity element.
 * @param quantity The quantity.
 * @return The size.
 */
int SIQuantityElementSize(SIQuantityRef quantity);

/**
 * @brief Tests if quantity has a specific element type.
 * @param quantity The quantity.
 * @param elementType The element type.
 * @return True or false.
 */
bool SIQuantityHasElementType(SIQuantityRef quantity, SINumberType elementType);

/**
 * @brief Tests if quantity has a complex element type.
 * @param theQuantity The quantity.
 * @return True or false.
 */
bool SIQuantityIsComplexType(SIQuantityRef theQuantity);

/**
 * @brief Tests if quantity has a specific dimensionality.
 * @param quantity The quantity.
 * @param theDimensionality The dimensionality.
 * @return True or false.
 */
bool SIQuantityHasDimensionality(SIQuantityRef quantity, SIDimensionalityRef theDimensionality);

/**
 * @brief Determines if two quantities have the same dimensionality exponents.
 * @param input1 The first quantity.
 * @param input2 The second quantity.
 * @return True or false.
 */
bool SIQuantityHasSameDimensionality(SIQuantityRef input1, SIQuantityRef input2);

/**
 * @brief Determines if two quantities have the same reduced dimensionality exponents.
 * @param input1 The first quantity.
 * @param input2 The second quantity.
 * @return True or false.
 */
bool SIQuantityHasSameReducedDimensionality(SIQuantityRef input1, SIQuantityRef input2);

/**
 * @brief Returns larger element type for the two input quantities.
 * @param input1 The first SIQuantity.
 * @param input2 The second SIQuantity.
 * @return The larger SINumberType of the two quantities.
 */
SINumberType SIQuantityLargerElementType(SIQuantityRef input1, SIQuantityRef input2);

/**
 * @brief Returns smaller element type for the two input quantities.
 * @param input1 The first SIQuantity.
 * @param input2 The second SIQuantity.
 * @return The smaller SINumberType of the two quantities.
 */
SINumberType SIQuantitySmallerElementType(SIQuantityRef input1, SIQuantityRef input2);

/**
 * @brief Returns the best element type for the two input quantities.
 * @param input1 The first SIQuantity.
 * @param input2 The second SIQuantity.
 * @return The best SINumberType from the two quantities.
 * @details Returns the best element type for the two input quantities which loses no precision
 * when the quantities are combined in any way: add, subtract, multiply, divide. Input element
 * types and outputs are:
 *
 * (float and float) => float
 *
 * (float and double) => double
 *
 * (float and float complex) => float complex
 *
 * (float and double complex) => double complex
 *
 * (double and double) => double
 *
 * (double and float complex) => double complex
 *
 * (double and double complex) => double complex
 *
 * (float complex and float complex) => float complex
 *
 * (float complex and double complex) => double complex
 *
 * (double complex and double complex) => double complex
 */
SINumberType SIQuantityBestElementType(SIQuantityRef input1, SIQuantityRef input2);

#endif /* SIQuantity_h */
