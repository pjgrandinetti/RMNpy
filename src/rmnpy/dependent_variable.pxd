from .core cimport *

cdef class DependentVariable:
    cdef DependentVariableRef _ref
