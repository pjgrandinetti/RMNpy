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
try:
    from .wrappers.sitypes import Dimensionality, Scalar, Unit  # noqa: E402

    _logger.info("Successfully imported SITypes wrappers")
except Exception as e:
    _logger.error(f"Failed to import SITypes wrappers: {e}")
    raise

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
