"""
Helper functions for converting between # Directly import the Cython‐built helpers.
from .octypes import (  # String conversion functions; Number conversion functions; Boolean conversion functions; Data/NumPy conversion functions; Array conversion functions; Dictionary conversion functions; Set conversion functions; Index array/set conversion functions
    numpy_array_to_ocdata,on types and OCTypes.

These are used internally by the SITypes and RMNLib wrappers.
They are not part of the public API.
"""

__all__ = [
    # String conversion functions
    "pystring_from_ocstring",
    "ocstring_create_with_pystring",
    "pystring_to_ocmutablestring",
    # Number conversion functions
    "pycomplex_to_ocnumber",
    "pynumber_to_ocnumber",
    "ocnumber_to_pynumber",
    # Boolean conversion functions
    "pybool_to_ocboolean",
    "ocboolean_to_pybool",
    # Data/NumPy conversion functions
    "numpy_array_to_ocdata",
    "ocdata_to_numpy_array",
    "numpy_array_to_ocmutabledata",
    # Array conversion functions
    "pylist_to_ocarray",
    "ocarray_to_pylist",
    "pylist_to_ocmutablearray",
    # Dictionary conversion functions
    "pydict_to_ocdict",
    "ocdict_to_pydict",
    "pydict_to_ocmutabledict",
    # Set conversion functions
    "pyset_to_ocset",
    "ocset_to_pyset",
    "pyset_to_ocmutableset",
    # Index array/set conversion functions
    "pylist_to_ocindexarray",
    "ocindexarray_to_pylist",
    "pyset_to_ocindexset",
    "ocindexset_to_pyset",
    "pydict_to_ocindexpairset",
    "ocindexpairset_to_pydict",
]

# Directly import the Cython‐built helpers.
from .octypes import (  # String conversion functions; Number conversion functions; Boolean conversion functions; Data/NumPy conversion functions; Array conversion functions; Dictionary conversion functions; Set conversion functions; Index array/set conversion functions; Type introspection functions
    numpy_array_to_ocdata,
    numpy_array_to_ocmutabledata,
    ocarray_to_pylist,
    ocboolean_to_pybool,
    ocdata_to_numpy_array,
    ocdict_to_pydict,
    ocindexarray_to_pylist,
    ocindexpairset_to_pydict,
    ocindexset_to_pyset,
    ocnumber_to_pynumber,
    ocset_to_pyset,
    ocstring_create_with_pystring,
    pybool_to_ocboolean,
    pycomplex_to_ocnumber,
    pydict_to_ocdict,
    pydict_to_ocindexpairset,
    pydict_to_ocmutabledict,
    pylist_to_ocarray,
    pylist_to_ocindexarray,
    pylist_to_ocmutablearray,
    pynumber_to_ocnumber,
    pyset_to_ocindexset,
    pyset_to_ocmutableset,
    pyset_to_ocset,
    pystring_from_ocstring,
    pystring_to_ocmutablestring,
)
