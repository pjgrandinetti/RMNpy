from .core cimport *

cdef class Dataset:
    cdef DatasetRef _ref
