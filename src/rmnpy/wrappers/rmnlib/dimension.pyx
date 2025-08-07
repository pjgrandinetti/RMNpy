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
    ocarray_to_py_list,
    ocdictionary_to_py_dict,
    ocnumber_to_py_number,
    ocstring_to_py_string,
    parse_c_string,
    py_dict_to_ocdictionary,
    py_list_to_ocarray,
    py_list_to_siscalar_ocarray,
    py_number_to_ocnumber,
    py_scalar_to_siscalar,
    py_string_to_ocstring,
)


cdef class BaseDimension:
    """
    Abstract base class for all dimensions.

    Provides common functionality shared across all dimension types:
    - Memory management for C dimension objects
    - Common properties: type, description, label, count, application
    - Utility methods: to_dict(), dict(), is_quantitative(), __repr__()
    """
    cdef DimensionRef _c_dimension
    cdef object _description
    cdef object _label
    cdef object _application

    def __cinit__(self):
        """Initialize C-level attributes."""
        self._c_dimension = NULL
        self._application = None

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
                return parse_c_string(<uint64_t>type_ref)
        # Fallback for subclasses that override this property
        raise NotImplementedError("Subclasses must implement type property")

    @property
    def description(self):
        """Get the description of the dimension."""
        cdef OCStringRef desc_ref
        cdef const char* c_string

        if self._c_dimension != NULL:
            desc_ref = DimensionGetDescription(self._c_dimension)
            if desc_ref != NULL:
                c_string = OCStringGetCString(desc_ref)
                if c_string != NULL:
                    return c_string.decode('utf-8')
        return self._description or ''

    @description.setter
    def description(self, value):
        """Set the description of the dimension."""
        cdef OCStringRef error = NULL
        cdef uint64_t desc_ptr

        if not isinstance(value, str):
            raise TypeError("Description must be a string")
        self._description = value

        # If we have a C dimension object, update it too
        if self._c_dimension != NULL:
            desc_ptr = py_string_to_ocstring(value)
            try:
                if not DimensionSetDescription(self._c_dimension, <OCStringRef>desc_ptr, &error):
                    if error != NULL:
                        error_msg = parse_c_string(<uint64_t>error)
                        OCRelease(<OCTypeRef>error)
                        raise RMNError(f"Failed to set description: {error_msg}")
                    else:
                        raise RMNError("Failed to set description")
            finally:
                OCRelease(<OCTypeRef>desc_ptr)

    @property
    def label(self):
        """Get the label of the dimension."""
        cdef OCStringRef label_ref
        cdef const char* c_string

        if self._c_dimension != NULL:
            label_ref = DimensionGetLabel(self._c_dimension)
            if label_ref != NULL:
                c_string = OCStringGetCString(label_ref)
                if c_string != NULL:
                    return c_string.decode('utf-8')
        return self._label or ''

    @label.setter
    def label(self, value):
        """Set the label of the dimension."""
        cdef OCStringRef error = NULL
        cdef uint64_t label_ptr

        if not isinstance(value, str):
            raise TypeError("Label must be a string")
        self._label = value

        # If we have a C dimension object, update it too
        if self._c_dimension != NULL:
            label_ptr = py_string_to_ocstring(value)
            try:
                if not DimensionSetLabel(self._c_dimension, <OCStringRef>label_ptr, &error):
                    if error != NULL:
                        error_msg = parse_c_string(<uint64_t>error)
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
        cdef OCDictionaryRef metadata_ref

        if self._c_dimension != NULL:
            # Get metadata dictionary from C API
            metadata_ref = DimensionGetApplicationMetaData(self._c_dimension)
            if metadata_ref != NULL:
                return ocdictionary_to_py_dict(<uint64_t>metadata_ref)
            return {}
        return self._application or {}

    @application.setter
    def application(self, value):
        """Set application metadata."""
        cdef OCStringRef error = NULL
        cdef uint64_t dict_ptr

        if value is not None and not isinstance(value, dict):
            raise TypeError("Application metadata must be a dictionary or None")

        self._application = value

        # If we have a C dimension object, update it too
        if self._c_dimension != NULL:
            if value is None or len(value) == 0:
                # Set empty metadata (NULL)
                if not DimensionSetApplicationMetaData(self._c_dimension, NULL, &error):
                    if error != NULL:
                        error_msg = parse_c_string(<uint64_t>error)
                        OCRelease(<OCTypeRef>error)
                        raise RMNError(f"Failed to clear metadata: {error_msg}")
                    else:
                        raise RMNError("Failed to clear metadata")
            else:
                # Convert Python dict to OCDictionary and set
                dict_ptr = py_dict_to_ocdictionary(value)
                try:
                    if not DimensionSetApplicationMetaData(self._c_dimension, <OCDictionaryRef>dict_ptr, &error):
                        if error != NULL:
                            error_msg = parse_c_string(<uint64_t>error)
                            OCRelease(<OCTypeRef>error)
                            raise RMNError(f"Failed to set metadata: {error_msg}")
                        else:
                            raise RMNError("Failed to set metadata")
                finally:
                    OCRelease(<OCTypeRef>dict_ptr)
        else:
            self._application = value

    def is_quantitative(self):
        """Check if dimension is quantitative (not labeled)."""
        return self.type != "labeled"

    def to_dict(self):
        """Convert to dictionary."""
        # Use C API if we have a real dimension object
        if self._c_dimension != NULL:
            dict_ref = DimensionCopyAsDictionary(self._c_dimension)
            if dict_ref != NULL:
                try:
                    # Convert C dictionary to Python dict using helper
                    return ocdictionary_to_py_dict(<uint64_t>dict_ref)
                finally:
                    OCRelease(dict_ref)

        # Fallback: manual dictionary creation (for placeholder phase)
        result = {
            'type': self.type,
            'count': self.count,
        }
        if self.description:
            result['description'] = self.description
        if self.label:
            result['label'] = self.label
        return result

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
        # Validate labels
        if not labels:
            raise RMNError("Labeled dimension requires labels")

        # Don't store duplicate data - C object will be single source of truth
        self._description = description
        self._label = label

        # Set application metadata if provided
        if application is not None:
            self._application = application

        # Create C dimension using the C API
        cdef OCArrayRef labels_array = NULL
        cdef OCStringRef label_ref = NULL
        cdef OCStringRef desc_ref = NULL
        cdef OCDictionaryRef metadata_ref = NULL
        cdef OCStringRef error = NULL

        try:
            # Convert Python string labels to OCStringRef array
            if labels:
                labels_array = <OCArrayRef><uintptr_t>py_list_to_ocarray(labels)
                if labels_array == NULL:
                    raise RMNError("Failed to create labels array")

            # Prepare label and description - only if provided (not None and not empty)
            if label is not None and label != "":
                label_ref = OCStringCreateWithCString(label.encode('utf-8'))
            if description is not None and description != "":
                desc_ref = OCStringCreateWithCString(description.encode('utf-8'))

            # Convert application metadata to OCDictionary if provided
            if self._application is not None:
                metadata_ref = <OCDictionaryRef><uintptr_t>py_dict_to_ocdictionary(self._application)

            # Create the labeled dimension using the actual C API signature
            self._labeled_dimension = LabeledDimensionCreate(
                label_ref, desc_ref, metadata_ref, labels_array, &error)

            if self._labeled_dimension == NULL:
                if error != NULL:
                    error_msg = parse_c_string(<uint64_t>error)
                    raise RMNError(f"Failed to create labeled dimension: {error_msg}")
                else:
                    raise RMNError("Failed to create labeled dimension")

            # Cast to base dimension reference
            self._c_dimension = <DimensionRef>self._labeled_dimension

        finally:
            if label_ref != NULL:
                OCRelease(<OCTypeRef>label_ref)
            if desc_ref != NULL:
                OCRelease(<OCTypeRef>desc_ref)
            if metadata_ref != NULL:
                OCRelease(<OCTypeRef>metadata_ref)
            if labels_array != NULL:
                OCRelease(<OCTypeRef>labels_array)
            if error != NULL:
                OCRelease(<OCTypeRef>error)

    @property
    def type(self):
        """Get the type of the dimension."""
        if self._c_dimension != NULL:
            type_ref = DimensionGetType(self._c_dimension)
            if type_ref != NULL:
                return parse_c_string(<uint64_t>type_ref)
        return 'labeled'  # Fallback

    @property
    def coordinates(self) -> np.ndarray:
        """Get coordinates (labels) for this dimension."""
        if self._c_dimension != NULL:
            labels_ref = LabeledDimensionGetCoordinateLabels(self._labeled_dimension)
            if labels_ref != NULL:
                # Use helper function to convert OCArray to Python list
                labels_list = ocarray_to_py_list(<uint64_t>labels_ref)
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
        cdef OCArrayRef labels_array = NULL

        # Update internal value
        self._input_labels = value

        # If we have a C dimension object, update it too
        if self._c_dimension != NULL:
            try:
                # Convert Python string labels to OCStringRef array
                labels_array = <OCArrayRef><uintptr_t>py_list_to_ocarray(value)
                if labels_array == NULL:
                    raise RMNError("Failed to create labels array")

                if not LabeledDimensionSetCoordinateLabels(self._labeled_dimension, labels_array, &error):
                    if error != NULL:
                        error_msg = parse_c_string(<uint64_t>error)
                        OCRelease(<OCTypeRef>error)
                        raise RMNError(f"Failed to set coordinate labels: {error_msg}")
                    else:
                        raise RMNError("Failed to set coordinate labels")
            finally:
                if labels_array != NULL:
                    OCRelease(<OCTypeRef>labels_array)

    def set_coordinate_label_at_index(self, index, label):
        """Set coordinate label at specific index."""
        cdef OCStringRef error = NULL
        cdef OCStringRef label_ref = NULL

        # Update internal value
        if 0 <= index < len(self._input_labels):
            self._input_labels[index] = label
        else:
            raise IndexError(f"Label index {index} out of range")

        # If we have a C dimension object, update it too
        if self._c_dimension != NULL:
            try:
                label_ref = OCStringCreateWithCString(str(label).encode('utf-8'))
                if not LabeledDimensionSetCoordinateLabelAtIndex(self._labeled_dimension, index, label_ref):
                    raise RMNError(f"Failed to set coordinate label at index {index}")
            finally:
                if label_ref != NULL:
                    OCRelease(<OCTypeRef>label_ref)

    @property
    def count(self):
        """Get the count of the dimension."""
        # Try to use C API first if we have a C object
        if self._c_dimension != NULL:
            return DimensionGetCount(self._c_dimension)
        return len(self._input_labels)

    def copy(self):
        """Create a copy of the dimension."""
        return LabeledDimension(
            labels=list(self._input_labels),
            label=self.label,
            description=self.description,
            application=self.application
        )

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
        # Don't store duplicate data - C object will be the single source of truth
        self._description = description
        self._label = label

        # Set application metadata if provided
        if application is not None:
            self._application = application

        # Create C dimension using the C API
        cdef OCStringRef label_ref = NULL
        cdef OCStringRef desc_ref = NULL
        cdef OCDictionaryRef metadata_ref = NULL
        cdef OCStringRef quantity_name_ref = NULL
        cdef SIScalarRef offset_ref = NULL
        cdef SIScalarRef origin_ref = NULL
        cdef SIScalarRef period_ref = NULL
        cdef OCStringRef error = NULL
        cdef object offset_scalar = None
        cdef object origin_scalar = None
        cdef object period_scalar = None

        try:
            # Prepare label and description - only if provided (not None and not empty)
            if label is not None and label != "":
                label_ref = OCStringCreateWithCString(label.encode('utf-8'))
            if description is not None and description != "":
                desc_ref = OCStringCreateWithCString(description.encode('utf-8'))

            # Convert application metadata if provided
            if self._application is not None:
                metadata_ref = <OCDictionaryRef><uintptr_t>py_dict_to_ocdictionary(self._application)

            # Handle quantity name - only if provided
            if quantity_name is not None:
                quantity_name_ref = OCStringCreateWithCString(quantity_name.encode('utf-8'))

            # Convert offset, origin, period to SIScalars if provided

            if offset is not None:
                if isinstance(offset, str):
                    offset_scalar = Scalar(offset)
                elif isinstance(offset, Scalar):
                    offset_scalar = offset
                else:
                    offset_scalar = Scalar(str(offset))
                offset_ref = (<Scalar>offset_scalar).get_c_scalar()

            if origin is not None:
                if isinstance(origin, str):
                    origin_scalar = Scalar(origin)
                elif isinstance(origin, Scalar):
                    origin_scalar = origin
                else:
                    origin_scalar = Scalar(str(origin))
                origin_ref = (<Scalar>origin_scalar).get_c_scalar()

            if period is not None:
                if isinstance(period, str):
                    period_scalar = Scalar(period)
                elif isinstance(period, Scalar):
                    period_scalar = period
                else:
                    period_scalar = Scalar(str(period))
                period_ref = (<Scalar>period_scalar).get_c_scalar()

            # Create the SI dimension using the C API with correct signature
            self._si_dimension = SIDimensionCreate(
                label_ref, desc_ref, metadata_ref, quantity_name_ref,
                offset_ref, origin_ref, period_ref, periodic, scaling, &error)

            if self._si_dimension == NULL:
                if error != NULL:
                    error_msg = parse_c_string(<uint64_t>error)
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
            if metadata_ref != NULL:
                OCRelease(<OCTypeRef>metadata_ref)
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
                return parse_c_string(<uint64_t>type_ref)
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
        if self._c_dimension != NULL:
            offset_ref = SIDimensionGetCoordinatesOffset(self._si_dimension)
            if offset_ref != NULL:
                return Scalar._from_ref(offset_ref)
        return None

    @coordinates_offset.setter
    def coordinates_offset(self, value):
        """Set coordinates offset."""
        cdef OCStringRef error = NULL

        # Convert value to SIScalarRef and update C dimension object
        offset_scalar = Scalar(str(value))
        if not SIDimensionSetCoordinatesOffset(self._si_dimension, (<Scalar>offset_scalar).get_c_scalar(), &error):
            if error != NULL:
                error_msg = parse_c_string(<uint64_t>error)
                OCRelease(<OCTypeRef>error)
                raise RMNError(f"Failed to set coordinates offset: {error_msg}")
            else:
                raise RMNError("Failed to set coordinates offset")

    @property
    def origin_offset(self):
        """Get origin offset."""
        if self._c_dimension != NULL:
            origin_ref = SIDimensionGetOriginOffset(self._si_dimension)
            if origin_ref != NULL:
                return Scalar._from_ref(origin_ref)
        return None

    @origin_offset.setter
    def origin_offset(self, value):
        """Set origin offset."""
        cdef OCStringRef error = NULL

        # Convert value to SIScalarRef and update C dimension object
        origin_scalar = Scalar(str(value))
        if not SIDimensionSetOriginOffset(self._si_dimension, (<Scalar>origin_scalar).get_c_scalar(), &error):
            if error != NULL:
                error_msg = parse_c_string(<uint64_t>error)
                OCRelease(<OCTypeRef>error)
                raise RMNError(f"Failed to set origin offset: {error_msg}")
            else:
                raise RMNError("Failed to set origin offset")

    @property
    def period(self):
        """Get the period."""
        if self._c_dimension != NULL:
            period_ref = SIDimensionGetPeriod(self._si_dimension)
            if period_ref != NULL:
                return Scalar._from_ref(period_ref)
        return None

    @period.setter
    def period(self, value):
        """Set the period."""
        cdef OCStringRef error = NULL

        # Update the C dimension object
        if value is not None:
            # Convert value to SIScalarRef
            period_scalar = Scalar(str(value))
            if not SIDimensionSetPeriod(self._si_dimension, (<Scalar>period_scalar).get_c_scalar(), &error):
                if error != NULL:
                    error_msg = parse_c_string(<uint64_t>error)
                    OCRelease(<OCTypeRef>error)
                    raise RMNError(f"Failed to set period: {error_msg}")
                else:
                    raise RMNError("Failed to set period")
        else:
            # Set NULL period for infinite period
            if not SIDimensionSetPeriod(self._si_dimension, NULL, &error):
                if error != NULL:
                    error_msg = parse_c_string(<uint64_t>error)
                    OCRelease(<OCTypeRef>error)
                    raise RMNError(f"Failed to clear period: {error_msg}")
                else:
                    raise RMNError("Failed to clear period")

    @property
    def absolute_coordinates(self) -> np.ndarray:
        """Get absolute coordinates along the dimension."""
        coords = self.coordinates
        return coords + self.origin_offset

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
        return "frequency"  # Default placeholder

    @quantity_name.setter
    def quantity_name(self, value):
        """Set quantity name for physical quantities."""
        cdef OCStringRef error = NULL
        cdef OCStringRef quantity_name_ref = NULL

        # If we have a C dimension object, update it too
        if self._c_dimension != NULL:
            if value is not None and value != "":
                quantity_name_ref = OCStringCreateWithCString(str(value).encode('utf-8'))
                try:
                    if not SIDimensionSetQuantityName(self._si_dimension, quantity_name_ref, &error):
                        if error != NULL:
                            error_msg = parse_c_string(<uint64_t>error)
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
                        error_msg = parse_c_string(<uint64_t>error)
                        OCRelease(<OCTypeRef>error)
                        raise RMNError(f"Failed to clear quantity name: {error_msg}")
                    else:
                        raise RMNError("Failed to clear quantity name")

    @property
    def periodic(self):
        """Get periodic flag."""
        # TODO: Add C API getter once available
        return False  # Default placeholder

    @periodic.setter
    def periodic(self, value):
        """Set periodic flag."""
        cdef OCStringRef error = NULL

        # If we have a C dimension object, update it too
        if self._c_dimension != NULL:
            if not SIDimensionSetPeriodic(self._si_dimension, bool(value), &error):
                if error != NULL:
                    error_msg = parse_c_string(<uint64_t>error)
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

    def __init__(self, count, increment, label=None, description=None,
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
        # Don't store duplicate data - C object will be the single source of truth
        # Only store what's needed during initialization
        self._description = description
        self._label = label

        # Set application metadata if provided
        if application is not None:
            self._application = application

        # Create C dimension using the C API
        cdef OCStringRef error = NULL
        cdef OCStringRef label_ref = NULL
        cdef OCStringRef desc_ref = NULL
        cdef OCStringRef quantity_name_ref = NULL
        cdef OCDictionaryRef metadata_ref = NULL
        cdef SIScalarRef increment_ref = NULL
        cdef SIScalarRef offset_ref = NULL
        cdef const char* c_expr
        cdef OCStringRef expr_ref
        cdef SIScalarRef origin_ref = NULL
        cdef SIScalarRef period_ref = NULL
        cdef SIDimensionRef reciprocal_ref = NULL
        cdef object offset_scalar = None
        cdef object origin_scalar = None
        cdef object period_scalar = None
        cdef OCTypeID scalar_type_id, actual_type_id
        cdef bint is_complex

        try:
            # Convert increment to SIScalarRef (required parameter)
            if increment is not None:
                if isinstance(increment, str):
                    # Create the SIScalarRef directly in this module
                    increment_str = increment
                    increment_bytes = increment_str.encode('utf-8')
                    c_expr = increment_bytes
                    expr_ref = OCStringCreateWithCString(c_expr)
                    increment_ref = SIScalarCreateFromExpression(expr_ref, &error)
                elif isinstance(increment, Scalar):
                    # For existing Scalar objects, recreate from expression
                    scalar_value = increment.value
                    scalar_unit = str(increment.unit) if hasattr(increment, 'unit') else "1"
                    scalar_expr = f"{scalar_value} {scalar_unit}"
                    scalar_bytes = scalar_expr.encode('utf-8')
                    c_expr = scalar_bytes
                    expr_ref = OCStringCreateWithCString(c_expr)
                    increment_ref = SIScalarCreateFromExpression(expr_ref, &error)
                else:
                    # For numeric values, create directly
                    scalar_expr = str(increment)
                    scalar_bytes = scalar_expr.encode('utf-8')
                    c_expr = scalar_bytes
                    expr_ref = OCStringCreateWithCString(c_expr)
                    increment_ref = SIScalarCreateFromExpression(expr_ref, &error)

                # Validate the created reference
                if increment_ref == NULL:
                    raise RMNError(f"Failed to create increment SIScalarRef from: {increment}")

                # Verify it's a valid SIScalar (not complex)
                if SIQuantityIsComplexType(<SIQuantityRef>increment_ref):
                    raise RMNError(f"increment must be a real (not complex) SIScalar, got complex value")
            else:
                raise RMNError("increment parameter is required")

            # Convert optional string parameters - only if provided (not None and not empty)
            if label is not None and label != "":
                label_ref = OCStringCreateWithCString(label.encode('utf-8'))
            if description is not None and description != "":
                desc_ref = OCStringCreateWithCString(description.encode('utf-8'))

            # Handle quantity name - only if provided
            if quantity_name is not None:
                quantity_name_ref = OCStringCreateWithCString(quantity_name.encode('utf-8'))

            # Convert application metadata - only if provided
            if application is not None:
                metadata_ref = <OCDictionaryRef><uintptr_t>py_dict_to_ocdictionary(application)

            # Convert offset, origin, period to SIScalars if provided

            if offset is not None:
                if isinstance(offset, str):
                    offset_scalar = Scalar(offset)
                elif isinstance(offset, Scalar):
                    offset_scalar = offset
                else:
                    offset_scalar = Scalar(str(offset))
                offset_ref = (<Scalar>offset_scalar).get_c_scalar()

            if origin is not None:
                if isinstance(origin, str):
                    origin_scalar = Scalar(origin)
                elif isinstance(origin, Scalar):
                    origin_scalar = origin
                else:
                    origin_scalar = Scalar(str(origin))
                origin_ref = (<Scalar>origin_scalar).get_c_scalar()

            if period is not None:
                if isinstance(period, str):
                    period_scalar = Scalar(period)
                elif isinstance(period, Scalar):
                    period_scalar = period
                else:
                    period_scalar = Scalar(str(period))
                period_ref = (<Scalar>period_scalar).get_c_scalar()

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
                metadata_ref,           # metadata
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
                    error_msg = parse_c_string(<uint64_t>error)
                    raise RMNError(f"Failed to create linear dimension: {error_msg}")
                else:
                    raise RMNError("Failed to create linear dimension")

            # Cast to base dimension reference
            self._c_dimension = <DimensionRef>self._linear_dimension

        finally:
            if label_ref != NULL:
                OCRelease(<OCTypeRef>label_ref)
            if desc_ref != NULL:
                OCRelease(<OCTypeRef>desc_ref)
            if quantity_name_ref != NULL:
                OCRelease(<OCTypeRef>quantity_name_ref)
            if metadata_ref != NULL:
                OCRelease(<OCTypeRef>metadata_ref)
            if error != NULL:
                OCRelease(<OCTypeRef>error)

    @property
    def type(self):
        """Get the type of the dimension."""
        if self._c_dimension != NULL:
            type_ref = DimensionGetType(self._c_dimension)
            if type_ref != NULL:
                return parse_c_string(<uint64_t>type_ref)
        return 'linear'  # Fallback

    @property
    def increment(self):
        """Get the increment of the dimension."""
        if self._c_dimension != NULL:
            increment_ref = SILinearDimensionGetIncrement(self._linear_dimension)
            if increment_ref != NULL:
                # TODO: Convert SIScalarRef to Python float
                # For now, return the Scalar wrapper
                return Scalar._from_ref(increment_ref)
        return None

    @increment.setter
    def increment(self, value):
        """Set the increment of the dimension."""
        # Convert value to SIScalarRef and update C dimension object
        increment_scalar = Scalar(str(value))
        if not SILinearDimensionSetIncrement(self._linear_dimension, (<Scalar>increment_scalar).get_c_scalar()):
            raise RMNError("Failed to set increment")

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
                # TODO: Convert SIScalarRef increment to Python float properly
                # For now, create a Scalar wrapper and extract the value
                increment_scalar = Scalar._from_ref(increment_ref)
                increment_val = float(increment_scalar.value)
                return np.arange(count, dtype=np.float64) * increment_val

        return np.array([])

    @property
    def coords(self) -> np.ndarray:
        """Alias for coordinates."""
        return self.coordinates

    @property
    def complex_fft(self):
        """Get complex FFT flag."""
        # TODO: Add C API getter once available
        # For now, there's no C API getter for this
        return False  # Default

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

        type_str = parse_c_string(<uint64_t>type_ref)

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
                error_msg = parse_c_string(<uint64_t>error)
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
                 periodic=False, scaling=0, reciprocal=None, **kwargs):
        """Initialize monotonic dimension with coordinates."""

        # Convert coordinates to C array - must be SIScalars
        cdef OCArrayRef coords_array = NULL
        cdef OCStringRef label_ref = NULL
        cdef OCStringRef desc_ref = NULL
        cdef OCStringRef error = NULL

        try:
            coords_array = <OCArrayRef><uintptr_t>py_list_to_siscalar_ocarray(coordinates, "1")
            if coords_array == NULL:
                raise RMNError("Failed to convert coordinates to SIScalar array")
        except Exception as e:
            raise RMNError(f"Error converting coordinates: {e}")

        try:
            # Prepare optional parameters if provided
            if label is not None and label != "":
                label_ref = OCStringCreateWithCString(label.encode('utf-8'))
            if description is not None and description != "":
                desc_ref = OCStringCreateWithCString(description.encode('utf-8'))

            # Create dimension - let C API handle all validation
            self._monotonic_dimension = SIMonotonicDimensionCreate(
                label_ref, desc_ref, NULL, NULL,  # label, description, metadata, quantity_name
                NULL, NULL, NULL,                 # offset, origin, period
                periodic, scaling,                # periodic, scaling
                coords_array, NULL, &error)       # coordinates, reciprocal, error

            if self._monotonic_dimension == NULL:
                if error != NULL:
                    error_msg = parse_c_string(<uint64_t>error)
                    raise RMNError(f"Failed to create monotonic dimension: {error_msg}")
                else:
                    raise RMNError("Failed to create monotonic dimension")

            # Cast to base dimension reference
            self._c_dimension = <DimensionRef>self._monotonic_dimension

        finally:
            # Clean up
            if label_ref != NULL:
                OCRelease(<OCTypeRef>label_ref)
            if desc_ref != NULL:
                OCRelease(<OCTypeRef>desc_ref)
            if coords_array != NULL:
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

    @property
    def coordinates(self) -> np.ndarray:
        """Get monotonic coordinates."""
        if self._c_dimension != NULL:
            coords_ref = SIMonotonicDimensionGetCoordinates(self._monotonic_dimension)
            if coords_ref != NULL:
                coords_list = ocarray_to_py_list(<uintptr_t>coords_ref)
                if coords_list:
                    return np.array(coords_list, dtype=np.float64)
        return np.array([])

    @property
    def coords(self) -> np.ndarray:
        """Alias for coordinates."""
        return self.coordinates

    def copy(self):
        """Create a copy of the dimension."""
        return SIMonotonicDimension(coordinates=self.coordinates.tolist())

    def to_dict(self):
        """Convert to dictionary."""
        return {'coordinates': self.coordinates.tolist()}
