"""
RMNpy - Python wrapper for RMNLib scientific data library.

RMNpy provides a Pythonic interface to the RMNLib C library for working with
Core Scientific Dataset Model (CSDM) files and multidimensional scientific datasets.

Main Classes:
    Dataset: Represents a complete scientific dataset with dimensions and data
    Datum: Represents a single data point with coordinates and response
    Dimension: Represents coordinate axes (labeled, SI, monotonic, linear)
    DependentVariable: Represents data variables with units and metadata

Example:
    >>> import rmnpy
    >>> dataset = rmnpy.Dataset.create(title="My NMR Spectrum")
    >>> datum = rmnpy.Datum.create(response_value=1.5, coordinates=[100.0])
    >>> print(f"Created dataset: {dataset}")

For more information, visit: https://github.com/pjgrandinetti/RMNpy
"""

from .core import Dataset, Datum, Dimension, DependentVariable, shutdown
from .exceptions import RMNLibError, RMNLibMemoryError, RMNLibValidationError
from .types import DimensionType, ScalingType

__version__ = "0.1.0"
__author__ = "Philip Grandinetti"
__email__ = "grandinetti.1@osu.edu"

__all__ = [
    # Core classes
    "Dataset",
    "Datum", 
    "Dimension",
    "DependentVariable",
    
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
