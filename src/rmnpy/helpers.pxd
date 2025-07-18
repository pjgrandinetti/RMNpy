from .core cimport *
from .sitypes.scalar cimport SIScalarRef

cdef OCStringRef _py_to_ocstring(object py_str)
cdef object _ocstring_to_py(OCStringRef ocstr)

# Legacy SIScalar helper functions (use sitypes module for new code)
cdef SIScalarRef _py_to_siscalar(double value, object unit_str=*)
cdef SIScalarRef _py_expression_to_siscalar(object expression_str)
cdef double _siscalar_to_py(SIScalarRef scalar)
cdef OCArrayRef _py_list_to_ocarray(object py_list, object item_converter=*)
