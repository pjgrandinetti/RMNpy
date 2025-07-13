//
//  SIScalarConstants
//
//  Created by PhySy Ltd on 5/5/13.
//  Copyright (c) 2008-2014 PhySy Ltd. All rights reserved.
//

/**
 * @file SIScalarConstants.h
 * @brief Declares constants and utility functions for scalar values and periodic table data in the SI system.
 *
 * SIScalarConstants provides functions for accessing periodic table element and isotope data, including symbols, atomic numbers, molar masses, and nuclear properties.
 * The API is CoreFoundation-style, with explicit memory management and reference counting where applicable.
 *
 * This interface supports querying element and isotope properties, as well as generating arrays of symbols and physical constants for use in scientific calculations.
 *
 * @author Philip Grandinetti
 */

#ifndef SIScalarConstants_h
#define SIScalarConstants_h

#include <stdbool.h>
#include <stdint.h>

/**
 * @brief Returns an array with the element symbols.
 * @param errorString A pointer to an OCStringRef to store error information.
 * @return An OCArrayRef containing the element symbols.
 */
OCArrayRef SIPeriodicTableCreateElementSymbols(OCStringRef *errorString);

/**
 * @brief Returns an array with the isotope symbols.
 * @param errorString A pointer to an OCStringRef to store error information.
 * @return An OCArrayRef containing the isotope symbols.
 */
OCArrayRef SIPeriodicTableCreateIsotopeSymbols(OCStringRef *errorString);

/**
 * @brief Returns an array with the stable isotope symbols.
 * @param errorString A pointer to an OCStringRef to store error information.
 * @return An OCArrayRef containing the stable isotope symbols.
 */
OCArrayRef SIPeriodicTableCreateStableIsotopeSymbols(OCStringRef *errorString);

/**
 * @brief Returns an array with the NMR active isotope symbols.
 * @param errorString A pointer to an OCStringRef to store error information.
 * @return An OCArrayRef containing the NMR active isotope symbols.
 */
OCArrayRef SIPeriodicTableCreateNMRActiveIsotopeSymbols(OCStringRef *errorString);

/**
 * @brief Returns an array with the stable NMR active isotope symbols.
 * @param errorString A pointer to an OCStringRef to store error information.
 * @return An OCArrayRef containing the stable NMR active isotope symbols.
 */
OCArrayRef SIPeriodicTableGetStableNMRActiveIsotopeSymbols(OCStringRef *errorString);

/**
 * @brief Returns the atomic number of an element.
 * @param elementSymbol An OCStringRef containing the element symbol.
 * @param errorString A pointer to an OCStringRef to store error information.
 * @return An integer representing the atomic number.
 */
int64_t SIPeriodicTableGetAtomicNumber(OCStringRef elementSymbol, OCStringRef *errorString);

/**
 * @brief Creates a scalar with the molar mass of an element.
 * @param elementSymbol An OCStringRef containing the element symbol.
 * @param errorString A pointer to an OCStringRef to store error information.
 * @return A SIScalarRef representing the molar mass.
 */
SIScalarRef SIPeriodicTableCreateMolarMass(OCStringRef elementSymbol, OCStringRef *errorString);

/**
 * @brief Determines whether an isotope is stable.
 * @param isotopeSymbol An OCStringRef containing the isotope symbol.
 * @param errorString A pointer to an OCStringRef to store error information.
 * @return A boolean indicating stability.
 */
bool SIPeriodicTableCreateIsotopeStable(OCStringRef isotopeSymbol, OCStringRef *errorString);

/**
 * @brief Creates a scalar with the magnetic dipole moment of an isotope.
 * @param isotopeSymbol An OCStringRef containing the isotope symbol.
 * @param errorString A pointer to an OCStringRef to store error information.
 * @return A SIScalarRef representing the magnetic dipole moment.
 */
SIScalarRef SIPeriodicTableCreateIsotopeMagneticDipoleMoment(OCStringRef isotopeSymbol, OCStringRef *errorString);

/**
 * @brief Creates a scalar with the electric quadrupole moment of an isotope.
 * @param isotopeSymbol An OCStringRef containing the isotope symbol.
 * @param errorString A pointer to an OCStringRef to store error information.
 * @return A SIScalarRef representing the electric quadrupole moment.
 */
SIScalarRef SIPeriodicTableCreateIsotopeElectricQuadrupoleMoment(OCStringRef isotopeSymbol, OCStringRef *errorString);

/**
 * @brief Creates a scalar with the gyromagnetic ratio of an isotope.
 * @param isotopeSymbol An OCStringRef containing the isotope symbol.
 * @param errorString A pointer to an OCStringRef to store error information.
 * @return A SIScalarRef representing the gyromagnetic ratio.
 */
SIScalarRef SIPeriodicTableCreateIsotopeGyromagneticRatio(OCStringRef isotopeSymbol, OCStringRef *errorString);

/**
 * @brief Creates a scalar with the natural abundance of an isotope.
 * @param isotopeSymbol An OCStringRef containing the isotope symbol.
 * @param errorString A pointer to an OCStringRef to store error information.
 * @return A SIScalarRef representing the natural abundance.
 */
SIScalarRef SIPeriodicTableCreateIsotopeAbundance(OCStringRef isotopeSymbol, OCStringRef *errorString);

/**
 * @brief Creates a scalar with the lifetime of an isotope.
 * @param isotopeSymbol An OCStringRef containing the isotope symbol.
 * @param errorString A pointer to an OCStringRef to store error information.
 * @return A SIScalarRef representing the lifetime.
 */
SIScalarRef SIPeriodicTableCreateIsotopeLifetime(OCStringRef isotopeSymbol, OCStringRef *errorString);

/**
 * @brief Creates a scalar with the half-life of an isotope.
 * @param isotopeSymbol An OCStringRef containing the isotope symbol.
 * @param errorString A pointer to an OCStringRef to store error information.
 * @return A SIScalarRef representing the half-life.
 */
SIScalarRef SIPeriodicTableCreateIsotopeHalfLife(OCStringRef isotopeSymbol, OCStringRef *errorString);

/**
 * @brief Creates a scalar with the nuclear spin of an isotope.
 * @param isotopeSymbol An OCStringRef containing the isotope symbol.
 * @param errorString A pointer to an OCStringRef to store error information.
 * @return A SIScalarRef representing the nuclear spin.
 */
SIScalarRef SIPeriodicTableCreateIsotopeSpin(OCStringRef isotopeSymbol, OCStringRef *errorString);

/**
 * @brief Creates a scalar with the NMR frequency/magnetic flux density of an isotope.
 * @param isotopeSymbol An OCStringRef containing the isotope symbol.
 * @param errorString A pointer to an OCStringRef to store error information.
 * @return A SIScalarRef representing the NMR frequency/magnetic flux density.
 */
SIScalarRef SIPeriodicTableCreateNMRFrequency(OCStringRef isotopeSymbol, OCStringRef *errorString);

/**
 * @brief Creates a scalar with the formula mass.
 * @param formula An OCStringRef containing the chemical formula.
 * @param errorString A pointer to an OCStringRef to store error information.
 * @return A SIScalarRef representing the formula mass.
 */
SIScalarRef SIPeriodicTableCreateFormulaMass(OCStringRef formula, OCStringRef *errorString);

#endif
