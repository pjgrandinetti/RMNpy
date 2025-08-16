"""
RMNpy: Python bindings for OCTypes, SITypes, and RMNLib.

This package provides:
- helpers: Internal conversion utilities for OCTypes
- wrappers: High-level Python interfaces for SITypes and RMNLib
- rmnlib: Convenient access to RMNLib classes (DependentVariable, Dimensions, etc.)
- sitypes: Convenient access to SITypes classes (Unit, Dimensionality, Scalar)
- quantities: SI quantity name constants
"""

# Setup Windows DLL paths before importing any C extensions
import sys

if sys.platform == "win32":
    from .dll_loader import setup_dll_paths

    setup_dll_paths()

# Read version from package metadata (single source of truth in pyproject.toml)
try:
    import importlib.metadata

    __version__ = importlib.metadata.version("rmnpy")
except ImportError:
    # Fallback for Python < 3.8
    try:
        import importlib_metadata

        __version__ = importlib_metadata.version("rmnpy")
    except ImportError:
        # Fallback if package not installed (e.g., during development)
        __version__ = "unknown"
except Exception:
    # Fallback if package not installed (e.g., during development)
    __version__ = "unknown"
__author__ = "Philip Grandinetti"
__email__ = "grandinetti.1@osu.edu"

# Import convenience modules
from . import rmnlib, sitypes

# Import commonly used classes for direct access
from .rmnlib import DependentVariable

# Import quantities module if available (compiled Cython extension)
try:
    from . import quantities
except ImportError:
    # This is expected during development/build process
    # quantities.pyx needs to be compiled first
    pass

# Import the main Cython-built API elements (legacy paths for compatibility)
from .wrappers.sitypes import Dimensionality, Scalar, Unit

__all__ = [
    "__version__",
    "__author__",
    "__email__",
    # Legacy direct imports (for compatibility)
    "Dimensionality",
    "Scalar",
    "Unit",
    # New convenience modules
    "rmnlib",
    "sitypes",
    "quantities",
    # Common classes
    "DependentVariable",
]
