# cython: language_level=3
"""
RMNLib Dataset wrapper

This module provides a Python wrapper around the RMNLib Dataset C API.
Dataset represents a high-level container for scientific datasets, managing
collections of Dimension and DependentVariable objects with associated metadata.

Dataset serves as the top-level data structure for complete scientific workflows,
integrating dimensions, dependent variables, and application-specific metadata
into a cohesive, serializable container.
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
    ocstring_create_from_pystring,
    ocstring_to_pystring,
)

# Import wrapper classes for cross-component integration

from rmnpy.wrappers.rmnlib.dependent_variable cimport DependentVariable
from rmnpy.wrappers.rmnlib.dimension cimport BaseDimension


cdef class Dataset:
    """
    Python wrapper for RMNLib Dataset.

    A Dataset represents a complete scientific dataset containing:
    - Dimensions: Coordinate systems for the data space
    - DependentVariables: Measured or computed data values with metadata
    - ApplicationMetadata: Custom metadata for domain-specific information

    This is the top-level container for scientific data workflows, providing
    a cohesive interface for managing multi-dimensional datasets with proper
    metadata and serialization capabilities.

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
    cdef Dataset _from_c_ref(DatasetRef dataset_ref):
        """Create Dataset wrapper from C reference (internal use).

        Creates a copy of the dataset reference, so caller retains ownership
        of their original reference and can safely release it.
        """
        cdef Dataset result = Dataset.__new__(Dataset)
        cdef DatasetRef copied_ref = DatasetCreateCopy(dataset_ref)
        if dataset_ref == NULL:
            raise RMNError("Cannot create wrapper from NULL dataset reference")

        if copied_ref == NULL:
            raise RMNError("Failed to create copy of Dataset")
        result._c_ref = copied_ref
        return result

    def __init__(self, name=None, description=None, dimensions=None,
                 dependent_variables=None, application_metadata=None):
        """
        Create a new Dataset.

        Parameters:
            name : str, optional
                Human-readable name for the dataset
            description : str, optional
                Longer description of the dataset
            dimensions : list of BaseDimension, optional
                List of dimension objects defining the coordinate systems
            dependent_variables : list of DependentVariable, optional
                List of dependent variable objects containing the data
            application_metadata : dict, optional
                Dictionary of application-specific metadata

        Raises:
            RMNError: If dataset creation fails
            TypeError: If input parameters have incorrect types
        """
        if self._c_ref != NULL:
            return  # Already initialized by _from_c_ref

        cdef OCStringRef name_ref = NULL
        cdef OCStringRef desc_ref = NULL
        cdef OCStringRef err_ocstr = NULL
        cdef OCArrayRef dimensions_ref = NULL
        cdef OCArrayRef variables_ref = NULL
        cdef OCDictionaryRef metadata_ref = NULL

        try:
            # Convert name parameter
            if name is not None:
                if not isinstance(name, str):
                    raise TypeError("name must be a string")
                name_ref = ocstring_create_from_pystring(name)
                if name_ref == NULL:
                    raise RMNError("Failed to create name string")

            # Convert description parameter
            if description is not None:
                if not isinstance(description, str):
                    raise TypeError("description must be a string")
                desc_ref = ocstring_create_from_pystring(description)
                if desc_ref == NULL:
                    raise RMNError("Failed to create description string")

            # Create the dataset
            self._c_ref = DatasetCreate(name_ref, desc_ref, &err_ocstr)
            if self._c_ref == NULL:
                error_msg = ocstring_to_pystring(<uint64_t>err_ocstr) if err_ocstr else "Unknown error"
                raise RMNError(f"Dataset creation failed: {error_msg}")

            # Set dimensions if provided
            if dimensions is not None:
                if not isinstance(dimensions, (list, tuple)):
                    raise TypeError("dimensions must be a list or tuple")
                self.dimensions = dimensions

            # Set dependent variables if provided
            if dependent_variables is not None:
                if not isinstance(dependent_variables, (list, tuple)):
                    raise TypeError("dependent_variables must be a list or tuple")
                self.dependent_variables = dependent_variables

            # Set application metadata if provided
            if application_metadata is not None:
                if not isinstance(application_metadata, dict):
                    raise TypeError("application_metadata must be a dictionary")
                self.application_metadata = application_metadata

        finally:
            # Clean up temporary references
            if name_ref != NULL:
                OCRelease(<OCTypeRef>name_ref)
            if desc_ref != NULL:
                OCRelease(<OCTypeRef>desc_ref)
            if err_ocstr != NULL:
                OCRelease(<OCTypeRef>err_ocstr)

    @classmethod
    def from_dict(cls, data_dict):
        """
        Create Dataset from dictionary representation.

        Parameters:
            data_dict : dict
                Dictionary containing dataset data and metadata

        Returns:
            Dataset: New dataset instance

        Raises:
            RMNError: If dataset creation from dictionary fails
            TypeError: If data_dict is not a dictionary
        """
        if not isinstance(data_dict, dict):
            raise TypeError("data_dict must be a dictionary")

        cdef OCDictionaryRef dict_ref = NULL
        cdef OCStringRef err_ocstr = NULL
        cdef DatasetRef dataset_ref = NULL

        try:
            # Convert Python dictionary to OCDictionary
            dict_ref = ocdict_create_from_pydict(data_dict)
            if dict_ref == NULL:
                raise RMNError("Failed to convert dictionary to OCDictionary")

            # Create dataset from dictionary
            dataset_ref = DatasetCreateFromDictionary(dict_ref, &err_ocstr)
            if dataset_ref == NULL:
                error_msg = ocstring_to_pystring(<uint64_t>err_ocstr) if err_ocstr else "Unknown error"
                raise RMNError(f"Dataset creation from dictionary failed: {error_msg}")

            # Create wrapper from C reference
            return cls._from_c_ref(dataset_ref)

        finally:
            # Clean up temporary references
            if dict_ref != NULL:
                OCRelease(<OCTypeRef>dict_ref)
            if err_ocstr != NULL:
                OCRelease(<OCTypeRef>err_ocstr)
            if dataset_ref != NULL:
                OCRelease(<OCTypeRef>dataset_ref)

    # Basic property accessors

    @property
    def name(self):
        """Get the name of the dataset."""
        cdef OCStringRef name_ref = DatasetGetName(self._c_ref)
        if name_ref == NULL:
            return ""  # Return empty string for datasets without names
        return ocstring_to_pystring(<uint64_t>name_ref)

    @name.setter
    def name(self, value):
        """Set the name of the dataset."""
        if not isinstance(value, str):
            raise TypeError("name must be a string")

        cdef OCStringRef name_ref = NULL
        cdef OCStringRef err_ocstr = NULL

        try:
            name_ref = ocstring_create_from_pystring(value)
            if name_ref == NULL:
                raise RMNError("Failed to create name string")

            if not DatasetSetName(self._c_ref, name_ref, &err_ocstr):
                error_msg = ocstring_to_pystring(<uint64_t>err_ocstr) if err_ocstr else "Unknown error"
                raise RMNError(f"Failed to set dataset name: {error_msg}")

        finally:
            if name_ref != NULL:
                OCRelease(<OCTypeRef>name_ref)
            if err_ocstr != NULL:
                OCRelease(<OCTypeRef>err_ocstr)

    @property
    def description(self):
        """Get the description of the dataset."""
        cdef OCStringRef desc_ref = DatasetGetDescription(self._c_ref)
        if desc_ref == NULL:
            return ""  # Return empty string for datasets without descriptions
        return ocstring_to_pystring(<uint64_t>desc_ref)

    @description.setter
    def description(self, value):
        """Set the description of the dataset."""
        if not isinstance(value, str):
            raise TypeError("description must be a string")

        cdef OCStringRef desc_ref = NULL
        cdef OCStringRef err_ocstr = NULL

        try:
            desc_ref = ocstring_create_from_pystring(value)
            if desc_ref == NULL:
                raise RMNError("Failed to create description string")

            if not DatasetSetDescription(self._c_ref, desc_ref, &err_ocstr):
                error_msg = ocstring_to_pystring(<uint64_t>err_ocstr) if err_ocstr else "Unknown error"
                raise RMNError(f"Failed to set dataset description: {error_msg}")

        finally:
            if desc_ref != NULL:
                OCRelease(<OCTypeRef>desc_ref)
            if err_ocstr != NULL:
                OCRelease(<OCTypeRef>err_ocstr)

    # Dimensions management

    @property
    def dimensions(self):
        """Get the list of dimensions in the dataset."""
        cdef OCArrayRef dims_ref = DatasetGetDimensions(self._c_ref)
        if dims_ref == NULL:
            return []  # Return empty list if no dimensions

        # Convert OCArray to Python list of Dimension objects
        cdef OCIndex count = OCArrayGetCount(dims_ref)
        cdef list result = []
        cdef DimensionRef dim_ref

        for i in range(count):
            dim_ref = <DimensionRef>OCArrayGetValueAtIndex(dims_ref, i)
            if dim_ref != NULL:
                # Use BaseDimension._from_c_ref to create appropriate wrapper type
                dimension_wrapper = BaseDimension._from_c_ref(dim_ref)
                result.append(dimension_wrapper)

        return result

    @dimensions.setter
    def dimensions(self, value):
        """Set the dimensions of the dataset."""
        if not isinstance(value, (list, tuple)):
            raise TypeError("dimensions must be a list or tuple")

        # Validate that all items are dimension objects
        for i, dim in enumerate(value):
            if not isinstance(dim, BaseDimension):
                raise TypeError(f"dimensions[{i}] must be a BaseDimension instance")

        cdef OCArrayRef dims_ref = NULL
        cdef OCStringRef err_ocstr = NULL
        cdef list c_refs = []

        try:
            # Extract C references from dimension objects
            for dim in value:
                c_refs.append(<uintptr_t>(<BaseDimension>dim)._c_ref)

            # Create OCArray from C references
            dims_ref = ocarray_create_from_pylist(c_refs)
            if dims_ref == NULL:
                raise RMNError("Failed to create dimensions array")

            # Set dimensions in dataset
            if not DatasetSetDimensions(self._c_ref, dims_ref, &err_ocstr):
                error_msg = ocstring_to_pystring(<uint64_t>err_ocstr) if err_ocstr else "Unknown error"
                raise RMNError(f"Failed to set dataset dimensions: {error_msg}")

        finally:
            if dims_ref != NULL:
                OCRelease(<OCTypeRef>dims_ref)
            if err_ocstr != NULL:
                OCRelease(<OCTypeRef>err_ocstr)

    def add_dimension(self, dimension):
        """
        Add a dimension to the dataset.

        Parameters:
            dimension : BaseDimension
                The dimension to add

        Raises:
            RMNError: If adding the dimension fails
            TypeError: If dimension is not a BaseDimension instance
        """
        if not isinstance(dimension, BaseDimension):
            raise TypeError("dimension must be a BaseDimension instance")

        cdef OCStringRef err_ocstr = NULL

        try:
            if not DatasetAddDimension(self._c_ref, (<BaseDimension>dimension)._c_ref, &err_ocstr):
                error_msg = ocstring_to_pystring(<uint64_t>err_ocstr) if err_ocstr else "Unknown error"
                raise RMNError(f"Failed to add dimension: {error_msg}")

        finally:
            if err_ocstr != NULL:
                OCRelease(<OCTypeRef>err_ocstr)

    # Dependent variables management

    @property
    def dependent_variables(self):
        """Get the list of dependent variables in the dataset."""
        cdef OCArrayRef vars_ref = DatasetGetDependentVariables(self._c_ref)
        if vars_ref == NULL:
            return []  # Return empty list if no dependent variables

        # Convert OCArray to Python list of DependentVariable objects
        cdef OCIndex count = OCArrayGetCount(vars_ref)
        cdef list result = []
        cdef DependentVariableRef var_ref

        for i in range(count):
            var_ref = <DependentVariableRef>OCArrayGetValueAtIndex(vars_ref, i)
            if var_ref != NULL:
                # Use DependentVariable._from_c_ref to create wrapper
                var_wrapper = DependentVariable._from_c_ref(var_ref)
                result.append(var_wrapper)

        return result

    @dependent_variables.setter
    def dependent_variables(self, value):
        """Set the dependent variables of the dataset."""
        if not isinstance(value, (list, tuple)):
            raise TypeError("dependent_variables must be a list or tuple")

        # Validate that all items are DependentVariable objects
        for i, var in enumerate(value):
            if not isinstance(var, DependentVariable):
                raise TypeError(f"dependent_variables[{i}] must be a DependentVariable instance")

        cdef OCArrayRef vars_ref = NULL
        cdef OCStringRef err_ocstr = NULL
        cdef list c_refs = []

        try:
            # Extract C references from DependentVariable objects
            for var in value:
                c_refs.append(<uintptr_t>(<DependentVariable>var)._c_ref)

            # Create OCArray from C references
            vars_ref = ocarray_create_from_pylist(c_refs)
            if vars_ref == NULL:
                raise RMNError("Failed to create dependent variables array")

            # Set dependent variables in dataset
            if not DatasetSetDependentVariables(self._c_ref, vars_ref, &err_ocstr):
                error_msg = ocstring_to_pystring(<uint64_t>err_ocstr) if err_ocstr else "Unknown error"
                raise RMNError(f"Failed to set dataset dependent variables: {error_msg}")

        finally:
            if vars_ref != NULL:
                OCRelease(<OCTypeRef>vars_ref)
            if err_ocstr != NULL:
                OCRelease(<OCTypeRef>err_ocstr)

    def add_dependent_variable(self, dependent_variable):
        """
        Add a dependent variable to the dataset.

        Parameters:
            dependent_variable : DependentVariable
                The dependent variable to add

        Raises:
            RMNError: If adding the dependent variable fails
            TypeError: If dependent_variable is not a DependentVariable instance
        """
        if not isinstance(dependent_variable, DependentVariable):
            raise TypeError("dependent_variable must be a DependentVariable instance")

        cdef OCStringRef err_ocstr = NULL

        try:
            if not DatasetAddDependentVariable(self._c_ref, (<DependentVariable>dependent_variable)._c_ref, &err_ocstr):
                error_msg = ocstring_to_pystring(<uint64_t>err_ocstr) if err_ocstr else "Unknown error"
                raise RMNError(f"Failed to add dependent variable: {error_msg}")

        finally:
            if err_ocstr != NULL:
                OCRelease(<OCTypeRef>err_ocstr)

    # Application metadata management

    @property
    def application_metadata(self):
        """Get the application metadata dictionary."""
        cdef OCDictionaryRef metadata_ref = DatasetGetApplicationMetaData(self._c_ref)
        if metadata_ref == NULL:
            return {}  # Return empty dict if no metadata

        return ocdict_to_pydict(<uint64_t>metadata_ref)

    @application_metadata.setter
    def application_metadata(self, value):
        """Set the application metadata dictionary."""
        if not isinstance(value, dict):
            raise TypeError("application_metadata must be a dictionary")

        cdef OCDictionaryRef metadata_ref = NULL
        cdef OCStringRef err_ocstr = NULL

        try:
            # Convert Python dictionary to OCDictionary
            metadata_ref = ocdict_create_from_pydict(value)
            if metadata_ref == NULL:
                raise RMNError("Failed to create metadata dictionary")

            # Set metadata in dataset
            if not DatasetSetApplicationMetaData(self._c_ref, metadata_ref, &err_ocstr):
                error_msg = ocstring_to_pystring(<uint64_t>err_ocstr) if err_ocstr else "Unknown error"
                raise RMNError(f"Failed to set dataset metadata: {error_msg}")

        finally:
            if metadata_ref != NULL:
                OCRelease(<OCTypeRef>metadata_ref)
            if err_ocstr != NULL:
                OCRelease(<OCTypeRef>err_ocstr)

    # Serialization methods

    def to_dict(self):
        """
        Convert dataset to dictionary representation.

        Returns:
            dict: Dictionary representation of the dataset

        Raises:
            RMNError: If conversion to dictionary fails
        """
        cdef OCDictionaryRef dict_ref = DatasetCopyAsDictionary(self._c_ref)
        if dict_ref == NULL:
            raise RMNError("Failed to convert dataset to dictionary")

        try:
            return ocdict_to_pydict(<uint64_t>dict_ref)
        finally:
            OCRelease(<OCTypeRef>dict_ref)

    def dict(self):
        """
        Alias for to_dict() for compatibility.

        Returns:
            dict: Dictionary representation of the dataset
        """
        return self.to_dict()

    # Utility methods

    def __repr__(self):
        """Return string representation of the dataset."""
        try:
            name = self.name or "unnamed"
            n_dims = len(self.dimensions)
            n_vars = len(self.dependent_variables)
            return f"Dataset(name='{name}', dimensions={n_dims}, dependent_variables={n_vars})"
        except Exception:
            # Fallback if any property access fails
            return f"Dataset(at {hex(id(self))})"

    def __str__(self):
        """Return string representation of the dataset."""
        return self.__repr__()

    @property
    def summary(self):
        """
        Get a summary of the dataset contents.

        Returns:
            dict: Summary information about the dataset
        """
        try:
            dimensions = self.dimensions
            dependent_variables = self.dependent_variables

            dim_summary = []
            for i, dim in enumerate(dimensions):
                dim_info = {
                    'index': i,
                    'type': dim.type,
                    'label': getattr(dim, 'label', ''),
                    'count': getattr(dim, 'count', 0)
                }
                dim_summary.append(dim_info)

            var_summary = []
            for i, var in enumerate(dependent_variables):
                var_info = {
                    'index': i,
                    'name': getattr(var, 'name', ''),
                    'quantity_type': getattr(var, 'quantity_type', ''),
                    'size': getattr(var, 'size', 0)
                }
                var_summary.append(var_info)

            return {
                'name': self.name,
                'description': self.description,
                'dimensions': dim_summary,
                'dependent_variables': var_summary,
                'metadata_keys': list(self.application_metadata.keys()) if self.application_metadata else []
            }
        except Exception as e:
            return {'error': f"Failed to generate summary: {str(e)}"}
