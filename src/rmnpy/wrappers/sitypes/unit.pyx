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
    OCStringCreateWithCString,
    OCStringGetCString,
    OCStringRef,
    OCTypeRef,
)
from rmnpy._c_api.sitypes cimport *

from rmnpy.exceptions import RMNError

from rmnpy.wrappers.sitypes.dimensionality cimport Dimensionality

from rmnpy.helpers.octypes import pystring_from_ocstring

from libc.stdint cimport uint64_t, uintptr_t


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
        self._c_unit = NULL

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
            # Empty constructor for internal use (e.g., _from_ref)
            return

        if not isinstance(expression, str):
            raise TypeError("Expression must be a string")

        # Check for empty string - raise error at Python level
        if not expression.strip():
            raise RMNError("Failed to parse unit expression '': Empty unit expression")

        cdef bytes expr_bytes = expression.encode('utf-8')
        cdef OCStringRef expr_string = OCStringCreateWithCString(expr_bytes)
        cdef OCStringRef error_string = <OCStringRef>0
        cdef double unit_multiplier = 1.0
        cdef SIUnitRef c_unit

        try:
            c_unit = SIUnitFromExpression(expr_string, &unit_multiplier, &error_string)

            if c_unit == NULL:
                if error_string != NULL:
                    error_msg = pystring_from_ocstring(<uint64_t>error_string)
                    raise RMNError(f"Failed to parse unit expression '{expression}': {error_msg}")
                else:
                    raise RMNError(f"Failed to parse unit expression '{expression}': Unknown error")

            # Validate that multiplier is exactly 1.0 - this is a safety check
            # since we eliminated the parse() method based on this assumption
            if unit_multiplier != 1.0:
                # Release the unit before raising error
                OCRelease(<OCTypeRef>c_unit)
                raise RMNError(f"Unit expression '{expression}' returned unexpected multiplier {unit_multiplier}, expected 1.0")

            # Store the C reference
            self._c_unit = c_unit

        finally:
            OCRelease(<OCTypeRef>expr_string)
            if error_string != <OCStringRef>0:
                OCRelease(<OCTypeRef>error_string)

    def __dealloc__(self):
        # Units are static instances managed by SITypes library
        # No need to release them
        pass

    @staticmethod
    cdef Unit _from_ref(SIUnitRef unit_ref):
        """Create Unit wrapper from C reference (internal use)."""
        cdef Unit result = Unit()
        result._c_unit = unit_ref
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

        cdef bytes name_bytes = name.encode('utf-8')
        cdef OCStringRef name_string = OCStringCreateWithCString(name_bytes)
        cdef SIUnitRef c_unit

        try:
            c_unit = SIUnitFindWithName(name_string)

            if c_unit == NULL:
                return None

            # Create Python wrapper using _from_ref
            return Unit._from_ref(c_unit)

        finally:
            OCRelease(<OCTypeRef>name_string)

    @classmethod
    def dimensionless(cls):
        """
        Create the dimensionless unit (1).

        Returns:
            Unit: Dimensionless unit
        """
        cdef SIUnitRef c_unit = SIUnitDimensionlessAndUnderived()

        return Unit._from_ref(c_unit)

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

        # Access the _dim_ref attribute using the proper cdef approach
        cdef Dimensionality dim_obj = <Dimensionality>dimensionality
        cdef SIDimensionalityRef dim_ref = dim_obj._dim_ref
        cdef SIUnitRef c_unit = SIUnitCoherentUnitFromDimensionality(dim_ref)

        if c_unit == NULL:
            return None

        return Unit._from_ref(c_unit)

    # Properties
    @property
    def name(self):
        """Get the unit name (e.g., 'meter per second')."""
        if self._c_unit == NULL:
            return ""

        cdef OCStringRef name_string = SIUnitCopyName(self._c_unit)
        if name_string == NULL:
            return ""

        try:
            return pystring_from_ocstring(<uint64_t>name_string)
        finally:
            OCRelease(<OCTypeRef>name_string)

    @property
    def plural(self):
        """Get the plural unit name (e.g., 'meters per second')."""
        if self._c_unit == NULL:
            return ""

        cdef OCStringRef plural_string = SIUnitCopyPluralName(self._c_unit)
        if plural_string == NULL:
            return ""

        try:
            return pystring_from_ocstring(<uint64_t>plural_string)
        finally:
            OCRelease(<OCTypeRef>plural_string)

    @property
    def symbol(self):
        """Get the symbol of this unit."""
        if self._c_unit == NULL:
            return ""

        cdef OCStringRef symbol_string = SIUnitCopySymbol(self._c_unit)
        if symbol_string == NULL:
            return ""

        try:
            return pystring_from_ocstring(<uint64_t>symbol_string)
        finally:
            OCRelease(<OCTypeRef>symbol_string)

    @property
    def is_si_unit(self):
        """Check if this is an SI unit."""
        if self._c_unit == NULL:
            return False

        return SIUnitIsSIUnit(self._c_unit)

    @property
    def is_coherent_unit(self):
        """Check if this is a coherent unit."""
        if self._c_unit == NULL:
            return False

        return SIUnitIsCoherentUnit(self._c_unit)

    @property
    def is_coherent_si(self):
        """Check if this is a coherent SI unit (alias for is_coherent_unit)."""
        return self.is_coherent_unit

    @property
    def is_cgs_unit(self):
        """Check if this is a CGS unit."""
        if self._c_unit == NULL:
            return False

        return SIUnitIsCGSUnit(self._c_unit)

    @property
    def is_imperial_unit(self):
        """Check if this is an Imperial unit."""
        if self._c_unit == NULL:
            return False

        return SIUnitIsImperialUnit(self._c_unit)

    @property
    def is_atomic_unit(self):
        """Check if this is an atomic unit."""
        if self._c_unit == NULL:
            return False

        return SIUnitIsAtomicUnit(self._c_unit)

    @property
    def is_planck_unit(self):
        """Check if this is a Planck unit."""
        if self._c_unit == NULL:
            return False

        return SIUnitIsPlanckUnit(self._c_unit)

    @property
    def is_constant(self):
        """Check if this unit represents a physical constant."""
        if self._c_unit == NULL:
            return False

        return SIUnitIsConstant(self._c_unit)

    @property
    def dimensionality(self):
        """Get the dimensionality of this unit."""
        if self._c_unit == <SIUnitRef>0:
            return None

        cdef SIDimensionalityRef c_dim = SIUnitGetDimensionality(self._c_unit)
        if c_dim == <SIDimensionalityRef>0:
            return None

        # Create Dimensionality wrapper using the proper _from_ref pattern
        # Note: SIUnitGetDimensionality does not transfer ownership, so we don't need to manage memory
        return Dimensionality._from_ref(c_dim)

    @property
    def scale_to_coherent_si(self):
        """Get the scale factor to convert to the coherent SI unit."""
        if self._c_unit == NULL:
            return 1.0

        return SIUnitScaleToCoherentSIUnit(self._c_unit)

    @property
    def is_dimensionless(self):
        """Check if this unit is dimensionless."""
        if self._c_unit == <SIUnitRef>0:
            return False

        return SIUnitIsDimensionless(self._c_unit)

    @property
    def is_derived(self):
        """Check if this is a derived unit."""
        if self._c_unit == NULL:
            return False

        # A unit is derived if its dimensionality is derived
        return self.dimensionality.is_derived


    @property
    def is_reduced(self):
        """Check if this unit is reduced to lowest terms."""
        if self._c_unit == NULL:
            return False

        # Since there's no direct function, we'll implement a basic check
        # by comparing with the reduced version
        cdef double multiplier = 1.0
        cdef SIUnitRef reduced = SIUnitByReducing(self._c_unit, &multiplier)

        if reduced == NULL:
            return False

        try:
            return SIUnitEqual(self._c_unit, reduced)
        finally:
            OCRelease(<OCTypeRef>reduced)

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

        # Check dimensional compatibility first
        if not self.has_same_reduced_dimensionality(other):
            raise RMNError("Cannot convert between units with different dimensionalities")

        return SIUnitConversion(self._c_unit, (<Unit>other)._c_unit)

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
        cdef OCStringRef error_string = NULL

        cdef SIUnitRef result = SIUnitByTakingNthRoot(self._c_unit, c_root,
                                                     &unit_multiplier, &error_string)

        if result == NULL:
            error_msg = "Unknown error"
            if error_string != NULL:
                error_msg = pystring_from_ocstring(<uint64_t>error_string)
                OCRelease(<OCTypeRef>error_string)
            raise RMNError(f"Unit root operation failed: {error_msg}")

        return Unit._from_ref(result)

    # Unit reduction and conversion methods
    def reduced(self):
        """
        Get this unit reduced to its lowest terms.

        Returns:
            Unit: Unit in lowest terms
        """
        cdef double unit_multiplier = 1.0

        cdef SIUnitRef result = SIUnitByReducing(self._c_unit, &unit_multiplier)

        if result == NULL:
            raise RMNError("Unit reduction failed")

        return Unit._from_ref(result)

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
        cdef SIDimensionalityRef dim_ref = dim_obj._dim_ref
        cdef SIUnitRef result = SIUnitCoherentUnitFromDimensionality(dim_ref)

        if result == NULL:
            raise RMNError("Conversion to coherent SI unit failed")

        return Unit._from_ref(result)

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

        return SIUnitAreEquivalentUnits(self._c_unit, (<Unit>other)._c_unit)

    def has_same_reduced_dimensionality(self, other):
        """
        Check if this unit has the same reduced dimensionality as another unit.

        This compares the reduced dimensionalities of both units to determine
        if they represent the same physical quantity type after reduction.

        Args:
            other (Unit): Unit to compare reduced dimensionality with

        Returns:
            bool: True if units have the same reduced dimensionality

        Examples:
            >>> meter = Unit("m")
            >>> kilometer = Unit("km")
            >>> meter.has_same_reduced_dimensionality(kilometer)  # True - both reduce to length
            >>>
            >>> second = Unit("s")
            >>> meter.has_same_reduced_dimensionality(second)     # False - length vs time
        """
        if not isinstance(other, Unit):
            return False

        # Compare reduced dimensionalities for physical compatibility
        self_dim = self.dimensionality
        other_dim = other.dimensionality
        if self_dim is None or other_dim is None:
            return self_dim is other_dim

        return self_dim.reduced() == other_dim.reduced()

    # Python operator overloading
    def __mul__(self, other):
        """Multiplication operator (*) - multiplies without reducing to lowest terms."""
        if not isinstance(other, Unit):
            raise TypeError("Can only multiply with another Unit")

        cdef double unit_multiplier = 1.0
        cdef OCStringRef error_string = NULL

        cdef SIUnitRef result = SIUnitByMultiplyingWithoutReducing(self._c_unit, (<Unit>other)._c_unit,
                                                                  &unit_multiplier, &error_string)

        if result == NULL:
            error_msg = "Unknown error"
            if error_string != NULL:
                error_msg = pystring_from_ocstring(<uint64_t>error_string)
                OCRelease(<OCTypeRef>error_string)
            raise RMNError(f"Unit multiplication failed: {error_msg}")

        return Unit._from_ref(result)

    def __truediv__(self, other):
        """Division operator (/) - divides without reducing to lowest terms."""
        if not isinstance(other, Unit):
            raise TypeError("Can only divide by another Unit")

        cdef double unit_multiplier = 1.0
        cdef OCStringRef error_string = NULL

        cdef SIUnitRef result = SIUnitByDividingWithoutReducing(self._c_unit, (<Unit>other)._c_unit,
                                                               &unit_multiplier, &error_string)

        if error_string != NULL:
            try:
                error_msg = pystring_from_ocstring(<uint64_t>error_string)
            finally:
                OCRelease(<OCTypeRef>error_string)
            raise RMNError(f"Unit division failed: {error_msg}")

        if result == NULL:
            raise RMNError("Unit division failed")

        return Unit._from_ref(result)

    def __pow__(self, exponent):
        """Power operator (**) - raises to power without reducing to lowest terms."""
        if not isinstance(exponent, (int, float)):
            raise TypeError("Exponent must be a number")

        cdef double power = float(exponent)
        cdef double unit_multiplier = 1.0
        cdef OCStringRef error_string = NULL
        cdef SIUnitRef result
        cdef uint8_t c_root
        cdef double root_candidate

        # Check if this is an integer power
        if power == int(power):
            # Use integer power function
            unit_multiplier = 1.0
            error_string = NULL

            result = SIUnitByRaisingToPowerWithoutReducing(self._c_unit, power,
                                                          &unit_multiplier, &error_string)

            if result == NULL:
                error_msg = "Unknown error"
                if error_string != NULL:
                    error_msg = pystring_from_ocstring(<uint64_t>error_string)
                    OCRelease(<OCTypeRef>error_string)
                raise RMNError(f"Unit power operation failed: {error_msg}")

            return Unit._from_ref(result)

        else:
            # Check if this is a valid integer root (1/n)
            # Only allow simple fractions that represent integer roots
            if power > 0:
                root_candidate = 1.0 / power
                if abs(root_candidate - round(root_candidate)) < 1e-10 and root_candidate >= 1:
                    # This is 1/n where n is a positive integer - use nth root
                    c_root = <uint8_t>round(root_candidate)
                    unit_multiplier = 1.0
                    error_string = NULL

                    result = SIUnitByTakingNthRoot(self._c_unit, c_root,
                                                  &unit_multiplier, &error_string)

                    if result == NULL:
                        error_msg = "Unknown error"
                        if error_string != NULL:
                            error_msg = pystring_from_ocstring(<uint64_t>error_string)
                            OCRelease(<OCTypeRef>error_string)
                        raise RMNError(f"Unit root operation failed: {error_msg}")

                    return Unit._from_ref(result)

            # Invalid fractional power
            raise RMNError(f"Cannot raise unit to fractional power {power}. Only integer powers and integer roots (like 0.5 for square root) are allowed.")

    def __eq__(self, other):
        """Equality operator (==)."""
        if isinstance(other, Unit):
            # Simple pointer comparison since SIUnitRef are singletons
            return self._c_unit == (<Unit>other)._c_unit
        elif isinstance(other, str):
            # Try to parse string as a unit and compare pointers
            try:
                other_unit = Unit(other)
                return self._c_unit == other_unit._c_unit
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
        if self._c_unit == NULL:
            return []

        cdef OCArrayRef array_ref = SIUnitCreateArrayOfEquivalentUnits(self._c_unit)
        if array_ref == NULL:
            return []

        try:
            return self._array_ref_to_unit_list(array_ref)
        finally:
            OCRelease(<OCTypeRef>array_ref)

    def find_convertible_units(self):
        """
        Find all units this unit can be converted to.

        Returns:
            list[Unit]: List of convertible units
        """
        if self._c_unit == NULL:
            return []

        cdef OCArrayRef array_ref = SIUnitCreateArrayOfConversionUnits(self._c_unit)
        if array_ref == NULL:
            return []

        try:
            return self._array_ref_to_unit_list(array_ref)
        finally:
            OCRelease(<OCTypeRef>array_ref)

    def find_same_dimensionality(self):
        """
        Find units with identical dimensionality.

        Returns:
            list[Unit]: List of units with same dimensionality
        """
        if self._c_unit == NULL:
            return []

        cdef SIDimensionalityRef dim_ref = SIUnitGetDimensionality(self._c_unit)
        if dim_ref == NULL:
            return []

        cdef OCArrayRef array_ref = SIUnitCreateArrayOfUnitsForDimensionality(dim_ref)
        if array_ref == NULL:
            return []

        try:
            return self._array_ref_to_unit_list(array_ref)
        finally:
            OCRelease(<OCTypeRef>array_ref)

    def find_same_reduced_dimensionality(self):
        """
        Find units with same reduced dimensionality.

        Returns:
            list[Unit]: List of units with same reduced dimensionality
        """
        if self._c_unit == NULL:
            return []

        cdef SIDimensionalityRef dim_ref = SIUnitGetDimensionality(self._c_unit)
        if dim_ref == NULL:
            return []

        cdef OCArrayRef array_ref = SIUnitCreateArrayOfUnitsForSameReducedDimensionality(dim_ref)
        if array_ref == NULL:
            return []

        try:
            return self._array_ref_to_unit_list(array_ref)
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

        cdef OCStringRef quantity_string = OCStringCreateWithCString(quantity_name.encode('utf-8'))
        if quantity_string == NULL:
            return []

        cdef OCArrayRef array_ref = SIUnitCreateArrayOfUnitsForQuantity(quantity_string)
        cdef list result = []

        try:
            if array_ref != NULL:
                result = Unit._array_ref_to_unit_list_static(array_ref)
        finally:
            OCRelease(<OCTypeRef>quantity_string)
            if array_ref != NULL:
                OCRelease(<OCTypeRef>array_ref)

        return result

    cdef list _array_ref_to_unit_list(self, OCArrayRef array_ref):
        """Convert OCArrayRef of units to Python list."""
        return Unit._array_ref_to_unit_list_static(array_ref)

    @staticmethod
    cdef list _array_ref_to_unit_list_static(OCArrayRef array_ref):
        """Convert OCArrayRef of units to Python list (static version)."""
        if array_ref == NULL:
            return []

        cdef uint64_t count = OCArrayGetCount(array_ref)
        cdef list result = []
        cdef SIUnitRef unit_ref
        cdef Unit unit_obj

        for i in range(count):
            unit_ref = <SIUnitRef>OCArrayGetValueAtIndex(array_ref, i)
            if unit_ref != NULL:
                # Create a new Unit object wrapping this SIUnitRef
                unit_obj = Unit.__new__(Unit)
                unit_obj._c_unit = unit_ref  # Direct assignment - SIUnitRef is immutable
                result.append(unit_obj)

        return result

    # String representation
    def __str__(self):
        """
        String representation - unit symbol like 'm/s' or '1' for dimensionless.

        Returns:
            str: Unit symbol representation
        """
        if self._c_unit == NULL:
            return ""

        # Special case for dimensionless unit
        if SIUnitIsDimensionless(self._c_unit):
            return "1"

        cdef OCStringRef symbol_string = SIUnitCopySymbol(self._c_unit)
        if symbol_string == NULL:
            return ""

        try:
            return pystring_from_ocstring(<uint64_t>symbol_string)
        finally:
            OCRelease(<OCTypeRef>symbol_string)

    def __repr__(self):
        """Return a detailed string representation."""
        return f"Unit('{str(self)}')"
