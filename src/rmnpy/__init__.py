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

    # Debug: List all files in package directory
    try:
        all_files = list(package_dir.iterdir())
        lib_files_found = [f for f in all_files if f.name.endswith(lib_ext)]
        print(f"DEBUG: Package directory: {package_dir}", file=sys.stderr)
        print(
            f"DEBUG: Library files found: {[f.name for f in lib_files_found]}",
            file=sys.stderr,
        )
    except Exception as e:
        print(f"DEBUG: Error listing package directory: {e}", file=sys.stderr)

    # Try to pre-load the libraries in dependency order
    lib_files = [f"libOCTypes{lib_ext}", f"libSITypes{lib_ext}", f"libRMN{lib_ext}"]

    for lib_file in lib_files:
        lib_path = package_dir / lib_file
        print(f"DEBUG: Checking for {lib_path}", file=sys.stderr)
        if lib_path.exists():
            try:
                print(f"DEBUG: Loading {lib_file}...", file=sys.stderr)
                ctypes.CDLL(str(lib_path), mode=ctypes.RTLD_GLOBAL)
                print(f"DEBUG: Successfully loaded {lib_file}", file=sys.stderr)
            except OSError as e:
                print(f"Warning: Could not pre-load {lib_file}: {e}", file=sys.stderr)
        else:
            print(f"DEBUG: Library {lib_file} not found at {lib_path}", file=sys.stderr)

    # Alternative approach: try to set LD_LIBRARY_PATH environment variable
    if sys.platform.startswith("linux"):
        current_ld_path = os.environ.get("LD_LIBRARY_PATH", "")
        new_ld_path = (
            f"{package_dir}:{current_ld_path}" if current_ld_path else str(package_dir)
        )
        os.environ["LD_LIBRARY_PATH"] = new_ld_path
        print(f"DEBUG: Set LD_LIBRARY_PATH to: {new_ld_path}", file=sys.stderr)

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
