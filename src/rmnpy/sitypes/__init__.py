"""
SITypes - SI Units and Dimensionality

This module provides convenient access to SITypes functionality with shorter import paths.
"""

from rmnpy.wrappers.sitypes.dimensionality import Dimensionality
from rmnpy.wrappers.sitypes.scalar import Scalar

# Re-export main classes from the wrappers for convenience
from rmnpy.wrappers.sitypes.unit import Unit, get_unit_symbol_tokens_lib

# Import quantity module - it should always be available after build
from . import quantity  # type: ignore[attr-defined]

__all__ = [
    "Unit",
    "Dimensionality",
    "Scalar",
    "quantity",
    "get_unit_symbol_tokens_lib",
]
