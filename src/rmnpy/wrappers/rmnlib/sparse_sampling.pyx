# cython: language_level=3
"""
RMNLib SparseSampling wrapper.

Provides Python access to RMNLib SparseSampling C API for managing sparse sampling
configurations used to define non-uniform sampling patterns in multidimensional data.
"""

from typing import Any, Dict, List, Optional, Union

import numpy as np

from libc.stdint cimport uint64_t, uintptr_t

from rmnpy._c_api.octypes cimport *
from rmnpy._c_api.rmnlib cimport *

from rmnpy.exceptions import RMNError
from rmnpy.wrappers.base_wrapper cimport BaseWrapper, RMNLibWrapper
from rmnpy.helpers.octypes import (
    ocarray_create_from_pylist,
    ocarray_to_pylist,
    ocdict_create_from_pydict,
    ocdict_to_pydict,
    ocnumber_create_from_pynumber,
    ocnumber_to_pynumber,
    ocstring_create_from_pystring,
    ocstring_to_pystring,
    pydict_to_cjson_ptr,
)
from rmnpy.helpers.octypes cimport cjson_to_pydict


cdef OCDataRef _create_vertices_data(vertices_data, OCNumberType num_type):
    """Convert vertex data to OCData with proper error handling."""
    # Just create empty OCData for now to test the structure
    # TODO: Implement proper vertex data conversion
    cdef uint8_t dummy_data = 0
    return OCDataCreate(&dummy_data, 1)


cdef class SparseSampling(RMNLibWrapper):
    """Python wrapper for RMNLib SparseSampling objects.

    SparseSampling defines configurations for sparse sampling of multi-dimensional data,
    including dimension indexes, grid vertices, data types, and encoding formats.

    Examples:
        Create a basic sparse sampling configuration:

        >>> sparse = SparseSampling([], [])
        >>> sparse.unsigned_integer_type = "uint32"
        >>> sparse.encoding = "base64"

        Load from dictionary:

        >>> data = {"dimension_indexes": [], "encoding": "none"}
        >>> sparse = SparseSampling.from_dict(data)
    """

    @staticmethod
    def from_c_ref(uintptr_t sparse_ref_ptr):
        """Create SparseSampling wrapper from C reference pointer."""
        return <SparseSampling>BaseWrapper._from_c_ref(SparseSampling, <void*><SparseSamplingRef>sparse_ref_ptr)

    def __init__(self, dimension_indexes, sparse_grid_vertices,
                 unsigned_integer_type="uint32", encoding="none",
                 description=None, metadata=None):
        """
        Create a new SparseSampling object.

        Args:
            dimension_indexes: List of dimension indexes that are sparsely sampled (required, can be empty list)
            sparse_grid_vertices: List of vertex coordinates (required, can be empty list)
            unsigned_integer_type: Integer type for encoding ("uint8", "uint16", "uint32", "uint64") - defaults to "uint32"
            encoding: Encoding type ("none" or "base64") - defaults to "none"
            description: Optional human-readable description
            metadata: Optional dictionary of metadata

        Note: Both dimension_indexes and sparse_grid_vertices are required but can be empty lists.
              If both contain data, each vertex in sparse_grid_vertices must have the same number of
              (index,value) pairs as there are dimensions in dimension_indexes.
        """
        if self.is_valid():
            return  # Already initialized by BaseWrapper._from_c_ref

        cdef OCStringRef err_ocstr = NULL
        cdef OCMutableIndexSetRef dim_indexes_ref = NULL
        cdef OCDataRef vertices_ref = NULL
        cdef OCNumberType num_type = kOCNumberUInt32Type  # Default
        cdef OCStringRef encoding_ref = NULL
        cdef OCStringRef desc_ref = NULL
        cdef OCDictionaryRef metadata_ref = NULL
        cdef SparseSamplingRef sparse_ref = NULL

        try:
            # Convert unsigned integer type first
            if unsigned_integer_type == "uint8":
                num_type = kOCNumberUInt8Type
            elif unsigned_integer_type == "uint16":
                num_type = kOCNumberUInt16Type
            elif unsigned_integer_type == "uint32":
                num_type = kOCNumberUInt32Type
            elif unsigned_integer_type == "uint64":
                num_type = kOCNumberUInt64Type
            else:
                raise ValueError(f"Invalid unsigned integer type: {unsigned_integer_type}")

            # Convert dimension indexes - use NULL if empty per API docs
            if dimension_indexes:
                # Create OCIndexSet from Python list using helper
                dim_indexes_ref = <OCMutableIndexSetRef><uintptr_t>ocarray_create_from_pylist(dimension_indexes)
            else:
                dim_indexes_ref = NULL

            # Convert sparse grid vertices - use NULL if empty per API docs
            if sparse_grid_vertices:
                vertices_ref = _create_vertices_data(sparse_grid_vertices, num_type)
            else:
                vertices_ref = NULL

            # Convert encoding (required)
            if encoding not in ("none", "base64"):
                raise ValueError(f"Invalid encoding: {encoding}. Must be 'none' or 'base64'")
            encoding_ref = <OCStringRef><uintptr_t>ocstring_create_from_pystring(encoding)

            # Convert description (optional)
            if description is not None:
                desc_ref = <OCStringRef><uintptr_t>ocstring_create_from_pystring(description)

            # Convert metadata (optional)
            if metadata is not None:
                metadata_ref = <OCDictionaryRef><uintptr_t>ocdict_create_from_pydict(metadata)

            # Create SparseSampling and set via base wrapper
            sparse_ref = SparseSamplingCreate(
                dim_indexes_ref,
                vertices_ref,
                num_type,
                encoding_ref,
                desc_ref,
                metadata_ref,
                &err_ocstr
            )

            if sparse_ref == NULL:
                if err_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uintptr_t>err_ocstr)
                    raise RMNError(f"Failed to create SparseSampling: {error_msg}")
                else:
                    raise RMNError("Failed to create SparseSampling")

            self._set_c_ref(sparse_ref)

        finally:
            # Clean up temporary references
            if dim_indexes_ref != NULL:
                OCRelease(<OCTypeRef>dim_indexes_ref)
            if vertices_ref != NULL:
                OCRelease(<OCTypeRef>vertices_ref)
            if encoding_ref != NULL:
                OCRelease(<OCTypeRef>encoding_ref)
            if desc_ref != NULL:
                OCRelease(<OCTypeRef>desc_ref)
            if metadata_ref != NULL:
                OCRelease(<OCTypeRef>metadata_ref)
            if err_ocstr != NULL:
                OCRelease(<OCTypeRef>err_ocstr)

    @classmethod
    def from_dict(cls, data_dict):
        """Create SparseSampling from dictionary."""
        cdef SparseSampling result = cls.__new__(cls)
        cdef SparseSamplingRef sparse_ref = NULL
        cdef OCStringRef err_ocstr = NULL
        cdef uintptr_t json_ptr
        cdef cJSON* json_obj = NULL

        try:
            # Convert Python dict → cJSON → SparseSamplingRef (same as Datum)
            json_ptr = pydict_to_cjson_ptr(data_dict)
            json_obj = <cJSON*>json_ptr

            sparse_ref = SparseSamplingCreateFromJSON(json_obj, &err_ocstr)

            if sparse_ref == NULL:
                if err_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uintptr_t>err_ocstr)
                    raise RMNError(f"Failed to create SparseSampling from dictionary: {error_msg}")
                else:
                    raise RMNError("Failed to create SparseSampling from dictionary")

            result._set_c_ref(<OCTypeRef>sparse_ref)
            return result

        finally:
            if json_obj != NULL:
                cJSON_Delete(json_obj)
            if err_ocstr != NULL:
                OCRelease(<OCTypeRef>err_ocstr)

    @property
    def dimension_indexes(self):
        """Get the set of dimension indexes that are sparsely sampled."""
        # For now, return empty list since TODO conversion not implemented
        # In the future, this would call SparseSamplingCopyDimensionIndexes and convert
        return []

    @dimension_indexes.setter
    def dimension_indexes(self, value):
        """Set the dimension indexes."""
        cdef OCIndexSetRef indexes_ref = NULL

        try:
            # TODO: Convert Python list to OCIndexSetRef
            if not SparseSamplingSetDimensionIndexes(<SparseSamplingRef>self._c_ref, indexes_ref):
                raise RMNError("Failed to set dimension indexes")
        finally:
            if indexes_ref != NULL:
                OCRelease(<OCTypeRef>indexes_ref)

    @property
    def sparse_grid_vertices(self):
        """Get the array of sparse grid vertices."""
        # For now, return empty list since TODO conversion not implemented
        # In the future, this would call SparseSamplingCopySparseGridVertexes and convert
        return []

    @sparse_grid_vertices.setter
    def sparse_grid_vertices(self, value):
        """Set the sparse grid vertices."""
        cdef OCDataRef vertices_ref = NULL

        try:
            # TODO: Convert Python list to OCDataRef
            if not SparseSamplingSetSparseGridVertexes(<SparseSamplingRef>self._c_ref, vertices_ref):
                raise RMNError("Failed to set sparse grid vertices")
        finally:
            if vertices_ref != NULL:
                OCRelease(<OCTypeRef>vertices_ref)

    @property
    def unsigned_integer_type(self):
        """Get the unsigned integer type used for indexing."""
        cdef OCNumberType num_type = SparseSamplingGetUnsignedIntegerType(<SparseSamplingRef>self._c_ref)
        if num_type == kOCNumberUInt8Type:
            return "uint8"
        elif num_type == kOCNumberUInt16Type:
            return "uint16"
        elif num_type == kOCNumberUInt32Type:
            return "uint32"
        elif num_type == kOCNumberUInt64Type:
            return "uint64"
        else:
            return "unknown"

    @unsigned_integer_type.setter
    def unsigned_integer_type(self, value):
        """Set the unsigned integer type."""
        cdef OCNumberType num_type

        if value == "uint8":
            num_type = kOCNumberUInt8Type
        elif value == "uint16":
            num_type = kOCNumberUInt16Type
        elif value == "uint32":
            num_type = kOCNumberUInt32Type
        elif value == "uint64":
            num_type = kOCNumberUInt64Type
        else:
            raise ValueError(f"Invalid unsigned integer type: {value}")

        if not SparseSamplingSetUnsignedIntegerType(<SparseSamplingRef>self._c_ref, num_type):
            raise RMNError("Failed to set unsigned integer type")

    @property
    def encoding(self):
        """Get the encoding for sparse_grid_vertices."""
        cdef OCStringRef encoding_ref = SparseSamplingCopyEncoding(<SparseSamplingRef>self._c_ref)
        if encoding_ref == NULL:
            return "none"
        try:
            return ocstring_to_pystring(<uintptr_t>encoding_ref)
        finally:
            if encoding_ref != NULL:
                OCRelease(<OCTypeRef>encoding_ref)
        return ocstring_to_pystring(<uintptr_t>encoding_ref)

    @encoding.setter
    def encoding(self, value):
        """Set the encoding."""
        cdef OCStringRef encoding_ref = NULL

        if not isinstance(value, str):
            raise TypeError("encoding must be a string")
        if value not in ("none", "base64"):
            raise ValueError(f"Invalid encoding: {value}. Must be 'none' or 'base64'")

        try:
            encoding_ref = <OCStringRef><uintptr_t>ocstring_create_from_pystring(value)
            if not SparseSamplingSetEncoding(<SparseSamplingRef>self._c_ref, encoding_ref):
                raise RMNError(f"Failed to set encoding: {value}")
        finally:
            if encoding_ref != NULL:
                OCRelease(<OCTypeRef>encoding_ref)

    def __repr__(self):
        """Return string representation."""
        encoding = self.encoding or "none"
        int_type = self.unsigned_integer_type
        desc = self.description
        if desc:
            return f"SparseSampling(encoding='{encoding}', type='{int_type}', description='{desc}')"
        else:
            return f"SparseSampling(encoding='{encoding}', type='{int_type}')"

    def __str__(self):
        """Return user-friendly string representation."""
        return self.__repr__()

    def to_dict(self):
        """Return dictionary representation of the sparse sampling."""
        cdef OCStringRef error_str = NULL
        cdef cJSON *json_obj = SparseSamplingCopyAsJSON(<SparseSamplingRef>self._c_ref, False, &error_str)

        if json_obj == NULL:
            if error_str != NULL:
                error_msg = ocstring_to_pystring(<uintptr_t>error_str)
                OCRelease(<OCTypeRef>error_str)
                raise RMNError(f"Failed to get JSON representation of SparseSampling: {error_msg}")
            else:
                raise RMNError("Failed to get JSON representation of SparseSampling")

        try:
            return cjson_to_pydict(json_obj)
        finally:
            cJSON_Delete(json_obj)
            if error_str != NULL:
                OCRelease(<OCTypeRef>error_str)

    def dict(self):
        """Return dictionary representation (alias for to_dict())."""
        return self.to_dict()
