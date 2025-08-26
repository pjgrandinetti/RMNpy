"""
RMNLib - NMR Data Types and Structures

This module provides convenient access to RMNLib functionality with shorter import paths.
"""

# Re-export main classes from the wrappers for convenience
from rmnpy.wrappers.rmnlib.dataset import Dataset
from rmnpy.wrappers.rmnlib.datum import Datum
from rmnpy.wrappers.rmnlib.dependent_variable import DependentVariable
from rmnpy.wrappers.rmnlib.dimension import (
    BaseDimension,
    DimensionScaling,
    LabeledDimension,
    LinearDimension,
    MonotonicDimension,
    SIDimension,
)
from rmnpy.wrappers.rmnlib.geographic_coordinate import GeographicCoordinate
from rmnpy.wrappers.rmnlib.sparse_sampling import SparseSampling

__all__ = [
    "Dataset",
    "Datum",
    "DependentVariable",
    "BaseDimension",
    "SIDimension",
    "LabeledDimension",
    "LinearDimension",
    "MonotonicDimension",
    "DimensionScaling",
    "GeographicCoordinate",
    "SparseSampling",
]
