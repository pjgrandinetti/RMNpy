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

from rmnpy.exceptions import RMNError
from rmnpy.helpers.octypes import (
    ocarray_create_from_pylist,
    ocarray_to_pylist,
    ocdict_create_from_pydict,
    ocdict_to_pydict,
)

# Import base wrapper classes
from rmnpy.wrappers.base_wrapper cimport RMNLibWrapper

# Import SITypes wrappers
from rmnpy.wrappers.sitypes.scalar cimport Scalar, create_siscalar_from_pytype
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

    # Base class handles __cinit__ and __dealloc__

    # Implement required base class methods

    cdef void* copy_c_ref(self) except NULL:
        """Create a copy of the C reference."""
        self._validate_initialized()
        cdef DatumRef copied = DatumCopy(<DatumRef>self._c_ref)
        if copied == NULL:
            raise RMNError("Failed to copy datum reference")
        return <void*>copied

    @staticmethod
    cdef Datum _from_c_ref(DatumRef datum_ref):
        """Create Datum wrapper from C reference (internal use)."""
        cdef Datum result = Datum.__new__(Datum)
        if datum_ref == NULL:
            raise RMNError("Cannot create wrapper from NULL datum reference")

        cdef DatumRef copied_ref = DatumCopy(datum_ref)
        if copied_ref == NULL:
            raise RMNError("Failed to create copy of Datum")

        result._set_c_ref(<void*>copied_ref)
        return result

    @staticmethod
    def from_c_ref(uint64_t datum_ref_ptr):
        """Create Datum wrapper from C reference pointer (Python-accessible)."""
        return Datum._from_c_ref(<DatumRef>datum_ref_ptr)

    def __init__(self, response, dependent_variable_index=0,
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
        if self._is_initialized():
            return  # Already initialized by _from_c_ref

        cdef SIScalarRef response_ref = NULL
        cdef OCStringRef error = NULL
        cdef DatumRef datum_ref = NULL

        try:
            # Convert response scalar
            response_ref = create_siscalar_from_pytype(response)
            if response_ref == NULL:
                raise RMNError("Failed to convert response to SIScalar")

            # Validate indices
            if not isinstance(dependent_variable_index, int) or dependent_variable_index < 0:
                raise TypeError("dependent_variable_index must be a non-negative integer")
            if not isinstance(component_index, int) or component_index < 0:
                raise TypeError("component_index must be a non-negative integer")
            if not isinstance(mem_offset, int) or mem_offset < 0:
                raise TypeError("mem_offset must be a non-negative integer")

            # Create the datum with error handling
            datum_ref = DatumCreate(
                response_ref,
                <OCIndex>dependent_variable_index,
                <OCIndex>component_index,
                <OCIndex>mem_offset,
                <OCTypeRef>NULL,  # owner - NULL for standalone datums
                &error
            )
            if datum_ref == NULL:
                error_msg = "Datum creation failed"
                if error != NULL:
                    error_msg = f"Datum creation failed: {OCStringGetCString(error)}"
                    OCRelease(error)
                raise RMNError(error_msg)

            self._set_c_ref(<void*>datum_ref)

        finally:
            # Clean up the response reference created by helper function
            if response_ref != NULL:
                OCRelease(<OCTypeRef>response_ref)


    # Property accessors

    @property
    def response(self):
        """Get the response scalar."""
        self._validate_initialized()

        cdef SIScalarRef response_ref = DatumCreateResponse(<DatumRef><DatumRef>self._c_ref)
        if response_ref == NULL:
            raise RMNError("Failed to get response scalar")

        try:
            return Scalar._from_c_ref(response_ref)
        finally:
            # DatumCreateResponse creates a copy, so we need to release it
            OCRelease(<OCTypeRef>response_ref)

    @property
    def dependent_variable_index(self):
        """Get the dependent variable index."""
        self._validate_initialized()

        cdef OCIndex index = DatumGetDependentVariableIndex(<DatumRef>self._c_ref)
        if index == kOCNotFound:
            raise RMNError("Failed to get dependent variable index")
        return <int>index

    @dependent_variable_index.setter
    def dependent_variable_index(self, value):
        """Set the dependent variable index."""
        self._validate_initialized()

        if not isinstance(value, int) or value < 0:
            raise TypeError("dependent_variable_index must be a non-negative integer")

        DatumSetDependentVariableIndex(<DatumRef>self._c_ref, <OCIndex>value)

    @property
    def component_index(self):
        """Get the component index."""
        self._validate_initialized()

        cdef OCIndex index = DatumGetComponentIndex(<DatumRef>self._c_ref)
        if index == kOCNotFound:
            raise RMNError("Failed to get component index")
        return <int>index

    @component_index.setter
    def component_index(self, value):
        """Set the component index."""
        self._validate_initialized()

        if not isinstance(value, int) or value < 0:
            raise TypeError("component_index must be a non-negative integer")

        DatumSetComponentIndex(<DatumRef>self._c_ref, <OCIndex>value)

    @property
    def mem_offset(self):
        """Get the memory offset."""
        self._validate_initialized()

        cdef OCIndex offset = DatumGetMemOffset(<DatumRef>self._c_ref)
        if offset == kOCNotFound:
            raise RMNError("Failed to get memory offset")
        return <int>offset

    @mem_offset.setter
    def mem_offset(self, value):
        """Set the memory offset."""
        self._validate_initialized()

        if not isinstance(value, int) or value < 0:
            raise TypeError("mem_offset must be a non-negative integer")

        DatumSetMemOffset(<DatumRef>self._c_ref, <OCIndex>value)

    @property
    def coordinates_count(self):
        """Get the number of coordinate scalars."""
        self._validate_initialized()

        return <int>DatumCoordinatesCount(<DatumRef>self._c_ref)

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

        return DatumHasSameReducedDimensionalities(<DatumRef>self._c_ref, (<Datum>other)._c_ref)

    # Implement comparison for RMNLibWrapper
    cdef int _compare_c_api(self, other) except? -999:
        """Compare with another Datum instance using C API."""
        if not isinstance(other, Datum):
            raise TypeError("Can only compare with another Datum")

        # For now, implement basic equality comparison
        # Could be extended for ordering if needed
        cdef Datum other_datum = <Datum>other

        # Compare basic properties
        if (self.dependent_variable_index != other_datum.dependent_variable_index or
            self.component_index != other_datum.component_index or
            self.mem_offset != other_datum.mem_offset):
            return -1 if self.dependent_variable_index < other_datum.dependent_variable_index else 1

        # Compare responses (this will need proper scalar comparison)
        try:
            if self.response == other_datum.response:
                return 0
            else:
                return -1  # Could implement proper ordering later
        except:
            return -1

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

        cdef OCIndex count = DatumCoordinatesCount(<DatumRef>self._c_ref)
        if index >= count:
            raise IndexError(f"Coordinate index {index} out of range (0-{count-1})")

        cdef SIScalarRef coord_ref = DatumGetCoordinateAtIndex(<DatumRef>self._c_ref, <OCIndex>index)
        if coord_ref == NULL:
            raise RMNError(f"Failed to get coordinate at index {index}")

        return Scalar._from_c_ref(coord_ref)

    # Serialization methods are inherited from RMNLibWrapper

    @classmethod
    def from_dict(cls, json_dict):
        """Create Datum from dictionary representation."""
        if not isinstance(json_dict, dict):
            raise TypeError("Expected dictionary input")

        # Convert Python dict to cJSON
        cdef uint64_t cjson_addr = pydict_to_cjson_ptr(json_dict)
        if cjson_addr == 0:
            raise RMNError("Failed to convert dictionary to JSON")

        cdef cJSON* json_obj = <cJSON*>cjson_addr
        cdef OCStringRef error = NULL
        cdef DatumRef datum_ref = NULL
        cdef const char* error_str

        try:
            datum_ref = DatumCreateFromJSON(json_obj, &error)
            if datum_ref == NULL:
                if error != NULL:
                    # Extract error message from OCString
                    error_str = OCStringGetCString(error)
                    error_msg = error_str.decode('utf-8') if error_str else "Unknown error"
                    OCRelease(<OCTypeRef>error)
                    raise RMNError(f"Failed to create Datum from JSON: {error_msg}")
                else:
                    raise RMNError("Failed to create Datum from JSON")

            # Create Python wrapper using existing _from_c_ref method
            return cls._from_c_ref(datum_ref)

        finally:
            if datum_ref != NULL:
                OCRelease(<OCTypeRef>datum_ref)
            if json_obj != NULL:
                cJSON_Delete(json_obj)
            if error != NULL:
                OCRelease(<OCTypeRef>error)

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
