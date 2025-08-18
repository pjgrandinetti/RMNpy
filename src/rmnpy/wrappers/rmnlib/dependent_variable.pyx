# cython: language_level=3
"""
RMNLib DependentVariable wrapper

Simple wrapper around the RMNLib DependentVariable C API.
DependentVariable represents measured or computed data values with
associated metadata including units, quantity type, and components.
"""

import numpy as np

cimport numpy as cnp

cnp.import_array()

from cpython.mem cimport PyMem_Free, PyMem_Malloc
from libc.stdlib cimport free, malloc

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

# Import the helper function and Unit class from unit.pyx

from rmnpy.wrappers.rmnlib.sparse_sampling cimport SparseSampling
from rmnpy.wrappers.sitypes.unit cimport Unit, convert_to_siunit_ref


cdef class DependentVariable:
    """
    Python wrapper for RMNLib DependentVariable.

    A DependentVariable represents measured or computed data values with
    associated metadata including units, quantity type, and components.
    """

    def __cinit__(self):
        """Initialize C-level attributes."""
        self._c_ref = NULL

    def __dealloc__(self):
        """Clean up C resources."""
        if self._c_ref != NULL:
            OCRelease(self._c_ref)

    @staticmethod
    cdef DependentVariable _from_c_ref(DependentVariableRef dep_var_ref):
        """Create DependentVariable wrapper from C reference (internal use).

        Creates a copy of the dependent variable reference, so caller retains ownership
        of their original reference and can safely release it.
        """
        cdef DependentVariable result = DependentVariable.__new__(DependentVariable)
        cdef DependentVariableRef copied_ref = DependentVariableCopy(dep_var_ref)
        if copied_ref == NULL:
            raise RMNError("Failed to create copy of DependentVariable")
        result._c_ref = copied_ref
        return result

    def __init__(self,
                 components,
                 name=None,
                 description=None,
                 unit=None,
                 quantity_name=None,
                 quantity_type="scalar",
                 element_type="float64",
                 component_labels=None):
        """
        Create a new DependentVariable using the core creator.

        Parameters:
            components : list of array-like, required
                Data buffers for each component - this is required and cannot be None
            name : str, optional
                Human-readable name
            description : str, optional
                Longer description
            unit : str, Unit, or None, optional
                SI unit specification - can be a unit string, Unit object, or None for dimensionless
            quantity_name : str, optional
                Logical quantity name (e.g. "temperature")
            quantity_type : str, optional
                Semantic type ("scalar", "vector_2", etc.), default "scalar"
            element_type : str, optional
                Numeric storage type, default "float64"
            component_labels : list of str, optional
                Labels for components
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
        cdef uint64_t num_components
        cdef const void **value_array
        cdef DependentVariableRef result = NULL
        cdef bint success = False
        cdef const unsigned char* data_ptr
        cdef uint64_t length
        cdef OCDataRef oc_data_ref
        cdef OCTypeID type_id
        cdef const char* type_name

        try:
            # Convert parameters to C types using the exact pattern from dimension.pyx
            if name is not None:
                name_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(name)
            if description is not None:
                desc_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(description)

            # Convert unit using the helper function
            unit_ref = convert_to_siunit_ref(unit)

            if quantity_name is not None:
                quantity_name_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(quantity_name)
            if quantity_type is not None:
                quantity_type_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(quantity_type)

            # Convert element_type to OCNumberType enum
            element_type_enum = self._element_type_to_enum(element_type)

            # Convert component labels if provided
            if component_labels is not None:
                component_labels_array = <OCArrayRef><uint64_t>ocarray_create_from_pylist(component_labels)

            # Convert components if provided - each component must be converted to OCDataRef
            if components is not None:
                # Create a mutable array and append each OCDataRef
                components_array = <OCArrayRef>OCArrayCreateMutable(0, &kOCTypeArrayCallBacks)
                if components_array == NULL:
                    raise RMNError("Failed to create components array")

                for component in components:
                    # Create OCData directly without going through uint64_t conversion
                    if not isinstance(component, np.ndarray):
                        raise TypeError(f"Expected numpy.ndarray, got {type(component)}. Use numpy arrays for OCData.")

                    # Ensure array is contiguous
                    if not component.flags.c_contiguous:
                        component = np.ascontiguousarray(component)

                    data_ptr = <const unsigned char*>cnp.PyArray_DATA(component)
                    length = component.nbytes

                    oc_data_ref = OCDataCreate(data_ptr, length)

                    if oc_data_ref == NULL:
                        raise RMNError("Failed to create OCData from NumPy array")

                    # Debug: Check TypeID of created OCData
                    type_id = OCGetTypeID(oc_data_ref)
                    type_name = OCTypeNameFromTypeID(type_id)
                    if type_name != NULL:
                        print(f"DEBUG: Created OCData with TypeID: {type_id}, Type name: {type_name.decode('utf-8')}")
                    else:
                        print(f"DEBUG: Created OCData with TypeID: {type_id}, but type name is NULL")

                    success = OCArrayAppendValue(<OCMutableArrayRef>components_array, <const void*>oc_data_ref)
                    if not success:
                        raise RMNError("Failed to append component to array")

            # Call the core C API creator
            result = DependentVariableCreate(
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

            if result == NULL:
                if err_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>err_ocstr)
                    raise RMNError(f"Failed to create DependentVariable: {error_msg}")
                else:
                    raise RMNError("Failed to create DependentVariable")

            self._c_ref = result

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

    def __dealloc__(self):
        """Clean up C resources."""
        if self._c_ref != NULL:
            OCRelease(<OCTypeRef>self._c_ref)

    cdef OCNumberType _element_type_to_enum(self, element_type):
        """Convert string element type to OCNumberType enum using OCTypes helper."""
        cdef bytes element_type_bytes = element_type.encode('utf-8')
        cdef const char* element_type_cstr = element_type_bytes
        cdef OCNumberType result = OCNumberTypeFromName(element_type_cstr)

        if result == 0:  # kOCNumberTypeInvalid
            raise ValueError(f"Invalid element_type: {element_type}. Use a valid OCNumberType name.")

        return result

    @property
    def name(self):
        """Get the name of the DependentVariable."""
        if self._c_ref == NULL:
            raise ValueError("DependentVariable not initialized")
        cdef OCStringRef name_ref = DependentVariableCopyName(self._c_ref)
        if name_ref == NULL:
            raise RMNError("Failed to get name - C reference may be corrupt")
        try:
            return ocstring_to_pystring(<uint64_t>name_ref)
        finally:
            OCRelease(<OCTypeRef>name_ref)

    @name.setter
    def name(self, value):
        """Set the name of the DependentVariable."""
        if self._c_ref == NULL:
            raise ValueError("DependentVariable not initialized")

        cdef OCStringRef name_ocstr = NULL

        try:
            if value is not None:
                name_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(value)
            success = DependentVariableSetName(self._c_ref, name_ocstr)
            if not success:
                raise RMNError("Failed to set name")
        finally:
            if name_ocstr != NULL:
                OCRelease(<OCTypeRef>name_ocstr)

    @property
    def description(self):
        """Get the description of the DependentVariable."""
        if self._c_ref == NULL:
            raise ValueError("DependentVariable not initialized")
        cdef OCStringRef desc_ref = DependentVariableCopyDescription(self._c_ref)
        if desc_ref == NULL:
            raise RMNError("Failed to get description - C reference may be corrupt")
        try:
            return ocstring_to_pystring(<uint64_t>desc_ref)
        finally:
            OCRelease(<OCTypeRef>desc_ref)

    @description.setter
    def description(self, value):
        """Set the description of the DependentVariable."""
        if self._c_ref == NULL:
            raise ValueError("DependentVariable not initialized")

        cdef OCStringRef desc_ocstr = NULL

        try:
            if value is not None:
                desc_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(value)
            success = DependentVariableSetDescription(self._c_ref, desc_ocstr)
            if not success:
                raise RMNError("Failed to set description")
        finally:
            if desc_ocstr != NULL:
                OCRelease(<OCTypeRef>desc_ocstr)

    @property
    def quantity_name(self):
        """Get the quantity name."""
        if self._c_ref == NULL:
            raise ValueError("DependentVariable not initialized")
        cdef OCStringRef qname_ref = DependentVariableCopyQuantityName(self._c_ref)
        if qname_ref == NULL:
            raise RMNError("Failed to get quantity_name - C reference may be corrupt")
        try:
            return ocstring_to_pystring(<uint64_t>qname_ref)
        finally:
            OCRelease(<OCTypeRef>qname_ref)

    @quantity_name.setter
    def quantity_name(self, value):
        """Set the quantity name of the DependentVariable."""
        if self._c_ref == NULL:
            raise ValueError("DependentVariable not initialized")

        cdef OCStringRef qname_ocstr = NULL

        try:
            if value is not None:
                qname_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(value)
            success = DependentVariableSetQuantityName(self._c_ref, qname_ocstr)
            if not success:
                raise RMNError("Failed to set quantity name")
        finally:
            if qname_ocstr != NULL:
                OCRelease(<OCTypeRef>qname_ocstr)

    @property
    def quantity_type(self):
        """Get the quantity type."""
        if self._c_ref == NULL:
            raise ValueError("DependentVariable not initialized")
        cdef OCStringRef qtype_ref = DependentVariableCopyQuantityType(self._c_ref)
        if qtype_ref == NULL:
            raise RMNError("Failed to get quantity_type - C reference may be corrupt")
        try:
            return ocstring_to_pystring(<uint64_t>qtype_ref)
        finally:
            OCRelease(<OCTypeRef>qtype_ref)

    @property
    def element_type(self):
        """Get the numeric element type."""
        if self._c_ref == NULL:
            raise ValueError("DependentVariable not initialized")
        cdef OCNumberType elem_type = DependentVariableGetNumericType(self._c_ref)
        return enum_to_element_type(elem_type)

    @property
    def component_count(self):
        """Get the number of components."""
        if self._c_ref == NULL:
            raise ValueError("DependentVariable not initialized")
        return DependentVariableGetComponentCount(self._c_ref)

    @property
    def size(self):
        """Get the size (number of elements per component)."""
        if self._c_ref == NULL:
            raise ValueError("DependentVariable not initialized")
        return DependentVariableGetSize(self._c_ref)

    @size.setter
    def size(self, OCIndex new_size):
        """Set the size (number of elements per component)."""
        if self._c_ref == NULL:
            raise ValueError("DependentVariable not initialized")

        if new_size < 0:
            raise ValueError("Size must be non-negative")

        cdef bint success = DependentVariableSetSize(self._c_ref, new_size)
        if not success:
            raise RMNError("Failed to set DependentVariable size")

    @property
    def components(self):
        """Get the components (data arrays) of this DependentVariable."""
        if self._c_ref == NULL:
            raise ValueError("DependentVariable not initialized")

        cdef OCMutableArrayRef components_ref = DependentVariableCopyComponents(self._c_ref)
        if components_ref == NULL:
            raise RMNError("Failed to get components - C reference may be corrupt")

        # Declare all cdef variables at the beginning
        cdef uint64_t count
        cdef list result = []
        cdef uint64_t i
        cdef const void* item_ptr
        cdef OCTypeID type_id

        try:
            # Get the element type to determine the correct numpy dtype
            element_type_str = self.element_type

            # Convert the OCArray to a list, but handle OCData components specially
            count = OCArrayGetCount(<OCArrayRef>components_ref)

            # Get the corresponding NumPy dtype using the helper function
            np_dtype = element_type_to_numpy_dtype(element_type_str)

            for i in range(count):
                item_ptr = OCArrayGetValueAtIndex(<OCArrayRef>components_ref, i)
                if item_ptr == NULL:
                    result.append(None)
                    continue

                type_id = OCGetTypeID(item_ptr)

                # Handle OCData with the correct dtype
                if type_id == OCDataGetTypeID():
                    from rmnpy.helpers.octypes import ocdata_to_numpy_array
                    py_item = ocdata_to_numpy_array(<uint64_t>item_ptr, np_dtype)
                else:
                    # For other types, use the standard conversion
                    from rmnpy.helpers.octypes import ocarray_to_pylist
                    py_item = ocarray_to_pylist(<uint64_t>item_ptr) if type_id == OCArrayGetTypeID() else None

                result.append(py_item)

            return result
        finally:
            OCRelease(<OCTypeRef>components_ref)

    @components.setter
    def components(self, value):
        """Set the components (data arrays) of this DependentVariable."""
        if self._c_ref == NULL:
            raise ValueError("DependentVariable not initialized")

        cdef OCArrayRef components_array = NULL

        try:
            if value is not None:
                components_array = <OCArrayRef><uint64_t>ocarray_create_from_pylist(value)

            success = DependentVariableSetComponents(self._c_ref, components_array)
            if not success:
                raise RMNError("Failed to set components")
        finally:
            if components_array != NULL:
                OCRelease(<OCTypeRef>components_array)

    @property
    def unit(self):
        """Get the unit of this DependentVariable."""
        if self._c_ref == NULL:
            raise ValueError("DependentVariable not initialized")

        # Cast DependentVariableRef to SIQuantityRef and call SIQuantityGetUnit
        cdef SIQuantityRef quantity_ref = <SIQuantityRef>self._c_ref
        cdef SIUnitRef unit_ref = SIQuantityGetUnit(quantity_ref)

        if unit_ref == NULL:
            return None

        # Use Unit._from_c_ref to create Python Unit object
        return Unit._from_c_ref(unit_ref)

    @property
    def sparse_sampling(self):
        """Get the sparse sampling of this DependentVariable."""
        if self._c_ref == NULL:
            raise ValueError("DependentVariable not initialized")

        cdef SparseSamplingRef sparse_ref = DependentVariableCopySparseSampling(self._c_ref)
        if sparse_ref == NULL:
            return None

        # Use SparseSampling._from_c_ref to create Python SparseSampling object
        return SparseSampling._from_c_ref(sparse_ref)

    @sparse_sampling.setter
    def sparse_sampling(self, value):
        """Set the sparse sampling of this DependentVariable."""
        if self._c_ref == NULL:
            raise ValueError("DependentVariable not initialized")

        cdef SparseSamplingRef sparse_ref = NULL
        cdef bint success
        cdef SparseSampling sparse_obj

        if value is not None:
            if not isinstance(value, SparseSampling):
                raise TypeError("sparse_sampling must be a SparseSampling object or None")

            # Cast to SparseSampling to access _c_ref
            sparse_obj = <SparseSampling>value
            if sparse_obj._c_ref == NULL:
                raise ValueError("SparseSampling object not initialized")
            sparse_ref = sparse_obj._c_ref

        success = DependentVariableSetSparseSampling(self._c_ref, sparse_ref)
        if not success:
            raise RMNError("Failed to set sparse sampling")

    def copy(self):
        """Create a copy of this DependentVariable."""
        if self._c_ref == NULL:
            raise ValueError("DependentVariable not initialized")
        cdef DependentVariableRef copy_ref = DependentVariableCopy(self._c_ref)
        if copy_ref == NULL:
            raise RMNError("Failed to copy DependentVariable")

        # Create new Python object with copied reference
        cdef DependentVariable new_dv = DependentVariable.__new__(DependentVariable)
        new_dv._c_ref = copy_ref
        return new_dv

    def append(self, other):
        """
        Append another DependentVariable's data onto the end of this one.

        Parameters:
        -----------
        other : DependentVariable
            The DependentVariable to append to this one

        Raises:
        -------
        ValueError
            If this DependentVariable is not initialized
        TypeError
            If other is not a DependentVariable
        RMNError
            If the append operation fails
        """
        if self._c_ref == NULL:
            raise ValueError("DependentVariable not initialized")

        if not isinstance(other, DependentVariable):
            raise TypeError("other must be a DependentVariable")

        # Cast other to our Cython class to access _c_ref
        cdef DependentVariable other_dv = <DependentVariable>other
        if other_dv._c_ref == NULL:
            raise ValueError("other DependentVariable not initialized")

        cdef OCStringRef err_ocstr = NULL
        cdef bint success

        try:
            success = DependentVariableAppend(self._c_ref, other_dv._c_ref, &err_ocstr)
            if not success:
                if err_ocstr != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>err_ocstr)
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
