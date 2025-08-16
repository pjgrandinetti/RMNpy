# cython: language_level=3
"""
RMNpy SIUnit Cython declarations for cross-module imports.
"""

from rmnpy._c_api.octypes cimport OCArrayRef
from rmnpy._c_api.sitypes cimport SIUnitRef


# Helper function for converting various input types to SIUnitRef
cdef SIUnitRef convert_to_siunit_ref(value) except NULL


cdef class Unit:
    cdef SIUnitRef _c_ref

    @staticmethod
    cdef Unit _from_c_ref(SIUnitRef unit_ref)
