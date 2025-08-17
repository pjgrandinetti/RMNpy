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

    def _extract_missing_library(lib_filename: str, target_dir: Path) -> None:
        """Extract missing library from package resources if available."""
        try:
            import importlib.resources as resources

            # Try to read the library from package data
            try:
                with resources.files("rmnpy").joinpath(lib_filename).open(
                    "rb"
                ) as lib_data:
                    lib_content = lib_data.read()
                    target_path = target_dir / lib_filename
                    print(
                        f"DEBUG: Extracting {lib_filename} to {target_path}",
                        file=sys.stderr,
                    )
                    with open(target_path, "wb") as f:
                        f.write(lib_content)
                    # Make it executable
                    target_path.chmod(0o755)
                    print(
                        f"DEBUG: Successfully extracted {lib_filename}", file=sys.stderr
                    )
            except (FileNotFoundError, AttributeError):
                # Library not found in package resources
                print(
                    f"DEBUG: {lib_filename} not found in package resources",
                    file=sys.stderr,
                )
        except ImportError:
            # importlib.resources not available
            print(
                "DEBUG: importlib.resources not available for library extraction",
                file=sys.stderr,
            )
        except Exception as e:
            print(f"DEBUG: Error extracting {lib_filename}: {e}", file=sys.stderr)

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
            # Try to extract from embedded wheel data if available
            try:
                _extract_missing_library(lib_file, package_dir)
                # Try loading again after extraction
                if lib_path.exists():
                    try:
                        print(
                            f"DEBUG: Loading extracted {lib_file}...", file=sys.stderr
                        )
                        ctypes.CDLL(str(lib_path), mode=ctypes.RTLD_GLOBAL)
                        print(
                            f"DEBUG: Successfully loaded extracted {lib_file}",
                            file=sys.stderr,
                        )
                    except OSError as e:
                        print(
                            f"Warning: Could not load extracted {lib_file}: {e}",
                            file=sys.stderr,
                        )
            except Exception as e:
                print(f"DEBUG: Could not extract {lib_file}: {e}", file=sys.stderr)

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
    print("This can happen in certain environments like Google Colab.", file=sys.stderr)
    print("", file=sys.stderr)
    print("🔧 QUICK FIX - Run this command to fix the issue:", file=sys.stderr)
    print("", file=sys.stderr)
    print("  import rmnpy; rmnpy.quick_fix()", file=sys.stderr)
    print("", file=sys.stderr)
    print("Or for more detailed diagnostics:", file=sys.stderr)
    print("", file=sys.stderr)
    print("  import rmnpy", file=sys.stderr)
    print("  rmnpy.colab_install_fix()", file=sys.stderr)
    print("", file=sys.stderr)
    print(
        "This will automatically download and install the missing libraries.",
        file=sys.stderr,
    )
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
