# cython: language_level=3
"""
RMNpy SparseSampling Cython declarations for cross-module imports.

This .pxd file allows other Cython modules to cimport and use
the SparseSampling class from sparse_sampling.pyx.
"""

from rmnpy._c_api.rmnlib cimport SparseSamplingRef
from rmnpy.wrappers.base_wrapper cimport RMNLibWrapper


cdef class SparseSampling(RMNLibWrapper):
    """Cython interface for SparseSampling wrapper."""
    pass
