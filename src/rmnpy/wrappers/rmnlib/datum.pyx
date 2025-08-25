# cython: language_level=3
"""
RMNLib Datum wrapper

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

# Import SITypes wrappers
from rmnpy.wrappers.sitypes.scalar cimport Scalar, convert_to_siscalar_ref
from rmnpy.wrappers.sitypes.scalar import Scalar


cdef class Datum:
    """
    Python wrapper for RMNLib Datum.

    A Datum represents a single data point in an N-dimensional dataset with:
    - Response: The primary scalar measurement value
    - Coordinates: Array of coordinate scalars representing position in N-D space
    - Indices: Three integer indices for tracking within datasets
      * dependent_variable_index: Index of parent DependentVariable
      * component_index: Index within DependentVariable components
      * mem_offset: Raw memory offset for internal use

    All scalar values are stored as SIScalar objects with proper units.
    """

    def __cinit__(self):
        """Initialize C-level attributes."""
        self._c_ref = NULL

    def __dealloc__(self):
        """Clean up C resources."""
        if self._c_ref != NULL:
            OCRelease(self._c_ref)

    @staticmethod
    cdef Datum _from_c_ref(DatumRef datum_ref):
        """Create Datum wrapper from C reference (internal use).

        Creates a copy of the datum reference, so caller retains ownership
        of their original reference and can safely release it.
        """
        cdef Datum result = Datum.__new__(Datum)
        if datum_ref == NULL:
            raise RMNError("Cannot create wrapper from NULL datum reference")

        cdef DatumRef copied_ref = DatumCopy(datum_ref)
        if copied_ref == NULL:
            raise RMNError("Failed to create copy of Datum")
        result._c_ref = copied_ref
        return result

    @staticmethod
    def from_c_ref(uint64_t datum_ref_ptr):
        """Create Datum wrapper from C reference pointer (Python-accessible)."""
        return Datum._from_c_ref(<DatumRef>datum_ref_ptr)

    def __init__(self, response, coordinates=None, dependent_variable_index=0,
                 component_index=0, mem_offset=0):
        """
        Create a new Datum.

        Parameters:
            response : Scalar or numeric
                The primary scalar measurement value
            coordinates : list of Scalar or numeric, optional
                Array of coordinate scalars representing position in N-D space
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
        if self._c_ref != NULL:
            return  # Already initialized by _from_c_ref

        cdef SIScalarRef response_ref = NULL
        cdef OCArrayRef coords_ref = NULL
        cdef list coord_refs = []

        try:
            # Convert response scalar
            response_ref = convert_to_siscalar_ref(response)
            if response_ref == NULL:
                raise RMNError("Failed to convert response to SIScalar")

            # Convert coordinates if provided
            if coordinates is not None:
                if not isinstance(coordinates, (list, tuple)):
                    raise TypeError("coordinates must be a list or tuple")

            # Convert each coordinate to SIScalar and collect references
            for i, coord in enumerate(coordinates):
                coord_ref = convert_to_siscalar_ref(coord)
                if coord_ref == NULL:
                    raise RMNError(f"Failed to convert coordinate[{i}] to SIScalar")
                coord_refs.append(<uint64_t>coord_ref)                # Create OCArray from coordinate references
                if coord_refs:
                    coords_ref = <OCArrayRef><uint64_t>ocarray_create_from_pylist(coord_refs)
                    if coords_ref == NULL:
                        raise RMNError("Failed to create coordinates array")

            # Validate indices
            if not isinstance(dependent_variable_index, int) or dependent_variable_index < 0:
                raise TypeError("dependent_variable_index must be a non-negative integer")
            if not isinstance(component_index, int) or component_index < 0:
                raise TypeError("component_index must be a non-negative integer")
            if not isinstance(mem_offset, int) or mem_offset < 0:
                raise TypeError("mem_offset must be a non-negative integer")

            # Create the datum
            self._c_ref = DatumCreate(
                response_ref,
                coords_ref,
                <OCIndex>dependent_variable_index,
                <OCIndex>component_index,
                <OCIndex>mem_offset
            )
            if self._c_ref == NULL:
                raise RMNError("Datum creation failed")

        finally:
            # Note: response_ref and coord_refs are references to converted scalars
            # We don't release them here as they may be borrowed from input objects
            if coords_ref != NULL:
                OCRelease(<OCTypeRef>coords_ref)

    # @classmethod  # TODO: Fix compilation issues with _from_c_ref
    # def from_dict(cls, data_dict):
    #     """
    #     Create Datum from dictionary representation.
    #
    #     Parameters:
    #         data_dict : dict
    #             Dictionary containing datum data
    #
    #     Returns:
    #         Datum: New datum instance
    #
    #     Raises:
    #         RMNError: If datum creation from dictionary fails
    #         TypeError: If data_dict is not a dictionary
    #     """
    #     if not isinstance(data_dict, dict):
    #         raise TypeError("data_dict must be a dictionary")
    #
    #     cdef OCDictionaryRef dict_ref = NULL
    #     cdef OCStringRef err_ocstr = NULL
    #     cdef DatumRef datum_ref = NULL
    #
    #     try:
    #         # Convert Python dictionary to OCDictionary
    #         dict_ref = <OCDictionaryRef><uint64_t>ocdict_create_from_pydict(data_dict)
    #         if dict_ref == NULL:
    #             raise RMNError("Failed to convert dictionary to OCDictionary")
    #
    #         # Create datum from dictionary
    #         datum_ref = DatumCreateFromDictionary(dict_ref, &err_ocstr)
    #         if datum_ref == NULL:
    #             error_msg = "Unknown error"
    #             if err_ocstr != NULL:
    #                 from rmnpy.helpers.octypes import ocstring_to_pystring
    #                 error_msg = ocstring_to_pystring(<uint64_t>err_ocstr)
    #             raise RMNError(f"Datum creation from dictionary failed: {error_msg}")
    #
    #         # Create wrapper from C reference
    #         return cls._from_c_ref(<DatumRef>datum_ref)
    #
    #     finally:
    #         # Clean up temporary references
    #         if dict_ref != NULL:
    #             OCRelease(<OCTypeRef>dict_ref)
    #         if err_ocstr != NULL:
    #             OCRelease(<OCTypeRef>err_ocstr)
    #         if datum_ref != NULL:
    #             OCRelease(<OCTypeRef>datum_ref)

    # Property accessors

    @property
    def response(self):
        """Get the response scalar."""
        if self._c_ref == NULL:
            raise ValueError("Datum not initialized")

        cdef SIScalarRef response_ref = DatumCreateResponse(self._c_ref)
        if response_ref == NULL:
            raise RMNError("Failed to get response scalar")

        try:
            return Scalar._from_c_ref(response_ref)
        finally:
            # DatumCreateResponse creates a copy, so we need to release it
            OCRelease(<OCTypeRef>response_ref)

    @property
    def coordinates(self):
        """Get the list of coordinate scalars."""
        if self._c_ref == NULL:
            raise ValueError("Datum not initialized")

        cdef OCIndex count = DatumCoordinatesCount(self._c_ref)
        cdef list result = []
        cdef SIScalarRef coord_ref

        for i in range(count):
            coord_ref = DatumGetCoordinateAtIndex(self._c_ref, i)
            if coord_ref != NULL:
                # DatumGetCoordinateAtIndex returns a borrowed reference
                # We need to create a wrapper from it
                coord_wrapper = Scalar._from_c_ref(coord_ref)
                result.append(coord_wrapper)

        return result

    @property
    def dependent_variable_index(self):
        """Get the dependent variable index."""
        if self._c_ref == NULL:
            raise ValueError("Datum not initialized")

        cdef OCIndex index = DatumGetDependentVariableIndex(self._c_ref)
        if index == kOCNotFound:
            raise RMNError("Failed to get dependent variable index")
        return <int>index

    @dependent_variable_index.setter
    def dependent_variable_index(self, value):
        """Set the dependent variable index."""
        if self._c_ref == NULL:
            raise ValueError("Datum not initialized")

        if not isinstance(value, int) or value < 0:
            raise TypeError("dependent_variable_index must be a non-negative integer")

        DatumSetDependentVariableIndex(self._c_ref, <OCIndex>value)

    @property
    def component_index(self):
        """Get the component index."""
        if self._c_ref == NULL:
            raise ValueError("Datum not initialized")

        cdef OCIndex index = DatumGetComponentIndex(self._c_ref)
        if index == kOCNotFound:
            raise RMNError("Failed to get component index")
        return <int>index

    @component_index.setter
    def component_index(self, value):
        """Set the component index."""
        if self._c_ref == NULL:
            raise ValueError("Datum not initialized")

        if not isinstance(value, int) or value < 0:
            raise TypeError("component_index must be a non-negative integer")

        DatumSetComponentIndex(self._c_ref, <OCIndex>value)

    @property
    def mem_offset(self):
        """Get the memory offset."""
        if self._c_ref == NULL:
            raise ValueError("Datum not initialized")

        cdef OCIndex offset = DatumGetMemOffset(self._c_ref)
        if offset == kOCNotFound:
            raise RMNError("Failed to get memory offset")
        return <int>offset

    @mem_offset.setter
    def mem_offset(self, value):
        """Set the memory offset."""
        if self._c_ref == NULL:
            raise ValueError("Datum not initialized")

        if not isinstance(value, int) or value < 0:
            raise TypeError("mem_offset must be a non-negative integer")

        DatumSetMemOffset(self._c_ref, <OCIndex>value)

    @property
    def coordinates_count(self):
        """Get the number of coordinate scalars."""
        if self._c_ref == NULL:
            raise ValueError("Datum not initialized")

        return <int>DatumCoordinatesCount(self._c_ref)

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

        if self._c_ref == NULL or (<Datum>other)._c_ref == NULL:
            raise ValueError("Datum not initialized")

        return DatumHasSameReducedDimensionalities(self._c_ref, (<Datum>other)._c_ref)

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
        if self._c_ref == NULL:
            raise ValueError("Datum not initialized")

        if not isinstance(index, int) or index < 0:
            raise TypeError("index must be a non-negative integer")

        cdef OCIndex count = DatumCoordinatesCount(self._c_ref)
        if index >= count:
            raise IndexError(f"Coordinate index {index} out of range (0-{count-1})")

        cdef SIScalarRef coord_ref = DatumGetCoordinateAtIndex(self._c_ref, <OCIndex>index)
        if coord_ref == NULL:
            raise RMNError(f"Failed to get coordinate at index {index}")

        return Scalar._from_c_ref(coord_ref)

    # Serialization methods

    def to_dict(self):
        """
        Convert datum to dictionary representation.

        Returns:
            dict: Dictionary representation of the datum

        Raises:
            RMNError: If conversion to dictionary fails
        """
        if self._c_ref == NULL:
            raise ValueError("Datum not initialized")

        cdef OCDictionaryRef dict_ref = DatumCopyAsDictionary(self._c_ref)
        if dict_ref == NULL:
            raise RMNError("Failed to convert datum to dictionary")

        try:
            return ocdict_to_pydict(<uint64_t>dict_ref)
        finally:
            OCRelease(<OCTypeRef>dict_ref)

    def dict(self):
        """
        Alias for to_dict() for compatibility.

        Returns:
            dict: Dictionary representation of the datum
        """
        return self.to_dict()

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

    @property
    def summary(self):
        """
        Get a summary of the datum.

        Returns:
            dict: Summary information about the datum
        """
        try:
            response = self.response
            coordinates = self.coordinates

            coord_summary = []
            for i, coord in enumerate(coordinates):
                coord_summary.append({
                    'index': i,
                    'value': str(coord)
                })

            return {
                'response': str(response),
                'coordinates_count': len(coordinates),
                'coordinates': coord_summary,
                'dependent_variable_index': self.dependent_variable_index,
                'component_index': self.component_index,
                'mem_offset': self.mem_offset
            }
        except Exception as e:
            return {'error': f"Failed to generate summary: {str(e)}"}
