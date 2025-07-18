# Cython declarations for SIDimensionality wrapper

from ..core cimport SIDimensionalityRef, SIBaseDimensionIndex

cdef class SIDimensionality:
    cdef SIDimensionalityRef _ref
    cdef bint _owns_ref
    
    @staticmethod
    cdef SIDimensionality _from_ref(SIDimensionalityRef ref, bint owns_ref=*)
    
    # Static factory methods
    @staticmethod
    cdef SIDimensionalityRef _parse_expression(object expression) except NULL

# Helper functions for other modules
cdef SIDimensionalityRef py_to_sidimensionality_ref(object value_or_expression) except NULL
cdef object sidimensionality_ref_to_py(SIDimensionalityRef dim_ref)
