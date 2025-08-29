# cython: language_level=3
"""
RMNLib DependentVariable wrapper.

Provides Python access to RMNLib DependentVariable C API for managing measured
or computed data values with associated metadata, units, and components.

DependentVariables represent the core data arrays in scientific measurements,
including time series, spectra, images, and multi-dimensional datasets. Each
DependentVariable contains one or more data components with consistent metadata
including physical units, quantity type classification, and descriptive labels.

Features:
    - Multi-component data arrays with SI units
    - JSON serialization and type-safe storage
    - Sparse sampling for irregular data
"""

import numpy as np

cimport numpy as cnp
from libc.stdint cimport uint64_t, uintptr_t

cnp.import_array()

from rmnpy._c_api.octypes cimport *
from rmnpy._c_api.rmnlib cimport *
from rmnpy._c_api.sitypes cimport *

from rmnpy.exceptions import RMNError
from rmnpy.helpers.octypes import (
    element_type_to_numpy_dtype,
    enum_to_element_type,
    ocarray_create_from_pylist,
    ocarray_to_pylist,
    ocdata_create_from_numpy_array,
    ocdict_create_from_pydict,
    ocdict_to_pydict,
    ocstring_create_from_pystring,
    ocstring_to_pystring,
)

from rmnpy.wrappers.base_wrapper cimport BaseWrapper, RMNLibWrapper
from rmnpy.wrappers.rmnlib.sparse_sampling cimport SparseSampling
from rmnpy.wrappers.sitypes.unit cimport Unit


cdef class DependentVariable(RMNLibWrapper):
    """Scientific data container with metadata and SI units.

    Manages multi-component numerical arrays representing measured or computed
    data values. Supports various quantity types (scalars, vectors, tensors),
    automatic unit conversion, and sparse sampling for irregular data.

    DependentVariable objects contain one or more data components with consistent
    metadata including physical units, quantity type classification, numeric
    precision, and descriptive labels. They form the core data structure for
    scientific measurements in RMNLib.

    Parameters:
        components: List of array-like data (required)
        name: Human-readable identifier
        description: Detailed description of the data
        unit: Physical unit (string, Unit object, or None)
        quantity_name: Logical quantity identifier (e.g., "temperature")
        quantity_type: Data structure type ("scalar", "vector_2", "vector_3", "tensor_2", etc.)
        element_type: Numeric storage type ("float32", "float64", "int32", etc.)
        component_labels: List of component names

    Examples:
        Basic usage:

        >>> import numpy as np
        >>> data = np.array([1.5, 2.3, 3.1])
        >>> dep_var = DependentVariable(components=[data], name="Temperature")
        >>> dep_var.size
        3

        Multi-component data:

        >>> x_data = np.array([1.0, 2.0])
        >>> y_data = np.array([0.5, 1.5])
        >>> vector = DependentVariable(
        ...     components=[x_data, y_data],
        ...     quantity_type="vector_2"
        ... )
        >>> vector.component_count
        2
    """

    @staticmethod
    def from_c_ref(uintptr_t dep_var_ref_ptr):
        """Create DependentVariable wrapper from C reference pointer."""
        return <DependentVariable>BaseWrapper._from_c_ref(DependentVariable, <void*><DependentVariableRef>dep_var_ref_ptr)

    @staticmethod
    def from_dict(dict json_dict):
        """Create DependentVariable from dictionary representation.

        Reconstructs a DependentVariable from its JSON/dictionary serialization,
        restoring all metadata, units, and data components.

        Args:
            json_dict (dict): Dictionary containing DependentVariable data.
                Expected keys include 'name', 'description', 'components',
                'unit', 'quantity_type', 'element_type', etc.

        Returns:
            DependentVariable: Newly constructed DependentVariable instance

        Raises:
            RMNError: If dictionary format is invalid or creation fails

        Examples:
            >>> data_dict = {"components": [[1.0, 2.0, 3.0]]}
            >>> dep_var = DependentVariable.from_dict(data_dict)
        """
        # Convert Python dict to OCDictionary using existing helper
        cdef uintptr_t dict_ptr = ocdict_create_from_pydict(json_dict)
        cdef OCDictionaryRef dict_ref = <OCDictionaryRef>dict_ptr

        cdef OCStringRef err_ocstr = NULL
        cdef DependentVariableRef dv_ref = NULL

        try:
            # Call C API to create dependent variable from dictionary
            dv_ref = DependentVariableCreateFromJSON(dict_ref, &err_ocstr)
            if dv_ref == NULL:
                if err_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uintptr_t>err_ocstr)
                    raise RMNError(f"Failed to create dependent variable from dictionary: {error_msg}")
                else:
                    raise RMNError("Failed to create dependent variable from dictionary: Unknown error")

            # Create wrapper using BaseWrapper._from_c_ref
            return <DependentVariable>BaseWrapper._from_c_ref(DependentVariable, <void*>dv_ref)

        finally:
            # Clean up resources
            if dv_ref != NULL:
                OCRelease(<OCTypeRef>dv_ref)
            if err_ocstr != NULL:
                OCRelease(<OCTypeRef>err_ocstr)
            if dict_ref != NULL:
                OCRelease(<OCTypeRef>dict_ref)

    def __init__(self,
                 components,
                 name=None,
                 description=None,
                 unit=None,
                 quantity_name=None,
                 quantity_type="scalar",
                 element_type="float64",
                 component_labels=None):
        """Initialize DependentVariable with data components and metadata.

        Args:
            components: List of array-like data buffers for each component (required)
            name: Human-readable name
            description: Longer description
            unit: SI unit specification (string, Unit object, or None)
            quantity_name: Logical quantity name (e.g. "temperature")
            quantity_type: Semantic type ("scalar", "vector_2", etc.)
            element_type: Numeric storage type (default "float64")
            component_labels: Labels for components
        """
        if self._c_ref != NULL:
            return  # Already initialized by _from_c_ref

        cdef OCStringRef name_ocstr = NULL
        cdef OCStringRef desc_ocstr = NULL
        cdef SIUnitRef unit_ref = NULL
        cdef OCStringRef quantity_name_ocstr = NULL
        cdef OCStringRef quantity_type_ocstr = NULL
        cdef OCNumberType element_type_enum
        cdef OCArrayRef component_labels_array = NULL
        cdef OCArrayRef components_array = NULL
        cdef OCStringRef err_ocstr = NULL
        cdef DependentVariableRef result = NULL

        try:
            if name is not None:
                name_ocstr = <OCStringRef><uintptr_t>ocstring_create_from_pystring(name)
            if description is not None:
                desc_ocstr = <OCStringRef><uintptr_t>ocstring_create_from_pystring(description)

            unit_ref = <SIUnitRef>Unit.from_value(unit)._get_c_ref()

            if quantity_name is not None:
                quantity_name_ocstr = <OCStringRef><uintptr_t>ocstring_create_from_pystring(quantity_name)
            if quantity_type is not None:
                quantity_type_ocstr = <OCStringRef><uintptr_t>ocstring_create_from_pystring(quantity_type)

            element_type_enum = self._element_type_to_enum(element_type)

            if component_labels is not None:
                component_labels_array = <OCArrayRef><uintptr_t>ocarray_create_from_pylist(component_labels)

            if components is not None:
                components_array = <OCArrayRef><uintptr_t>ocarray_create_from_pylist(components)

            self._c_ref = DependentVariableCreate(
                name_ocstr,
                desc_ocstr,
                unit_ref,
                quantity_name_ocstr,
                quantity_type_ocstr,
                element_type_enum,
                component_labels_array,
                components_array,
                &err_ocstr
            )

            if self._c_ref == NULL:
                if err_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uintptr_t>err_ocstr)
                    raise RMNError(f"Failed to create DependentVariable: {error_msg}")
                else:
                    raise RMNError("Failed to create DependentVariable")

        finally:
            # Clean up temporary OCTypes
            if name_ocstr != NULL:
                OCRelease(<OCTypeRef>name_ocstr)
            if desc_ocstr != NULL:
                OCRelease(<OCTypeRef>desc_ocstr)
            if quantity_name_ocstr != NULL:
                OCRelease(<OCTypeRef>quantity_name_ocstr)
            if quantity_type_ocstr != NULL:
                OCRelease(<OCTypeRef>quantity_type_ocstr)
            if component_labels_array != NULL:
                OCRelease(<OCTypeRef>component_labels_array)
            if components_array != NULL:
                OCRelease(<OCTypeRef>components_array)
            if err_ocstr != NULL:
                OCRelease(<OCTypeRef>err_ocstr)

    cdef OCNumberType _element_type_to_enum(self, element_type):
        """Convert string element type to OCNumberType enum using OCTypes helper."""
        cdef bytes element_type_bytes = element_type.encode('utf-8')
        cdef const char* element_type_cstr = element_type_bytes
        cdef OCNumberType result = OCNumberTypeFromName(element_type_cstr)

        if result == 0:  # kOCNumberTypeInvalid
            raise ValueError(f"Invalid element_type: {element_type}. Use a valid OCNumberType name.")

        return result

    @property
    def _c_ref(self):
        """Get the C reference as uintptr_t for use by octypes helpers."""
        return <uintptr_t><void*>self._c_ref

    @property
    def name(self):
        """Get the name of the DependentVariable."""
        cdef OCStringRef name_ref = DependentVariableCopyName(self._c_ref)
        if name_ref == NULL:
            raise RMNError("Failed to get name - C reference may be corrupt")
        try:
            return ocstring_to_pystring(<uintptr_t>name_ref)
        finally:
            OCRelease(<OCTypeRef>name_ref)

    @name.setter
    def name(self, value):
        """Set the name of the DependentVariable."""
        cdef OCStringRef name_ocstr = NULL

        try:
            if value is not None:
                name_ocstr = <OCStringRef><uintptr_t>ocstring_create_from_pystring(value)
            success = DependentVariableSetName(self._c_ref, name_ocstr)
            if not success:
                raise RMNError("Failed to set name")
        finally:
            if name_ocstr != NULL:
                OCRelease(<OCTypeRef>name_ocstr)

    @property
    def quantity_name(self):
        """Get the quantity name."""
        cdef OCStringRef quantity_name_ref = DependentVariableCopyQuantityName(self._c_ref)
        if quantity_name_ref == NULL:
            return None
        try:
            return ocstring_to_pystring(<uintptr_t>quantity_name_ref)
        finally:
            OCRelease(<OCTypeRef>quantity_name_ref)

    @quantity_name.setter
    def quantity_name(self, value):
        """Set the quantity name of the DependentVariable."""
        cdef OCStringRef qname_ocstr = NULL

        try:
            if value is not None:
                qname_ocstr = <OCStringRef><uintptr_t>ocstring_create_from_pystring(value)
            success = DependentVariableSetQuantityName(self._c_ref, qname_ocstr)
            if not success:
                raise RMNError("Failed to set quantity name")
        finally:
            if qname_ocstr != NULL:
                OCRelease(<OCTypeRef>qname_ocstr)

    @property
    def quantity_type(self):
        """Get the quantity type."""
        cdef OCStringRef qtype_ref = DependentVariableCopyQuantityType(self._c_ref)
        if qtype_ref == NULL:
            raise RMNError("Failed to get quantity_type - C reference may be corrupt")
        try:
            return ocstring_to_pystring(<uintptr_t>qtype_ref)
        finally:
            OCRelease(<OCTypeRef>qtype_ref)

    @property
    def element_type(self):
        """Get the numeric element type."""
        cdef OCNumberType elem_type = DependentVariableGetNumericType(self._c_ref)
        return enum_to_element_type(elem_type)

    @property
    def component_count(self):
        """Get the number of components."""
        return DependentVariableGetComponentCount(self._c_ref)

    @property
    def size(self):
        """Get the size (number of elements per component)."""
        return DependentVariableGetSize(self._c_ref)

    @size.setter
    def size(self, OCIndex new_size):
        """Set the size (number of elements per component)."""
        if new_size < 0:
            raise ValueError("Size must be non-negative")

        cdef bint success = DependentVariableSetSize(self._c_ref, new_size)
        if not success:
            raise RMNError("Failed to set DependentVariable size")

    @property
    def components(self):
        """List of data arrays representing the dependent variable's components.

        Each component is a numpy array containing the numerical values for one
        dimension of the data. Scalar quantities have one component, vectors
        have multiple components (2-3), and tensors can have many components.

        Returns:
            list: List of numpy arrays, one per component

        Examples:
            >>> data = np.array([1.0, 2.0, 3.0])
            >>> dep_var = DependentVariable([data])
            >>> len(dep_var.components)
            1
        """
        cdef OCMutableArrayRef components_ref = DependentVariableCopyComponents(self._c_ref)
        if components_ref == NULL:
            raise RMNError("Failed to get components - C reference may be corrupt")

        cdef uint64_t count
        cdef list result = []
        cdef uint64_t i
        cdef const void* item_ptr
        cdef OCTypeID type_id

        try:
            element_type_str = self.element_type
            count = OCArrayGetCount(<OCArrayRef>components_ref)
            np_dtype = element_type_to_numpy_dtype(element_type_str)

            for i in range(count):
                item_ptr = OCArrayGetValueAtIndex(<OCArrayRef>components_ref, i)
                if item_ptr == NULL:
                    result.append(None)
                    continue

                type_id = OCGetTypeID(item_ptr)

                if type_id == OCDataGetTypeID():
                    from rmnpy.helpers.octypes import ocdata_to_numpy_array
                    py_item = ocdata_to_numpy_array(<uintptr_t>item_ptr, np_dtype)
                else:
                    from rmnpy.helpers.octypes import ocarray_to_pylist
                    py_item = ocarray_to_pylist(<uintptr_t>item_ptr) if type_id == OCArrayGetTypeID() else None

                result.append(py_item)

            return result
        finally:
            OCRelease(<OCTypeRef>components_ref)

    @components.setter
    def components(self, value):
        """Set the data components from a list of array-like objects.

        Updates all data arrays simultaneously. The number of components must
        match the quantity_type (1 for scalar, 2-3 for vectors, etc.).
        All components must have the same length.

        Args:
            value (list or None): List of array-like objects (lists, numpy arrays)
                                 or None to clear components

        Raises:
            RMNError: If component assignment fails

        Examples:
            >>> data = np.array([1.0, 2.0])
            >>> dep_var = DependentVariable([data])
            >>> new_data = np.array([3.0, 4.0])
            >>> dep_var.components = [new_data]
        """
        cdef OCArrayRef components_array = NULL

        try:
            if value is not None:
                components_array = <OCArrayRef><uintptr_t>ocarray_create_from_pylist(value)

            success = DependentVariableSetComponents(self._c_ref, components_array)
            if not success:
                raise RMNError("Failed to set components")
        finally:
            if components_array != NULL:
                OCRelease(<OCTypeRef>components_array)

    @property
    def unit(self):
        """SI unit of the dependent variable.

        Returns the physical unit associated with this data, enabling
        automatic unit conversion and dimensional analysis. Returns None
        if no unit is specified (dimensionless quantities).

        Returns:
            Unit or None: Unit object representing the physical dimensions

        Examples:
            >>> data = np.array([300.0])
            >>> dep_var = DependentVariable([data], unit="K")
            >>> dep_var.unit.symbol
            'K'
        """
        cdef SIQuantityRef quantity_ref = <SIQuantityRef>self._c_ref
        cdef SIUnitRef unit_ref = SIQuantityGetUnit(quantity_ref)

        if unit_ref == NULL:
            return None
        return Unit._from_c_ref(unit_ref)

    @property
    def sparse_sampling(self):
        """Get the sparse sampling of this DependentVariable."""
        cdef SparseSamplingRef sparse_ref = DependentVariableCopySparseSampling(self._c_ref)
        if sparse_ref == NULL:
            return None
        return SparseSampling._from_c_ref(sparse_ref)

    @sparse_sampling.setter
    def sparse_sampling(self, value):
        """Set the sparse sampling of this DependentVariable."""
        cdef SparseSamplingRef sparse_ref = NULL
        cdef bint success
        cdef SparseSampling sparse_obj

        if value is not None:
            if not isinstance(value, SparseSampling):
                raise TypeError("sparse_sampling must be a SparseSampling object or None")

            sparse_obj = <SparseSampling>value
            if sparse_obj._c_ref == NULL:
                raise ValueError("SparseSampling object not initialized")
            sparse_ref = sparse_obj._c_ref

        success = DependentVariableSetSparseSampling(self._c_ref, sparse_ref)
        if not success:
            raise RMNError("Failed to set sparse sampling")

    def copy(self):
        """Create a copy of this DependentVariable."""
        cdef DependentVariableRef copy_ref = DependentVariableCopy(self._c_ref)
        if copy_ref == NULL:
            raise RMNError("Failed to copy DependentVariable")

        cdef DependentVariable new_dv = DependentVariable.__new__(DependentVariable)
        new_dv._c_ref = copy_ref
        return new_dv

    def append(self, other):
        """Append another DependentVariable's data to this one.

        Concatenates the data components from another DependentVariable onto
        the end of this one's data arrays. Both variables must have compatible
        metadata (same component count, element type, etc.).

        Args:
            other (DependentVariable): The DependentVariable to append

        Raises:
            TypeError: If other is not a DependentVariable
            RMNError: If the append operation fails due to incompatible data

        Examples:
            >>> data1 = np.array([1.0, 2.0])
            >>> data2 = np.array([3.0, 4.0])
            >>> dep_var1 = DependentVariable([data1])
            >>> dep_var2 = DependentVariable([data2])
            >>> dep_var1.append(dep_var2)
            >>> dep_var1.size
            4
        """
        if not isinstance(other, DependentVariable):
            raise TypeError("other must be a DependentVariable")

        # Cast other to our Cython class to access _c_ref
        cdef DependentVariable other_dv = <DependentVariable>other

        cdef OCStringRef err_ocstr = NULL
        cdef bint success

        try:
            success = DependentVariableAppend(self._c_ref, other_dv._c_ref, &err_ocstr)
            if not success:
                if err_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uintptr_t>err_ocstr)
                    raise RMNError(f"Failed to append DependentVariable: {error_msg}")
                else:
                    raise RMNError("Failed to append DependentVariable")
        finally:
            if err_ocstr != NULL:
                OCRelease(<OCTypeRef>err_ocstr)

    def __str__(self):
        """String representation showing key properties."""
        if self._c_ref == NULL:
            return "DependentVariable(uninitialized)"

        parts = []
        if self.name:
            parts.append(f"name='{self.name}'")
        if self.quantity_name:
            parts.append(f"quantity='{self.quantity_name}'")
        if self.quantity_type:
            parts.append(f"type='{self.quantity_type}'")
        parts.append(f"components={self.component_count}")
        parts.append(f"size={self.size}")

        return f"DependentVariable({', '.join(parts)})"

    def __repr__(self):
        return self.__str__()
