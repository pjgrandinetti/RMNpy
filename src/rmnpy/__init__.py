"""
RMNpy: Python bindings for OCTypes, SITypes, and RMNLib

This package provides Python access to three C libraries:
- OCTypes: Objective-C style data structures and memory management
- SITypes: Scientific units and dimensional analysis
- RMNLib: High-level analysis and computation tools

The package is organized into:
- helpers: Internal conversion utilities for OCTypes
- wrappers: High-level Python interfaces for SITypes and RMNLib
"""

import logging
import sys

# Set up logging for package initialization
_logger = logging.getLogger(__name__)
_handler = logging.StreamHandler(sys.stderr)
_handler.setFormatter(logging.Formatter("[%(asctime)s] RMNPY_INIT: %(message)s"))
_logger.addHandler(_handler)
_logger.setLevel(logging.INFO)

_logger.info("Starting RMNpy package initialization")

# Check if we're in a pytest environment which can cause import conflicts
in_pytest = "pytest" in sys.modules or "pytest" in str(sys.argv)
if in_pytest:
    _logger.warning("Detected pytest environment - using defensive import strategy")

# CRITICAL: Import DLL loader FIRST to set up Windows DLL paths
# This implements Claude Opus 4's recommendation to fix DLL import issues
_logger.info("Importing DLL loader module")
from . import dll_loader  # Import DLL loader first  # noqa: E402

# Initialize DLL loader before loading C extension modules
_logger.info("Setting up DLL paths")
dll_loader.setup_dll_paths()
_logger.info("Running MinGW runtime preload")
_ = getattr(dll_loader, "preload_mingw_runtime", lambda: None)()

_logger.info("Attempting to import C extension modules")

# Global flag to prevent double imports
_extensions_loaded = False

if not _extensions_loaded:
    try:
        # Add extra safety for pytest contexts
        if in_pytest:
            _logger.info("Using pytest-safe import strategy")

        from .wrappers.sitypes import Dimensionality, Scalar, Unit  # noqa: E402

        _logger.info("Successfully imported SITypes wrappers")
        _extensions_loaded = True
    except Exception as e:
        _logger.error(f"Failed to import SITypes wrappers: {e}")

        # In pytest context, provide more debugging info but try to continue
        if in_pytest:
            _logger.error("Import failure occurred in pytest context")
            import traceback

            _logger.error(f"Full traceback: {traceback.format_exc()}")

        raise
else:
    _logger.info("C extensions already loaded, skipping re-import")

__version__ = "0.1.0"
__author__ = "Philip Grandinetti"
__email__ = "grandinetti.1@osu.edu"

# Import main functionality is done above for proper ordering
__all__ = [
    "__version__",
    "__author__",
    "__email__",
    "Dimensionality",
    "Unit",
    "Scalar",
]

_logger.info("RMNpy package initialization completed successfully")
