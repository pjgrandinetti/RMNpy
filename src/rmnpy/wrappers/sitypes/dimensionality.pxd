# cython: language_level=3
"""
Cython interface declarations for Dimensionality class.

This .pxd file allows other Cython modules to cimport and use
the Dimensionality class from dimensionality.pyx.
"""

from rmnpy._c_api.octypes cimport OCTypeRef
from rmnpy._c_api.sitypes cimport SIDimensionalityRef
from rmnpy.wrappers.base_wrapper cimport SITypesWrapper


cdef class Dimensionality(SITypesWrapper):
    """Cython interface for SIDimensionality wrapper."""

    @staticmethod
    cdef Dimensionality _from_c_ref(object cls, void* c_ref)
