# cython: language_level=3
"""
Cython declarations for OCTypes helper functions.

This file provides C-level function declarations that can be imported
by other Cython modules using cimport.
"""

from rmnpy._c_api.octypes cimport cJSON


# JSON/Dictionary conversion functions
cdef object cjson_to_pydict(cJSON* json_obj)
