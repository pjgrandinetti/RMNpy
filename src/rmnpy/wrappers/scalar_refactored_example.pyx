# cython: language_level=3
"""
Example refactored Scalar wrapper using the base wrapper classes.

This demonstrates how the new base class system dramatically simplifies
wrapper implementation while maintaining all functionality.
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

from libc.stdint cimport uint64_t

from rmnpy.wrappers.base_wrapper cimport (
    ArithmeticWrapper,
    ComparableWrapper,
    SerializableWrapper,
    SITypesWrapper,
    create_wrapper_from_c_ref,
)
from rmnpy.wrappers.sitypes.unit cimport Unit

import cmath


# Helper function remains the same
cdef SIScalarRef create_siscalar_from_pytype(value) except NULL:
    """Convert various input types to SIScalarRef."""
    cdef Scalar temp_scalar

    if isinstance(value, Scalar):
        return SIScalarCreateCopy((<Scalar>value)._c_ref)
    elif isinstance(value, str):
        temp_scalar = Scalar(value)
        return SIScalarCreateCopy(temp_scalar._c_ref)
    elif isinstance(value, (int, float, complex)):
        temp_scalar = Scalar(value)
        return SIScalarCreateCopy(temp_scalar._c_ref)
    else:
        raise TypeError(f"Cannot convert {type(value)} to Scalar. Expected Scalar, str, or numeric type.")


cdef class Scalar(SITypesWrapper, SerializableWrapper, ComparableWrapper, ArithmeticWrapper):
    """
    Python wrapper for SIScalar - REFACTORED VERSION.

    This version demonstrates how the base class system dramatically reduces
    boilerplate code while maintaining all functionality.

    Compare this to the original 1110-line implementation!
    """

    # The base class handles __cinit__ and __dealloc__

    def __init__(self, value=1.0, expression=None):
        """Create a scalar physical quantity with flexible argument patterns."""
        if self._c_ref != NULL:
            return  # Already initialized by _from_c_ref

        cdef SIScalarRef si_scalar = NULL
        cdef OCStringRef error_ocstr = NULL

        try:
            # Handle different argument patterns
            if expression is None:
                if isinstance(value, str):
                    # Full expression like "100 J"
                    si_scalar = self._create_from_expression(value)
                else:
                    # Numeric value (dimensionless)
                    si_scalar = self._create_from_numeric(value)
            else:
                # Value and unit expression
                si_scalar = self._create_from_value_and_unit(value, expression)

            if si_scalar == NULL:
                raise RMNError("Failed to create scalar")

            self._set_c_ref(<void*>si_scalar)

        except Exception:
            if si_scalar != NULL:
                OCRelease(<OCTypeRef>si_scalar)
            raise
        finally:
            if error_ocstr != NULL:
                OCRelease(<OCTypeRef>error_ocstr)

    # Implement required base class methods

    cdef void* copy_c_ref(self) except NULL:
        """Create a copy of the C reference."""
        self._validate_initialized()
        cdef SIScalarRef copied = SIScalarCreateCopy(<SIScalarRef>self._c_ref)
        if copied == NULL:
            raise RMNError("Failed to copy scalar reference")
        return <void*>copied

    @staticmethod
    cdef Scalar _from_c_ref(SIScalarRef scalar_ref):
        """Create Scalar wrapper from C reference (internal use)."""
        return <Scalar>create_wrapper_from_c_ref(
            <void*>scalar_ref,
            Scalar,
            <copy_func_ptr>SIScalarCreateCopy
        )

    @staticmethod
    def from_c_ref(uint64_t scalar_ref_ptr):
        """Create Scalar wrapper from C reference pointer (Python-accessible)."""
        return Scalar._from_c_ref(<SIScalarRef>scalar_ref_ptr)

    # Implement serialization methods (SerializableWrapper)

    def _to_dict_c_api(self):
        """Convert to dictionary using C API."""
        # Implementation would call SIScalarCopyAsDictionary
        # and convert to Python dict
        pass

    @classmethod
    def _from_dict_c_api(cls, data_dict):
        """Create from dictionary using C API."""
        # Implementation would convert dict to OCDictionary
        # and call SIScalarCreateFromDictionary
        pass

    # Implement comparison methods (ComparableWrapper)

    cdef int _compare_c_api(self, other) except? -999:
        """Compare with another scalar using C API."""
        cdef OCComparisonResult result = SIScalarCompare(
            <SIScalarRef>self._c_ref,
            <SIScalarRef>(<Scalar>other)._c_ref
        )
        if result == kOCCompareLessThan:
            return -1
        elif result == kOCCompareGreaterThan:
            return 1
        elif result == kOCCompareEqualTo:
            return 0
        else:
            raise RMNError("Cannot compare scalars with incompatible dimensions")

    # Implement arithmetic methods (ArithmeticWrapper)

    def _add_c_api(self, other):
        """Addition using C API."""
        if isinstance(other, Scalar):
            return self._scalar_add_scalar(other)
        else:
            return self._scalar_add_numeric(other)

    def _sub_c_api(self, other):
        """Subtraction using C API."""
        if isinstance(other, Scalar):
            return self._scalar_sub_scalar(other)
        else:
            return self._scalar_sub_numeric(other)

    def _mul_c_api(self, other):
        """Multiplication using C API."""
        if isinstance(other, Scalar):
            return self._scalar_mul_scalar(other)
        else:
            return self._scalar_mul_numeric(other)

    def _div_c_api(self, other):
        """Division using C API."""
        if isinstance(other, Scalar):
            return self._scalar_div_scalar(other)
        else:
            return self._scalar_div_numeric(other)

    def _pow_c_api(self, other):
        """Power using C API."""
        return self._scalar_pow_numeric(other)

    # Domain-specific properties and methods

    @property
    def value(self):
        """Get the numeric value."""
        self._validate_initialized()
        return SIScalarGetDoubleValue(<SIScalarRef>self._c_ref)

    @property
    def unit(self):
        """Get the unit."""
        self._validate_initialized()
        cdef SIUnitRef unit_ref = SIScalarGetUnit(<SIScalarRef>self._c_ref)
        return Unit._from_c_ref(unit_ref)

    # Helper methods for construction

    cdef SIScalarRef _create_from_expression(self, str expression):
        """Create scalar from string expression."""
        # Implementation details...
        pass

    cdef SIScalarRef _create_from_numeric(self, value):
        """Create dimensionless scalar from numeric value."""
        # Implementation details...
        pass

    cdef SIScalarRef _create_from_value_and_unit(self, value, str unit_expr):
        """Create scalar from value and unit expression."""
        # Implementation details...
        pass

    # Helper methods for arithmetic operations

    cdef Scalar _scalar_add_scalar(self, Scalar other):
        """Add two scalars."""
        # Implementation details...
        pass

    cdef Scalar _scalar_add_numeric(self, value):
        """Add scalar and numeric value."""
        # Implementation details...
        pass

    # ... similar methods for other operations

    def __repr__(self):
        """String representation."""
        try:
            return f"Scalar({self.value}, unit={self.unit})"
        except Exception:
            return f"Scalar(at {hex(id(self))})"
