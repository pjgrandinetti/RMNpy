# cython: language_level=3
"""
RMNpy Dimension Cython declarations for cross-module imports.

This .pxd file allows other Cython modules to cimport and use
the dimension classes from dimension.pyx.
"""

from rmnpy._c_api.rmnlib cimport DimensionRef
from rmnpy.wrappers.base_wrapper cimport RMNLibWrapper


cdef class BaseDimension(RMNLibWrapper):
    """Cython interface for BaseDimension wrapper."""
    pass


cdef class LabeledDimension(BaseDimension):
    """Cython interface for LabeledDimension wrapper."""
    pass


cdef class SIDimension(BaseDimension):
    """Cython interface for SIDimension wrapper."""
    pass


cdef class LinearDimension(SIDimension):
    """Cython interface for LinearDimension wrapper."""
    pass


cdef class MonotonicDimension(SIDimension):
    """Cython interface for MonotonicDimension wrapper."""
    pass
