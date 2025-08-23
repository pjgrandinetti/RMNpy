# cython: language_level=3
"""
SI Quantity Constants - Auto-generated from SITypes C API

This module provides access to all SI quantity names supported by the SITypes library.
The quantities are dynamically loaded from the C library to ensure completeness.

Usage:
    from rmnpy import quantity
    dim = Dimensionality.for_quantity(quantity.Length)
    dim = Dimensionality.for_quantity(quantity.ElectricCharge)

All quantity names follow PascalCase convention (e.g., 'electric charge' -> 'ElectricCharge').
"""

from rmnpy._c_api.sitypes cimport *
from rmnpy._c_api.octypes cimport *
from rmnpy.helpers.octypes import ocstring_to_pystring


def get_all_quantity_names():
    """
    Get all available quantity names from the SITypes library.

    Returns:
        list[str]: List of all quantity name strings
    """
    cdef OCArrayRef quantity_names
    cdef uint64_t count, i
    cdef const void* item_ptr
    cdef OCStringRef string_item
    
    quantity_names = SIDimensionalityCreateArrayOfAllQuantityNames()
    if quantity_names == NULL:
        raise RuntimeError("Failed to get quantity names from SITypes library")
    
    try:
        count = OCArrayGetCount(quantity_names)
        
        # Convert each OCString item to Python string
        result = []
        for i in range(count):
            item_ptr = OCArrayGetValueAtIndex(quantity_names, i)
            if item_ptr != NULL:
                # Cast to OCStringRef and convert directly
                string_item = <OCStringRef>item_ptr
                py_string = ocstring_to_pystring(<uint64_t>string_item)
                result.append(py_string)
        
        return result
        
    finally:
        OCRelease(<OCTypeRef>quantity_names)


# Initialize quantities at module import
_quantity_names = get_all_quantity_names()

# Create clean Python aliases for all quantities
# This makes them available as quantity.Length, quantity.Mass, etc.
for _name in _quantity_names:
    _python_name = ''.join(word.capitalize() for word in _name.replace('-', ' ').replace('_', ' ').split())
    globals()[_python_name] = _name

# Build __all__ list with all available quantities
__all__ = [
    # Utility functions
    "get_all_quantity_names",
    # All quantity constants (dynamically added)
] + [
    ''.join(word.capitalize() for word in name.replace('-', ' ').replace('_', ' ').split())
    for name in _quantity_names
]
