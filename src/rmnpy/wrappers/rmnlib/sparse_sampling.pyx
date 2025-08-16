# cython: language_level=3
"""
RMNLib SparseSampling wrapper

This module provides a thin Python wrapper around the RMNLib SparseSampling C API.
SparseSampling represents non-uniform, non-Cartesian sampling layouts where data
values are only recorded at explicitly listed vertices on a subgrid.

This is essential for applications like NMR, tomography, and any domain involving
compressed or selective acquisition.
"""

from typing import Any, Dict, List, Optional, Union

import numpy as np

from rmnpy._c_api.octypes cimport *
from rmnpy._c_api.rmnlib cimport *

from rmnpy.exceptions import RMNError
from rmnpy.helpers.octypes import (
    ocarray_create_from_pylist,
    ocarray_to_pylist,
    ocdict_create_from_pydict,
    ocdict_to_pydict,
    ocnumber_create_from_pynumber,
    ocnumber_to_pynumber,
    ocstring_create_from_pystring,
    ocstring_to_pystring,
)


cdef class SparseSampling:
    """
    Thin wrapper around RMNLib SparseSamplingRef.

    Represents sparse sampling patterns over selected dimensions in a multidimensional grid.
    All properties are retrieved directly from the C API (single source of truth).
    """

    def __cinit__(self):
        """Initialize C-level attributes."""
        self._c_ref = NULL

    def __dealloc__(self):
        """Clean up C resources."""
        if self._c_ref != NULL:
            OCRelease(self._c_ref)

    @staticmethod
    cdef SparseSampling _from_c_ref(SparseSamplingRef sparse_ref):
        """Create SparseSampling wrapper from C reference (internal use).

        Creates a copy of the sparse sampling reference, so caller retains ownership
        of their original reference and can safely release it.
        """
        cdef SparseSampling result = SparseSampling.__new__(SparseSampling)
        cdef SparseSamplingRef copied_ref = <SparseSamplingRef>OCTypeDeepCopy(<OCTypeRef>sparse_ref)
        if copied_ref == NULL:
            raise RMNError("Failed to create copy of SparseSampling")
        result._c_ref = copied_ref
        return result

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
        if self._c_ref != NULL:
            return  # Already initialized by _from_c_ref

        cdef OCStringRef err_ocstr = NULL
        cdef OCIndexSetRef dim_indexes_ref = NULL
        cdef OCArrayRef vertices_ref = NULL
        cdef OCNumberType num_type = kOCNumberUInt32Type  # Default
        cdef OCStringRef encoding_ref = NULL
        cdef OCStringRef desc_ref = NULL
        cdef OCDictionaryRef metadata_ref = NULL

        try:
            # Validate and convert dimension indexes (required)
            if not isinstance(dimension_indexes, (list, tuple)):
                raise TypeError("dimension_indexes must be a list or tuple")
            # TODO: Need to implement index set creation from Python list
            # For now, skip complex conversion but validate structure

            # Validate and convert sparse grid vertices (required)
            if not isinstance(sparse_grid_vertices, (list, tuple)):
                raise TypeError("sparse_grid_vertices must be a list or tuple")
            # TODO: Need to implement vertex array conversion
            # For now, skip complex conversion but validate structure

            # Structural validation - each vertex must match dimension count
            ndim = len(dimension_indexes)
            for i, vertex in enumerate(sparse_grid_vertices):
                if not isinstance(vertex, (list, tuple)):
                    raise ValueError(f"sparse_grid_vertices[{i}] must be a list or tuple of (index,value) pairs")
                if len(vertex) != ndim:
                    raise ValueError(f"sparse_grid_vertices[{i}] must contain {ndim} (index,value) pairs to match dimension_indexes")

            # Convert unsigned integer type (required)
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

            # Convert encoding (required)
            if encoding not in ("none", "base64"):
                raise ValueError(f"Invalid encoding: {encoding}. Must be 'none' or 'base64'")
            encoding_ref = <OCStringRef><uint64_t>ocstring_create_from_pystring(encoding)

            # Convert description (optional)
            if description is not None:
                desc_ref = <OCStringRef><uint64_t>ocstring_create_from_pystring(description)

            # Convert metadata (optional)
            if metadata is not None:
                metadata_ref = <OCDictionaryRef><uint64_t>ocdict_create_from_pydict(metadata)

            # Create SparseSampling
            self._c_ref = SparseSamplingCreate(
                dim_indexes_ref,
                vertices_ref,
                num_type,
                encoding_ref,
                desc_ref,
                metadata_ref,
                &err_ocstr
            )

            if self._c_ref == NULL:
                if err_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>err_ocstr)
                    raise RMNError(f"Failed to create SparseSampling: {error_msg}")
                else:
                    raise RMNError("Failed to create SparseSampling")

        finally:
            # Clean up temporary references
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
        cdef OCDictionaryRef dict_ref = NULL
        cdef OCStringRef err_ocstr = NULL

        try:
            dict_ref = <OCDictionaryRef><uint64_t>ocdict_create_from_pydict(data_dict)
            result._c_ref = SparseSamplingCreateFromDictionary(dict_ref, &err_ocstr)

            if result._c_ref == NULL:
                if err_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>err_ocstr)
                    raise RMNError(f"Failed to create SparseSampling from dictionary: {error_msg}")
                else:
                    raise RMNError("Failed to create SparseSampling from dictionary")

            return result

        finally:
            if dict_ref != NULL:
                OCRelease(<OCTypeRef>dict_ref)
            if err_ocstr != NULL:
                OCRelease(<OCTypeRef>err_ocstr)

    @property
    def dimension_indexes(self):
        """Get the set of dimension indexes that are sparsely sampled."""
        cdef OCIndexSetRef indexes_ref = SparseSamplingGetDimensionIndexes(self._c_ref)
        if indexes_ref == NULL:
            return None
        # TODO: Convert OCIndexSetRef to Python list
        # For now, return placeholder
        return []

    @dimension_indexes.setter
    def dimension_indexes(self, value):
        """Set the dimension indexes."""
        cdef OCIndexSetRef indexes_ref = NULL

        try:
            # TODO: Convert Python list to OCIndexSetRef
            if not SparseSamplingSetDimensionIndexes(self._c_ref, indexes_ref):
                raise RMNError("Failed to set dimension indexes")
        finally:
            if indexes_ref != NULL:
                OCRelease(<OCTypeRef>indexes_ref)

    @property
    def sparse_grid_vertices(self):
        """Get the array of sparse grid vertices."""
        cdef OCArrayRef vertices_ref = SparseSamplingGetSparseGridVertexes(self._c_ref)
        if vertices_ref == NULL:
            return None
        # TODO: Convert OCArrayRef of OCIndexPairSetRef to Python list
        # For now, return placeholder
        return []

    @sparse_grid_vertices.setter
    def sparse_grid_vertices(self, value):
        """Set the sparse grid vertices."""
        cdef OCArrayRef vertices_ref = NULL

        try:
            # TODO: Convert Python list to OCArrayRef of OCIndexPairSetRef
            if not SparseSamplingSetSparseGridVertexes(self._c_ref, vertices_ref):
                raise RMNError("Failed to set sparse grid vertices")
        finally:
            if vertices_ref != NULL:
                OCRelease(<OCTypeRef>vertices_ref)

    @property
    def unsigned_integer_type(self):
        """Get the unsigned integer type used for indexing."""
        cdef OCNumberType num_type = SparseSamplingGetUnsignedIntegerType(self._c_ref)
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

        if not SparseSamplingSetUnsignedIntegerType(self._c_ref, num_type):
            raise RMNError("Failed to set unsigned integer type")

    @property
    def encoding(self):
        """Get the encoding for sparse_grid_vertices."""
        cdef OCStringRef encoding_ref = SparseSamplingGetEncoding(self._c_ref)
        if encoding_ref == NULL:
            return None
        return ocstring_to_pystring(<uint64_t>encoding_ref)

    @encoding.setter
    def encoding(self, value):
        """Set the encoding."""
        cdef OCStringRef encoding_ref = NULL

        if not isinstance(value, str):
            raise TypeError("encoding must be a string")
        if value not in ("none", "base64"):
            raise ValueError(f"Invalid encoding: {value}. Must be 'none' or 'base64'")

        try:
            encoding_ref = <OCStringRef><uint64_t>ocstring_create_from_pystring(value)
            if not SparseSamplingSetEncoding(self._c_ref, encoding_ref):
                raise RMNError(f"Failed to set encoding: {value}")
        finally:
            if encoding_ref != NULL:
                OCRelease(<OCTypeRef>encoding_ref)

    @property
    def description(self):
        """Get the human-readable description."""
        cdef OCStringRef desc_ref = SparseSamplingGetDescription(self._c_ref)
        if desc_ref == NULL:
            return ""
        return ocstring_to_pystring(<uint64_t>desc_ref)

    @description.setter
    def description(self, value):
        """Set the description."""
        cdef OCStringRef desc_ref = NULL

        if value is not None and not isinstance(value, str):
            raise TypeError("description must be a string or None")

        try:
            if value is not None:
                desc_ref = <OCStringRef><uint64_t>ocstring_create_from_pystring(value)
            if not SparseSamplingSetDescription(self._c_ref, desc_ref):
                raise RMNError("Failed to set description")
        finally:
            if desc_ref != NULL:
                OCRelease(<OCTypeRef>desc_ref)

    @property
    def metadata(self):
        """Get the metadata dictionary."""
        cdef OCDictionaryRef metadata_ref = SparseSamplingGetApplicationMetaData(self._c_ref)
        if metadata_ref == NULL:
            return {}
        return ocdict_to_pydict(<uint64_t>metadata_ref)

    @metadata.setter
    def metadata(self, value):
        """Set the metadata."""
        cdef OCDictionaryRef metadata_ref = NULL

        if value is not None and not isinstance(value, dict):
            raise TypeError("metadata must be a dictionary or None")

        try:
            if value is not None:
                metadata_ref = <OCDictionaryRef><uint64_t>ocdict_create_from_pydict(value)
            if not SparseSamplingSetApplicationMetaData(self._c_ref, metadata_ref):
                raise RMNError("Failed to set metadata")
        finally:
            if metadata_ref != NULL:
                OCRelease(<OCTypeRef>metadata_ref)

    def to_dict(self):
        """Convert SparseSampling to dictionary."""
        cdef OCDictionaryRef dict_ref = SparseSamplingCopyAsDictionary(self._c_ref)
        if dict_ref == NULL:
            raise RMNError("Failed to convert SparseSampling to dictionary")

        try:
            return ocdict_to_pydict(<uint64_t>dict_ref)
        finally:
            OCRelease(<OCTypeRef>dict_ref)

    def dict(self):
        """Alias for to_dict() for consistency with other wrappers."""
        return self.to_dict()

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
