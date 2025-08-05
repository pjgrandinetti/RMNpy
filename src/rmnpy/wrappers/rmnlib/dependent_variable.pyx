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
    ocarray_to_py_list,
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
    Python wrapper for RMNLib's DependentVariable.

    A DependentVariable represents an N-dimensional dataset variable with support
    for multiple components, sparse sampling, and comprehensive data manipulation.
    DependentVariable inherits from SIQuantity, providing unit and dimensionality support.

    Attributes:
        name: Human-readable name
        description: Detailed description
        unit: Physical unit (SIUnit) - inherited from SIQuantity
        dimensionality: Unit dimensionality - inherited from SIQuantity
        quantity_name: Logical quantity name (e.g., "temperature")
        quantity_type: Semantic type ("scalar", "vector_N", etc.)
        element_type: Numeric storage type (OCNumberType)
        numeric_type: SINumberType - inherited from SIQuantity
        element_size: Size in bytes of each element - inherited from SIQuantity
        size: Number of elements per component
        component_count: Number of components

    SIQuantity inherited methods:
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
               element_type: str = "float64",
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
            element_type: Numeric storage type ("float32", "float64", "complex64", "complex128", etc.)
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
        cdef OCNumberType c_element_type
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

            # Convert element type string to OCNumberType
            c_element_type = _element_type_from_string(element_type)

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
                c_element_type, c_component_labels, c_components, &error_msg)

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
                        element_type: str = "float64",
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
            element_type: Numeric storage type
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
        cdef OCNumberType c_element_type
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
            c_element_type = _element_type_from_string(element_type)

            if component_labels is not None:
                c_component_labels = py_list_to_ocarray(component_labels)

            # Create the DependentVariable
            result._c_dependent_variable = DependentVariableCreateWithSize(
                c_name, c_description, c_unit, c_quantity_name, c_quantity_type,
                c_element_type, c_component_labels, c_size, &error_msg)

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
                      element_type: str,
                      components: List[bytes]) -> "DependentVariable":
        """
        Create a DependentVariable with minimal required parameters.

        Args:
            unit: Physical unit (required)
            quantity_name: Logical quantity name
            quantity_type: Semantic type
            element_type: Numeric storage type
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
        cdef OCNumberType c_element_type = _element_type_from_string(element_type)
        cdef OCArrayRef c_components = py_list_to_ocarray(components)
        cdef OCStringRef error_msg = NULL

        try:
            result._c_dependent_variable = DependentVariableCreateMinimal(
                c_unit, c_quantity_name, c_quantity_type, c_element_type, c_components, &error_msg)

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

    @property
    def element_type(self) -> str:
        """Get the numeric element type of this DependentVariable."""
        if not self._c_dependent_variable:
            return "unknown"
        cdef OCNumberType c_type = DependentVariableGetElementType(self._c_dependent_variable)
        return _element_type_to_string(c_type)

    @element_type.setter
    def element_type(self, value: str):
        """Set the numeric element type of this DependentVariable."""
        if not self._c_dependent_variable:
            raise RMNLibError("Cannot set element_type on null DependentVariable")

        cdef OCNumberType c_type = _element_type_from_string(value)
        cdef bint success = DependentVariableSetElementType(self._c_dependent_variable, c_type)

        if not success:
            raise RMNLibError("Failed to set element_type")

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
    def numeric_type(self) -> str:
        """Get the SINumberType of this DependentVariable (inherited from SIQuantity)."""
        if not self._c_dependent_variable:
            return "unknown"
        cdef SINumberType c_type = SIQuantityGetNumericType(<SIQuantityRef>self._c_dependent_variable)
        return _si_number_type_to_string(c_type)

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

    # ==================================================================================
    # End of SIQuantity inherited methods
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

    # Type checking methods
    def is_scalar_type(self) -> bool:
        """Check if this is a scalar-type DependentVariable."""
        if not self._c_dependent_variable:
            return False
        return DependentVariableIsScalarType(self._c_dependent_variable)

    def is_vector_type(self) -> Tuple[bool, int]:
        """Check if this is a vector-type DependentVariable. Returns (is_vector, count)."""
        if not self._c_dependent_variable:
            return False, 0
        cdef OCIndex count = 0
        cdef bint is_vector = DependentVariableIsVectorType(self._c_dependent_variable, &count)
        return is_vector, count

    def is_pixel_type(self) -> Tuple[bool, int]:
        """Check if this is a pixel-type DependentVariable. Returns (is_pixel, count)."""
        if not self._c_dependent_variable:
            return False, 0
        cdef OCIndex count = 0
        cdef bint is_pixel = DependentVariableIsPixelType(self._c_dependent_variable, &count)
        return is_pixel, count

    def is_matrix_type(self) -> Tuple[bool, int, int]:
        """Check if this is a matrix-type DependentVariable. Returns (is_matrix, rows, cols)."""
        if not self._c_dependent_variable:
            return False, 0, 0
        cdef OCIndex rows = 0, cols = 0
        cdef bint is_matrix = DependentVariableIsMatrixType(self._c_dependent_variable, &rows, &cols)
        return is_matrix, rows, cols

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

    def __repr__(self) -> str:
        if not self._c_dependent_variable:
            return "DependentVariable(null)"

        unit_str = "None"
        if self.unit:
            unit_str = f"'{self.unit.symbol}'"

        return (f"DependentVariable(name='{self.name}', "
                f"quantity_type='{self.quantity_type}', "
                f"element_type='{self.element_type}', "
                f"unit={unit_str}, "
                f"size={self.size}, "
                f"components={self.component_count})")


# Helper functions for element type conversion
cdef OCNumberType _element_type_from_string(str type_str):
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


cdef str _element_type_to_string(OCNumberType type_id):
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
    """Convert string to SINumberType."""
    type_map = {
        "int8": kSINumberSInt8Type,
        "uint8": kSINumberUInt8Type,
        "int16": kSINumberSInt16Type,
        "uint16": kSINumberUInt16Type,
        "int32": kSINumberSInt32Type,
        "uint32": kSINumberUInt32Type,
        "int64": kSINumberSInt64Type,
        "uint64": kSINumberUInt64Type,
        "float32": kSINumberFloat32Type,
        "float64": kSINumberFloat64Type,
        "complex64": kSINumberComplex64Type,
        "complex128": kSINumberComplex128Type,
    }
    return type_map.get(type_str, kSINumberFloat64Type)


cdef str _si_number_type_to_string(SINumberType type_id):
    """Convert SINumberType to string representation."""
    type_map = {
        kSINumberSInt8Type: "int8",
        kSINumberUInt8Type: "uint8",
        kSINumberSInt16Type: "int16",
        kSINumberUInt16Type: "uint16",
        kSINumberSInt32Type: "int32",
        kSINumberUInt32Type: "uint32",
        kSINumberSInt64Type: "int64",
        kSINumberUInt64Type: "uint64",
        kSINumberFloat32Type: "float32",
        kSINumberFloat64Type: "float64",
        kSINumberComplex64Type: "complex64",
        kSINumberComplex128Type: "complex128",
    }
    return type_map.get(type_id, "unknown")
