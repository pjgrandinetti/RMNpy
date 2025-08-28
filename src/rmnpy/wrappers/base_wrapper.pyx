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
    OCRelease,
    OCTypeCopyJSON,
    OCTypeEqual,
    OCTypeRef,
    cJSON,
    cJSON_Delete,
)

from rmnpy.exceptions import RMNError
from rmnpy.helpers.octypes import cjson_to_pydict


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

    cdef bint _is_initialized(self):
        """Check if the wrapper has a valid C reference."""
        return self._c_ref != NULL

    def is_valid(self):
        """Check if the wrapper has a valid C reference (Python-accessible)."""
        return self._is_initialized()

    cdef void _validate_initialized(self) except *:
        """Validate that the wrapper is initialized, raise if not."""
        if not self._is_initialized():
            raise ValueError(f"{self.__class__.__name__} not initialized")

    # Subclasses must implement these methods
    cdef void* copy_c_ref(self) except NULL:
        """Create a copy of the C reference. Must be implemented by subclasses."""
        raise NotImplementedError(f"{self.__class__.__name__} must implement copy_c_ref()")

    @staticmethod
    def from_c_ref(uint64_t c_ref_ptr):
        """Create wrapper from C reference pointer (Python-accessible)."""
        raise NotImplementedError("Subclasses must implement from_c_ref()")

    # Universal comparison functionality using OCTypeEqual
    def __eq__(self, other):
        """Check equality using universal OCTypeEqual."""
        if not isinstance(other, BaseWrapper):
            return False
        self._validate_initialized()
        if hasattr(other, '_validate_initialized'):
            other._validate_initialized()
        else:
            # Fallback for objects that don't have validation
            if not getattr(other, '_is_initialized', lambda: True)():
                return False

        # Use universal OCTypeEqual function
        return OCTypeEqual(self._c_ref, (<BaseWrapper>other)._c_ref)

    def __ne__(self, other):
        """Check inequality."""
        return not self.__eq__(other)


# Specific base classes for different API families with integrated functionality

cdef class SITypesWrapper(BaseWrapper):
    """
    Base class for SITypes wrappers (Scalar, Unit, Dimensionality, etc.).

    Inherits universal functionality from BaseWrapper including:
    - Memory management and copying
    - Universal equality comparison (OCTypeEqual)

    Provides arithmetic operations that delegate to subclass implementations.
    """

    # Arithmetic functionality (integrated from ArithmeticWrapper)
    def __add__(self, other):
        """Addition operation."""
        self._validate_initialized()
        return self._binary_arithmetic(other, "add")

    def __sub__(self, other):
        """Subtraction operation."""
        self._validate_initialized()
        return self._binary_arithmetic(other, "sub")

    def __mul__(self, other):
        """Multiplication operation."""
        self._validate_initialized()
        return self._binary_arithmetic(other, "mul")

    def __truediv__(self, other):
        """Division operation."""
        self._validate_initialized()
        return self._binary_arithmetic(other, "div")

    def __pow__(self, exponent):
        """Power operation."""
        self._validate_initialized()
        return self._power_arithmetic(exponent)

    def nth_root(self, root):
        """Take the nth root of this object.

        Args:
            root (int): Root to take (e.g., 2 for square root)

        Returns:
            Same type as self: nth root of the object

        Raises:
            TypeError: If root is not an integer
            ValueError: If root is not positive
        """
        if not isinstance(root, int):
            raise TypeError("Root must be an integer")
        if root <= 0:
            raise ValueError("Root must be a positive integer")

        self._validate_initialized()
        return self._nth_root_arithmetic(root)

    # Subclasses must implement these unified methods
    def _binary_arithmetic(self, other, operation):
        """Perform binary arithmetic operation. Override in subclasses."""
        raise NotImplementedError(f"{self.__class__.__name__} does not implement {operation}")

    def _power_arithmetic(self, exponent):
        """Perform power operation. Override in subclasses."""
        raise NotImplementedError(f"{self.__class__.__name__} does not implement power")

    def _nth_root_arithmetic(self, root):
        """Perform nth root operation. Override in subclasses."""
        raise NotImplementedError(f"{self.__class__.__name__} does not implement nth_root")


cdef class RMNLibWrapper(BaseWrapper):
    """
    Base class for RMNLib wrappers (Dataset, Datum, DependentVariable, etc.).

    Inherits universal functionality from BaseWrapper including:
    - Memory management and copying
    - Universal equality comparison (OCTypeEqual)

    Provides serialization functionality for data container types.
    """

    # Serialization functionality (integrated from SerializableWrapper)
    def dict(self):
        """Convert to dictionary representation (canonical API).

        This is the single, stable serialization entrypoint for RMNLib wrappers.
        Uses the universal OCTypeCopyJSON C API for consistent serialization.
        """
        self._validate_initialized()

        # Call OCTypeCopyJSON directly
        cdef cJSON* json_obj = OCTypeCopyJSON(self._c_ref)
        if json_obj == NULL:
            raise RuntimeError("Failed to serialize OCType to JSON")

        try:
            # Convert cJSON to Python dict
            return cjson_to_pydict(json_obj)
        finally:
            # Clean up cJSON object
            cJSON_Delete(json_obj)

    @classmethod
    def from_dict(cls, json_dict):
        """Create instance from dictionary representation."""
        if not isinstance(json_dict, dict):
            raise TypeError("Expected dictionary input")
        raise NotImplementedError(f"{cls.__name__} must implement from_dict()")
