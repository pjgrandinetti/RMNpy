# cython: language_level=3
"""
Base wrapper class for all RMNpy C API wrappers.

This module provides a common base class that implements the repetitive
boilerplate code found across all wrapper classes, reducing code duplication
and providing consistent behavior.
"""

from typing import Any, Dict, Optional, Union

from libc.stdint cimport uint64_t

from rmnpy._c_api.octypes cimport OCRelease, OCTypeRef

from rmnpy.exceptions import RMNError


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


# Specific base classes for different API families with integrated functionality

cdef class SITypesWrapper(BaseWrapper):
    """
    Base class for SITypes wrappers (Scalar, Unit, Dimensionality, etc.).

    Provides integrated functionality that would have been in mixins,
    since Cython doesn't support multiple inheritance.
    """

    # Comparison functionality (integrated from ComparableWrapper)
    def __eq__(self, other):
        """Check equality."""
        if not isinstance(other, self.__class__):
            return False
        self._validate_initialized()
        if hasattr(other, '_validate_initialized'):
            other._validate_initialized()
        else:
            # Fallback for objects that don't have validation
            if not getattr(other, '_is_initialized', lambda: True)():
                return False
        return self._compare_c_api(other) == 0

    def __ne__(self, other):
        """Check inequality."""
        return not self.__eq__(other)

    def __lt__(self, other):
        """Check less than."""
        if not isinstance(other, self.__class__):
            return NotImplemented
        self._validate_initialized()
        if hasattr(other, '_validate_initialized'):
            other._validate_initialized()
        return self._compare_c_api(other) < 0

    def __le__(self, other):
        """Check less than or equal."""
        if not isinstance(other, self.__class__):
            return NotImplemented
        self._validate_initialized()
        if hasattr(other, '_validate_initialized'):
            other._validate_initialized()
        return self._compare_c_api(other) <= 0

    def __gt__(self, other):
        """Check greater than."""
        if not isinstance(other, self.__class__):
            return NotImplemented
        self._validate_initialized()
        if hasattr(other, '_validate_initialized'):
            other._validate_initialized()
        return self._compare_c_api(other) > 0

    def __ge__(self, other):
        """Check greater than or equal."""
        if not isinstance(other, self.__class__):
            return NotImplemented
        self._validate_initialized()
        if hasattr(other, '_validate_initialized'):
            other._validate_initialized()
        return self._compare_c_api(other) >= 0

    # Arithmetic functionality (integrated from ArithmeticWrapper)
    def __add__(self, other):
        """Addition operation."""
        self._validate_initialized()
        return self._add_c_api(other)

    def __sub__(self, other):
        """Subtraction operation."""
        self._validate_initialized()
        return self._sub_c_api(other)

    def __mul__(self, other):
        """Multiplication operation."""
        self._validate_initialized()
        return self._mul_c_api(other)

    def __truediv__(self, other):
        """Division operation."""
        self._validate_initialized()
        return self._div_c_api(other)

    def __pow__(self, other):
        """Power operation."""
        self._validate_initialized()
        return self._pow_c_api(other)

    # Subclasses can override specific operations as needed
    cdef int _compare_c_api(self, other) except? -999:
        """Compare with another instance using C API. Override in subclasses."""
        raise NotImplementedError(f"{self.__class__.__name__} must implement _compare_c_api()")

    def _add_c_api(self, other):
        """Addition using C API. Override in subclasses."""
        raise NotImplementedError(f"{self.__class__.__name__} does not support addition")

    def _sub_c_api(self, other):
        """Subtraction using C API. Override in subclasses."""
        raise NotImplementedError(f"{self.__class__.__name__} does not support subtraction")

    def _mul_c_api(self, other):
        """Multiplication using C API. Override in subclasses."""
        raise NotImplementedError(f"{self.__class__.__name__} does not support multiplication")

    def _div_c_api(self, other):
        """Division using C API. Override in subclasses."""
        raise NotImplementedError(f"{self.__class__.__name__} does not support division")

    def _pow_c_api(self, other):
        """Power using C API. Override in subclasses."""
        raise NotImplementedError(f"{self.__class__.__name__} does not support exponentiation")


cdef class RMNLibWrapper(BaseWrapper):
    """
    Base class for RMNLib wrappers (Dataset, Datum, DependentVariable, etc.).

    Provides integrated functionality that would have been in mixins,
    since Cython doesn't support multiple inheritance.
    """

    # Serialization functionality (integrated from SerializableWrapper)
    def to_dict(self):
        """Convert to dictionary representation."""
        self._validate_initialized()
        return self._to_dict_c_api()

    def dict(self):
        """Alias for to_dict() for compatibility."""
        return self.to_dict()

    @classmethod
    def from_dict(cls, data_dict):
        """Create instance from dictionary representation."""
        if not isinstance(data_dict, dict):
            raise TypeError("Expected dictionary input")
        return cls._from_dict_c_api(data_dict)

    # Comparison functionality (integrated from ComparableWrapper)
    def __eq__(self, other):
        """Check equality."""
        if not isinstance(other, self.__class__):
            return False
        self._validate_initialized()
        if hasattr(other, '_validate_initialized'):
            other._validate_initialized()
        else:
            # Fallback for objects that don't have validation
            if not getattr(other, '_is_initialized', lambda: True)():
                return False
        return self._compare_c_api(other) == 0

    def __ne__(self, other):
        """Check inequality."""
        return not self.__eq__(other)

    # Subclasses must implement these methods
    def _to_dict_c_api(self):
        """Convert to dictionary using C API. Must be implemented by subclasses."""
        raise NotImplementedError(f"{self.__class__.__name__} must implement _to_dict_c_api()")

    @classmethod
    def _from_dict_c_api(cls, data_dict):
        """Create from dictionary using C API. Must be implemented by subclasses."""
        raise NotImplementedError(f"{cls.__name__} must implement _from_dict_c_api()")

    cdef int _compare_c_api(self, other) except? -999:
        """Compare with another instance using C API. Override in subclasses if needed."""
        # Default implementation for RMNLib objects - can be overridden
        raise NotImplementedError(f"{self.__class__.__name__} must implement _compare_c_api()")
