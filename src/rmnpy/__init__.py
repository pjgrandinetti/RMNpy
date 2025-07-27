"""
RMNpy: Python bindings for OCTypes, SITypes, and RMNLib.

This package provides:
- helpers: Internal conversion utilities for OCTypes
- wrappers: High-level Python interfaces for SITypes and RMNLib
"""

__version__ = "0.1.0"
__author__ = "Philip Grandinetti"
__email__ = "grandinetti.1@osu.edu"

# Import the main Cython-built API elements
from .wrappers.sitypes import Dimensionality, Scalar, Unit

__all__ = [
    "__version__",
    "__author__",
    "__email__",
    "Dimensionality",
    "Scalar",
    "Unit",
]
