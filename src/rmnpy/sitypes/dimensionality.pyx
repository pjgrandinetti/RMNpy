# Cython implementation for SIDimensionality wrapper

from ..core cimport (
    SIDimensionalityRef, SIBaseDimensionIndex, OCStringRef,
    SIDimensionalityParseExpression, SIDimensionalityGetSymbol,
    SIDimensionalityDimensionless, OCStringGetCString,
    SIDimensionalityReducedExponentAtIndex,
    SIDimensionalityByMultiplying, SIDimensionalityByDividing,
    SIDimensionalityByRaisingToPower, SIDimensionalityByTakingNthRoot,
    SIDimensionalityForQuantity,
    kSILengthIndex, kSIMassIndex, kSITimeIndex, kSICurrentIndex,
    kSITemperatureIndex, kSIAmountIndex, kSILuminousIntensityIndex,
    # A few key quantity constants for testing
    kSIQuantityPressure, kSIQuantityForce, kSIQuantityEnergy,
    kSIQuantityPower, kSIQuantityFrequency, kSIQuantityVelocity,
    # Base dimension quantities
    kSIQuantityLength, kSIQuantityMass, kSIQuantityTime,
    kSIQuantityCurrent, kSIQuantityTemperature,
    # Common derived quantities
    kSIQuantityArea, kSIQuantityVolume, kSIQuantityAcceleration,
    kSIQuantityDensity,
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
    def from_quantity(cls, quantity):
        """Create a SIDimensionality from a quantity name.
        
        Args:
            quantity: A string representing a physical quantity name, or one of the 
                     kSIQuantity* constants to avoid typos.
        
        Returns:
            SIDimensionality: The dimensionality for the given quantity.
        
        Raises:
            RMNLibValidationError: If the quantity is not recognized.
            RMNLibMemoryError: If memory allocation fails.
        
        Example:
            >>> dim = SIDimensionality.from_quantity("pressure")
            >>> dim = SIDimensionality.from_quantity(kSIQuantityPressure)  # Preferred
            >>> dim = SIDimensionality.from_quantity(kSIQuantityElectricCharge)
            >>> dim = SIDimensionality.from_quantity(kSIQuantityLinearMomentum)
            
        Available constants include:
        - Base quantities: kSIQuantityLength, kSIQuantityMass, kSIQuantityTime, etc.
        - Derived quantities: kSIQuantityPressure, kSIQuantityForce, kSIQuantityEnergy, etc.
        - Electromagnetic: kSIQuantityElectricCharge, kSIQuantityElectricResistance, etc.
        """
        if quantity is None:
            raise RMNLibValidationError("Quantity cannot be None")
        
        cdef OCStringRef quantity_str = NULL
        cdef OCStringRef error = NULL
        cdef SIDimensionalityRef result = NULL
        
        # Handle both OCStringRef constants and regular strings
        if isinstance(quantity, str):
            # Regular string - convert to OCStringRef
            quantity_str = _py_to_ocstring(quantity)
            if quantity_str is NULL:
                raise RMNLibMemoryError("Failed to create OCString for quantity")
        else:
            # Assume it's already an OCStringRef constant (from QUANTITY_* constants)
            quantity_str = <OCStringRef>quantity
        
        try:
            # Call the SITypes function directly
            result = SIDimensionalityForQuantity(quantity_str, &error)
            
            if error is not NULL:
                # Extract error message and release the error string
                error_msg = _ocstring_to_py(error)
                OCRelease(error)
                raise RMNLibValidationError(f"Invalid quantity: {error_msg}")
                
            if result is NULL:
                raise RMNLibValidationError(f"Unknown quantity")
                
            # Create Python wrapper
            return SIDimensionality._from_ref(result, True)
            
        finally:
            # Clean up - only release if we created the string
            if isinstance(quantity, str) and quantity_str is not NULL:
                OCRelease(quantity_str)
    
    @property
    def symbol(self):
        """Get the symbol representation of this dimensionality."""
        if self._ref == NULL:
            raise ValueError("Cannot get symbol of NULL dimensionality")
        
        cdef OCStringRef symbol_str = SIDimensionalityGetSymbol(self._ref)
        if symbol_str == NULL:
            return ""
        
        # Don't release the string as it may be a constant reference
        return _ocstring_to_py(symbol_str)
    
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
        
        # Direct comparison since SIDimensionalityEqual is not available
        cdef bint result = (self.symbol == other_dim.symbol)
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

# Python module level variables to expose C constants
# These are not explicitly assigned to avoid Cython typing issues
# They will be assigned in the module __init__ phase

# Constants are defined in __init__.py to avoid Cython type inference issues
