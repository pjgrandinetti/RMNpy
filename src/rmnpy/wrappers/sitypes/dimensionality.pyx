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
    - Dimensionality objects: Returns their C reference
    - str: Creates Dimensionality from string expression
    - None: Returns dimensionless dimensionality

    Returns:
        SIDimensionalityRef: C reference to dimensionality (singleton, no need to release)

    Raises:
        TypeError: If input type is not supported
        RMNError: If dimensionality creation fails
    """
    cdef Dimensionality temp_dim
    cdef OCStringRef expr_ocstr = NULL
    cdef OCStringRef error_ocstr = NULL
    cdef SIDimensionalityRef result = NULL

    if value is None:
        return SIDimensionalityDimensionless()
    elif isinstance(value, Dimensionality):
        return (<Dimensionality>value)._c_ref
    elif isinstance(value, str):
        try:
            expr_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(value)
            result = SIDimensionalityFromExpression(expr_ocstr, &error_ocstr)

            if error_ocstr != NULL:
                error_msg = ocstring_to_pystring(<uint64_t>error_ocstr)
                OCRelease(<OCTypeRef>error_ocstr)
                raise RMNError(f"Failed to create dimensionality from expression '{value}': {error_msg}")

            if result == NULL:
                raise RMNError(f"Failed to create dimensionality from expression '{value}'")

            return result
        finally:
            if expr_ocstr != NULL:
                OCRelease(<OCTypeRef>expr_ocstr)
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

    def __cinit__(self):
        """Initialize empty dimensionality wrapper."""
        self._c_ref = NULL

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

            return Dimensionality._from_c_ref(Dimensionality, <void*>c_ref)

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
        return Dimensionality._from_c_ref(Dimensionality, <void*>c_ref)

    @staticmethod
    cdef Dimensionality _from_c_ref(object cls, void* c_ref):
        """Create Dimensionality wrapper from C reference (internal use)."""
        cdef Dimensionality result = <Dimensionality>cls()
        result._c_ref = <OCTypeRef>OCTypeDeepCopy(<OCTypeRef>c_ref)
        return result

    @staticmethod
    def from_c_ref(uint64_t c_ref_ptr):
        """Create Dimensionality wrapper from C reference pointer (Python-accessible)."""
        return Dimensionality._from_c_ref(Dimensionality, <void*>c_ref_ptr)

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
            >>> length.is_compatible_with("m")        # True - both are length
            >>> length.is_compatible_with("L")        # True - same as above
            >>> length.is_compatible_with("T")        # False - length vs time
        """
        cdef SIDimensionalityRef other_ref = sidimensionality_from_pytype(other)

        return SIDimensionalityHasSameReducedDimensionality(<SIDimensionalityRef>self._c_ref, other_ref)

    def has_same_reduced_dimensionality(self, other):
        """
        Check if this dimensionality has the same reduced dimensionality as another.

        This compares the reduced dimensionalities to determine if they represent
        the same physical quantity type after reduction. This is the same as
        is_compatible_with but with a more descriptive name.

        Args:
            other (Dimensionality, str, or None): Dimensionality to compare reduced form with.
                Can be a Dimensionality object, string expression, or None for dimensionless.

        Returns:
            bool: True if dimensionalities have the same reduced form

        Examples:
            >>> length = Dimensionality("L")
            >>> length_squared_per_length = Dimensionality("L^2/L")
            >>> length.has_same_reduced_dimensionality(length_squared_per_length)  # True - both reduce to L
            >>>
            >>> time = Dimensionality("T")
            >>> length.has_same_reduced_dimensionality(time)  # False - L vs T
            >>> length.has_same_reduced_dimensionality("T")   # False - L vs T (string)
        """
        cdef SIDimensionalityRef other_ref = sidimensionality_from_pytype(other)

        return SIDimensionalityHasSameReducedDimensionality(<SIDimensionalityRef>self._c_ref, other_ref)

    def reduced(self):
        """
        Get this dimensionality with all exponents reduced to lowest terms.

        Returns:
            Dimensionality: Reduced form dimensionality
        """

        cdef SIDimensionalityRef result = SIDimensionalityByReducing(<SIDimensionalityRef>self._c_ref)

        if result == NULL:
            raise RMNError("Dimensionality reduction failed")

        return Dimensionality._from_c_ref(Dimensionality, <void*>result)

    def __str__(self):
        """
        String representation - canonical symbol like "M•L^2•T^-2" or "L•T^-1".

        Returns:
            str: Canonical symbol representation of this dimensionality
        """

        cdef OCStringRef symbol_str = SIDimensionalityCopySymbol(<SIDimensionalityRef>self._c_ref)
        try:
            return ocstring_to_pystring(<uint64_t>symbol_str)
        finally:
            OCRelease(<OCTypeRef>symbol_str)

    def __repr__(self):
        """Detailed string representation."""
        return f"Dimensionality('{str(self)}')"

    # Abstract method implementations for SITypesWrapper
    def _binary_arithmetic(self, other, operation):
        """Handle binary arithmetic operations."""
        cdef SIDimensionalityRef other_ref = sidimensionality_from_pytype(other)

        if self._c_ref == NULL or other_ref == NULL:
            raise RMNError(f"Cannot {operation} with NULL dimensionality")

        cdef SIDimensionalityRef result = NULL

        if operation == "mul":
            result = SIDimensionalityByMultiplying(<SIDimensionalityRef>self._c_ref, other_ref)
        elif operation == "div":
            result = SIDimensionalityByDividing(<SIDimensionalityRef>self._c_ref, other_ref)
        else:
            raise ValueError(f"Unsupported binary operation: {operation}")

        if result == NULL:
            raise RMNError(f"Dimensionality {operation} operation failed")
        return Dimensionality._from_c_ref(Dimensionality, <void*>result)

    def _power_arithmetic(self, exponent):
        """Handle power operations."""
        if self._c_ref == NULL:
            raise RMNError("Cannot raise NULL dimensionality to power")

        cdef SIDimensionalityRef result = SIDimensionalityByRaisingToPower(
            <SIDimensionalityRef>self._c_ref, float(exponent))

        if result == NULL:
            raise RMNError("Dimensionality power operation failed")
        return Dimensionality._from_c_ref(Dimensionality, <void*>result)

    def _nth_root_arithmetic(self, n):
        """Take the nth root using C API."""
        if self._c_ref == NULL:
            raise RMNError("Cannot take root of NULL dimensionality")

        cdef OCStringRef error_ocstr = NULL
        cdef SIDimensionalityRef result = SIDimensionalityByTakingNthRoot(
            <SIDimensionalityRef>self._c_ref, n, &error_ocstr)

        if error_ocstr != NULL:
            error_msg = ocstring_to_pystring(<uint64_t>error_ocstr)
            OCRelease(<OCTypeRef>error_ocstr)
            raise RMNError(f"Dimensionality root operation failed: {error_msg}")

        if result == NULL:
            raise RMNError("Dimensionality root operation failed")

        return Dimensionality._from_c_ref(Dimensionality, <void*>result)

    def _unary_arithmetic(self, operation):
        """Handle unary arithmetic operations."""
        raise TypeError(f"Dimensionality does not support unary arithmetic operation: {operation}")

    def __eq__(self, other):
        """Equality comparison with string and None support."""
        if not isinstance(other, BaseWrapper):
            other_ref = sidimensionality_from_pytype(other)
            return OCTypeEqual(self._c_ref, <OCTypeRef>other_ref)

        return super().__eq__(other)
