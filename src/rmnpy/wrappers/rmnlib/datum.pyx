# cython: language_level=3
"""
RMNLib Datum wrapper.

Provides Python access to RMNLib Datum C API. A Datum represents a single data point
in an N-dimensional dataset, containing a scalar response value, coordinate positions,
and indexing metadata for efficient dataset organization.

The Datum class wraps:
- A scalar response (primary measurement value)
- Coordinate scalars (position in N-D space)
- Three integer indices (dependent-variable, component, memory offset)

This implementation uses the universal base wrapper system for automatic memory
management, consistent factory methods, and standardized serialization.
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
from rmnpy.wrappers.base_wrapper cimport BaseWrapper, RMNLibWrapper


cdef class Datum(RMNLibWrapper):
    """
    A single data point in an N-dimensional dataset.

    The Datum class represents one measurement in a multidimensional space, containing:

    - **Response**: The primary scalar measurement value (e.g., intensity, signal amplitude)
    - **Coordinates**: Position scalars defining location in N-dimensional space
    - **Indices**: Organizational metadata for efficient dataset management

      * dependent_variable_index: Index of parent DependentVariable
      * component_index: Index within DependentVariable components
      * mem_offset: Raw memory offset for internal optimization

    All scalar values maintain proper physical units through the SITypes system.
    Memory management, serialization, and comparison operations are handled
    automatically through the universal base wrapper system.

    Examples:
        Create a simple datum with numeric response:

        >>> datum = Datum(response=42.5)
        >>> datum.response.value
        42.5

        Create with explicit indices:

        >>> datum = Datum(
        ...     response=Scalar("100.0 Hz"),
        ...     dependent_variable_index=0,
        ...     component_index=1
        ... )

        Access coordinates (when attached to dataset):

        >>> coordinates = datum.coordinates
        >>> count = datum.coordinates_count

    Note:
        Coordinates are managed by the parent Dataset. Standalone Datums
        created directly will have empty coordinate arrays until attached
        to a Dataset that provides coordinate information.
    """

    @staticmethod
    def from_c_ref(uint64_t datum_ref_ptr):
        """Create Datum wrapper from C reference pointer."""
        return <Datum>BaseWrapper._from_c_ref(Datum, <void*><DatumRef>datum_ref_ptr)

    def __init__(self, response, dependent_variable_index=0,
                 component_index=0, mem_offset=0):
        """
        Initialize a new Datum with response value and optional indexing metadata.

        Args:
            response: Primary measurement value. Can be numeric (converted to dimensionless
                Scalar) or an existing Scalar object with units.
            dependent_variable_index: Index of parent DependentVariable in dataset (default: 0)
            component_index: Index within DependentVariable components (default: 0)
            mem_offset: Raw memory offset for internal optimization (default: 0)

        Raises:
            RMNError: If datum creation fails due to invalid response or C API error
            TypeError: If index parameters are not non-negative integers

        Note:
            Coordinates must be set separately via Dataset methods. This constructor
            creates a datum with the specified response and indices but no coordinate
            information until attached to a Dataset.
        """
        if self.is_valid():
            return

        cdef SIScalarRef response_ref = NULL
        cdef OCStringRef error = NULL
        cdef DatumRef datum_ref = NULL

        try:
            if isinstance(response, Scalar):
                response_scalar = response
            else:
                response_scalar = Scalar(response)

            response_ref = <SIScalarRef>OCTypeDeepCopy(<OCTypeRef>(<Scalar>response_scalar)._c_ref)
            if response_ref == NULL:
                raise RMNError("Failed to copy response scalar")

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
            pass

    @property
    def response(self):
        """
        The primary scalar measurement value for this datum.

        Returns:
            Scalar: The response value with appropriate units and dimensionality.

        Raises:
            RMNError: If response retrieval fails from the C API.
        """
        cdef SIScalarRef response_ref = DatumCreateResponse(<DatumRef>self._get_c_ref())
        if response_ref == NULL:
            raise RMNError("Failed to get response scalar")

        return <Scalar>BaseWrapper._from_c_ref(Scalar, <void*>response_ref)

    @property
    def dependent_variable_index(self):
        """
        Index of the parent DependentVariable in the dataset.

        Returns:
            int: Zero-based index identifying which DependentVariable owns this datum.

        Raises:
            RMNError: If index retrieval fails.
        """
        cdef OCIndex index = DatumGetDependentVariableIndex(<DatumRef>self._get_c_ref())
        if index == kOCNotFound:
            raise RMNError("Failed to get dependent variable index")
        return <int>index

    @dependent_variable_index.setter
    def dependent_variable_index(self, value):
        if not isinstance(value, int) or value < 0:
            raise TypeError("dependent_variable_index must be a non-negative integer")
        DatumSetDependentVariableIndex(<DatumRef>self._get_c_ref(), <OCIndex>value)

    @property
    def component_index(self):
        """
        Index within the DependentVariable components array.

        Returns:
            int: Zero-based index specifying which component of a multi-component
                 DependentVariable this datum belongs to.

        Raises:
            RMNError: If index retrieval fails.
        """
        cdef OCIndex index = DatumGetComponentIndex(<DatumRef>self._get_c_ref())
        if index == kOCNotFound:
            raise RMNError("Failed to get component index")
        return <int>index

    @component_index.setter
    def component_index(self, value):
        if not isinstance(value, int) or value < 0:
            raise TypeError("component_index must be a non-negative integer")
        DatumSetComponentIndex(<DatumRef>self._get_c_ref(), <OCIndex>value)

    @property
    def mem_offset(self):
        """
        Raw memory offset for internal optimization.

        Returns:
            int: Memory offset used internally by the C API for efficient
                 data access and storage management.

        Raises:
            RMNError: If offset retrieval fails.
        """
        cdef OCIndex offset = DatumGetMemOffset(<DatumRef>self._get_c_ref())
        if offset == kOCNotFound:
            raise RMNError("Failed to get memory offset")
        return <int>offset

    @mem_offset.setter
    def mem_offset(self, value):
        if not isinstance(value, int) or value < 0:
            raise TypeError("mem_offset must be a non-negative integer")

        DatumSetMemOffset(<DatumRef>self._get_c_ref(), <OCIndex>value)

    @property
    def coordinates_count(self):
        """
        Number of coordinate scalars associated with this datum.

        Returns:
            int: Count of coordinate values. Returns 0 for datums not
                 attached to a Dataset or datasets without coordinate information.
        """
        return <int>DatumCoordinatesCount(<DatumRef>self._get_c_ref())

    @property
    def coordinates(self):
        """
        All coordinate scalars defining this datum's position in N-dimensional space.

        Returns:
            list[Scalar]: Coordinate values as Scalar objects with appropriate units.
                         Empty list if datum has no coordinates (not attached to Dataset
                         or Dataset lacks coordinate information).

        Note:
            Coordinates are managed by the parent Dataset. Standalone datums created
            directly will return an empty list until attached to a Dataset that
            provides coordinate information through its dimension objects.
        """
        cdef OCIndex count = DatumCoordinatesCount(<DatumRef>self._get_c_ref())
        if count == 0:
            return []

        cdef SIScalarRef coord_ref
        cdef SIScalarRef copied_ref
        cdef OCIndex i

        coordinates = []
        for i in range(count):
            coord_ref = DatumGetCoordinateAtIndex(<DatumRef>self._get_c_ref(), i)
            if coord_ref != NULL:
                copied_ref = <SIScalarRef>OCTypeDeepCopy(<OCTypeRef>coord_ref)
                if copied_ref != NULL:
                    coord_scalar = <Scalar>BaseWrapper._from_c_ref(Scalar, <void*>copied_ref)
                    coordinates.append(coord_scalar)
        return coordinates

    def has_same_reduced_dimensionalities(self, other):
        """
        Compare reduced dimensionalities with another datum.

        Checks whether this datum and another have the same reduced dimensionalities
        for both response and coordinate values. This is useful for determining
        compatibility between datums in mathematical operations.

        Args:
            other: Another Datum instance to compare against.

        Returns:
            bool: True if both datums have matching reduced dimensionalities,
                  False otherwise.

        Raises:
            TypeError: If other is not a Datum instance.
        """
        if not isinstance(other, Datum):
            raise TypeError("other must be a Datum instance")
        return DatumHasSameReducedDimensionalities(<DatumRef>self._get_c_ref(), (<Datum>other)._get_c_ref())

    def get_coordinate(self, index):
        """
        Retrieve a specific coordinate scalar by its index position.

        Args:
            index: Zero-based index of the coordinate to retrieve.

        Returns:
            Scalar: The coordinate value at the specified index with appropriate units.

        Raises:
            TypeError: If index is not a non-negative integer.
            IndexError: If index is out of range for available coordinates.
            RMNError: If coordinate retrieval fails from the C API.

        Note:
            This method only works for datums attached to a Dataset with coordinate
            information. Standalone datums will raise IndexError since they have
            no coordinates.
        """
        if not isinstance(index, int) or index < 0:
            raise TypeError("index must be a non-negative integer")

        cdef OCIndex count = DatumCoordinatesCount(<DatumRef>self._get_c_ref())
        if count == 0 or index >= count:
            raise IndexError(f"Coordinate index {index} out of range (0-{count-1})")

        cdef SIScalarRef coord_ref = DatumGetCoordinateAtIndex(<DatumRef>self._get_c_ref(), <OCIndex>index)
        if coord_ref == NULL:
            raise RMNError(f"Failed to get coordinate at index {index}")

        cdef SIScalarRef copied_ref = <SIScalarRef>OCTypeDeepCopy(<OCTypeRef>coord_ref)
        if copied_ref == NULL:
            raise RMNError(f"Failed to copy coordinate at index {index}")

        return <Scalar>BaseWrapper._from_c_ref(Scalar, <void*>copied_ref)

    @classmethod
    def from_dict(cls, data_dict):
        """
        Create a Datum instance from its dictionary representation.

        Uses efficient JSON-based deserialization through the C API to reconstruct
        a Datum object from a dictionary containing response, indices, and optionally
        coordinate information.

        Args:
            data_dict: Dictionary containing datum data in the format produced
                      by the to_dict() method.

        Returns:
            Datum: New Datum instance with data from the dictionary.

        Raises:
            TypeError: If data_dict is not a dictionary.
            RMNError: If datum creation fails due to invalid data or C API error.

        Note:
            This method creates datums with coordinate information if present in
            the dictionary. However, coordinates are typically managed by the
            parent Dataset rather than individual datums.
        """
        if not isinstance(data_dict, dict):
            raise TypeError("Expected dictionary input")

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

            return <Datum>BaseWrapper._from_c_ref(Datum, <void*>datum_ref)

        finally:
            if error != NULL:
                OCRelease(<OCTypeRef>error)
            if json_obj != NULL:
                cJSON_Delete(json_obj)

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
            return f"Datum(at {hex(id(self))})"

    def __str__(self):
        return self.__repr__()
