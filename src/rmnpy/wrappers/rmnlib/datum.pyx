# cython: language_level=3
"""
RMNLib Datum wrapper - REFACTORED VERSION

This module provides a Python wrapper around the RMNLib Datum C API.
Datum represents a scalar sample with coordinates and indexing metadata,
essentially a "data point" in an N-dimensional dataset.

A Datum wraps:
- A scalar response (primary measurement value)
- An array of coordinate scalars (position in N-D space)
- Three integer indices (dependent-variable, component, memory offset)
"""

from typing import Dict, List, Optional, Union

from rmnpy._c_api.octypes cimport *
from rmnpy._c_api.rmnlib cimport *
from rmnpy._c_api.sitypes cimport SIScalarRef
from rmnpy.wrappers.sitypes.scalar cimport Scalar

from rmnpy.exceptions import RMNError
from rmnpy.helpers.octypes import (
    ocarray_create_from_pylist,
    ocarray_to_pylist,
    ocdict_create_from_pydict,
    ocdict_to_pydict,
    pydict_to_cjson_ptr,
)
from rmnpy.wrappers.sitypes.scalar import Scalar

# Import base wrapper classes

from rmnpy.wrappers.base_wrapper cimport BaseWrapper, RMNLibWrapper

# Import SITypes wrappers
from rmnpy.wrappers.sitypes.scalar cimport Scalar

from rmnpy.wrappers.sitypes.scalar import Scalar


cdef class Datum(RMNLibWrapper):
    """
    Python wrapper for RMNLib Datum - REFACTORED VERSION.

    A Datum represents a single data point in an N-dimensional dataset with:
    - Response: The primary scalar measurement value
    - Coordinates: Array of coordinate scalars representing position in N-D space
    - Indices: Three integer indices for tracking within datasets
      * dependent_variable_index: Index of parent DependentVariable
      * component_index: Index within DependentVariable components
      * mem_offset: Raw memory offset for internal use

    All scalar values are stored as SIScalar objects with proper units.

    This refactored version uses the base wrapper system for:
    - Automatic C reference management (__cinit__, __dealloc__)
    - Consistent factory methods (_from_c_ref, from_c_ref)
    - Standardized serialization (to_dict, from_dict)
    - Input validation and error handling
    """

    # Base class handles __cinit__, __dealloc__, and copy_c_ref via universal OCTypeDeepCopy
    # No _from_c_ref method needed - use BaseWrapper._from_c_ref directly!

    @staticmethod
    def from_c_ref(uint64_t datum_ref_ptr):
        """Create Datum wrapper from C reference pointer (Python-accessible)."""
        return <Datum>BaseWrapper._from_c_ref(Datum, <void*><DatumRef>datum_ref_ptr)

    def __init__(self, response, coordinates=None, dependent_variable_index=0,
                 component_index=0, mem_offset=0):
        """
        Create a new Datum.

        Parameters:
            response : Scalar or numeric
                The primary scalar measurement value
            dependent_variable_index : int, optional
                Index of parent DependentVariable (default: 0)
            component_index : int, optional
                Index within DependentVariable components (default: 0)
            mem_offset : int, optional
                Raw memory offset for internal use (default: 0)

        Raises:
            RMNError: If datum creation fails
            TypeError: If input parameters have incorrect types
        """
        if self.is_valid():
            return  # Already initialized by _from_c_ref

        cdef SIScalarRef response_ref = NULL
        cdef OCStringRef error = NULL
        cdef DatumRef datum_ref = NULL

        try:
            # Convert response scalar
            if isinstance(response, Scalar):
                response_scalar = response
            else:
                # Create Scalar from numeric or string
                response_scalar = Scalar(response)

            response_ref = <SIScalarRef>OCTypeDeepCopy(<OCTypeRef>(<Scalar>response_scalar)._c_ref)
            if response_ref == NULL:
                raise RMNError("Failed to copy response scalar")

            # Validate indices
            if not isinstance(dependent_variable_index, int) or dependent_variable_index < 0:
                raise TypeError("dependent_variable_index must be a non-negative integer")
            if not isinstance(component_index, int) or component_index < 0:
                raise TypeError("component_index must be a non-negative integer")
            if not isinstance(mem_offset, int) or mem_offset < 0:
                raise TypeError("mem_offset must be a non-negative integer")

            # Create the datum
            datum_ref = DatumCreate(
                response_ref,
                <OCIndex>dependent_variable_index,
                <OCIndex>component_index,
                <OCIndex>mem_offset,
                <OCTypeRef>NULL,
                &error
            )
            if datum_ref == NULL:
                error_msg = f"Datum creation failed: {OCStringGetCString(error)}"
                OCRelease(error)
                raise RMNError(error_msg)

            self._set_c_ref(<void*>datum_ref)

        finally:
            # Note: response_ref is a reference to converted scalar
            # We don't release it here as it may be borrowed from input object
            pass


    # Property accessors

    @property
    def response(self):
        """Get the response scalar."""
        self._validate_initialized()

        cdef SIScalarRef response_ref = DatumCreateResponse(<DatumRef><DatumRef>self._get_c_ref())
        if response_ref == NULL:
            raise RMNError("Failed to get response scalar")

        try:
            return Scalar.from_c_ref(<uint64_t>response_ref)
        finally:
            # DatumCreateResponse creates a copy, so we need to release it
            OCRelease(<OCTypeRef>response_ref)

    @property
    def dependent_variable_index(self):
        """Get the dependent variable index."""
        self._validate_initialized()

        cdef OCIndex index = DatumGetDependentVariableIndex(<DatumRef>self._get_c_ref())
        if index == kOCNotFound:
            raise RMNError("Failed to get dependent variable index")
        return <int>index

    @dependent_variable_index.setter
    def dependent_variable_index(self, value):
        """Set the dependent variable index."""
        self._validate_initialized()

        if not isinstance(value, int) or value < 0:
            raise TypeError("dependent_variable_index must be a non-negative integer")

        DatumSetDependentVariableIndex(<DatumRef>self._get_c_ref(), <OCIndex>value)

    @property
    def component_index(self):
        """Get the component index."""
        self._validate_initialized()

        cdef OCIndex index = DatumGetComponentIndex(<DatumRef>self._get_c_ref())
        if index == kOCNotFound:
            raise RMNError("Failed to get component index")
        return <int>index

    @component_index.setter
    def component_index(self, value):
        """Set the component index."""
        self._validate_initialized()

        if not isinstance(value, int) or value < 0:
            raise TypeError("component_index must be a non-negative integer")

        DatumSetComponentIndex(<DatumRef>self._get_c_ref(), <OCIndex>value)

    @property
    def mem_offset(self):
        """Get the memory offset."""
        self._validate_initialized()

        cdef OCIndex offset = DatumGetMemOffset(<DatumRef>self._get_c_ref())
        if offset == kOCNotFound:
            raise RMNError("Failed to get memory offset")
        return <int>offset

    @mem_offset.setter
    def mem_offset(self, value):
        """Set the memory offset."""
        self._validate_initialized()

        if not isinstance(value, int) or value < 0:
            raise TypeError("mem_offset must be a non-negative integer")

        DatumSetMemOffset(<DatumRef>self._get_c_ref(), <OCIndex>value)

    @property
    def coordinates_count(self):
        """Get the number of coordinate scalars."""
        self._validate_initialized()

        return <int>DatumCoordinatesCount(<DatumRef>self._get_c_ref())

    # Utility methods

    def has_same_reduced_dimensionalities(self, other):
        """
        Check if this Datum has the same reduced dimensionalities as another.

        Compares both response and coordinate dimensionalities.

        Parameters:
            other : Datum
                Another Datum to compare with

        Returns:
            bool: True if dimensionalities match, False otherwise

        Raises:
            TypeError: If other is not a Datum instance
        """
        if not isinstance(other, Datum):
            raise TypeError("other must be a Datum instance")

        self._validate_initialized()
        (<Datum>other)._validate_initialized()

        return DatumHasSameReducedDimensionalities(<DatumRef>self._get_c_ref(), (<Datum>other)._get_c_ref())

    # Comparison is handled by universal OCTypeEqual in BaseWrapper

    def get_coordinate(self, index):
        """
        Get a specific coordinate scalar by index.

        Parameters:
            index : int
                Zero-based coordinate index

        Returns:
            Scalar: The coordinate scalar at the specified index

        Raises:
            IndexError: If index is out of range
            RMNError: If coordinate retrieval fails
        """
        self._validate_initialized()

        if not isinstance(index, int) or index < 0:
            raise TypeError("index must be a non-negative integer")

        cdef OCIndex count = DatumCoordinatesCount(<DatumRef>self._get_c_ref())
        if index >= count:
            raise IndexError(f"Coordinate index {index} out of range (0-{count-1})")

        cdef SIScalarRef coord_ref = DatumGetCoordinateAtIndex(<DatumRef>self._get_c_ref(), <OCIndex>index)
        if coord_ref == NULL:
            raise RMNError(f"Failed to get coordinate at index {index}")

        return Scalar.from_c_ref(<uint64_t>coord_ref)

    # Universal dictionary serialization is inherited from BaseWrapper via OCTypeCopyJSON
    # Custom serialization methods are no longer needed!

    @classmethod
    def from_dict(cls, data_dict):
        """
        Create Datum from dictionary using JSON-based deserialization.

        This uses the more efficient DatumCreateFromJSON approach instead of
        the old DatumCreateFromDictionary method.
        """
        if not isinstance(data_dict, dict):
            raise TypeError("Expected dictionary input")

        # Convert Python dict → cJSON → DatumRef
        cdef uint64_t json_ptr = pydict_to_cjson_ptr(data_dict)
        cdef cJSON* json_obj = <cJSON*>json_ptr
        cdef OCStringRef error = NULL
        cdef DatumRef datum_ref = NULL

        try:
            datum_ref = DatumCreateFromJSON(json_obj, &error)
            if datum_ref == NULL:
                if error != NULL:
                    error_str = OCStringGetCString(error)
                    error_msg = error_str.decode('utf-8') if error_str else "Unknown error"
                    raise RMNError(f"Failed to create Datum from dictionary: {error_msg}")
                else:
                    raise RMNError("Failed to create Datum from dictionary")

            # Create Python wrapper
            return <Datum>BaseWrapper._from_c_ref(Datum, <void*>datum_ref)

        finally:
            if error != NULL:
                OCRelease(<OCTypeRef>error)
            if json_obj != NULL:
                cJSON_Delete(json_obj)
            # Note: datum_ref is managed by the _from_c_ref method

    # String representation

    def __repr__(self):
        """Return string representation of the datum."""
        try:
            response = self.response
            coords_count = self.coordinates_count
            dv_index = self.dependent_variable_index
            comp_index = self.component_index

            return (f"Datum(response={response}, coordinates_count={coords_count}, "
                   f"dv_index={dv_index}, comp_index={comp_index})")
        except Exception:
            # Fallback if any property access fails
            return f"Datum(at {hex(id(self))})"

    def __str__(self):
        """Return string representation of the datum."""
        return self.__repr__()
