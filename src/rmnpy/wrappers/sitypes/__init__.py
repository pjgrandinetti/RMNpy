"""
SITypes Python wrappers

This module provides Python interfaces to the SITypes library for
scientific units, dimensional analysis, and physical quantities.
"""

# Initialize DLL loader before loading C extensions
import rmnpy.dll_loader as _dll_loader  # noqa: E402

# Initialize DLL loader before loading C extensions
_dll_loader.setup_dll_paths()
_dll_loader.preload_mingw_runtime()
from .dimensionality import Dimensionality  # type: ignore[attr-defined]  # noqa: E402
from .scalar import Scalar  # noqa: E402
from .unit import Unit  # type: ignore[attr-defined]  # noqa: E402

__all__ = ["Dimensionality", "Unit", "Scalar"]
