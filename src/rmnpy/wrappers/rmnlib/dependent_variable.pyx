# cython: language_level=3
"""
DependentVariable Python wrapper

This module provides a Python interface to RMNLib's DependentVariable,
which represents N-dimensional dataset variables with support for:
- Internal/external storage
- Multiple components
- Sparse sampling
- Unit conversions
- Complex data manipulations
"""

from typing import Any, Dict, List, Optional, Tuple, Union

import cython
import numpy as np

from cython cimport bint
from libc.complex cimport double_complex, float_complex
from libc.stdint cimport int64_t

from rmnpy._c_api.octypes cimport *

# Import C API declarations
from rmnpy._c_api.rmnlib cimport *
from rmnpy._c_api.sitypes cimport *

# Import helper functions for OCTypes conversions
from rmnpy.helpers.octypes cimport (
    numpy_array_to_ocdata,
    ocarray_to_py_list,
    ocdata_to_numpy_array,
    ocdata_to_py_bytes,
    ocdictionary_to_py_dict,
    ocstring_to_py_string,
    octype_release,
    octype_retain,
    py_bytes_to_ocdata,
    py_dict_to_ocdictionary,
    py_list_to_ocarray,
    py_string_to_ocstring,
)
from rmnpy.wrappers.sitypes.dimensionality cimport Dimensionality
from rmnpy.wrappers.sitypes.scalar cimport Scalar

# Import SITypes wrappers
from rmnpy.wrappers.sitypes.unit cimport Unit

# Import custom exceptions

from rmnpy.exceptions import RMNLibError


cdef class DependentVariable:
    """
    Python wrapper for RMNLib's DependentVariable with csdmpy API compatibility.

    A DependentVariable represents p-component data values where p > 0. This class
    provides an interface compatible with the csdmpy library's DependentVariable API
    while leveraging RMNLib's underlying C implementation for performance.

    csdmpy API compatible attributes:
        type: Dependent variable subtype ('internal' or 'external')
        description: Brief description of the dependent variable
        application: Application metadata (dict)
        name: Name of the dependent variable
        unit: Unit associated with the dependent variable (use to() method to convert)
        quantity_name: Quantity name of physical quantities
        encoding: Encoding method ('raw', 'base64', 'none')
        numeric_type: Numeric type of component values
        quantity_type: Quantity type ('scalar', 'vector_n', 'pixel_n', etc.)
        component_labels: List of labels for each component
        components: Component array (numpy array)
        components_url: URL for external data storage (readonly)
        axis_label: Formatted string labels for components (readonly)
        data_structure: JSON string representation (readonly)

    csdmpy API compatible methods:
        to(unit): Convert unit of the dependent variable
        dict(): Return as python dictionary
        to_dict(): Alias for dict() method
        copy(): Return a copy of the DependentVariable

    RMNLib specific attributes:
        size: Number of elements per component
        component_count: Number of components
        dimensionality: Unit dimensionality
        element_size: Size in bytes of each element

    RMNLib inherited methods (from SIQuantity):
        has_numeric_type(type): Check if has specific numeric type
        is_complex_type(): Check if has complex numeric type
        has_dimensionality(dim): Check if has specific dimensionality
        has_same_dimensionality(other): Compare dimensionality with another quantity
        has_same_reduced_dimensionality(other): Compare reduced dimensionality
    """

    cdef DependentVariableRef _c_dependent_variable
    cdef bint _owner

    def __cinit__(self):
        self._c_dependent_variable = NULL
        self._owner = False

    def __dealloc__(self):
        if self._owner and self._c_dependent_variable:
            octype_release(<OCTypeRef>self._c_dependent_variable)

    @staticmethod
    def create(name: Optional[str] = None,
               description: Optional[str] = None,
               unit: Optional[Unit] = None,
               quantity_name: str = "unknown",
               quantity_type: str = "scalar",
               numeric_type: str = "float64",
               component_labels: Optional[List[str]] = None,
               components: Optional[List[bytes]] = None) -> "DependentVariable":
        """
        Create a new DependentVariable with internal storage.

        Args:
            name: Optional human-readable name
            description: Optional detailed description
            unit: Physical unit (SIUnit instance)
            quantity_name: Logical quantity name
            quantity_type: Semantic type ("scalar", "vector_2", "vector_3", etc.)
            numeric_type: Numeric storage type ("float32", "float64", "complex64", "complex128", etc.)
            component_labels: Optional labels for each component
            components: List of byte arrays containing component data

        Returns:
            New DependentVariable instance

        Raises:
            RMNLibError: If creation fails
        """
        cdef DependentVariable result = DependentVariable()
        cdef OCStringRef c_name = NULL
        cdef OCStringRef c_description = NULL
        cdef SIUnitRef c_unit = NULL
        cdef OCStringRef c_quantity_name = NULL
        cdef OCStringRef c_quantity_type = NULL
        cdef OCNumberType c_numeric_type
        cdef OCArrayRef c_component_labels = NULL
        cdef OCArrayRef c_components = NULL
        cdef OCStringRef error_msg = NULL

        try:
            # Convert parameters to C types
            if name is not None:
                c_name = py_string_to_ocstring(name)
            if description is not None:
                c_description = py_string_to_ocstring(description)
            if unit is not None:
                c_unit = unit._c_unit

            c_quantity_name = py_string_to_ocstring(quantity_name)
            c_quantity_type = py_string_to_ocstring(quantity_type)

            # Convert numeric type string to OCNumberType
            c_numeric_type = _numeric_type_from_string(numeric_type)

            # Convert component labels
            if component_labels is not None:
                c_component_labels = py_list_to_ocarray(component_labels)

            # Convert components
            if components is not None:
                py_data_list = []
                for comp_data in components:
                    py_data_list.append(comp_data)
                c_components = py_list_to_ocarray(py_data_list)

            # Create the DependentVariable
            result._c_dependent_variable = DependentVariableCreate(
                c_name, c_description, c_unit, c_quantity_name, c_quantity_type,
                c_numeric_type, c_component_labels, c_components, &error_msg)

            if result._c_dependent_variable == NULL:
                if error_msg:
                    error_str = ocstring_to_py_string(error_msg)
                    octype_release(<OCTypeRef>error_msg)
                    raise RMNLibError(f"Failed to create DependentVariable: {error_str}")
                else:
                    raise RMNLibError("Failed to create DependentVariable: unknown error")

            result._owner = True
            return result

        finally:
            # Clean up temporary C objects
            if c_name:
                octype_release(<OCTypeRef>c_name)
            if c_description:
                octype_release(<OCTypeRef>c_description)
            if c_quantity_name:
                octype_release(<OCTypeRef>c_quantity_name)
            if c_quantity_type:
                octype_release(<OCTypeRef>c_quantity_type)
            if c_component_labels:
                octype_release(<OCTypeRef>c_component_labels)
            if c_components:
                octype_release(<OCTypeRef>c_components)

    @staticmethod
    def create_with_size(name: Optional[str] = None,
                        description: Optional[str] = None,
                        unit: Optional[Unit] = None,
                        quantity_name: str = "unknown",
                        quantity_type: str = "scalar",
                        numeric_type: str = "float64",
                        component_labels: Optional[List[str]] = None,
                        size: int = 0) -> "DependentVariable":
        """
        Create a new DependentVariable pre-allocated with given size (zero-filled).

        Args:
            name: Optional human-readable name
            description: Optional detailed description
            unit: Physical unit (SIUnit instance)
            quantity_name: Logical quantity name
            quantity_type: Semantic type
            numeric_type: Numeric storage type
            component_labels: Optional labels for each component
            size: Number of elements per component

        Returns:
            New DependentVariable instance

        Raises:
            RMNLibError: If creation fails
        """
        cdef DependentVariable result = DependentVariable()
        cdef OCStringRef c_name = NULL
        cdef OCStringRef c_description = NULL
        cdef SIUnitRef c_unit = NULL
        cdef OCStringRef c_quantity_name = NULL
        cdef OCStringRef c_quantity_type = NULL
        cdef OCNumberType c_numeric_type
        cdef OCArrayRef c_component_labels = NULL
        cdef OCIndex c_size = size
        cdef OCStringRef error_msg = NULL

        try:
            # Convert parameters to C types
            if name is not None:
                c_name = py_string_to_ocstring(name)
            if description is not None:
                c_description = py_string_to_ocstring(description)
            if unit is not None:
                c_unit = unit._c_unit

            c_quantity_name = py_string_to_ocstring(quantity_name)
            c_quantity_type = py_string_to_ocstring(quantity_type)
            c_numeric_type = _numeric_type_from_string(numeric_type)

            if component_labels is not None:
                c_component_labels = py_list_to_ocarray(component_labels)

            # Create the DependentVariable
            result._c_dependent_variable = DependentVariableCreateWithSize(
                c_name, c_description, c_unit, c_quantity_name, c_quantity_type,
                c_numeric_type, c_component_labels, c_size, &error_msg)

            if result._c_dependent_variable == NULL:
                if error_msg:
                    error_str = ocstring_to_py_string(error_msg)
                    octype_release(<OCTypeRef>error_msg)
                    raise RMNLibError(f"Failed to create DependentVariable: {error_str}")
                else:
                    raise RMNLibError("Failed to create DependentVariable: unknown error")

            result._owner = True
            return result

        finally:
            # Clean up temporary C objects
            if c_name:
                octype_release(<OCTypeRef>c_name)
            if c_description:
                octype_release(<OCTypeRef>c_description)
            if c_quantity_name:
                octype_release(<OCTypeRef>c_quantity_name)
            if c_quantity_type:
                octype_release(<OCTypeRef>c_quantity_type)
            if c_component_labels:
                octype_release(<OCTypeRef>c_component_labels)

    @staticmethod
    def create_minimal(unit: Unit,
                      quantity_name: str,
                      quantity_type: str,
                      numeric_type: str,
                      components: List[bytes]) -> "DependentVariable":
        """
        Create a DependentVariable with minimal required parameters.

        Args:
            unit: Physical unit (required)
            quantity_name: Logical quantity name
            quantity_type: Semantic type
            numeric_type: Numeric storage type
            components: List of byte arrays containing component data

        Returns:
            New DependentVariable instance

        Raises:
            RMNLibError: If creation fails
        """
        cdef DependentVariable result = DependentVariable()
        cdef SIUnitRef c_unit = unit._c_unit
        cdef OCStringRef c_quantity_name = py_string_to_ocstring(quantity_name)
        cdef OCStringRef c_quantity_type = py_string_to_ocstring(quantity_type)
        cdef OCNumberType c_numeric_type = _numeric_type_from_string(numeric_type)
        cdef OCArrayRef c_components = py_list_to_ocarray(components)
        cdef OCStringRef error_msg = NULL

        try:
            result._c_dependent_variable = DependentVariableCreateMinimal(
                c_unit, c_quantity_name, c_quantity_type, c_numeric_type, c_components, &error_msg)

            if result._c_dependent_variable == NULL:
                if error_msg:
                    error_str = ocstring_to_py_string(error_msg)
                    octype_release(<OCTypeRef>error_msg)
                    raise RMNLibError(f"Failed to create DependentVariable: {error_str}")
                else:
                    raise RMNLibError("Failed to create DependentVariable: unknown error")

            result._owner = True
            return result

        finally:
            octype_release(<OCTypeRef>c_quantity_name)
            octype_release(<OCTypeRef>c_quantity_type)
            octype_release(<OCTypeRef>c_components)

    @staticmethod
    def create_external(name: Optional[str] = None,
                       description: Optional[str] = None,
                       unit: Optional[Unit] = None,
                       quantity_name: str = "unknown",
                       quantity_type: str = "scalar",
                       numeric_type: str = "float64",
                       components_url: str = "") -> "DependentVariable":
        """
        Create a DependentVariable with external storage.

        Args:
            name: Optional human-readable name
            description: Optional detailed description
            unit: Physical unit (SIUnit instance)
            quantity_name: Logical quantity name
            quantity_type: Semantic type
            numeric_type: Numeric storage type
            components_url: URL for external component data

        Returns:
            New DependentVariable instance

        Raises:
            RMNLibError: If creation fails
        """
        cdef DependentVariable result = DependentVariable()
        cdef OCStringRef c_name = NULL
        cdef OCStringRef c_description = NULL
        cdef SIUnitRef c_unit = NULL
        cdef OCStringRef c_quantity_name = NULL
        cdef OCStringRef c_quantity_type = NULL
        cdef OCNumberType c_numeric_type
        cdef OCStringRef c_components_url = NULL
        cdef OCStringRef error_msg = NULL

        try:
            # Convert parameters to C types
            if name is not None:
                c_name = py_string_to_ocstring(name)
            if description is not None:
                c_description = py_string_to_ocstring(description)
            if unit is not None:
                c_unit = unit._c_unit

            c_quantity_name = py_string_to_ocstring(quantity_name)
            c_quantity_type = py_string_to_ocstring(quantity_type)
            c_numeric_type = _numeric_type_from_string(numeric_type)
            c_components_url = py_string_to_ocstring(components_url)

            # Create the external DependentVariable
            result._c_dependent_variable = DependentVariableCreateExternal(
                c_name, c_description, c_unit, c_quantity_name, c_quantity_type,
                c_numeric_type, c_components_url, &error_msg)

            if result._c_dependent_variable == NULL:
                if error_msg:
                    error_str = ocstring_to_py_string(error_msg)
                    octype_release(<OCTypeRef>error_msg)
                    raise RMNLibError(f"Failed to create external DependentVariable: {error_str}")
                else:
                    raise RMNLibError("Failed to create external DependentVariable: unknown error")

            result._owner = True
            return result

        finally:
            # Clean up temporary C objects
            if c_name:
                octype_release(<OCTypeRef>c_name)
            if c_description:
                octype_release(<OCTypeRef>c_description)
            if c_quantity_name:
                octype_release(<OCTypeRef>c_quantity_name)
            if c_quantity_type:
                octype_release(<OCTypeRef>c_quantity_type)
            if c_components_url:
                octype_release(<OCTypeRef>c_components_url)

    def copy(self) -> "DependentVariable":
        """Create a deep copy of this DependentVariable."""
        if not self._c_dependent_variable:
            raise RMNLibError("Cannot copy null DependentVariable")

        cdef DependentVariable result = DependentVariable()
        result._c_dependent_variable = DependentVariableCopy(self._c_dependent_variable)
        if result._c_dependent_variable == NULL:
            raise RMNLibError("Failed to copy DependentVariable")

        result._owner = True
        return result

    # Properties
    @property
    def name(self) -> Optional[str]:
        """Get the name of this DependentVariable."""
        if not self._c_dependent_variable:
            return None
        cdef OCStringRef c_name = DependentVariableGetName(self._c_dependent_variable)
        if c_name:
            return ocstring_to_py_string(c_name)
        return None

    @name.setter
    def name(self, value: Optional[str]):
        """Set the name of this DependentVariable."""
        if not self._c_dependent_variable:
            raise RMNLibError("Cannot set name on null DependentVariable")

        cdef OCStringRef c_name = NULL
        if value is not None:
            c_name = py_string_to_ocstring(value)

        cdef bint success = DependentVariableSetName(self._c_dependent_variable, c_name)

        if c_name:
            octype_release(<OCTypeRef>c_name)

        if not success:
            raise RMNLibError("Failed to set name")

    @property
    def description(self) -> Optional[str]:
        """Get the description of this DependentVariable."""
        if not self._c_dependent_variable:
            return None
        cdef OCStringRef c_desc = DependentVariableGetDescription(self._c_dependent_variable)
        if c_desc:
            return ocstring_to_py_string(c_desc)
        return None

    @description.setter
    def description(self, value: Optional[str]):
        """Set the description of this DependentVariable."""
        if not self._c_dependent_variable:
            raise RMNLibError("Cannot set description on null DependentVariable")

        cdef OCStringRef c_desc = NULL
        if value is not None:
            c_desc = py_string_to_ocstring(value)

        cdef bint success = DependentVariableSetDescription(self._c_dependent_variable, c_desc)

        if c_desc:
            octype_release(<OCTypeRef>c_desc)

        if not success:
            raise RMNLibError("Failed to set description")

    @property
    def quantity_name(self) -> Optional[str]:
        """Get the quantity name of this DependentVariable."""
        if not self._c_dependent_variable:
            return None
        cdef OCStringRef c_name = DependentVariableGetQuantityName(self._c_dependent_variable)
        if c_name:
            return ocstring_to_py_string(c_name)
        return None

    @quantity_name.setter
    def quantity_name(self, value: str):
        """Set the quantity name of this DependentVariable."""
        if not self._c_dependent_variable:
            raise RMNLibError("Cannot set quantity_name on null DependentVariable")

        cdef OCStringRef c_name = py_string_to_ocstring(value)
        cdef bint success = DependentVariableSetQuantityName(self._c_dependent_variable, c_name)
        octype_release(<OCTypeRef>c_name)

        if not success:
            raise RMNLibError("Failed to set quantity_name")

    @property
    def quantity_type(self) -> Optional[str]:
        """Get the quantity type of this DependentVariable."""
        if not self._c_dependent_variable:
            return None
        cdef OCStringRef c_type = DependentVariableGetQuantityType(self._c_dependent_variable)
        if c_type:
            return ocstring_to_py_string(c_type)
        return None

    @quantity_type.setter
    def quantity_type(self, value: str):
        """Set the quantity type of this DependentVariable."""
        if not self._c_dependent_variable:
            raise RMNLibError("Cannot set quantity_type on null DependentVariable")

        cdef OCStringRef c_type = py_string_to_ocstring(value)
        cdef bint success = DependentVariableSetQuantityType(self._c_dependent_variable, c_type)
        octype_release(<OCTypeRef>c_type)

        if not success:
            raise RMNLibError("Failed to set quantity_type")

    # ==================================================================================
    # Additional csdmpy API compatibility properties
    # ==================================================================================

    @property
    def type(self) -> str:
        """Get the dependent variable subtype ('internal' or 'external') - csdmpy API."""
        cdef OCStringRef type_str = DependentVariableGetType(self._dv)
        if type_str == NULL:
            return "internal"  # Default fallback
        return oc_string_to_python(type_str)

    @type.setter
    def type(self, value: str) -> None:
        """Set the dependent variable subtype - csdmpy API."""
        cdef OCStringRef type_str = python_to_oc_string(value)
        try:
            if not DependentVariableSetType(self._dv, type_str):
                raise RuntimeError(f"Failed to set dependent variable type to '{value}'")
        finally:
            OCRelease(type_str)

    @property
    def application(self) -> Optional[Dict[str, Any]]:
        """Get application metadata - csdmpy API."""
        return self.get_metadata()

    @application.setter
    def application(self, value: Optional[Dict[str, Any]]):
        """Set application metadata - csdmpy API."""
        if value is None:
            value = {}
        success = self.set_metadata(value)
        if not success:
            raise RMNLibError("Failed to set application metadata")

    @property
    def encoding(self) -> str:
        """Get the encoding method ('raw', 'base64', 'none') - csdmpy API."""
        if not self._c_dependent_variable:
            return "raw"

        cdef OCStringRef c_encoding = DependentVariableGetEncoding(self._c_dependent_variable)
        if c_encoding == NULL:
            return "raw"  # Default encoding

        result = ocstring_to_py_string(c_encoding)
        # Note: Don't release c_encoding as it's a borrowed reference
        return result

    @encoding.setter
    def encoding(self, value: str):
        """Set the encoding method - csdmpy API."""
        valid_encodings = ["raw", "base64", "none"]
        if value not in valid_encodings:
            raise ValueError(f"Invalid encoding '{value}'. Must be one of {valid_encodings}")

        if not self._c_dependent_variable:
            raise RMNLibError("Cannot set encoding on null DependentVariable")

        cdef OCStringRef c_encoding = py_string_to_ocstring(value)
        try:
            if not DependentVariableSetEncoding(self._c_dependent_variable, c_encoding):
                raise RMNLibError(f"Failed to set encoding to '{value}'")
        finally:
            octype_release(<OCTypeRef>c_encoding)

    @property
    def components(self):
        """Get the component array (numpy array) - csdmpy API."""
        if not self._c_dependent_variable:
            return None

        cdef OCMutableArrayRef c_components = DependentVariableGetComponents(self._c_dependent_variable)
        if c_components == NULL:
            return None

        # Convert OCArray of OCData to list of numpy arrays
        component_arrays = []
        cdef int component_count = self.component_count
        cdef int size = self.size

        if component_count == 0 or size == 0:
            return np.array([])

        # Get the numeric type to determine numpy dtype
        numeric_type_str = self.numeric_type

        # Map RMNLib numeric types to numpy dtypes
        dtype_map = {
            "float32": np.float32,
            "float64": np.float64,
            "complex64": np.complex64,
            "complex128": np.complex128,
            "int8": np.int8,
            "int16": np.int16,
            "int32": np.int32,
            "int64": np.int64,
            "uint8": np.uint8,
            "uint16": np.uint16,
            "uint32": np.uint32,
            "uint64": np.uint64,
        }

        numpy_dtype = dtype_map.get(numeric_type_str, np.float64)

        # Extract each component and convert to numpy array
        for i in range(component_count):
            c_data = OCArrayGetElementAtIndex(<OCArrayRef>c_components, i)
            if c_data != NULL:
                # Convert OCData to numpy array with proper shape and dtype
                numpy_array = ocdata_to_numpy_array(<uint64_t>c_data, numpy_dtype, (size,))
                component_arrays.append(numpy_array)

        if len(component_arrays) == 1:
            # Single component: return 1D array
            return component_arrays[0]
        else:
            # Multiple components: return 2D array (components x size)
            return np.array(component_arrays)

    @components.setter
    def components(self, value):
        """Set the component array - csdmpy API."""
        if not self._c_dependent_variable:
            raise RMNLibError("Cannot set components on null DependentVariable")

        # Convert input to numpy array if it isn't already
        if not isinstance(value, np.ndarray):
            value = np.array(value)

        # Ensure array is contiguous
        if not value.flags.c_contiguous:
            value = np.ascontiguousarray(value)

        # Handle different array shapes
        if value.ndim == 1:
            # Single component
            component_arrays = [value]
        elif value.ndim == 2:
            # Multiple components (components x size)
            component_arrays = [value[i] for i in range(value.shape[0])]
        else:
            raise ValueError(f"Components array must be 1D or 2D, got {value.ndim}D")

        # Convert numpy arrays to OCData and create OCArray
        c_data_list = []
        try:
            for component_array in component_arrays:
                c_data = numpy_array_to_ocdata(component_array)
                c_data_list.append(c_data)

            # Create OCArray from the list of OCData
            cdef OCArrayRef c_components = py_list_to_ocarray([<uint64_t>data for data in c_data_list])

            # Set the components using C API
            success = DependentVariableSetComponents(self._c_dependent_variable, c_components)
            octype_release(<OCTypeRef>c_components)

            if not success:
                raise RMNLibError("Failed to set components")

        finally:
            # Clean up temporary OCData objects
            for c_data in c_data_list:
                if c_data != NULL:
                    octype_release(<OCTypeRef>c_data)

    @property
    def components_url(self) -> Optional[str]:
        """Get URL where data components are stored (readonly) - csdmpy API."""
        if not self._c_dependent_variable:
            return None

        cdef OCStringRef c_url = DependentVariableGetComponentsURL(self._c_dependent_variable)
        if c_url == NULL:
            return None

        return ocstring_to_py_string(c_url)

    @components_url.setter
    def components_url(self, value: Optional[str]):
        """Set URL where data components are stored - csdmpy API."""
        if not self._c_dependent_variable:
            raise RMNLibError("Cannot set components_url on null DependentVariable")

        cdef OCStringRef c_url = NULL
        if value is not None:
            c_url = py_string_to_ocstring(value)

        try:
            if not DependentVariableSetComponentsURL(self._c_dependent_variable, c_url):
                raise RMNLibError(f"Failed to set components_url to '{value}'")
        finally:
            if c_url:
                octype_release(<OCTypeRef>c_url)

    @property
    def axis_label(self) -> List[str]:
        """Get formatted string labels for each component (readonly) - csdmpy API."""
        if not self._c_dependent_variable:
            return []

        labels = []
        component_labels = self.get_component_labels()
        quantity_name = self.quantity_name or "quantity"
        unit_str = str(self.unit.symbol) if self.unit else "dimensionless"

        for i, label in enumerate(component_labels):
            if label:
                formatted_label = f"{label} / {unit_str}"
            else:
                formatted_label = f"{quantity_name} / {unit_str}"
            labels.append(formatted_label)

        return labels

    @property
    def data_structure(self) -> str:
        """Get JSON string representation (readonly) - csdmpy API."""
        if not self._c_dependent_variable:
            return "{}"

        # Use C API to create dictionary representation
        cdef OCDictionaryRef c_dict = DependentVariableCopyAsDictionary(self._c_dependent_variable)
        if c_dict == NULL:
            return "{}"

        try:
            # Convert OCDictionary to JSON using C API
            from rmnpy._c_api.rmnlib cimport OCMetadataCopyJSON
            cdef void* json_obj = OCMetadataCopyJSON(c_dict)
            if json_obj == NULL:
                return "{}"

            try:
                # Convert cJSON to string using cJSON C library
                from rmnpy._c_api.rmnlib cimport cJSON_Delete, cJSON_Print
                cdef char* json_string = cJSON_Print(<void*>json_obj)
                if json_string == NULL:
                    return "{}"

                try:
                    # Convert C string to Python string
                    result = json_string.decode('utf-8')
                    return result
                finally:
                    # Free the JSON string
                    from libc.stdlib cimport free
                    free(json_string)
            finally:
                # Free the JSON object
                cJSON_Delete(<void*>json_obj)

        finally:
            # Release the dictionary
            octype_release(<OCTypeRef>c_dict)

    # ==================================================================================
    # SIQuantity inherited methods (DependentVariable inherits from SIQuantity)
    # ==================================================================================

    @property
    def unit(self) -> Optional[Unit]:
        """Get the physical unit of this DependentVariable (inherited from SIQuantity)."""
        if not self._c_dependent_variable:
            return None

        cdef SIUnitRef c_unit = SIQuantityGetUnit(<SIQuantityRef>self._c_dependent_variable)
        if c_unit == NULL:
            return None

        # Create Unit wrapper around existing C unit (no ownership transfer)
        cdef Unit unit_wrapper = Unit()
        unit_wrapper._c_unit = c_unit
        unit_wrapper._owner = False
        return unit_wrapper

    @unit.setter
    def unit(self, value: Optional[Unit]):
        """Set the physical unit of this DependentVariable (inherited from SIQuantity)."""
        if not self._c_dependent_variable:
            raise RMNLibError("Cannot set unit on null DependentVariable")

        cdef SIUnitRef c_unit = NULL
        if value is not None:
            c_unit = value._c_unit

        cdef bint success = SIQuantitySetUnit(<SIMutableQuantityRef>self._c_dependent_variable, c_unit)
        if not success:
            raise RMNLibError("Failed to set unit")

    @property
    def dimensionality(self) -> Optional[Dimensionality]:
        """Get the dimensionality of this DependentVariable's unit (inherited from SIQuantity)."""
        if not self._c_dependent_variable:
            return None

        cdef SIDimensionalityRef c_dim = SIQuantityGetUnitDimensionality(<SIQuantityRef>self._c_dependent_variable)
        if c_dim == NULL:
            return None

        # Create Dimensionality wrapper around existing C dimensionality (no ownership transfer)
        cdef Dimensionality dim_wrapper = Dimensionality()
        dim_wrapper._c_dimensionality = c_dim
        dim_wrapper._owner = False
        return dim_wrapper

    @property
    def element_size(self) -> int:
        """Get the size in bytes of each element (inherited from SIQuantity)."""
        if not self._c_dependent_variable:
            return 0
        return SIQuantityElementSize(<SIQuantityRef>self._c_dependent_variable)

    def has_numeric_type(self, numeric_type: str) -> bool:
        """Check if this DependentVariable has the specified numeric type (inherited from SIQuantity)."""
        if not self._c_dependent_variable:
            return False
        cdef SINumberType c_type = _si_number_type_from_string(numeric_type)
        return SIQuantityHasNumericType(<SIQuantityRef>self._c_dependent_variable, c_type)

    def is_complex_type(self) -> bool:
        """Check if this DependentVariable has a complex numeric type (inherited from SIQuantity)."""
        if not self._c_dependent_variable:
            return False
        return SIQuantityIsComplexType(<SIQuantityRef>self._c_dependent_variable)

    def has_dimensionality(self, dimensionality: Dimensionality) -> bool:
        """Check if this DependentVariable has the specified dimensionality (inherited from SIQuantity)."""
        if not self._c_dependent_variable or not dimensionality:
            return False
        return SIQuantityHasDimensionality(<SIQuantityRef>self._c_dependent_variable, dimensionality._c_dimensionality)

    def has_same_dimensionality(self, other: "DependentVariable") -> bool:
        """Check if this DependentVariable has the same dimensionality as another (inherited from SIQuantity)."""
        if not self._c_dependent_variable or not other._c_dependent_variable:
            return False
        return SIQuantityHasSameDimensionality(<SIQuantityRef>self._c_dependent_variable, <SIQuantityRef>other._c_dependent_variable)

    def has_same_reduced_dimensionality(self, other: "DependentVariable") -> bool:
        """Check if this DependentVariable has the same reduced dimensionality as another (inherited from SIQuantity)."""
        if not self._c_dependent_variable or not other._c_dependent_variable:
            return False
        return SIQuantityHasSameReducedDimensionality(<SIQuantityRef>self._c_dependent_variable, <SIQuantityRef>other._c_dependent_variable)

    # Note: Following scalar.pyx pattern, we don't expose numeric_type property
    # It can be accessed internally via SIQuantityGetNumericType() if needed
    # However, for csdmpy API compatibility, we need to expose numeric_type

    @property
    def numeric_type(self) -> str:
        """Get the numeric type of this DependentVariable (csdmpy API compatibility)."""
        if not self._c_dependent_variable:
            return "unknown"
        cdef SINumberType c_type = SIQuantityGetNumericType(<SIQuantityRef>self._c_dependent_variable)
        return _si_number_type_to_string(c_type)

    @numeric_type.setter
    def numeric_type(self, value: str):
        """Set the numeric type of this DependentVariable (csdmpy API compatibility)."""
        if not self._c_dependent_variable:
            raise RMNLibError("Cannot set numeric_type on null DependentVariable")

        cdef OCNumberType c_type = _numeric_type_from_string(value)
        cdef bint success = DependentVariableSetNumericType(self._c_dependent_variable, c_type)

        if not success:
            raise RMNLibError("Failed to set numeric_type")

    # ==================================================================================
    # End of SIQuantity inherited methods
    # ==================================================================================

    # ==================================================================================
    # Properties and methods to mirror scalar.pyx API
    # Note: These should only be implemented if corresponding C functions exist
    # Wrappers should not perform calculations - all logic should be in C layer
    # ==================================================================================

    # Note: value, magnitude, real, imag, argument, phase properties are NOT implemented
    # because they would require the wrapper to perform calculations or complex logic.
    # All calculations should be done in the C layer with appropriate C functions.
    # If these properties are needed, corresponding C functions should be implemented first.

    # Boolean property methods to mirror scalar.pyx
    def is_real(self) -> bool:
        """Check if all values are real numbers (equivalent to scalar.is_real)."""
        return not self.is_complex_type()

    def is_complex(self) -> bool:
        """Check if the DependentVariable contains complex numbers (equivalent to scalar.is_complex)."""
        return self.is_complex_type()

    # Note: is_imaginary() is NOT implemented because it would require wrapper logic
    # to distinguish between "supports imaginary values" vs "all values are purely imaginary"
    # If needed, a corresponding C function should be implemented first

    # Note: is_zero() and is_infinite() are NOT implemented for DependentVariable
    # because they are ambiguous for arrays - do we check all elements? any element?
    # Users should access individual elements or use specialized array methods instead

    # Note: Unit conversion methods (to, can_convert_to, to_coherent_si, reduced)
    # are NOT implemented because they would require complex wrapper logic
    # for unit parsing, compatibility checking, and dimensional analysis.
    # All such logic should be implemented in the C layer with appropriate C functions.
    # If these methods are needed, corresponding C functions should be implemented first.
    #
    # However, for csdmpy API compatibility, we implement the to() method:

    def to(self, unit):
        """
        Convert the unit of the dependent variable to the target unit (csdmpy API).

        Args:
            unit (str or Unit): Target unit with same dimensionality
        """
        if not self._c_dependent_variable:
            raise RMNLibError("Cannot convert null DependentVariable")

        cdef SIUnitRef c_unit = NULL
        cdef OCStringRef error_msg = NULL

        try:
            # Handle both Unit objects and string representations
            if isinstance(unit, Unit):
                c_unit = unit._c_unit
            elif isinstance(unit, str):
                # Create temporary unit from string
                from rmnpy.wrappers.sitypes.unit import Unit
                temp_unit = Unit.create_from_symbol(unit)
                c_unit = temp_unit._c_unit
            else:
                raise RMNLibError("Unit must be a Unit object or string")

            # Call C API for unit conversion
            success = DependentVariableConvertToUnit(self._c_dependent_variable, c_unit, &error_msg)

            if not success:
                if error_msg:
                    error_str = ocstring_to_py_string(error_msg)
                    octype_release(<OCTypeRef>error_msg)
                    raise RMNLibError(f"Unit conversion failed: {error_str}")
                else:
                    raise RMNLibError("Unit conversion failed: unknown error")

        finally:
            if error_msg:
                octype_release(<OCTypeRef>error_msg)

    # ==================================================================================
    # csdmpy API dictionary methods
    # ==================================================================================

    def dict(self) -> Dict[str, Any]:
        """Return DependentVariable object as a python dictionary (csdmpy API)."""
        if not self._c_dependent_variable:
            return {}

        result = {
            "type": self.type,
            "description": self.description or "",
            "name": self.name or "",
            "unit": str(self.unit.symbol) if self.unit else "",
            "quantity_name": self.quantity_name or "",
            "encoding": self.encoding,
            "numeric_type": self.numeric_type,
            "quantity_type": self.quantity_type or "",
            "component_labels": self.get_component_labels(),
        }

        # Add components array if available
        try:
            # This would need numpy integration
            # result["components"] = self.components.tolist()
            pass
        except:
            pass

        # Add application metadata if available
        if self.application:
            result["application"] = self.application

        return result

    def to_dict(self) -> Dict[str, Any]:
        """Alias to the dict() method (csdmpy API)."""
        return self.dict()

    # ==================================================================================
    # End of scalar.pyx API mirror methods
    # ==================================================================================

    # ==================================================================================
    # Python operator overloading adapted for array semantics
    # ==================================================================================

    def __add__(self, other):
        """
        Add two DependentVariables (element-wise) or add scalar to all elements.
        Result maintains the unit from dimensional analysis.
        """
        if not self._c_dependent_variable:
            raise RMNLibError("Cannot add to null DependentVariable")

        # Create a copy to store the result
        result = self.copy()

        if isinstance(other, DependentVariable):
            # DependentVariable + DependentVariable: element-wise addition
            if not other._c_dependent_variable:
                raise RMNLibError("Cannot add null DependentVariable")

            success = DependentVariableAdd(result._c_dependent_variable, other._c_dependent_variable)
            if not success:
                raise RMNLibError("Failed to add DependentVariables")
        else:
            # DependentVariable + Scalar: broadcast addition
            from rmnpy.wrappers.sitypes.scalar import Scalar
            if isinstance(other, Scalar):
                scalar_ref = other._c_scalar
            else:
                # Convert to scalar if possible
                temp_scalar = Scalar.create(float(other))
                scalar_ref = temp_scalar._c_scalar

            # This would need a C API function for scalar addition
            raise RMNLibError("Scalar addition not yet implemented - needs C API support")

        return result

    def __radd__(self, other):
        """Right addition (other + self)."""
        return self.__add__(other)

    def __sub__(self, other):
        """
        Subtract DependentVariables (element-wise) or subtract scalar from all elements.
        Result maintains the unit from dimensional analysis.
        """
        if not self._c_dependent_variable:
            raise RMNLibError("Cannot subtract from null DependentVariable")

        # Create a copy to store the result
        result = self.copy()

        if isinstance(other, DependentVariable):
            # DependentVariable - DependentVariable: element-wise subtraction
            if not other._c_dependent_variable:
                raise RMNLibError("Cannot subtract null DependentVariable")

            success = DependentVariableSubtract(result._c_dependent_variable, other._c_dependent_variable)
            if not success:
                raise RMNLibError("Failed to subtract DependentVariables")
        else:
            # DependentVariable - Scalar: broadcast subtraction
            raise RMNLibError("Scalar subtraction not yet implemented - needs C API support")

        return result

    def __rsub__(self, other):
        """Right subtraction (other - self)."""
        # This would need to negate self then add to other
        raise RMNLibError("Right subtraction not yet implemented for DependentVariable")

    def __mul__(self, other):
        """
        Multiply DependentVariables (element-wise) or multiply all elements by scalar.
        Result unit follows dimensional analysis rules.
        """
        if not self._c_dependent_variable:
            raise RMNLibError("Cannot multiply null DependentVariable")

        # Create a copy to store the result
        result = self.copy()

        if isinstance(other, DependentVariable):
            # DependentVariable * DependentVariable: element-wise multiplication
            if not other._c_dependent_variable:
                raise RMNLibError("Cannot multiply by null DependentVariable")

            success = DependentVariableMultiply(result._c_dependent_variable, other._c_dependent_variable)
            if not success:
                raise RMNLibError("Failed to multiply DependentVariables")
        else:
            # DependentVariable * Scalar: broadcast multiplication
            if isinstance(other, (int, float)):
                # Use the existing multiply_by_constant method for dimensionless constants
                success = result.multiply_by_constant(float(other))
                if not success:
                    raise RMNLibError("Failed to multiply by scalar constant")
            elif isinstance(other, complex):
                success = result.multiply_by_constant(other)
                if not success:
                    raise RMNLibError("Failed to multiply by complex constant")
            else:
                raise RMNLibError("Unsupported multiplication operand type")

        return result

    def __rmul__(self, other):
        """Right multiplication (other * self)."""
        return self.__mul__(other)

    def __truediv__(self, other):
        """
        Divide DependentVariables (element-wise) or divide all elements by scalar.
        Result unit follows dimensional analysis rules.
        """
        if not self._c_dependent_variable:
            raise RMNLibError("Cannot divide null DependentVariable")

        # Create a copy to store the result
        result = self.copy()

        if isinstance(other, DependentVariable):
            # DependentVariable / DependentVariable: element-wise division
            if not other._c_dependent_variable:
                raise RMNLibError("Cannot divide by null DependentVariable")

            success = DependentVariableDivide(result._c_dependent_variable, other._c_dependent_variable)
            if not success:
                raise RMNLibError("Failed to divide DependentVariables")
        else:
            # DependentVariable / Scalar: broadcast division (multiply by 1/scalar)
            if isinstance(other, (int, float)):
                if other == 0:
                    raise ZeroDivisionError("Cannot divide by zero")
                success = result.multiply_by_constant(1.0 / float(other))
                if not success:
                    raise RMNLibError("Failed to divide by scalar constant")
            elif isinstance(other, complex):
                if other == 0:
                    raise ZeroDivisionError("Cannot divide by zero")
                success = result.multiply_by_constant(1.0 / other)
                if not success:
                    raise RMNLibError("Failed to divide by complex constant")
            else:
                raise RMNLibError("Unsupported division operand type")

        return result

    def __rtruediv__(self, other):
        """Right division (other / self)."""
        raise RMNLibError("Right division not yet implemented for DependentVariable")

    def __pow__(self, other):
        """
        Raise all elements to a power (scalar exponent only).
        Unit raised to the same power.
        """
        if not self._c_dependent_variable:
            raise RMNLibError("Cannot raise null DependentVariable to power")

        raise RMNLibError("Power operations not yet implemented for DependentVariable")

    # Note: __abs__ is NOT implemented because it would require wrapper logic
    # (copy + take_absolute_value). If absolute value is needed, either:
    # 1. Use the existing take_absolute_value() method (modifies in place), or
    # 2. Implement a C function that returns a new DependentVariable with absolute values

    def __neg__(self):
        """Negate all elements in the DependentVariable."""
        if not self._c_dependent_variable:
            raise RMNLibError("Cannot negate null DependentVariable")

        raise RMNLibError("Negation not yet implemented for DependentVariable")

    def __pos__(self):
        """Positive operator (returns copy)."""
        return self.copy()

    # Note: Comparison operators (__eq__, __ne__, __lt__, __le__, __gt__, __ge__)
    # are NOT implemented for DependentVariable because array comparisons are ambiguous:
    # - Should we compare element-wise and return a boolean array?
    # - Should we return True only if ALL elements satisfy the condition?
    # - Should we return True if ANY element satisfies the condition?
    # Users should access individual elements or use specialized array comparison methods instead

    # Note: nth_root() is NOT implemented for DependentVariable because it's ambiguous
    # for arrays and would require specialized array mathematical operations
    # Users should use numpy or other array libraries for advanced mathematical operations

    # ==================================================================================
    # End of Python operator overloading
    # ==================================================================================

    @property
    def size(self) -> int:
        """Get the size (number of elements per component) of this DependentVariable."""
        if not self._c_dependent_variable:
            return 0
        return DependentVariableGetSize(self._c_dependent_variable)

    @size.setter
    def size(self, value: int):
        """Set the size of this DependentVariable."""
        if not self._c_dependent_variable:
            raise RMNLibError("Cannot set size on null DependentVariable")

        cdef bint success = DependentVariableSetSize(self._c_dependent_variable, value)
        if not success:
            raise RMNLibError("Failed to set size")

    @property
    def component_count(self) -> int:
        """Get the number of components in this DependentVariable."""
        if not self._c_dependent_variable:
            return 0
        return DependentVariableGetComponentCount(self._c_dependent_variable)

    # Component data access
    def get_component_data(self, index: int) -> bytes:
        """Get the raw data for a specific component as bytes."""
        if not self._c_dependent_variable:
            raise RMNLibError("Cannot get component data from null DependentVariable")

        cdef OCDataRef c_data = DependentVariableGetComponentAtIndex(self._c_dependent_variable, index)
        if c_data == NULL:
            raise RMNLibError(f"Component {index} not found or invalid")

        return ocdata_to_py_bytes(c_data)

    def set_component_data(self, index: int, data: bytes):
        """Set the raw data for a specific component."""
        if not self._c_dependent_variable:
            raise RMNLibError("Cannot set component data on null DependentVariable")

        cdef OCDataRef c_data = py_bytes_to_ocdata(data)
        cdef bint success = DependentVariableSetComponentAtIndex(self._c_dependent_variable, c_data, index)
        octype_release(<OCTypeRef>c_data)

        if not success:
            raise RMNLibError(f"Failed to set component {index} data")

    # Component labels
    def get_component_labels(self) -> List[str]:
        """Get all component labels."""
        if not self._c_dependent_variable:
            return []

        cdef OCArrayRef c_labels = DependentVariableGetComponentLabels(self._c_dependent_variable)
        if c_labels == NULL:
            return []

        return ocarray_to_py_list(c_labels)

    def set_component_labels(self, labels: List[str]):
        """Set all component labels."""
        if not self._c_dependent_variable:
            raise RMNLibError("Cannot set component labels on null DependentVariable")

        cdef OCArrayRef c_labels = py_list_to_ocarray(labels)
        cdef bint success = DependentVariableSetComponentLabels(self._c_dependent_variable, c_labels)
        octype_release(<OCTypeRef>c_labels)

        if not success:
            raise RMNLibError("Failed to set component labels")

    def get_component_label(self, index: int) -> Optional[str]:
        """Get the label for a specific component."""
        if not self._c_dependent_variable:
            return None

        cdef OCStringRef c_label = DependentVariableGetComponentLabelAtIndex(self._c_dependent_variable, index)
        if c_label:
            return ocstring_to_py_string(c_label)
        return None

    # Data manipulation methods
    def set_values_to_zero(self, component_index: int = -1) -> bool:
        """
        Set all values in the DependentVariable (or specific component) to zero.

        Args:
            component_index: Component to zero (-1 for all components)

        Returns:
            True if successful
        """
        if not self._c_dependent_variable:
            return False
        return DependentVariableSetValuesToZero(self._c_dependent_variable, component_index)

    def take_absolute_value(self, component_index: int = -1) -> bool:
        """
        Replace each value with its absolute value.

        Args:
            component_index: Component to process (-1 for all components)

        Returns:
            True if successful
        """
        if not self._c_dependent_variable:
            return False
        return DependentVariableTakeAbsoluteValue(self._c_dependent_variable, component_index)

    def conjugate(self, component_index: int = -1) -> bool:
        """
        Take complex conjugate of all values.

        Args:
            component_index: Component to process (-1 for all components)

        Returns:
            True if successful
        """
        if not self._c_dependent_variable:
            return False
        return DependentVariableConjugate(self._c_dependent_variable, component_index)

    def multiply_by_constant(self, constant: Union[float, complex], component_index: int = -1) -> bool:
        """
        Multiply all values by a dimensionless constant.

        Args:
            constant: Real or complex constant to multiply by
            component_index: Component to process (-1 for all components)

        Returns:
            True if successful
        """
        if not self._c_dependent_variable:
            return False

        if isinstance(constant, complex):
            cdef double_complex c_constant = constant.real + 1j * constant.imag
            return DependentVariableMultiplyValuesByDimensionlessComplexConstant(
                self._c_dependent_variable, component_index, c_constant)
        else:
            cdef double c_constant = float(constant)
            return DependentVariableMultiplyValuesByDimensionlessRealConstant(
                self._c_dependent_variable, component_index, c_constant)

    def set_values_to_zero(self, component_index: int = -1) -> bool:
        """
        Set all values to zero for specified component(s).

        Args:
            component_index: Component to process (-1 for all components)

        Returns:
            True if successful
        """
        if not self._c_dependent_variable:
            return False
        return DependentVariableSetValuesToZero(self._c_dependent_variable, component_index)

    def take_complex_part(self, component_index: int, part: str) -> bool:
        """
        Extract specific part of complex numbers.

        Args:
            component_index: Component to process
            part: Part to extract ('real', 'imaginary', 'magnitude', 'argument')

        Returns:
            True if successful
        """
        if not self._c_dependent_variable:
            return False

        cdef complexPart c_part
        if part == "real":
            c_part = kSIRealPart
        elif part == "imaginary":
            c_part = kSIImaginaryPart
        elif part == "magnitude":
            c_part = kSIMagnitudePart
        elif part == "argument":
            c_part = kSIArgumentPart
        else:
            raise ValueError(f"Unknown complex part: {part}")

        return DependentVariableTakeComplexPart(self._c_dependent_variable, component_index, c_part)

    # Additional C API wrapper functions for metadata and external storage
    def get_metadata(self) -> Dict[str, Any]:
        """Get metadata dictionary."""
        if not self._c_dependent_variable:
            return {}

        cdef OCDictionaryRef c_metadata = DependentVariableGetMetaData(self._c_dependent_variable)
        if c_metadata == NULL:
            return {}

        result = ocdictionary_to_py_dict(c_metadata)
        # Note: Don't release c_metadata as it's a borrowed reference
        return result

    def set_metadata(self, metadata: Dict[str, Any]) -> bool:
        """Set metadata dictionary."""
        if not self._c_dependent_variable:
            return False

        cdef OCDictionaryRef c_metadata = py_dict_to_ocdictionary(metadata)
        success = DependentVariableSetMetaData(self._c_dependent_variable, c_metadata)
        octype_release(<OCTypeRef>c_metadata)
        return success

    def set_components_url(self, url: str) -> bool:
        """Set external components URL."""
        if not self._c_dependent_variable:
            return False

        cdef OCStringRef c_url = py_string_to_ocstring(url)
        success = DependentVariableSetComponentsURL(self._c_dependent_variable, c_url)
        octype_release(<OCTypeRef>c_url)
        return success

    def set_encoding(self, encoding: str) -> bool:
        """Set encoding method."""
        if not self._c_dependent_variable:
            return False

        cdef OCStringRef c_encoding = py_string_to_ocstring(encoding)
        success = DependentVariableSetEncoding(self._c_dependent_variable, c_encoding)
        octype_release(<OCTypeRef>c_encoding)
        return success

    def set_size(self, new_size: int) -> bool:
        """Set the size (number of elements per component)."""
        if not self._c_dependent_variable:
            return False

        return DependentVariableSetSize(self._c_dependent_variable, new_size)

    def append(self, other: "DependentVariable") -> bool:
        """Append another DependentVariable to this one."""
        if not self._c_dependent_variable or not other._c_dependent_variable:
            return False

        cdef OCStringRef error_msg = NULL
        success = DependentVariableAppend(self._c_dependent_variable, other._c_dependent_variable, &error_msg)

        if not success and error_msg:
            error_str = ocstring_to_py_string(error_msg)
            octype_release(<OCTypeRef>error_msg)
            raise RMNLibError(f"Failed to append DependentVariable: {error_str}")
        elif error_msg:
            octype_release(<OCTypeRef>error_msg)

        return success

    # Serialization
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary representation."""
        if not self._c_dependent_variable:
            return {}

        cdef OCDictionaryRef c_dict = DependentVariableCopyAsDictionary(self._c_dependent_variable)
        if c_dict == NULL:
            return {}

        result = ocdictionary_to_py_dict(c_dict)
        octype_release(<OCTypeRef>c_dict)
        return result

    @staticmethod
    def create_from_dict(data: Dict[str, Any]) -> "DependentVariable":
        """Create DependentVariable from dictionary representation."""
        cdef DependentVariable result = DependentVariable()
        cdef OCDictionaryRef c_dict = py_dict_to_ocdictionary(data)
        cdef OCStringRef error_msg = NULL

        try:
            result._c_dependent_variable = DependentVariableCreateFromDictionary(c_dict, &error_msg)

            if result._c_dependent_variable == NULL:
                if error_msg:
                    error_str = ocstring_to_py_string(error_msg)
                    octype_release(<OCTypeRef>error_msg)
                    raise RMNLibError(f"Failed to create DependentVariable from dict: {error_str}")
                else:
                    raise RMNLibError("Failed to create DependentVariable from dict: unknown error")

            result._owner = True
            return result

        finally:
            octype_release(<OCTypeRef>c_dict)
            if error_msg:
                octype_release(<OCTypeRef>error_msg)

    def __repr__(self) -> str:
        if not self._c_dependent_variable:
            return "DependentVariable(null)"

        unit_str = "None"
        if self.unit:
            unit_str = f"'{self.unit.symbol}'"

        # csdmpy-style representation with key attributes
        return (f"DependentVariable(name='{self.name}', "
                f"type='{self.type}', "
                f"quantity_type='{self.quantity_type}', "
                f"numeric_type='{self.numeric_type}', "
                f"unit={unit_str}, "
                f"components={self.component_count})")


# Helper functions for element type conversion
cdef OCNumberType _numeric_type_from_string(str type_str):
    """Convert string element type to OCNumberType."""
    type_map = {
        "int8": kOCNumberSInt8Type,
        "uint8": kOCNumberUInt8Type,
        "int16": kOCNumberSInt16Type,
        "uint16": kOCNumberUInt16Type,
        "int32": kOCNumberSInt32Type,
        "uint32": kOCNumberUInt32Type,
        "int64": kOCNumberSInt64Type,
        "uint64": kOCNumberUInt64Type,
        "float32": kOCNumberFloat32Type,
        "float64": kOCNumberFloat64Type,
        "complex64": kOCNumberComplex64Type,
        "complex128": kOCNumberComplex128Type,
    }
    return type_map.get(type_str, kOCNumberFloat64Type)


cdef str _numeric_type_to_string(OCNumberType type_id):
    """Convert OCNumberType to string representation."""
    type_map = {
        kOCNumberSInt8Type: "int8",
        kOCNumberUInt8Type: "uint8",
        kOCNumberSInt16Type: "int16",
        kOCNumberUInt16Type: "uint16",
        kOCNumberSInt32Type: "int32",
        kOCNumberUInt32Type: "uint32",
        kOCNumberSInt64Type: "int64",
        kOCNumberUInt64Type: "uint64",
        kOCNumberFloat32Type: "float32",
        kOCNumberFloat64Type: "float64",
        kOCNumberComplex64Type: "complex64",
        kOCNumberComplex128Type: "complex128",
    }
    return type_map.get(type_id, "unknown")


cdef SINumberType _si_number_type_from_string(str type_str):
    """Convert string to SINumberType.

    Note: SINumberType only supports float and complex types, not integers.
    Integer types should use OCNumberType instead.
    """
    type_map = {
        "float32": kSINumberFloat32Type,
        "float64": kSINumberFloat64Type,
        "complex64": kSINumberComplex64Type,
        "complex128": kSINumberComplex128Type,
    }
    # Default to float64 for unsupported types (like integers)
    return type_map.get(type_str, kSINumberFloat64Type)


cdef str _si_number_type_to_string(SINumberType type_id):
    """Convert SINumberType to string representation."""
    type_map = {
        kSINumberFloat32Type: "float32",
        kSINumberFloat64Type: "float64",
        kSINumberComplex64Type: "complex64",
        kSINumberComplex128Type: "complex128",
    }
    return type_map.get(type_id, "unknown")
