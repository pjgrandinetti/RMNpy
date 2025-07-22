# cython: language_level=3
"""
RMNpy SIScalar Wrapper - Phase 2C Implementation

Complete wrapper for SIScalar providing comprehensive scalar physical quantity capabilities.
This implementation builds on the SIDimensionality and SIUnit foundations from Phases 2A and 2B.

SIScalar represents a physical quantity with a numerical value, unit, and associated dimensionality.
It supports comprehensive arithmetic operations with automatic unit handling and dimensional validation.
"""

from rmnpy._c_api.octypes cimport (OCStringRef, OCRelease, OCStringCreateWithCString, 
                                   OCStringGetCString, OCTypeRef, OCComparisonResult)
from rmnpy._c_api.sitypes cimport *
from rmnpy.exceptions import RMNError
from rmnpy.wrappers.sitypes.dimensionality cimport Dimensionality
from rmnpy.wrappers.sitypes.dimensionality import Dimensionality
from rmnpy.wrappers.sitypes.unit cimport Unit  
from rmnpy.wrappers.sitypes.unit import Unit
from rmnpy.helpers.octypes import parse_c_string

from libc.stdint cimport uint64_t, uintptr_t, uint8_t
import cmath


cdef class Scalar:
    """
    Python wrapper for SIScalar - represents a scalar physical quantity.
    
    A scalar combines a numerical value with a unit, enabling type-safe scientific computing
    with automatic dimensional analysis and unit conversion capabilities.
    
    Examples:
        >>> # Create from value and unit
        >>> distance = Scalar(5.0, "m")  # 5 meters
        >>> time = Scalar(2.0, "s")      # 2 seconds
        >>> velocity = distance / time    # 2.5 m/s
        >>> 
        >>> # Automatic unit handling
        >>> velocity.value    # 2.5
        >>> velocity.unit     # Unit('m/s')
        >>> str(velocity)     # "2.5 m/s"
        >>> 
        >>> # Unit conversion
        >>> velocity_kmh = velocity.convert_to("km/h")  # Convert to km/h
        >>> velocity_kmh.value  # 9.0
        >>> 
        >>> # Arithmetic with automatic dimensional validation
        >>> area = distance * distance  # 25 m^2
        >>> volume = area * distance     # 125 m^3
        >>> 
        >>> # Error on dimensionally incompatible operations
        >>> try:
        ...     invalid = distance + time  # Error: can't add length + time
        ... except RMNError:
        ...     print("Dimensional mismatch caught!")
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
    
    def __init__(self, value=None, unit=None):
        """
        Create a scalar with a numerical value and unit.
        
        Args:
            value (int, float, complex): Numerical value
            unit (str or Unit): Unit specification
            
        Examples:
            >>> s1 = Scalar(5.0, "m")     # 5 meters
            >>> s2 = Scalar(3+4j, "A")    # Complex current
            >>> s3 = Scalar(42, Unit.parse("kg")[0])  # Using Unit object
        """
        if self._c_scalar != NULL:
            return  # Already initialized by _from_ref
        
        if value is None or unit is None:
            raise TypeError("Both value and unit are required")
        
        # Handle unit parameter
        cdef Unit unit_obj
        if isinstance(unit, str):
            unit_obj, _ = Unit.parse(unit)
        elif isinstance(unit, Unit):
            unit_obj = <Unit>unit
        else:
            raise TypeError("Unit must be a string or Unit object")
        
        # Create scalar based on value type (using double precision)
        if isinstance(value, str):
            # Convert string to float
            try:
                value = float(value)
            except (ValueError, TypeError):
                raise ValueError(f"Cannot convert string '{value}' to a number")
        
        # Handle Decimal and Fraction types
        try:
            from decimal import Decimal
            from fractions import Fraction
            if isinstance(value, (Decimal, Fraction)):
                value = float(value)
        except ImportError:
            pass  # Decimal/Fraction not available
        
        if isinstance(value, complex):
            # Always treat complex as complex (don't convert to real)
            self._c_scalar = SIScalarCreateWithDoubleComplex(value, unit_obj._c_unit)
        elif isinstance(value, float):
            self._c_scalar = SIScalarCreateWithDouble(value, unit_obj._c_unit)
        elif isinstance(value, int):
            self._c_scalar = SIScalarCreateWithDouble(float(value), unit_obj._c_unit)
        else:
            raise TypeError(f"Value must be int, float, complex, string, Decimal, or Fraction, got {type(value)}")
        
        if self._c_scalar == NULL:
            raise RMNError("Failed to create scalar")
    
    @classmethod
    def from_string(cls, expression):
        """
        Create a scalar from a string expression containing value and unit.
        
        Args:
            expression (str): String like "5.0 m/s", "3.14 kg*m/s^2"
            
        Returns:
            Scalar: Parsed scalar object
            
        Examples:
            >>> velocity = Scalar.from_string("25 m/s")
            >>> force = Scalar.from_string("9.8 kg*m/s^2") 
        """
        if not isinstance(expression, str):
            raise TypeError("Expression must be a string")
        
        cdef bytes expr_bytes = expression.encode('utf-8')
        cdef OCStringRef expr_ref = OCStringCreateWithCString(expr_bytes)
        cdef OCStringRef error_string = NULL
        cdef SIScalarRef result
        
        try:
            result = SIScalarCreateFromExpression(expr_ref, &error_string)
            
            if result == NULL:
                if error_string != NULL:
                    error_msg = parse_c_string(<uint64_t>error_string)
                    OCRelease(<OCTypeRef>error_string)
                    raise ValueError(f"Invalid scalar expression: {error_msg}")
                else:
                    raise ValueError(f"Invalid scalar expression: '{expression}'")
            
            return Scalar._from_ref(result)
            
        finally:
            OCRelease(<OCTypeRef>expr_ref)
    
    @classmethod
    def from_value_and_unit(cls, value, unit):
        """
        Create a scalar from separate value and unit.
        
        Args:
            value (int, float, complex): Numerical value
            unit (str or Unit): Unit specification
            
        Returns:
            Scalar: New scalar object
            
        Examples:
            >>> s1 = Scalar.from_value_and_unit(5.0, "m")
            >>> s2 = Scalar.from_value_and_unit(3+4j, "A")
        """
        return cls(value, unit)

    @classmethod
    def from_value_unit(cls, value, unit):
        """Alias for from_value_and_unit for backward compatibility."""
        return cls.from_value_and_unit(value, unit)
    
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
            other (Scalar): Scalar to add
            
        Returns:
            Scalar: Sum of the scalars
            
        Note:
            Both scalars must have compatible (same) dimensionality
        """
        if not isinstance(other, Scalar):
            raise TypeError("Can only add with another Scalar")
        
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
            other (Scalar): Scalar to subtract
            
        Returns:
            Scalar: Difference of the scalars
        """
        if not isinstance(other, Scalar):
            raise TypeError("Can only subtract another Scalar")
        
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
            other (Scalar): Scalar to multiply by
            
        Returns:
            Scalar: Product of the scalars
        """
        if not isinstance(other, Scalar):
            raise TypeError("Can only multiply with another Scalar")
        
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
            other (Scalar): Scalar to divide by
            
        Returns:
            Scalar: Quotient of the scalars
        """
        if not isinstance(other, Scalar):
            raise TypeError("Can only divide by another Scalar")
        
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
        
        cdef double power = float(exponent)
        cdef OCStringRef error_string = NULL
        cdef SIScalarRef result = SIScalarCreateByRaisingToPower(self._c_scalar, power, &error_string)
        
        if result == NULL:
            if error_string != NULL:
                error_msg = parse_c_string(<uint64_t>error_string)
                OCRelease(<OCTypeRef>error_string)
                raise RMNError(f"Power operation failed: {error_msg}")
            else:
                raise RMNError("Power operation failed")
        
        return Scalar._from_ref(result)
    
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
    
    def __sub__(self, other):
        """Subtraction operator (-)."""
        return self.subtract(other)
    
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
