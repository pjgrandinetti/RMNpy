# Helper functions for other modules
# Cython implementation for SIDimensionality wrapper

from ..core cimport (
    SIDimensionalityRef, SIBaseDimensionIndex, OCStringRef,
    SIDimensionalityParseExpression, SIDimensionalityForQuantity, SIDimensionalityGetSymbol,
    SIDimensionalityDimensionless, OCStringGetCString,
    SIDimensionalityReducedExponentAtIndex,
    SIDimensionalityByMultiplying, SIDimensionalityByDividing,
    SIDimensionalityByRaisingToPower, SIDimensionalityByTakingNthRoot,
    kSILengthIndex, kSIMassIndex, kSITimeIndex, kSICurrentIndex,
    kSITemperatureIndex, kSIAmountIndex, kSILuminousIntensityIndex,
    OCRelease
)
from ..helpers cimport _py_to_ocstring, _ocstring_to_py
from ..exceptions import RMNLibValidationError, RMNLibMemoryError

cdef class SIDimensionality:
    """Wrapper for SITypes SIDimensionality objects representing physical dimensionalities."""
    
    def __cinit__(self):
        self._ref = NULL
        self._owns_ref = False
    
    def __dealloc__(self):
        if self._owns_ref and self._ref != NULL:
            OCRelease(self._ref)
    
    @staticmethod
    cdef SIDimensionality _from_ref(SIDimensionalityRef ref, bint owns_ref=True):
        """Create SIDimensionality wrapper from existing ref."""
        cdef SIDimensionality obj = SIDimensionality.__new__(SIDimensionality)
        obj._ref = ref
        obj._owns_ref = owns_ref
        return obj
        
    @staticmethod
    cdef SIDimensionalityRef _from_quantity(str quantity_name) except NULL:
        """Create a SIDimensionalityRef from a quantity name."""
        cdef SIDimensionalityRef result = NULL
        cdef OCStringRef error_str = NULL
        cdef OCStringRef quantity_str = NULL
        
        # Convert Python string to OCString
        quantity_str = _py_to_ocstring(quantity_name)
        if quantity_str == NULL:
            raise RMNLibMemoryError("Failed to create OCString from quantity name")
        
        try:
            result = SIDimensionalityForQuantity(quantity_str, &error_str)
            if result == NULL:
                if error_str != NULL:
                    error_msg = _ocstring_to_py(error_str)
                    OCRelease(error_str)
                    raise RMNLibValidationError(f"Unknown quantity name '{quantity_name}': {error_msg}")
                else:
                    raise RMNLibMemoryError(f"Failed to get dimensionality for quantity '{quantity_name}'")
        finally:
            OCRelease(quantity_str)
        
        return result
    
    @classmethod
    def dimensionless(cls):
        """Create a dimensionless SIDimensionality object."""
        cdef SIDimensionalityRef ref = SIDimensionalityDimensionless()
        if ref == NULL:
            raise RMNLibMemoryError("Failed to create dimensionless SIDimensionality")
        return SIDimensionality._from_ref(ref, True)
    
    @classmethod 
    def parse_expression(cls, expression):
        """Parse a dimensionality expression string.
        
        Args:
            expression: String like "L^2 T^-1" or "[length]^2 [time]^-1"
            
        Returns:
            SIDimensionality object
        """
        if not isinstance(expression, str):
            raise ValueError("Expression must be a string")
        
        cdef SIDimensionalityRef ref = SIDimensionality._parse_expression(expression)
        return SIDimensionality._from_ref(ref, True)
    
    @staticmethod
    cdef SIDimensionalityRef _parse_expression(str expression) except NULL:
        """Parse a dimensionality expression into a SIDimensionalityRef."""
        cdef SIDimensionalityRef result = NULL
        cdef OCStringRef error_str = NULL
        cdef OCStringRef expr_str = NULL
        
        # Convert Python string to OCString
        expr_str = _py_to_ocstring(expression)
        if expr_str == NULL:
            raise RMNLibMemoryError("Failed to create OCString from expression")
        
        try:
            result = SIDimensionalityParseExpression(expr_str, &error_str)
            if result == NULL:
                if error_str != NULL:
                    error_msg = _ocstring_to_py(error_str)
                    OCRelease(error_str)
                    raise RMNLibValidationError(f"Invalid dimensionality expression '{expression}': {error_msg}")
                else:
                    raise RMNLibMemoryError(f"Failed to parse dimensionality '{expression}'")
        finally:
            OCRelease(expr_str)
        
        return result
    
    @classmethod
    def from_quantity(cls, quantity_name):
        """Create a dimensionality from a physical quantity name.
        
        Args:
            quantity_name: String like "force", "energy", "pressure", "velocity", etc.
                          See kSIQuantity* constants in SIDimensionality.h
                          
        Returns:
            SIDimensionality object
            
        Example:
            force_dim = SIDimensionality.from_quantity("force")  # Returns L•M/T^2
            energy_dim = SIDimensionality.from_quantity("energy")  # Returns L^2•M/T^2
        """
        if not isinstance(quantity_name, str):
            raise ValueError("Quantity name must be a string")
        
        cdef SIDimensionalityRef ref = SIDimensionality._from_quantity(quantity_name)
        return SIDimensionality._from_ref(ref, True)
    
    @property
    def symbol(self):
        """Get the symbol representation of this dimensionality."""
        if self._ref == NULL:
            raise ValueError("Cannot get symbol of NULL dimensionality")
        
        cdef OCStringRef symbol_str = SIDimensionalityGetSymbol(self._ref)
        if symbol_str == NULL:
            return ""
        
        try:
            return _ocstring_to_py(symbol_str)
        finally:
            OCRelease(symbol_str)
    
    @property
    def length_exponent(self):
        """Get the exponent of the length dimension."""
        return self.get_reduced_exponent(kSILengthIndex)
    
    @property
    def mass_exponent(self):
        """Get the exponent of the mass dimension."""
        return self.get_reduced_exponent(kSIMassIndex)
    
    @property
    def time_exponent(self):
        """Get the exponent of the time dimension."""
        return self.get_reduced_exponent(kSITimeIndex)
    
    @property
    def current_exponent(self):
        """Get the exponent of the electric current dimension."""
        return self.get_reduced_exponent(kSICurrentIndex)
    
    @property
    def temperature_exponent(self):
        """Get the exponent of the temperature dimension."""
        return self.get_reduced_exponent(kSITemperatureIndex)
    
    @property
    def amount_exponent(self):
        """Get the exponent of the amount dimension."""
        return self.get_reduced_exponent(kSIAmountIndex)
    
    @property
    def luminous_intensity_exponent(self):
        """Get the exponent of the luminous intensity dimension."""
        return self.get_reduced_exponent(kSILuminousIntensityIndex)
    
    def get_reduced_exponent(self, SIBaseDimensionIndex dim_index):
        """Get the reduced exponent for a base dimension.
        
        Args:
            dim_index: Base dimension index (kSI*Index constant)
            
        Returns:
            Float with the exponent value
        """
        if self._ref == NULL:
            raise ValueError("Cannot get exponent from NULL dimensionality")
        return SIDimensionalityReducedExponentAtIndex(self._ref, dim_index)
    
    def __repr__(self):
        if self._ref == NULL:
            return "SIDimensionality(NULL)"
        return f"SIDimensionality({self.symbol})"
    
    def __str__(self):
        if self._ref == NULL:
            return "NULL"
        return self.symbol
    
    def __richcmp__(self, other, int op):
        if op != 2 and op != 3:  # Only == and != supported
            raise NotImplementedError("Only == and != comparisons are supported")
        
        if not isinstance(other, SIDimensionality):
            return False if op == 2 else True  # Not equal if other is not SIDimensionality
        
        cdef SIDimensionality other_dim = <SIDimensionality>other
        if self._ref == NULL or other_dim._ref == NULL:
            return (self._ref == other_dim._ref) if op == 2 else (self._ref != other_dim._ref)
        
        result = SIDimensionalityEqual(self._ref, other_dim._ref)
        return result if op == 2 else not result
    
    def __mul__(self, other):
        if not isinstance(other, SIDimensionality):
            return NotImplemented
        
        cdef SIDimensionality other_dim = <SIDimensionality>other
        cdef OCStringRef error_str = NULL
        cdef SIDimensionalityRef result = NULL
        
        result = SIDimensionalityByMultiplying(self._ref, other_dim._ref, &error_str)
        if result == NULL:
            if error_str != NULL:
                error_msg = _ocstring_to_py(error_str)
                OCRelease(error_str)
                raise RMNLibValidationError(f"Error multiplying dimensionalities: {error_msg}")
            else:
                raise RMNLibMemoryError("Failed to multiply dimensionalities")
        
        return SIDimensionality._from_ref(result, True)
    
    def __truediv__(self, other):
        if not isinstance(other, SIDimensionality):
            return NotImplemented
        
        cdef SIDimensionality other_dim = <SIDimensionality>other
        cdef SIDimensionalityRef result = NULL
        
        result = SIDimensionalityByDividing(self._ref, other_dim._ref)
        if result == NULL:
            raise RMNLibMemoryError("Failed to divide dimensionalities")
        
        return SIDimensionality._from_ref(result, True)
    
    def __pow__(self, exponent, modulo):
        if modulo is not None:
            return NotImplemented
        
        cdef double power = 0.0
        if isinstance(exponent, int) or isinstance(exponent, float):
            power = exponent
        else:
            try:
                power = float(exponent)
            except (TypeError, ValueError):
                return NotImplemented
        
        cdef OCStringRef error_str = NULL
        cdef SIDimensionalityRef result = NULL
        
        result = SIDimensionalityByRaisingToPower(self._ref, power, &error_str)
        if result == NULL:
            if error_str != NULL:
                error_msg = _ocstring_to_py(error_str)
                OCRelease(error_str)
                raise RMNLibValidationError(f"Error raising dimensionality to power: {error_msg}")
            else:
                raise RMNLibMemoryError("Failed to raise dimensionality to power")
        
        return SIDimensionality._from_ref(result, True)
    
    def root(self, unsigned int n):
        """Take the nth root of this dimensionality.
        
        Args:
            n: The root to take (e.g., 2 for square root, 3 for cube root)
            
        Returns:
            SIDimensionality object
            
        Raises:
            RMNLibValidationError: If the root cannot be taken (e.g., odd root of negative dimensionality)
        """
        if n == 0:
            raise ValueError("Cannot take 0th root")
        
        cdef OCStringRef error_str = NULL
        cdef SIDimensionalityRef result = NULL
        
        result = SIDimensionalityByTakingNthRoot(self._ref, n, &error_str)
        if result == NULL:
            if error_str != NULL:
                error_msg = _ocstring_to_py(error_str)
                OCRelease(error_str)
                raise RMNLibValidationError(f"Error taking root of dimensionality: {error_msg}")
            else:
                raise RMNLibMemoryError("Failed to take root of dimensionality")
        
        return SIDimensionality._from_ref(result, True)

# Helper functions for other modules (defined after class)
cdef SIDimensionalityRef py_to_sidimensionality_ref(object value_or_expression) except NULL:
    """Convert Python object to SIDimensionalityRef."""
    if isinstance(value_or_expression, SIDimensionality):
        return (<SIDimensionality>value_or_expression)._ref
    elif isinstance(value_or_expression, str):
        return SIDimensionality._parse_expression(value_or_expression)
    else:
        raise TypeError(f"Cannot convert {type(value_or_expression)} to SIDimensionalityRef")

cdef object sidimensionality_ref_to_py(SIDimensionalityRef dim_ref):
    """Convert SIDimensionalityRef to Python SIDimensionality object."""
    if dim_ref == NULL:
        return None
    return SIDimensionality._from_ref(dim_ref, False)
