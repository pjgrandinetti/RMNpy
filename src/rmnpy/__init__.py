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
    # For Linux and macOS, pre-load shared libraries in dependency order
    package_dir = Path(__file__).parent

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
            except OSError:
                # Library loading failed, but continue - auditwheel should have bundled dependencies
                pass

    # Set LD_LIBRARY_PATH for Linux if needed
    if sys.platform.startswith("linux"):
        current_ld_path = os.environ.get("LD_LIBRARY_PATH", "")
        new_ld_path = (
            f"{package_dir}:{current_ld_path}" if current_ld_path else str(package_dir)
        )
        os.environ["LD_LIBRARY_PATH"] = new_ld_path

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

# Import Google Colab compatibility fix
try:
    from .colab_fix import colab_install_fix, quick_fix
except ImportError:

    def colab_install_fix() -> bool:
        print("Colab fix utility not available in this installation")
        return False

    def quick_fix() -> bool:
        print("Quick fix utility not available in this installation")
        return False


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
    # Google Colab compatibility
    "colab_install_fix",
    "quick_fix",
]


# Add a helpful message for import errors
def _handle_import_error() -> None:
    """Provide helpful instructions when import fails due to missing libraries."""
    print("=" * 60, file=sys.stderr)
    print("RMNpy ImportError - Missing Shared Libraries", file=sys.stderr)
    print("=" * 60, file=sys.stderr)
    print(
        "It appears that shared libraries are missing from your installation.",
        file=sys.stderr,
    )
    print("This typically means the wheel was not built correctly.", file=sys.stderr)
    print("", file=sys.stderr)
    print("� Possible solutions:", file=sys.stderr)
    print("", file=sys.stderr)
    print("1. Try installing system dependencies:", file=sys.stderr)
    print(
        "   !apt-get update && apt-get install -y liblapacke-dev libomp-dev",
        file=sys.stderr,
    )
    print("", file=sys.stderr)
    print("2. Report this issue at:", file=sys.stderr)
    print("   https://github.com/pjgrandinetti/RMNpy/issues", file=sys.stderr)
    print("", file=sys.stderr)
    print("=" * 60, file=sys.stderr)


# Check if this is being imported from a failing context
try:
    # Test a basic import that should work if libraries are properly installed
    from .wrappers.sitypes.scalar import Scalar as _test_scalar
except ImportError as e:
    if "libOCTypes.so" in str(e) or "cannot open shared object file" in str(e):
        _handle_import_error()
    # Re-raise the original error
    raise
