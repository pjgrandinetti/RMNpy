# cython: language_level=3
"""
RMNpy SIUnit Cython declarations for cross-module imports.
"""

from rmnpy._c_api.octypes cimport OCArrayRef
from rmnpy._c_api.sitypes cimport SIUnitRef


cdef class Unit:
    cdef SIUnitRef _c_unit

    @staticmethod
    cdef Unit _from_ref(SIUnitRef unit_ref)

    # Unit analysis methods
    cdef list _array_ref_to_unit_list(self, OCArrayRef array_ref)

    @staticmethod
    cdef list _array_ref_to_unit_list_static(OCArrayRef array_ref)
