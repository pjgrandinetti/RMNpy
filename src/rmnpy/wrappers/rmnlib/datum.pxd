# cython: language_level=3
"""
RMNpy Datum Cython declarations for cross-module imports.

This .pxd file allows other Cython modules to cimport and use
the Datum class from datum.pyx.
"""

from rmnpy._c_api.rmnlib cimport DatumRef
from rmnpy.wrappers.base_wrapper cimport RMNLibWrapper


cdef class Datum(RMNLibWrapper):
    """Cython interface for Datum wrapper."""
    # No _from_c_ref needed - use BaseWrapper._from_c_ref directly!
    pass
