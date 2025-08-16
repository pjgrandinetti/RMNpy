# cython: language_level=3
"""
RMNpy SIScalar Cython declarations for cross-module imports.

This .pxd file allows other Cython modules to cimport and use
the Scalar class from scalar.pyx.
"""

from rmnpy._c_api.sitypes cimport SIScalarRef


# Helper function declaration
cdef SIScalarRef convert_to_siscalar_ref(value) except NULL


cdef class Scalar:
    """Cython interface for SIScalar wrapper."""
    cdef SIScalarRef _c_ref

    @staticmethod
    cdef Scalar _from_c_ref(SIScalarRef scalar_ref)
