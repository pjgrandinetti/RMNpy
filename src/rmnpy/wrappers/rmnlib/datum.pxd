# cython: language_level=3
"""
RMNpy Datum Cython declarations for cross-module imports.

This .pxd file allows other Cython modules to cimport and use
the Datum class from datum.pyx.
"""

from rmnpy._c_api.rmnlib cimport DatumRef


cdef class Datum:
    """Cython interface for Datum wrapper."""
    cdef DatumRef _c_ref

    @staticmethod
    cdef Datum _from_c_ref(DatumRef datum_ref)
