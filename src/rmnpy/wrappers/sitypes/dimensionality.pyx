# cython: language_level=3
"""
RMNpy SIDimensionality Wrapper - Phase 2A Complete Implementation

Full-featured wrapper for SIDimensionality providing comprehensive dimensional analysis capabilities.
This implementation includes all methods for scientific computing applications.
"""

from rmnpy._c_api.octypes cimport (
    OCRelease,
    OCStringRef,
    OCTypeRef,
)
from rmnpy._c_api.sitypes cimport *

from rmnpy.exceptions import RMNError
from rmnpy.helpers.octypes import ocstring_to_pystring

from libc.stdint cimport uint64_t


cdef class Dimensionality:
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

            # Store the C reference
            self._c_ref = c_ref

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
            >>> from rmnpy.quantities import kSIQuantityPressure, kSIQuantityEnergy
            >>> pressure_dim = Dimensionality.for_quantity(kSIQuantityPressure)
            >>> energy_dim = Dimensionality.for_quantity(kSIQuantityEnergy)
            >>>
            >>> # Also works with strings directly:
            >>> pressure_dim2 = Dimensionality.for_quantity("pressure")
        """
        cdef OCStringRef error_ocstr = NULL

        # Handle both string constants and OCStringRef objects
        if isinstance(quantity_constant, str):
            # Convert Python string to OCStringRef
            from rmnpy.helpers.octypes import ocstring_create_from_pystring
            quantity_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(quantity_constant)
        else:
            # Reject anything that's not a string
            raise TypeError(
                "quantity_constant must be a string from the constants module. "
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

            return Dimensionality._from_c_ref(c_ref)

        except Exception as e:
            if "TypeError" in str(type(e)):
                raise
            raise RMNError(f"Invalid quantity constant: {e}")
        finally:
            # Always clean up the quantity string
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
        return Dimensionality._from_c_ref(c_ref)

    @staticmethod
    cdef Dimensionality _from_c_ref(SIDimensionalityRef c_ref):
        """Create Dimensionality wrapper from C reference (internal use)."""
        cdef Dimensionality result = Dimensionality()
        result._c_ref = c_ref
        return result

    @property
    def is_dimensionless(self):
        """
        Check if this dimensionality is physically dimensionless.

        Returns:
            bool: True if all reduced exponents are zero
        """
        return SIDimensionalityIsDimensionless(self._c_ref)

    @property
    def is_derived(self):
        """
        Check if this dimensionality is derived (compound).

        Returns:
            bool: True if derived from multiple base dimensions
        """
        return SIDimensionalityIsDerived(self._c_ref)

    @property
    def is_base_dimensionality(self):
        """
        Check if this matches exactly one SI base dimension.

        Returns:
            bool: True if represents a single base dimension
        """
        return SIDimensionalityIsBaseDimensionality(self._c_ref)

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

        return SIDimensionalityCanBeReduced(self._c_ref)

    def is_compatible_with(self, other):
        """
        Test physical compatibility (same reduced dimensionality).

        Args:
            other (Dimensionality): Other dimensionality to check

        Returns:
            bool: True if physically compatible
        """
        if not isinstance(other, Dimensionality):
            return False

        return SIDimensionalityHasSameReducedDimensionality(self._c_ref, (<Dimensionality>other)._c_ref)

    def has_same_reduced_dimensionality(self, other):
        """
        Check if this dimensionality has the same reduced dimensionality as another.

        This compares the reduced dimensionalities to determine if they represent
        the same physical quantity type after reduction. This is the same as
        is_compatible_with but with a more descriptive name.

        Args:
            other (Dimensionality): Dimensionality to compare reduced form with

        Returns:
            bool: True if dimensionalities have the same reduced form

        Examples:
            >>> length = Dimensionality("L")
            >>> length_squared_per_length = Dimensionality("L^2/L")
            >>> length.has_same_reduced_dimensionality(length_squared_per_length)  # True - both reduce to L
            >>>
            >>> time = Dimensionality("T")
            >>> length.has_same_reduced_dimensionality(time)  # False - L vs T
        """
        if not isinstance(other, Dimensionality):
            return False

        return SIDimensionalityHasSameReducedDimensionality(self._c_ref, (<Dimensionality>other)._c_ref)

    def nth_root(self, n):
        """
        Take the nth root of this dimensionality.

        Args:
            n (int): Root to take (must be positive)

        Returns:
            Dimensionality: nth root dimensionality

        Raises:
            RMNError: If root operation fails or is invalid
        """
        if n <= 0:
            raise ValueError(f"Root must be positive, got {n}")

        if self._c_ref == NULL:
            raise RMNError("Cannot take root of NULL dimensionality")

        cdef OCStringRef error_ocstr = NULL
        cdef SIDimensionalityRef result = SIDimensionalityByTakingNthRoot(
            self._c_ref, n, &error_ocstr)

        if error_ocstr != NULL:
            error_msg = ocstring_to_pystring(<uint64_t>error_ocstr)
            OCRelease(<OCTypeRef>error_ocstr)
            raise RMNError(f"Dimensionality root operation failed: {error_msg}")

        if result == NULL:
            raise RMNError("Dimensionality root operation failed")

        return Dimensionality._from_c_ref(result)

    def reduced(self):
        """
        Get this dimensionality with all exponents reduced to lowest terms.

        Returns:
            Dimensionality: Reduced form dimensionality
        """

        cdef SIDimensionalityRef result = SIDimensionalityByReducing(self._c_ref)

        if result == NULL:
            raise RMNError("Dimensionality reduction failed")

        return Dimensionality._from_c_ref(result)

    def __str__(self):
        """
        String representation - canonical symbol like "M•L^2•T^-2" or "L•T^-1".

        Returns:
            str: Canonical symbol representation of this dimensionality
        """

        cdef OCStringRef symbol_str = SIDimensionalityCopySymbol(self._c_ref)
        try:
            return ocstring_to_pystring(<uint64_t>symbol_str)
        finally:
            OCRelease(<OCTypeRef>symbol_str)

    def __repr__(self):
        """Detailed string representation."""
        return f"Dimensionality('{str(self)}')"

    def __eq__(self, other):
        """Equality comparison (==) - strict equality with same rational exponents."""
        if isinstance(other, Dimensionality):
            if self._c_ref == NULL or (<Dimensionality>other)._c_ref == NULL:
                return self._c_ref == (<Dimensionality>other)._c_ref
            return SIDimensionalityEqual(self._c_ref, (<Dimensionality>other)._c_ref)
        elif isinstance(other, str):
            # Try to parse string as a dimensionality and compare
            try:
                other_dim = Dimensionality(other)
                if self._c_ref == NULL or other_dim._c_ref == NULL:
                    return self._c_ref == other_dim._c_ref
                return SIDimensionalityEqual(self._c_ref, other_dim._c_ref)
            except (RMNError, TypeError, ValueError):
                # If parsing fails, dimensionalities are not equal
                return False
        else:
            return False

    def __mul__(self, other):
        """Multiplication operator (*)."""
        if not isinstance(other, Dimensionality):
            raise TypeError("Can only multiply with another Dimensionality")

        if self._c_ref == NULL or (<Dimensionality>other)._c_ref == NULL:
            raise RMNError("Cannot multiply with NULL dimensionality")

        cdef OCStringRef error_ocstr = NULL
        cdef SIDimensionalityRef result = SIDimensionalityByMultiplying(
            self._c_ref, (<Dimensionality>other)._c_ref, &error_ocstr)

        if error_ocstr != NULL:
            error_msg = ocstring_to_pystring(<uint64_t>error_ocstr)
            OCRelease(<OCTypeRef>error_ocstr)
            raise RMNError(f"Dimensionality multiplication failed: {error_msg}")

        if result == NULL:
            raise RMNError("Dimensionality multiplication failed")

        return Dimensionality._from_c_ref(result)

    def __truediv__(self, other):
        """Division operator (/)."""
        if not isinstance(other, Dimensionality):
            raise TypeError("Can only divide by another Dimensionality")

        if self._c_ref == NULL or (<Dimensionality>other)._c_ref == NULL:
            raise RMNError("Cannot divide with NULL dimensionality")

        cdef SIDimensionalityRef result = SIDimensionalityByDividing(
            self._c_ref, (<Dimensionality>other)._c_ref)

        if result == NULL:
            raise RMNError("Dimensionality division failed")

        return Dimensionality._from_c_ref(result)

    def __pow__(self, exponent):
        """Power operator (**)."""
        if self._c_ref == NULL:
            raise RMNError("Cannot raise NULL dimensionality to power")

        cdef OCStringRef error_ocstr = NULL
        cdef SIDimensionalityRef result = SIDimensionalityByRaisingToPower(
            self._c_ref, float(exponent), &error_ocstr)

        if error_ocstr != NULL:
            error_msg = ocstring_to_pystring(<uint64_t>error_ocstr)
            OCRelease(<OCTypeRef>error_ocstr)
            raise RMNError(f"Dimensionality power operation failed: {error_msg}")

        if result == NULL:
            raise RMNError("Dimensionality power operation failed")

        return Dimensionality._from_c_ref(result)


# ====================================================================================
# SIDimensionality Helper Functions
# ====================================================================================

def sidimensionality_to_dimensionality(uint64_t si_dimensionality_ptr):
    """
    Convert an SIDimensionalityRef to a Python Dimensionality object.

    Args:
        si_dimensionality_ptr (uint64_t): Pointer to SIDimensionalityRef

    Returns:
        Dimensionality: Python Dimensionality object

    Raises:
        ValueError: If the SIDimensionalityRef is NULL
        RuntimeError: If Dimensionality class is not available or conversion fails
    """
    cdef SIDimensionalityRef si_dimensionality = <SIDimensionalityRef>si_dimensionality_ptr

    if si_dimensionality == NULL:
        raise ValueError("SIDimensionalityRef is NULL")

    # Use the Dimensionality class's _from_c_ref method to create a proper Dimensionality object
    # No retention needed since SIDimensionalityRef are singletons managed by SILibrary
    return Dimensionality._from_c_ref(si_dimensionality)
