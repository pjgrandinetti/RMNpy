from .core cimport *

cdef class Dimension:
    cdef DimensionRef _ref
