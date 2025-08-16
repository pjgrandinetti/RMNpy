# cython: language_level=3
"""
RMNpy SIUnit Wrapper - Phase 2B Implementation

Complete wrapper for SIUnit providing comprehensive unit manipulation capabilities.
This implementation builds on the SIDimensionality foundation from Phase 2A.
"""

from rmnpy._c_api.octypes cimport (
    OCArrayGetCount,
    OCArrayGetValueAtIndex,
    OCArrayRef,
    OCRelease,
    OCStringRef,
    OCTypeRef,
)
from rmnpy._c_api.sitypes cimport *

from rmnpy.exceptions import RMNError

from rmnpy.wrappers.sitypes.dimensionality cimport Dimensionality

from rmnpy.helpers.octypes import ocarray_to_pylist, ocstring_to_pystring

from libc.stdint cimport uint64_t, uintptr_t


# Helper function for converting various input types to SIUnitRef
cdef SIUnitRef convert_to_siunit_ref(value) except NULL:
    """
    Convert various input types to SIUnitRef.

    Accepts:
    - Unit objects: Returns their C reference (borrowed, caller should copy if needed)
    - str: Creates Unit from string expression
    - None: Returns NULL (for dimensionless/no unit)

    Returns:
        SIUnitRef: C reference to unit (caller owns reference and must release)

    Raises:
        TypeError: If input type is not supported
        RMNError: If unit creation fails
    """
    cdef Unit temp_unit

    if value is None:
        return NULL  # Allow NULL for dimensionless quantities
    elif isinstance(value, Unit):
        # Return the C reference directly
        return (<Unit>value)._c_ref
    elif isinstance(value, str):
        # Create Unit from string and return its C reference
        temp_unit = Unit(value)
        return temp_unit._c_ref
    else:
        raise TypeError(f"Cannot convert {type(value)} to SIUnitRef")


cdef class Unit:
    """
    Python wrapper for SIUnit - represents a physical unit.

    A unit combines a dimensionality with scale factors, prefixes, and symbols.
    Units support full algebraic operations with automatic dimensional validation.

    Examples:
        >>> # Create from expression
        >>> meter = Unit("m")  # meter
        >>> second = Unit("s")  # second
        >>> velocity_unit = meter / second  # m/s
        >>>
        >>> # Test properties
        >>> velocity_unit.symbol
        'm/s'
        >>> velocity_unit.dimensionality.symbol
        'L/T'
        >>>
        >>> # Unit operations
        >>> area_unit = meter * meter  # m^2
        >>> volume_unit = area_unit * meter  # m^3
        >>>
        >>> # More complex units
        >>> force = Unit("kg*m/s^2")  # newton
        >>> energy = Unit("kg*m^2/s^2")  # joule
    """

    def __cinit__(self):
        self._c_ref = NULL

    def __init__(self, expression=None):
        """
        Create a Unit from a string expression.

        Args:
            expression (str, optional): Unit expression (e.g., "m", "m/s", "kg*m/s^2")
                If None, creates an empty unit wrapper (for internal use)

        Examples:
            >>> meter = Unit("m")
            >>> velocity = Unit("m/s")
            >>> force = Unit("kg*m/s^2")
        """
        if expression is None:
            # Empty constructor for internal use (e.g., _from_c_ref)
            return

        if not isinstance(expression, str):
            raise TypeError("Expression must be a string")

        from rmnpy.helpers.octypes import ocstring_create_from_pystring

        cdef OCStringRef expr_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(expression)
        cdef OCStringRef error_ocstr = <OCStringRef>0
        cdef double unit_multiplier = 1.0
        cdef SIUnitRef c_ref

        try:
            c_ref = SIUnitFromExpression(expr_ocstr, &unit_multiplier, &error_ocstr)

            if c_ref == NULL:
                if error_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>error_ocstr)
                    raise RMNError(f"Failed to parse unit expression '{expression}': {error_msg}")
                else:
                    raise RMNError(f"Failed to parse unit expression '{expression}': Unknown error")

            # Validate that multiplier is exactly 1.0 - this is a safety check
            if unit_multiplier != 1.0:
                # Release the unit before raising error
                OCRelease(<OCTypeRef>c_ref)
                raise RMNError(f"Unit expression '{expression}' returned unexpected multiplier {unit_multiplier}, expected 1.0")

            # Store the C reference
            self._c_ref = c_ref

        finally:
            OCRelease(<OCTypeRef>expr_ocstr)
            if error_ocstr != <OCStringRef>0:
                OCRelease(<OCTypeRef>error_ocstr)

    def __dealloc__(self):
        # Units are static instances managed by SITypes library
        # No need to release them
        pass

    @staticmethod
    cdef Unit _from_c_ref(SIUnitRef unit_ref):
        """Create Unit wrapper from C reference (internal use)."""
        cdef Unit result = Unit()
        result._c_ref = unit_ref
        return result

    @classmethod
    def from_name(cls, name):
        """
        Find a unit by its name.

        Args:
            name (str): Unit name (e.g., "meter", "second", "kilogram")

        Returns:
            Unit: Unit with the given name, or None if not found
        """
        if not isinstance(name, str):
            raise TypeError("Name must be a string")

        from rmnpy.helpers.octypes import ocstring_create_from_pystring

        cdef OCStringRef name_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(name)
        cdef SIUnitRef c_ref

        try:
            c_ref = SIUnitFindWithName(name_ocstr)

            if c_ref == NULL:
                return None

            # Create Python wrapper using _from_c_ref
            return Unit._from_c_ref(c_ref)

        finally:
            OCRelease(<OCTypeRef>name_ocstr)

    @classmethod
    def dimensionless(cls):
        """
        Create the dimensionless unit (1).

        Returns:
            Unit: Dimensionless unit
        """
        cdef SIUnitRef c_ref = SIUnitDimensionlessAndUnderived()

        return Unit._from_c_ref(c_ref)

    @classmethod
    def for_dimensionality(cls, dimensionality):
        """
        Find the coherent SI unit for a given dimensionality.

        Args:
            dimensionality (Dimensionality): Target dimensionality

        Returns:
            Unit: Coherent SI unit with that dimensionality
        """
        if not isinstance(dimensionality, Dimensionality):
            raise TypeError("Expected Dimensionality object")

        # Access the _c_ref attribute using the proper cdef approach
        cdef Dimensionality dim_obj = <Dimensionality>dimensionality
        cdef SIDimensionalityRef dim_ref = dim_obj._c_ref
        cdef SIUnitRef c_ref = SIUnitCoherentUnitFromDimensionality(dim_ref)

        if c_ref == NULL:
            return None

        return Unit._from_c_ref(c_ref)

    # Properties
    @property
    def name(self):
        """Get the unit name (e.g., 'meter per second')."""

        cdef OCStringRef name_ocstr = SIUnitCopyName(self._c_ref)
        if name_ocstr == NULL:
            return ""

        try:
            return ocstring_to_pystring(<uint64_t>name_ocstr)
        finally:
            OCRelease(<OCTypeRef>name_ocstr)

    @property
    def plural(self):
        """Get the plural unit name (e.g., 'meters per second')."""
        cdef OCStringRef plural_ocstr = SIUnitCopyPluralName(self._c_ref)
        if plural_ocstr == NULL:
            return ""

        try:
            return ocstring_to_pystring(<uint64_t>plural_ocstr)
        finally:
            OCRelease(<OCTypeRef>plural_ocstr)

    @property
    def symbol(self):
        """Get the symbol of this unit."""
        if self._c_ref == NULL:
            raise RMNError("Cannot get symbol of NULL unit")

        cdef OCStringRef symbol_ocstr = SIUnitCopySymbol(self._c_ref)
        if symbol_ocstr == NULL:
            raise RMNError("Unit has no symbol - this indicates a corrupted or invalid unit")

        try:
            return ocstring_to_pystring(<uint64_t>symbol_ocstr)
        finally:
            OCRelease(<OCTypeRef>symbol_ocstr)

    @property
    def is_si_unit(self):
        """Check if this is an SI unit."""

        return SIUnitIsSIUnit(self._c_ref)

    @property
    def is_coherent_unit(self):
        """Check if this is a coherent unit."""

        return SIUnitIsCoherentUnit(self._c_ref)

    @property
    def is_coherent_si(self):
        """Check if this is a coherent SI unit (alias for is_coherent_unit)."""
        return self.is_coherent_unit

    @property
    def is_cgs_unit(self):
        """Check if this is a CGS unit."""

        return SIUnitIsCGSUnit(self._c_ref)

    @property
    def is_imperial_unit(self):
        """Check if this is an Imperial unit."""

        return SIUnitIsImperialUnit(self._c_ref)

    @property
    def is_atomic_unit(self):
        """Check if this is an atomic unit."""

        return SIUnitIsAtomicUnit(self._c_ref)

    @property
    def is_planck_unit(self):
        """Check if this is a Planck unit."""

        return SIUnitIsPlanckUnit(self._c_ref)

    @property
    def is_constant(self):
        """Check if this unit represents a physical constant."""

        return SIUnitIsConstant(self._c_ref)

    @property
    def dimensionality(self):
        """Get the dimensionality of this unit."""
        if self._c_ref == NULL:
            raise RMNError("Cannot get dimensionality of NULL unit")

        cdef SIDimensionalityRef c_dim = SIUnitGetDimensionality(self._c_ref)
        if c_dim == NULL:
            raise RMNError("Unit has no dimensionality - this indicates a corrupted or invalid unit")

        # Create Dimensionality wrapper using the proper _from_c_ref pattern
        # Note: SIUnitGetDimensionality does not transfer ownership, so we don't need to manage memory
        return Dimensionality._from_c_ref(c_dim)

    @property
    def scale_to_coherent_si(self):
        """Get the scale factor to convert to the coherent SI unit."""

        return SIUnitScaleToCoherentSIUnit(self._c_ref)

    @property
    def is_dimensionless(self):
        """Check if this unit is dimensionless."""

        return SIUnitIsDimensionless(self._c_ref)

    @property
    def is_derived(self):
        """Check if this is a derived unit."""

        # A unit is derived if its dimensionality is derived
        return self.dimensionality.is_derived

    # Unit conversion methods
    def scale_to(self, other):
        """
        Get the scale factor to convert from this unit to another compatible unit.

        Args:
            other (Unit): Target unit to convert to

        Returns:
            float: Scale factor (multiply by this to convert from self to other)

        Examples:
            >>> meter = Unit("m")
            >>> kilometer = Unit("km")
            >>> factor = meter.scale_to(kilometer)
            >>> # factor should be 0.001 (1 m = 0.001 km)
        """
        if not isinstance(other, Unit):
            raise TypeError("Can only get scale factor with another Unit")

        cdef double conversion_factor = SIUnitConversion(self._c_ref, (<Unit>other)._c_ref)

        # SIUnitConversion returns 0 if units are incompatible
        if conversion_factor == 0.0:
            raise RMNError("Cannot convert between units with different dimensionalities")

        return conversion_factor

    def nth_root(self, root):
        """
        Take the nth root of this unit.

        Args:
            root (int): Root to take (e.g., 2 for square root)

        Returns:
            Unit: nth root of the unit

        Examples:
            >>> area = Unit("m^2")
            >>> sqrt_area = area.nth_root(2)  # Should give meter
        """
        if not isinstance(root, int):
            raise TypeError("Root must be an integer")
        if root <= 0:
            raise ValueError("Root must be a positive integer")

        cdef uint8_t c_root = <uint8_t>root
        cdef double unit_multiplier = 1.0
        cdef OCStringRef error_ocstr = NULL

        cdef SIUnitRef result = SIUnitByTakingNthRoot(self._c_ref, c_root,
                                                     &unit_multiplier, &error_ocstr)

        if result == NULL:
            error_msg = "Unknown error"
            if error_ocstr != NULL:
                error_msg = ocstring_to_pystring(<uint64_t>error_ocstr)
                OCRelease(<OCTypeRef>error_ocstr)
            raise RMNError(f"Unit root operation failed: {error_msg}")

        return Unit._from_c_ref(result)

    # Unit reduction and conversion methods
    def reduced(self):
        """
        Get this unit reduced to its lowest terms.

        Returns:
            Unit: Unit in lowest terms
        """
        cdef double unit_multiplier = 1.0

        cdef SIUnitRef result = SIUnitByReducing(self._c_ref, &unit_multiplier)

        if result == NULL:
            raise RMNError("Unit reduction failed")

        return Unit._from_c_ref(result)

    def to_coherent_si(self):
        """
        Convert this unit to its coherent SI representation.

        Returns:
            Unit: Coherent SI unit
        """
        # Get the dimensionality and find the coherent SI unit for it
        dim = self.dimensionality
        if dim is None:
            raise RMNError("Cannot get dimensionality for coherent SI conversion")

        cdef Dimensionality dim_obj = <Dimensionality>dim
        cdef SIDimensionalityRef dim_ref = dim_obj._c_ref
        cdef SIUnitRef result = SIUnitCoherentUnitFromDimensionality(dim_ref)

        if result == NULL:
            raise RMNError("Conversion to coherent SI unit failed")

        return Unit._from_c_ref(result)

    # Additional comparison method
    def is_equivalent(self, other):
        """
        Check if this unit is equivalent to another unit.

        Equivalent units can replace each other without changing the numerical
        value of a scalar (1:1 conversion ratio). For example, mL and cm³ are
        equivalent because 1 mL = 1 cm³.

        Args:
            other (Unit): Unit to compare with

        Returns:
            bool: True if units are equivalent (1:1 convertible)

        Examples:
            >>> ml = Unit("mL")
            >>> cm3 = Unit("cm^3")
            >>> liter = Unit("L")
            >>>
            >>> ml.is_equivalent(cm3)    # True - 1 mL = 1 cm³
            >>> ml.is_equivalent(liter)  # False - 1 mL ≠ 1 L
        """
        if not isinstance(other, Unit):
            return False

        return SIUnitAreEquivalentUnits(self._c_ref, (<Unit>other)._c_ref)

    # Python operator overloading
    def __mul__(self, other):
        """Multiplication operator (*) - multiplies without reducing to lowest terms."""
        if not isinstance(other, Unit):
            raise TypeError("Can only multiply with another Unit")

        cdef double unit_multiplier = 1.0
        cdef OCStringRef error_ocstr = NULL

        cdef SIUnitRef result = SIUnitByMultiplyingWithoutReducing(self._c_ref, (<Unit>other)._c_ref,
                                                                  &unit_multiplier, &error_ocstr)

        if result == NULL:
            error_msg = "Unknown error"
            if error_ocstr != NULL:
                error_msg = ocstring_to_pystring(<uint64_t>error_ocstr)
                OCRelease(<OCTypeRef>error_ocstr)
            raise RMNError(f"Unit multiplication failed: {error_msg}")

        return Unit._from_c_ref(result)

    def __truediv__(self, other):
        """Division operator (/) - divides without reducing to lowest terms."""
        if not isinstance(other, Unit):
            raise TypeError("Can only divide by another Unit")

        cdef double unit_multiplier = 1.0
        cdef OCStringRef error_ocstr = NULL

        cdef SIUnitRef result = SIUnitByDividingWithoutReducing(self._c_ref, (<Unit>other)._c_ref,
                                                               &unit_multiplier, &error_ocstr)

        if error_ocstr != NULL:
            try:
                error_msg = ocstring_to_pystring(<uint64_t>error_ocstr)
            finally:
                OCRelease(<OCTypeRef>error_ocstr)
            raise RMNError(f"Unit division failed: {error_msg}")

        if result == NULL:
            raise RMNError("Unit division failed")

        return Unit._from_c_ref(result)

    def __pow__(self, exponent):
        """Power operator (**) - raises to power without reducing to lowest terms."""
        if not isinstance(exponent, (int, float)):
            raise TypeError("Exponent must be a number")

        cdef double power = float(exponent)
        cdef double unit_multiplier = 1.0
        cdef OCStringRef error_ocstr = NULL
        cdef SIUnitRef result
        cdef uint8_t c_root
        cdef double root_candidate

        # Check if this is an integer power
        if power == int(power):
            # Use integer power function
            unit_multiplier = 1.0
            error_ocstr = NULL

            result = SIUnitByRaisingToPowerWithoutReducing(self._c_ref, power,
                                                          &unit_multiplier, &error_ocstr)

            if result == NULL:
                error_msg = "Unknown error"
                if error_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>error_ocstr)
                    OCRelease(<OCTypeRef>error_ocstr)
                raise RMNError(f"Unit power operation failed: {error_msg}")

            return Unit._from_c_ref(result)

        else:
            # Check if this is a valid integer root (1/n)
            # Only allow simple fractions that represent integer roots
            if power > 0:
                root_candidate = 1.0 / power
                if abs(root_candidate - round(root_candidate)) < 1e-10 and root_candidate >= 1:
                    # This is 1/n where n is a positive integer - use nth root
                    c_root = <uint8_t>round(root_candidate)
                    unit_multiplier = 1.0
                    error_ocstr = NULL

                    result = SIUnitByTakingNthRoot(self._c_ref, c_root,
                                                  &unit_multiplier, &error_ocstr)

                    if result == NULL:
                        error_msg = "Unknown error"
                        if error_ocstr != NULL:
                            error_msg = ocstring_to_pystring(<uint64_t>error_ocstr)
                            OCRelease(<OCTypeRef>error_ocstr)
                        raise RMNError(f"Unit root operation failed: {error_msg}")

                    return Unit._from_c_ref(result)

            # Invalid fractional power
            raise RMNError(f"Cannot raise unit to fractional power {power}. Only integer powers and integer roots (like 0.5 for square root) are allowed.")

    def __eq__(self, other):
        """Equality operator (==)."""
        if isinstance(other, Unit):
            # Simple pointer comparison since SIUnitRef are singletons
            return self._c_ref == (<Unit>other)._c_ref
        elif isinstance(other, str):
            # Try to parse string as a unit and compare pointers
            try:
                other_unit = Unit(other)
                return self._c_ref == other_unit._c_ref
            except (RMNError, TypeError, ValueError):
                # If parsing fails, units are not equal
                return False
        else:
            return False

    def __ne__(self, other):
        """Inequality operator (!=)."""
        return not self.__eq__(other)

    # ================================================================================
    # Unit Analysis and Discovery Methods
    # ================================================================================

    def find_equivalent_units(self):
        """
        Find units that are equivalent (no conversion needed).

        Returns:
            list[Unit]: List of equivalent units
        """
        if self._c_ref == NULL:
            raise RMNError("Cannot find equivalent units for NULL unit")

        cdef OCArrayRef array_c_ref = SIUnitCreateArrayOfEquivalentUnits(self._c_ref)
        if array_c_ref == NULL:
            return []

        try:
            return ocarray_to_pylist(<uint64_t>array_c_ref)
        finally:
            OCRelease(<OCTypeRef>array_c_ref)

    def find_convertible_units(self):
        """
        Find all units this unit can be converted to.

        Returns:
            list[Unit]: List of convertible units
        """
        if self._c_ref == NULL:
            raise RMNError("Cannot find convertible units for NULL unit")

        cdef OCArrayRef array_ref = SIUnitCreateArrayOfConversionUnits(self._c_ref)
        if array_ref == NULL:
            return []

        try:
            return ocarray_to_pylist(<uint64_t>array_ref)
        finally:
            OCRelease(<OCTypeRef>array_ref)

    def find_same_dimensionality(self):
        """
        Find units with identical dimensionality.

        Returns:
            list[Unit]: List of units with same dimensionality
        """
        if self._c_ref == NULL:
            raise RMNError("Cannot find units with same dimensionality for NULL unit")

        cdef SIDimensionalityRef dim_ref = SIUnitGetDimensionality(self._c_ref)
        if dim_ref == NULL:
            return []

        cdef OCArrayRef array_ref = SIUnitCreateArrayOfUnitsForDimensionality(dim_ref)
        if array_ref == NULL:
            return []

        try:
            return ocarray_to_pylist(<uint64_t>array_ref)
        finally:
            OCRelease(<OCTypeRef>array_ref)

    def find_same_reduced_dimensionality(self):
        """
        Find units with same reduced dimensionality.

        Returns:
            list[Unit]: List of units with same reduced dimensionality
        """
        if self._c_ref == NULL:
            raise RMNError("Cannot find units with same reduced dimensionality for NULL unit")

        cdef SIDimensionalityRef dim_ref = SIUnitGetDimensionality(self._c_ref)
        if dim_ref == NULL:
            return []

        cdef OCArrayRef array_ref = SIUnitCreateArrayOfUnitsForSameReducedDimensionality(dim_ref)
        if array_ref == NULL:
            return []

        try:
            return ocarray_to_pylist(<uint64_t>array_ref)
        finally:
            OCRelease(<OCTypeRef>array_ref)

    @classmethod
    def find_units_for_quantity(cls, quantity_name):
        """
        Find all units for a given physical quantity.

        Args:
            quantity_name (str): Name of the physical quantity

        Returns:
            list[Unit]: List of units for the quantity
        """
        if not isinstance(quantity_name, str):
            raise TypeError("quantity_name must be a string")

        from rmnpy.helpers.octypes import ocstring_create_from_pystring

        cdef OCStringRef quantity_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(quantity_name)
        if quantity_ocstr == NULL:
            return []

        cdef OCArrayRef array_ref = SIUnitCreateArrayOfUnitsForQuantity(quantity_ocstr)
        cdef list result = []

        try:
            if array_ref != NULL:
                result = ocarray_to_pylist(<uint64_t>array_ref)
        finally:
            OCRelease(<OCTypeRef>quantity_ocstr)
            if array_ref != NULL:
                OCRelease(<OCTypeRef>array_ref)

        return result

    # String representation
    def __str__(self):
        """
        String representation - unit symbol like 'm/s' or '1' for dimensionless.

        Returns:
            str: Unit symbol representation
        """
        if self._c_ref == NULL:
            raise RMNError("Cannot get string representation of NULL unit")

        cdef OCStringRef symbol_ocstr = SIUnitCopySymbol(self._c_ref)
        if symbol_ocstr == NULL:
            raise RMNError("Unit has no symbol - this indicates a corrupted or invalid unit")

        try:
            return ocstring_to_pystring(<uint64_t>symbol_ocstr)
        finally:
            OCRelease(<OCTypeRef>symbol_ocstr)

    def __repr__(self):
        """Return a detailed string representation."""
        return f"Unit('{str(self)}')"


# ====================================================================================
# SIUnit Helper Functions
# ====================================================================================

def siunit_to_pyunit(uint64_t si_unit_ptr):
    """
    Convert an SIUnitRef to a Python Unit object.

    Args:
        si_unit_ptr (uint64_t): Pointer to SIUnitRef

    Returns:
        Unit: Python Unit object

    Raises:
        ValueError: If the SIUnitRef is NULL
        RuntimeError: If Unit class is not available or conversion fails
    """
    cdef SIUnitRef si_unit = <SIUnitRef>si_unit_ptr

    if si_unit == NULL:
        raise ValueError("SIUnitRef is NULL")

    # Use the Unit class's _from_c_ref method to create a proper Unit object
    # No retention needed since SIUnitRef are singletons managed by SILibrary
    return Unit._from_c_ref(si_unit)
