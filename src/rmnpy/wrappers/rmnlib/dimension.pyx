# cython: language_level=3
"""
RMNLib Dimension wrapper with proper inheritance hierarchy

This module provides Python wrappers that mirror the C inheritance:
- BaseDimension (abstract base for common functionality)
- LabeledDimension (for discrete labeled coordinates)
- SIDimension (base for quantitative coordinates with SI units)
  - SILinearDimension (for linear coordinates with constant increment)
  - SIMonotonicDimension (for monotonic coordinates with arbitrary spacing)

Use the specific dimension classes directly for explicit dimension creation.
"""

from typing import Any, Dict, List, Optional, Union

import numpy as np

# Import Cython types

from libc.stdint cimport uintptr_t

# Import all C API declarations
from rmnpy._c_api.octypes cimport *
from rmnpy._c_api.rmnlib cimport *
from rmnpy._c_api.sitypes cimport *

from rmnpy.exceptions import RMNError

# Import Cython class interfaces

from rmnpy.wrappers.sitypes.scalar cimport Scalar

# Import helper conversion functions

from rmnpy.helpers.octypes import (
    ocarray_to_pylist,
    ocdict_to_pydict,
    ocnumber_to_pynumber,
    ocstring_to_pystring,
    py_list_to_siscalar_ocarray,
    pydict_to_ocdict,
    pylist_to_ocarray,
    pynumber_to_ocnumber,
    pynumber_to_siscalar_expression,
    pyscalar_to_siscalar,
    pystring_to_ocstring,
)


cdef class BaseDimension:
    """
    Abstract base class for all dimensions.

    Thin wrapper providing common functionality shared across all dimension types:
    - Memory management for C dimension objects
    - Common properties: type, description, label, count, application
    - Utility methods: to_dict(), dict(), is_quantitative(), __repr__()

    All properties are retrieved directly from the C API (single source of truth).
    No duplicate Python storage to avoid synchronization issues.
    """
    cdef DimensionRef _c_dimension

    def __cinit__(self):
        """Initialize C-level attributes."""
        self._c_dimension = NULL

    def __dealloc__(self):
        """Clean up C resources."""
        if self._c_dimension != NULL:
            OCRelease(self._c_dimension)

    @property
    def type(self):
        """Get the type of the dimension."""
        if self._c_dimension != NULL:
            type_ref = DimensionGetType(self._c_dimension)
            if type_ref != NULL:
                return ocstring_to_pystring(<uint64_t>type_ref)
        # Fallback for subclasses that override this property
        raise NotImplementedError("Subclasses must implement type property")

    @property
    def description(self):
        """Get the description of the dimension."""
        if self._c_dimension != NULL:
            desc_ref = DimensionGetDescription(self._c_dimension)
            if desc_ref != NULL:
                return ocstring_to_pystring(<uint64_t>desc_ref)
        return ""

    @description.setter
    def description(self, value):
        """Set the description of the dimension."""
        cdef OCStringRef error = NULL
        cdef uint64_t desc_ptr

        if not isinstance(value, str):
            raise TypeError("Description must be a string")

        # Update C dimension object only - single source of truth
        if self._c_dimension != NULL:
            desc_ptr = pystring_to_ocstring(value)
            try:
                if not DimensionSetDescription(self._c_dimension, <OCStringRef>desc_ptr, &error):
                    if error != NULL:
                        error_msg = ocstring_to_pystring(<uint64_t>error)
                        OCRelease(<OCTypeRef>error)
                        raise RMNError(f"Failed to set description: {error_msg}")
                    else:
                        raise RMNError("Failed to set description")
            finally:
                OCRelease(<OCTypeRef>desc_ptr)

    @property
    def label(self):
        """Get the label of the dimension."""
        if self._c_dimension != NULL:
            label_ref = DimensionGetLabel(self._c_dimension)
            if label_ref != NULL:
                return ocstring_to_pystring(<uint64_t>label_ref)
        return ""

    @label.setter
    def label(self, value):
        """Set the label of the dimension."""
        cdef OCStringRef error = NULL
        cdef uint64_t label_ptr

        if not isinstance(value, str):
            raise TypeError("Label must be a string")

        # Update C dimension object only - single source of truth
        if self._c_dimension != NULL:
            label_ptr = pystring_to_ocstring(value)
            try:
                if not DimensionSetLabel(self._c_dimension, <OCStringRef>label_ptr, &error):
                    if error != NULL:
                        error_msg = ocstring_to_pystring(<uint64_t>error)
                        OCRelease(<OCTypeRef>error)
                        raise RMNError(f"Failed to set label: {error_msg}")
                    else:
                        raise RMNError("Failed to set label")
            finally:
                OCRelease(<OCTypeRef>label_ptr)

    @property
    def count(self):
        """Get the count of the dimension."""
        if self._c_dimension != NULL:
            return DimensionGetCount(self._c_dimension)
        return 0

    @property
    def application(self):
        """Get application metadata."""
        cdef OCDictionaryRef application_ref

        if self._c_dimension != NULL:
            # Get metadata dictionary from C API - single source of truth
            application_ref = DimensionGetApplicationMetaData(self._c_dimension)
            if application_ref != NULL:
                return ocdict_to_pydict(<uint64_t>application_ref)
        return {}

    @application.setter
    def application(self, value):
        """Set application metadata."""
        cdef OCStringRef error = NULL
        cdef uint64_t dict_ptr

        if value is not None and not isinstance(value, dict):
            raise TypeError("Application metadata must be a dictionary or None")

        # Update C dimension object only - single source of truth
        if self._c_dimension != NULL:
            if value is None or len(value) == 0:
                # Set empty metadata (NULL)
                if not DimensionSetApplicationMetaData(self._c_dimension, NULL, &error):
                    if error != NULL:
                        error_msg = ocstring_to_pystring(<uint64_t>error)
                        OCRelease(<OCTypeRef>error)
                        raise RMNError(f"Failed to clear metadata: {error_msg}")
                    else:
                        raise RMNError("Failed to clear metadata")
            else:
                # Convert Python dict to OCDictionary and set
                dict_ptr = pydict_to_ocdict(value)
                try:
                    if not DimensionSetApplicationMetaData(self._c_dimension, <OCDictionaryRef>dict_ptr, &error):
                        if error != NULL:
                            error_msg = ocstring_to_pystring(<uint64_t>error)
                            OCRelease(<OCTypeRef>error)
                            raise RMNError(f"Failed to set metadata: {error_msg}")
                        else:
                            raise RMNError("Failed to set metadata")
                finally:
                    OCRelease(<OCTypeRef>dict_ptr)

    def is_quantitative(self):
        """Check if dimension is quantitative (not labeled)."""
        return self.type != "labeled"

    def to_dict(self):
        """Convert to dictionary."""
        # Use C API as single source of truth
        if self._c_dimension != NULL:
            dict_ref = DimensionCopyAsDictionary(self._c_dimension)
            if dict_ref != NULL:
                try:
                    # Convert C dictionary to Python dict using helper
                    return ocdict_to_pydict(<uint64_t>dict_ref)
                finally:
                    OCRelease(dict_ref)

        # Minimal fallback for dimensions without C objects
        return {
            'type': self.type,
            'count': self.count,
        }

    def dict(self):
        """Alias for to_dict() method (csdmpy compatibility)."""
        return self.to_dict()

    def __repr__(self):
        """String representation."""
        return f"{self.__class__.__name__}(type='{self.type}', count={self.count})"

cdef class LabeledDimension(BaseDimension):
    """
    Dimension with discrete labels (non-quantitative).

    Used for dimensions that represent discrete categories or labels
    rather than continuous physical quantities.

    Examples:
        >>> dim = LabeledDimension(['A', 'B', 'C'])
        >>> dim.coordinates
        array(['A', 'B', 'C'], dtype='<U1')
        >>> dim.is_quantitative()
        False
        >>> dim.count
        3
    """
    cdef LabeledDimensionRef _labeled_dimension

    def __init__(self, labels, label=None, description=None, application=None, **kwargs):
        """
        Initialize labeled dimension.

        C API Requirements (LabeledDimensionCreate):
        - coordinateLabels: REQUIRED ≥2 string labels (fails with "need ≥2 coordinate labels")
        - All other parameters: OPTIONAL (can be NULL)

        Args:
            labels (list, REQUIRED): List of string labels for coordinates (≥2 elements required)
            label (str, optional): Short label for the dimension
            description (str, optional): Description of the dimension
            application (dict, optional): Application metadata
            **kwargs: Additional keyword arguments (for compatibility)

        Raises:
            RMNError: If labels array has <2 elements or conversion fails
            RMNError: If labels is empty or None

        Examples:
            # Basic labeled dimension (minimum 2 labels required)
            >>> dim = LabeledDimension(['A', 'B', 'C'])
            >>> dim.coordinates
            array(['A', 'B', 'C'], dtype='<U1')

            # With metadata
            >>> dim = LabeledDimension(
            ...     ['low', 'medium', 'high'],
            ...     label='intensity',
            ...     description='Intensity levels'
            ... )

            # With application metadata
            >>> dim = LabeledDimension(
            ...     ['red', 'green', 'blue'],
            ...     label='color',
            ...     description='RGB color channels',
            ...     application={'encoding': 'sRGB'}
            ... )
        """
        cdef OCArrayRef labels_array = <OCArrayRef><uint64_t>pylist_to_ocarray(labels)
        cdef OCStringRef label_ref = <OCStringRef><uint64_t>pystring_to_ocstring(label)
        cdef OCStringRef desc_ref = <OCStringRef><uint64_t>pystring_to_ocstring(description)
        cdef OCDictionaryRef application_ref = <OCDictionaryRef><uint64_t>pydict_to_ocdict(application)
        cdef OCStringRef error = NULL

        try:
            # Create the labeled dimension (C API handles validation)
            self._labeled_dimension = LabeledDimensionCreate(
                label_ref, desc_ref, application_ref, labels_array, &error)
            if self._labeled_dimension == NULL:
                if error != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>error)
                    raise RMNError(f"Failed to create labeled dimension: {error_msg}")
                else:
                    raise RMNError("Failed to create labeled dimension")
            # Keep base reference
            self._c_dimension = <DimensionRef>self._labeled_dimension
        finally:
            OCRelease(<OCTypeRef>label_ref)
            OCRelease(<OCTypeRef>desc_ref)
            if application_ref != NULL:
                OCRelease(<OCTypeRef>application_ref)
            OCRelease(<OCTypeRef>labels_array)
            if error != NULL:
                OCRelease(<OCTypeRef>error)

    @property
    def type(self):
        """Get the type of the dimension."""
        if self._c_dimension != NULL:
            type_ref = DimensionGetType(self._c_dimension)
            if type_ref != NULL:
                return ocstring_to_pystring(<uint64_t>type_ref)
        return 'labeled'  # Fallback

    @property
    def coordinates(self) -> np.ndarray:
        """Get coordinates (labels) for this dimension."""
        if self._c_dimension != NULL:
            labels_ref = LabeledDimensionGetCoordinateLabels(self._labeled_dimension)
            if labels_ref != NULL:
                # Use helper function to convert OCArray to Python list
                labels_list = ocarray_to_pylist(<uint64_t>labels_ref)
                if labels_list:
                    return np.array(labels_list)

        # Return empty array if no C object or no labels
        return np.array([])

    @property
    def coords(self) -> np.ndarray:
        """Alias for coordinates."""
        return self.coordinates

    @property
    def labels(self):
        """Get labels for labeled dimensions."""
        return self.coordinates

    @labels.setter
    def labels(self, value):
        """Set labels for labeled dimensions (alias for coordinate_labels)."""
        self.coordinate_labels = value

    @property
    def coordinate_labels(self):
        """Get coordinate labels."""
        return self.coordinates

    @coordinate_labels.setter
    def coordinate_labels(self, value):
        """Set coordinate labels."""
        cdef OCStringRef error = NULL
        cdef OCArrayRef labels_array = <OCArrayRef><uint64_t>pylist_to_ocarray(value)

        # Update C dimension object - single source of truth
        if self._c_dimension != NULL:
            try:
                if not LabeledDimensionSetCoordinateLabels(self._labeled_dimension, labels_array, &error):
                    if error != NULL:
                        error_msg = ocstring_to_pystring(<uint64_t>error)
                        OCRelease(<OCTypeRef>error)
                        raise RMNError(f"Failed to set coordinate labels: {error_msg}")
                    else:
                        raise RMNError("Failed to set coordinate labels")
            finally:
                OCRelease(<OCTypeRef>labels_array)

    def set_coordinate_label_at_index(self, index, label):
        """Set coordinate label at specific index."""
        cdef OCStringRef error = NULL
        cdef OCStringRef label_ref = NULL

        # Validate index first using C API count
        if not (0 <= index < self.count):
            raise IndexError(f"Label index {index} out of range")

        # Update C dimension object - single source of truth
        if self._c_dimension != NULL:
            try:
                label_ref = <OCStringRef><uint64_t>pystring_to_ocstring(str(label))
                if not LabeledDimensionSetCoordinateLabelAtIndex(self._labeled_dimension, index, label_ref):
                    raise RMNError(f"Failed to set coordinate label at index {index}")
            finally:
                if label_ref != NULL:
                    OCRelease(<OCTypeRef>label_ref)

    @property
    def count(self):
        """Get the count of the dimension."""
        # Use C API as single source of truth
        if self._c_dimension != NULL:
            return DimensionGetCount(self._c_dimension)
        return 0

    def copy(self):
        """Create a copy of the dimension."""
        return LabeledDimension(
            labels=list(self.coordinates),  # Get from C API
            label=self.label,
            description=self.description,
            application=self.application
        )

    @property
    def axis_label(self):
        """Get axis label for labeled dimensions."""
        if self.label:
            return self.label
        else:
            return "categories"

    def to_dict(self):
        """Convert to dictionary."""
        # Get the base dictionary from C API
        base_dict = super().to_dict()
        # Ensure count is included
        if 'count' not in base_dict:
            base_dict['count'] = self.count
        return base_dict

cdef class SIDimension(BaseDimension):
    """
    Base class for quantitative dimensions with SI units.

    Provides common functionality for quantitative dimensions including
    coordinate offsets, periods, and unit-aware operations.
    """
    cdef SIDimensionRef _si_dimension

    def __init__(self, label=None, description=None, application=None,
                 quantity_name=None, offset=None, origin=None, period=None,
                 periodic=False, scaling=0, coordinates_offset=None, origin_offset=None,
                 complex_fft=False, **kwargs):
        """
        Initialize SI dimension.

        C API Requirements (SIDimensionCreate):
        - ALL parameters are OPTIONAL (function provides intelligent defaults)
        - Derives units from first non-NULL scalar (priority: offset → origin → period → quantityName → dimensionless)
        - Creates zero scalars in appropriate units for NULL parameters

        Args:
            label (str, optional): Short label for the dimension
            description (str, optional): Description of the dimension
            application (dict, optional): Application metadata
            quantity_name (str, optional): Physical quantity name (e.g., "frequency", "time")
                If None, derived from first available scalar's dimensionality
            offset (str or Scalar, optional): SIScalar offset value
                Defaults to zero in derived base unit
            origin (str or Scalar, optional): SIScalar origin value
                Defaults to zero in derived base unit
            period (str or Scalar, optional): SIScalar period value for periodic dimensions
                Defaults to zero in derived base unit
            periodic (bool, optional): True if dimension wraps around
            scaling (int, optional): Dimension scaling type (0 = kDimensionScalingNone)
            coordinates_offset (str, optional): Coordinates offset value (legacy, use origin instead)
            origin_offset (str, optional): Origin offset value (legacy, use origin instead)
            complex_fft (bool, optional): Complex FFT flag (legacy)
            **kwargs: Additional keyword arguments (for compatibility)

        Note:
            SIDimension is abstract - use SILinearDimension or SIMonotonicDimension instead.
            This class provides common SI dimension functionality and default parameter handling.
        """
        # Create C dimension using the C API
        cdef OCStringRef label_ref = <OCStringRef><uint64_t>pystring_to_ocstring(label)
        cdef OCStringRef desc_ref = <OCStringRef><uint64_t>pystring_to_ocstring(description)
        # Convert application metadata (None → NULL)
        cdef OCDictionaryRef application_ref = <OCDictionaryRef><uint64_t>pydict_to_ocdict(application)
        cdef OCStringRef quantity_name_ref = <OCStringRef><uint64_t>pystring_to_ocstring(quantity_name)
        cdef SIScalarRef offset_ref = Scalar(offset).get_c_scalar() if offset is not None else NULL
        cdef SIScalarRef origin_ref = Scalar(origin).get_c_scalar() if origin is not None else NULL
        cdef SIScalarRef period_ref = Scalar(period).get_c_scalar() if period is not None else NULL
        cdef OCStringRef error = NULL
        cdef object offset_scalar = None
        cdef object origin_scalar = None
        cdef object period_scalar = None

        try:
            # Create the SI dimension using the C API with correct signature
            self._si_dimension = SIDimensionCreate(
                label_ref, desc_ref, application_ref, quantity_name_ref,
                offset_ref, origin_ref, period_ref, periodic, scaling, &error)

            if self._si_dimension == NULL:
                if error != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>error)
                    raise RMNError(f"Failed to create SI dimension: {error_msg}")
                else:
                    raise RMNError("Failed to create SI dimension")

            # Cast to base dimension reference
            self._c_dimension = <DimensionRef>self._si_dimension

        finally:
            if label_ref != NULL:
                OCRelease(<OCTypeRef>label_ref)
            if desc_ref != NULL:
                OCRelease(<OCTypeRef>desc_ref)
            if application_ref != NULL:
                OCRelease(<OCTypeRef>application_ref)
            if quantity_name_ref != NULL:
                OCRelease(<OCTypeRef>quantity_name_ref)
            if error != NULL:
                OCRelease(<OCTypeRef>error)

    @property
    def type(self):
        """Get the type of the dimension."""
        if self._c_dimension != NULL:
            type_ref = DimensionGetType(self._c_dimension)
            if type_ref != NULL:
                return ocstring_to_pystring(<uint64_t>type_ref)
        return 'si'  # Fallback

    def copy(self):
        """Create a copy of the dimension."""
        return SIDimension(
            label=self.label,
            description=self.description,
            application=self.application,
            # Get current values from C API, not stored Python values
            offset=self.coordinates_offset,
            origin=self.origin_offset,
            period=self.period
        )

    @property
    def coordinates_offset(self):
        """Get coordinates offset."""
        if self._c_dimension != NULL and self._si_dimension != NULL:
            offset_ref = SIDimensionGetCoordinatesOffset(self._si_dimension)
            if offset_ref != NULL:
                # Extract value directly without creating Scalar wrapper to avoid memory issues
                value = SIScalarDoubleValue(offset_ref)
                return value
        return 0.0  # Default to 0

    @coordinates_offset.setter
    def coordinates_offset(self, value):
        """Set coordinates offset."""
        cdef OCStringRef error = NULL

        # Ensure we have valid dimension pointers
        if self._c_dimension == NULL or self._si_dimension == NULL:
            raise RMNError("Cannot set coordinates offset: dimension not properly initialized")

        # Convert value to SIScalarRef and update C dimension object
        # Let Scalar constructor handle dimensionless units automatically
        cdef Scalar scalar_obj = Scalar(str(value))
        if not SIDimensionSetCoordinatesOffset(self._si_dimension, scalar_obj.get_c_scalar(), &error):
            if error != NULL:
                error_msg = ocstring_to_pystring(<uint64_t>error)
                OCRelease(<OCTypeRef>error)
                raise RMNError(f"Failed to set coordinates offset: {error_msg}")
            else:
                raise RMNError("Failed to set coordinates offset")

    @property
    def origin_offset(self):
        """Get origin offset."""
        if self._c_dimension != NULL and self._si_dimension != NULL:
            origin_ref = SIDimensionGetOriginOffset(self._si_dimension)
            if origin_ref != NULL:
                # Extract value directly without creating Scalar wrapper to avoid memory issues
                value = SIScalarDoubleValue(origin_ref)
                return value
        return 0.0  # Default to 0 instead of None

    @origin_offset.setter
    def origin_offset(self, value):
        """Set origin offset."""
        cdef OCStringRef error = NULL

        # Ensure we have valid dimension pointers
        if self._c_dimension == NULL or self._si_dimension == NULL:
            raise RMNError("Cannot set origin offset: dimension not properly initialized")

        # Convert value to SIScalarRef - use simple approach
        cdef Scalar scalar_obj = Scalar(str(value))
        if not SIDimensionSetOriginOffset(self._si_dimension, scalar_obj.get_c_scalar(), &error):
            if error != NULL:
                error_msg = ocstring_to_pystring(<uint64_t>error)
                OCRelease(<OCTypeRef>error)
                raise RMNError(f"Failed to set origin offset: {error_msg}")
            else:
                raise RMNError("Failed to set origin offset")

    @property
    def period(self):
        """Get the period."""
        if self._c_dimension != NULL and self._si_dimension != NULL:
            period_ref = SIDimensionGetPeriod(self._si_dimension)
            if period_ref != NULL:
                # Try to extract value directly first
                value = SIScalarDoubleValue(period_ref)
                # Check for nan, zero, and valid values
                if value != value:  # nan check
                    return float("inf")  # treat nan as infinite
                elif value == 0.0:
                    return float("inf")  # Zero period means infinite
                else:
                    return value
            else:
                # NULL period means infinity in SITypes
                return float("inf")
        return float("inf")  # Default to infinity

    @period.setter
    def period(self, value):
        """Set the period."""
        cdef OCStringRef error = NULL

        # Ensure we have valid dimension pointers
        if self._c_dimension == NULL or self._si_dimension == NULL:
            raise RMNError("Cannot set period: dimension not properly initialized")

        # Update the C dimension object
        if value is not None:
            # Convert value to SIScalarRef - use simple approach
            scalar_obj = Scalar(str(value))
            if not SIDimensionSetPeriod(self._si_dimension, scalar_obj.get_c_scalar(), &error):
                if error != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>error)
                    OCRelease(<OCTypeRef>error)
                    raise RMNError(f"Failed to set period: {error_msg}")
                else:
                    raise RMNError("Failed to set period")
        else:
            # Set NULL period for infinite period
            if not SIDimensionSetPeriod(self._si_dimension, NULL, &error):
                if error != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>error)
                    OCRelease(<OCTypeRef>error)
                    raise RMNError(f"Failed to clear period: {error_msg}")
                else:
                    raise RMNError("Failed to clear period")

    @property
    def absolute_coordinates(self) -> np.ndarray:
        """Get absolute coordinates along the dimension."""
        coords = self.coordinates
        origin_offset_val = self.origin_offset

        if origin_offset_val is None:
            return coords

        # Convert Scalar coordinates to numeric values and add origin offset
        if isinstance(coords[0], Scalar):
            numeric_coords = np.array([float(coord.value) for coord in coords])
        else:
            numeric_coords = coords

        # Convert origin offset to numeric value
        if isinstance(origin_offset_val, Scalar):
            origin_offset_numeric = float(origin_offset_val.value)
        else:
            origin_offset_numeric = float(origin_offset_val)

        return numeric_coords + origin_offset_numeric

    @property
    def axis_label(self):
        """Get formatted axis label."""
        if self.label:
            return self.label
        elif hasattr(self, 'quantity_name') and self.quantity_name:
            return f"{self.quantity_name} / arbitrary unit"
        else:
            return f"{self.type} / arbitrary unit"

    @property
    def quantity_name(self):
        """Get quantity name for physical quantities."""
        if self._c_dimension != NULL and self._si_dimension != NULL:
            quantity_ref = SIDimensionGetQuantityName(self._si_dimension)
            if quantity_ref != NULL:
                return ocstring_to_pystring(<uint64_t>quantity_ref)
        return "dimensionless"  # Default fallback

    @quantity_name.setter
    def quantity_name(self, value):
        """Set quantity name for physical quantities."""
        cdef OCStringRef error = NULL
        cdef OCStringRef quantity_name_ref = NULL

        # If we have a C dimension object, update it too
        if self._c_dimension != NULL:
            if value is not None and value != "":
                quantity_name_ref = <OCStringRef><uint64_t>pystring_to_ocstring(str(value))
                try:
                    if not SIDimensionSetQuantityName(self._si_dimension, quantity_name_ref, &error):
                        if error != NULL:
                            error_msg = ocstring_to_pystring(<uint64_t>error)
                            OCRelease(<OCTypeRef>error)
                            raise RMNError(f"Failed to set quantity name: {error_msg}")
                        else:
                            raise RMNError("Failed to set quantity name")
                finally:
                    if quantity_name_ref != NULL:
                        OCRelease(<OCTypeRef>quantity_name_ref)
            else:
                # Set NULL for no quantity name
                if not SIDimensionSetQuantityName(self._si_dimension, NULL, &error):
                    if error != NULL:
                        error_msg = ocstring_to_pystring(<uint64_t>error)
                        OCRelease(<OCTypeRef>error)
                        raise RMNError(f"Failed to clear quantity name: {error_msg}")
                    else:
                        raise RMNError("Failed to clear quantity name")

    @property
    def periodic(self):
        """Get periodic flag."""
        if self._c_dimension != NULL and self._si_dimension != NULL:
            return SIDimensionIsPeriodic(self._si_dimension)
        return False

    @periodic.setter
    def periodic(self, value):
        """Set periodic flag."""
        cdef OCStringRef error = NULL

        # If we have a C dimension object, update it too
        if self._c_dimension != NULL:
            if not SIDimensionSetPeriodic(self._si_dimension, bool(value), &error):
                if error != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>error)
                    OCRelease(<OCTypeRef>error)
                    raise RMNError(f"Failed to set periodic flag: {error_msg}")
                else:
                    raise RMNError("Failed to set periodic flag")

    @property
    def scaling(self):
        """Get scaling type."""
        # TODO: Add C API getter once available
        return 0  # Default placeholder (kDimensionScalingNone)

    @scaling.setter
    def scaling(self, value):
        """Set scaling type."""
        cdef OCStringRef error = NULL

        # If we have a C dimension object, update it too
        if self._c_dimension != NULL:
            if not SIDimensionSetScaling(self._si_dimension, int(value)):
                raise RMNError("Failed to set scaling")

cdef class SILinearDimension(SIDimension):
    """
    Linear dimension with constant increment.

    Used for dimensions with evenly spaced coordinates, such as
    time series or frequency sweeps with constant spacing.

    Examples:
        >>> dim = SILinearDimension({'count': 5, 'increment': '2.0'})
        >>> dim.coordinates
        array([0., 2., 4., 6., 8.])
        >>> dim.increment
        2.0
    """
    cdef SILinearDimensionRef _linear_dimension
    cdef object _increment_scalar  # Keep reference to prevent GC during init
    cdef object _reciprocal  # Cache for reciprocal dimension wrapper

    def __init__(self, count, increment="1.0", label=None, description=None,
                 application=None, quantity_name=None, offset=None, origin=None,
                 period=None, periodic=False, scaling=0, fft=False, reciprocal=None,
                 coordinates_offset=None, origin_offset=None, complex_fft=False, **kwargs):
        """
        Initialize linear dimension.

        C API Requirements (SILinearDimensionCreate):
        - count: REQUIRED ≥2 (fails with "need ≥2 points")
        - increment: REQUIRED real SIScalar (fails with "increment must be a real SIScalar")
        - All other parameters: OPTIONAL (function provides defaults)

        Args:
            count (int, REQUIRED): Number of coordinates, must be ≥2
            increment (str or Scalar, REQUIRED): Increment between coordinates,
                converted to real-valued SIScalar (use Scalar('10.0 Hz') for units)
            label (str, optional): Short label for the dimension (default: None = NULL)
            description (str, optional): Description of the dimension (default: None = NULL)
            application (dict, optional): Application metadata (default: None = NULL)
            quantity_name (str, optional): Physical quantity name (default: None = NULL, C API derives from increment)
            offset (str or Scalar, optional): SIScalar offset value (default: None = NULL, C API uses zero)
            origin (str or Scalar, optional): SIScalar origin value (default: None = NULL, C API uses zero)
            period (str or Scalar, optional): SIScalar period value for periodic dimensions (default: None = NULL)
            periodic (bool, optional): True if dimension wraps around
            scaling (int, optional): Dimension scaling type (0 = kDimensionScalingNone)
            fft (bool, optional): True if used for FFT
            reciprocal (SIDimension, optional): Reciprocal dimension (default: None = NULL)
            coordinates_offset (str, optional): Coordinates offset value (legacy, use origin instead, default: None = NULL)
            origin_offset (str, optional): Origin offset value (legacy, use origin instead, default: None = NULL)
            complex_fft (bool, optional): Complex FFT flag (legacy, use fft instead)
            **kwargs: Additional keyword arguments (for compatibility)

        Raises:
            RMNError: If count < 2 or increment is not a real SIScalar
            RMNError: If increment cannot be converted to Scalar
            TypeError: If count or increment are not provided (required parameters)

        Examples:
            # Basic linear dimension (count and increment required)
            >>> dim = SILinearDimension(count=10, increment='1.0 Hz')

            # With units and metadata
            >>> dim = SILinearDimension(
            ...     count=100,
            ...     increment='10.0 kHz',
            ...     label='frequency',
            ...     quantity_name='frequency'
            ... )
        """
        # Create C dimension using the C API
        cdef OCStringRef error = NULL
        cdef OCStringRef label_ref = <OCStringRef><uint64_t>pystring_to_ocstring(label)
        cdef OCStringRef desc_ref = <OCStringRef><uint64_t>pystring_to_ocstring(description)
        # Convert application metadata (None → NULL)
        cdef OCDictionaryRef application_ref = <OCDictionaryRef><uint64_t>pydict_to_ocdict(application)
        cdef OCStringRef quantity_name_ref = <OCStringRef><uint64_t>pystring_to_ocstring(quantity_name)

        # Handle parameter aliases
        if coordinates_offset is not None:
            offset = coordinates_offset

        if origin_offset is not None:
            origin = origin_offset

        # Convert scalar inputs using helper functions (which return owned references)
        cdef SIScalarRef increment_ref = NULL
        cdef SIScalarRef offset_ref = NULL
        cdef SIScalarRef origin_ref = NULL
        cdef SIScalarRef period_ref = NULL

        if increment is not None:
            if isinstance(increment, Scalar):
                # Get the reference and retain it (since C API will copy it)
                increment_ref = (<Scalar>increment).get_c_scalar()
                increment_ref = <SIScalarRef>OCRetain(<OCTypeRef>increment_ref)
            else:
                # For strings, use direct conversion
                increment_ref = <SIScalarRef><uint64_t>pynumber_to_siscalar_expression(1.0, str(increment))

        if offset is not None:
            if isinstance(offset, Scalar):
                offset_ref = (<Scalar>offset).get_c_scalar()
                offset_ref = <SIScalarRef>OCRetain(<OCTypeRef>offset_ref)
            else:
                offset_ref = <SIScalarRef><uint64_t>pynumber_to_siscalar_expression(1.0, str(offset))

        if origin is not None:
            if isinstance(origin, Scalar):
                origin_ref = (<Scalar>origin).get_c_scalar()
                origin_ref = <SIScalarRef>OCRetain(<OCTypeRef>origin_ref)
            else:
                origin_ref = <SIScalarRef><uint64_t>pynumber_to_siscalar_expression(1.0, str(origin))

        if period is not None:
            if isinstance(period, Scalar):
                period_ref = (<Scalar>period).get_c_scalar()
                period_ref = <SIScalarRef>OCRetain(<OCTypeRef>period_ref)
            else:
                period_ref = <SIScalarRef><uint64_t>pynumber_to_siscalar_expression(1.0, str(period))

        cdef const char* c_expr
        cdef OCStringRef expr_ref
        cdef SIDimensionRef reciprocal_ref = NULL
        cdef OCTypeID scalar_type_id, actual_type_id
        cdef bint is_complex

        try:

            # Handle reciprocal dimension - only if provided
            if reciprocal is not None:
                if hasattr(reciprocal, '_si_dimension'):
                    reciprocal_ref = (<SIDimension>reciprocal)._si_dimension
                else:
                    reciprocal_ref = NULL

            # Let C API handle validation and error reporting
            self._linear_dimension = SILinearDimensionCreate(
                label_ref,              # label
                desc_ref,               # description
                application_ref,        # metadata
                quantity_name_ref,      # quantityName
                offset_ref,             # offset
                origin_ref,             # origin
                period_ref,             # period
                periodic,               # periodic
                scaling,                # scaling
                count,                  # count (use parameter, not stored value)
                increment_ref,          # increment (required)
                fft or complex_fft,     # fft (use parameter, not stored value)
                reciprocal_ref,         # reciprocal
                &error                  # error
            )

            if self._linear_dimension == NULL:
                if error != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>error)
                    raise RMNError(f"Failed to create linear dimension: {error_msg}")
                else:
                    raise RMNError("Failed to create linear dimension")

            # Cast to base dimension references
            self._c_dimension = <DimensionRef>self._linear_dimension
            self._si_dimension = <SIDimensionRef>self._linear_dimension

        finally:
            if label_ref != NULL:
                OCRelease(<OCTypeRef>label_ref)
            if desc_ref != NULL:
                OCRelease(<OCTypeRef>desc_ref)
            if quantity_name_ref != NULL:
                OCRelease(<OCTypeRef>quantity_name_ref)
            if application_ref != NULL:
                OCRelease(<OCTypeRef>application_ref)
            # Release all scalar references (we either retained them or created them)
            if increment_ref != NULL:
                OCRelease(<OCTypeRef>increment_ref)
            if offset_ref != NULL:
                OCRelease(<OCTypeRef>offset_ref)
            if origin_ref != NULL:
                OCRelease(<OCTypeRef>origin_ref)
            if period_ref != NULL:
                OCRelease(<OCTypeRef>period_ref)
            if error != NULL:
                OCRelease(<OCTypeRef>error)

    @property
    def type(self):
        """Get the type of the dimension."""
        if self._c_dimension != NULL:
            type_ref = DimensionGetType(self._c_dimension)
            if type_ref != NULL:
                return ocstring_to_pystring(<uint64_t>type_ref)
        return 'linear'  # Fallback

    @property
    def increment(self):
        """Get the increment of the dimension."""
        if self._c_dimension != NULL:
            increment_ref = SILinearDimensionGetIncrement(self._linear_dimension)
            if increment_ref != NULL:
                # Convert SIScalarRef to Python float
                scalar = Scalar._from_ref(increment_ref)
                return scalar.value
        return None

    @increment.setter
    def increment(self, value):
        """Set the increment of the dimension."""
        cdef SIScalarRef increment_ref = NULL
        cdef Scalar scalar_obj = None

        try:
            # Handle both existing Scalar objects and string values
            if isinstance(value, Scalar):
                # For existing Scalar objects, store reference to prevent GC
                scalar_obj = value
                increment_ref = scalar_obj.get_c_scalar()
                OCRetain(<void*>increment_ref)
            else:
                # For strings and other values, use helper function
                scalar_obj = Scalar(str(value))
                increment_ref = scalar_obj.get_c_scalar()
                OCRetain(<void*>increment_ref)

            if increment_ref == NULL:
                raise RMNError("Failed to convert increment value to SIScalar")

            # Set the increment using C API
            if not SILinearDimensionSetIncrement(self._linear_dimension, increment_ref):
                raise RMNError("Failed to set increment")

        finally:
            # Release our reference since C API copies the scalar
            if increment_ref != NULL:
                OCRelease(<void*>increment_ref)

    @property
    def count(self):
        """Get the count of the dimension."""
        if self._c_dimension != NULL:
            return SILinearDimensionGetCount(self._linear_dimension)
        return 0

    @count.setter
    def count(self, value):
        """Set the count of the dimension."""
        if not isinstance(value, int) or value <= 0:
            raise TypeError("Count must be a positive integer")

        # Update C dimension object only
        if not SILinearDimensionSetCount(self._linear_dimension, value):
            raise RMNError("Failed to set count")

    @property
    def coordinates(self) -> np.ndarray:
        """Get linear coordinates."""
        # For linear dimensions, coordinates are calculated from count and increment
        # Get both from C API
        if self._c_dimension != NULL:
            count = SILinearDimensionGetCount(self._linear_dimension)
            increment_ref = SILinearDimensionGetIncrement(self._linear_dimension)

            if increment_ref != NULL:
                # Extract increment value directly without creating Scalar wrapper to avoid memory issues
                increment_val = SIScalarDoubleValue(increment_ref)
                coords = np.arange(count, dtype=np.float64) * increment_val

                # Add coordinates offset if present - coordinates_offset property returns float directly
                try:
                    offset_val = self.coordinates_offset
                    if offset_val is not None and offset_val != 0.0:
                        coords += offset_val
                except:
                    pass

                return coords

        return np.array([])

    @property
    def coords(self) -> np.ndarray:
        """Alias for coordinates."""
        return self.coordinates

    @property
    def complex_fft(self):
        """Get complex FFT flag."""
        return SILinearDimensionGetComplexFFT(self._linear_dimension)

    @complex_fft.setter
    def complex_fft(self, value):
        """Set complex FFT flag."""
        # Update C dimension object only
        if not SILinearDimensionSetComplexFFT(self._linear_dimension, bool(value)):
            raise RMNError("Failed to set complex FFT flag")

    cdef object _create_dimension_wrapper_from_ref(self, SIDimensionRef dim_ref):
        """Create a Python dimension wrapper from a C SIDimensionRef."""
        if dim_ref == NULL:
            return None

        # Get the type of the dimension to determine which wrapper to create
        cdef OCStringRef type_ref = DimensionGetType(<DimensionRef>dim_ref)
        if type_ref == NULL:
            return None

        type_str = ocstring_to_pystring(<uint64_t>type_ref)

        if type_str == "linear":
            # Create SILinearDimension wrapper
            wrapper = SILinearDimension.__new__(SILinearDimension)
            (<SILinearDimension>wrapper)._linear_dimension = <SILinearDimensionRef>dim_ref
            (<SILinearDimension>wrapper)._si_dimension = dim_ref
            (<SILinearDimension>wrapper)._c_dimension = <DimensionRef>dim_ref
            OCRetain(<OCTypeRef>dim_ref)  # Retain the reference
            return wrapper
        elif type_str == "monotonic":
            # Create SIMonotonicDimension wrapper
            wrapper = SIMonotonicDimension.__new__(SIMonotonicDimension)
            (<SIMonotonicDimension>wrapper)._monotonic_dimension = <SIMonotonicDimensionRef>dim_ref
            (<SIMonotonicDimension>wrapper)._si_dimension = dim_ref
            (<SIMonotonicDimension>wrapper)._c_dimension = <DimensionRef>dim_ref
            OCRetain(<OCTypeRef>dim_ref)  # Retain the reference
            return wrapper
        else:
            # Generic SIDimension wrapper for unknown types
            wrapper = SIDimension.__new__(SIDimension)
            (<SIDimension>wrapper)._si_dimension = dim_ref
            (<SIDimension>wrapper)._c_dimension = <DimensionRef>dim_ref
            OCRetain(<OCTypeRef>dim_ref)  # Retain the reference
            return wrapper

    @property
    def reciprocal(self):
        """Get reciprocal dimension."""
        if self._reciprocal is not None:
            return self._reciprocal

        # Try to get from C API if we don't have a cached value
        if self._c_dimension != NULL:
            reciprocal_ref = SILinearDimensionGetReciprocal(self._linear_dimension)
            if reciprocal_ref != NULL:
                # Create and cache the wrapper
                self._reciprocal = self._create_dimension_wrapper_from_ref(reciprocal_ref)
                return self._reciprocal
        return None

    @reciprocal.setter
    def reciprocal(self, value):
        """Set reciprocal dimension."""
        cdef OCStringRef error = NULL
        cdef SIDimensionRef reciprocal_ref = NULL

        # Clear cache since we're setting a new value
        self._reciprocal = None

        # Update C dimension object
        if value is not None:
            if hasattr(value, '_si_dimension'):
                reciprocal_ref = (<SIDimension>value)._si_dimension
            else:
                reciprocal_ref = NULL

        if not SILinearDimensionSetReciprocal(self._linear_dimension, reciprocal_ref, &error):
            if error != NULL:
                error_msg = ocstring_to_pystring(<uint64_t>error)
                OCRelease(<OCTypeRef>error)
                raise RMNError(f"Failed to set reciprocal dimension: {error_msg}")
            else:
                raise RMNError("Failed to set reciprocal dimension")

    def reciprocal_increment(self):
        """Get reciprocal increment."""
        if self._c_dimension != NULL:
            reciprocal_increment_ref = SILinearDimensionGetReciprocalIncrement(self._linear_dimension)
            if reciprocal_increment_ref != NULL:
                # Create Scalar wrapper from the C SIScalarRef using _from_ref
                return Scalar._from_ref(reciprocal_increment_ref)
        return None

    def copy(self):
        """Create a copy of the dimension."""
        return SILinearDimension(
            count=self.count,
            increment=self.increment,  # This returns a Scalar object now
            label=self.label,
            description=self.description,
            application=self.application,
            complex_fft=self.complex_fft
        )

cdef class SIMonotonicDimension(SIDimension):
    """
    Monotonic dimension with arbitrary coordinate spacing.

    Used for dimensions where coordinates are not evenly spaced
    but maintain a monotonic (increasing or decreasing) order.

    Examples:
        >>> dim = SIMonotonicDimension({'coordinates': [1.0, 2.5, 4.0, 7.0]})
        >>> dim.coordinates
        array([1. , 2.5, 4. , 7. ])
        >>> dim.count
        4
    """
    cdef SIMonotonicDimensionRef _monotonic_dimension

    def __init__(self, coordinates, label=None, description=None, application=None,
                 quantity_name=None, offset=None, origin=None, period=None,
                 periodic=False, scaling=0, reciprocal=None, origin_offset=None, **kwargs):
        """Initialize monotonic dimension with coordinates."""

        # Convert coordinates to OCArray of SIScalars (raises on bad input)
        cdef OCStringRef error = NULL
        cdef OCArrayRef coords_array = <OCArrayRef><uint64_t>py_list_to_siscalar_ocarray(coordinates, "1")
        cdef OCStringRef label_ref = <OCStringRef><uint64_t>pystring_to_ocstring(label)
        cdef OCStringRef desc_ref = <OCStringRef><uint64_t>pystring_to_ocstring(description)

        # Handle origin_offset alias
        if origin_offset is not None:
            origin = origin_offset

        try:
            # Create dimension - let C API handle all validation
            self._monotonic_dimension = SIMonotonicDimensionCreate(
                label_ref, desc_ref, NULL, NULL,
                NULL, NULL, NULL,
                periodic, scaling,
                coords_array, NULL, &error)
            if self._monotonic_dimension == NULL:
                if error != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>error)
                    raise RMNError(f"Failed to create monotonic dimension: {error_msg}")
                else:
                    raise RMNError("Failed to create monotonic dimension")
            # Cast to base dimension reference
            self._c_dimension = <DimensionRef>self._monotonic_dimension
            # Set the SIDimension reference for inherited properties
            self._si_dimension = <SIDimensionRef>self._monotonic_dimension

            # Set origin offset after creation if provided
            if origin is not None:
                self.origin_offset = origin
        finally:
            OCRelease(<OCTypeRef>label_ref)
            OCRelease(<OCTypeRef>desc_ref)
            OCRelease(<OCTypeRef>coords_array)
            if error != NULL:
                OCRelease(<OCTypeRef>error)

    @property
    def type(self):
        """Get the type of the dimension."""
        return 'monotonic'

    @property
    def count(self):
        """Get the count of the dimension."""
        if self._c_dimension != NULL:
            coords_ref = SIMonotonicDimensionGetCoordinates(self._monotonic_dimension)
            if coords_ref != NULL:
                return OCArrayGetCount(coords_ref)
        return 0

    @count.setter
    def count(self, value):
        """Set the count by truncating coordinates."""
        current_coords = self.coordinates
        if value > len(current_coords):
            raise ValueError(f"Cannot set count to {value}, only have {len(current_coords)} coordinates")
        # Truncate coordinates to the specified count
        self.coordinates = current_coords[:value]

    @property
    def coordinates(self) -> np.ndarray:
        """Get monotonic coordinates."""
        if self._c_dimension != NULL:
            coords_ref = SIMonotonicDimensionGetCoordinates(self._monotonic_dimension)
            if coords_ref != NULL:
                coords_list = ocarray_to_pylist(<uint64_t>coords_ref)
                if coords_list:
                    return np.array(coords_list, dtype=np.float64)
        return np.array([])

    @coordinates.setter
    def coordinates(self, value):
        """Set new coordinates for the dimension."""
        # This would require recreating the dimension since coordinates are fundamental
        # For now, raise AttributeError to match test expectations
        raise AttributeError("attribute 'coordinates' of 'rmnpy.wrappers.rmnlib.dimension.SIMonotonicDimension' objects is not writable")

    @property
    def coords(self) -> np.ndarray:
        """Alias for coordinates."""
        return self.coordinates

    def copy(self):
        """Create a copy of the dimension."""
        return SIMonotonicDimension(coordinates=self.coordinates.tolist())

    @property
    def reciprocal(self):
        """Get reciprocal dimension."""
        # Monotonic dimensions don't typically have reciprocals
        return None

    @reciprocal.setter
    def reciprocal(self, value):
        """Set reciprocal dimension."""
        # For monotonic dimensions, this is typically not supported
        pass

    # Override linear-only properties to raise AttributeError
    @property
    def coordinates_offset(self):
        """Monotonic dimensions don't have coordinates_offset."""
        raise AttributeError("'SIMonotonicDimension' object has no attribute 'coordinates_offset'")

    @coordinates_offset.setter
    def coordinates_offset(self, value):
        """Monotonic dimensions don't have coordinates_offset."""
        raise AttributeError("'SIMonotonicDimension' object has no attribute 'coordinates_offset'")

    @property
    def increment(self):
        """Monotonic dimensions don't have increment."""
        raise AttributeError("'SIMonotonicDimension' object has no attribute 'increment'")

    @increment.setter
    def increment(self, value):
        """Monotonic dimensions don't have increment."""
        raise AttributeError("'SIMonotonicDimension' object has no attribute 'increment'")

    @property
    def complex_fft(self):
        """Monotonic dimensions don't have complex_fft."""
        raise AttributeError("'SIMonotonicDimension' object has no attribute 'complex_fft'")

    @complex_fft.setter
    def complex_fft(self, value):
        """Monotonic dimensions don't have complex_fft."""
        raise AttributeError("'SIMonotonicDimension' object has no attribute 'complex_fft'")

    def to_dict(self):
        """Convert to dictionary."""
        return {
            'type': 'monotonic',
            'count': self.count,
            'coordinates': self.coordinates.tolist()
        }
