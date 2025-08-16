# cython: language_level=3
"""
RMNpy Dimension Cython declarations for cross-module imports.

This .pxd file allows other Cython modules to cimport and use
the dimension classes from dimension.pyx.
"""

from rmnpy._c_api.rmnlib cimport DimensionRef


cdef class BaseDimension:
    """Cython interface for BaseDimension wrapper."""
    cdef DimensionRef _c_ref

    @staticmethod
    cdef BaseDimension _from_c_ref(DimensionRef dim_ref)


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
