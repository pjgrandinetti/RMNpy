"""
SITypes - SI Units and Dimensionality

This module provides convenient access to SITypes functionality with shorter import paths.
"""

from rmnpy.wrappers.sitypes.dimensionality import Dimensionality
from rmnpy.wrappers.sitypes.scalar import Scalar

# Re-export main classes from the wrappers for convenience
from rmnpy.wrappers.sitypes.unit import Unit, get_unit_symbol_tokens_lib

# Dynamic quantity module with all SITypes quantities
try:
    from . import quantity  # noqa: F401,E402
except Exception:
    pass

__all__ = [
    "Unit",
    "Dimensionality", 
    "Scalar",
    "quantity",
    "get_unit_symbol_tokens_lib",
]
