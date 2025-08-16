# cython: language_level=3
"""
RMNpy DependentVariable Cython declarations for cross-module imports.

This .pxd file allows other Cython modules to cimport and use
the DependentVariable class from dependent_variable.pyx.
"""

from rmnpy._c_api.octypes cimport OCNumberType
from rmnpy._c_api.rmnlib cimport DependentVariableRef


cdef class DependentVariable:
    """Cython interface for DependentVariable wrapper."""
    cdef DependentVariableRef _c_ref

    @staticmethod
    cdef DependentVariable _from_c_ref(DependentVariableRef dep_var_ref)
    cdef OCNumberType _element_type_to_enum(self, element_type)
