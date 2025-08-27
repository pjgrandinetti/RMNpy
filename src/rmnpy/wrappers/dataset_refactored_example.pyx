# cython: language_level=3
"""
Example refactored Dataset wrapper using the base wrapper classes.

This demonstrates how a complex wrapper like Dataset becomes much simpler
with the base class system while maintaining all functionality.
"""

from typing import Any, Dict, List, Optional, Union

import numpy as np

from libc.stdint cimport uintptr_t

from rmnpy._c_api.octypes cimport *
from rmnpy._c_api.rmnlib cimport *

from rmnpy.exceptions import RMNError

from rmnpy.wrappers.base_wrapper cimport (
    RMNLibWrapper,
    SerializableWrapper,
    create_wrapper_from_c_ref,
)

from rmnpy.helpers.octypes import (
    ocdict_create_from_pydict,
    ocdict_to_pydict,
    ocstring_create_from_pystring,
    ocstring_to_pystring,
)


cdef class Dataset(RMNLibWrapper, SerializableWrapper):
    """
    Python wrapper for RMNLib Dataset - REFACTORED VERSION.

    This version demonstrates how the base class system dramatically reduces
    boilerplate code while maintaining all functionality.

    Compare this to the original 876-line implementation!
    """

    # The base class handles __cinit__ and __dealloc__

    def __init__(self, dimensions=None, dependent_variables=None,
                 application_metadata=None, label=None, description=None):
        """Create a new Dataset."""
        if self._c_ref != NULL:
            return  # Already initialized by _from_c_ref

        # Convert inputs and create dataset
        cdef DatasetRef dataset_ref = self._create_dataset_c_api(
            dimensions, dependent_variables, application_metadata,
            label, description
        )

        if dataset_ref == NULL:
            raise RMNError("Failed to create dataset")

        self._set_c_ref(<void*>dataset_ref)

    # Implement required base class methods

    cdef void* copy_c_ref(self) except NULL:
        """Create a copy of the C reference."""
        self._validate_initialized()
        cdef DatasetRef copied = DatasetCreateCopy(<DatasetRef>self._c_ref)
        if copied == NULL:
            raise RMNError("Failed to copy dataset reference")
        return <void*>copied

    @staticmethod
    cdef Dataset _from_c_ref(DatasetRef dataset_ref):
        """Create Dataset wrapper from C reference (internal use)."""
        return <Dataset>create_wrapper_from_c_ref(
            <void*>dataset_ref,
            Dataset,
            <copy_func_ptr>DatasetCreateCopy
        )

    @staticmethod
    def from_c_ref(uint64_t dataset_ref_ptr):
        """Create Dataset wrapper from C reference pointer (Python-accessible)."""
        return Dataset._from_c_ref(<DatasetRef>dataset_ref_ptr)

    # Implement serialization methods (SerializableWrapper)

    def _to_dict_c_api(self):
        """Convert to dictionary using C API."""
        cdef OCDictionaryRef dict_ref = DatasetCopyAsDictionary(<DatasetRef>self._c_ref)
        if dict_ref == NULL:
            raise RMNError("Failed to convert dataset to dictionary")

        try:
            return ocdict_to_pydict(<uint64_t>dict_ref)
        finally:
            OCRelease(<OCTypeRef>dict_ref)

    @classmethod
    def _from_dict_c_api(cls, data_dict):
        """Create from dictionary using C API."""
        cdef uint64_t oc_dict_addr = ocdict_create_from_pydict(data_dict)
        if oc_dict_addr == 0:
            raise RMNError("Failed to convert dictionary to OCDictionary")

        cdef OCDictionaryRef oc_dict = <OCDictionaryRef>oc_dict_addr
        cdef OCStringRef error = NULL
        cdef DatasetRef dataset_ref = NULL

        try:
            dataset_ref = DatasetCreateFromDictionary(oc_dict, &error)
            if dataset_ref == NULL:
                if error != NULL:
                    error_str = OCStringGetCString(error)
                    error_msg = error_str.decode('utf-8') if error_str else "Unknown error"
                    raise RMNError(f"Failed to create Dataset from dictionary: {error_msg}")
                else:
                    raise RMNError("Failed to create Dataset from dictionary")

            return cls._from_c_ref(dataset_ref)

        finally:
            if dataset_ref != NULL:
                OCRelease(<OCTypeRef>dataset_ref)
            if oc_dict != NULL:
                OCRelease(<OCTypeRef>oc_dict)
            if error != NULL:
                OCRelease(<OCTypeRef>error)

    # Domain-specific properties and methods

    @property
    def label(self):
        """Get the dataset label."""
        self._validate_initialized()
        cdef OCStringRef label_ref = DatasetGetLabel(<DatasetRef>self._c_ref)
        if label_ref != NULL:
            return ocstring_to_pystring(<uint64_t>label_ref)
        return None

    @property
    def description(self):
        """Get the dataset description."""
        self._validate_initialized()
        cdef OCStringRef desc_ref = DatasetGetDescription(<DatasetRef>self._c_ref)
        if desc_ref != NULL:
            return ocstring_to_pystring(<uint64_t>desc_ref)
        return None

    @property
    def dimensions_count(self):
        """Get the number of dimensions."""
        self._validate_initialized()
        return <int>DatasetGetDimensionsCount(<DatasetRef>self._c_ref)

    @property
    def dependent_variables_count(self):
        """Get the number of dependent variables."""
        self._validate_initialized()
        return <int>DatasetGetDependentVariablesCount(<DatasetRef>self._c_ref)

    def get_dimension(self, index):
        """Get dimension by index."""
        self._validate_initialized()
        if not isinstance(index, int) or index < 0:
            raise TypeError("index must be a non-negative integer")

        cdef OCIndex count = DatasetGetDimensionsCount(<DatasetRef>self._c_ref)
        if index >= count:
            raise IndexError(f"Dimension index {index} out of range (0-{count-1})")

        cdef SIDimensionRef dim_ref = DatasetGetDimensionAtIndex(<DatasetRef>self._c_ref, <OCIndex>index)
        if dim_ref == NULL:
            raise RMNError(f"Failed to get dimension at index {index}")

        # Import and return appropriate dimension wrapper
        from rmnpy.wrappers.rmnlib.dimension import BaseDimension
        return BaseDimension._from_c_ref(dim_ref)

    def get_dependent_variable(self, index):
        """Get dependent variable by index."""
        self._validate_initialized()
        if not isinstance(index, int) or index < 0:
            raise TypeError("index must be a non-negative integer")

        cdef OCIndex count = DatasetGetDependentVariablesCount(<DatasetRef>self._c_ref)
        if index >= count:
            raise IndexError(f"DependentVariable index {index} out of range (0-{count-1})")

        cdef DependentVariableRef dv_ref = DatasetGetDependentVariableAtIndex(<DatasetRef>self._c_ref, <OCIndex>index)
        if dv_ref == NULL:
            raise RMNError(f"Failed to get dependent variable at index {index}")

        from rmnpy.wrappers.rmnlib.dependent_variable import DependentVariable
        return DependentVariable._from_c_ref(dv_ref)

    # Helper methods

    cdef DatasetRef _create_dataset_c_api(self, dimensions, dependent_variables,
                                         application_metadata, label, description):
        """Create dataset using C API."""
        # Implementation would handle conversion of Python inputs to C types
        # and call DatasetCreate with appropriate parameters
        cdef OCStringRef error = NULL
        cdef DatasetRef result = NULL

        try:
            # Convert inputs to C types
            # ... conversion logic ...

            # Call C API
            result = DatasetCreate(
                # ... appropriate parameters ...
                &error
            )

            if result == NULL and error != NULL:
                error_str = OCStringGetCString(error)
                error_msg = error_str.decode('utf-8') if error_str else "Unknown error"
                raise RMNError(f"Failed to create dataset: {error_msg}")

            return result

        finally:
            if error != NULL:
                OCRelease(<OCTypeRef>error)

    def __repr__(self):
        """String representation."""
        try:
            label = self.label or "unlabeled"
            dims = self.dimensions_count
            dvs = self.dependent_variables_count
            return f"Dataset(label='{label}', dimensions={dims}, dependent_variables={dvs})"
        except Exception:
            return f"Dataset(at {hex(id(self))})"
