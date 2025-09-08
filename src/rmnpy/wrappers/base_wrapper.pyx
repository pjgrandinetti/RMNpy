# cython: language_level=3
"""
Base wrapper class for all RMNpy C API wrappers.

This module provides a common base class that implements the repetitive
boilerplate code found across all wrapper classes, reducing code duplication
and providing consistent behavior.
"""

from typing import Any, Dict, Optional, Union

from libc.stdint cimport uint64_t, uintptr_t

from rmnpy._c_api.octypes cimport (
    OCDictionaryRef,
    OCRelease,
    OCStringGetCString,
    OCStringRef,
    OCTypeCopyJSON,
    OCTypeDeepCopy,
    OCTypeEqual,
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
from rmnpy._c_api.sitypes cimport (
    SITypesCreateByRaisingToPower,
    SITypesCreateByReducing,
    SITypesCreateByTakingNthRoot,
    SITypesCreateStringRepresentation,
    SITypesCreateWithBinaryArithmeticOperation,
)

from rmnpy.exceptions import RMNError

from rmnpy.helpers.octypes cimport cjson_to_pydict


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

    def is_valid(self):
        """Check if the wrapper has a valid C reference (Python-accessible)."""
        return self._c_ref != NULL

    cdef void _validate_initialized(self) except *:
        """Validate that the wrapper is initialized, raise if not."""
        if self._c_ref == NULL:
            raise ValueError(f"{self.__class__.__name__} not initialized")

    # Universal copy functionality using OCTypeDeepCopy
    def copy(self):
        """Create a deep copy of this object using universal OCTypeDeepCopy.

        Returns:
            BaseWrapper: New instance of the same type (deep copy)

        Raises:
            ValueError: If wrapper is not initialized
            MemoryError: If copying fails
        """
        self._validate_initialized()
        cdef void* copied_ref = OCTypeDeepCopy(self._c_ref)
        if copied_ref == NULL:
            raise MemoryError(f"Failed to create copy of {self.__class__.__name__}")

        # Create new Python object directly with copied reference
        cdef BaseWrapper new_obj = self.__class__.__new__(self.__class__)
        new_obj._set_c_ref(copied_ref)
        return new_obj

    @classmethod
    def from_c_ref(cls, uintptr_t c_ref_ptr):
        """Create wrapper from C reference pointer using universal OCTypeDeepCopy.

        Args:
            c_ref_ptr (uintptr_t): C reference pointer as integer

        Returns:
            BaseWrapper: New instance of the calling class wrapping a copy of the C reference

        Raises:
            ValueError: If c_ref_ptr is NULL
            MemoryError: If copying fails
        """
        return BaseWrapper._from_c_ref(cls, <void*><uintptr_t>c_ref_ptr)

    @staticmethod
    cdef BaseWrapper _from_c_ref(object cls, void* c_ref):
        """Internal C-level factory method for creating wrappers from C references.

        Args:
            cls: The wrapper class to instantiate
            c_ref: The C reference pointer

        Returns:
            BaseWrapper: New instance of cls wrapping a copy of the C reference
        """
        if c_ref == NULL:
            raise ValueError("Cannot create wrapper from NULL reference")

        # Make a copy using universal OCTypeDeepCopy
        cdef void* copied_ref = OCTypeDeepCopy(<OCTypeRef>c_ref)
        if copied_ref == NULL:
            raise MemoryError("Failed to create copy of C reference")

        # Create new Python object of the correct subclass with copied reference
        cdef BaseWrapper new_obj = cls.__new__(cls)
        new_obj._set_c_ref(copied_ref)
        return new_obj

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
            if not getattr(other, 'is_valid', lambda: True)():
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

    # Universal arithmetic functionality using SITypesCreateWithBinaryArithmeticOperation
    def __add__(self, other):
        """Addition operation."""
        self._validate_initialized()
        return self._universal_binary_arithmetic(other, '+')

    def __sub__(self, other):
        """Subtraction operation."""
        self._validate_initialized()
        return self._universal_binary_arithmetic(other, '-')

    def __mul__(self, other):
        """Multiplication operation."""
        self._validate_initialized()
        return self._universal_binary_arithmetic(other, '*')

    def __truediv__(self, other):
        """Division operation."""
        self._validate_initialized()
        return self._universal_binary_arithmetic(other, '/')

    # Right-hand arithmetic operations for when Python numbers are on the left side
    def __radd__(self, other):
        """Right-hand addition: other + self."""
        # Convert other to same type and delegate to regular addition
        if hasattr(self.__class__, 'from_value'):
            try:
                other_converted = self.__class__.from_value(other)
                return other_converted.__add__(self)
            except TypeError:
                return NotImplemented
            # Let RMNError (dimensional analysis errors) propagate
        return NotImplemented

    def __rsub__(self, other):
        """Right-hand subtraction: other - self."""
        # Convert other to same type and delegate to regular subtraction
        if hasattr(self.__class__, 'from_value'):
            try:
                other_converted = self.__class__.from_value(other)
                return other_converted.__sub__(self)
            except TypeError:
                return NotImplemented
            # Let RMNError (dimensional analysis errors) propagate
        return NotImplemented

    def __rmul__(self, other):
        """Right-hand multiplication: other * self."""
        # Convert other to same type and delegate to regular multiplication
        if hasattr(self.__class__, 'from_value'):
            try:
                other_converted = self.__class__.from_value(other)
                return other_converted.__mul__(self)
            except TypeError:
                return NotImplemented
            # Let RMNError (dimensional analysis errors) propagate
        return NotImplemented

    def __rtruediv__(self, other):
        """Right-hand division: other / self."""
        # Convert other to same type and delegate to regular division
        if hasattr(self.__class__, 'from_value'):
            try:
                other_converted = self.__class__.from_value(other)
                return other_converted.__truediv__(self)
            except TypeError:
                return NotImplemented
            # Let RMNError (dimensional analysis errors) propagate
        return NotImplemented

    def _universal_binary_arithmetic(self, other, op):
        """Universal binary arithmetic using SITypesCreateWithBinaryArithmeticOperation C API."""
        # Try to convert other to the same type using from_value class method
        if not isinstance(other, BaseWrapper):
            if hasattr(self.__class__, 'from_value'):
                try:
                    other = self.__class__.from_value(other)
                except (TypeError, RMNError):
                    return NotImplemented
            else:
                return NotImplemented

        # Ensure other is a BaseWrapper after conversion and validate it
        if not isinstance(other, BaseWrapper):
            return NotImplemented

        # Validate the converted object using the same pattern as __eq__
        if hasattr(other, '_validate_initialized'):
            other._validate_initialized()
        else:
            # Fallback for objects that don't have validation
            if not getattr(other, 'is_valid', lambda: True)():
                return NotImplemented

        cdef OCStringRef error_ref = NULL
        cdef OCTypeRef result_ref = SITypesCreateWithBinaryArithmeticOperation(
            self._c_ref,
            (<BaseWrapper>other)._c_ref,
            ord(op),  # Convert char to int
            &error_ref
        )

        try:
            if error_ref != NULL:
                from rmnpy.helpers.octypes import ocstring_to_pystring
                error_msg = ocstring_to_pystring(<uintptr_t>error_ref)
                raise RMNError(f"Arithmetic operation '{op}' failed: {error_msg}")

            if result_ref == NULL:
                raise RMNError(f"Arithmetic operation '{op}' returned NULL")

            # Create appropriate wrapper for the result
            return BaseWrapper._from_c_ref(self.__class__, <void*>result_ref)
        finally:
            if error_ref != NULL:
                OCRelease(<OCTypeRef>error_ref)
            if result_ref != NULL:
                OCRelease(result_ref)

    def __pow__(self, exponent):
        """Power operation supporting both integer and fractional powers."""
        self._validate_initialized()

        # Declare Cython variables at the top
        cdef OCStringRef error_ref = NULL
        cdef OCTypeRef result_ref = NULL

        # Handle integer exponents
        if isinstance(exponent, int):
            result_ref = SITypesCreateByRaisingToPower(
                self._c_ref,
                exponent,
                &error_ref
            )

            try:
                if error_ref != NULL:
                    from rmnpy.helpers.octypes import ocstring_to_pystring
                    error_msg = ocstring_to_pystring(<uintptr_t>error_ref)
                    raise RMNError(f"Power operation failed: {error_msg}")

                if result_ref == NULL:
                    raise RMNError("Power operation returned NULL")

                # Create appropriate wrapper for the result
                return BaseWrapper._from_c_ref(self.__class__, <void*>result_ref)
            finally:
                if error_ref != NULL:
                    OCRelease(<OCTypeRef>error_ref)
                if result_ref != NULL:
                    OCRelease(result_ref)

        # Handle fractional exponents using rational approximation
        elif isinstance(exponent, (float, complex)):
            try:
                from fractions import Fraction

                # Convert to fraction with reasonable denominator limit
                frac = Fraction(exponent).limit_denominator(1000)

                # Check if it's close to the original float
                if abs(float(frac) - exponent) < 1e-10:
                    if frac.denominator == 1:
                        # It's actually an integer
                        return self.__pow__(frac.numerator)
                    elif frac.numerator == 1:
                        # Simple nth root: x^(1/n) = nth_root(x, n)
                        return self.nth_root(frac.denominator)
                    else:
                        # Complex fraction: x^(a/b) = nth_root(x^a, b)
                        powered = self.__pow__(frac.numerator)
                        return powered.nth_root(frac.denominator)
                else:
                    raise ValueError(f"Cannot represent {exponent} as a simple fraction")

            except (ValueError, OverflowError, ZeroDivisionError) as e:
                raise RMNError(f"Fractional power operation failed: {e}")

        else:
            raise TypeError("Exponent must be a number")

    def nth_root(self, root):
        """Take the nth root of this object using universal SITypesCreateByTakingNthRoot C API.

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

        cdef OCStringRef error_ref = NULL
        cdef OCTypeRef result_ref = SITypesCreateByTakingNthRoot(
            self._c_ref,
            root,
            &error_ref
        )

        try:
            if error_ref != NULL:
                from rmnpy.helpers.octypes import ocstring_to_pystring
                error_msg = ocstring_to_pystring(<uintptr_t>error_ref)
                raise RMNError(f"Nth root operation failed: {error_msg}")

            if result_ref == NULL:
                raise RMNError("Nth root operation returned NULL")

            # Create appropriate wrapper for the result
            return BaseWrapper._from_c_ref(self.__class__, <void*>result_ref)
        finally:
            if error_ref != NULL:
                OCRelease(<OCTypeRef>error_ref)
            if result_ref != NULL:
                OCRelease(result_ref)

    def reduced(self):
        """Create a reduced form of this object using universal SITypesCreateByReducing C API.

        Returns:
            Same type as self: Reduced form of the object

        Raises:
            ValueError: If wrapper is not initialized
            MemoryError: If reduction fails

        Note:
            - For scalars: Reduces the unit to its simplest form
            - For units: Reduces to lowest terms by canceling common factors
            - For dimensionalities: Reduces exponents to lowest terms
        """
        self._validate_initialized()

        cdef OCTypeRef result_ref = SITypesCreateByReducing(self._c_ref)

        try:
            if result_ref == NULL:
                raise MemoryError("Reduction operation returned NULL")

            # Create appropriate wrapper for the result
            return BaseWrapper._from_c_ref(self.__class__, <void*>result_ref)
        finally:
            if result_ref != NULL:
                OCRelease(result_ref)

    def __str__(self):
        """Create string representation using universal SITypesCreateStringRepresentation C API.

        Returns:
            str: String representation of the object

        Raises:
            ValueError: If wrapper is not initialized
            MemoryError: If string creation fails

        Note:
            - For scalars: Returns full value with unit (e.g., "5.0 m/s")
            - For units: Returns symbol representation (e.g., "m/s")
            - For dimensionalities: Returns symbolic form (e.g., "L•T^-1")
        """
        self._validate_initialized()

        cdef OCStringRef string_ref = SITypesCreateStringRepresentation(self._c_ref)

        try:
            if string_ref == NULL:
                raise MemoryError("String representation returned NULL")

            # Convert to Python string
            from rmnpy.helpers.octypes import ocstring_to_pystring
            return ocstring_to_pystring(<uintptr_t>string_ref)
        finally:
            if string_ref != NULL:
                OCRelease(<OCTypeRef>string_ref)

    def __repr__(self):
        """Universal detailed string representation.

        Returns:
            str: Detailed representation in format "ClassName('string_value')"

        Note:
            Automatically uses the class name and string representation for consistent formatting.
        """
        return f"{self.__class__.__name__}('{str(self)}')"

    # Enhanced comparison functionality using from_value for flexible comparisons
    def __eq__(self, other):
        """Enhanced equality comparison with automatic type conversion via from_value.

        Supports comparison with:
        - Other BaseWrapper instances (delegates to base class)
        - Strings, numbers, and other types convertible via from_value()

        Examples:
            >>> scalar = Scalar("5.0 m")
            >>> scalar == "5.0 m"  # True
            >>> unit = Unit("kg")
            >>> unit == "kg"       # True
        """
        if isinstance(other, BaseWrapper):
            # Delegate to base class for BaseWrapper instances
            return super().__eq__(other)

        # Try to convert other using from_value for flexible comparison
        if hasattr(self.__class__, 'from_value'):
            try:
                other_converted = self.__class__.from_value(other)
                return super().__eq__(other_converted)
            except (TypeError, RMNError, ValueError):
                # If conversion fails, objects are not equal
                return False

        # No from_value method available, not equal
        return False

    def __ne__(self, other):
        """Enhanced inequality comparison with automatic type conversion via from_value."""
        return not self.__eq__(other)


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

        # Call OCTypeCopyJSON directly with new signature
        cdef OCStringRef error_msg = NULL
        cdef cJSON* json_obj = OCTypeCopyJSON(self._c_ref, True, &error_msg)
        if json_obj == NULL:
            error_text = "Failed to serialize OCType to JSON"
            if error_msg != NULL:
                error_text += f": {OCStringGetCString(error_msg)}"
                OCRelease(error_msg)
            raise RuntimeError(error_text)

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

    @property
    def description(self):
        """Get the description of the RMNLib object."""
        self._validate_initialized()

        cdef OCStringRef error_ref = NULL
        cdef OCStringRef desc_ref = RMNLibGetDescription(self._c_ref, &error_ref)

        try:
            if error_ref != NULL:
                from rmnpy.helpers.octypes import ocstring_to_pystring
                error_msg = ocstring_to_pystring(<uintptr_t>error_ref)
                raise RMNError(f"Failed to get description: {error_msg}")

            if desc_ref == NULL:
                return None

            from rmnpy.helpers.octypes import ocstring_to_pystring
            return ocstring_to_pystring(<uintptr_t>desc_ref)
        finally:
            if error_ref != NULL:
                OCRelease(<OCTypeRef>error_ref)
            if desc_ref != NULL:
                OCRelease(<OCTypeRef>desc_ref)

    @description.setter
    def description(self, value):
        """Set the description of the RMNLib object."""
        self._validate_initialized()

        cdef OCStringRef desc_ref = NULL
        cdef OCStringRef error_ref = NULL

        if value is not None:
            from rmnpy.helpers.octypes import ocstring_create_from_pystring
            desc_ref = <OCStringRef><uintptr_t>ocstring_create_from_pystring(value)

        try:
            if not RMNLibSetDescription(self._c_ref, desc_ref, &error_ref):
                if error_ref != NULL:
                    from rmnpy.helpers.octypes import ocstring_to_pystring
                    error_msg = ocstring_to_pystring(<uintptr_t>error_ref)
                    raise RMNError(f"Failed to set description: {error_msg}")
                else:
                    raise RMNError("Failed to set description")
        finally:
            if error_ref != NULL:
                OCRelease(<OCTypeRef>error_ref)
            if desc_ref != NULL:
                OCRelease(<OCTypeRef>desc_ref)

    @property
    def application(self):
        """Get the application metadata of the RMNLib object."""
        self._validate_initialized()

        cdef OCStringRef error_ref = NULL
        cdef OCDictionaryRef app_ref = RMNLibGetApplicationMetaData(self._c_ref, &error_ref)

        try:
            if error_ref != NULL:
                from rmnpy.helpers.octypes import ocstring_to_pystring
                error_msg = ocstring_to_pystring(<uintptr_t>error_ref)
                raise RMNError(f"Failed to get application metadata: {error_msg}")

            if app_ref == NULL:
                return {}

            from rmnpy.helpers.octypes import ocdict_to_pydict
            return ocdict_to_pydict(<uintptr_t>app_ref)
        finally:
            if error_ref != NULL:
                OCRelease(<OCTypeRef>error_ref)
            # Don't release app_ref - it's an internal reference

    @application.setter
    def application(self, value):
        """Set the application metadata of the RMNLib object."""
        self._validate_initialized()

        if not isinstance(value, dict):
            raise TypeError("application metadata must be a dictionary")

        cdef OCDictionaryRef app_ref = NULL
        cdef OCStringRef error_ref = NULL

        try:
            # Convert Python dictionary to OCDictionary
            from rmnpy.helpers.octypes import ocdict_create_from_pydict
            app_ref = <OCDictionaryRef><uintptr_t>ocdict_create_from_pydict(value)
            if app_ref == NULL:
                raise RMNError("Failed to create application metadata dictionary")

            if not RMNLibSetApplicationMetaData(self._c_ref, app_ref, &error_ref):
                if error_ref != NULL:
                    from rmnpy.helpers.octypes import ocstring_to_pystring
                    error_msg = ocstring_to_pystring(<uintptr_t>error_ref)
                    raise RMNError(f"Failed to set application metadata: {error_msg}")
                else:
                    raise RMNError("Failed to set application metadata")
        finally:
            if error_ref != NULL:
                OCRelease(<OCTypeRef>error_ref)
            if app_ref != NULL:
                OCRelease(<OCTypeRef>app_ref)
