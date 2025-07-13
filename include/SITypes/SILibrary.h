/**
 * @file SILibrary.h
 * @brief Core definitions, macros, and public interfaces for the SITypes library.
 *
 * This header centralizes the core types, forward declarations, and helper macros
 * used throughout the SITypes framework. It also includes all public-facing APIs
 * from the SITypes modules.
 *
 * @note This header should be included wherever SITypes functionality is required.
 */

#ifndef SILibrary_h
#define SILibrary_h

// C Standard Library Headers
#include <stdio.h>
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h> // Needed for memset, strcmp, etc.

#define SILIB_TYPES_COUNT 3 // Total number of types in SITypes

/** @cond INTERNAL */
// Centralized Ref typedefs
typedef const struct impl_SIDimensionality * SIDimensionalityRef;
typedef const struct impl_SIUnit * SIUnitRef;
typedef const struct impl_SIQuantity * SIQuantityRef;
typedef const struct impl_SIScalar *SIScalarRef;
typedef struct impl_SIScalar *SIMutableScalarRef;
/** @endcond */


// Include OCTypes base framework
#include <OCLibrary.h>

// Public SITypes API headers
#include "SIDimensionality.h"
#include "SIDimensionalityParser.h"
#include "SIUnit.h"
#include "SIUnitParser.h"
#include "SIQuantity.h"
#include "SIScalar.h"
#include "SIScalarConstants.h"

void SITypesShutdown(void);

#endif /* SILibrary_h */
