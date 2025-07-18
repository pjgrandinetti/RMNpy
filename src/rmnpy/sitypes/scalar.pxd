# Cython declarations for SIScalar wrapper

from ..core cimport SIScalarRef, SIUnitRef, OCStringRef
from .unit cimport SIUnit

cdef class SIScalar:
    cdef SIScalarRef _ref
    cdef bint _owns_ref
    
    @staticmethod
    cdef SIScalar _from_ref(SIScalarRef ref, bint owns_ref=*)
    
    cdef SIScalarRef _get_c_ref(self)
    
    @staticmethod
    cdef SIScalarRef _create_with_value_and_unit(double value, object unit_str) except NULL
    
    @staticmethod
    cdef SIScalarRef _create_with_value_and_siunit(double value, SIUnit unit_obj) except NULL

# Helper functions for other modules to use
cdef SIScalarRef _get_scalar_ref(object scalar_obj)
