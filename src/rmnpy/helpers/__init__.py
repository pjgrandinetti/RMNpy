"""
Helper functions for converting between Python types and OCTypes

This module provides internal conversion utilities that handle the
translation between Python objects and OCTypes C structures. These
helpers are not exposed to end users but are used internally by
the SITypes and RMNLib wrappers.
"""

# Import convenience functions for SITypes integration
from .octypes import create_oc_string, parse_c_string

__all__ = [
    "parse_c_string",
    "create_oc_string",
]
