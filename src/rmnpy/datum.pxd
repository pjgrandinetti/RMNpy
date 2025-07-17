from .core cimport *

cdef class Datum:
    cdef DatumRef _ref
