# cython: language_level=3
"""
RMNLib DependentVariable wrapper

Simple wrapper foll        try:
            print("DEBUG: Starting DependentVariable.__init__")
            # Convert parameters to C types using the exact pattern from dimension.pyx
            if name is not None:
                print("DEBUG: Converting name")
                name_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(name)
            if description is not None:
                print("DEBUG: Converting description")
                desc_ocstr = <OCStringRef><uint64_t>ocstring_create_from_pystring(description)

            print("DEBUG: About to convert unit")
            # Convert unit to SIUnitRef exact pattern from dimension.pyx.
"""

from rmnpy._c_api.octypes cimport *
from rmnpy._c_api.rmnlib cimport *
from rmnpy._c_api.sitypes cimport *

from rmnpy.exceptions import RMNError
from rmnpy.helpers.octypes import (
    ocarray_create_from_pylist,
    ocarray_to_pylist,
    ocdict_create_from_pydict,
    ocdict_to_pydict,
    ocstring_create_from_pystring,
    ocstring_to_pystring,
)

# Import the helper function and Unit class from unit.pyx

from rmnpy.wrappers.sitypes.unit cimport Unit, convert_to_siunit_ref


cdef class DependentVariable:
    """
    Python wrapper for RMNLib DependentVariable.

    A DependentVariable represents measured or computed data values with
    associated metadata including units, quantity type, and components.
    """

    cdef DependentVariableRef _c_ref
    cdef bint _owns_reference

    def __cinit__(self):
        self._c_ref = NULL
        self._owns_reference = False

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
        -----------
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

            # Convert components if provided
            if components is not None:
                components_array = <OCArrayRef><uint64_t>ocarray_create_from_pylist(components)

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
            self._owns_reference = True

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
        if self._owns_reference and self._c_ref != NULL:
            OCRelease(<OCTypeRef>self._c_ref)

    cdef OCNumberType _element_type_to_enum(self, element_type):
        """Convert string element type to OCNumberType enum."""
        # Use the correct constants from octypes.pxd with k prefix
        type_map = {
            "float64": kOCNumberFloat64Type,
            "float32": kOCNumberFloat32Type,
            "int32": kOCNumberSInt32Type,
            "int64": kOCNumberSInt64Type,
        }
        if element_type not in type_map:
            supported_types = list(type_map.keys())
            raise ValueError(f"Invalid element_type: {element_type}. Supported: {supported_types}")
        return type_map[element_type]

    @property
    def name(self):
        """Get the name of the DependentVariable."""
        if self._c_ref == NULL:
            return None
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
            return None
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
            return None
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
            return None
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
            return None
        cdef OCNumberType elem_type = DependentVariableGetNumericType(self._c_ref)
        return self._enum_to_element_type(elem_type)

    cdef str _enum_to_element_type(self, OCNumberType elem_type):
        """Convert OCNumberType enum to string."""
        type_map = {
            kOCNumberFloat64Type: "float64",
            kOCNumberFloat32Type: "float32",
            kOCNumberSInt32Type: "int32",
            kOCNumberSInt64Type: "int64",
        }
        return type_map.get(elem_type, "unknown")

    @property
    def component_count(self):
        """Get the number of components."""
        if self._c_ref == NULL:
            return 0
        return DependentVariableGetComponentCount(self._c_ref)

    @property
    def size(self):
        """Get the size (number of elements per component)."""
        if self._c_ref == NULL:
            return 0
        return DependentVariableGetSize(self._c_ref)

    @property
    def unit(self):
        """Get the unit of this DependentVariable."""
        if self._c_ref == NULL:
            return None

        # Cast DependentVariableRef to SIQuantityRef and call SIQuantityGetUnit
        cdef SIQuantityRef quantity_ref = <SIQuantityRef>self._c_ref
        cdef SIUnitRef unit_ref = SIQuantityGetUnit(quantity_ref)

        if unit_ref == NULL:
            return None

        # Use Unit._from_c_ref to create Python Unit object
        return Unit._from_c_ref(unit_ref)

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
        new_dv._owns_reference = True
        return new_dv

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
