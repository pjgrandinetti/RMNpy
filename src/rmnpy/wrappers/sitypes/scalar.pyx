# cython: language_level=3
"""
RMNpy SIScalar Wrapper

Python wrapper for SIScalar representing physical quantities with units.

SIScalar combines a numerical value with a unit, enabling type-safe scientific computing
with automatic dimensional analysis and unit conversion capabilities. It supports
comprehensive arithmetic operations with automatic unit handling and dimensional validation.
"""

from rmnpy._c_api.octypes cimport (
    OCComparisonResult,
    OCRelease,
    OCStringCreateWithCString,
    OCStringGetCString,
    OCStringRef,
    OCTypeRef,
    kOCCompareEqualTo,
    kOCCompareGreaterThan,
    kOCCompareLessThan,
    kOCCompareUnequalDimensionalities,
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
    def phase(self):
        """Get the phase angle of the scalar in radians as a dimensionless Scalar (same as argument)."""
        return self.argument

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
    def to(self, new_unit):
        """
        Convert to a different unit of the same dimensionality.

        Args:
            new_unit (str or Unit): Target unit

        Returns:
            Scalar: New scalar with converted value and unit

        Examples:
            >>> distance = Scalar(1000, "m")
            >>> distance_km = distance.to("km")  # 1.0 km
            >>> speed = Scalar(60, "mph")
            >>> speed_mps = speed.to("m/s")  # 26.8224 m/s
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

    def can_convert_to(self, new_unit):
        """
        Check if this scalar can be converted to the specified unit.

        Args:
            new_unit (str or Unit): Target unit to check compatibility with

        Returns:
            bool: True if conversion is possible, False otherwise

        Examples:
            >>> distance = Scalar(1000, "m")
            >>> distance.can_convert_to("km")  # True - same dimensionality
            >>> distance.can_convert_to("s")   # False - different dimensionality
        """
        try:
            # Attempt conversion to check compatibility
            self.to(new_unit)
            return True
        except (ValueError, RMNError, TypeError):
            return False

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

    def reduced(self):
        """
        Get this scalar with its unit reduced to lowest terms.

        The numerical value is preserved by converting to the reduced unit.
        For example, Scalar(1.0, "m*s/m") becomes Scalar(1.0, "s").

        Returns:
            Scalar: Scalar with reduced unit

        Examples:
            >>> s = Scalar(1.0, "m*s/m")  # Non-reduced unit
            >>> s_reduced = s.reduced()   # 1.0 s (reduced unit)
        """
        cdef SIScalarRef result = SIScalarCreateByReducingUnit(self._c_scalar)

        if result == NULL:
            raise RMNError("Scalar unit reduction failed")

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

    # Python operator overloading
    def __add__(self, other):
        """Addition operator (+)."""
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

    def __radd__(self, other):
        """Reverse addition operator (+)."""
        # For addition, order doesn't matter: other + self = self + other
        return self.__add__(other)

    def __sub__(self, other):
        """Subtraction operator (-)."""
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

    def __rsub__(self, other):
        """Reverse subtraction operator (-)."""
        # For reverse subtraction: other - self
        if isinstance(other, (int, float, complex)):
            other_scalar = Scalar(other, "1")  # Create dimensionless scalar
            return other_scalar.__sub__(self)
        else:
            return NotImplemented

    def __mul__(self, other):
        """Multiplication operator (*)."""
        cdef SIScalarRef result
        cdef OCStringRef error_string

        if isinstance(other, Scalar):
            # Multiply by another scalar
            error_string = NULL
            result = SIScalarCreateByMultiplying(self._c_scalar, (<Scalar>other)._c_scalar, &error_string)

            if result == NULL:
                if error_string != NULL:
                    error_msg = parse_c_string(<uint64_t>error_string)
                    OCRelease(<OCTypeRef>error_string)
                    raise RMNError(f"Multiplication failed: {error_msg}")
                else:
                    raise RMNError("Multiplication failed")

            return Scalar._from_ref(result)
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
            # Try to handle other numeric types (Decimal, Fraction)
            try:
                # Convert to float and multiply
                float_value = float(other)
                result = SIScalarCreateByMultiplyingByDimensionlessRealConstant(
                    self._c_scalar, float_value)
                if result == NULL:
                    raise RMNError("Failed to multiply by dimensionless constant")
                return Scalar._from_ref(result)
            except (TypeError, ValueError):
                return NotImplemented

    def __rmul__(self, other):
        """Reverse multiplication operator (*)."""
        # Multiplication is commutative for dimensionless constants
        return self.__mul__(other)

    def __truediv__(self, other):
        """Division operator (/)."""
        cdef SIScalarRef result
        cdef OCStringRef error_string

        if isinstance(other, Scalar):
            # Divide by another scalar
            error_string = NULL
            result = SIScalarCreateByDividing(self._c_scalar, (<Scalar>other)._c_scalar, &error_string)

            if result == NULL:
                if error_string != NULL:
                    error_msg = parse_c_string(<uint64_t>error_string)
                    OCRelease(<OCTypeRef>error_string)
                    raise RMNError(f"Division failed: {error_msg}")
                else:
                    raise RMNError("Division failed")

            return Scalar._from_ref(result)
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
            return other_scalar.__truediv__(self)
        else:
            return NotImplemented

    def __pow__(self, exponent):
        """Power operator (**)."""
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

    def __abs__(self):
        """Absolute value operator (abs())."""
        return self.magnitude

    def __eq__(self, other):
        """Equality operator (==)."""
        cdef OCComparisonResult result
        if isinstance(other, Scalar):
            try:
                result = SIScalarCompare(self._c_scalar, (<Scalar>other)._c_scalar)

                if result == kOCCompareEqualTo:
                    return True
                elif result in (kOCCompareLessThan, kOCCompareGreaterThan):
                    return False
                else:
                    # For equality, dimensional mismatch or other errors means not equal
                    return False
            except:
                # For equality, any exception means not equal
                return False
        elif isinstance(other, str):
            # Try to parse string as a scalar and compare
            try:
                other_scalar = Scalar(other)
                result = SIScalarCompare(self._c_scalar, other_scalar._c_scalar)

                if result == kOCCompareEqualTo:
                    return True
                elif result in (kOCCompareLessThan, kOCCompareGreaterThan):
                    return False
                else:
                    # For equality, dimensional mismatch or other errors means not equal
                    return False
            except (RMNError, TypeError, ValueError):
                # If parsing fails, scalars are not equal
                return False
        else:
            return False

    def __ne__(self, other):
        """Inequality operator (!=)."""
        cdef OCComparisonResult result
        if not isinstance(other, Scalar):
            return True
        try:
            result = SIScalarCompare(self._c_scalar, (<Scalar>other)._c_scalar)

            if result == kOCCompareEqualTo:
                return False
            elif result in (kOCCompareLessThan, kOCCompareGreaterThan):
                return True
            elif result == kOCCompareUnequalDimensionalities:
                raise RMNError("Cannot compare scalars with incompatible dimensionalities")
            else:
                # For other errors, treat as not equal
                return True
        except Exception as e:
            if isinstance(e, RMNError):
                raise
            # For other exceptions, treat as not equal
            return True

    def __lt__(self, other):
        """Less than operator (<)."""
        cdef OCComparisonResult result
        if not isinstance(other, Scalar):
            return NotImplemented
        try:
            result = SIScalarCompare(self._c_scalar, (<Scalar>other)._c_scalar)
            if result == kOCCompareLessThan:
                return True
            elif result in (kOCCompareEqualTo, kOCCompareGreaterThan):
                return False
            elif result == kOCCompareUnequalDimensionalities:
                raise TypeError("Cannot order scalars with incompatible dimensionalities")
            else:
                return NotImplemented
        except Exception as e:
            if isinstance(e, TypeError):
                raise
            return NotImplemented

    def __le__(self, other):
        """Less than or equal operator (<=)."""
        cdef OCComparisonResult result
        if not isinstance(other, Scalar):
            return NotImplemented
        try:
            result = SIScalarCompare(self._c_scalar, (<Scalar>other)._c_scalar)
            if result in (kOCCompareLessThan, kOCCompareEqualTo):
                return True
            elif result == kOCCompareGreaterThan:
                return False
            elif result == kOCCompareUnequalDimensionalities:
                raise TypeError("Cannot order scalars with incompatible dimensionalities")
            else:
                return NotImplemented
        except Exception as e:
            if isinstance(e, TypeError):
                raise
            return NotImplemented

    def __gt__(self, other):
        """Greater than operator (>)."""
        cdef OCComparisonResult result
        if not isinstance(other, Scalar):
            return NotImplemented
        try:
            result = SIScalarCompare(self._c_scalar, (<Scalar>other)._c_scalar)
            if result == kOCCompareGreaterThan:
                return True
            elif result in (kOCCompareEqualTo, kOCCompareLessThan):
                return False
            elif result == kOCCompareUnequalDimensionalities:
                raise TypeError("Cannot order scalars with incompatible dimensionalities")
            else:
                return NotImplemented
        except Exception as e:
            if isinstance(e, TypeError):
                raise
            return NotImplemented

    def __ge__(self, other):
        """Greater than or equal operator (>=)."""
        cdef OCComparisonResult result
        if not isinstance(other, Scalar):
            return NotImplemented
        try:
            result = SIScalarCompare(self._c_scalar, (<Scalar>other)._c_scalar)
            if result in (kOCCompareGreaterThan, kOCCompareEqualTo):
                return True
            elif result == kOCCompareLessThan:
                return False
            elif result == kOCCompareUnequalDimensionalities:
                raise TypeError("Cannot order scalars with incompatible dimensionalities")
            else:
                return NotImplemented
        except Exception as e:
            if isinstance(e, TypeError):
                raise
            return NotImplemented

    def __hash__(self):
        """
        Hash the scalar based on its value and unit for use in sets and as dict keys.

        Note: Only real scalars with finite values can be hashed.
        Complex, infinite, or NaN scalars will raise TypeError.

        Returns:
            int: Hash value based on the scalar's normalized value and unit

        Raises:
            TypeError: If scalar is complex, infinite, or NaN
        """
        if self._c_scalar == NULL:
            return hash(0)

        if self.is_complex:
            raise TypeError("Complex scalars are not hashable")

        if self.is_infinite:
            raise TypeError("Infinite scalars are not hashable")

        value = self.value
        if isinstance(value, float) and (value != value):  # Check for NaN
            raise TypeError("NaN scalars are not hashable")

        # Convert to coherent SI units for consistent hashing
        try:
            coherent = self.to_coherent_si()
            # Hash based on coherent SI value and unit string
            unit_str = str(coherent.unit)
            return hash((coherent.value, unit_str))
        except:
            # Fallback to current value and unit
            unit_str = str(self.unit)
            return hash((value, unit_str))

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
        return f"Scalar('{str(self)}')"
