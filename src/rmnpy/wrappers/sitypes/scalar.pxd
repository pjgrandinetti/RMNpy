# cython: language_level=3
"""
RMNpy SIScalar Cython declarations for cross-module imports.

This .pxd file allows other Cython modules to cimport and use
the Scalar class from scalar.pyx.
"""

from rmnpy._c_api.sitypes cimport SIScalarRef
from rmnpy.wrappers.base_wrapper cimport SITypesWrapper


cdef class Scalar(SITypesWrapper):
    """Cython interface for SIScalar wrapper."""
    # No _from_c_ref needed - use BaseWrapper._from_c_ref directly!
    pass

# Helper function for converting various input types to SIScalarRef
cdef SIScalarRef create_siscalar_from_pytype(value) except NULL
