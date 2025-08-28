# cython: language_level=3
"""
RMNpy DependentVariable Cython declarations for cross-module imports.

This .pxd file allows other Cython modules to cimport and use
the DependentVariable class from dependent_variable.pyx.
"""

from rmnpy._c_api.octypes cimport OCNumberType
from rmnpy._c_api.rmnlib cimport DependentVariableRef
from rmnpy.wrappers.base_wrapper cimport RMNLibWrapper


cdef class DependentVariable(RMNLibWrapper):
    """Cython interface for DependentVariable wrapper."""

    cdef OCNumberType _element_type_to_enum(self, element_type)
