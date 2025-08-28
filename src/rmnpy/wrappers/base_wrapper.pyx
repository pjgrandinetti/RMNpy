# cython: language_level=3
"""
Base wrapper class for all RMNpy C API wrappers.

This module provides a common base class that implements the repetitive
boilerplate code found across all wrapper classes, reducing code duplication
and providing consistent behavior.
"""

from typing import Any, Dict, Optional, Union

from libc.stdint cimport uint64_t

from rmnpy._c_api.octypes cimport (
    OCDictionaryRef,
    OCGetTypeID,
    OCRelease,
    OCStringCreateWithCString,
    OCStringGetCString,
    OCStringRef,
    OCTypeCopyFormattingDesc,
    OCTypeCopyJSON,
    OCTypeDeepCopy,
    OCTypeEqual,
    OCTypeGetRetainCount,
    OCTypeID,
    OCTypeNameFromTypeID,
    OCTypeRef,
    cJSON,
    cJSON_Delete,
)
from rmnpy._c_api.rmnlib cimport (
    RMNLibGetApplicationMetaData,
    RMNLibGetDescription,
    RMNLibSetApplicationMetaData,
    RMNLibSetDescription,
)

from rmnpy.exceptions import RMNError
from rmnpy.helpers.octypes import (
    ocdict_create_from_pydict,
    ocdict_to_pydict,
    ocstring_to_pystring,
    universal_to_dict,
)


cdef class BaseWrapper:
    """
    Base class for all RMNpy C API wrappers.

    This class implements the common patterns found across all wrapper classes:
    - C reference management (__cinit__, __dealloc__)
    - Factory methods (_from_c_ref, from_c_ref)
    - Copy operations
    - Basic validation

    Subclasses must implement:
    - Specific __init__ methods
    - copy_c_ref() method for their specific C type
    - Any domain-specific functionality
    """

    def __cinit__(self):
        """Initialize C-level attributes."""
        self._c_ref = NULL

    def __dealloc__(self):
        """Clean up C resources."""
        if self._c_ref != NULL:
            OCRelease(self._c_ref)

    cdef void _set_c_ref(self, void* c_ref):
        """Set the C reference (internal use only)."""
        if self._c_ref != NULL:
            OCRelease(self._c_ref)
        self._c_ref = <OCTypeRef>c_ref

    cdef void* _get_c_ref(self):
        """Get the C reference (internal use only)."""
        return <void*>self._c_ref

    @property
    def _c_ref(self):
        """Get the C reference pointer as integer (for helper functions)."""
        return <uint64_t>self._c_ref

    def is_valid(self):
        """Check if the wrapper has a valid C reference."""
        return self._c_ref != NULL

    cdef void _validate_initialized(self) except *:
        """Validate that the wrapper is initialized, raise if not."""
        if not self.is_valid():
            raise ValueError(f"{self.__class__.__name__} not initialized")

    # Universal OCType methods - available to ALL OCTypes
    cdef void* copy_c_ref(self) except NULL:
        """Create a copy using universal OCTypeDeepCopy."""
        self._validate_initialized()
        cdef void* copied = OCTypeDeepCopy(self._c_ref)
        if copied == NULL:
            raise MemoryError("Failed to copy OCType reference")
        return copied

    def get_type_id(self):
        """Get the OCTypeID of this object."""
        self._validate_initialized()
        return OCGetTypeID(self._c_ref)

    def get_type_name(self):
        """Get the type name string of this object."""
        self._validate_initialized()
        cdef OCTypeID type_id = OCGetTypeID(self._c_ref)
        cdef const char* name = OCTypeNameFromTypeID(type_id)
        if name == NULL:
            return None
        return name.decode('utf-8')

    def get_retain_count(self):
        """Get the current retain count (for debugging)."""
        self._validate_initialized()
        return OCTypeGetRetainCount(self._c_ref)

    def copy_formatting_description(self):
        """Get a formatted description string."""
        self._validate_initialized()
        cdef OCStringRef desc = OCTypeCopyFormattingDesc(self._c_ref)
        if desc == NULL:
            return None

        cdef const char* desc_str = OCStringGetCString(desc)
        try:
            if desc_str == NULL:
                return None
            return desc_str.decode('utf-8')
        finally:
            OCRelease(<OCTypeRef>desc)

    def copy(self):
        """
        Create a deep copy of this object.

        Returns:
            BaseWrapper: New instance of the same type (deep copy)

        Raises:
            RMNError: If copying fails
        """
        self._validate_initialized()
        cdef void* copied_ref = OCTypeDeepCopy(self._c_ref)
        if copied_ref == NULL:
            raise RMNError(f"Failed to create copy of {self.__class__.__name__}")

        # Create new Python object directly with copied reference
        cdef BaseWrapper new_obj = self.__class__.__new__(self.__class__)
        new_obj._set_c_ref(copied_ref)
        return new_obj

    def __eq__(self, other):
        """Universal equality comparison using OCTypeEqual."""
        if not isinstance(other, BaseWrapper):
            return False
        self._validate_initialized()
        if hasattr(other, '_validate_initialized'):
            other._validate_initialized()
        elif not getattr(other, 'is_valid', lambda: True)():
            return False

        # Use universal OCTypeEqual function
        return OCTypeEqual(self._c_ref, (<BaseWrapper>other)._c_ref)

    def __ne__(self, other):
        """Universal inequality comparison."""
        return not self.__eq__(other)

    @staticmethod
    cdef BaseWrapper _from_c_ref(object cls, void* c_ref):
        """
        Universal factory method for creating wrappers from C references.

        This implements the common pattern:
        1. Create new instance with __new__
        2. Check for NULL
        3. Use OCTypeDeepCopy to copy the reference
        4. Check for copy failure
        5. Set the C reference
        6. Return the instance

        Parameters:
            cls: The wrapper class to instantiate
            c_ref: The C reference to wrap

        Returns:
            BaseWrapper: New instance of cls wrapping the copied C reference
        """
        if c_ref == NULL:
            raise ValueError("Cannot create wrapper from NULL reference")

        cdef BaseWrapper result = cls.__new__(cls)
        cdef void* copied_ref = OCTypeDeepCopy(<OCTypeRef>c_ref)
        if copied_ref == NULL:
            raise MemoryError(f"Failed to create copy of {cls.__name__}")

        result._set_c_ref(copied_ref)
        return result

    @staticmethod
    def from_c_ref(uint64_t c_ref_ptr):
        """Create wrapper from C reference pointer (Python-accessible)."""
        raise NotImplementedError("Subclasses must implement from_c_ref()")


# Specific base classes for different API families with integrated functionality

cdef class SITypesWrapper(BaseWrapper):
    """
    Base class for SITypes wrappers (Scalar, Unit, Dimensionality, etc.).

    Inherits universal functionality from BaseWrapper including:
    - Memory management and copying (OCTypeDeepCopy)
    - Equality comparison (OCTypeEqual)
    - Type introspection (OCGetTypeID, OCTypeIDName)

    Provides arithmetic operations that delegate to subclass implementations.
    This dramatically reduces code duplication across arithmetic types.
    """

    # Arithmetic operations that delegate to subclass implementations
    def __add__(self, other):
        """Addition operator (+)."""
        self._validate_initialized()
        return self._binary_arithmetic(other, "add")

    def __radd__(self, other):
        """Reverse addition operator (+)."""
        return self.__add__(other)  # Addition is commutative

    def __sub__(self, other):
        """Subtraction operator (-)."""
        self._validate_initialized()
        return self._binary_arithmetic(other, "sub")

    def __rsub__(self, other):
        """Reverse subtraction operator (-)."""
        if isinstance(other, (int, float, complex)):
            other_obj = self.__class__(other, "1")
            return other_obj.__sub__(self)
        else:
            return NotImplemented

    def __mul__(self, other):
        """Multiplication operator (*)."""
        self._validate_initialized()
        return self._binary_arithmetic(other, "mul")

    def __rmul__(self, other):
        """Reverse multiplication operator (*)."""
        return self.__mul__(other)  # Multiplication is commutative

    def __truediv__(self, other):
        """Division operator (/)."""
        self._validate_initialized()
        return self._binary_arithmetic(other, "div")

    def __rtruediv__(self, other):
        """Reverse division operator (/)."""
        if isinstance(other, (int, float, complex)):
            other_obj = self.__class__(other, "1")
            return other_obj.__truediv__(self)
        else:
            return NotImplemented

    def __pow__(self, exponent):
        """Power operator (**)."""
        self._validate_initialized()
        return self._power_arithmetic(exponent)

    def __abs__(self):
        """Absolute value."""
        self._validate_initialized()
        return self._unary_arithmetic("abs")

    # Abstract methods that subclasses must implement (much simpler!)
    def _binary_arithmetic(self, other, operation):
        """Perform binary arithmetic operation. Override in subclasses."""
        raise NotImplementedError(f"{self.__class__.__name__} does not implement {operation}")

    def _power_arithmetic(self, exponent):
        """Perform power operation. Override in subclasses."""
        raise NotImplementedError(f"{self.__class__.__name__} does not implement power")

    def _unary_arithmetic(self, operation):
        """Perform unary arithmetic operation. Override in subclasses."""
        raise NotImplementedError(f"{self.__class__.__name__} does not implement {operation}")


cdef class RMNLibWrapper(BaseWrapper):
    """
    Base class for RMNLib wrappers (Dataset, Datum, DependentVariable, etc.).

    Inherits universal functionality from BaseWrapper including:
    - Memory management and copying (OCTypeDeepCopy)
    - Equality comparison (OCTypeEqual)
    - Dictionary serialization (OCTypeCopyJSON → universal_to_dict)
    - Type introspection (OCGetTypeID, OCTypeIDName)

    RMNLib wrappers now get universal serialization automatically!
    Custom serialization methods are optional and can override the universal behavior.
    """

    def copy_as_dictionary(self):
        """Serialize object to dictionary representation using universal OCTypeCopyJSON."""
        self._validate_initialized()
        return universal_to_dict(<uint64_t>self._c_ref)

    def to_dict(self):
        """Universal dictionary serialization for all OCTypes."""
        return self.copy_as_dictionary()

    def dict(self):
        """Alias for to_dict() for compatibility."""
        return self.to_dict()

    @classmethod
    def from_dict(cls, data_dict):
        """
        Create instance from dictionary representation.

        Subclasses should implement this if they support deserialization.
        """
        if not isinstance(data_dict, dict):
            raise TypeError("Expected dictionary input")
        raise NotImplementedError(f"{cls.__name__} does not support deserialization from dictionary")

    # Universal property accessors using the new RMNLib universal functions

    @property
    def description(self):
        """Get the description string for this RMNLib object.

        Returns:
            str: The description string, or None if not supported by this type

        Raises:
            RMNError: If the object type doesn't support descriptions
        """
        self._validate_initialized()

        cdef OCStringRef error_ref = NULL
        cdef OCStringRef desc_ref = RMNLibGetDescription(self._c_ref, &error_ref)

        try:
            if error_ref != NULL:
                error_msg = ocstring_to_pystring(<uint64_t>error_ref)
                raise RMNError(f"Failed to get description: {error_msg}")

            if desc_ref == NULL:
                return None

            return ocstring_to_pystring(<uint64_t>desc_ref)

        finally:
            if error_ref != NULL:
                OCRelease(<OCTypeRef>error_ref)
            if desc_ref != NULL:
                OCRelease(<OCTypeRef>desc_ref)

    @description.setter
    def description(self, value):
        """Set the description string for this RMNLib object.

        Args:
            value (str): The description string to set

        Raises:
            RMNError: If the object type doesn't support descriptions or setting fails
            TypeError: If value is not a string
        """
        self._validate_initialized()

        if value is not None and not isinstance(value, str):
            raise TypeError("Description must be a string or None")

        cdef OCStringRef desc_ref = NULL
        cdef OCStringRef error_ref = NULL

        try:
            if value is not None:
                desc_ref = OCStringCreateWithCString(value.encode('utf-8'))
                if desc_ref == NULL:
                    raise RMNError("Failed to create description string")

            success = RMNLibSetDescription(self._c_ref, desc_ref, &error_ref)

            if not success:
                if error_ref != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>error_ref)
                    raise RMNError(f"Failed to set description: {error_msg}")
                else:
                    raise RMNError("Failed to set description")

        finally:
            if desc_ref != NULL:
                OCRelease(<OCTypeRef>desc_ref)
            if error_ref != NULL:
                OCRelease(<OCTypeRef>error_ref)

    @property
    def application(self):
        """Get the application metadata dictionary for this RMNLib object.

        Returns:
            dict: The application metadata dictionary, empty dict if no metadata

        Raises:
            RMNError: If the object type doesn't support metadata
        """
        self._validate_initialized()

        cdef OCStringRef error_ref = NULL
        cdef OCDictionaryRef metadata_ref = RMNLibGetApplicationMetaData(self._c_ref, &error_ref)

        try:
            if error_ref != NULL:
                error_msg = ocstring_to_pystring(<uint64_t>error_ref)
                raise RMNError(f"Failed to get metadata: {error_msg}")

            if metadata_ref == NULL:
                return {}

            return ocdict_to_pydict(<uint64_t>metadata_ref)

        finally:
            if error_ref != NULL:
                OCRelease(<OCTypeRef>error_ref)
            # Don't release metadata_ref - it's owned by the object

    @application.setter
    def application(self, value):
        """Set the application metadata dictionary for this RMNLib object.

        Args:
            value (dict): The application metadata dictionary to set

        Raises:
            RMNError: If the object type doesn't support application metadata or setting fails
            TypeError: If value is not a dictionary
        """
        self._validate_initialized()

        if not isinstance(value, dict):
            raise TypeError("Application metadata must be a dictionary")

        cdef OCDictionaryRef metadata_ref = NULL
        cdef OCStringRef error_ref = NULL

        try:
            metadata_ref = <OCDictionaryRef><uint64_t>ocdict_create_from_pydict(value)
            if metadata_ref == NULL:
                raise RMNError("Failed to create application metadata dictionary")

            success = RMNLibSetApplicationMetaData(self._c_ref, metadata_ref, &error_ref)

            if not success:
                if error_ref != NULL:
                    error_msg = ocstring_to_pystring(<uint64_t>error_ref)
                    raise RMNError(f"Failed to set application metadata: {error_msg}")
                else:
                    raise RMNError("Failed to set application metadata")

        finally:
            if metadata_ref != NULL:
                OCRelease(<OCTypeRef>metadata_ref)
            if error_ref != NULL:
                OCRelease(<OCTypeRef>error_ref)
