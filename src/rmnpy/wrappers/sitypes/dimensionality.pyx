# cython: language_level=3
"""
RMNpy SIDimensionality Wrapper - Phase 2A Complete Implementation

Full-featured wrapper for SIDimensionality providing comprehensive dimensional analysis capabilities.
This implementation includes all methods for scientific computing applications.
"""

from rmnpy._c_api.octypes cimport (
    OCRelease,
    OCStringRef,
    OCTypeDeepCopy,
    OCTypeEqual,
    OCTypeRef,
)
from rmnpy._c_api.sitypes cimport *
from rmnpy.wrappers.base_wrapper cimport BaseWrapper, SITypesWrapper

from rmnpy.exceptions import RMNError
from rmnpy.helpers.octypes import ocstring_create_from_pystring, ocstring_to_pystring

from libc.stdint cimport uint64_t


# Helper function for converting various input types to SIDimensionalityRef
cdef SIDimensionalityRef sidimensionality_from_pytype(value) except NULL:
    """
    Convert various input types to SIDimensionalityRef.

    Accepts:
    - Dimensionality objects: Returns copy of their C reference
    - str: Creates Dimensionality from string expression
    - None: Returns dimensionless dimensionality

    Returns:
        SIDimensionalityRef: C reference to dimensionality (caller owns reference and must release)

    Raises:
        TypeError: If input type is not supported
        RMNError: If dimensionality creation fails
    """
    cdef Dimensionality temp_dim

    if value is None:
        return SIDimensionalityDimensionless()
    elif isinstance(value, Dimensionality):
        return <SIDimensionalityRef>OCTypeDeepCopy((<Dimensionality>value)._c_ref)
    elif isinstance(value, str):
        # Create Dimensionality from string, then return copy of its reference
        temp_dim = Dimensionality(value)
        return <SIDimensionalityRef>OCTypeDeepCopy(temp_dim._c_ref)
    else:
        raise TypeError(f"Cannot convert {type(value)} to SIDimensionalityRef")


cdef class Dimensionality(SITypesWrapper):
    """
    Python wrapper for SIDimensionality - represents a physical dimensionality.

    A dimensionality encodes the exponents of the seven SI base dimensions:
    - Length (L): meter [m]
    - Mass (M): kilogram [kg]
    - Time (T): second [s]
    - Current (I): ampere [A]
    - Temperature (K): kelvin [K]
    - Amount (N): mole [mol]
    - Luminous Intensity (J): candela [cd]

    Examples:
        >>> # Create from expression
        >>> vel = Dimensionality("L/T")  # velocity
        >>> force = Dimensionality("M*L/T^2")  # force
        >>>
        >>> # Test properties
        >>> vel.is_derived
        True
        >>> force.symbol
        'kg*m/s^2'
        >>>
        >>> # Dimensional algebra
        >>> energy = force * Dimensionality("L")  # F*L = energy
        >>> energy.symbol
        'kg*m^2/s^2'
        >>>
        >>> # Check compatibility
        >>> vel.is_compatible_with(Dimensionality("m/s"))
        True
    """

    def __init__(self, expression=None):
        """
        Create a Dimensionality from a string expression.

        Args:
            expression (str, optional): Dimensional expression like "L^2*M/T^2" or "T^-1"
                If None, creates an empty dimensionality wrapper (for internal use)

        Examples:
            >>> velocity = Dimensionality("L/T")
            >>> energy = Dimensionality("M*L^2/T^2")
            >>> frequency = Dimensionality("T^-1")
        """
        if expression is None:
            # Empty constructor for internal use
            return

        from rmnpy.helpers.octypes import ocstring_create_from_pystring

        cdef OCStringRef expr_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(expression)
        cdef OCStringRef error_ocstr = NULL
        cdef SIDimensionalityRef c_ref

        try:
            c_ref = SIDimensionalityFromExpression(expr_ocstr, &error_ocstr)

            if error_ocstr != NULL:
                error_msg = ocstring_to_pystring(<uint64_t>error_ocstr)
                OCRelease(<OCTypeRef>error_ocstr)
                raise RMNError(f"Failed to parse dimensionality expression '{expression}': {error_msg}")

            if c_ref == NULL:
                raise RMNError(f"Failed to parse dimensionality expression '{expression}': Unknown error")

            self._c_ref = <OCTypeRef>c_ref

        finally:
            OCRelease(<OCTypeRef>expr_ocstr)

    @staticmethod
    def for_quantity(quantity_constant):
        """
        Create dimensionality from a predefined physical quantity constant.

        Args:
            quantity_constant (str): A quantity constant string. Can be one of the
                                   kSIQuantity* constants from the quantities module
                                   or the equivalent string value.

        Returns:
            Dimensionality: Dimensionality for the quantity constant

        Raises:
            RMNError: If quantity constant is not recognized

        Examples:
            >>> # Import quantity constants
            >>> from rmnpy.sitypes import quantity as q
            >>> pressure_dim = Dimensionality.for_quantity(q.Pressure)
            >>> energy_dim = Dimensionality.for_quantity(q.Energy)
            >>>
            >>> # Also works with strings directly:
            >>> pressure_dim2 = Dimensionality.for_quantity("pressure")
        """
        cdef OCStringRef error_ocstr = NULL

        # Handle both string constants and OCStringRef objects
        if isinstance(quantity_constant, str):
            from rmnpy.helpers.octypes import ocstring_create_from_pystring
            quantity_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(quantity_constant)
        else:
            raise TypeError(
                "quantity_constant must be a string from the quantity module. "
                f"Got type: {type(quantity_constant)}"
            )

        cdef SIDimensionalityRef c_ref

        try:
            c_ref = SIDimensionalityForQuantity(quantity_ocstr, &error_ocstr)

            if error_ocstr != NULL:
                error_msg = ocstring_to_pystring(<uint64_t>error_ocstr)
                OCRelease(<OCTypeRef>error_ocstr)
                raise RMNError(f"Unknown quantity constant: {error_msg}")

            if c_ref == NULL:
                raise RMNError("Failed to create dimensionality for quantity constant")

            return <Dimensionality>BaseWrapper._from_c_ref(Dimensionality, <void*>c_ref)

        except Exception as e:
            if "TypeError" in str(type(e)):
                raise
            raise RMNError(f"Invalid quantity constant: {e}")
        finally:
            OCRelease(<OCTypeRef>quantity_ocstr)

    @staticmethod
    def dimensionless():
        """
        Create the canonical dimensionless dimensionality.

        Returns:
            Dimensionality: Dimensionless dimensionality (all exponents = 0)

        Examples:
            >>> d = Dimensionality.dimensionless()
            >>> d.is_dimensionless
            True
        """
        cdef SIDimensionalityRef c_ref = SIDimensionalityDimensionless()
        return <Dimensionality>BaseWrapper._from_c_ref(Dimensionality, <void*>c_ref)

    @property
    def is_dimensionless(self):
        """
        Check if this dimensionality is physically dimensionless.

        Returns:
            bool: True if all reduced exponents are zero
        """
        return SIDimensionalityIsDimensionless(<SIDimensionalityRef>self._c_ref)

    @property
    def is_derived(self):
        """
        Check if this dimensionality is derived (compound).

        Returns:
            bool: True if derived from multiple base dimensions
        """
        return SIDimensionalityIsDerived(<SIDimensionalityRef>self._c_ref)

    @property
    def is_base_dimensionality(self):
        """
        Check if this matches exactly one SI base dimension.

        Returns:
            bool: True if represents a single base dimension
        """
        return SIDimensionalityIsBaseDimensionality(<SIDimensionalityRef>self._c_ref)

    @property
    def is_reducible(self):
        """
        Check if this dimensionality can be reduced by canceling common factors.

        A dimensionality is reducible if it has common factors between
        numerator and denominator exponents for any base dimension.

        Returns:
            bool: True if dimensionality can be reduced

        Examples:
            >>> area_per_length = Dimensionality("L^2/L")
            >>> area_per_length.is_reducible
            True
            >>>
            >>> # m/s -> not reducible (no common factors)
            >>> velocity = Dimensionality("L/T")
            >>> velocity.is_reducible
            False
        """
        if self._c_ref == NULL:
            raise RMNError("Cannot check reducibility of dimensionality with NULL reference")

        return SIDimensionalityCanBeReduced(<SIDimensionalityRef>self._c_ref)

    def is_compatible_with(self, other):
        """
        Test physical compatibility (same reduced dimensionality).

        Args:
            other (Dimensionality, str, or None): Other dimensionality to check.
                Can be a Dimensionality object, string expression, or None for dimensionless.

        Returns:
            bool: True if physically compatible

        Examples:
            >>> length = Dimensionality("L")
            >>> length.is_compatible_with("L")        # True - same dimensionality
            >>> length.is_compatible_with("T")        # False - length vs time
            >>>
            >>> # Also works with reduced forms:
            >>> length = Dimensionality("L")
            >>> length_squared_per_length = Dimensionality("L^2/L")
            >>> length.is_compatible_with(length_squared_per_length)  # True - both reduce to L
        """
        cdef SIDimensionalityRef other_ref = sidimensionality_from_pytype(other)

        return SIDimensionalityHasSameReducedDimensionality(<SIDimensionalityRef>self._c_ref, other_ref)

    # Alias for backward compatibility
    def has_same_reduced_dimensionality(self, other):
        """Alias for is_compatible_with() - checks if dimensionalities have the same reduced form."""
        return self.is_compatible_with(other)

    def __eq__(self, other):
        """Equality comparison with string and None support."""
        if not isinstance(other, BaseWrapper):
            other_ref = sidimensionality_from_pytype(other)
            return OCTypeEqual(self._c_ref, <OCTypeRef>other_ref)

        return super().__eq__(other)

    def __ne__(self, other):
        """Inequality comparison with string and None support."""
        if not isinstance(other, BaseWrapper):
            other_ref = sidimensionality_from_pytype(other)
            return not OCTypeEqual(self._c_ref, <OCTypeRef>other_ref)

        return super().__ne__(other)
