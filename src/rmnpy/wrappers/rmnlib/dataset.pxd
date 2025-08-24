# cython: language_level=3
"""
RMNLib Dataset wrapper declarations

This file provides Cython declarations for the Dataset wrapper class,
enabling other Cython modules to import and use Dataset objects efficiently.
"""

from rmnpy._c_api.rmnlib cimport DatasetRef


cdef class Dataset:
    """Cython declaration for Dataset wrapper class."""
    cdef DatasetRef _c_ref

    @staticmethod
    cdef Dataset _from_c_ref(DatasetRef dataset_ref)
