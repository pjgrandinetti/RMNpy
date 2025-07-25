# cython: language_level=3
"""
RMNpy SIScalar Wrapper - Phase 2C Implementation

Complete wrapper for SIScalar providing comprehensive scalar physical quantity capabilities.
This implementation builds on the SIDimensionality and SIUnit foundations from Phases 2A and 2B.

SIScalar represents a physical quantity with a numerical value, unit, and associated dimensionality.
It supports comprehensive arithmetic operations with automatic unit handling and dimensional validation.
"""

from rmnpy._c_api.octypes cimport (
    OCComparisonResult,
    OCRelease,
    OCStringCreateWithCString,
    OCStringGetCString,
    OCStringRef,
    OCTypeRef,
)
from rmnpy._c_api.sitypes cimport *

from rmnpy.exceptions import RMNError

from rmnpy.wrappers.sitypes.dimensionality cimport Dimensionality

from rmnpy.wrappers.sitypes.dimensionality import Dimensionality

from rmnpy.wrappers.sitypes.unit cimport Unit

from rmnpy.helpers.octypes import parse_c_string
from rmnpy.wrappers.sitypes.unit import Unit

from libc.stdint cimport uint8_t, uint64_t, uintptr_t

import cmath


cdef class Scalar:
    """
    Python wrapper for SIScalar - represents a scalar physical quantity.

    A scalar combines a numerical value with a unit, enabling type-safe scientific computing
    with automatic dimensional analysis and unit conversion capabilities.

    The constructor accepts multiple usage patterns for maximum flexibility:

    **Single Argument Patterns:**
        - String expression: `Scalar("100 J")` creates 100 Joules
        - Numeric value: `Scalar(42)` creates dimensionless 42
        - Complex value: `Scalar(3+4j)` creates dimensionless complex number

    **Two Argument Patterns:**
        - Value and unit: `Scalar(100, "m")` creates 100 meters
        - String value and unit: `Scalar("5.0", "m")` creates 5 meters (legacy)

    **Named Parameter Patterns:**
        - Unit only: `Scalar(expression="m")` creates 1 meter
        - Full specification: `Scalar(value=2.5, expression="W")` creates 2.5 Watts

    The Scalar class provides comprehensive arithmetic operations, unit conversions,
    and dimensional analysis while maintaining type safety and preventing common
    physics calculation errors through automatic dimensional validation.
    """

    cdef SIScalarRef _c_scalar

    def __cinit__(self):
        self._c_scalar = NULL

    def __dealloc__(self):
        if self._c_scalar != NULL:
            OCRelease(<OCTypeRef>self._c_scalar)

    @staticmethod
    cdef Scalar _from_ref(SIScalarRef scalar_ref):
        """Create Scalar wrapper from C reference (internal use)."""
        cdef Scalar result = Scalar.__new__(Scalar)
        result._c_scalar = scalar_ref
        return result

    def __init__(self, value=1.0, expression=None):
        """
        Create a scalar physical quantity with flexible argument patterns.

        This constructor intelligently handles multiple usage patterns to provide
        maximum flexibility while maintaining backward compatibility.

        Args:
            value (numeric or str, optional):
                - If `expression` is None and `value` is str: Full expression (e.g., "100 J")
                - If `expression` is None and `value` is numeric: Dimensionless value
                - If `expression` is provided: Numeric multiplier for the expression
                - Default: 1.0
            expression (str, optional):
                - Unit expression like "m", "m/s", "kg*m/s^2", "J", "W"
                - If None, behavior depends on `value` type
                - Default: None

        Returns:
            Scalar: New scalar object with specified value and unit

        Raises:
            TypeError: If arguments have incompatible types
            ValueError: If string values cannot be parsed as numbers
            RMNError: If unit expression is invalid or cannot be parsed

        Note:
            All numeric types are supported including int, float, complex,
            Decimal, and Fraction. The underlying SITypes library handles
            dimensional analysis and unit validation automatically.
        """
        if self._c_scalar != NULL:
            return  # Already initialized by _from_ref

        # Handle single argument cases
        if expression is None:
            if isinstance(value, str):
                # Single string argument: treat as full expression
                expression = value
                value = 1.0
            elif isinstance(value, (int, float, complex)):
                # Single numeric argument: create dimensionless scalar
                expression = "1"  # Dimensionless unit
                # value stays as provided
            else:
                raise TypeError("Single argument must be a string expression or numeric value")
        else:
            # Two arguments provided - both should be compatible
            if not isinstance(expression, str):
                raise TypeError("Expression must be a string")

            # If value is string, try to parse it as a number
            if isinstance(value, str):
                try:
                    # Try to parse as float first, then int
                    if '.' in value or 'e' in value.lower() or 'E' in value:
                        value = float(value)
                    else:
                        value = int(value)
                except ValueError:
                    raise ValueError(f"Cannot parse numeric value from '{value}'")

        if not isinstance(expression, str):
            raise TypeError("Expression must be a string")

        # Create base scalar from expression
        cdef bytes expr_bytes = expression.encode('utf-8')
        cdef OCStringRef expr_ref = OCStringCreateWithCString(expr_bytes)
        cdef OCStringRef error_string = NULL
        cdef SIScalarRef base_scalar
        cdef SIScalarRef result

        try:
            base_scalar = SIScalarCreateFromExpression(expr_ref, &error_string)

            if base_scalar == NULL:
                if error_string != NULL:
                    error_msg = parse_c_string(<uint64_t>error_string)
                    OCRelease(<OCTypeRef>error_string)
                    raise RMNError(f"Failed to parse scalar expression '{expression}': {error_msg}")
                else:
                    raise RMNError(f"Failed to parse scalar expression '{expression}'")

            # If value is 1.0, use base scalar directly
            if value == 1.0:
                self._c_scalar = base_scalar
            else:
                # Multiply by the value
                if isinstance(value, complex):
                    result = SIScalarCreateByMultiplyingByDimensionlessComplexConstant(base_scalar, value)
                else:
                    result = SIScalarCreateByMultiplyingByDimensionlessRealConstant(base_scalar, float(value))

                # Release base scalar since we created a new one
                OCRelease(<OCTypeRef>base_scalar)

                if result == NULL:
                    raise RMNError("Failed to multiply scalar by value")

                self._c_scalar = result

        finally:
            OCRelease(<OCTypeRef>expr_ref)

    # Properties
    @property
    def value(self):
        """Get the numeric value in the current unit (not coherent SI units)."""
        if self._c_scalar == NULL:
            return 0.0

        # Get the value directly from the C function
        # SIScalarDoubleValue returns the value in the current unit
        # (unlike SIScalarDoubleValueInCoherentUnit which always gives the SI base unit value)

        # Check if the scalar contains a complex number using C function
        if SIScalarIsComplex(self._c_scalar):
            return SIScalarDoubleComplexValue(self._c_scalar)
        else:
            # Use the appropriate C function that returns the value in the current unit
            return SIScalarDoubleValue(self._c_scalar)

    @property
    def unit(self):
        """Get the unit of the scalar."""
        if self._c_scalar == NULL:
            return None

        cdef SIUnitRef c_unit = SIQuantityGetUnit(<SIQuantityRef>self._c_scalar)
        if c_unit == NULL:
            return None

        return Unit._from_ref(c_unit)

    @property
    def dimensionality(self):
        """Get the dimensionality of the scalar."""
        if self._c_scalar == NULL:
            return None

        cdef SIDimensionalityRef c_dim = SIQuantityGetUnitDimensionality(<SIQuantityRef>self._c_scalar)
        if c_dim == NULL:
            return None

        return Dimensionality._from_ref(c_dim)

    @property
    def is_real(self):
        """Check if the scalar is a real number."""
        if self._c_scalar == NULL:
            return True
        return SIScalarIsReal(self._c_scalar)

    @property
    def is_complex(self):
        """Check if the scalar has a non-zero imaginary component."""
        if self._c_scalar == NULL:
            return False
        return SIScalarIsComplex(self._c_scalar)

    @property
    def is_imaginary(self):
        """Check if the scalar is purely imaginary."""
        if self._c_scalar == NULL:
            return False
        return SIScalarIsImaginary(self._c_scalar)

    @property
    def is_zero(self):
        """Check if the scalar value is exactly zero."""
        if self._c_scalar == NULL:
            return True
        return SIScalarIsZero(self._c_scalar)

    @property
    def is_infinite(self):
        """Check if the scalar value is infinite."""
        if self._c_scalar == NULL:
            return False
        return SIScalarIsInfinite(self._c_scalar)

    @property
    def magnitude(self):
        """Get the magnitude (absolute value) of the scalar as a Scalar with same unit."""
        if self._c_scalar == NULL:
            raise RMNError("Cannot get magnitude of null scalar")

        cdef SIScalarRef result = SIScalarCreateByTakingComplexPart(self._c_scalar, kSIMagnitudePart)
        if result == NULL:
            raise RMNError("Failed to get magnitude")

        return Scalar._from_ref(result)

    @property
    def argument(self):
        """Get the argument (phase angle) of the scalar in radians as a dimensionless Scalar."""
        if self._c_scalar == NULL:
            raise RMNError("Cannot get argument of null scalar")

        cdef SIScalarRef result = SIScalarCreateByTakingComplexPart(self._c_scalar, kSIArgumentPart)
        if result == NULL:
            raise RMNError("Failed to get argument")

        return Scalar._from_ref(result)

    @property
    def real(self):
        """Get the real part of the scalar as a Scalar with same unit."""
        if self._c_scalar == NULL:
            raise RMNError("Cannot get real part of null scalar")

        cdef SIScalarRef result = SIScalarCreateByTakingComplexPart(self._c_scalar, kSIRealPart)
        if result == NULL:
            raise RMNError("Failed to get real part")

        return Scalar._from_ref(result)

    @property
    def imag(self):
        """Get the imaginary part of the scalar as a Scalar with same unit."""
        if self._c_scalar == NULL:
            raise RMNError("Cannot get imaginary part of null scalar")

        cdef SIScalarRef result = SIScalarCreateByTakingComplexPart(self._c_scalar, kSIImaginaryPart)
        if result == NULL:
            raise RMNError("Failed to get imaginary part")

        return Scalar._from_ref(result)

    # Unit conversion methods
    def convert_to(self, new_unit):
        """
        Convert to a different unit of the same dimensionality.

        Args:
            new_unit (str or Unit): Target unit

        Returns:
            Scalar: New scalar with converted value and unit

        Examples:
            >>> distance = Scalar(1000, "m")
            >>> distance_km = distance.convert_to("km")  # 1.0 km
        """
        if self._c_scalar == NULL:
            raise ValueError("Cannot convert NULL scalar")

        cdef OCStringRef error_string = NULL
        cdef SIScalarRef result
        cdef bytes unit_bytes
        cdef OCStringRef unit_str
        cdef Unit unit_obj

        if isinstance(new_unit, str):
            # Use string-based conversion that creates a new immutable scalar
            unit_bytes = new_unit.encode('utf-8')
            unit_str = OCStringCreateWithCString(unit_bytes)

            try:
                result = SIScalarCreateByConvertingToUnitWithString(self._c_scalar, unit_str, &error_string)
            finally:
                OCRelease(<OCTypeRef>unit_str)

        elif isinstance(new_unit, Unit):
            # Use Unit object directly with immutable conversion
            unit_obj = <Unit>new_unit
            result = SIScalarCreateByConvertingToUnit(self._c_scalar, unit_obj._c_unit, &error_string)

            if result == NULL:
                if error_string != NULL:
                    error_msg = parse_c_string(<uint64_t>error_string)
                    OCRelease(<OCTypeRef>error_string)
                    raise ValueError(f"Unit conversion failed: {error_msg}")
                else:
                    raise ValueError("Unit conversion failed: incompatible dimensions")
        else:
            raise TypeError("Unit must be a string or Unit object")

        if result == NULL:
            raise ValueError("Unit conversion failed")

        return Scalar._from_ref(result)

    def to_coherent_si(self):
        """
        Convert to the coherent SI unit for this dimensionality.

        Returns:
            Scalar: New scalar in coherent SI units

        Examples:
            >>> force = Scalar(1000, "g*m/s^2")  # Non-coherent
            >>> force_si = force.to_coherent_si()  # 1.0 kg*m/s^2 (Newton)
        """
        cdef OCStringRef error_string = NULL
        cdef SIScalarRef result = SIScalarCreateByConvertingToCoherentUnit(self._c_scalar, &error_string)

        if result == NULL:
            if error_string != NULL:
                error_msg = parse_c_string(<uint64_t>error_string)
                OCRelease(<OCTypeRef>error_string)
                raise RMNError(f"Coherent SI conversion failed: {error_msg}")
            else:
                raise RMNError("Coherent SI conversion failed")

        return Scalar._from_ref(result)

    # Arithmetic operations
    def add(self, other):
        """
        Add another scalar to this scalar.

        Args:
            other (Scalar or numeric): Scalar to add, or numeric value (converted to dimensionless scalar)

        Returns:
            Scalar: Sum of the scalars

        Note:
            Both scalars must have compatible (same) dimensionality
        """
        if not isinstance(other, Scalar):
            # Convert Python number to dimensionless scalar
            if isinstance(other, (int, float, complex)):
                other = Scalar(other, "1")  # Create dimensionless scalar
            else:
                raise TypeError("Can only add with another Scalar or numeric value")

        cdef OCStringRef error_string = NULL
        cdef SIScalarRef result = SIScalarCreateByAdding(self._c_scalar, (<Scalar>other)._c_scalar, &error_string)

        if result == NULL:
            if error_string != NULL:
                error_msg = parse_c_string(<uint64_t>error_string)
                OCRelease(<OCTypeRef>error_string)
                raise RMNError(f"Addition failed: {error_msg}")
            else:
                raise RMNError("Addition failed - likely dimensional mismatch")

        return Scalar._from_ref(result)

    def subtract(self, other):
        """
        Subtract another scalar from this scalar.

        Args:
            other (Scalar or numeric): Scalar to subtract, or numeric value (converted to dimensionless scalar)

        Returns:
            Scalar: Difference of the scalars
        """
        if not isinstance(other, Scalar):
            # Convert Python number to dimensionless scalar
            if isinstance(other, (int, float, complex)):
                other = Scalar(other, "1")  # Create dimensionless scalar
            else:
                raise TypeError("Can only subtract another Scalar or numeric value")

        cdef OCStringRef error_string = NULL
        cdef SIScalarRef result = SIScalarCreateBySubtracting(self._c_scalar, (<Scalar>other)._c_scalar, &error_string)

        if result == NULL:
            if error_string != NULL:
                error_msg = parse_c_string(<uint64_t>error_string)
                OCRelease(<OCTypeRef>error_string)
                raise RMNError(f"Subtraction failed: {error_msg}")
            else:
                raise RMNError("Subtraction failed - likely dimensional mismatch")

        return Scalar._from_ref(result)

    def multiply(self, other):
        """
        Multiply this scalar by another scalar.

        Args:
            other (Scalar or numeric): Scalar to multiply by, or numeric value (converted to dimensionless scalar)

        Returns:
            Scalar: Product of the scalars
        """
        if not isinstance(other, Scalar):
            # Convert Python number to dimensionless scalar
            if isinstance(other, (int, float, complex)):
                other = Scalar(other, "1")  # Create dimensionless scalar
            else:
                raise TypeError("Can only multiply with another Scalar or numeric value")

        cdef OCStringRef error_string = NULL
        cdef SIScalarRef result = SIScalarCreateByMultiplying(self._c_scalar, (<Scalar>other)._c_scalar, &error_string)

        if result == NULL:
            if error_string != NULL:
                error_msg = parse_c_string(<uint64_t>error_string)
                OCRelease(<OCTypeRef>error_string)
                raise RMNError(f"Multiplication failed: {error_msg}")
            else:
                raise RMNError("Multiplication failed")

        return Scalar._from_ref(result)

    def divide(self, other):
        """
        Divide this scalar by another scalar.

        Args:
            other (Scalar or numeric): Scalar to divide by, or numeric value (converted to dimensionless scalar)

        Returns:
            Scalar: Quotient of the scalars
        """
        if not isinstance(other, Scalar):
            # Convert Python number to dimensionless scalar
            if isinstance(other, (int, float, complex)):
                if other == 0:
                    raise ZeroDivisionError("Cannot divide by zero")
                other = Scalar(other, "1")  # Create dimensionless scalar
            else:
                raise TypeError("Can only divide by another Scalar or numeric value")

        cdef OCStringRef error_string = NULL
        cdef SIScalarRef result = SIScalarCreateByDividing(self._c_scalar, (<Scalar>other)._c_scalar, &error_string)

        if result == NULL:
            if error_string != NULL:
                error_msg = parse_c_string(<uint64_t>error_string)
                OCRelease(<OCTypeRef>error_string)
                raise RMNError(f"Division failed: {error_msg}")
            else:
                raise RMNError("Division failed")

        return Scalar._from_ref(result)

    def power(self, exponent):
        """
        Raise this scalar to a power.

        Args:
            exponent (float): Power to raise to

        Returns:
            Scalar: Scalar raised to the power
        """
        if not isinstance(exponent, (int, float)):
            raise TypeError("Exponent must be a number")

        cdef int power
        cdef uint8_t root
        cdef OCStringRef error_string = NULL
        cdef SIScalarRef result

        # Check if exponent is an integer or can be treated as one
        if isinstance(exponent, int) or (isinstance(exponent, float) and exponent.is_integer()):
            # Use integer power function
            power = int(exponent)
            result = SIScalarCreateByRaisingToPower(self._c_scalar, power, &error_string)

            if result == NULL:
                if error_string != NULL:
                    error_msg = parse_c_string(<uint64_t>error_string)
                    OCRelease(<OCTypeRef>error_string)
                    raise RMNError(f"Power operation failed: {error_msg}")
                else:
                    raise RMNError("Power operation failed")

            return Scalar._from_ref(result)

        # Check if it's a simple fractional power (1/n)
        elif isinstance(exponent, float):
            # Check if this is 1/n where n is a positive integer
            if exponent > 0 and (1.0 / exponent).is_integer():
                root_value = int(1.0 / exponent)
                if root_value > 0 and root_value <= 255:  # uint8_t range
                    root = <uint8_t>root_value
                    result = SIScalarCreateByTakingNthRoot(self._c_scalar, root, &error_string)

                    if result == NULL:
                        if error_string != NULL:
                            error_msg = parse_c_string(<uint64_t>error_string)
                            OCRelease(<OCTypeRef>error_string)
                            raise RMNError(f"Nth root operation failed: {error_msg}")
                        else:
                            raise RMNError("Nth root operation failed")

                    return Scalar._from_ref(result)

            # Reject other fractional powers
            raise RMNError(f"Fractional power {exponent} is not supported. Only integer powers and simple roots (like 0.5, 0.333...) are allowed.")

        else:
            raise TypeError("Exponent must be a number")

    def abs(self):
        """
        Get the absolute value of this scalar.

        Returns:
            Scalar: Absolute value with same unit
        """
        cdef OCStringRef error_string = NULL
        cdef SIScalarRef result = SIScalarCreateByTakingAbsoluteValue(self._c_scalar, &error_string)

        if result == NULL:
            if error_string != NULL:
                error_msg = parse_c_string(<uint64_t>error_string)
                OCRelease(<OCTypeRef>error_string)
                raise RMNError(f"Absolute value failed: {error_msg}")
            else:
                raise RMNError("Absolute value failed")

        return Scalar._from_ref(result)

    def nth_root(self, root):
        """
        Take the nth root of this scalar.

        Args:
            root (int): Root to take (e.g., 2 for square root)

        Returns:
            Scalar: nth root of the scalar
        """
        if not isinstance(root, int):
            raise TypeError("Root must be an integer")
        if root <= 0:
            raise ValueError("Root must be a positive integer")

        cdef uint8_t c_root = <uint8_t>root
        cdef OCStringRef error_string = NULL
        cdef SIScalarRef result = SIScalarCreateByTakingNthRoot(self._c_scalar, c_root, &error_string)

        if result == NULL:
            if error_string != NULL:
                error_msg = parse_c_string(<uint64_t>error_string)
                OCRelease(<OCTypeRef>error_string)
                raise RMNError(f"Root operation failed: {error_msg}")
            else:
                raise RMNError("Root operation failed")

        return Scalar._from_ref(result)

    # Comparison methods
    def is_equal(self, other):
        """
        Check if this scalar is exactly equal to another scalar.

        Args:
            other (Scalar): Scalar to compare with

        Returns:
            bool: True if scalars are equal

        Raises:
            RMNError: If comparison fails due to dimensional mismatch or other errors
        """
        if not isinstance(other, Scalar):
            return False

        cdef OCComparisonResult result = SIScalarCompareLoose(self._c_scalar, (<Scalar>other)._c_scalar)

        if result == kOCCompareEqualTo:
            return True
        elif result in (kOCCompareLessThan, kOCCompareGreaterThan):
            return False
        elif result == kOCCompareUnequalDimensionalities:
            raise RMNError("Cannot compare scalars with different dimensionalities")
        elif result == kOCCompareNoSingleValue:
            raise RMNError("Cannot compare - no single comparison value available")
        elif result == kOCCompareError:
            raise RMNError("Comparison failed due to internal error")
        else:
            raise RMNError(f"Unexpected comparison result: {result}")

    def compare(self, other):
        """
        Compare this scalar with another scalar.

        Args:
            other (Scalar): Scalar to compare with

        Returns:
            int: Comparison result as integer
            - -1 if self < other
            - 0 if self == other
            - 1 if self > other

        Raises:
            TypeError: If other is not a Scalar
            RMNError: If comparison fails due to dimensional mismatch or other errors
        """
        if not isinstance(other, Scalar):
            raise TypeError("Can only compare with another Scalar")

        cdef OCComparisonResult result = SIScalarCompareLoose(self._c_scalar, (<Scalar>other)._c_scalar)

        if result == kOCCompareLessThan:
            return -1
        elif result == kOCCompareEqualTo:
            return 0
        elif result == kOCCompareGreaterThan:
            return 1
        elif result == kOCCompareUnequalDimensionalities:
            raise RMNError("Cannot compare scalars with different dimensionalities")
        elif result == kOCCompareNoSingleValue:
            raise RMNError("Cannot compare - no single comparison value available")
        elif result == kOCCompareError:
            raise RMNError("Comparison failed due to internal error")
        else:
            raise RMNError(f"Unexpected comparison result: {result}")

    # Python operator overloading
    def __add__(self, other):
        """Addition operator (+)."""
        return self.add(other)

    def __radd__(self, other):
        """Reverse addition operator (+)."""
        # For addition, order doesn't matter: other + self = self + other
        return self.add(other)

    def __sub__(self, other):
        """Subtraction operator (-)."""
        return self.subtract(other)

    def __rsub__(self, other):
        """Reverse subtraction operator (-)."""
        # For reverse subtraction: other - self
        if isinstance(other, (int, float, complex)):
            other_scalar = Scalar(other, "1")  # Create dimensionless scalar
            return other_scalar.subtract(self)
        else:
            return NotImplemented

    def __mul__(self, other):
        """Multiplication operator (*)."""
        cdef SIScalarRef result

        if isinstance(other, Scalar):
            return self.multiply(other)
        elif isinstance(other, (int, float)):
            # Multiply by dimensionless real constant
            result = SIScalarCreateByMultiplyingByDimensionlessRealConstant(
                self._c_scalar, float(other))
            if result == NULL:
                raise RMNError("Failed to multiply by dimensionless constant")
            return Scalar._from_ref(result)
        elif isinstance(other, complex):
            # Multiply by dimensionless complex constant
            result = SIScalarCreateByMultiplyingByDimensionlessComplexConstant(
                self._c_scalar, other)
            if result == NULL:
                raise RMNError("Failed to multiply by dimensionless complex constant")
            return Scalar._from_ref(result)
        else:
            return NotImplemented

    def __rmul__(self, other):
        """Reverse multiplication operator (*)."""
        # Multiplication is commutative for dimensionless constants
        return self.__mul__(other)

    def __truediv__(self, other):
        """Division operator (/)."""
        cdef SIScalarRef result

        if isinstance(other, Scalar):
            return self.divide(other)
        elif isinstance(other, (int, float)):
            # Divide by dimensionless real constant (multiply by 1/constant)
            if other == 0:
                raise ZeroDivisionError("Cannot divide by zero")
            result = SIScalarCreateByMultiplyingByDimensionlessRealConstant(
                self._c_scalar, 1.0 / float(other))
            if result == NULL:
                raise RMNError("Failed to divide by dimensionless constant")
            return Scalar._from_ref(result)
        elif isinstance(other, complex):
            # Divide by dimensionless complex constant (multiply by 1/constant)
            if other == 0:
                raise ZeroDivisionError("Cannot divide by zero")
            result = SIScalarCreateByMultiplyingByDimensionlessComplexConstant(
                self._c_scalar, 1.0 / other)
            if result == NULL:
                raise RMNError("Failed to divide by dimensionless complex constant")
            return Scalar._from_ref(result)
        else:
            return NotImplemented

    def __rtruediv__(self, other):
        """Reverse division operator (/)."""
        # For reverse division: other / self
        if isinstance(other, (int, float, complex)):
            other_scalar = Scalar(other, "1")  # Create dimensionless scalar
            return other_scalar.divide(self)
        else:
            return NotImplemented

    def __pow__(self, exponent):
        """Power operator (**)."""
        return self.power(exponent)

    def __abs__(self):
        """Absolute value operator (abs())."""
        return self.abs()

    def __eq__(self, other):
        """Equality operator (==)."""
        if not isinstance(other, Scalar):
            return False
        try:
            return self.is_equal(other)
        except RMNError:
            # For equality, dimensional mismatch means not equal
            return False

    def __ne__(self, other):
        """Inequality operator (!=)."""
        return not self.is_equal(other)

    def __lt__(self, other):
        """Less than operator (<)."""
        if not isinstance(other, Scalar):
            return NotImplemented
        try:
            return self.compare(other) < 0
        except RMNError:
            return NotImplemented

    def __le__(self, other):
        """Less than or equal operator (<=)."""
        if not isinstance(other, Scalar):
            return NotImplemented
        try:
            return self.compare(other) <= 0
        except RMNError:
            return NotImplemented

    def __gt__(self, other):
        """Greater than operator (>)."""
        if not isinstance(other, Scalar):
            return NotImplemented
        try:
            return self.compare(other) > 0
        except RMNError:
            return NotImplemented

    def __ge__(self, other):
        """Greater than or equal operator (>=)."""
        if not isinstance(other, Scalar):
            return NotImplemented
        try:
            return self.compare(other) >= 0
        except RMNError:
            return NotImplemented

    # String representation
    def __str__(self):
        """Return a string representation of the scalar with value and unit."""
        if self._c_scalar == NULL:
            return "Scalar(0)"

        cdef OCStringRef str_ref = SIScalarCreateStringValue(self._c_scalar)
        if str_ref == NULL:
            return f"Scalar({self.value})"

        try:
            return parse_c_string(<uint64_t>str_ref)
        finally:
            OCRelease(<OCTypeRef>str_ref)

    def __repr__(self):
        """Return a detailed string representation."""
        return f"Scalar(value={self.value!r}, unit='{self.unit.symbol if self.unit else None}')"

    def to_string(self, format_str=None):
        """
        Create a formatted string representation.

        Args:
            format_str (str, optional): Custom format string

        Returns:
            str: Formatted string representation
        """
        cdef OCStringRef str_ref
        cdef bytes format_bytes
        cdef OCStringRef format_ref

        if self._c_scalar == NULL:
            return "Scalar(0)"

        if format_str is not None:
            format_bytes = format_str.encode('utf-8')
            format_ref = OCStringCreateWithCString(format_bytes)
            try:
                str_ref = SIScalarCreateStringValueWithFormat(self._c_scalar, format_ref)
            finally:
                OCRelease(<OCTypeRef>format_ref)
        else:
            str_ref = SIScalarCreateStringValue(self._c_scalar)

        if str_ref == NULL:
            return f"Scalar({self.value})"

        try:
            return parse_c_string(<uint64_t>str_ref)
        finally:
            OCRelease(<OCTypeRef>str_ref)

    # Display methods
    def show(self):
        """Display scalar information to stdout."""
        if self._c_scalar != NULL:
            SIScalarShow(self._c_scalar)

    # Utility methods
    def copy(self):
        """Create a deep copy of this scalar."""
        if self._c_scalar == NULL:
            raise RMNError("Cannot copy null scalar")

        cdef SIScalarRef copy_ref = SIScalarCreateCopy(self._c_scalar)
        if copy_ref == NULL:
            raise RMNError("Failed to create copy")

        return Scalar._from_ref(copy_ref)

    def mutable_copy(self):
        """Create a mutable deep copy of this scalar."""
        if self._c_scalar == NULL:
            raise RMNError("Cannot copy null scalar")

        cdef SIScalarRef copy_ref = SIScalarCreateMutableCopy(self._c_scalar)
        if copy_ref == NULL:
            raise RMNError("Failed to create mutable copy")

        return Scalar._from_ref(copy_ref)
