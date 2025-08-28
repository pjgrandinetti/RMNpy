# cython: language_level=3
"""
RMNpy GeographicCoordinate Cython declarations for cross-module imports.

This .pxd file allows other Cython modules to cimport and use
the GeographicCoordinate class from geographic_coordinate.pyx.
"""

from rmnpy._c_api.rmnlib cimport GeographicCoordinateRef
from rmnpy.wrappers.base_wrapper cimport RMNLibWrapper


cdef class GeographicCoordinate(RMNLibWrapper):
    """Cython interface for GeographicCoordinate wrapper."""
    # _c_ref is inherited from BaseWrapper
