# cython: language_level=3
"""
RMNpy SIDimensionality Wrapper - Phase 2A Complete Implementation

Full-featured wrapper for SIDimensionality providing comprehensive dimensional analysis capabilities.
This implementation includes all essential methods for scientific computing applications.
"""

from rmnpy._c_api.octypes cimport (
    OCRelease,
    OCStringCreateWithCString,
    OCStringGetCString,
    OCStringRef,
)
from rmnpy._c_api.sitypes cimport *

from rmnpy.exceptions import RMNError
from rmnpy.helpers.octypes import ocstring_create_with_pystring, pystring_from_ocstring

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
        self._dim_ref = NULL

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

        cdef OCStringRef expr_str = <OCStringRef><uint64_t>ocstring_create_with_pystring(expression)
        cdef OCStringRef error_str = NULL
        cdef SIDimensionalityRef dim_ref

        try:
            dim_ref = SIDimensionalityFromExpression(expr_str, &error_str)

            if error_str != NULL:
                error_msg = pystring_from_ocstring(<uint64_t>error_str)
                OCRelease(error_str)
                raise RMNError(f"Failed to parse dimensionality expression '{expression}': {error_msg}")

            if dim_ref == NULL:
                raise RMNError(f"Failed to parse dimensionality expression '{expression}': Unknown error")

            # Store the C reference
            self._dim_ref = dim_ref

        finally:
            OCRelease(expr_str)

    @staticmethod
    def for_quantity(quantity_constant):
        """
        Create dimensionality from a predefined physical quantity constant.

        Args:
            quantity_constant (str): A quantity constant string. Can be one of the
                                   kSIQuantity* constants from the constants module
                                   or the equivalent string value.

        Returns:
            Dimensionality: Dimensionality for the quantity constant

        Raises:
            RMNError: If quantity constant is not recognized

        Examples:
            >>> # Import quantity constants
            >>> from rmnpy.constants import kSIQuantityPressure, kSIQuantityEnergy
            >>> pressure_dim = Dimensionality.for_quantity(kSIQuantityPressure)
            >>> energy_dim = Dimensionality.for_quantity(kSIQuantityEnergy)
            >>>
            >>> # Also works with strings directly:
            >>> pressure_dim2 = Dimensionality.for_quantity("pressure")
        """
        cdef OCStringRef error_str = NULL

        # Handle both string constants and OCStringRef objects
        if isinstance(quantity_constant, str):
            # Convert Python string to OCStringRef using helper function
            quantity_str = <OCStringRef><uint64_t>ocstring_create_with_pystring(quantity_constant)
        else:
            # Reject anything that's not a string
            raise TypeError(
                "quantity_constant must be a string from the constants module. "
                f"Got type: {type(quantity_constant)}"
            )

        cdef SIDimensionalityRef dim_ref

        try:
            dim_ref = SIDimensionalityForQuantity(quantity_str, &error_str)

            if error_str != NULL:
                error_msg = pystring_from_ocstring(<uint64_t>error_str)
                OCRelease(error_str)
                raise RMNError(f"Unknown quantity constant: {error_msg}")

            if dim_ref == NULL:
                raise RMNError("Failed to create dimensionality for quantity constant")

            return Dimensionality._from_ref(dim_ref)

        except Exception as e:
            if "TypeError" in str(type(e)):
                raise
            raise RMNError(f"Invalid quantity constant: {e}")
        finally:
            # Clean up the created string
            OCRelease(quantity_str)

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
        cdef SIDimensionalityRef dim_ref = SIDimensionalityDimensionless()
        return Dimensionality._from_ref(dim_ref)

    @staticmethod
    cdef Dimensionality _from_ref(SIDimensionalityRef dim_ref):
        """Create Dimensionality wrapper from C reference (internal use)."""
        cdef Dimensionality result = Dimensionality()
        result._dim_ref = dim_ref
        return result

    @property
    def is_dimensionless(self):
        """
        Check if this dimensionality is physically dimensionless.

        Returns:
            bool: True if all reduced exponents are zero
        """
        if self._dim_ref == NULL:
            return True

        return SIDimensionalityIsDimensionless(self._dim_ref)

    @property
    def is_derived(self):
        """
        Check if this dimensionality is derived (compound).

        Returns:
            bool: True if derived from multiple base dimensions
        """
        if self._dim_ref == NULL:
            return False

        return SIDimensionalityIsDerived(self._dim_ref)

    @property
    def is_base_dimensionality(self):
        """
        Check if this matches exactly one SI base dimension.

        Returns:
            bool: True if represents a single base dimension
        """
        if self._dim_ref == NULL:
            return False

        return SIDimensionalityIsBaseDimensionality(self._dim_ref)

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

        if self._dim_ref == NULL or (<Dimensionality>other)._dim_ref == NULL:
            return self._dim_ref == (<Dimensionality>other)._dim_ref

        return SIDimensionalityHasSameReducedDimensionality(self._dim_ref, (<Dimensionality>other)._dim_ref)

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

        if self._dim_ref == NULL:
            raise RMNError("Cannot take root of NULL dimensionality")

        cdef OCStringRef error_str = NULL
        cdef SIDimensionalityRef result = SIDimensionalityByTakingNthRoot(
            self._dim_ref, n, &error_str)

        if error_str != NULL:
            error_msg = pystring_from_ocstring(<uint64_t>error_str)
            OCRelease(error_str)
            raise RMNError(f"Dimensionality root operation failed: {error_msg}")

        if result == NULL:
            raise RMNError("Dimensionality root operation failed")

        return Dimensionality._from_ref(result)

    def reduced(self):
        """
        Get this dimensionality with all exponents reduced to lowest terms.

        Returns:
            Dimensionality: Reduced form dimensionality
        """
        if self._dim_ref == NULL:
            return Dimensionality.dimensionless()

        cdef SIDimensionalityRef result = SIDimensionalityByReducing(self._dim_ref)

        if result == NULL:
            raise RMNError("Dimensionality reduction failed")

        return Dimensionality._from_ref(result)

    def __str__(self):
        """
        String representation - canonical symbol like "M•L^2•T^-2" or "L•T^-1".

        Returns:
            str: Canonical symbol representation of this dimensionality
        """
        if self._dim_ref == NULL:
            return ""

        cdef OCStringRef symbol_str = SIDimensionalityCopySymbol(self._dim_ref)
        return pystring_from_ocstring(<uint64_t>symbol_str)

    def __repr__(self):
        """Detailed string representation."""
        return f"Dimensionality('{str(self)}')"

    def __eq__(self, other):
        """Equality comparison (==) - strict equality with same rational exponents."""
        if isinstance(other, Dimensionality):
            if self._dim_ref == NULL or (<Dimensionality>other)._dim_ref == NULL:
                return self._dim_ref == (<Dimensionality>other)._dim_ref
            return SIDimensionalityEqual(self._dim_ref, (<Dimensionality>other)._dim_ref)
        elif isinstance(other, str):
            # Try to parse string as a dimensionality and compare
            try:
                other_dim = Dimensionality(other)
                if self._dim_ref == NULL or other_dim._dim_ref == NULL:
                    return self._dim_ref == other_dim._dim_ref
                return SIDimensionalityEqual(self._dim_ref, other_dim._dim_ref)
            except (RMNError, TypeError, ValueError):
                # If parsing fails, dimensionalities are not equal
                return False
        else:
            return False

    def __mul__(self, other):
        """Multiplication operator (*)."""
        if not isinstance(other, Dimensionality):
            raise TypeError("Can only multiply with another Dimensionality")

        if self._dim_ref == NULL or (<Dimensionality>other)._dim_ref == NULL:
            raise RMNError("Cannot multiply with NULL dimensionality")

        cdef OCStringRef error_str = NULL
        cdef SIDimensionalityRef result = SIDimensionalityByMultiplying(
            self._dim_ref, (<Dimensionality>other)._dim_ref, &error_str)

        if error_str != NULL:
            error_msg = pystring_from_ocstring(<uint64_t>error_str)
            OCRelease(error_str)
            raise RMNError(f"Dimensionality multiplication failed: {error_msg}")

        if result == NULL:
            raise RMNError("Dimensionality multiplication failed")

        return Dimensionality._from_ref(result)

    def __truediv__(self, other):
        """Division operator (/)."""
        if not isinstance(other, Dimensionality):
            raise TypeError("Can only divide by another Dimensionality")

        if self._dim_ref == NULL or (<Dimensionality>other)._dim_ref == NULL:
            raise RMNError("Cannot divide with NULL dimensionality")

        cdef SIDimensionalityRef result = SIDimensionalityByDividing(
            self._dim_ref, (<Dimensionality>other)._dim_ref)

        if result == NULL:
            raise RMNError("Dimensionality division failed")

        return Dimensionality._from_ref(result)

    def __pow__(self, exponent):
        """Power operator (**)."""
        if self._dim_ref == NULL:
            raise RMNError("Cannot raise NULL dimensionality to power")

        cdef OCStringRef error_str = NULL
        cdef SIDimensionalityRef result = SIDimensionalityByRaisingToPower(
            self._dim_ref, float(exponent), &error_str)

        if error_str != NULL:
            error_msg = pystring_from_ocstring(<uint64_t>error_str)
            OCRelease(error_str)
            raise RMNError(f"Dimensionality power operation failed: {error_msg}")

        if result == NULL:
            raise RMNError("Dimensionality power operation failed")

        return Dimensionality._from_ref(result)
