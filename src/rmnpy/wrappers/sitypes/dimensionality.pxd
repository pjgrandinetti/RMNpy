# cython: language_level=3
"""
Cython interface declarations for Dimensionality class.

This .pxd file allows other Cython modules to cimport and use
the Dimensionality class from dimensionality.pyx.
"""

from rmnpy._c_api.sitypes cimport SIDimensionalityRef


cdef class Dimensionality:
    """Cython interface for SIDimensionality wrapper."""
    cdef SIDimensionalityRef _c_ref

    @staticmethod
    cdef Dimensionality _from_c_ref(SIDimensionalityRef dim_ref)
