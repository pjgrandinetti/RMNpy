# cython: language_level=3
"""
RMNpy SIUnit Cython declarations for cross-module imports.
"""

from rmnpy._c_api.octypes cimport OCArrayRef
from rmnpy._c_api.sitypes cimport SIUnitRef
from rmnpy.wrappers.base_wrapper cimport SITypesWrapper


# Helper function for converting various input types to SIUnitRef
cdef SIUnitRef siunit_from_pytype(value) except NULL


cdef class Unit(SITypesWrapper):

    @staticmethod
    cdef Unit _from_c_ref(object cls, void* c_ref)
