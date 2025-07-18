# Cython implementation for SIScalar wrapper

from ..core cimport (
    SIScalarRef, SIUnitRef, SIDimensionalityRef, OCStringRef,
    SIScalarCreateFromExpression, SIScalarCreateWithDouble,
    SIScalarDoubleValueInCoherentUnit, SIUnitFromExpression,
    SIScalarCreateByAdding, SIScalarCreateBySubtracting,
    SIScalarCreateByMultiplying, SIScalarCreateByDividing,
    SIScalarCreateByRaisingToPower, SIScalarCreateUnitString,
    SIUnitGetDimensionality, OCStringGetCString,
    OCRelease, OCRetain
)
from ..helpers cimport _py_to_ocstring, _ocstring_to_py
from ..exceptions import RMNLibValidationError, RMNLibMemoryError
from .helpers cimport py_to_siscalar_ref, siscalar_ref_to_py, siscalar_ref_to_string
from .unit cimport SIUnit
from .dimensionality cimport SIDimensionality

cdef class SIScalar:
    """Wrapper for SITypes SIScalar objects representing physical quantities with units."""
    
    def __cinit__(self):
        self._ref = NULL
        self._owns_ref = False
    
    def __dealloc__(self):
        if self._owns_ref and self._ref != NULL:
            OCRelease(self._ref)
    
    def __init__(self, value=None):
        """Initialize SIScalar with optional numeric value (creates dimensionless scalar)."""
        if value is not None:
            # Create dimensionless scalar using helper functions
            try:
                self._ref = py_to_siscalar_ref(value)
                if self._ref == NULL:
                    raise RMNLibMemoryError("Failed to create dimensionless SIScalar")
                self._owns_ref = True
            except Exception as e:
                raise TypeError(f"Cannot convert {type(value)} to SIScalar: {e}")
    
    @staticmethod
    cdef SIScalar _from_ref(SIScalarRef ref, bint owns_ref=True):
        """Create SIScalar wrapper from existing SIScalarRef."""
        if ref == NULL:
            return None
        cdef SIScalar scalar = SIScalar.__new__(SIScalar)
        scalar._ref = ref
        scalar._owns_ref = owns_ref
        if not owns_ref:
            OCRetain(ref)  # Retain if we don't own it
        return scalar
    
    cdef SIScalarRef _get_c_ref(self):
        """Get the underlying C SIScalarRef for internal use."""
        return self._ref
    
    @staticmethod
    def from_expression(expression):
        """Create SIScalar from string expression.
        
        Note: Full expression parsing is not available in this version of SITypes.
        This method only supports simple "value unit" format like "1.0 Hz" or "2.5 m".
        """
        if not isinstance(expression, str):
            raise ValueError("Expression must be a string")
        
        # Try to parse simple "value unit" format
        parts = expression.strip().split()
        if len(parts) == 2:
            try:
                value = float(parts[0])
                unit = parts[1]
                return SIScalar.from_value_and_unit(value, unit)
            except ValueError:
                raise RMNLibValidationError(f"Cannot parse expression '{expression}'. Only simple 'value unit' format is supported (e.g., '1.0 Hz').")
        elif len(parts) == 1:
            try:
                value = float(parts[0])
                return SIScalar.from_value_and_unit(value, None)
            except ValueError:
                raise RMNLibValidationError(f"Cannot parse expression '{expression}' as a numeric value.")
        else:
            raise RMNLibValidationError(f"Cannot parse expression '{expression}'. Only simple 'value unit' format is supported (e.g., '1.0 Hz').")
    
    @staticmethod
    def from_value_and_unit(double value, unit):
        """Create SIScalar from separate value and unit.
        
        Args:
            value: Numeric value
            unit: Either a unit string like 'Hz', 'ppm', 's', or a SIUnit object
            
        Returns:
            SIScalar object
            
        Raises:
            RMNLibValidationError: If unit is invalid
            RMNLibMemoryError: If creation fails
        """
        cdef SIScalarRef ref
        
        if isinstance(unit, SIUnit):
            # Use the SIUnit object directly
            ref = SIScalar._create_with_value_and_siunit(value, unit)
        else:
            # Treat as string
            ref = SIScalar._create_with_value_and_unit(value, unit)
        
        return SIScalar._from_ref(ref, owns_ref=True)
    
    @staticmethod
    cdef SIScalarRef _create_with_value_and_siunit(double value, SIUnit unit_obj) except NULL:
        """Create SIScalarRef from value and SIUnit object."""
        cdef SIUnitRef unit_ref = unit_obj._get_c_unit()
        if unit_ref == NULL:
            raise RMNLibValidationError("Invalid SIUnit object")
        
        cdef SIScalarRef result = SIScalarCreateWithDouble(value, unit_ref)
        if result == NULL:
            raise RMNLibMemoryError("Failed to create SIScalar")
        
        return result
    
    @staticmethod
    cdef SIScalarRef _create_with_value_and_unit(double value, object unit_str) except NULL:
        """Create SIScalarRef from value and unit string."""
        cdef SIUnitRef unit = NULL
        cdef SIScalarRef result = NULL
        cdef OCStringRef error_str = NULL
        cdef OCStringRef unit_expr = NULL
        
        if unit_str is not None:
            # Parse the unit string
            unit_expr = _py_to_ocstring(unit_str)
            if unit_expr == NULL:
                raise RMNLibMemoryError("Failed to create OCString from unit")
            
            try:
                unit = SIUnitFromExpression(unit_expr, NULL, &error_str)
                if unit == NULL:
                    if error_str != NULL:
                        error_msg = _ocstring_to_py(error_str)
                        OCRelease(error_str)
                        raise RMNLibValidationError(f"Invalid unit expression '{unit_str}': {error_msg}")
                    else:
                        raise RMNLibMemoryError(f"Failed to parse unit '{unit_str}'")
            finally:
                OCRelease(unit_expr)
        
        # Create scalar with parsed unit
        result = SIScalarCreateWithDouble(value, unit)
        if result == NULL:
            if unit != NULL:
                OCRelease(unit)
            raise RMNLibMemoryError("Failed to create SIScalar")
        
        # Release unit since SIScalar now owns it
        if unit != NULL:
            OCRelease(unit)
        
        return result
    
    @property
    def value(self):
        """Get the numeric value in coherent SI units."""
        if self._ref == NULL:
            return 0.0
        return SIScalarDoubleValueInCoherentUnit(self._ref)
    
    @property
    def unit(self):
        """Get the unit as a SIUnit object.
        
        Returns:
            SIUnit: The unit of this scalar
        """
        if self._ref == NULL:
            return None
        
        # For now, return None until we implement proper unit extraction
        # This requires accessing the internal SIScalar struct which
        # isn't directly exposed in the SITypes API
        # TODO: Implement when SITypes provides a unit getter function
        return None
    
    @property
    def unit_symbol(self):
        """Get the unit symbol as a string.
        
        Returns:
            str: The symbol representation of this scalar's unit
        """
        if self._ref == NULL:
            return ""
        
        cdef OCStringRef unit_string = SIScalarCreateUnitString(self._ref)
        if unit_string == NULL:
            return ""
        
        cdef const char* c_str = OCStringGetCString(unit_string)
        cdef str result = ""
        
        if c_str != NULL:
            result = c_str.decode('utf-8')
        
        OCRelease(unit_string)
        return result
    
    @property 
    def dimensionality(self):
        """Get the dimensionality as a SIDimensionality object.
        
        Returns:
            SIDimensionality: The dimensionality of this scalar's unit
        """
        # For now, return None until we implement unit access
        # TODO: Extract unit first, then get its dimensionality
        return None
    
    def __str__(self):
        """String representation of the scalar with value and unit."""
        if self._ref == NULL:
            return "SIScalar(0.0)"
        
        unit_symbol = self.unit_symbol
        if unit_symbol:
            return f"{self.value} {unit_symbol}"
        else:
            return f"{self.value}"
    
    def __repr__(self):
        """Detailed string representation."""
        if self._ref == NULL:
            return "SIScalar(NULL)"
        
        unit_symbol = self.unit_symbol
        if unit_symbol:
            return f"SIScalar(value={self.value}, unit='{unit_symbol}')"
        else:
            return f"SIScalar(value={self.value})"
    
    # Arithmetic operations using SITypes functions
    def __add__(self, other):
        """Add two SIScalar objects."""
        if not isinstance(other, SIScalar):
            raise TypeError(f"Cannot add SIScalar to {type(other)}")
        
        cdef SIScalarRef other_ref = (<SIScalar>other)._ref
        cdef OCStringRef error = NULL
        
        cdef SIScalarRef result = SIScalarCreateByAdding(self._ref, other_ref, &error)
        if result == NULL:
            if error != NULL:
                error_msg = _ocstring_to_py(error)
                OCRelease(error)
                raise RMNLibValidationError(f"Cannot add scalars: {error_msg}")
            else:
                raise RMNLibMemoryError("Failed to add SIScalar objects")
        
        return SIScalar._from_ref(result, owns_ref=True)
    
    def __sub__(self, other):
        """Subtract two SIScalar objects."""
        if not isinstance(other, SIScalar):
            raise TypeError(f"Cannot subtract {type(other)} from SIScalar")
        
        cdef SIScalarRef other_ref = (<SIScalar>other)._ref
        cdef OCStringRef error = NULL
        
        cdef SIScalarRef result = SIScalarCreateBySubtracting(self._ref, other_ref, &error)
        if result == NULL:
            if error != NULL:
                error_msg = _ocstring_to_py(error)
                OCRelease(error)
                raise RMNLibValidationError(f"Cannot subtract scalars: {error_msg}")
            else:
                raise RMNLibMemoryError("Failed to subtract SIScalar objects")
        
        return SIScalar._from_ref(result, owns_ref=True)
    
    def __mul__(self, other):
        """Multiply two SIScalar objects."""
        if not isinstance(other, SIScalar):
            raise TypeError(f"Cannot multiply SIScalar by {type(other)}")
        
        cdef SIScalarRef other_ref = (<SIScalar>other)._ref
        cdef OCStringRef error = NULL
        
        cdef SIScalarRef result = SIScalarCreateByMultiplying(self._ref, other_ref, &error)
        if result == NULL:
            if error != NULL:
                error_msg = _ocstring_to_py(error)
                OCRelease(error)
                raise RMNLibValidationError(f"Cannot multiply scalars: {error_msg}")
            else:
                raise RMNLibMemoryError("Failed to multiply SIScalar objects")
        
        return SIScalar._from_ref(result, owns_ref=True)
    
    def __truediv__(self, other):
        """Divide two SIScalar objects."""
        if not isinstance(other, SIScalar):
            raise TypeError(f"Cannot divide SIScalar by {type(other)}")
        
        cdef SIScalarRef other_ref = (<SIScalar>other)._ref
        cdef OCStringRef error = NULL
        
        cdef SIScalarRef result = SIScalarCreateByDividing(self._ref, other_ref, &error)
        if result == NULL:
            if error != NULL:
                error_msg = _ocstring_to_py(error)
                OCRelease(error)
                raise RMNLibValidationError(f"Cannot divide scalars: {error_msg}")
            else:
                raise RMNLibMemoryError("Failed to divide SIScalar objects")
        
        return SIScalar._from_ref(result, owns_ref=True)
    
    def __pow__(self, power):
        """Raise SIScalar to a power."""
        if not isinstance(power, (int, float)):
            raise TypeError(f"Cannot raise SIScalar to power of type {type(power)}")
        
        cdef OCStringRef error = NULL
        cdef SIScalarRef result = SIScalarCreateByRaisingToPower(self._ref, <double>power, &error)
        
        if result == NULL:
            if error != NULL:
                error_msg = _ocstring_to_py(error)
                OCRelease(error)
                raise RMNLibValidationError(f"Cannot raise scalar to power: {error_msg}")
            else:
                raise RMNLibMemoryError("Failed to raise SIScalar to power")
        
        return SIScalar._from_ref(result, owns_ref=True)

# Helper function for other modules to extract SIScalarRef
cdef SIScalarRef _get_scalar_ref(object scalar_obj):
    """Extract SIScalarRef from a SIScalar object."""
    if not isinstance(scalar_obj, SIScalar):
        return NULL
    cdef SIScalar scalar = <SIScalar>scalar_obj
    return scalar._ref
