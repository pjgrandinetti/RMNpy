# cython: language_level=3
"""
RMNpy SparseSampling Cython declarations for cross-module imports.

This .pxd file allows other Cython modules to cimport and use
the SparseSampling class from sparse_sampling.pyx.
"""

from rmnpy._c_api.rmnlib cimport SparseSamplingRef


cdef class SparseSampling:
    """Cython interface for SparseSampling wrapper."""
    cdef SparseSamplingRef _c_ref

    @staticmethod
    cdef SparseSampling _from_c_ref(SparseSamplingRef sparse_ref)
