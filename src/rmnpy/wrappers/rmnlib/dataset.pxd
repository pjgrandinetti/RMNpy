# cython: language_level=3
"""
RMNLib Dataset wrapper declarations

This file provides Cython declarations for the Dataset wrapper class,
enabling other Cython modules to import and use Dataset objects efficiently.
"""

from rmnpy._c_api.rmnlib cimport DatasetRef
from rmnpy.wrappers.base_wrapper cimport RMNLibWrapper


cdef class Dataset(RMNLibWrapper):
    """Cython declaration for Dataset wrapper class."""
    pass
