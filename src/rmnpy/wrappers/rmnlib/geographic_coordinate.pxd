# cython: language_level=3
"""
RMNpy GeographicCoordinate Cython declarations for cross-module imports.

This .pxd file allows other Cython modules to cimport and use
the GeographicCoordinate class from geographic_coordinate.pyx.
"""

from rmnpy._c_api.rmnlib cimport GeographicCoordinateRef


cdef class GeographicCoordinate:
    """Cython interface for GeographicCoordinate wrapper."""
    cdef GeographicCoordinateRef _c_ref

    @staticmethod
    cdef GeographicCoordinate _from_c_ref(GeographicCoordinateRef geo_ref)
