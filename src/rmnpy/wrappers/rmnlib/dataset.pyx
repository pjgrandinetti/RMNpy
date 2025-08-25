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

from libc.stdint cimport uintptr_t

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

from rmnpy.wrappers.rmnlib.datum cimport Datum
from rmnpy.wrappers.rmnlib.dependent_variable cimport DependentVariable
from rmnpy.wrappers.rmnlib.dimension cimport BaseDimension

# from rmnpy.wrappers.rmnlib.geographic_coordinate cimport GeographicCoordinate  # TODO: Add when geographic_coordinate module is compiled


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
        if dataset_ref == NULL:
            raise RMNError("Cannot create wrapper from NULL dataset reference")
        cdef DatasetRef copied_ref = DatasetCreateCopy(dataset_ref)

        if copied_ref == NULL:
            raise RMNError("Failed to create copy of Dataset")
        result._c_ref = copied_ref
        return result

    @staticmethod
    def from_c_ref(uint64_t dataset_ref_ptr):
        """Create Dataset wrapper from C reference pointer (Python-accessible)."""
        return Dataset._from_c_ref(<DatasetRef>dataset_ref_ptr)

    def __init__(self, title=None, description=None, dimensions=None,
                 dependent_variables, application_metadata=None,
                 dimension_precedence=None, tags=None, focus=None, previous_focus=None):
        """
        Create a new Dataset.

        Parameters:
            title : str, optional
                Human-readable title for the dataset
            description : str, optional
                Longer description of the dataset
            dimensions : list of BaseDimension, optional
                List of dimension objects defining the coordinate systems
            dependent_variables : list of DependentVariable, optional
                List of dependent variable objects containing the data
            application_metadata : dict, optional
                Dictionary of application-specific metadata
            dimension_precedence : list of int, optional
                List of dimension indices specifying precedence ordering
            tags : list of str, optional
                List of string tags for the dataset
            focus : Datum, optional
                Focus datum for the dataset
            previous_focus : Datum, optional
                Previous focus datum for the dataset

        Raises:
            RMNError: If dataset creation fails
            TypeError: If input parameters have incorrect types
        """
        if self._c_ref != NULL:
            return  # Already initialized by _from_c_ref

        cdef OCStringRef err_ocstr = NULL
        cdef OCArrayRef dims_ref = NULL
        cdef OCIndexArrayRef precedence_ref = NULL
        cdef OCArrayRef deps_ref = NULL
        cdef OCArrayRef tags_ref = NULL
        cdef OCStringRef desc_ref = NULL
        cdef OCStringRef title_ref = NULL
        cdef DatumRef focus_ref = NULL
        cdef DatumRef prev_focus_ref = NULL
        cdef OCDictionaryRef metadata_ref = NULL

        try:
            # Convert dimensions to OCArray
            if dimensions is not None:
                dims_ref = <OCArrayRef><uint64_t>ocarray_create_from_pylist(dimensions)

            # Convert dimension precedence to OCIndexArray
            if dimension_precedence is not None:
                from rmnpy.helpers.octypes import ocindexarray_create_from_pylist
                precedence_ref = <OCIndexArrayRef><uint64_t>ocindexarray_create_from_pylist(list(dimension_precedence))

            # Convert dependent variables to OCArray
            if dependent_variables is not None:
                deps_ref = <OCArrayRef><uint64_t>ocarray_create_from_pylist(dependent_variables)

            # Convert tags to OCArray
            if tags is not None:
                tags_ref = <OCArrayRef><uint64_t>ocarray_create_from_pylist(list(tags))

            # Convert description to OCString
            if description is not None:
                desc_ref = <OCStringRef><uint64_t>ocstring_create_from_pystring(description)

            # Convert title to OCString
            if title is not None:
                title_ref = <OCStringRef><uint64_t>ocstring_create_from_pystring(title)

            # Handle focus datum
            if focus is not None:
                focus_ref = (<Datum>focus)._c_ref

            # Handle previous focus datum
            if previous_focus is not None:
                prev_focus_ref = (<Datum>previous_focus)._c_ref

            # Convert application metadata to OCDictionary
            if application_metadata is not None:
                metadata_ref = <OCDictionaryRef><uint64_t>ocdict_create_from_pydict(application_metadata)

            # Create dataset using DatasetCreate
            self._c_ref = DatasetCreate(
                dims_ref,
                precedence_ref,
                deps_ref,
                tags_ref,
                desc_ref,
                title_ref,
                focus_ref,
                prev_focus_ref,
                metadata_ref,
                &err_ocstr
            )
            if self._c_ref == NULL:
                error_msg = ocstring_to_pystring(<uint64_t>err_ocstr) if err_ocstr else "Unknown error"
                raise RMNError(f"Dataset creation failed: {error_msg}")

        except:
            # Clean up on failure
            if self._c_ref != NULL:
                OCRelease(<OCTypeRef>self._c_ref)
                self._c_ref = NULL
            raise
        finally:
            # Clean up temporary references
            if dims_ref != NULL:
                OCRelease(<OCTypeRef>dims_ref)
            if precedence_ref != NULL:
                OCRelease(<OCTypeRef>precedence_ref)
            if deps_ref != NULL:
                OCRelease(<OCTypeRef>deps_ref)
            if tags_ref != NULL:
                OCRelease(<OCTypeRef>tags_ref)
            if desc_ref != NULL:
                OCRelease(<OCTypeRef>desc_ref)
            if title_ref != NULL:
                OCRelease(<OCTypeRef>title_ref)
            if metadata_ref != NULL:
                OCRelease(<OCTypeRef>metadata_ref)
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
            dict_ref = <OCDictionaryRef><uint64_t>ocdict_create_from_pydict(data_dict)
            if dict_ref == NULL:
                raise RMNError("Failed to convert dictionary to OCDictionary")

            # Create dataset from dictionary
            dataset_ref = DatasetCreateFromDictionary(dict_ref, &err_ocstr)
            if dataset_ref == NULL:
                error_msg = ocstring_to_pystring(<uint64_t>err_ocstr) if err_ocstr else "Unknown error"
                raise RMNError(f"Dataset creation from dictionary failed: {error_msg}")

            # Create wrapper from C reference
            return cls._from_c_ref(<uint64_t>dataset_ref)

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
    def description(self):
        """Get the description of the dataset."""
        cdef OCStringRef desc_ref = DatasetGetDescription(<DatasetRef>self._c_ref)
        if desc_ref == NULL:
            return ""  # Return empty string for datasets without descriptions
        return ocstring_to_pystring(<uint64_t>desc_ref)

    @description.setter
    def description(self, value):
        """Set the description of the dataset."""
        if not isinstance(value, str):
            raise TypeError("description must be a string")

        cdef OCStringRef desc_ref = NULL

        try:
            desc_ref = <OCStringRef><uint64_t>ocstring_create_from_pystring(value)
            if desc_ref == NULL:
                raise RMNError("Failed to create description string")

            if not DatasetSetDescription(<DatasetRef>self._c_ref, desc_ref):
                raise RMNError("Failed to set dataset description")

        finally:
            if desc_ref != NULL:
                OCRelease(<OCTypeRef>desc_ref)

    @property
    def title(self):
        """Get the title of the dataset."""
        cdef OCStringRef title_ref = DatasetGetTitle(<DatasetRef>self._c_ref)
        if title_ref == NULL:
            return ""  # Return empty string for datasets without titles
        return ocstring_to_pystring(<uint64_t>title_ref)

    @title.setter
    def title(self, value):
        """Set the title of the dataset."""
        if not isinstance(value, str):
            raise TypeError("title must be a string")

        cdef OCStringRef title_ref = NULL

        try:
            title_ref = <OCStringRef><uint64_t>ocstring_create_from_pystring(value)
            if title_ref == NULL:
                raise RMNError("Failed to create title string")

            if not DatasetSetTitle(<DatasetRef>self._c_ref, title_ref):
                raise RMNError("Failed to set dataset title")

        finally:
            if title_ref != NULL:
                OCRelease(<OCTypeRef>title_ref)

    @property
    def read_only(self):
        """Get the read-only flag of the dataset."""
        if self._c_ref == NULL:
            raise ValueError("Dataset not initialized")
        return DatasetGetReadOnly(self._c_ref)

    @read_only.setter
    def read_only(self, value):
        """Set the read-only flag of the dataset."""
        if self._c_ref == NULL:
            raise ValueError("Dataset not initialized")

        if not isinstance(value, bool):
            raise TypeError("read_only must be a boolean")

        if not DatasetSetReadOnly(self._c_ref, value):
            raise RMNError("Failed to set dataset read-only flag")

    @property
    def tags(self):
        """Get the list of tags for the dataset."""
        if self._c_ref == NULL:
            raise ValueError("Dataset not initialized")

        cdef OCMutableArrayRef tags_ref = DatasetGetTags(<DatasetRef>self._c_ref)
        if tags_ref == NULL:
            return []  # Return empty list if no tags

        return ocarray_to_pylist(<uint64_t>tags_ref)

    @tags.setter
    def tags(self, value):
        """Set the tags for the dataset."""
        if self._c_ref == NULL:
            raise ValueError("Dataset not initialized")

        if not isinstance(value, (list, tuple)):
            raise TypeError("tags must be a list or tuple")

        cdef OCMutableArrayRef tags_ref = NULL

        try:
            # Convert Python list to OCMutableArray
            tags_ref = <OCMutableArrayRef><uint64_t>ocarray_create_from_pylist(list(value))
            if tags_ref == NULL:
                raise RMNError("Failed to create tags array")

            if not DatasetSetTags(<DatasetRef>self._c_ref, tags_ref):
                raise RMNError("Failed to set dataset tags")

        finally:
            if tags_ref != NULL:
                OCRelease(<OCTypeRef>tags_ref)

    @property
    def version(self):
        """Get the version string of the dataset (always '1.0' for CSDM-1.0)."""
        if self._c_ref == NULL:
            raise ValueError("Dataset not initialized")

        cdef OCStringRef version_ref = DatasetGetVersion(self._c_ref)
        if version_ref == NULL:
            return "1.0"  # Default version for CSDM-1.0
        return ocstring_to_pystring(<uint64_t>version_ref)

    @version.setter
    def version(self, value):
        """Set the version string of the dataset (rarely needed)."""
        if self._c_ref == NULL:
            raise ValueError("Dataset not initialized")

        if not isinstance(value, str):
            raise TypeError("version must be a string")

        cdef OCStringRef version_ref = NULL

        try:
            version_ref = <OCStringRef><uint64_t>ocstring_create_from_pystring(value)
            if version_ref == NULL:
                raise RMNError("Failed to create version string")

            if not DatasetSetVersion(self._c_ref, version_ref):
                raise RMNError("Failed to set dataset version")

        finally:
            if version_ref != NULL:
                OCRelease(<OCTypeRef>version_ref)

    @property
    def timestamp(self):
        """Get the ISO-8601 timestamp of serialization."""
        if self._c_ref == NULL:
            raise ValueError("Dataset not initialized")

        cdef OCStringRef timestamp_ref = DatasetGetTimestamp(self._c_ref)
        if timestamp_ref == NULL:
            return ""  # Return empty string if no timestamp set
        return ocstring_to_pystring(<uint64_t>timestamp_ref)

    @timestamp.setter
    def timestamp(self, value):
        """Set the ISO-8601 timestamp of serialization (rarely needed)."""
        if self._c_ref == NULL:
            raise ValueError("Dataset not initialized")

        if not isinstance(value, str):
            raise TypeError("timestamp must be a string")

        cdef OCStringRef timestamp_ref = NULL

        try:
            timestamp_ref = <OCStringRef><uint64_t>ocstring_create_from_pystring(value)
            if timestamp_ref == NULL:
                raise RMNError("Failed to create timestamp string")

            if not DatasetSetTimestamp(self._c_ref, timestamp_ref):
                raise RMNError("Failed to set dataset timestamp")

        finally:
            if timestamp_ref != NULL:
                OCRelease(<OCTypeRef>timestamp_ref)

    @property
    def geographic_coordinate(self):
        """Get the geographic coordinate, if set."""
        if self._c_ref == NULL:
            raise ValueError("Dataset not initialized")

        cdef GeographicCoordinateRef geo_ref = DatasetGetGeographicCoordinate(self._c_ref)
        if geo_ref == NULL:
            return None  # Return None if no geographic coordinate set

        # TODO: Uncomment when geographic_coordinate module is compiled
        # return GeographicCoordinate._from_c_ref(geo_ref)
        return None  # Temporary placeholder

    @geographic_coordinate.setter
    def geographic_coordinate(self, value):
        """Set the geographic coordinate."""
        if self._c_ref == NULL:
            raise ValueError("Dataset not initialized")

        cdef GeographicCoordinateRef geo_ref = NULL

        if value is None:
            # Setting to None clears the coordinate
            geo_ref = NULL
        # TODO: Uncomment when geographic_coordinate module is compiled
        # elif isinstance(value, GeographicCoordinate):
        #     # Extract C reference from GeographicCoordinate object
        #     geo_ref = (<GeographicCoordinate>value)._c_ref
        else:
            # raise TypeError("geographic_coordinate must be a GeographicCoordinate object or None")
            raise TypeError("geographic_coordinate setter temporarily disabled - module not compiled")

        if not DatasetSetGeographicCoordinate(self._c_ref, geo_ref):
            raise RMNError("Failed to set dataset geographic coordinate")

    @property
    def focus(self):
        """Get the focus datum, if set."""
        if self._c_ref == NULL:
            raise ValueError("Dataset not initialized")

        cdef DatumRef focus_ref = DatasetGetFocus(self._c_ref)
        if focus_ref == NULL:
            return None  # Return None if no focus datum set

        return Datum._from_c_ref(focus_ref)

    @focus.setter
    def focus(self, value):
        """Set the focus datum."""
        if self._c_ref == NULL:
            raise ValueError("Dataset not initialized")

        cdef DatumRef focus_ref = NULL

        if value is None:
            # Setting to None clears the focus
            focus_ref = NULL
        elif isinstance(value, Datum):
            # Extract C reference from Datum object
            focus_ref = (<Datum>value)._c_ref
        else:
            raise TypeError("focus must be a Datum object or None")

        if not DatasetSetFocus(self._c_ref, focus_ref):
            raise RMNError("Failed to set dataset focus")

    @property
    def previous_focus(self):
        """Get the previous focus datum, if set."""
        if self._c_ref == NULL:
            raise ValueError("Dataset not initialized")

        cdef DatumRef prev_focus_ref = DatasetGetPreviousFocus(self._c_ref)
        if prev_focus_ref == NULL:
            return None  # Return None if no previous focus datum set

        return Datum._from_c_ref(prev_focus_ref)

    @previous_focus.setter
    def previous_focus(self, value):
        """Set the previous focus datum."""
        if self._c_ref == NULL:
            raise ValueError("Dataset not initialized")

        cdef DatumRef prev_focus_ref = NULL

        if value is None:
            # Setting to None clears the previous focus
            prev_focus_ref = NULL
        elif isinstance(value, Datum):
            # Extract C reference from Datum object
            prev_focus_ref = (<Datum>value)._c_ref
        else:
            raise TypeError("previous_focus must be a Datum object or None")

        if not DatasetSetPreviousFocus(self._c_ref, prev_focus_ref):
            raise RMNError("Failed to set dataset previous focus")

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
                c_refs.append(<uint64_t>(<BaseDimension>dim)._c_ref)

            # Create OCArray from C references
            dims_ref = <OCArrayRef><uint64_t>ocarray_create_from_pylist(c_refs)
            if dims_ref == NULL:
                raise RMNError("Failed to create dimensions array")

            # Set dimensions in dataset
            if not DatasetSetDimensions(<DatasetRef>self._c_ref, <OCMutableArrayRef>dims_ref):
                raise RMNError("Failed to set dataset dimensions")

        finally:
            if dims_ref != NULL:
                OCRelease(<OCTypeRef>dims_ref)

    @property
    def dimension_precedence(self):
        """Get the dimension precedence ordering."""
        cdef OCMutableIndexArrayRef precedence_ref = DatasetGetDimensionPrecedence(<DatasetRef>self._c_ref)
        if precedence_ref == NULL:
            return []  # Return empty list if no precedence set

        # Convert OCIndexArray to Python list
        from rmnpy.helpers.octypes import ocindexarray_to_pylist
        return ocindexarray_to_pylist(<uint64_t>precedence_ref)

    @dimension_precedence.setter
    def dimension_precedence(self, value):
        """Set the dimension precedence ordering."""
        if not isinstance(value, (list, tuple)):
            raise TypeError("dimension_precedence must be a list or tuple")

        cdef OCMutableIndexArrayRef precedence_ref = NULL

        try:
            # Convert Python list to OCIndexArray
            from rmnpy.helpers.octypes import ocindexarray_create_from_pylist
            precedence_ref = <OCMutableIndexArrayRef><uint64_t>ocindexarray_create_from_pylist(list(value))
            if precedence_ref == NULL:
                raise RMNError("Failed to create precedence array")

            if not DatasetSetDimensionPrecedence(<DatasetRef>self._c_ref, precedence_ref):
                raise RMNError("Failed to set dimension precedence")

        finally:
            if precedence_ref != NULL:
                OCRelease(<OCTypeRef>precedence_ref)

    # Dependent variables management

    @property
    def dependent_variables(self):
        """Get the list of dependent variables in the dataset."""
        cdef OCMutableArrayRef vars_ref = DatasetGetDependentVariables(<DatasetRef>self._c_ref)
        if vars_ref == NULL:
            return []  # Return empty list if no dependent variables

        # Convert OCArray to Python list of DependentVariable objects
        cdef OCIndex count = OCArrayGetCount(<OCArrayRef>vars_ref)
        cdef list result = []
        cdef DependentVariableRef var_ref

        for i in range(count):
            var_ref = <DependentVariableRef>OCArrayGetValueAtIndex(<OCArrayRef>vars_ref, i)
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
                c_refs.append(<uint64_t>(<DependentVariable>var)._c_ref)

            # Create OCArray from C references
            vars_ref = <OCArrayRef><uint64_t>ocarray_create_from_pylist(c_refs)
            if vars_ref == NULL:
                raise RMNError("Failed to create dependent variables array")

            # Set dependent variables in dataset
            if not DatasetSetDependentVariables(<DatasetRef>self._c_ref, <OCMutableArrayRef>vars_ref):
                raise RMNError("Failed to set dataset dependent variables")

        finally:
            if vars_ref != NULL:
                OCRelease(<OCTypeRef>vars_ref)

    def get_dependent_variable_count(self):
        """
        Get the number of dependent variables in the dataset.

        Returns:
            int: Number of dependent variables
        """
        cdef OCMutableArrayRef vars_ref = DatasetGetDependentVariables(self._c_ref)
        if vars_ref == NULL:
            return 0

        cdef OCIndex count = OCArrayGetCount(<OCArrayRef>vars_ref)
        return <int>count

    def add_empty_dependent_variable(self, quantity_type, element_type, size):
        """
        Add an empty dependent variable to the dataset.

        Parameters:
            quantity_type : str
                The quantity type for the dependent variable
            element_type : OCNumberType or int
                The element type for the data
            size : int
                The size of the dependent variable

        Returns:
            DependentVariable: The newly created dependent variable

        Raises:
            RMNError: If creation fails
            TypeError: If parameters have incorrect types
        """
        if not isinstance(quantity_type, str):
            raise TypeError("quantity_type must be a string")
        if not isinstance(size, int) or size < 0:
            raise TypeError("size must be a non-negative integer")

        cdef OCStringRef qty_type_ref = NULL
        cdef DependentVariableRef dv_ref = NULL

        try:
            qty_type_ref = <OCStringRef><uint64_t>ocstring_create_from_pystring(quantity_type)
            if qty_type_ref == NULL:
                raise RMNError("Failed to create quantity type string")

            dv_ref = DatasetAddEmptyDependentVariable(
                self._c_ref,
                qty_type_ref,
                <OCNumberType>element_type,
                <OCIndex>size
            )
            if dv_ref == NULL:
                raise RMNError("Failed to add empty dependent variable")

            return DependentVariable._from_c_ref(dv_ref)

        finally:
            if qty_type_ref != NULL:
                OCRelease(<OCTypeRef>qty_type_ref)

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

        try:
            # Convert Python dictionary to OCDictionary
            metadata_ref = <OCDictionaryRef><uint64_t>ocdict_create_from_pydict(value)
            if metadata_ref == NULL:
                raise RMNError("Failed to create metadata dictionary")

            # Set metadata in dataset
            if not DatasetSetApplicationMetaData(<DatasetRef>self._c_ref, metadata_ref):
                raise RMNError("Failed to set dataset metadata")

        finally:
            if metadata_ref != NULL:
                OCRelease(<OCTypeRef>metadata_ref)

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

    def copy(self):
        """
        Create a deep copy of the dataset.

        Returns:
            Dataset: New dataset instance (deep copy)

        Raises:
            RMNError: If copying fails
        """
        cdef DatasetRef copied_ref = DatasetCreateCopy(self._c_ref)
        if copied_ref == NULL:
            raise RMNError("Failed to create copy of Dataset")

        # Create new Python object directly with copied reference (no additional copying)
        cdef Dataset new_dataset = Dataset.__new__(Dataset)
        new_dataset._c_ref = copied_ref
        return new_dataset

    # File I/O methods

    def export(self, json_path, binary_dir=None):
        """
        Export dataset to disk (.csdf/.csdfe format).

        Parameters:
            json_path : str
                Full path to JSON file (must end in .csdf or .csdfe)
            binary_dir : str, optional
                Directory for external data files (default: same as json_path directory)

        Raises:
            RMNError: If export fails
            TypeError: If paths are not strings
        """
        if not isinstance(json_path, str):
            raise TypeError("json_path must be a string")
        if binary_dir is not None and not isinstance(binary_dir, str):
            raise TypeError("binary_dir must be a string or None")

        cdef bytes json_path_bytes = json_path.encode('utf-8')
        cdef const char* c_json_path = json_path_bytes
        cdef bytes binary_dir_bytes
        cdef const char* c_binary_dir = NULL
        cdef OCStringRef err_ocstr = NULL

        try:
            if binary_dir is not None:
                binary_dir_bytes = binary_dir.encode('utf-8')
                c_binary_dir = binary_dir_bytes

            if not DatasetExport(self._c_ref, c_json_path, c_binary_dir, &err_ocstr):
                error_msg = ocstring_to_pystring(<uint64_t>err_ocstr) if err_ocstr else "Unknown error"
                raise RMNError(f"Dataset export failed: {error_msg}")

        finally:
            if err_ocstr != NULL:
                OCRelease(<OCTypeRef>err_ocstr)

    @classmethod
    def from_file(cls, json_path, binary_dir=None):
        """
        Load dataset from disk (.csdf/.csdfe format).

        Parameters:
            json_path : str
                Path to JSON file (.csdf/.csdfe)
            binary_dir : str, optional
                Directory containing external data files (default: same as json_path directory)

        Returns:
            Dataset: Loaded dataset instance

        Raises:
            RMNError: If loading fails
            TypeError: If paths are not strings
        """
        if not isinstance(json_path, str):
            raise TypeError("json_path must be a string")
        if binary_dir is not None and not isinstance(binary_dir, str):
            raise TypeError("binary_dir must be a string or None")

        cdef bytes json_path_bytes = json_path.encode('utf-8')
        cdef const char* c_json_path = json_path_bytes
        cdef bytes binary_dir_bytes
        cdef const char* c_binary_dir = NULL
        cdef OCStringRef err_ocstr = NULL
        cdef DatasetRef dataset_ref = NULL

        try:
            if binary_dir is not None:
                binary_dir_bytes = binary_dir.encode('utf-8')
                c_binary_dir = binary_dir_bytes

            dataset_ref = DatasetCreateWithImport(c_json_path, c_binary_dir, &err_ocstr)
            if dataset_ref == NULL:
                error_msg = ocstring_to_pystring(<uint64_t>err_ocstr) if err_ocstr else "Unknown error"
                raise RMNError(f"Dataset import failed: {error_msg}")

            return cls._from_c_ref(<uint64_t>dataset_ref)

        finally:
            if err_ocstr != NULL:
                OCRelease(<OCTypeRef>err_ocstr)
            if dataset_ref != NULL:
                OCRelease(<OCTypeRef>dataset_ref)

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
