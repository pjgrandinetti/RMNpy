# cython: language_level=3
"""
RMNpy SIUnit Wrapper - Phase 2B Implementation

Complete wrapper for SIUnit providing comprehensive unit manipulation capabilities.
This implementation builds on the SIDimensionality foundation from Phase 2A.
"""

from rmnpy._c_api.octypes cimport (OCStringRef, OCRelease, OCStringCreateWithCString, 
                                   OCStringGetCString, OCTypeRef)
from rmnpy._c_api.sitypes cimport *
from rmnpy.exceptions import RMNError
from rmnpy.wrappers.sitypes.dimensionality cimport Dimensionality
from rmnpy.helpers.octypes import parse_c_string

from libc.stdint cimport uint64_t, uintptr_t


cdef class Unit:
    """
    Python wrapper for SIUnit - represents a physical unit.
    
    A unit combines a dimensionality with scale factors, prefixes, and symbols.
    Units support full algebraic operations with automatic dimensional validation.
    
    Examples:
        >>> # Create from expression
        >>> meter, mult1 = Unit.parse("m")  # meter
        >>> second, mult2 = Unit.parse("s")  # second
        >>> velocity_unit = meter / second  # m/s
        >>> 
        >>> # Test properties
        >>> velocity_unit.symbol
        'm/s'
        >>> velocity_unit.dimensionality.symbol
        'L/T'
        >>> 
        >>> # Unit operations
        >>> area_unit = meter * meter  # m^2
        >>> volume_unit = area_unit * meter  # m^3
        >>> 
        >>> # Parse with multiplier (usually 1.0)
        >>> km_unit, km_mult = Unit.parse("km")  # kilometer
        >>> km_unit.symbol  # "km"
        >>> km_mult  # 1.0 (standard unit)
        >>> 
        >>> # Compound units also typically return 1.0
        >>> vel_unit, vel_mult = Unit.parse("m/s")
        >>> vel_unit.symbol  # "m/s"
        >>> vel_mult  # 1.0
    """
    
    cdef SIUnitRef _c_unit
    
    def __cinit__(self):
        self._c_unit = NULL
    
    def __dealloc__(self):
        if self._c_unit != NULL:
            OCRelease(<OCTypeRef>self._c_unit)
    
    @staticmethod
    cdef Unit _from_ref(SIUnitRef unit_ref):
        """Create Unit wrapper from C reference (internal use)."""
        cdef Unit result = Unit()
        result._c_unit = unit_ref
        return result
    
    @classmethod
    def parse(cls, expression):
        """
        Parse a unit from string expression.
        
        Args:
            expression (str): Unit expression (e.g., "m/s", "kg*m/s^2")
            
        Returns:
            tuple: (Unit, float) - Parsed unit object and multiplier
            
        Raises:
            RMNError: If parsing fails
            
        Examples:
            >>> # Standard units return multiplier = 1.0
            >>> unit, multiplier = Unit.parse("km")  # kilometer
            >>> unit.symbol  # "km" (actual kilometer unit)
            >>> multiplier   # 1.0 (no scaling needed)
            >>> 
            >>> # Most expressions also return multiplier = 1.0
            >>> unit, multiplier = Unit.parse("m/s")  # meter per second
            >>> unit.symbol  # "m/s"
            >>> multiplier   # 1.0 (standard compound unit)
        """
        if not isinstance(expression, str):
            raise TypeError("Expression must be a string")
        
        cdef bytes expr_bytes = expression.encode('utf-8')
        cdef OCStringRef expr_string = OCStringCreateWithCString(expr_bytes)
        cdef OCStringRef error_string = <OCStringRef>0
        cdef double unit_multiplier = 1.0
        cdef SIUnitRef c_unit
        
        try:
            c_unit = SIUnitFromExpression(expr_string, &unit_multiplier, &error_string)
            
            if c_unit == NULL:
                if error_string != NULL:
                    error_msg = parse_c_string(<uint64_t>error_string)
                    raise RMNError(f"Failed to parse unit expression '{expression}': {error_msg}")
                else:
                    raise RMNError(f"Failed to parse unit expression '{expression}': Unknown error")
            
            # Create Python wrapper using _from_ref and return both unit and multiplier
            return Unit._from_ref(c_unit), unit_multiplier
        finally:
            OCRelease(<OCTypeRef>expr_string)
            if error_string != <OCStringRef>0:
                OCRelease(<OCTypeRef>error_string)
    
    @classmethod  
    def from_name(cls, name):
        """
        Find a unit by its name.
        
        Args:
            name (str): Unit name (e.g., "meter", "second", "kilogram")
            
        Returns:
            Unit: Unit with the given name, or None if not found
        """
        if not isinstance(name, str):
            raise TypeError("Name must be a string")
        
        cdef bytes name_bytes = name.encode('utf-8')
        cdef OCStringRef name_string = OCStringCreateWithCString(name_bytes)
        cdef SIUnitRef c_unit
        
        try:
            c_unit = SIUnitFindWithName(name_string)
            
            if c_unit == NULL:
                return None
            
            # Create Python wrapper using _from_ref
            return Unit._from_ref(c_unit)
            
        finally:
            OCRelease(<OCTypeRef>name_string)
    
    @classmethod
    def from_symbol(cls, symbol):
        """
        Find a unit by its symbol.
        
        Args:
            symbol (str): Unit symbol (e.g., "m", "s", "kg")
            
        Returns:
            Unit: Unit with the given symbol, or None if not found
        """
        if not isinstance(symbol, str):
            raise TypeError("Symbol must be a string")
        
        cdef bytes symbol_bytes = symbol.encode('utf-8')
        cdef OCStringRef symbol_string = OCStringCreateWithCString(symbol_bytes)
        cdef SIUnitRef c_unit
        
        try:
            c_unit = SIUnitFindWithUnderivedSymbol(symbol_string)
            
            if c_unit == NULL:
                return None
            
            # Create Python wrapper using _from_ref
            return Unit._from_ref(c_unit)
            
        finally:
            OCRelease(<OCTypeRef>symbol_string)
    
    @classmethod
    def dimensionless(cls):
        """
        Create the dimensionless unit (1).
        
        Returns:
            Unit: Dimensionless unit
        """
        cdef SIUnitRef c_unit = SIUnitDimensionlessAndUnderived()
        
        return Unit._from_ref(c_unit)
    
    @classmethod
    def for_dimensionality(cls, dimensionality):
        """
        Find the coherent SI unit for a given dimensionality.
        
        Args:
            dimensionality (Dimensionality): Target dimensionality
            
        Returns:
            Unit: Coherent SI unit with that dimensionality
        """
        if not isinstance(dimensionality, Dimensionality):
            raise TypeError("Expected Dimensionality object")
        
        # Access the _dim_ref attribute using the proper cdef approach
        cdef Dimensionality dim_obj = <Dimensionality>dimensionality
        cdef SIDimensionalityRef dim_ref = dim_obj._dim_ref
        cdef SIUnitRef c_unit = SIUnitFindCoherentSIUnitWithDimensionality(dim_ref)
        
        if c_unit == NULL:
            return None
        
        return Unit._from_ref(c_unit)
    
    # Properties
    @property
    def symbol(self):
        """Get the unit symbol (e.g., 'm/s')."""
        if self._c_unit == NULL:
            return ""
        
        cdef OCStringRef symbol_string = SIUnitCopySymbol(self._c_unit)
        if symbol_string == NULL:
            return ""
        
        try:
            return parse_c_string(<uint64_t>symbol_string)
        finally:
            OCRelease(<OCTypeRef>symbol_string)
    
    @property
    def name(self):
        """Get the unit name (e.g., 'meter per second')."""
        if self._c_unit == NULL:
            return ""
        
        cdef OCStringRef name_string = SIUnitCopyRootName(self._c_unit)
        if name_string == NULL:
            return ""
        
        try:
            return parse_c_string(<uint64_t>name_string)
        finally:
            OCRelease(<OCTypeRef>name_string)
    
    @property
    def plural_name(self):
        """Get the plural unit name (e.g., 'meters per second')."""
        if self._c_unit == NULL:
            return ""
        
        cdef OCStringRef plural_string = SIUnitCopyRootPluralName(self._c_unit)
        if plural_string == NULL:
            return ""
        
        try:
            return parse_c_string(<uint64_t>plural_string)
        finally:
            OCRelease(<OCTypeRef>plural_string)
    
    @property
    def dimensionality(self):
        """Get the dimensionality of this unit."""
        if self._c_unit == <SIUnitRef>0:
            return None
        
        cdef SIDimensionalityRef c_dim = SIUnitGetDimensionality(self._c_unit)
        if c_dim == <SIDimensionalityRef>0:
            return None
        
        # Create Dimensionality wrapper using the proper _from_ref pattern
        # Note: SIUnitGetDimensionality does not transfer ownership, so we don't need to manage memory
        return Dimensionality._from_ref(c_dim)
    
    @property
    def scale_factor(self):
        """Get the scale factor relative to the SI base unit."""
        if self._c_unit == NULL:
            return 1.0
        
        return SIUnitGetScaleNonSIToCoherentSI(self._c_unit)
    
    @property
    def is_dimensionless(self):
        """Check if this unit is dimensionless."""
        if self._c_unit == <SIUnitRef>0:
            return False
        
        return SIUnitIsDimensionless(self._c_unit)
    
    @property
    def is_derived(self):
        """Check if this is a derived unit."""
        if self._c_unit == NULL:
            return False
        
        return SIUnitIsCoherentDerivedUnit(self._c_unit)
    
    @property
    def is_si_base_unit(self):
        """Check if this unit is an SI base unit."""
        if self._c_unit == <SIUnitRef>0:
            return False
        
        return SIUnitIsSIBaseUnit(self._c_unit)
    
    @property
    def is_coherent_si(self):
        """Check if this is a coherent SI unit."""
        if self._c_unit == NULL:
            return False
        
        # Use base unit check as approximation for coherent SI
        return SIUnitIsSIBaseUnit(self._c_unit)
    
    # Algebraic operations
    def multiply(self, other):
        """
        Multiply this unit by another unit.
        
        Args:
            other (Unit): Unit to multiply by
            
        Returns:
            Unit: Product unit
        """
        if not isinstance(other, Unit):
            raise TypeError("Can only multiply with another Unit")
        
        cdef double unit_multiplier = 1.0
        cdef OCStringRef error_string = NULL
        
        cdef SIUnitRef result = SIUnitByMultiplying(self._c_unit, (<Unit>other)._c_unit, 
                                                   &unit_multiplier, &error_string)
        
        if result == NULL:
            error_msg = "Unknown error"
            if error_string != NULL:
                error_msg = parse_c_string(<uint64_t>error_string)
                OCRelease(<OCTypeRef>error_string)
            raise RMNError(f"Unit multiplication failed: {error_msg}")
        
        # Create wrapper for result using _from_ref
        return Unit._from_ref(result)
    
    def divide(self, other):
        """
        Divide this unit by another unit.
        
        Args:
            other (Unit): Unit to divide by
            
        Returns:
            Unit: Quotient unit
        """
        if not isinstance(other, Unit):
            raise TypeError("Can only divide by another Unit")
        
        cdef double unit_multiplier = 1.0
        
        cdef SIUnitRef result = SIUnitByDividing(self._c_unit, (<Unit>other)._c_unit, &unit_multiplier)
        
        if result == NULL:
            raise RMNError("Unit division failed")
        
        # Create wrapper for result using _from_ref
        return Unit._from_ref(result)
    
    def power(self, exponent):
        """
        Raise this unit to a power.
        
        Args:
            exponent (float): Power to raise to
            
        Returns:
            Unit: Unit raised to the power
        """
        if not isinstance(exponent, (int, float)):
            raise TypeError("Exponent must be a number")
        
        cdef double power = float(exponent)
        cdef double unit_multiplier = 1.0
        cdef OCStringRef error_string = NULL
        
        cdef SIUnitRef result = SIUnitByRaisingToPower(self._c_unit, power, 
                                                      &unit_multiplier, &error_string)
        
        if result == NULL:
            error_msg = "Unknown error"
            if error_string != NULL:
                error_msg = parse_c_string(<uint64_t>error_string)
                OCRelease(<OCTypeRef>error_string)
            raise RMNError(f"Unit power operation failed: {error_msg}")
        
        # Create wrapper for result using _from_ref
        return Unit._from_ref(result)
    
    def nth_root(self, root):
        """
        Take the nth root of this unit.
        
        Args:
            root (int): Root to take (e.g., 2 for square root)
            
        Returns:
            Unit: nth root of the unit
        """
        if not isinstance(root, int) or root <= 0:
            raise ValueError("Root must be a positive integer")
        
        cdef uint8_t c_root = <uint8_t>root
        cdef double unit_multiplier = 1.0
        cdef OCStringRef error_string = NULL
        
        cdef SIUnitRef result = SIUnitByTakingNthRoot(self._c_unit, c_root, 
                                                     &unit_multiplier, &error_string)
        
        if result == NULL:
            error_msg = "Unknown error"
            if error_string != NULL:
                error_msg = parse_c_string(<uint64_t>error_string)
                OCRelease(<OCTypeRef>error_string)
            raise RMNError(f"Unit root operation failed: {error_msg}")
        
        # Create wrapper for result using _from_ref
        return Unit._from_ref(result)
    
    # Comparison methods
    def is_equal(self, other):
        """
        Check if this unit is exactly equal to another unit.
        
        Args:
            other (Unit): Unit to compare with
            
        Returns:
            bool: True if units are equal
        """
        if not isinstance(other, Unit):
            return False
        
        return SIUnitEqual(self._c_unit, (<Unit>other)._c_unit)
    
    def is_dimensionally_equal(self, other):
        """
        Check if this unit has the same dimensionality as another unit.
        
        Args:
            other (Unit): Unit to compare with
            
        Returns:
            bool: True if units have same dimensionality
        """
        if not isinstance(other, Unit):
            return False
        
        # Compare dimensionalities rather than units directly
        self_dim = self.dimensionality
        other_dim = other.dimensionality
        return self_dim.is_equal(other_dim)
    
    def is_compatible_with(self, other):
        """
        Check if this unit is compatible (convertible) with another unit.
        This is an alias for is_dimensionally_equal.
        
        Args:
            other (Unit): Unit to check compatibility with
            
        Returns:
            bool: True if units are compatible
        """
        return self.is_dimensionally_equal(other)
    
    # Python operator overloading
    def __mul__(self, other):
        """Multiplication operator (*)."""
        return self.multiply(other)
    
    def __truediv__(self, other):
        """Division operator (/)."""
        return self.divide(other)
    
    def __pow__(self, exponent):
        """Power operator (**)."""
        return self.power(exponent)
    
    def __eq__(self, other):
        """Equality operator (==)."""
        return self.is_equal(other)
    
    def __ne__(self, other):
        """Inequality operator (!=)."""
        return not self.is_equal(other)
    
    # String representation
    def __str__(self):
        """Return the unit symbol."""
        return self.symbol
    
    def __repr__(self):
        """Return a detailed string representation."""
        return f"Unit('{self.symbol}')"
    
    # Display methods
    def show(self):
        """Display unit information to stdout."""
        if self._c_unit != <SIUnitRef>0:
            SIUnitShow(self._c_unit)
