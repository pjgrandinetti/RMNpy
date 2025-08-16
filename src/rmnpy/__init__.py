"""
RMNpy: Python bindings for OCTypes, SITypes, and RMNLib.

This package provides:
- helpers: Internal conversion utilities for OCTypes
- wrappers: High-level Python interfaces for SITypes and RMNLib
- rmnlib: Convenient access to RMNLib classes (DependentVariable, Dimensions, etc.)
- sitypes: Convenient access to SITypes classes (Unit, Dimensionality, Scalar)
- quantities: SI quantity name constants
"""

import os

# Setup platform-specific library paths before importing any C extensions
import sys
from pathlib import Path

if sys.platform == "win32":
    from .dll_loader import setup_dll_paths

    setup_dll_paths()
elif sys.platform.startswith("linux") or sys.platform.startswith("darwin"):
    # For Linux and macOS, add the package directory to LD_LIBRARY_PATH equivalent
    package_dir = Path(__file__).parent

    # Pre-load the shared libraries to ensure they're found
    import ctypes

    # Library file extensions by platform
    if sys.platform.startswith("linux"):
        lib_ext = ".so"
    else:  # macOS
        lib_ext = ".dylib"

    # Try to pre-load the libraries in dependency order
    lib_files = [f"libOCTypes{lib_ext}", f"libSITypes{lib_ext}", f"libRMN{lib_ext}"]

    for lib_file in lib_files:
        lib_path = package_dir / lib_file
        if lib_path.exists():
            try:
                ctypes.CDLL(str(lib_path), mode=ctypes.RTLD_GLOBAL)
            except OSError as e:
                # Log but don't fail - the libraries might still be found through other means
                print(f"Warning: Could not pre-load {lib_file}: {e}", file=sys.stderr)

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
