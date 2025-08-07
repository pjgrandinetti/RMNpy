# cython: language_level=3
"""
RMNLib Dimension wrapper with proper inheritance hierarchy

This module provides Python wrappers that mirror the C inheritance:
- BaseDimension (abstract base for common functionality)
- LabeledDimension (for discrete labeled coordinates)
- SIDimension (base for quantitative coordinates with SI units)
  - SILinearDimension (for linear coordinates with constant increment)
  - SIMonotonicDimension (for monotonic coordinates with arbitrary spacing)

Factory function Dimension() provides csdmpy-compatible interface.
"""

from typing import Any, Dict, List, Optional, Union

import numpy as np

from rmnpy._c_api.octypes cimport (
    OCArrayCreateWithDoubles,
    OCArrayGetCount,
    OCArrayGetDoubles,
    OCArrayRef,
    OCDictionaryRef,
    OCIndex,
    OCMutableDictionaryRef,
    OCRelease,
    OCStringCreateWithCString,
    OCStringGetCString,
    OCStringRef,
    OCTypeRef,
)
from rmnpy._c_api.rmnlib cimport (
    DimensionCopyAsDictionary,
    DimensionCreateFromDictionary,
    DimensionGetCount,
    DimensionGetDescription,
    DimensionGetLabel,
    DimensionGetMetadata,
    DimensionGetType,
    DimensionRef,
    DimensionSetDescription,
    DimensionSetLabel,
    DimensionSetMetadata,
    LabeledDimensionCreate,
    LabeledDimensionGetCoordinateLabels,
    LabeledDimensionRef,
    SIDimensionCreate,
    SIDimensionRef,
    SILinearDimensionCreate,
    SILinearDimensionGetCoordinateAtIndex,
    SILinearDimensionGetIncrement,
    SILinearDimensionGetStart,
    SILinearDimensionRef,
    SIMonotonicDimensionCreate,
    SIMonotonicDimensionGetCoordinates,
    SIMonotonicDimensionRef,
)
from rmnpy._c_api.sitypes cimport *

# Import OCTypes helper functions
from rmnpy.helpers.octypes cimport ocdictionary_to_py_dict, py_dict_to_ocdictionary


# Factory function for creating appropriate dimension type (csdmpy compatibility)
def Dimension(*args, **kwargs):
    """
    Factory function to create the appropriate dimension type.

    Args:
        *args: Positional arguments (dict or direct arguments)
        **kwargs: Keyword arguments

    Returns:
        Appropriate dimension subclass instance

    Examples:
        >>> dim = Dimension(type='linear', count=5)
        >>> type(dim)
        <class 'SILinearDimension'>

        >>> dim = Dimension(type='labeled', labels=['A', 'B', 'C'])
        >>> type(dim)
        <class 'LabeledDimension'>

        # Dictionary-based (csdmpy compatibility)
        >>> dim = Dimension({'type': 'labeled', 'labels': ['X', 'Y', 'Z']})
        >>> type(dim)
        <class 'LabeledDimension'>
    """
    params = {}

    # Handle first argument as dict (csdmpy compatibility)
    if args and isinstance(args[0], dict):
        params.update(args[0])
    elif args:
        # If first arg is not dict, assume it's a direct argument
        # This would need more logic based on dimension type
        raise ValueError("Direct positional arguments not yet supported. Use type= keyword argument.")

    # Add kwargs
    params.update(kwargs)

    # Get dimension type
    dim_type = params.get('type', 'linear')

    if dim_type == 'labeled':
        # Extract labels for new API
        labels = params.get('labels', [])
        if not labels:
            raise ValueError("Labeled dimension requires 'labels' parameter")
        return LabeledDimension(
            labels=labels,
            label=params.get('label', ''),
            description=params.get('description', ''),
            application=params.get('application')
        )
    elif dim_type == 'si' or dim_type == 'SIDimension':
        return SIDimension(
            label=params.get('label', ''),
            description=params.get('description', ''),
            application=params.get('application'),
            coordinates_offset=params.get('coordinates_offset', '0'),
            origin_offset=params.get('origin_offset', '0'),
            period=params.get('period'),
            complex_fft=params.get('complex_fft', False)
        )
    elif dim_type == 'monotonic':
        coordinates = params.get('coordinates', [])
        if not coordinates:
            raise ValueError("Monotonic dimension requires 'coordinates' parameter")
        return SIMonotonicDimension(
            coordinates=coordinates,
            label=params.get('label', ''),
            description=params.get('description', ''),
            application=params.get('application'),
            coordinates_offset=params.get('coordinates_offset', '0'),
            origin_offset=params.get('origin_offset', '0'),
            period=params.get('period'),
            complex_fft=params.get('complex_fft', False)
        )
    elif dim_type == 'linear':
        return SILinearDimension(
            count=params.get('count', 10),
            increment=params.get('increment', '1.0'),
            label=params.get('label', ''),
            description=params.get('description', ''),
            application=params.get('application'),
            coordinates_offset=params.get('coordinates_offset', '0'),
            origin_offset=params.get('origin_offset', '0'),
            period=params.get('period'),
            complex_fft=params.get('complex_fft', False)
        )
    else:
        raise ValueError(f"Unknown dimension type: {dim_type}")

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
            cdef OCStringRef type_ref = DimensionGetType(self._c_dimension)
            if type_ref != NULL:
                return OCStringGetCString(type_ref).decode('utf-8')
        # Fallback for subclasses that override this property
        raise NotImplementedError("Subclasses must implement type property")

    @property
    def description(self):
        """Get the description of the dimension."""
        if self._c_dimension != NULL:
            cdef OCStringRef desc_ref = DimensionGetDescription(self._c_dimension)
            if desc_ref != NULL:
                return OCStringGetCString(desc_ref).decode('utf-8')
        return self._description or ''

    @description.setter
    def description(self, value):
        """Set the description of the dimension."""
        if not isinstance(value, str):
            raise TypeError("Description must be a string")
        self._description = value

        # If we have a C dimension object, update it too
        if self._c_dimension != NULL:
            cdef OCStringRef desc_ref = OCStringCreateWithCString(value.encode('utf-8'))
            cdef OCStringRef error = NULL
            try:
                if not DimensionSetDescription(self._c_dimension, desc_ref, &error):
                    if error != NULL:
                        error_msg = OCStringGetCString(error).decode('utf-8')
                        raise ValueError(f"Failed to set description: {error_msg}")
                    else:
                        raise ValueError("Failed to set description")
            finally:
                if desc_ref != NULL:
                    OCRelease(desc_ref)
                if error != NULL:
                    OCRelease(error)

    @property
    def label(self):
        """Get the label of the dimension."""
        if self._c_dimension != NULL:
            cdef OCStringRef label_ref = DimensionGetLabel(self._c_dimension)
            if label_ref != NULL:
                return OCStringGetCString(label_ref).decode('utf-8')
        return self._label or ''

    @label.setter
    def label(self, value):
        """Set the label of the dimension."""
        if not isinstance(value, str):
            raise TypeError("Label must be a string")
        self._label = value

        # If we have a C dimension object, update it too
        if self._c_dimension != NULL:
            cdef OCStringRef label_ref = OCStringCreateWithCString(value.encode('utf-8'))
            cdef OCStringRef error = NULL
            try:
                if not DimensionSetLabel(self._c_dimension, label_ref, &error):
                    if error != NULL:
                        error_msg = OCStringGetCString(error).decode('utf-8')
                        raise ValueError(f"Failed to set label: {error_msg}")
                    else:
                        raise ValueError("Failed to set label")
            finally:
                if label_ref != NULL:
                    OCRelease(label_ref)
                if error != NULL:
                    OCRelease(error)

    @property
    def count(self):
        """Get the count of the dimension."""
        if self._c_dimension != NULL:
            return DimensionGetCount(self._c_dimension)
        return 0

    @property
    def application(self):
        """Get application metadata."""
        if self._c_dimension != NULL:
            cdef OCMutableDictionaryRef metadata = DimensionGetMetadata(self._c_dimension)
            if metadata != NULL:
                py_dict = ocdictionary_to_py_dict(<OCDictionaryRef>metadata)
                return py_dict
            return {}
        return self._application

    @application.setter
    def application(self, value):
        """Set application metadata."""
        if value is not None and not isinstance(value, dict):
            raise TypeError("Application metadata must be a dictionary")

        if self._c_dimension != NULL:
            cdef OCDictionaryRef dict_ref = NULL
            cdef OCStringRef error = NULL

            if value is not None:
                dict_ref = py_dict_to_ocdictionary(value)

            if DimensionSetMetadata(self._c_dimension, dict_ref, &error):
                if dict_ref != NULL:
                    OCRelease(<OCTypeRef>dict_ref)
            else:
                if dict_ref != NULL:
                    OCRelease(<OCTypeRef>dict_ref)
                if error != NULL:
                    error_msg = OCStringGetCString(error).decode('utf-8')
                    OCRelease(<OCTypeRef>error)
                    raise RuntimeError(f"Failed to set metadata: {error_msg}")
                else:
                    raise RuntimeError("Failed to set metadata")
        else:
            self._application = value

    def is_quantitative(self):
        """Check if dimension is quantitative (not labeled)."""
        return self.type != "labeled"

    def to_dict(self):
        """Convert to dictionary."""
        # Use C API if we have a real dimension object
        if self._c_dimension != NULL:
            cdef OCDictionaryRef dict_ref = DimensionCopyAsDictionary(self._c_dimension)
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
    cdef object _input_labels

    def __init__(self, labels, label="", description="", application=None, **kwargs):
        """
        Initialize labeled dimension.

        Args:
            labels (list): List of string labels for coordinates
            label (str, optional): Short label for the dimension
            description (str, optional): Description of the dimension
            application (dict, optional): Application metadata
            **kwargs: Additional keyword arguments (for compatibility)

        Examples:
            # Basic labeled dimension
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
            raise ValueError("Labeled dimension requires labels")

        self._input_labels = labels
        self._description = description
        self._label = label

        # Set application metadata if provided
        if application is not None:
            self._application = application

        # Create C dimension using the C API
        cdef OCArrayRef labels_array = NULL
        cdef OCStringRef label_ref = NULL
        cdef OCStringRef desc_ref = NULL
        cdef OCStringRef error = NULL

        try:
            # Convert Python string labels to OCStringRef array
            # TODO: Create proper OCArray of OCStringRef objects from labels
            # For now, labels_array will be NULL, which should create an empty dimension

            # Prepare label and description
            if self._label:
                label_ref = OCStringCreateWithCString(self._label.encode('utf-8'))
            if self._description:
                desc_ref = OCStringCreateWithCString(self._description.encode('utf-8'))

            # Create the labeled dimension using the .pxd signature
            self._labeled_dimension = LabeledDimensionCreate(
                label_ref, desc_ref, labels_array, &error)

            if self._labeled_dimension == NULL:
                if error != NULL:
                    error_msg = OCStringGetCString(error).decode('utf-8')
                    raise RuntimeError(f"Failed to create labeled dimension: {error_msg}")
                else:
                    raise RuntimeError("Failed to create labeled dimension")

            # Cast to base dimension reference
            self._c_dimension = <DimensionRef>self._labeled_dimension

        finally:
            if label_ref != NULL:
                OCRelease(<OCTypeRef>label_ref)
            if desc_ref != NULL:
                OCRelease(<OCTypeRef>desc_ref)
            if labels_array != NULL:
                OCRelease(<OCTypeRef>labels_array)
            if error != NULL:
                OCRelease(<OCTypeRef>error)

    @property
    def type(self):
        """Get the type of the dimension."""
        return 'labeled'

    @property
    def coordinates(self) -> np.ndarray:
        """Get coordinates (labels) for this dimension."""
        return np.array(self._input_labels)

    @property
    def coords(self) -> np.ndarray:
        """Alias for coordinates."""
        return self.coordinates

    @property
    def labels(self):
        """Get labels for labeled dimensions."""
        return self.coordinates

    @property
    def count(self):
        """Get the count of the dimension."""
        return len(self._input_labels)

    def copy(self):
        """Create a copy of the dimension."""
        return LabeledDimension(
            labels=list(self._input_labels),
            label=self.label,
            description=self.description,
            application=self.application
        )

    def copy_metadata(self, obj):
        """
        Copy LabeledDimension metadata.

        Args:
            obj: Object to copy metadata from
        """
        if hasattr(obj, 'label'):
            self.label = obj.label
        if hasattr(obj, 'description'):
            self.description = obj.description
        if hasattr(obj, 'application'):
            self.application = obj.application

cdef class SIDimension(BaseDimension):
    """
    Base class for quantitative dimensions with SI units.

    Provides common functionality for quantitative dimensions including
    coordinate offsets, periods, and unit-aware operations.
    """
    cdef SIDimensionRef _si_dimension
    cdef object _coordinates_offset
    cdef object _origin_offset
    cdef object _period
    cdef object _complex_fft

    def __init__(self, label="", description="", application=None,
                 coordinates_offset='0', origin_offset='0', period=None,
                 complex_fft=False, **kwargs):
        """
        Initialize SI dimension.

        Args:
            label (str, optional): Short label for the dimension
            description (str, optional): Description of the dimension
            application (dict, optional): Application metadata
            coordinates_offset (str, optional): Coordinates offset value
            origin_offset (str, optional): Origin offset value
            period (str, optional): Period value for periodic dimensions
            complex_fft (bool, optional): Complex FFT flag
            **kwargs: Additional keyword arguments (for compatibility)
        """
        # Set quantitative properties
        self._coordinates_offset = coordinates_offset
        self._origin_offset = origin_offset
        self._period = period
        self._complex_fft = complex_fft
        self._description = description
        self._label = label

        # Set application metadata if provided
        if application is not None:
            self._application = application

        # Create C dimension using the C API
        cdef OCStringRef label_ref = NULL
        cdef OCStringRef desc_ref = NULL
        cdef OCMutableDictionaryRef metadata_ref = NULL
        cdef OCStringRef quantity_name_ref = NULL
        cdef SIScalarRef offset_ref = NULL
        cdef SIScalarRef origin_ref = NULL
        cdef SIScalarRef period_ref = NULL
        cdef OCStringRef error = NULL

        try:
            # Prepare label and description
            if self._label:
                label_ref = OCStringCreateWithCString(self._label.encode('utf-8'))
            if self._description:
                desc_ref = OCStringCreateWithCString(self._description.encode('utf-8'))

            # TODO: Handle metadata, quantity_name, offset, origin, period parameters
            # For now using NULL values (will be handled by SIDimensionCreate defaults)

            # Create the SI dimension using the C API
            self._si_dimension = SIDimensionCreate(
                label_ref, desc_ref, metadata_ref, quantity_name_ref,
                offset_ref, origin_ref, period_ref, False, 0, &error)

            if self._si_dimension == NULL:
                if error != NULL:
                    error_msg = OCStringGetCString(error).decode('utf-8')
                    raise RuntimeError(f"Failed to create SI dimension: {error_msg}")
                else:
                    raise RuntimeError("Failed to create SI dimension")

            # Cast to base dimension reference
            self._c_dimension = <DimensionRef>self._si_dimension

        finally:
            if label_ref != NULL:
                OCRelease(<OCTypeRef>label_ref)
            if desc_ref != NULL:
                OCRelease(<OCTypeRef>desc_ref)
            if error != NULL:
                OCRelease(<OCTypeRef>error)

    @property
    def type(self):
        """Get the type of the dimension."""
        return 'si'

    @property
    def count(self):
        """Get the count of the dimension."""
        # SIDimension is abstract - subclasses must implement this
        raise NotImplementedError("SIDimension is abstract - use SILinearDimension or SIMonotonicDimension")

    def copy(self):
        """Create a copy of the dimension."""
        return SIDimension(
            label=self.label,
            description=self.description,
            application=self.application,
            coordinates_offset=str(self._coordinates_offset),
            origin_offset=str(self._origin_offset),
            period=self._period,
            complex_fft=self._complex_fft
        )

    def copy_metadata(self, obj):
        """
        Copy SIDimension metadata.

        Args:
            obj: Object to copy metadata from
        """
        if hasattr(obj, 'label'):
            self.label = obj.label
        if hasattr(obj, 'description'):
            self.description = obj.description
        if hasattr(obj, 'application'):
            self.application = obj.application
        if hasattr(obj, 'coordinates_offset'):
            self.coordinates_offset = obj.coordinates_offset
        if hasattr(obj, 'origin_offset'):
            self.origin_offset = obj.origin_offset
        if hasattr(obj, 'period'):
            self.period = obj.period
        if hasattr(obj, 'complex_fft'):
            self.complex_fft = obj.complex_fft

    cdef object _parse_numeric_value(self, value):
        """Parse numeric value from string like '100 Hz' or return float."""
        if value is None:
            return 0.0
        if isinstance(value, str):
            # Check for infinity variants
            if "infinity" in value.lower() or "inf" in value.lower() or "∞" in value:
                return float('inf')
            import re
            match = re.search(r'[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?', value)
            if match:
                return float(match.group())
            return 0.0
        return float(value)

    @property
    def coordinates_offset(self):
        """Get coordinates offset."""
        return self._parse_numeric_value(self._coordinates_offset)

    @coordinates_offset.setter
    def coordinates_offset(self, value):
        """Set coordinates offset."""
        self._coordinates_offset = value

    @property
    def origin_offset(self):
        """Get origin offset."""
        return self._parse_numeric_value(self._origin_offset)

    @origin_offset.setter
    def origin_offset(self, value):
        """Set origin offset."""
        self._origin_offset = value

    @property
    def period(self):
        """Get the period."""
        if self._period is None:
            return float('inf')
        return self._parse_numeric_value(self._period)

    @period.setter
    def period(self, value):
        """Set the period."""
        self._period = value

    @property
    def complex_fft(self):
        """Get complex FFT flag."""
        return self._complex_fft

    @complex_fft.setter
    def complex_fft(self, value):
        """Set complex FFT flag."""
        self._complex_fft = bool(value)

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

    def reciprocal_coordinates(self):
        """Get reciprocal coordinates."""
        coords = self.coordinates
        if len(coords) == 0:
            return np.array([])
        # Handle zero coordinates to avoid division by zero warning
        with np.errstate(divide='ignore', invalid='ignore'):
            result = 1.0 / coords
        return result

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
    cdef object _increment
    cdef object _count

    def __init__(self, count=10, increment='1.0', label="", description="",
                 application=None, coordinates_offset='0', origin_offset='0',
                 period=None, complex_fft=False, **kwargs):
        """
        Initialize linear dimension.

        Args:
            count (int, optional): Number of coordinates
            increment (str or float, optional): Increment between coordinates
            label (str, optional): Short label for the dimension
            description (str, optional): Description of the dimension
            application (dict, optional): Application metadata
            coordinates_offset (str, optional): Coordinates offset value
            origin_offset (str, optional): Origin offset value
            period (str, optional): Period value for periodic dimensions
            complex_fft (bool, optional): Complex FFT flag
            **kwargs: Additional keyword arguments (for compatibility)
        """
        # Set linear-specific properties
        self._increment = increment
        self._count = count

        # Call parent init with SI dimension properties
        super().__init__(
            label=label,
            description=description,
            application=application,
            coordinates_offset=coordinates_offset,
            origin_offset=origin_offset,
            period=period,
            complex_fft=complex_fft,
            **kwargs
        )

        # Create C dimension using the C API
        cdef OCStringRef error = NULL

        try:
            # Get numeric values for C API
            count = self._count
            increment_val = self.increment
            start = 0.0  # Could be made configurable

            # Create the SI linear dimension
            self._linear_dimension = SILinearDimensionCreate(count, start, increment_val, &error)
            if self._linear_dimension == NULL:
                if error != NULL:
                    error_msg = OCStringGetCString(error).decode('utf-8')
                    raise RuntimeError(f"Failed to create linear dimension: {error_msg}")
                else:
                    raise RuntimeError("Failed to create linear dimension")

            # Cast to base dimension reference
            self._c_dimension = <DimensionRef>self._linear_dimension

        finally:
            if error != NULL:
                OCRelease(<OCTypeRef>error)

    @property
    def type(self):
        """Get the type of the dimension."""
        return 'linear'

    @property
    def increment(self):
        """Get the increment of the dimension."""
        # Parse the numeric value from strings like "100 Hz" or "5.0 G"
        if isinstance(self._increment, str):
            import re
            match = re.search(r'[-+]?(?:\d+\.?\d*|\.\d+)', self._increment)
            if match:
                return float(match.group())
        return float(self._increment)

    @increment.setter
    def increment(self, value):
        """Set the increment of the dimension."""
        self._increment = value

    @property
    def count(self):
        """Get the count of the dimension."""
        return self._count

    @count.setter
    def count(self, value):
        """Set the count of the dimension."""
        if not isinstance(value, int) or value <= 0:
            raise TypeError("Count must be a positive integer")
        self._count = value

    @property
    def coordinates(self) -> np.ndarray:
        """Get linear coordinates."""
        # Linear dimensions generate coordinates based on count and increment
        # rather than storing them directly
        increment_val = self.increment
        return np.arange(self._count, dtype=np.float64) * increment_val

    @property
    def coords(self) -> np.ndarray:
        """Alias for coordinates."""
        return self.coordinates

    def reciprocal_increment(self):
        """Get reciprocal increment."""
        inc = self.increment
        if inc == 0.0:
            return float('inf')
        return 1.0 / inc

    def copy(self):
        """Create a copy of the dimension."""
        return SILinearDimension(
            count=self._count,
            increment=str(self._increment),
            label=self.label,
            description=self.description,
            application=self.application,
            coordinates_offset=str(self._coordinates_offset),
            origin_offset=str(self._origin_offset),
            period=self._period,
            complex_fft=self._complex_fft
        )

    def copy_metadata(self, obj):
        """
        Copy SILinearDimension metadata.

        Args:
            obj: Object to copy metadata from
        """
        if hasattr(obj, 'label'):
            self.label = obj.label
        if hasattr(obj, 'description'):
            self.description = obj.description
        if hasattr(obj, 'application'):
            self.application = obj.application
        if hasattr(obj, 'coordinates_offset'):
            self.coordinates_offset = obj.coordinates_offset
        if hasattr(obj, 'origin_offset'):
            self.origin_offset = obj.origin_offset
        if hasattr(obj, 'period'):
            self.period = obj.period
        if hasattr(obj, 'complex_fft'):
            self.complex_fft = obj.complex_fft
        if hasattr(obj, 'increment'):
            self.increment = obj.increment
        if hasattr(obj, 'count'):
            self.count = obj.count

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
    cdef object _input_coordinates

    def __init__(self, coordinates, label="", description="", application=None,
                 coordinates_offset='0', origin_offset='0', period=None,
                 complex_fft=False, **kwargs):
        """
        Initialize monotonic dimension.

        Args:
            coordinates (list): List of coordinate values
            label (str, optional): Short label for the dimension
            description (str, optional): Description of the dimension
            application (dict, optional): Application metadata
            coordinates_offset (str, optional): Coordinates offset value
            origin_offset (str, optional): Origin offset value
            period (str, optional): Period value for periodic dimensions
            complex_fft (bool, optional): Complex FFT flag
            **kwargs: Additional keyword arguments (for compatibility)
        """
        # Validate coordinates
        if not coordinates:
            raise ValueError("Monotonic dimension requires coordinates")

        self._input_coordinates = coordinates

        # Call parent init with SI dimension properties
        super().__init__(
            label=label,
            description=description,
            application=application,
            coordinates_offset=coordinates_offset,
            origin_offset=origin_offset,
            period=period,
            complex_fft=complex_fft,
            **kwargs
        )

        # Create C dimension using the C API
        cdef OCArrayRef coords_array = NULL
        cdef OCStringRef error = NULL

        try:
            # Convert Python coordinates to C array
            coords_np = np.array(coordinates, dtype=np.float64)
            coords_array = OCArrayCreateWithDoubles(<double*>coords_np.data, len(coordinates))

            if coords_array == NULL:
                raise RuntimeError("Failed to create coordinates array")

            # Create the SI monotonic dimension
            self._monotonic_dimension = SIMonotonicDimensionCreate(coords_array, &error)
            if self._monotonic_dimension == NULL:
                if error != NULL:
                    error_msg = OCStringGetCString(error).decode('utf-8')
                    raise RuntimeError(f"Failed to create monotonic dimension: {error_msg}")
                else:
                    raise RuntimeError("Failed to create monotonic dimension")

            # Cast to base dimension reference
            self._c_dimension = <DimensionRef>self._monotonic_dimension

        finally:
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
        return len(self._input_coordinates)

    @property
    def coordinates(self) -> np.ndarray:
        """Get monotonic coordinates."""
        # Try to use C API first if we have a C object
        if self._c_dimension != NULL:
            cdef OCArrayRef coords_ref = SIMonotonicDimensionGetCoordinates(self._monotonic_dimension)
            if coords_ref != NULL:
                cdef OCIndex count = OCArrayGetCount(coords_ref)
                if count > 0:
                    cdef double* coords_ptr = OCArrayGetDoubles(coords_ref)
                    if coords_ptr != NULL:
                        # Convert C array to numpy array
                        coords_list = [coords_ptr[i] for i in range(count)]
                        return np.array(coords_list, dtype=np.float64)

        # Fallback: return the input coordinates
        return np.array(self._input_coordinates, dtype=np.float64)

    @property
    def coords(self) -> np.ndarray:
        """Alias for coordinates."""
        return self.coordinates

    def copy(self):
        """Create a copy of the dimension."""
        return SIMonotonicDimension(
            coordinates=list(self._input_coordinates),
            label=self.label,
            description=self.description,
            application=self.application,
            coordinates_offset=str(self._coordinates_offset),
            origin_offset=str(self._origin_offset),
            period=self._period,
            complex_fft=self._complex_fft
        )

    def to_dict(self):
        """Convert to dictionary."""
        result = super().to_dict()
        result['coordinates'] = list(self._input_coordinates)
        return result

    def copy_metadata(self, obj):
        """
        Copy SIMonotonicDimension metadata.

        Args:
            obj: Object to copy metadata from
        """
        if hasattr(obj, 'label'):
            self.label = obj.label
        if hasattr(obj, 'description'):
            self.description = obj.description
        if hasattr(obj, 'application'):
            self.application = obj.application
        if hasattr(obj, 'coordinates_offset'):
            self.coordinates_offset = obj.coordinates_offset
        if hasattr(obj, 'origin_offset'):
            self.origin_offset = obj.origin_offset
        if hasattr(obj, 'period'):
            self.period = obj.period
        if hasattr(obj, 'complex_fft'):
            self.complex_fft = obj.complex_fft
        if hasattr(obj, 'coordinates'):
            # For monotonic, copy the coordinates array
            if hasattr(obj.coordinates, 'tolist'):
                self._input_coordinates = obj.coordinates.tolist()
            else:
                self._input_coordinates = list(obj.coordinates)
