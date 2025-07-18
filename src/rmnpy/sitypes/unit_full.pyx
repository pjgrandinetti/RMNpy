# cython: language_level=3

from ..core cimport *
from ..helpers cimport _py_to_ocstring, _ocstring_to_py
from .dimensionality cimport SIDimensionality
from .dimensionality import SIDimensionality

cdef class SIUnit:
    """
    A comprehensive wrapper for SIUnit that provides:
    - Unit creation from symbols and expressions
    - Unit arithmetic operations (multiplication, division, powers)
    - Unit properties (symbol, name, dimensionality)
    - Unit comparison and conversion factors
    """
    
    def __init__(self):
        # SIUnit objects should only be created through class methods
        raise RuntimeError("SIUnit objects should be created using class methods like from_symbol() or from_expression()")
    
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
    
    # Class methods for creating SIUnit objects
    
    @classmethod
    def from_symbol(cls, symbol):
        """
        Create a SIUnit from a symbol string.
        
        Args:
            symbol (str): Unit symbol like "Hz", "m", "kg", etc.
            
        Returns:
            SIUnit: The unit object
            
        Raises:
            ValueError: If the symbol is not recognized
        """
        cdef OCStringRef c_symbol = _py_to_ocstring(symbol)
        cdef SIUnitRef c_unit = SIUnitFindWithUnderivedSymbol(c_symbol)
        
        if c_unit == NULL:
            raise ValueError(f"Unknown unit symbol: {symbol}")
        
        return SIUnit._from_c_unit(c_unit, False)
    
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
    
    @classmethod
    def from_name(cls, name):
        """
        Create a SIUnit from a unit name.
        
        Args:
            name (str): Unit name like "hertz", "meter", "kilogram", etc.
            
        Returns:
            SIUnit: The unit object
            
        Raises:
            ValueError: If the name is not recognized
        """
        cdef OCStringRef c_name = _py_to_ocstring(name)
        cdef SIUnitRef c_unit = SIUnitFindWithName(c_name)
        
        if c_unit == NULL:
            raise ValueError(f"Unknown unit name: {name}")
        
        return SIUnit._from_c_unit(c_unit, False)
    
    @classmethod
    def dimensionless(cls):
        """
        Create the dimensionless unit.
        
        Returns:
            SIUnit: The dimensionless unit
        """
        cdef SIUnitRef c_unit = SIUnitDimensionlessAndUnderived()
        return SIUnit._from_c_unit(c_unit, False)
    
    # Properties
    
    @property
    def symbol(self):
        """Get the unit symbol (e.g., 'Hz', 'm/s')"""
        cdef OCStringRef c_symbol = SIUnitCopySymbol(self._c_unit)
        if c_symbol == NULL:
            return ""
        
        symbol = _ocstring_to_py(c_symbol)
        OCRelease(c_symbol)  # CopySymbol creates a new object
        return symbol
    
    @property
    def name(self):
        """Get the unit name (e.g., 'hertz', 'meter per second')"""
        cdef OCStringRef c_name = SIUnitCreateName(self._c_unit)
        if c_name == NULL:
            return ""
        
        name = _ocstring_to_py(c_name)
        OCRelease(c_name)  # CreateName creates a new object
        return name
    
    @property
    def plural_name(self):
        """Get the plural unit name (e.g., 'hertz', 'meters per second')"""
        cdef OCStringRef c_name = SIUnitCreatePluralName(self._c_unit)
        if c_name == NULL:
            return ""
        
        name = _ocstring_to_py(c_name)
        OCRelease(c_name)  # CreatePluralName creates a new object
        return name
    
    @property
    def dimensionality(self):
        """Get the dimensionality of this unit"""
        cdef SIDimensionalityRef c_dim = SIUnitGetDimensionality(self._c_unit)
        if c_dim == NULL:
            return None
        
        return SIDimensionality._from_ref(c_dim, False)
    
    @property
    def quantity_name(self):
        """Get a guessed quantity name for this unit"""
        cdef OCStringRef c_name = SIUnitGuessQuantityName(self._c_unit)
        if c_name == NULL:
            return ""
        
        # SIUnitGuessQuantityName returns a borrowed reference
        return _ocstring_to_py(c_name)
    
    # Unit arithmetic operations
    
    def __mul__(self, other):
        """Multiply two units (unit1 * unit2)"""
        if not isinstance(other, SIUnit):
            raise TypeError(f"Cannot multiply SIUnit with {type(other)}")
        
        cdef SIUnit other_unit = other
        cdef double multiplier = 1.0
        cdef OCStringRef error = NULL
        
        cdef SIUnitRef c_result = SIUnitByMultiplying(
            self._c_unit, other_unit._c_unit, &multiplier, &error
        )
        
        if c_result == NULL:
            error_msg = "Failed to multiply units"
            if error != NULL:
                error_msg = f"Failed to multiply units: {_ocstring_to_py(error)}"
            raise ValueError(error_msg)
        
        result = SIUnit._from_c_unit(c_result, True)  # ByMultiplying creates a new object
        return result, multiplier
    
    def __truediv__(self, other):
        """Divide two units (unit1 / unit2)"""
        if not isinstance(other, SIUnit):
            raise TypeError(f"Cannot divide SIUnit by {type(other)}")
        
        cdef SIUnit other_unit = other
        cdef double multiplier = 1.0
        
        cdef SIUnitRef c_result = SIUnitByDividing(
            self._c_unit, other_unit._c_unit, &multiplier
        )
        
        if c_result == NULL:
            raise ValueError("Failed to divide units")
        
        result = SIUnit._from_c_unit(c_result, True)  # ByDividing creates a new object
        return result, multiplier
    
    def __pow__(self, power):
        """Raise unit to a power (unit ** power)"""
        if not isinstance(power, (int, float)):
            raise TypeError(f"Cannot raise SIUnit to power of type {type(power)}")
        
        cdef double multiplier = 1.0
        cdef OCStringRef error = NULL
        
        cdef SIUnitRef c_result = SIUnitByRaisingToPower(
            self._c_unit, <double>power, &multiplier, &error
        )
        
        if c_result == NULL:
            error_msg = "Failed to raise unit to power"
            if error != NULL:
                error_msg = f"Failed to raise unit to power: {_ocstring_to_py(error)}"
            raise ValueError(error_msg)
        
        result = SIUnit._from_c_unit(c_result, True)  # ByRaisingToPower creates a new object
        return result, multiplier
    
    # Unit comparisons
    
    def __eq__(self, other):
        """Check if two units are exactly equal"""
        if not isinstance(other, SIUnit):
            return False
        
        cdef SIUnit other_unit = other
        return SIUnitEqual(self._c_unit, other_unit._c_unit)
    
    def is_equivalent(self, other):
        """Check if two units are dimensionally equivalent"""
        if not isinstance(other, SIUnit):
            return False
        
        cdef SIUnit other_unit = other
        return SIUnitAreEquivalentUnits(self._c_unit, other_unit._c_unit)
    
    def conversion_factor_to(self, other):
        """Get the conversion factor from this unit to another unit"""
        if not isinstance(other, SIUnit):
            raise TypeError(f"Cannot convert to {type(other)}")
        
        cdef SIUnit other_unit = other
        
        # Check if units are equivalent first
        if not self.is_equivalent(other_unit):
            raise ValueError(f"Cannot convert from {self.symbol} to {other_unit.symbol}: incompatible dimensions")
        
        return SIUnitConversion(self._c_unit, other_unit._c_unit)
    
    # String representation
    
    def __str__(self):
        """String representation showing the unit symbol"""
        return self.symbol
    
    def __repr__(self):
        """Detailed string representation"""
        return f"SIUnit(symbol='{self.symbol}', name='{self.name}', dimensionality={self.dimensionality})"
