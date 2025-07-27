"""
Helper functions for converting between Python types and OCTypes.

These are used internally by the SITypes and RMNLib wrappers.
They are not part of the public API.
"""

__all__ = [
    # String conversion functions
    "create_oc_string",
    "parse_c_string",
    "ocstring_to_py_string",
    "py_string_to_ocstring",
    "py_string_to_ocmutablestring",
    # Number conversion functions
    "py_complex_to_ocnumber",
    "py_number_to_ocnumber",
    "ocnumber_to_py_number",
    # Boolean conversion functions
    "py_bool_to_ocboolean",
    "ocboolean_to_py_bool",
    # Data/NumPy conversion functions
    "numpy_array_to_ocdata",
    "ocdata_to_numpy_array",
    "numpy_array_to_ocmutabledata",
    # Array conversion functions
    "py_list_to_ocarray",
    "ocarray_to_py_list",
    "py_list_to_ocmutablearray",
    # Dictionary conversion functions
    "py_dict_to_ocdictionary",
    "ocdictionary_to_py_dict",
    "py_dict_to_ocmutabledictionary",
    # Set conversion functions
    "py_set_to_ocset",
    "ocset_to_py_set",
    "py_set_to_ocmutableset",
    # Index array/set conversion functions
    "py_list_to_ocindexarray",
    "ocindexarray_to_py_list",
    "py_set_to_ocindexset",
    "ocindexset_to_py_set",
    "py_dict_to_ocindexpairset",
    "ocindexpairset_to_py_dict",
    # Memory management functions
    "release_octype",
    "retain_octype",
    "get_retain_count",
    # Type introspection functions
    "octype_get_type_id",
    "octype_equal",
    "octype_deep_copy",
]

# Directly import the Cython‐built helpers.
from .octypes import (  # String conversion functions; Number conversion functions; Boolean conversion functions; Data/NumPy conversion functions; Array conversion functions; Dictionary conversion functions; Set conversion functions; Index array/set conversion functions; Memory management functions; Type introspection functions
    create_oc_string,
    get_retain_count,
    numpy_array_to_ocdata,
    numpy_array_to_ocmutabledata,
    ocarray_to_py_list,
    ocboolean_to_py_bool,
    ocdata_to_numpy_array,
    ocdictionary_to_py_dict,
    ocindexarray_to_py_list,
    ocindexpairset_to_py_dict,
    ocindexset_to_py_set,
    ocnumber_to_py_number,
    ocset_to_py_set,
    ocstring_to_py_string,
    octype_deep_copy,
    octype_equal,
    octype_get_type_id,
    parse_c_string,
    py_bool_to_ocboolean,
    py_complex_to_ocnumber,
    py_dict_to_ocdictionary,
    py_dict_to_ocindexpairset,
    py_dict_to_ocmutabledictionary,
    py_list_to_ocarray,
    py_list_to_ocindexarray,
    py_list_to_ocmutablearray,
    py_number_to_ocnumber,
    py_set_to_ocindexset,
    py_set_to_ocmutableset,
    py_set_to_ocset,
    py_string_to_ocmutablestring,
    py_string_to_ocstring,
    release_octype,
    retain_octype,
)
