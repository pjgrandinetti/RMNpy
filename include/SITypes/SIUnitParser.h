//
//  SIUnitParser.h
//
//  Created by PhySy Ltd on 5/3/13.
//  Copyright (c) 2012-2014 PhySy Ltd. All rights reserved.
//

#ifndef SIUnitParser_h
#define SIUnitParser_h

#include "SILibrary.h"  // for OCStringRef, SIUnitRef

extern OCStringRef unitError;

/**
 * @brief Returns the SI unit for a parsed symbol string.
 * 
 * This function always returns a valid SI unit, even when parsing non-SI units like "in", "lb", or "lbf". 
 * For non-SI units, it returns the equivalent SI unit and sets the unit_multiplier to the appropriate 
 * conversion factor. For example, parsing "in" will return the SI unit "m" with a multiplier of 0.0254.
 * The unit_multiplier pointer must be initialized to 1.0 before calling. On return, it holds the scaling 
 * factor needed to convert from the parsed unit to the returned SI unit.
 * 
 * @param string The unit symbol string to parse.
 * @param unit_multiplier Pointer to a double; must be initialized to 1.0 to receive multiplier.
 * @param error Pointer to an OCStringRef to receive error messages.
 @result The equivalent SI unit as SIUnitRef, or NULL on error.
 */
SIUnitRef SIUnitFromExpressionInternal(OCStringRef string, double *unit_multiplier, OCStringRef *error);

#endif
