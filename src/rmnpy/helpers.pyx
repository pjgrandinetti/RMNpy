# Shared Cython helper functions for RMNpy
from .exceptions import RMNLibValidationError, RMNLibMemoryError

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

cdef SIScalarRef _py_to_siscalar(double value, object unit_str = None):
    """Convert Python value to SIScalarRef."""
    cdef SIUnitRef unit = NULL
    cdef SIScalarRef result = NULL
    
    # For now, just create with basic SI unit (NULL for dimensionless)
    result = SIScalarCreateWithDouble(value, unit)
    if result == NULL:
        raise RMNLibMemoryError("Failed to create SIScalar")
    return result

cdef double _siscalar_to_py(SIScalarRef scalar):
    """Convert SIScalarRef to Python float."""
    if scalar == NULL:
        return 0.0
    return SIScalarDoubleValueInCoherentUnit(scalar)

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
