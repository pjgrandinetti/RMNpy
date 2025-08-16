# cython: language_level=3
"""
RMNLib Dimension wrapper with proper inheritance hierarchy

This module provides Python wrappers that mirror the C inheritance:
- BaseDimension (abstract base for common functionality)
- LabeledDimension (for discrete labeled coordinates)
- SIDimension (base for quantitative coordinates with SI units)
  - LinearDimension (for linear coordinates with constant increment)
  - MonotonicDimension (for monotonic coordinates with arbitrary spacing)

Use the specific dimension classes directly for explicit dimension creation.
"""

from enum import IntEnum
from typing import Any, Dict, List, Optional, Union

import numpy as np

from rmnpy._c_api.octypes cimport *
from rmnpy._c_api.rmnlib cimport *
from rmnpy._c_api.sitypes cimport *

from rmnpy.exceptions import RMNError

from rmnpy.wrappers.sitypes.scalar cimport Scalar, convert_to_siscalar_ref

from rmnpy.helpers.octypes import (  # py_list_to_siscalar_ocarray,  # Function doesn't exist; ocdict_create_from_pydict,  # Use ocdict_create_from_pydict instead; ocarray_create_from_pylist,  # Use ocarray_create_from_pylist instead; ocnumber_create_from_pynumber,  # Use ocnumber_create_from_pynumber instead; pynumber_to_siscalar_expression,  # Function doesn't exist; ocstring_to_pystring,  # Use ocstring_to_pystring instead
    ocarray_create_from_pylist,
    ocarray_to_pylist,
    ocdict_create_from_pydict,
    ocdict_to_pydict,
    ocnumber_create_from_pynumber,
    ocnumber_to_pynumber,
    ocstring_create_from_pystring,
    ocstring_to_pystring,
)


class DimensionScaling(IntEnum):
    """
    Dimension scaling types that mirror the C API dimensionScaling enum.

    Values:
        NONE (0): No scaling applied (kDimensionScalingNone)
        NMR (1): NMR-specific scaling applied (kDimensionScalingNMR)
    """
    NONE = 0  # kDimensionScalingNone
    NMR = 1   # kDimensionScalingNMR


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

    def __cinit__(self):
        """Initialize C-level attributes."""
        self._c_ref = NULL

    def __dealloc__(self):
        """Clean up C resources."""
        if self._c_ref != NULL:
            OCRelease(self._c_ref)

    @staticmethod
    cdef BaseDimension _from_c_ref(DimensionRef dim_ref):
        """Create appropriate dimension wrapper from C reference (internal use).

        Creates a copy of the dimension reference and returns the appropriate
        wrapper type based on the dimension's actual type.
        """
        if dim_ref == NULL:
            raise RMNError("Cannot create wrapper from NULL dimension reference")

        cdef DimensionRef copied_ref = <DimensionRef>OCTypeDeepCopy(<OCTypeRef>dim_ref)
        if copied_ref == NULL:
            raise RMNError("Failed to create copy of Dimension")

        cdef OCStringRef type_ref = DimensionGetType(copied_ref)
        if type_ref == NULL:
            OCRelease(<OCTypeRef>copied_ref)
            raise RMNError("C API returned NULL type for dimension reference")

        try:
            type_str = ocstring_to_pystring(<uint64_t>type_ref)
        finally:
            OCRelease(<OCTypeRef>type_ref)

        if type_str == "labeled":
            wrapper = LabeledDimension.__new__(LabeledDimension)
            (<LabeledDimension>wrapper)._c_ref = copied_ref
            return wrapper
        elif type_str == "linear":
            wrapper = LinearDimension.__new__(LinearDimension)
            (<LinearDimension>wrapper)._c_ref = copied_ref
            return wrapper
        elif type_str == "monotonic":
            wrapper = MonotonicDimension.__new__(MonotonicDimension)
            (<MonotonicDimension>wrapper)._c_ref = copied_ref
            return wrapper
        elif type_str == "si_dimension":
            # Base SIDimension type
            wrapper = SIDimension.__new__(SIDimension)
            (<SIDimension>wrapper)._c_ref = copied_ref
            return wrapper
        elif type_str == "dimension":
            # Generic base dimension type
            wrapper = BaseDimension.__new__(BaseDimension)
            (<BaseDimension>wrapper)._c_ref = copied_ref
            return wrapper
        else:
            # Fallback for unknown types - use base dimension
            wrapper = BaseDimension.__new__(BaseDimension)
            (<BaseDimension>wrapper)._c_ref = copied_ref
            return wrapper

    @property
    def type(self):
        """Get the type of the dimension."""
        type_ocstr = DimensionGetType(self._c_ref)
        if type_ocstr != NULL:
            return ocstring_to_pystring(<uint64_t>type_ocstr)
        raise RMNError("Invalid dimension: C API returned NULL type (dimension may be corrupted or uninitialized)")

    @property
    def description(self):
        """Get the description of the dimension."""
        desc_ocstr = DimensionCopyDescription(self._c_ref)
        if desc_ocstr == NULL:
            raise RMNError("C API returned NULL description (dimension may be corrupted or uninitialized)")
        try:
            result = ocstring_to_pystring(<uint64_t>desc_ocstr)
            if result is None:
                raise RMNError("Failed to convert description to Python string")
            return result
        finally:
            OCRelease(<OCTypeRef>desc_ocstr)

    @description.setter
    def description(self, value):
        """Set the description of the dimension."""
        cdef OCStringRef err_ocstr = NULL
        cdef OCStringRef desc_ocstr

        if value is not None and not isinstance(value, str):
            raise TypeError("Description must be a string or None")

        desc_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(value)
        try:
            if not DimensionSetDescription(self._c_ref, desc_ocstr, &err_ocstr):
                if err_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>err_ocstr)
                    raise RMNError(f"Failed to set description: {error_msg}")
                else:
                    raise RMNError("Failed to set description")
        finally:
            if desc_ocstr != NULL:
                OCRelease(<OCTypeRef>desc_ocstr)
            if err_ocstr != NULL:
                OCRelease(<OCTypeRef>err_ocstr)

    @property
    def label(self):
        """Get the label of the dimension."""
        label_ocstr = DimensionCopyLabel(self._c_ref)
        if label_ocstr == NULL:
            raise RMNError("C API returned NULL label (dimension may be corrupted or uninitialized)")
        try:
            return ocstring_to_pystring(<uint64_t>label_ocstr)
        finally:
            OCRelease(<OCTypeRef>label_ocstr)

    @label.setter
    def label(self, value):
        """Set the label of the dimension."""
        cdef OCStringRef err_ocstr = NULL
        cdef OCStringRef label_ocstr

        if value is not None and not isinstance(value, str):
            raise TypeError("Label must be a string or None")

        label_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(value)
        try:
            if not DimensionSetLabel(self._c_ref, label_ocstr, &err_ocstr):
                if err_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>err_ocstr)
                    OCRelease(<OCTypeRef>err_ocstr)
                    raise RMNError(f"Failed to set label: {error_msg}")
                else:
                    raise RMNError("Failed to set label")
        finally:
            if label_ocstr != NULL:
                OCRelease(<OCTypeRef>label_ocstr)

    @property
    def count(self):
        """Get the count of the dimension."""
        return DimensionGetCount(self._c_ref)

    @property
    def size(self):
        """Alias for count property (csdmpy compatibility)."""
        return self.count

    @property
    def application(self):
        """Get application metadata."""
        cdef OCDictionaryRef application_ocdict

        application_ocdict = DimensionGetApplicationMetaData(self._c_ref)
        if application_ocdict != NULL:
            return ocdict_to_pydict(<uint64_t>application_ocdict)
        raise RMNError("C API returned NULL application metadata (dimension may be corrupted or uninitialized)")

    @application.setter
    def application(self, value):
        """Set application metadata."""
        cdef OCStringRef err_ocstr = NULL
        cdef OCDictionaryRef application_ocdict = NULL

        if value is not None and not isinstance(value, dict):
            raise TypeError("Application metadata must be a dictionary or None")

        try:
            if value is None or (isinstance(value, dict) and len(value) == 0):
                if not DimensionSetApplicationMetaData(self._c_ref, NULL, &err_ocstr):
                    if err_ocstr != NULL:
                        error_msg = ocstring_to_pystring(<uint64_t>err_ocstr)
                        raise RMNError(f"Failed to clear metadata: {error_msg}")
                    else:
                        raise RMNError("Failed to clear metadata")
            else:
                application_ocdict = <OCDictionaryRef><uint64_t>ocdict_create_from_pydict(value)
                try:
                    if not DimensionSetApplicationMetaData(self._c_ref, application_ocdict, &err_ocstr):
                        if err_ocstr != NULL:
                            error_msg = ocstring_to_pystring(<uint64_t>err_ocstr)
                            raise RMNError(f"Failed to set metadata: {error_msg}")
                        else:
                            raise RMNError("Failed to set metadata")
                finally:
                    if application_ocdict != NULL:
                        OCRelease(<OCTypeRef>application_ocdict)
        finally:
            if err_ocstr != NULL:
                OCRelease(<OCTypeRef>err_ocstr)

    def is_quantitative(self):
        """Check if dimension is quantitative (not labeled)."""
        return DimensionIsQuantitative(self._c_ref)

    def axis_label(self, index):
        """Get formatted axis label using C API."""
        cdef OCStringRef axis_label_ocstr = NULL

        axis_label_ocstr = DimensionCreateAxisLabel(self._c_ref, <OCIndex>index)
        if axis_label_ocstr == NULL:
            raise RMNError("Failed to create axis label")

        try:
            return ocstring_to_pystring(<uint64_t>axis_label_ocstr)
        finally:
            if axis_label_ocstr != NULL:
                OCRelease(<OCTypeRef>axis_label_ocstr)

    def to_dict(self):
        """Convert to dictionary."""
        dim_ocdict = DimensionCopyAsDictionary(self._c_ref)
        if dim_ocdict != NULL:
            try:
                return ocdict_to_pydict(<uint64_t>dim_ocdict)
            finally:
                OCRelease(<OCTypeRef>dim_ocdict)

        raise RMNError("C API returned NULL dictionary representation (dimension may be corrupted or uninitialized)")

    def dict(self):
        """Alias for to_dict() method (csdmpy compatibility)."""
        return self.to_dict()

    @property
    def data_structure(self):
        """JSON serialized string of dimension object (csdmpy compatibility)."""
        import json
        return json.dumps(self.to_dict(), ensure_ascii=False, sort_keys=False, indent=2)

    def __eq__(self, other):
        """Compare dimensions for equality using OCTypes C API."""
        if not isinstance(other, BaseDimension):
            return False

        cdef BaseDimension other_dim = <BaseDimension>other

        return OCTypeEqual(<OCTypeRef>self._c_ref, <OCTypeRef>other_dim._c_ref)

    def __repr__(self):
        """String representation."""
        return f"{self.__class__.__name__}(type='{self.type}', count={self.count})"

    @property
    def absolute_coordinates(self) -> np.ndarray:
        """Get absolute coordinates along the dimension."""
        # Dispatch to appropriate C API function based on dimension type
        dim_type = self.type
        cdef OCArrayRef coords_ref = NULL

        if dim_type == "labeled":
            # For labeled dimensions, return the coordinate labels
            coords_ref = LabeledDimensionCopyCoordinateLabels(<LabeledDimensionRef>self._c_ref)
            if coords_ref != NULL:
                try:
                    coords_list = ocarray_to_pylist(<uint64_t>coords_ref)
                    if coords_list:
                        return np.array(coords_list)  # Keep original data type for labels
                finally:
                    OCRelease(<OCTypeRef>coords_ref)
        elif dim_type == "linear":
            coords_ref = SILinearDimensionCreateAbsoluteCoordinates(<SILinearDimensionRef>self._c_ref)
            if coords_ref != NULL:
                try:
                    coords_list = ocarray_to_pylist(<uint64_t>coords_ref)
                    if coords_list:
                        return np.array(coords_list, dtype=np.float64)
                finally:
                    OCRelease(<OCTypeRef>coords_ref)
        elif dim_type == "monotonic":
            coords_ref = SIMonotonicDimensionCreateAbsoluteCoordinates(<SIMonotonicDimensionRef>self._c_ref)
            if coords_ref != NULL:
                try:
                    coords_list = ocarray_to_pylist(<uint64_t>coords_ref)
                    if coords_list:
                        return np.array(coords_list, dtype=np.float64)
                finally:
                    OCRelease(<OCTypeRef>coords_ref)

        raise RMNError(f"C API returned NULL absolute coordinates for {dim_type} dimension (dimension may be corrupted or uninitialized)")

    @property
    def coordinates(self) -> np.ndarray:
        """Get coordinates along the dimension."""
        # Dispatch to appropriate C API function based on dimension type
        dim_type = self.type
        cdef OCArrayRef coords_ref = NULL

        if dim_type == "labeled":
            # For labeled dimensions, return the coordinate labels
            coords_ref = LabeledDimensionCopyCoordinateLabels(<LabeledDimensionRef>self._c_ref)
            if coords_ref != NULL:
                try:
                    coords_list = ocarray_to_pylist(<uint64_t>coords_ref)
                    if coords_list:
                        return np.array(coords_list)  # Keep original data type for labels
                finally:
                    OCRelease(<OCTypeRef>coords_ref)
        elif dim_type == "linear":
            coords_ref = SILinearDimensionCreateCoordinates(<SILinearDimensionRef>self._c_ref)
            if coords_ref != NULL:
                try:
                    coords_list = ocarray_to_pylist(<uint64_t>coords_ref)
                    if coords_list:
                        return np.array(coords_list, dtype=np.float64)
                finally:
                    OCRelease(<OCTypeRef>coords_ref)
        elif dim_type == "monotonic":
            coords_ref = SIMonotonicDimensionCopyCoordinates(<SIMonotonicDimensionRef>self._c_ref)
            if coords_ref != NULL:
                try:
                    coords_list = ocarray_to_pylist(<uint64_t>coords_ref)
                    if coords_list:
                        return np.array(coords_list, dtype=np.float64)
                finally:
                    OCRelease(<OCTypeRef>coords_ref)

        raise RMNError(f"C API returned NULL coordinates for {dim_type} dimension (dimension may be corrupted or uninitialized)")

    @property
    def coords(self) -> np.ndarray:
        """Alias for coordinates."""
        return self.coordinates

    def copy(self):
        """Create a copy of the dimension using OCTypeDeepCopy."""
        if self._c_ref == NULL:
            raise RMNError("Cannot copy null dimension")

        cdef void *copied_dimension = OCTypeDeepCopy(self._c_ref)
        if copied_dimension == NULL:
            raise RMNError("Failed to create dimension copy")

        # Use the _from_c_ref static method to create the appropriate wrapper
        return BaseDimension._from_c_ref(<DimensionRef>copied_dimension)

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
        cdef OCArrayRef labels_ocarray = <OCArrayRef><uint64_t>ocarray_create_from_pylist(labels)
        cdef OCStringRef label_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(label)
        cdef OCStringRef desc_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(description)
        cdef OCDictionaryRef application_ocdict = <OCDictionaryRef><uint64_t>ocdict_create_from_pydict(application)
        cdef OCStringRef err_ocstr = NULL

        try:
            self._c_ref = <DimensionRef>LabeledDimensionCreate(
                label_ocstr, desc_ocstr, application_ocdict, labels_ocarray, &err_ocstr)
            if self._c_ref == NULL:
                if err_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>err_ocstr)
                    raise RMNError(f"Failed to create labeled dimension: {error_msg}")
                else:
                    raise RMNError("Failed to create labeled dimension")
        finally:
            if label_ocstr != NULL:
                OCRelease(<OCTypeRef>label_ocstr)
            if desc_ocstr != NULL:
                OCRelease(<OCTypeRef>desc_ocstr)
            if application_ocdict != NULL:
                OCRelease(<OCTypeRef>application_ocdict)
            if labels_ocarray != NULL:
                OCRelease(<OCTypeRef>labels_ocarray)
            if err_ocstr != NULL:
                OCRelease(<OCTypeRef>err_ocstr)

    @property
    def coordinate_labels(self) -> np.ndarray:
        """Get coordinate labels (primary implementation)."""
        labels_ocarray = LabeledDimensionCopyCoordinateLabels(<LabeledDimensionRef>self._c_ref)
        if labels_ocarray != NULL:
            try:
                labels_list = ocarray_to_pylist(<uint64_t>labels_ocarray)
                if labels_list:
                    return np.array(labels_list)
            finally:
                OCRelease(<OCTypeRef>labels_ocarray)

        raise RMNError("C API returned NULL coordinate labels (dimension may be corrupted or uninitialized)")

    @property
    def labels(self):
        """Get labels for labeled dimensions."""
        return self.coordinate_labels

    @coordinate_labels.setter
    def coordinate_labels(self, value):
        """Set coordinate labels."""
        cdef OCStringRef err_ocstr = NULL
        cdef OCArrayRef labels_ocarray = <OCArrayRef><uint64_t>ocarray_create_from_pylist(value)

        if self._c_ref == NULL:
            raise RMNError("Cannot set coordinate labels: dimension not properly initialized")

        try:
            if not LabeledDimensionSetCoordinateLabels(<LabeledDimensionRef>self._c_ref, labels_ocarray, &err_ocstr):
                if err_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>err_ocstr)
                    OCRelease(<OCTypeRef>err_ocstr)
                    raise RMNError(f"Failed to set coordinate labels: {error_msg}")
                else:
                    raise RMNError("Failed to set coordinate labels")
        finally:
            OCRelease(<OCTypeRef>labels_ocarray)

    @labels.setter
    def labels(self, value):
        """Set labels for labeled dimensions (alias for coordinate_labels)."""
        # Delegate to coordinate_labels.setter to avoid code duplication
        # and maintain single source of truth for C API interaction
        self.coordinate_labels = value


    def set_coordinate_label_at_index(self, index, label):
        """Set coordinate label at specific index."""
        cdef OCStringRef err_ocstr = NULL
        cdef OCStringRef label_ocstr = NULL

        if self._c_ref == NULL:
            raise RMNError("Cannot set coordinate label: dimension not properly initialized")

        if not (0 <= index < self.count):
            raise IndexError(f"Label index {index} out of range")

        try:
            label_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(str(label))
            if not LabeledDimensionSetCoordinateLabelAtIndex(<LabeledDimensionRef>self._c_ref, index, label_ocstr):
                raise RMNError(f"Failed to set coordinate label at index {index}")
        finally:
            if label_ocstr != NULL:
                OCRelease(<OCTypeRef>label_ocstr)

cdef class SIDimension(BaseDimension):
    """
    Base class for quantitative dimensions with SI units.

    Provides common functionality for quantitative dimensions including
    coordinate offsets, periods, and unit-aware operations.
    """

    def __init__(self, label=None, description=None, application=None,
                 quantity_name=None, period=None, scaling=DimensionScaling.NONE,
                 coordinates_offset=None, origin_offset=None, **kwargs):
        """
        Initialize SI dimension.

        C API Requirements (SIDimensionCreate):
        - ALL parameters are OPTIONAL (function provides intelligent defaults)
        - Derives units from first non-NULL scalar (priority: coordinates_offset → origin_offset → period → quantityName → dimensionless)
        - Creates zero scalars in appropriate units for NULL parameters
        - Periodicity is determined automatically: period exists and is finite → periodic, otherwise non-periodic

        Args:
            label (str, optional): Short label for the dimension
            description (str, optional): Description of the dimension
            application (dict, optional): Application metadata
            quantity_name (str, optional): Physical quantity name (e.g., "frequency", "time")
                If None, derived from first available scalar's dimensionality
            period (str or Scalar, optional): SIScalar period value for periodic dimensions
                Defaults to zero in derived base unit
            scaling (DimensionScaling or int, optional): Dimension scaling type
                (default: DimensionScaling.NONE). Use DimensionScaling.NONE or DimensionScaling.NMR
            coordinates_offset (str or Scalar, optional): SIScalar coordinates offset value
                Defaults to zero in derived base unit
            origin_offset (str or Scalar, optional): SIScalar origin offset value
                Defaults to zero in derived base unit
            **kwargs: Additional keyword arguments (for compatibility)

        Note:
            SIDimension is abstract - use LinearDimension or MonotonicDimension instead.
            This class provides common SI dimension functionality and default parameter handling.
        """
        cdef OCStringRef label_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(label)
        cdef OCStringRef desc_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(description)
        cdef OCDictionaryRef application_ocdict = <OCDictionaryRef><uint64_t>ocdict_create_from_pydict(application)
        cdef OCStringRef quantity_name_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(quantity_name)
        cdef SIScalarRef coordinates_offset_sisclr = NULL
        cdef SIScalarRef origin_offset_sisclr = NULL
        cdef SIScalarRef period_sisclr = NULL
        cdef OCStringRef err_ocstr = NULL

        # Validate scaling parameter
        if scaling is not None:
            if isinstance(scaling, int):
                if scaling not in [DimensionScaling.NONE, DimensionScaling.NMR]:
                    raise ValueError(f"Invalid scaling value {scaling}. Use DimensionScaling.NONE (0) or DimensionScaling.NMR (1)")
            elif isinstance(scaling, DimensionScaling):
                scaling = int(scaling)  # Convert enum to int for C API
            else:
                raise TypeError(f"scaling must be DimensionScaling enum or int, got {type(scaling)}")

        # Convert coordinates_offset parameter to SIScalar if provided
        if coordinates_offset is not None:
            coordinates_offset_sisclr = convert_to_siscalar_ref(coordinates_offset)

        # Convert origin_offset parameter to SIScalar if provided
        if origin_offset is not None:
            origin_offset_sisclr = convert_to_siscalar_ref(origin_offset)

        # Convert period parameter to SIScalar if provided
        if period is not None:
            period_sisclr = convert_to_siscalar_ref(period)

        try:
            si_dimension = SIDimensionCreate(
                label_ocstr,
                desc_ocstr,
                application_ocdict,
                quantity_name_ocstr,
                coordinates_offset_sisclr,
                origin_offset_sisclr,
                period_sisclr,
                scaling,
                &err_ocstr)

            if si_dimension == NULL:
                if err_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>err_ocstr)
                    OCRelease(<OCTypeRef>err_ocstr)
                    raise RMNError(f"Failed to create SI dimension: {error_msg}")
                else:
                    raise RMNError("Failed to create SI dimension")

            self._c_ref = <DimensionRef>si_dimension

        finally:
            if label_ocstr != NULL:
                OCRelease(<OCTypeRef>label_ocstr)
            if desc_ocstr != NULL:
                OCRelease(<OCTypeRef>desc_ocstr)
            if application_ocdict != NULL:
                OCRelease(<OCTypeRef>application_ocdict)
            if quantity_name_ocstr != NULL:
                OCRelease(<OCTypeRef>quantity_name_ocstr)

    @property
    def coordinates_offset(self):
        """Get coordinates offset."""
        offset_sisclr = SIDimensionCopyCoordinatesOffset(<SIDimensionRef>self._c_ref)
        if offset_sisclr == NULL:
            raise RMNError("C API returned NULL coordinates offset (dimension may be corrupted or uninitialized)")

        try:
            return Scalar._from_c_ref(offset_sisclr)
        finally:
            OCRelease(<OCTypeRef>offset_sisclr)

    @coordinates_offset.setter
    def coordinates_offset(self, value):
        """Set coordinates offset."""
        cdef OCStringRef err_ocstr = NULL
        cdef SIScalarRef coordinates_offset_sisclr = NULL

        if self._c_ref == NULL:
            raise RMNError("Cannot set coordinates offset: dimension not properly initialized")

        # Handle both Scalar objects and strings like in __init__
        coordinates_offset_sisclr = convert_to_siscalar_ref(value)

        if not SIDimensionSetCoordinatesOffset(<SIDimensionRef>self._c_ref, coordinates_offset_sisclr, &err_ocstr):
            if err_ocstr != NULL:
                error_msg = ocstring_to_pystring(<uint64_t>err_ocstr)
                OCRelease(<OCTypeRef>err_ocstr)
                raise RMNError(f"Failed to set coordinates offset: {error_msg}")
            else:
                raise RMNError("Failed to set coordinates offset")

    @property
    def origin_offset(self):
        """Get origin offset as Scalar object."""
        origin_sisclr = SIDimensionCopyOriginOffset(<SIDimensionRef>self._c_ref)
        if origin_sisclr == NULL:
            raise RMNError("C API returned NULL origin offset (dimension may be corrupted or uninitialized)")

        # _from_c_ref now creates a copy, so we can safely release our reference
        try:
            return Scalar._from_c_ref(origin_sisclr)
        finally:
            OCRelease(<OCTypeRef>origin_sisclr)

    @origin_offset.setter
    def origin_offset(self, value):
        """Set origin offset."""
        cdef OCStringRef err_ocstr = NULL
        cdef SIScalarRef origin_offset_sisclr = NULL

        if self._c_ref == NULL:
            raise RMNError("Cannot set origin offset: dimension not properly initialized")

        # Handle both Scalar objects and strings like in __init__
        origin_offset_sisclr = convert_to_siscalar_ref(value)

        if not SIDimensionSetOriginOffset(<SIDimensionRef>self._c_ref, origin_offset_sisclr, &err_ocstr):
            if err_ocstr != NULL:
                error_msg = ocstring_to_pystring(<uint64_t>err_ocstr)
                OCRelease(<OCTypeRef>err_ocstr)
                raise RMNError(f"Failed to set origin offset: {error_msg}")
            else:
                raise RMNError("Failed to set origin offset")

    @property
    def period(self):
        """Get the period."""
        period_sisclr = SIDimensionCopyPeriod(<SIDimensionRef>self._c_ref)
        if period_sisclr != NULL:
            try:
                value = SIScalarDoubleValue(period_sisclr)
                if value != value:
                    return float("inf")
                elif value == float("inf") or value == float("-inf"):
                    return float("inf")
                else:
                    return value
            finally:

                OCRelease(<OCTypeRef>period_sisclr)
        else:

            raise RMNError("C API returned NULL period (dimension may be corrupted or uninitialized)")

    @period.setter
    def period(self, value):
        """Set the period."""
        cdef OCStringRef err_ocstr = NULL
        cdef SIScalarRef period_sisclr = NULL

        if self._c_ref == NULL:
            raise RMNError("Cannot set period: dimension not properly initialized")

        # Handle None and infinity string values
        if value is None:
            # Pass NULL to C API for infinite/no period
            if not SIDimensionSetPeriod(<SIDimensionRef>self._c_ref, NULL, &err_ocstr):
                if err_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>err_ocstr)
                    OCRelease(<OCTypeRef>err_ocstr)
                    raise RMNError(f"Failed to set period to None: {error_msg}")
                else:
                    raise RMNError("Failed to set period to None")
            return

        # Handle string values that represent infinity
        if isinstance(value, str) and value.lower() in ['infinity', 'inf']:
            # Pass NULL to C API for infinite period
            if not SIDimensionSetPeriod(<SIDimensionRef>self._c_ref, NULL, &err_ocstr):
                if err_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>err_ocstr)
                    OCRelease(<OCTypeRef>err_ocstr)
                    raise RMNError(f"Failed to set period to infinity: {error_msg}")
                else:
                    raise RMNError("Failed to set period to infinity")
            return

        # Handle both Scalar objects and strings like in __init__
        period_sisclr = convert_to_siscalar_ref(value)

        if not SIDimensionSetPeriod(<SIDimensionRef>self._c_ref, period_sisclr, &err_ocstr):
            if err_ocstr != NULL:
                error_msg = ocstring_to_pystring(<uint64_t>err_ocstr)
                OCRelease(<OCTypeRef>err_ocstr)
                raise RMNError(f"Failed to set period: {error_msg}")
            else:
                raise RMNError("Failed to set period")

    @property
    def quantity_name(self):
        """Get quantity name for physical quantities."""
        quantity_ref = SIDimensionCopyQuantityName(<SIDimensionRef>self._c_ref)
        if quantity_ref != NULL:
            try:
                return ocstring_to_pystring(<uint64_t>quantity_ref)
            finally:
                OCRelease(<OCTypeRef>quantity_ref)

        raise RMNError("C API returned NULL quantity name (dimension may be corrupted or uninitialized)")

    @quantity_name.setter
    def quantity_name(self, value):
        """Set quantity name for physical quantities."""
        cdef OCStringRef err_ocstr = NULL
        cdef OCStringRef quantity_name_ocstr = NULL

        if self._c_ref == NULL:
            raise RMNError("Cannot set quantity name: dimension not properly initialized")

        # If we have a C dimension object, update it too
        if value is not None and value != "":
            quantity_name_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(str(value))
            try:
                if not SIDimensionSetQuantityName(<SIDimensionRef>self._c_ref, quantity_name_ocstr, &err_ocstr):
                    if err_ocstr != NULL:
                        error_msg = ocstring_to_pystring(<uint64_t>err_ocstr)
                        OCRelease(<OCTypeRef>err_ocstr)
                        raise RMNError(f"Failed to set quantity name: {error_msg}")
                    else:
                        raise RMNError("Failed to set quantity name")
            finally:
                if quantity_name_ocstr != NULL:
                    OCRelease(<OCTypeRef>quantity_name_ocstr)
        else:
            if not SIDimensionSetQuantityName(<SIDimensionRef>self._c_ref, NULL, &err_ocstr):
                if err_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>err_ocstr)
                    OCRelease(<OCTypeRef>err_ocstr)
                    raise RMNError(f"Failed to clear quantity name: {error_msg}")
                else:
                    raise RMNError("Failed to clear quantity name")

    @property
    def periodic(self):
        """Get periodic flag - now based on finite period."""
        return SIDimensionIsPeriodic(<SIDimensionRef>self._c_ref)

    # Note: periodic is now read-only and determined by period value
    # To make a dimension periodic, set a finite period value
    # To make it non-periodic, set period to infinity or remove it

    @property
    def scaling(self):
        """Get scaling type."""
        # TODO: Add C API getter once available
        return 0  # Default placeholder (kDimensionScalingNone)

    @scaling.setter
    def scaling(self, value):
        """Set scaling type."""
        cdef OCStringRef err_ocstr = NULL

        if self._c_ref == NULL:
            raise RMNError("Cannot set scaling: dimension not properly initialized")

        # Validate scaling parameter
        if isinstance(value, int):
            if value not in [DimensionScaling.NONE, DimensionScaling.NMR]:
                raise ValueError(f"Invalid scaling value {value}. Use DimensionScaling.NONE (0) or DimensionScaling.NMR (1)")
            scaling_value = value
        elif isinstance(value, DimensionScaling):
            scaling_value = int(value)  # Convert enum to int for C API
        else:
            raise TypeError(f"scaling must be DimensionScaling enum or int, got {type(value)}")

        # Update C dimension object
        if not SIDimensionSetScaling(<SIDimensionRef>self._c_ref, scaling_value):
            raise RMNError("Failed to set scaling")

cdef class LinearDimension(SIDimension):
    """
    Linear dimension with constant increment.

    Used for dimensions with evenly spaced coordinates, such as
    time series or frequency sweeps with constant spacing.

    Examples:
        >>> dim = LinearDimension({'count': 5, 'increment': '2.0'})
        >>> dim.coordinates
        array([0., 2., 4., 6., 8.])
        >>> dim.increment
        2.0
    """

    def __init__(self, count, increment, label=None, description=None,
                 application=None, quantity_name=None, coordinates_offset=None, origin_offset=None,
                 period=None, scaling=DimensionScaling.NONE, complex_fft=False, reciprocal=None, **kwargs):
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
            coordinates_offset (str or Scalar, optional): SIScalar coordinates offset value (default: None = NULL, C API uses zero)
            origin_offset (str or Scalar, optional): SIScalar origin offset value (default: None = NULL, C API uses zero)
            period (str or Scalar, optional): SIScalar period value for periodic dimensions (default: None = NULL)
            scaling (DimensionScaling or int, optional): Dimension scaling type
                (default: DimensionScaling.NONE). Use DimensionScaling.NONE or DimensionScaling.NMR
            complex_fft (bool, optional): True if used for complex FFT
            reciprocal (SIDimension, optional): Reciprocal dimension (default: None = NULL)
            **kwargs: Additional keyword arguments (for compatibility)

        Raises:
            RMNError: If count < 2 or increment is not a real SIScalar
            RMNError: If increment cannot be converted to Scalar
            TypeError: If count or increment are not provided (required parameters)

        Examples:
            # Basic linear dimension (count and increment required)
            >>> dim = LinearDimension(count=10, increment='1.0 Hz')

            # With units and metadata
            >>> dim = LinearDimension(
            ...     count=100,
            ...     increment='10.0 kHz',
            ...     label='frequency',
            ...     quantity_name='frequency'
            ... )
        """
        cdef OCStringRef label_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(label)
        cdef OCStringRef desc_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(description)
        cdef OCDictionaryRef application_ocdict = <OCDictionaryRef><uint64_t>ocdict_create_from_pydict(application)
        cdef OCStringRef quantity_name_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(quantity_name)
        cdef SIScalarRef increment_sisclr = NULL
        cdef SIScalarRef coordinates_offset_sisclr = NULL
        cdef SIScalarRef origin_offset_sisclr = NULL
        cdef SIScalarRef period_sisclr = NULL
        cdef OCStringRef err_ocstr = NULL

        # Validate scaling parameter
        if scaling is not None:
            if isinstance(scaling, int):
                if scaling not in [DimensionScaling.NONE, DimensionScaling.NMR]:
                    raise ValueError(f"Invalid scaling value {scaling}. Use DimensionScaling.NONE (0) or DimensionScaling.NMR (1)")
            elif isinstance(scaling, DimensionScaling):
                scaling = int(scaling)  # Convert enum to int for C API
            else:
                raise TypeError(f"scaling must be DimensionScaling enum or int, got {type(scaling)}")

        # Convert increment parameter to SIScalar (required parameter)
        if increment is not None:
            increment_sisclr = convert_to_siscalar_ref(increment)

        # Convert coordinates_offset parameter to SIScalar if provided
        if coordinates_offset is not None:
            coordinates_offset_sisclr = convert_to_siscalar_ref(coordinates_offset)

        # Convert origin_offset parameter to SIScalar if provided
        if origin_offset is not None:
            origin_offset_sisclr = convert_to_siscalar_ref(origin_offset)

        # Convert period parameter to SIScalar if provided
        if period is not None:
            period_sisclr = convert_to_siscalar_ref(period)

        cdef SIDimensionRef reciprocal_ref = NULL

        # Convert reciprocal parameter to SIDimensionRef if provided
        if reciprocal is not None:
            if hasattr(reciprocal, '_c_ref'):
                reciprocal_ref = <SIDimensionRef>(<SIDimension>reciprocal)._c_ref
            else:
                reciprocal_ref = NULL

        try:
            linear_dimension = SILinearDimensionCreate(
                label_ocstr,
                desc_ocstr,
                application_ocdict,
                quantity_name_ocstr,
                coordinates_offset_sisclr,
                origin_offset_sisclr,
                period_sisclr,
                scaling,
                count,                  # count (use parameter, not stored value)
                increment_sisclr,       # increment (required)
                complex_fft,            # complex_fft (use parameter, not stored value)
                reciprocal_ref,         # reciprocal
                &err_ocstr              # err_ocstr
            )

            if linear_dimension == NULL:
                if err_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>err_ocstr)
                    raise RMNError(f"Failed to create linear dimension: {error_msg}")
                else:
                    raise RMNError("Failed to create linear dimension")

            # Cast to base dimension reference
            self._c_ref = <DimensionRef>linear_dimension

        finally:
            if label_ocstr != NULL:
                OCRelease(<OCTypeRef>label_ocstr)
            if desc_ocstr != NULL:
                OCRelease(<OCTypeRef>desc_ocstr)
            if quantity_name_ocstr != NULL:
                OCRelease(<OCTypeRef>quantity_name_ocstr)
            if application_ocdict != NULL:
                OCRelease(<OCTypeRef>application_ocdict)
            if increment_sisclr != NULL:
                OCRelease(<OCTypeRef>increment_sisclr)
            if coordinates_offset_sisclr != NULL:
                OCRelease(<OCTypeRef>coordinates_offset_sisclr)
            if origin_offset_sisclr != NULL:
                OCRelease(<OCTypeRef>origin_offset_sisclr)
            if period_sisclr != NULL:
                OCRelease(<OCTypeRef>period_sisclr)
            if err_ocstr != NULL:
                OCRelease(<OCTypeRef>err_ocstr)

    @property
    def increment(self):
        """Get the increment of the dimension."""
        increment_sisclr = SILinearDimensionCopyIncrement(<SILinearDimensionRef>self._c_ref)
        if increment_sisclr == NULL:
            raise RMNError("C API returned NULL increment (dimension may be corrupted or uninitialized)")

        # _from_c_ref now creates a copy, so we can safely release our reference
        try:
            return Scalar._from_c_ref(increment_sisclr)
        finally:
            OCRelease(<OCTypeRef>increment_sisclr)

    @increment.setter
    def increment(self, value):
        """Set the increment of the dimension."""
        cdef SIScalarRef increment_sisclr = NULL

        if self._c_ref == NULL:
            raise RMNError("Cannot set increment: dimension not properly initialized")

        increment_sisclr = convert_to_siscalar_ref(value)

        if increment_sisclr == NULL:
            raise RMNError("Failed to convert increment value to SIScalar")

        if not SILinearDimensionSetIncrement(<SILinearDimensionRef>self._c_ref, increment_sisclr):
            raise RMNError("Failed to set increment")

    @property
    def count(self):
        """Get the count of the dimension."""
        return DimensionGetCount(self._c_ref)

    @count.setter
    def count(self, value):
        """Set the count of the dimension."""
        if self._c_ref == NULL:
            raise RMNError("Cannot set count: dimension not properly initialized")

        if not isinstance(value, int) or value <= 0:
            raise TypeError("Count must be a positive integer")

        # Update C dimension object only
        if not SILinearDimensionSetCount(<SILinearDimensionRef>self._c_ref, value):
            raise RMNError("Failed to set count")

    @property
    def complex_fft(self):
        """Get complex FFT flag."""
        return SILinearDimensionGetComplexFFT(<SILinearDimensionRef>self._c_ref)

    @complex_fft.setter
    def complex_fft(self, value):
        """Set complex FFT flag."""
        if self._c_ref == NULL:
            raise RMNError("Cannot set complex FFT flag: dimension not properly initialized")

        # Update C dimension object only
        if not SILinearDimensionSetComplexFFT(<SILinearDimensionRef>self._c_ref, bool(value)):
            raise RMNError("Failed to set complex FFT flag")

    @property
    def reciprocal(self):
        """Get reciprocal dimension."""
        reciprocal_ref = SILinearDimensionCopyReciprocal(<SILinearDimensionRef>self._c_ref)
        if reciprocal_ref != NULL:
            return BaseDimension._from_c_ref(<DimensionRef>reciprocal_ref)
        raise RMNError("C API returned NULL reciprocal dimension (dimension may be corrupted or uninitialized)")

    @reciprocal.setter
    def reciprocal(self, value):
        """Set reciprocal dimension."""
        cdef OCStringRef err_ocstr = NULL
        cdef SIDimensionRef reciprocal_ref = NULL

        # Update C dimension object
        if value is not None:
            if hasattr(value, '_c_ref'):
                reciprocal_ref = <SIDimensionRef>(<SIDimension>value)._c_ref
            else:
                reciprocal_ref = NULL

        if not SILinearDimensionSetReciprocal(<SILinearDimensionRef>self._c_ref, reciprocal_ref, &err_ocstr):
            if err_ocstr != NULL:
                error_msg = ocstring_to_pystring(<uint64_t>err_ocstr)
                OCRelease(<OCTypeRef>err_ocstr)
                raise RMNError(f"Failed to set reciprocal dimension: {error_msg}")
            else:
                raise RMNError("Failed to set reciprocal dimension")

    @property
    def reciprocal_increment(self):
        """Get reciprocal increment."""
        reciprocal_increment_sisclr = SILinearDimensionCreateReciprocalIncrement(<SILinearDimensionRef>self._c_ref)
        if reciprocal_increment_sisclr == NULL:
            raise RMNError("C API returned NULL reciprocal increment (dimension may be corrupted or uninitialized)")

        try:
            return Scalar._from_c_ref(reciprocal_increment_sisclr)
        finally:
            OCRelease(<OCTypeRef>reciprocal_increment_sisclr)

cdef class MonotonicDimension(SIDimension):
    """
    Monotonic dimension with arbitrary coordinate spacing.

    Used for dimensions where coordinates are not evenly spaced
    but maintain a monotonic (increasing or decreasing) order.

    Examples:
        >>> dim = MonotonicDimension({'coordinates': [1.0, 2.5, 4.0, 7.0]})
        >>> dim.coordinates
        array([1. , 2.5, 4. , 7. ])
        >>> dim.count
        4
    """

    def __init__(self, coordinates, label=None, description=None, application=None,
                 quantity_name=None, coordinates_offset=None, origin_offset=None,
                 period=None, scaling=DimensionScaling.NONE, reciprocal=None, **kwargs):
        """
        Initialize monotonic dimension.

        C API Requirements (SIMonotonicDimensionCreate):
        - coordinates: REQUIRED array of coordinate values (≥2 elements required)
        - All other parameters: OPTIONAL (function provides defaults)

        Args:
            coordinates (list, REQUIRED): List of coordinate values (≥2 elements required)
            label (str, optional): Short label for the dimension
            description (str, optional): Description of the dimension
            application (dict, optional): Application metadata
            quantity_name (str, optional): Physical quantity name (e.g., "time", "frequency")
            coordinates_offset (str or Scalar, optional): SIScalar coordinates offset value
            origin_offset (str or Scalar, optional): SIScalar origin offset value
            period (str or Scalar, optional): SIScalar period value for periodic dimensions
            scaling (DimensionScaling or int, optional): Dimension scaling type
                (default: DimensionScaling.NONE). Use DimensionScaling.NONE or DimensionScaling.NMR
            reciprocal (SIDimension, optional): Reciprocal dimension
            **kwargs: Additional keyword arguments (for compatibility)

        Raises:
            RMNError: If coordinates array has <2 elements or conversion fails
            RMNError: If coordinates is empty or None

        Examples:
            # Basic monotonic dimension (coordinates required)
            >>> dim = MonotonicDimension([1.0, 2.5, 4.0, 7.0])

            # With metadata
            >>> dim = MonotonicDimension(
            ...     [0.0, 1.5, 3.2, 5.1, 8.0],
            ...     label='time',
            ...     description='Acquisition time points'
            ... )
        """
        # Convert coordinates to OCArray of SIScalar objects (C API expects SIScalarRef, not OCNumbers)
        cdef OCStringRef err_ocstr = NULL
        cdef OCMutableArrayRef coords_array = OCArrayCreateMutable(0, &kOCTypeArrayCallBacks)
        cdef OCStringRef label_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(label)
        cdef OCStringRef desc_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(description)
        cdef OCDictionaryRef application_ocdict = <OCDictionaryRef><uint64_t>ocdict_create_from_pydict(application)
        cdef OCStringRef quantity_name_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(quantity_name)
        cdef SIScalarRef coordinates_offset_sisclr = NULL
        cdef SIScalarRef origin_offset_sisclr = NULL
        cdef SIScalarRef period_sisclr = NULL
        cdef SIDimensionRef reciprocal_ref = NULL
        cdef SIScalarRef coord_scalar = NULL

        # Convert each coordinate to an SIScalar object using the helper function
        for coord_value in coordinates:
            coord_scalar = convert_to_siscalar_ref(coord_value)
            if coord_scalar == NULL:
                OCRelease(<OCTypeRef>coords_array)
                raise RMNError(f"Failed to create SIScalar for coordinate value {coord_value}")

            OCArrayAppendValue(coords_array, <const void*>coord_scalar)
            OCRelease(<OCTypeRef>coord_scalar)  # Release our reference, array retains it

        # Validate scaling parameter
        if scaling is not None:
            if isinstance(scaling, int):
                if scaling not in [DimensionScaling.NONE, DimensionScaling.NMR]:
                    raise ValueError(f"Invalid scaling value {scaling}. Use DimensionScaling.NONE (0) or DimensionScaling.NMR (1)")
            elif isinstance(scaling, DimensionScaling):
                scaling = int(scaling)  # Convert enum to int for C API
            else:
                raise TypeError(f"scaling must be DimensionScaling enum or int, got {type(scaling)}")

        # Convert coordinates_offset parameter to SIScalar if provided
        if coordinates_offset is not None:
            coordinates_offset_sisclr = convert_to_siscalar_ref(coordinates_offset)

        # Convert origin_offset parameter to SIScalar if provided
        if origin_offset is not None:
            origin_offset_sisclr = convert_to_siscalar_ref(origin_offset)

        # Convert period parameter to SIScalar if provided
        if period is not None:
            period_sisclr = convert_to_siscalar_ref(period)

        # Convert reciprocal parameter to SIDimensionRef if provided
        if reciprocal is not None:
            if hasattr(reciprocal, '_c_ref'):
                reciprocal_ref = <SIDimensionRef>(<SIDimension>reciprocal)._c_ref
            else:
                reciprocal_ref = NULL

        try:
            # Create dimension with proper parameter passing to match C API exactly
            monotonic_dimension = SIMonotonicDimensionCreate(
                label_ocstr,              # label
                desc_ocstr,               # description
                application_ocdict,       # metadata (application)
                quantity_name_ocstr,      # quantityName
                coordinates_offset_sisclr, # offset (coordinates_offset)
                origin_offset_sisclr,     # origin (origin_offset)
                period_sisclr,            # period
                scaling,                  # scaling
                <OCArrayRef>coords_array, # coordinates (REQUIRED)
                reciprocal_ref,           # reciprocal
                &err_ocstr                # outError
            )
            if monotonic_dimension == NULL:
                if err_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>err_ocstr)
                    raise RMNError(f"Failed to create monotonic dimension: {error_msg}")
                else:
                    raise RMNError("Failed to create monotonic dimension")

            # Cast to base dimension reference
            self._c_ref = <DimensionRef>monotonic_dimension

        finally:
            if label_ocstr != NULL:
                OCRelease(<OCTypeRef>label_ocstr)
            if desc_ocstr != NULL:
                OCRelease(<OCTypeRef>desc_ocstr)
            if application_ocdict != NULL:
                OCRelease(<OCTypeRef>application_ocdict)
            if quantity_name_ocstr != NULL:
                OCRelease(<OCTypeRef>quantity_name_ocstr)
            if coords_array != NULL:
                OCRelease(<OCTypeRef>coords_array)
            if err_ocstr != NULL:
                OCRelease(<OCTypeRef>err_ocstr)

    @property
    def reciprocal(self):
        """Get reciprocal dimension."""
        reciprocal_ref = SIMonotonicDimensionCopyReciprocal(<SIMonotonicDimensionRef>self._c_ref)
        if reciprocal_ref != NULL:
            return BaseDimension._from_c_ref(<DimensionRef>reciprocal_ref)
        raise RMNError("C API returned NULL reciprocal dimension (dimension may be corrupted or uninitialized)")

    @reciprocal.setter
    def reciprocal(self, value):
        """Set reciprocal dimension."""
        cdef OCStringRef err_ocstr = NULL
        cdef SIDimensionRef reciprocal_ref = NULL

        # Update C dimension object
        if value is not None:
            if hasattr(value, '_c_ref'):
                reciprocal_ref = <SIDimensionRef>(<SIDimension>value)._c_ref
            else:
                reciprocal_ref = NULL

        if not SIMonotonicDimensionSetReciprocal(<SIMonotonicDimensionRef>self._c_ref, reciprocal_ref, &err_ocstr):
            if err_ocstr != NULL:
                error_msg = ocstring_to_pystring(<uint64_t>err_ocstr)
                OCRelease(<OCTypeRef>err_ocstr)
                raise RMNError(f"Failed to set reciprocal dimension: {error_msg}")
            else:
                raise RMNError("Failed to set reciprocal dimension")
