"""Type definitions and utilities for RMNpy."""

from typing import List, Optional, Union, Dict, Any, Tuple
import numpy as np
from numpy.typing import NDArray

# Type aliases for better documentation and type hints
ArrayLike = Union[List, Tuple, NDArray[np.floating]]
MetadataDict = Dict[str, Any]
Coordinate = Union[float, int]
CoordinateList = List[Coordinate]


class DimensionType:
    """Enumeration of dimension types supported by RMNLib.
    
    These correspond to the different dimension classes in RMNLib:
    - LABELED: Discrete labels (categories)
    - SI: General SI units with physical quantities  
    - MONOTONIC: Non-uniformly spaced but monotonic coordinates
    - LINEAR: Uniformly spaced coordinates
    """
    LABELED = "labeled"
    SI = "si_dimension" 
    MONOTONIC = "monotonic"
    LINEAR = "linear"


class ScalingType:
    """Enumeration of scaling types for SI dimensions.
    
    These affect how physical quantities are interpreted:
    - NONE: No special scaling applied
    - NMR: NMR-specific scaling conventions
    """
    NONE = 0
    NMR = 1


class DataType:
    """Enumeration of supported data types for dependent variables.
    
    These correspond to the OCNumber types in the underlying library.
    """
    FLOAT32 = "float32"
    FLOAT64 = "float64" 
    COMPLEX64 = "complex64"
    COMPLEX128 = "complex128"
    INT8 = "int8"
    INT16 = "int16"
    INT32 = "int32"
    INT64 = "int64"
    UINT8 = "uint8"
    UINT16 = "uint16"
    UINT32 = "uint32"
    UINT64 = "uint64"


class Quantity:
    """Represents a physical quantity with value and unit.
    
    This is a simple Python representation that gets converted
    to SIScalar objects in the C library.
    
    Attributes:
        value: Numerical value
        unit: Unit string (e.g., "Hz", "ppm", "s")
        uncertainty: Optional measurement uncertainty
    """
    
    def __init__(self, value: float, unit: str = "", uncertainty: Optional[float] = None):
        self.value = value
        self.unit = unit
        self.uncertainty = uncertainty
    
    def __str__(self) -> str:
        if self.unit:
            result = f"{self.value} {self.unit}"
        else:
            result = str(self.value)
        
        if self.uncertainty is not None:
            result += f" ± {self.uncertainty}"
        
        return result
    
    def __repr__(self) -> str:
        return f"Quantity({self.value!r}, {self.unit!r}, {self.uncertainty!r})"


# Utility functions for type validation
def validate_array_like(data: Any, name: str = "data") -> NDArray:
    """Validate and convert array-like input to numpy array."""
    try:
        arr = np.asarray(data)
        if arr.size == 0:
            raise ValueError(f"{name} cannot be empty")
        return arr
    except (ValueError, TypeError) as e:
        raise TypeError(f"{name} must be array-like, got {type(data).__name__}: {e}")


def validate_positive_integer(value: Any, name: str = "value") -> int:
    """Validate that a value is a positive integer."""
    try:
        int_val = int(value)
        if int_val <= 0:
            raise ValueError(f"{name} must be positive, got {int_val}")
        return int_val
    except (ValueError, TypeError) as e:
        raise TypeError(f"{name} must be a positive integer: {e}")


def validate_string(value: Any, name: str = "value", allow_none: bool = True) -> Optional[str]:
    """Validate string input."""
    if value is None:
        if allow_none:
            return None
        else:
            raise ValueError(f"{name} cannot be None")
    
    if isinstance(value, str):
        return value
    
    # Try to convert to string
    try:
        return str(value)
    except (ValueError, TypeError) as e:
        raise TypeError(f"{name} must be a string or convertible to string: {e}")


def validate_coordinates(coords: Any, name: str = "coordinates") -> Optional[List[float]]:
    """Validate coordinate list."""
    if coords is None:
        return None
    
    try:
        coord_list = list(coords)
        return [float(c) for c in coord_list]
    except (ValueError, TypeError) as e:
        raise TypeError(f"{name} must be a list of numbers: {e}")
