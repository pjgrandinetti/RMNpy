"""
RMNpy - Python wrapper for RMNLib scientific dataset library.

RMNpy provides a Pythonic interface to the RMNLib C library for working with
Core Scientific Dataset Model (CSDM) files and multidimensional scientific datasets.

Currently Implemented Classes:
    Dataset: Represents a complete scientific dataset with dimensions and data
    Dimension: Represents coordinate axes (labeled, SI, monotonic, linear)
    DependentVariable: Represents data variables with units and metadata  
    Datum: Represents individual data points with coordinates and response values
    SparseSampling: Represents non-uniform, non-Cartesian sampling layouts
    SIScalar: Represents physical quantities with values and units

Available in RMNLib but not yet wrapped in RMNpy:
    GeographicCoordinate: For geographic location data with lat/lon/altitude
    RMNGridUtils: Grid utility functions

Example:
    >>> import rmnpy
    >>> dataset = rmnpy.Dataset.create()
    >>> print(f"Created dataset: {dataset}")

For more information, visit: https://github.com/pjgrandinetti/RMNpy
"""

from .core import Dataset, Datum, Dimension, DependentVariable, SparseSampling, shutdown
# Backward compatibility: Import SIScalar from new sitypes module
from .sitypes import SIScalar
from .exceptions import RMNLibError, RMNLibMemoryError, RMNLibValidationError
from .types import DimensionType, ScalingType

# Also expose the sitypes module for users who want the new API
from . import sitypes

__version__ = "0.1.0"
__author__ = "Philip Grandinetti"
__email__ = "grandinetti.1@osu.edu"

__all__ = [
    # Core classes
    "Dataset",
    "Datum", 
    "Dimension",
    "DependentVariable",
    "SparseSampling",
    "SIScalar",  # Backward compatibility
    
    # SITypes module (new API)
    "sitypes",
    
    # Exceptions
    "RMNLibError",
    "RMNLibMemoryError", 
    "RMNLibValidationError",
    
    # Type definitions
    "DimensionType",
    "ScalingType",
    
    # Utility functions
    "shutdown",
    
    # Metadata
    "__version__",
    "__author__",
    "__email__",
]

# Clean up resources when module is unloaded
import atexit
atexit.register(shutdown)
