"""
RMNLib Python wrappers

This module provides Python interfaces to the RMNLib library for
high-level analysis and computation tools.
"""

# Import wrapper classes when they're available
try:
    from .dimension import Dimension

    __all__ = ["Dimension"]
except ImportError:
    # Wrapper not yet built/available
    __all__ = []

# TODO: Add other wrappers when implemented
# try:
#     from .dependent_variable import DependentVariable
#     __all__.append("DependentVariable")
# except ImportError:
#     pass
