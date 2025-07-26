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

# CRITICAL: Import DLL loader FIRST to set up Windows DLL paths
# This implements Claude Opus 4's recommendation to fix DLL import issues
# CRITICAL: Import DLL loader FIRST to set up Windows DLL paths
# This implements Claude Opus 4's recommendation to fix DLL import issues
from . import dll_loader  # This sets up DLL paths before any other imports
from .wrappers.sitypes import Dimensionality, Scalar, Unit

# Automatically initialize DLL loading on import
dll_loader.setup_dll_paths()
dll_loader.preload_mingw_runtime()

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
