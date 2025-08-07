"""
RMNLib Python wrappers

This module provides Python interfaces to the RMNLib library for
high-level analysis and computation tools.
"""

# Import wrapper classes when they're available
try:
    from .dependent_variable import DependentVariable
    from .dimension import Dimension

    __all__ = ["Dimension", "DependentVariable"]
except ImportError:
    # Wrapper not yet built/available
    __all__ = []
