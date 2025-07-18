# cython: language_level=3

from ..core cimport *
from .dimensionality cimport SIDimensionality

cdef class SIUnit:
    cdef SIUnitRef _c_unit
    cdef bint _owns_ref
    
    @staticmethod
    cdef SIUnit _from_c_unit(SIUnitRef c_unit, bint owns_ref=*)
    
    cdef SIUnitRef _get_c_unit(self)
