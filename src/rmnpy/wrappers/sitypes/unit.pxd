# cython: language_level=3
"""
RMNpy SIUnit Cython declarations for cross-module imports.
"""

from rmnpy._c_api.octypes cimport OCArrayRef
from rmnpy._c_api.sitypes cimport SIUnitRef
from rmnpy.wrappers.base_wrapper cimport SITypesWrapper


cdef class Unit(SITypesWrapper):
    pass
