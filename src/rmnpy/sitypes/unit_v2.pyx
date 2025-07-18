# cython: language_level=3

from ..core cimport *
from ..helpers cimport _py_to_ocstring, _ocstring_to_py
from .dimensionality cimport SIDimensionality
from .dimensionality import SIDimensionality

cdef class SIUnit:
    """
    A comprehensive wrapper for SIUnit that provides unit creation and operations.
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
        """Get the unit symbol (root symbol only)"""
        cdef OCStringRef c_symbol = SIUnitCopyRootSymbol(self._c_unit)
        if c_symbol == NULL:
            return ""
        
        symbol = _ocstring_to_py(c_symbol)
        OCRelease(c_symbol)  # CopyRootSymbol creates a new object
        return symbol
    
    @property
    def dimensionality(self):
        """Get the dimensionality of this unit (if available)"""
        # Check if this function is available
        try:
            cdef SIDimensionalityRef c_dim = SIUnitGetDimensionality(self._c_unit)
            if c_dim == NULL:
                return None
            return SIDimensionality._from_ref(c_dim, False)
        except:
            return None
    
    def __str__(self):
        """String representation showing the unit symbol"""
        return self.symbol
    
    def __repr__(self):
        """Detailed string representation"""
        return f"SIUnit(symbol='{self.symbol}')"
