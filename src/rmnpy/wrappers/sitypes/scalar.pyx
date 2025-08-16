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

from rmnpy.helpers.octypes import ocstring_create_from_pystring, ocstring_to_pystring
from rmnpy.wrappers.sitypes.unit import Unit

from libc.stdint cimport uint8_t, uint64_t, uintptr_t

import cmath


# Helper function for converting various input types to SIScalarRef
cdef SIScalarRef convert_to_siscalar_ref(value) except NULL:
    """
    Convert various input types to SIScalarRef.

    Accepts:
    - Scalar objects: Returns their C reference (borrowed, caller should copy if needed)
    - str: Creates Scalar from string expression
    - numeric types (int, float, complex): Creates dimensionless Scalar

    Returns:
        SIScalarRef: C reference to scalar (caller owns reference and must release)

    Raises:
        TypeError: If input type is not supported
        RMNError: If scalar creation fails
    """
    cdef Scalar temp_scalar

    if isinstance(value, Scalar):
        # Return copy of the C reference so caller owns it
        return SIScalarCreateCopy((<Scalar>value)._c_ref)
    elif isinstance(value, str):
        # Create Scalar from string, then return copy of its reference
        temp_scalar = Scalar(value)
        return SIScalarCreateCopy(temp_scalar._c_ref)
    elif isinstance(value, (int, float, complex)):
        # Create dimensionless Scalar from numeric value, then return copy
        temp_scalar = Scalar(value)
        return SIScalarCreateCopy(temp_scalar._c_ref)
    else:
        raise TypeError(f"Cannot convert {type(value)} to Scalar. Expected Scalar, str, or numeric type.")


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
        self._c_ref = NULL

    def __dealloc__(self):
        if self._c_ref != NULL:
            OCRelease(<OCTypeRef>self._c_ref)

    @staticmethod
    cdef Scalar _from_c_ref(SIScalarRef scalar_ref):
        """Create Scalar wrapper from C reference (internal use).

        Creates a copy of the scalar reference, so caller retains ownership
        of their original reference and can safely release it.
        """
        cdef Scalar result = Scalar.__new__(Scalar)
        cdef SIScalarRef copied_ref = SIScalarCreateCopy(scalar_ref)
        if copied_ref == NULL:
            raise RMNError("Failed to create copy of SIScalar")
        result._c_ref = copied_ref
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
        if self._c_ref != NULL:
            return  # Already initialized by _from_c_ref

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
        cdef OCStringRef expr_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(expression)
        cdef OCStringRef error_ocstr = NULL
        cdef SIScalarRef base_scalar
        cdef SIScalarRef result

        try:
            base_scalar = SIScalarCreateFromExpression(expr_ocstr, &error_ocstr)

            if base_scalar == NULL:
                if error_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>error_ocstr)
                    raise RMNError(f"Failed to parse scalar expression '{expression}': {error_msg}")
                else:
                    raise RMNError(f"Failed to parse scalar expression '{expression}'")

            # If value is 1.0, use base scalar directly
            if value == 1.0:
                self._c_ref = base_scalar
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

                self._c_ref = result

        finally:
            OCRelease(<OCTypeRef>expr_ocstr)
            if error_ocstr != NULL:
                OCRelease(<OCTypeRef>error_ocstr)

    # Properties
    @property
    def value(self):
        """Get the numeric value in the current unit (not coherent SI units)."""
        # Get the value directly from the C function
        # SIScalarDoubleValue returns the value in the current unit
        # (unlike SIScalarDoubleValueInCoherentUnit which always gives the SI base unit value)

        # Check if the scalar contains a complex number using C function
        if SIScalarIsComplex(self._c_ref):
            return SIScalarDoubleComplexValue(self._c_ref)
        else:
            # Use the appropriate C function that returns the value in the current unit
            return SIScalarDoubleValue(self._c_ref)

    @property
    def unit(self):
        """Get the unit of the scalar."""
        cdef SIUnitRef c_unit = SIQuantityGetUnit(<SIQuantityRef>self._c_ref)
        if c_unit == NULL:
            return None

        return Unit._from_c_ref(c_unit)

    @property
    def dimensionality(self):
        """Get the dimensionality of the scalar."""
        cdef SIDimensionalityRef c_dim = SIQuantityGetUnitDimensionality(<SIQuantityRef>self._c_ref)
        if c_dim == NULL:
            return None

        return Dimensionality._from_c_ref(c_dim)

    @property
    def is_real(self):
        """Check if the scalar is a real number."""
        return SIScalarIsReal(self._c_ref)

    @property
    def is_complex(self):
        """Check if the scalar has a non-zero imaginary component."""
        return SIScalarIsComplex(self._c_ref)

    @property
    def is_imaginary(self):
        """Check if the scalar is purely imaginary."""
        return SIScalarIsImaginary(self._c_ref)

    @property
    def is_zero(self):
        """Check if the scalar value is exactly zero."""
        return SIScalarIsZero(self._c_ref)

    @property
    def is_infinite(self):
        """Check if the scalar value is infinite."""
        return SIScalarIsInfinite(self._c_ref)

    @property
    def magnitude(self):
        """Get the magnitude (absolute value) of the scalar as a Scalar with same unit."""
        cdef SIScalarRef result = SIScalarCreateByTakingComplexPart(self._c_ref, kSIMagnitudePart)
        if result == NULL:
            raise RMNError("Failed to get magnitude")

        return Scalar._from_c_ref(result)

    @property
    def argument(self):
        """Get the argument (phase angle) of the scalar in radians as a dimensionless Scalar."""
        cdef SIScalarRef result = SIScalarCreateByTakingComplexPart(self._c_ref, kSIArgumentPart)
        if result == NULL:
            raise RMNError("Failed to get argument")

        return Scalar._from_c_ref(result)

    @property
    def phase(self):
        """Get the phase angle of the scalar in radians as a dimensionless Scalar (same as argument)."""
        return self.argument

    @property
    def real(self):
        """Get the real part of the scalar as a Scalar with same unit."""
        cdef SIScalarRef result = SIScalarCreateByTakingComplexPart(self._c_ref, kSIRealPart)
        if result == NULL:
            raise RMNError("Failed to get real part")

        return Scalar._from_c_ref(result)

    @property
    def imag(self):
        """Get the imaginary part of the scalar as a Scalar with same unit."""
        cdef SIScalarRef result = SIScalarCreateByTakingComplexPart(self._c_ref, kSIImaginaryPart)
        if result == NULL:
            raise RMNError("Failed to get imaginary part")

        return Scalar._from_c_ref(result)

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
        cdef OCStringRef error_ocstr = NULL
        cdef SIScalarRef result
        cdef bytes unit_bytes
        cdef OCStringRef unit_ocstr
        cdef Unit unit_obj

        if isinstance(new_unit, str):
            # Use string-based conversion that creates a new immutable scalar
            unit_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(new_unit)

            try:
                result = SIScalarCreateByConvertingToUnitWithString(self._c_ref, unit_ocstr, &error_ocstr)
            finally:
                OCRelease(<OCTypeRef>unit_ocstr)

        elif isinstance(new_unit, Unit):
            # Use Unit object directly with immutable conversion
            unit_obj = <Unit>new_unit
            result = SIScalarCreateByConvertingToUnit(self._c_ref, unit_obj._c_ref, &error_ocstr)
        else:
            raise TypeError("Unit must be a string or Unit object")

        try:
            if result == NULL:
                if error_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>error_ocstr)
                    raise ValueError(f"Unit conversion failed: {error_msg}")
                else:
                    raise ValueError("Unit conversion failed: incompatible dimensions")

            return Scalar._from_c_ref(result)
        finally:
            if error_ocstr != NULL:
                OCRelease(<OCTypeRef>error_ocstr)

    def to_coherent_si(self):
        """
        Convert to the coherent SI unit for this dimensionality.

        Returns:
            Scalar: New scalar in coherent SI units

        Examples:
            >>> force = Scalar(1000, "g*m/s^2")  # Non-coherent
            >>> force_si = force.to_coherent_si()  # 1.0 kg*m/s^2 (Newton)
        """
        cdef OCStringRef error_ocstr = NULL
        cdef SIScalarRef result = SIScalarCreateByConvertingToCoherentUnit(self._c_ref, &error_ocstr)

        try:
            if result == NULL:
                if error_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>error_ocstr)
                    raise RMNError(f"Coherent SI conversion failed: {error_msg}")
                else:
                    raise RMNError("Coherent SI conversion failed")

            return Scalar._from_c_ref(result)
        finally:
            if error_ocstr != NULL:
                OCRelease(<OCTypeRef>error_ocstr)

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
        cdef SIScalarRef result = SIScalarCreateByReducingUnit(self._c_ref)

        if result == NULL:
            raise RMNError("Scalar unit reduction failed")

        return Scalar._from_c_ref(result)

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
        cdef OCStringRef error_ocstr = NULL
        cdef SIScalarRef result = SIScalarCreateByTakingNthRoot(self._c_ref, c_root, &error_ocstr)

        try:
            if result == NULL:
                if error_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>error_ocstr)
                    raise RMNError(f"Root operation failed: {error_msg}")
                else:
                    raise RMNError("Root operation failed")

            return Scalar._from_c_ref(result)
        finally:
            if error_ocstr != NULL:
                OCRelease(<OCTypeRef>error_ocstr)

    # Python operator overloading
    def __add__(self, other):
        """Addition operator (+)."""
        if not isinstance(other, Scalar):
            # Convert Python number to dimensionless scalar
            if isinstance(other, (int, float, complex)):
                other = Scalar(other, "1")  # Create dimensionless scalar
            else:
                raise TypeError("Can only add with another Scalar or numeric value")

        cdef OCStringRef error_ocstr = NULL
        cdef SIScalarRef result = SIScalarCreateByAdding(self._c_ref, (<Scalar>other)._c_ref, &error_ocstr)

        if result == NULL:
            if error_ocstr != NULL:
                error_msg = ocstring_to_pystring(<uint64_t>error_ocstr)
                OCRelease(<OCTypeRef>error_ocstr)
                raise RMNError(f"Addition failed: {error_msg}")
            else:
                raise RMNError("Addition failed - likely dimensional mismatch")

        return Scalar._from_c_ref(result)

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

        cdef OCStringRef error_ocstr = NULL
        cdef SIScalarRef result = SIScalarCreateBySubtracting(self._c_ref, (<Scalar>other)._c_ref, &error_ocstr)

        try:
            if result == NULL:
                if error_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>error_ocstr)
                    raise RMNError(f"Subtraction failed: {error_msg}")
                else:
                    raise RMNError("Subtraction failed - likely dimensional mismatch")

            return Scalar._from_c_ref(result)
        finally:
            if error_ocstr != NULL:
                OCRelease(<OCTypeRef>error_ocstr)

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
        cdef OCStringRef error_ocstr

        if isinstance(other, Scalar):
            # Multiply by another scalar
            error_ocstr = NULL
            result = SIScalarCreateByMultiplying(self._c_ref, (<Scalar>other)._c_ref, &error_ocstr)

            try:
                if result == NULL:
                    if error_ocstr != NULL:
                        error_msg = ocstring_to_pystring(<uint64_t>error_ocstr)
                        raise RMNError(f"Multiplication failed: {error_msg}")
                    else:
                        raise RMNError("Multiplication failed")

                return Scalar._from_c_ref(result)
            finally:
                if error_ocstr != NULL:
                    OCRelease(<OCTypeRef>error_ocstr)
        elif isinstance(other, (int, float)):
            # Multiply by dimensionless real constant
            result = SIScalarCreateByMultiplyingByDimensionlessRealConstant(
                self._c_ref, float(other))
            if result == NULL:
                raise RMNError("Failed to multiply by dimensionless constant")
            return Scalar._from_c_ref(result)
        elif isinstance(other, complex):
            # Multiply by dimensionless complex constant
            result = SIScalarCreateByMultiplyingByDimensionlessComplexConstant(
                self._c_ref, other)
            if result == NULL:
                raise RMNError("Failed to multiply by dimensionless complex constant")
            return Scalar._from_c_ref(result)
        else:
            # Try to handle other numeric types (Decimal, Fraction)
            try:
                # Convert to float and multiply
                float_value = float(other)
                result = SIScalarCreateByMultiplyingByDimensionlessRealConstant(
                    self._c_ref, float_value)
                if result == NULL:
                    raise RMNError("Failed to multiply by dimensionless constant")
                return Scalar._from_c_ref(result)
            except (TypeError, ValueError):
                return NotImplemented

    def __rmul__(self, other):
        """Reverse multiplication operator (*)."""
        # Multiplication is commutative for dimensionless constants
        return self.__mul__(other)

    def __truediv__(self, other):
        """Division operator (/)."""
        cdef SIScalarRef result
        cdef OCStringRef error_ocstr

        if isinstance(other, Scalar):
            # Divide by another scalar
            error_ocstr = NULL
            result = SIScalarCreateByDividing(self._c_ref, (<Scalar>other)._c_ref, &error_ocstr)

            try:
                if result == NULL:
                    if error_ocstr != NULL:
                        error_msg = ocstring_to_pystring(<uint64_t>error_ocstr)
                        raise RMNError(f"Division failed: {error_msg}")
                    else:
                        raise RMNError("Division failed")

                return Scalar._from_c_ref(result)
            finally:
                if error_ocstr != NULL:
                    OCRelease(<OCTypeRef>error_ocstr)
        elif isinstance(other, (int, float)):
            # Divide by dimensionless real constant (multiply by 1/constant)
            if other == 0:
                raise ZeroDivisionError("Cannot divide by zero")
            result = SIScalarCreateByMultiplyingByDimensionlessRealConstant(
                self._c_ref, 1.0 / float(other))
            if result == NULL:
                raise RMNError("Failed to divide by dimensionless constant")
            return Scalar._from_c_ref(result)
        elif isinstance(other, complex):
            # Divide by dimensionless complex constant (multiply by 1/constant)
            if other == 0:
                raise ZeroDivisionError("Cannot divide by zero")
            result = SIScalarCreateByMultiplyingByDimensionlessComplexConstant(
                self._c_ref, 1.0 / other)
            if result == NULL:
                raise RMNError("Failed to divide by dimensionless complex constant")
            return Scalar._from_c_ref(result)
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
        cdef OCStringRef error_ocstr = NULL
        cdef SIScalarRef result

        # Check if exponent is an integer or can be treated as one
        if isinstance(exponent, int) or (isinstance(exponent, float) and exponent.is_integer()):
            # Use integer power function
            power = int(exponent)
            result = SIScalarCreateByRaisingToPower(self._c_ref, power, &error_ocstr)

            try:
                if result == NULL:
                    if error_ocstr != NULL:
                        error_msg = ocstring_to_pystring(<uint64_t>error_ocstr)
                        raise RMNError(f"Power operation failed: {error_msg}")
                    else:
                        raise RMNError("Power operation failed")

                return Scalar._from_c_ref(result)
            finally:
                if error_ocstr != NULL:
                    OCRelease(<OCTypeRef>error_ocstr)

        # Check if it's a simple fractional power (1/n)
        elif isinstance(exponent, float):
            # Check if this is 1/n where n is a positive integer
            if exponent > 0 and (1.0 / exponent).is_integer():
                root_value = int(1.0 / exponent)
                if root_value > 0 and root_value <= 255:  # uint8_t range
                    root = <uint8_t>root_value
                    result = SIScalarCreateByTakingNthRoot(self._c_ref, root, &error_ocstr)

                    try:
                        if result == NULL:
                            if error_ocstr != NULL:
                                error_msg = ocstring_to_pystring(<uint64_t>error_ocstr)
                                raise RMNError(f"Nth root operation failed: {error_msg}")
                            else:
                                raise RMNError("Nth root operation failed")

                        return Scalar._from_c_ref(result)
                    finally:
                        if error_ocstr != NULL:
                            OCRelease(<OCTypeRef>error_ocstr)

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
                result = SIScalarCompare(self._c_ref, (<Scalar>other)._c_ref)

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
                result = SIScalarCompare(self._c_ref, other_scalar._c_ref)

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
            result = SIScalarCompare(self._c_ref, (<Scalar>other)._c_ref)

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
            result = SIScalarCompare(self._c_ref, (<Scalar>other)._c_ref)
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
            result = SIScalarCompare(self._c_ref, (<Scalar>other)._c_ref)
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
            result = SIScalarCompare(self._c_ref, (<Scalar>other)._c_ref)
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
            result = SIScalarCompare(self._c_ref, (<Scalar>other)._c_ref)
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
            unit_ocstr = str(coherent.unit)
            return hash((coherent.value, unit_ocstr))
        except:
            # Fallback to current value and unit
            unit_ocstr = str(self.unit)
            return hash((value, unit_ocstr))

    # String representation
    def __str__(self):
        """Return a string representation of the scalar with value and unit."""
        cdef OCStringRef str_ref = SIScalarCreateStringValue(self._c_ref)
        if str_ref == NULL:
            return f"Scalar({self.value})"

        try:
            return ocstring_to_pystring(<uint64_t>str_ref)
        finally:
            OCRelease(<OCTypeRef>str_ref)

    def __repr__(self):
        """Return a detailed string representation."""
        return f"Scalar('{str(self)}')"


# ====================================================================================
# SIScalar Helper Functions
# ====================================================================================

def siscalar_create_from_py_number(py_number, str unit_ocstring="1"):
    """
    Convert a Python number to an SIScalarRef.

    Args:
        py_number: Python number (int, float, complex)
        unit_ocstring (str): Unit string expression (default: "1" for dimensionless)

    Returns:
        uint64_t: SIScalarRef as integer pointer (needs to be released)

    Raises:
        RuntimeError: If scalar creation fails
        TypeError: If number type is unsupported
    """
    cdef OCStringRef unit_oc_string = NULL
    cdef OCStringRef error_ocstr = NULL
    cdef SIScalarRef si_scalar = NULL
    cdef double complex c_complex

    try:
        # Create unit string
        unit_oc_string = <OCStringRef><uint64_t>ocstring_create_from_pystring(unit_ocstring)
        if unit_oc_string == NULL:
            raise RuntimeError(f"Failed to create unit string: {unit_ocstring}")

        # Create scalar based on number type
        if isinstance(py_number, bool):
            # Handle bool as int (bool is subclass of int in Python)
            si_scalar = SIScalarCreateWithDouble(<double>(1 if py_number else 0), <SIUnitRef>unit_oc_string)
        elif isinstance(py_number, int):
            si_scalar = SIScalarCreateWithDouble(<double>py_number, <SIUnitRef>unit_oc_string)
        elif isinstance(py_number, float):
            si_scalar = SIScalarCreateWithDouble(<double>py_number, <SIUnitRef>unit_oc_string)
        elif isinstance(py_number, complex):
            # Create complex scalar
            c_complex = <double complex>py_number
            si_scalar = SIScalarCreateWithDoubleComplex(c_complex, <SIUnitRef>unit_oc_string)
        else:
            raise TypeError(f"Unsupported number type for SIScalar: {type(py_number)}")

        if si_scalar == NULL:
            raise RuntimeError(f"Failed to create SIScalar from: {py_number}")

        return <uint64_t>si_scalar

    except Exception:
        # Clean up on error
        if si_scalar != NULL:
            OCRelease(<const void*>si_scalar)
        raise
    finally:
        # Always clean up the unit string
        if unit_oc_string != NULL:
            OCRelease(<const void*>unit_oc_string)

def siscalar_create_from_pyscalar(object py_scalar):
    """
    Convert a Python Scalar object to an SIScalarRef.

    This function is designed to work with Scalar objects from the RMNpy.wrappers.scalar module.
    It uses the bypass approach to avoid cross-module Cython issues.

    Args:
        py_scalar: Python Scalar object

    Returns:
        uint64_t: SIScalarRef as integer pointer (needs to be released)

    Raises:
        RuntimeError: If scalar conversion fails
        TypeError: If input is not a Scalar object
    """
    # Check if it has the expected Scalar attributes
    if not hasattr(py_scalar, 'value') or not hasattr(py_scalar, 'unit'):
        raise TypeError(f"Expected Scalar object with 'value' and 'unit' attributes, got {type(py_scalar)}")

    try:
        # Extract value and unit from the Scalar object
        py_value = py_scalar.value
        py_unit = py_scalar.unit

        # Convert unit to string representation
        if hasattr(py_unit, '__str__'):
            unit_ocstr = str(py_unit)
        else:
            unit_ocstr = "1"  # fallback to dimensionless

        # Use the number-to-scalar conversion
        return siscalar_create_from_py_number(py_value, unit_ocstr)

    except Exception as e:
        raise RuntimeError(f"Failed to convert Scalar to SIScalar: {e}")

def siscalar_create_from_pynumber_expression(py_number, str expression="1"):
    """
    Convert a Python number to an SIScalarRef using expression parsing.

    This is the preferred method as it uses SIScalarCreateFromExpression which
    bypasses the need for SIUnit objects and handles complex unit expressions.

    Args:
        py_number: Python number (int, float, complex)
        expression (str): Complete scalar expression (default: "1" for dimensionless)

    Returns:
        uint64_t: SIScalarRef as integer pointer (needs to be released)

    Raises:
        RuntimeError: If scalar creation fails
    """
    cdef OCStringRef expr_string = NULL
    cdef OCStringRef error_ocstr = NULL
    cdef SIScalarRef si_scalar = NULL

    try:
        # Create the full expression string combining value and unit
        if isinstance(py_number, complex):
            # Handle complex numbers with special formatting for SITypes parser
            real_part = py_number.real
            imag_part = py_number.imag
            if imag_part >= 0:
                # Use proper complex syntax for SITypes: (real + imag * i)
                full_expr = f"({real_part} + {imag_part} * i) * {expression}"
            else:
                # Negative imaginary part
                full_expr = f"({real_part} - {abs(imag_part)} * i) * {expression}"
        else:
            # Simple number
            full_expr = f"{py_number} * {expression}"

        # Create expression string
        expr_string = <OCStringRef><uint64_t>ocstring_create_from_pystring(full_expr)
        if expr_string == NULL:
            raise RuntimeError(f"Failed to create expression string: {full_expr}")

        # Parse the expression to create scalar
        si_scalar = SIScalarCreateFromExpression(expr_string, &error_ocstr)

        if si_scalar == NULL:
            error_msg = "Unknown error"
            if error_ocstr != NULL:
                error_c_str = OCStringGetCString(error_ocstr)
                if error_c_str != NULL:
                    error_msg = error_c_str.decode('utf-8')
                OCRelease(<const void*>error_ocstr)
            raise RuntimeError(f"Failed to create SIScalar from expression '{full_expr}': {error_msg}")

        return <uint64_t>si_scalar

    except Exception:
        # Clean up on error
        if si_scalar != NULL:
            OCRelease(<const void*>si_scalar)
        raise
    finally:
        # Always clean up the expression string
        if expr_string != NULL:
            OCRelease(<const void*>expr_string)

def siscalar_to_pynumber(uint64_t si_scalar_ptr):
    """
    Convert an SIScalarRef to a Python number.

    Args:
        si_scalar_ptr (uint64_t): Pointer to SIScalarRef

    Returns:
        int/float/complex: Python number (loses unit information)

    Raises:
        ValueError: If the SIScalarRef is NULL
        RuntimeError: If value extraction fails
    """
    cdef SIScalarRef si_scalar = <SIScalarRef>si_scalar_ptr
    cdef double complex complex_val
    cdef double double_val

    if si_scalar == NULL:
        raise ValueError("SIScalarRef is NULL")

    try:
        # Check if it's complex
        if SIScalarIsComplex(si_scalar):
            complex_val = SIScalarDoubleComplexValue(si_scalar)
            return complex(complex_val.real, complex_val.imag)
        elif SIScalarIsReal(si_scalar):
            double_val = SIScalarDoubleValue(si_scalar)
            # Return as int if it's a whole number, otherwise float
            if double_val == int(double_val):
                return int(double_val)
            else:
                return float(double_val)
        else:
            # Fallback to double value
            double_val = SIScalarDoubleValue(si_scalar)
            return float(double_val)

    except Exception as e:
        raise RuntimeError(f"Failed to extract value from SIScalar: {e}")


def siscalar_to_scalar(uint64_t si_scalar_ptr):
    """
    Convert an SIScalarRef to a Python numeric value.

    For coordinate arrays, we want numeric values that work with numpy,
    not full Scalar objects. This avoids circular import issues and
    provides the expected numeric behavior.

    Args:
        si_scalar_ptr (uint64_t): Pointer to SIScalarRef

    Returns:
        float/int: Python numeric value (loses unit information)

    Raises:
        ValueError: If the SIScalarRef is NULL
        RuntimeError: If value extraction fails
    """
    cdef SIScalarRef si_scalar = <SIScalarRef>si_scalar_ptr

    if si_scalar == NULL:
        raise ValueError("SIScalarRef is NULL")

    # Return numeric value directly - this is what coordinate arrays need
    return siscalar_to_pynumber(si_scalar_ptr)
