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
    OCTypeDeepCopy,
    OCTypeRef,
)
from rmnpy._c_api.sitypes cimport *
from rmnpy.wrappers.base_wrapper cimport BaseWrapper, SITypesWrapper

from rmnpy.exceptions import RMNError

from rmnpy.wrappers.sitypes.dimensionality cimport Dimensionality

from rmnpy.helpers.octypes import ocarray_to_pylist, ocstring_to_pystring

from libc.stdint cimport uint64_t, uintptr_t


cdef class Unit(SITypesWrapper):
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

        cdef OCStringRef expr_ocstr = <OCStringRef><uintptr_t>ocstring_create_from_pystring(expression)
        cdef OCStringRef error_ocstr = <OCStringRef>0
        cdef double unit_multiplier = 1.0
        cdef SIUnitRef c_ref

        try:
            c_ref = SIUnitFromExpression(expr_ocstr, &unit_multiplier, &error_ocstr)

            if c_ref == NULL:
                if error_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uintptr_t>error_ocstr)
                    raise RMNError(f"Failed to parse unit expression '{expression}': {error_msg}")
                else:
                    raise RMNError(f"Failed to parse unit expression '{expression}': Unknown error")

            # Validate that multiplier is exactly 1.0 - this is a safety check
            if unit_multiplier != 1.0:
                # Release the unit before raising error
                OCRelease(<OCTypeRef>c_ref)
                raise RMNError(f"Unit expression '{expression}' returned unexpected multiplier {unit_multiplier}, expected 1.0")

            # Store the C reference (cast to OCTypeRef)
            self._c_ref = <OCTypeRef>c_ref

        finally:
            OCRelease(<OCTypeRef>expr_ocstr)
            if error_ocstr != <OCStringRef>0:
                OCRelease(<OCTypeRef>error_ocstr)

    def __dealloc__(self):
        # Units are static instances managed by SITypes library
        # No need to release them
        pass

    # ========================================================================
    # Class methods for creating Units from various input types
    # ========================================================================

    @classmethod
    def from_value(cls, value):
        """
        Create a Unit from various input types.

        This class method provides a unified interface for creating Unit objects
        from different Python types, following the same conversion logic as the
        internal helper function but returning Unit objects directly.

        Args:
            value: Input value to convert
                - Unit objects: Returns the object directly
                - str: Creates Unit from string expression
                - None: Returns dimensionless unit

        Returns:
            Unit: Unit object created from the input value

        Raises:
            TypeError: If input type is not supported
            RMNError: If unit creation fails

        Examples:
            >>> u1 = Unit.from_value("m")           # Meter unit
            >>> u2 = Unit.from_value("m/s")         # Velocity unit
            >>> u3 = Unit.from_value(None)          # Dimensionless unit
            >>> u4 = Unit.from_value(existing_unit) # Returns existing unit directly
        """
        if value is None:
            # Return dimensionless unit
            return cls.dimensionless()
        elif isinstance(value, Unit):
            # If it's already a Unit, return it directly
            return value
        elif isinstance(value, str):
            # Create Unit from string expression using constructor
            return cls(value)
        else:
            raise TypeError(f"Cannot convert {type(value)} to Unit")

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

        cdef OCStringRef name_ocstr = <OCStringRef><uintptr_t>ocstring_create_from_pystring(name)
        cdef SIUnitRef c_ref

        try:
            c_ref = SIUnitFindWithName(name_ocstr)

            if c_ref == NULL:
                return None

            # Create Python wrapper using _from_c_ref
            return <Unit>BaseWrapper._from_c_ref(Unit, <void*>c_ref)

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

        return <Unit>BaseWrapper._from_c_ref(Unit, <void*>c_ref)

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

        return <Unit>BaseWrapper._from_c_ref(Unit, <void*>c_ref)

    # Properties
    @property
    def name(self):
        """Get the unit name (e.g., 'meter per second')."""

        cdef OCStringRef name_ocstr = SIUnitCopyName(self._c_ref)
        if name_ocstr == NULL:
            return ""

        try:
            return ocstring_to_pystring(<uintptr_t>name_ocstr)
        finally:
            OCRelease(<OCTypeRef>name_ocstr)

    @property
    def plural(self):
        """Get the plural unit name (e.g., 'meters per second')."""
        cdef OCStringRef plural_ocstr = SIUnitCopyPluralName(self._c_ref)
        if plural_ocstr == NULL:
            return ""

        try:
            return ocstring_to_pystring(<uintptr_t>plural_ocstr)
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
            return ocstring_to_pystring(<uintptr_t>symbol_ocstr)
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
        return Dimensionality._from_c_ref(Dimensionality, <void*>c_dim)

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
            other (Unit or str): Target unit to convert to. Can be a Unit object or string expression.

        Returns:
            float: Scale factor (multiply by this to convert from self to other)

        Examples:
            >>> meter = Unit("m")
            >>> kilometer = Unit("km")
            >>> factor = meter.scale_to(kilometer)
            >>> # factor should be 0.001 (1 m = 0.001 km)
            >>>
            >>> # Can also use string expressions
            >>> factor2 = meter.scale_to("km")
            >>> # factor2 should be 0.001 (1 m = 0.001 km)
        """
        cdef SIUnitRef other_ref
        cdef double conversion_factor
        cdef Unit other_obj

        other_obj = Unit.from_value(other)
        other_ref = (<SIUnitRef>other_obj._get_c_ref())

        try:
            conversion_factor = SIUnitConversion(self._c_ref, other_ref)

            if conversion_factor == 0.0:
                raise RMNError("Cannot convert between units with different dimensionalities")

            return conversion_factor
        finally:
            if other_ref != NULL:
                OCRelease(<OCTypeRef>other_ref)

    # Unit conversion methods
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

        return <Unit>BaseWrapper._from_c_ref(Unit, <void*>result)

    # Additional comparison method
    def is_equivalent(self, other):
        """
        Check if this unit is equivalent to another unit.

        Equivalent units can replace each other without changing the numerical
        value of a scalar (1:1 conversion ratio). For example, mL and cm³ are
        equivalent because 1 mL = 1 cm³.

        Args:
            other (Unit or str): Unit to compare with. Can be a Unit object or string expression.

        Returns:
            bool: True if units are equivalent (1:1 convertible)

        Examples:
            >>> ml = Unit("mL")
            >>> cm3 = Unit("cm^3")
            >>> liter = Unit("L")
            >>>
            >>> ml.is_equivalent(cm3)    # True - 1 mL = 1 cm³
            >>> ml.is_equivalent(liter)  # False - 1 mL ≠ 1 L
            >>> ml.is_equivalent("cm^3") # True - string support
        """
        cdef SIUnitRef other_ref
        cdef Unit other_obj

        try:
            other_obj = Unit.from_value(other)
            other_ref = (<SIUnitRef>other_obj._get_c_ref())
            return SIUnitAreEquivalentUnits(self._c_ref, other_ref)
        except (TypeError, RMNError):
            return False
        finally:
            if 'other_ref' in locals() and other_ref != NULL:
                OCRelease(<OCTypeRef>other_ref)

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
            return ocarray_to_pylist(<uintptr_t>array_c_ref)
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
            return ocarray_to_pylist(<uintptr_t>array_ref)
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
            return ocarray_to_pylist(<uintptr_t>array_ref)
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
            return ocarray_to_pylist(<uintptr_t>array_ref)
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

        cdef OCStringRef quantity_ocstr = <OCStringRef><uintptr_t>ocstring_create_from_pystring(quantity_name)
        if quantity_ocstr == NULL:
            return []

        cdef OCArrayRef array_ref = SIUnitCreateArrayOfUnitsForQuantity(quantity_ocstr)
        cdef list result = []

        try:
            if array_ref != NULL:
                result = ocarray_to_pylist(<uintptr_t>array_ref)
        finally:
            OCRelease(<OCTypeRef>quantity_ocstr)
            if array_ref != NULL:
                OCRelease(<OCTypeRef>array_ref)

        return result


# ====================================================================================
# SIUnit Helper Functions
# ====================================================================================

def get_unit_symbol_tokens_lib():
    """
    Get all possible unit symbol tokens for derived units from the SITypes library.

    Returns:
        list: List of unit symbol token strings

    Raises:
        RuntimeError: If unable to get unit symbol tokens from the library
    """
    cdef OCMutableArrayRef symbols_array = SIUnitGetTokenSymbolsLib()

    if symbols_array == NULL:
        raise RuntimeError("Failed to get unit symbol tokens from SITypes library")

    # Convert OCMutableArrayRef to Python list
    try:
        return ocarray_to_pylist(<uintptr_t>symbols_array)
    finally:
        # The array is owned by the library, so we don't need to release it
        pass
