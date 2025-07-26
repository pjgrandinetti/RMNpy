"""
SITypes Python wrappers

This module provides Python interfaces to the SITypes library for
scientific units, dimensional analysis, and physical quantities.
"""

import rmnpy.dll_loader as _dll_loader

from .dimensionality import Dimensionality  # type: ignore[attr-defined]
from .scalar import Scalar
from .unit import Unit  # type: ignore[attr-defined]

__all__ = ["Dimensionality", "Unit", "Scalar"]

# Initialize DLL loader before loading extensions
_dll_loader.setup_dll_paths()
_dll_loader.preload_mingw_runtime()
