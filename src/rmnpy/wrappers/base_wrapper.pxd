# cython: language_level=3
"""
Header file for base wrapper classes.
"""

from libc.stdint cimport uint64_t

from rmnpy._c_api.octypes cimport OCTypeRef


cdef class BaseWrapper:
    """Base class for all RMNpy C API wrappers."""
    cdef OCTypeRef _c_ref

    cdef void _set_c_ref(self, void* c_ref)
    cdef void* _get_c_ref(self)
    cdef bint _is_initialized(self)
    cdef void _validate_initialized(self) except *
    cdef void* copy_c_ref(self) except NULL


cdef class SITypesWrapper(BaseWrapper):
    """Base class for SITypes wrappers."""
    cdef int _compare_c_api(self, other) except? -999


cdef class RMNLibWrapper(BaseWrapper):
    """Base class for RMNLib wrappers."""
    cdef int _compare_c_api(self, other) except? -999
