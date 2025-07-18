# cython: language_level=3

from ..core cimport *
from ..helpers cimport _py_to_ocstring, _ocstring_to_py
from .dimensionality cimport SIDimensionality
from .dimensionality import SIDimensionality

cdef class SIUnit:
    """
    A minimal SIUnit wrapper to test basic functionality.
    """
    
    def __init__(self):
        # SIUnit objects should only be created through class methods
        raise RuntimeError("SIUnit objects should be created using class methods like from_expression()")
    
    @staticmethod
    cdef SIUnit _from_c_unit(SIUnitRef c_unit, bint owns_ref=False):
        """Create a SIUnit wrapper from a C SIUnitRef"""
        if c_unit == NULL:
            return None
        
        cdef SIUnit unit = SIUnit.__new__(SIUnit)
        unit._c_unit = c_unit
        unit._owns_ref = owns_ref
        return unit
    
    cdef SIUnitRef _get_c_unit(self):
        """Get the underlying C SIUnitRef"""
        return self._c_unit
    
    def __dealloc__(self):
        """Cleanup when the object is destroyed"""
        if self._owns_ref and self._c_unit != NULL:
            OCRelease(self._c_unit)
    
    @classmethod
    def from_expression(cls, expression):
        """
        Create a SIUnit from an expression string.
        
        Args:
            expression (str): Unit expression like "m/s^2", "Hz", "kg*m/s^2", etc.
            
        Returns:
            tuple: (SIUnit, multiplier) where multiplier is the scale factor
            
        Raises:
            ValueError: If the expression cannot be parsed
        """
        cdef OCStringRef c_expression = _py_to_ocstring(expression)
        cdef double multiplier = 1.0
        cdef OCStringRef error = NULL
        
        cdef SIUnitRef c_unit = SIUnitFromExpression(c_expression, &multiplier, &error)
        
        if c_unit == NULL:
            error_msg = "Failed to parse unit expression"
            if error != NULL:
                error_msg = f"Failed to parse unit expression: {_ocstring_to_py(error)}"
            raise ValueError(error_msg)
        
        unit = SIUnit._from_c_unit(c_unit, True)  # FromExpression creates a new object
        return unit, multiplier
    
    @property
    def symbol(self):
        """Get the unit symbol (uses SIUnitCopySymbol for compound units)"""
        cdef OCStringRef c_symbol = SIUnitCopySymbol(self._c_unit)
        if c_symbol == NULL:
            return ""
        
        symbol = _ocstring_to_py(c_symbol)
        OCRelease(c_symbol)  # CopySymbol creates a new object
        return symbol
    
    def __str__(self):
        """String representation showing the unit symbol"""
        return self.symbol
    
    def dimensionality(self):
        """Get the dimensionality of this unit
        
        Returns:
            SIDimensionality: The dimensionality object for this unit
        """
        # For now, return None until we can properly access SIUnitGetDimensionality
        # TODO: Fix the function declaration issue
        return None
    
    def __repr__(self):
        """Detailed string representation"""
        return f"SIUnit(symbol='{self.symbol}')"
    
    # Arithmetic operations
    def __mul__(self, other):
        """Multiply two units: unit1 * unit2"""
        if not isinstance(other, SIUnit):
            raise TypeError(f"Cannot multiply SIUnit with {type(other)}")
        
        # Create a combined expression and parse it
        # This is a workaround using the working from_expression method
        combined_expr = f"({self.symbol})*({other.symbol})"
        try:
            result_unit, multiplier = SIUnit.from_expression(combined_expr)
            return result_unit  # Return just the unit, not the tuple
        except ValueError as e:
            raise ValueError(f"Failed to multiply units {self.symbol} and {other.symbol}: {e}")
    
    def __truediv__(self, other):
        """Divide two units: unit1 / unit2"""
        if not isinstance(other, SIUnit):
            raise TypeError(f"Cannot divide SIUnit by {type(other)}")
        
        # Create a combined expression and parse it
        # This is a workaround using the working from_expression method  
        combined_expr = f"({self.symbol})/({other.symbol})"
        try:
            result_unit, multiplier = SIUnit.from_expression(combined_expr)
            return result_unit  # Return just the unit, not the tuple
        except ValueError as e:
            raise ValueError(f"Failed to divide units {self.symbol} by {other.symbol}: {e}")
    
    def __pow__(self, power):
        """Raise unit to a power: unit ** power"""
        if not isinstance(power, (int, float)):
            raise TypeError(f"Cannot raise SIUnit to power of type {type(power)}")
        
        # Create a power expression and parse it
        # This is a workaround using the working from_expression method
        power_expr = f"({self.symbol})^{power}"
        try:
            result_unit, multiplier = SIUnit.from_expression(power_expr)
            return result_unit  # Return just the unit, not the tuple
        except ValueError as e:
            raise ValueError(f"Failed to raise unit {self.symbol} to power {power}: {e}")
