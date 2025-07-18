# Shared Cython helper functions for RMNpy
from .exceptions import RMNLibValidationError, RMNLibMemoryError
# Note: SIScalar helpers are available in sitypes.scalar module

cdef OCStringRef _py_to_ocstring(py_str):
    """Convert Python string to OCStringRef."""
    if py_str is None:
        return NULL
    str_bytes = py_str.encode('utf-8')
    return OCStringCreateWithCString(str_bytes)

cdef object _ocstring_to_py(OCStringRef ocstr):
    """Convert OCStringRef to Python string."""
    if ocstr == NULL:
        return None
    cdef const char* c_str = OCStringGetCString(ocstr)
    if c_str == NULL:
        return None
    return c_str.decode('utf-8')

# distutils: sources = ../../../SITypes/src/SIType.c
# distutils: include_dirs = ../../../SITypes/src ../../../OCTypes/src

from .core cimport *
from .sitypes.helpers cimport py_to_siscalar_ref, siscalar_ref_to_py
from .sitypes.scalar cimport SIScalarRef

__all__ = ["array_to_list", "dict_to_py_dict", "list_to_array", "py_dict_to_dict"]

# Legacy wrapper functions for backward compatibility
cdef SIScalarRef _py_to_siscalar(double value, object unit_str = None):
    """Convert Python value to SIScalarRef (legacy wrapper)."""
    if unit_str is not None:
        # Create expression string and delegate to sitypes parser
        expression = f"{value} {unit_str}"
        return py_to_siscalar_ref(expression)
    else:
        return py_to_siscalar_ref(value)

cdef SIScalarRef _py_expression_to_siscalar(object expression_str):
    """Convert Python string expression to SIScalarRef (legacy wrapper)."""
    return py_to_siscalar_ref(expression_str)

cdef double _siscalar_to_py(SIScalarRef scalar):
    """Convert SIScalarRef to Python float (legacy wrapper)."""
    return siscalar_ref_to_py(scalar)

cdef OCArrayRef _py_list_to_ocarray(py_list, item_converter=None):
    """Convert Python list to OCArrayRef."""
    if py_list is None or len(py_list) == 0:
        return NULL
    cdef OCMutableArrayRef mutable_array = OCArrayCreateMutable(len(py_list), NULL)
    if mutable_array == NULL:
        raise RMNLibMemoryError("Failed to create OCArray")
    cdef OCStringRef string_item = NULL
    try:
        for item in py_list:
            string_item = _py_to_ocstring(str(item))
            if string_item != NULL:
                OCArrayAppendValue(mutable_array, <const void*>string_item)
        return <OCArrayRef>mutable_array
    except Exception as e:
        OCRelease(mutable_array)
        raise
