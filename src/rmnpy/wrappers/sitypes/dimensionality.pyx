# cython: language_level=3
"""
RMNpy SIDimensionality Wrapper - Phase 2A Complete Implementation

Full-featured wrapper for SIDimensionality providing comprehensive dimensional analysis capabilities.
This implementation includes all essential methods for scientific computing applications.
"""

from rmnpy._c_api.octypes cimport (OCStringRef, OCRelease, OCStringCreateWithCString, 
                                   OCStringGetCString)
from rmnpy._c_api.sitypes cimport *
from rmnpy.exceptions import RMNError

from libc.stdint cimport uint64_t


cdef str _parse_c_string(uint64_t oc_string_ptr):
    """Helper to convert OCStringRef to Python string."""
    if oc_string_ptr == 0:
        return ""
    
    cdef OCStringRef oc_string = <OCStringRef>oc_string_ptr
    cdef const char* c_str = OCStringGetCString(oc_string)
    if c_str == NULL:
        return ""
    
    return c_str.decode('utf-8')


cdef class Dimensionality:
    """
    Python wrapper for SIDimensionality - represents a physical dimensionality.
    
    A dimensionality encodes the exponents of the seven SI base dimensions:
    - Length (L): meter [m]
    - Mass (M): kilogram [kg] 
    - Time (T): second [s]
    - Current (I): ampere [A]
    - Temperature (K): kelvin [K]
    - Amount (N): mole [mol]
    - Luminous Intensity (J): candela [cd]
    
    Examples:
        >>> # Create from expression
        >>> vel = Dimensionality("L/T")  # velocity
        >>> force = Dimensionality("M*L/T^2")  # force
        >>> 
        >>> # Test properties
        >>> vel.is_derived
        True
        >>> force.symbol
        'kg*m/s^2'
        >>> 
        >>> # Dimensional algebra
        >>> energy = force * Dimensionality("L")  # F*L = energy
        >>> energy.symbol
        'kg*m^2/s^2'
        >>> 
        >>> # Check compatibility
        >>> vel.is_compatible_with(Dimensionality("m/s"))
        True
        >>> 
        >>> # Legacy parse method still available
        >>> frequency = Dimensionality.parse("T^-1")
    """
    
    def __cinit__(self):
        """Initialize empty dimensionality wrapper."""
        self._dim_ref = NULL
    
    def __init__(self, expression=None):
        """
        Create a Dimensionality from a string expression.
        
        Args:
            expression (str, optional): Dimensional expression like "L^2*M/T^2" or "T^-1"
                If None, creates an empty dimensionality wrapper (for internal use)
            
        Examples:
            >>> velocity = Dimensionality("L/T")
            >>> energy = Dimensionality("M*L^2/T^2")
            >>> frequency = Dimensionality("T^-1")
        """
        if expression is None:
            # Empty constructor for internal use 
            return
            
        cdef bytes utf8_bytes = expression.encode('utf-8')
        cdef const char* c_string = utf8_bytes
        cdef OCStringRef expr_str = OCStringCreateWithCString(c_string)
        cdef OCStringRef error_str = NULL
        cdef SIDimensionalityRef dim_ref
        
        try:
            dim_ref = SIDimensionalityParseExpression(expr_str, &error_str)
            
            if error_str != NULL:
                error_msg = _parse_c_string(<uint64_t>error_str)
                OCRelease(error_str)
                raise RMNError(f"Failed to parse dimensionality expression '{expression}': {error_msg}")
            
            if dim_ref == NULL:
                raise RMNError(f"Failed to parse dimensionality expression '{expression}': Unknown error")
            
            # Store the C reference
            self._dim_ref = dim_ref
            
        finally:
            OCRelease(expr_str)
    
    @staticmethod
    def parse(expression):
        """
        Parse a dimensionality expression into a Dimensionality object.
        
        Args:
            expression (str): Dimensional expression like "L^2*M/T^2" or "T^-1"
            
        Returns:
            Dimensionality: Parsed dimensionality object
            
        Raises:
            RMNError: If expression cannot be parsed
            
        Examples:
            >>> d = Dimensionality.parse("M*L^2/T^2")  # energy
            >>> d.symbol
            'kg*m^2/s^2'
        """
        cdef bytes utf8_bytes = expression.encode('utf-8')
        cdef const char* c_string = utf8_bytes
        cdef OCStringRef expr_str = OCStringCreateWithCString(c_string)
        cdef OCStringRef error_str = NULL
        cdef SIDimensionalityRef dim_ref
        
        try:
            dim_ref = SIDimensionalityParseExpression(expr_str, &error_str)
            
            if error_str != NULL:
                error_msg = _parse_c_string(<uint64_t>error_str)
                OCRelease(error_str)
                raise RMNError(f"Failed to parse dimensionality expression '{expression}': {error_msg}")
            
            if dim_ref == NULL:
                raise RMNError(f"Failed to parse dimensionality expression '{expression}': Unknown error")
            
            return Dimensionality._from_ref(dim_ref)
            
        finally:
            OCRelease(expr_str)
    
    @staticmethod
    def for_quantity(quantity_constant):
        """
        Create dimensionality from a predefined physical quantity constant.
        
        Args:
            quantity_constant (OCStringRef): A quantity constant from the SITypes library.
                                           Must be one of the kSIQuantity* constants defined 
                                           in SIDimensionality.h, not a literal string.
            
        Returns:
            Dimensionality: Dimensionality for the quantity constant
            
        Raises:
            RMNError: If quantity constant is not recognized
            TypeError: If a string literal is passed instead of a constant
            
        Examples:
            >>> # Import quantity constants
            >>> from rmnpy.constants import kSIQuantityPressure, kSIQuantityEnergy
            >>> pressure_dim = Dimensionality.for_quantity(kSIQuantityPressure)
            >>> energy_dim = Dimensionality.for_quantity(kSIQuantityEnergy)
            >>> 
            >>> # This will raise TypeError:
            >>> # pressure_dim = Dimensionality.for_quantity("pressure")  # NOT allowed
        """
        cdef OCStringRef error_str = NULL
        
        # Reject string literals - only allow OCStringRef constants
        if isinstance(quantity_constant, str):
            raise TypeError(
                "String literals are not allowed. Use predefined quantity constants "
                "from the SITypes library (kSIQuantity* constants) instead of literal strings. "
                f"Got string: '{quantity_constant}'"
            )
        
        # Cast to OCStringRef - should be a predefined constant
        cdef OCStringRef quantity_str = <OCStringRef>quantity_constant
        cdef SIDimensionalityRef dim_ref
        
        try:
            dim_ref = SIDimensionalityForQuantity(quantity_str, &error_str)
            
            if error_str != NULL:
                error_msg = _parse_c_string(<uint64_t>error_str)
                OCRelease(error_str)
                raise RMNError(f"Unknown quantity constant: {error_msg}")
            
            if dim_ref == NULL:
                raise RMNError("Failed to create dimensionality for quantity constant")
            
            return Dimensionality._from_ref(dim_ref)
            
        except Exception as e:
            if "TypeError" in str(type(e)):
                raise
            raise RMNError(f"Invalid quantity constant: {e}")
    
    @staticmethod
    def dimensionless():
        """
        Create the canonical dimensionless dimensionality.
        
        Returns:
            Dimensionality: Dimensionless dimensionality (all exponents = 0)
            
        Examples:
            >>> d = Dimensionality.dimensionless()
            >>> d.is_dimensionless
            True
        """
        cdef SIDimensionalityRef dim_ref = SIDimensionalityDimensionless()
        return Dimensionality._from_ref(dim_ref)
    
    @staticmethod
    cdef Dimensionality _from_ref(SIDimensionalityRef dim_ref):
        """Create Dimensionality wrapper from C reference (internal use)."""
        cdef Dimensionality result = Dimensionality()
        result._dim_ref = dim_ref
        return result
    
    @property 
    def symbol(self):
        """
        Get the canonical symbol representation of this dimensionality.
        
        Returns:
            str: Symbol like "kg*m^2/s^2" or "m/s"
        """
        if self._dim_ref == NULL:
            return ""
        
        cdef OCStringRef symbol_str = SIDimensionalityGetSymbol(self._dim_ref)
        return _parse_c_string(<uint64_t>symbol_str)
    
    @property
    def is_dimensionless(self):
        """
        Check if this dimensionality is physically dimensionless.
        
        Returns:
            bool: True if all reduced exponents are zero
        """
        if self._dim_ref == NULL:
            return True
        
        return SIDimensionalityIsDimensionless(self._dim_ref)
    
    @property
    def is_derived(self):
        """
        Check if this dimensionality is derived (compound).
        
        Returns:
            bool: True if derived from multiple base dimensions
        """
        if self._dim_ref == NULL:
            return False
        
        return SIDimensionalityIsDerived(self._dim_ref)
    
    @property
    def is_base_dimensionality(self):
        """
        Check if this matches exactly one SI base dimension.
        
        Returns:
            bool: True if represents a single base dimension
        """
        if self._dim_ref == NULL:
            return False
        
        return SIDimensionalityIsBaseDimensionality(self._dim_ref)
    
    def is_equal(self, other):
        """
        Test strict equality with another dimensionality.
        
        Args:
            other (Dimensionality): Other dimensionality to compare
            
        Returns:
            bool: True if strictly equal (same rational exponents)
        """
        if not isinstance(other, Dimensionality):
            return False
        
        if self._dim_ref == NULL or (<Dimensionality>other)._dim_ref == NULL:
            return self._dim_ref == (<Dimensionality>other)._dim_ref
        
        return SIDimensionalityEqual(self._dim_ref, (<Dimensionality>other)._dim_ref)
    
    def is_compatible_with(self, other):
        """
        Test physical compatibility (same reduced dimensionality).
        
        Args:
            other (Dimensionality): Other dimensionality to check
            
        Returns:
            bool: True if physically compatible
        """
        if not isinstance(other, Dimensionality):
            return False
        
        if self._dim_ref == NULL or (<Dimensionality>other)._dim_ref == NULL:
            return self._dim_ref == (<Dimensionality>other)._dim_ref
        
        return SIDimensionalityHasSameReducedDimensionality(self._dim_ref, (<Dimensionality>other)._dim_ref)
    
    def multiply(self, other):
        """
        Multiply this dimensionality with another.
        
        Args:
            other (Dimensionality): Other dimensionality
            
        Returns:
            Dimensionality: Product dimensionality
            
        Raises:
            RMNError: If multiplication fails
        """
        if not isinstance(other, Dimensionality):
            raise TypeError("Can only multiply with another Dimensionality")
        
        if self._dim_ref == NULL or (<Dimensionality>other)._dim_ref == NULL:
            raise RMNError("Cannot multiply with NULL dimensionality")
        
        cdef OCStringRef error_str = NULL
        cdef SIDimensionalityRef result = SIDimensionalityByMultiplying(
            self._dim_ref, (<Dimensionality>other)._dim_ref, &error_str)
        
        if error_str != NULL:
            error_msg = _parse_c_string(<uint64_t>error_str)
            OCRelease(error_str)
            raise RMNError(f"Dimensionality multiplication failed: {error_msg}")
        
        if result == NULL:
            raise RMNError("Dimensionality multiplication failed")
        
        return Dimensionality._from_ref(result)
    
    def divide(self, other):
        """
        Divide this dimensionality by another.
        
        Args:
            other (Dimensionality): Divisor dimensionality
            
        Returns:
            Dimensionality: Quotient dimensionality
        """
        if not isinstance(other, Dimensionality):
            raise TypeError("Can only divide by another Dimensionality")
        
        if self._dim_ref == NULL or (<Dimensionality>other)._dim_ref == NULL:
            raise RMNError("Cannot divide with NULL dimensionality")
        
        cdef SIDimensionalityRef result = SIDimensionalityByDividing(
            self._dim_ref, (<Dimensionality>other)._dim_ref)
        
        if result == NULL:
            raise RMNError("Dimensionality division failed")
        
        return Dimensionality._from_ref(result)
    
    def power(self, exponent):
        """
        Raise this dimensionality to a power.
        
        Args:
            exponent (float): Exponent to raise to
            
        Returns:
            Dimensionality: Result of raising to power
            
        Raises:
            RMNError: If power operation fails
        """
        if self._dim_ref == NULL:
            raise RMNError("Cannot raise NULL dimensionality to power")
        
        cdef OCStringRef error_str = NULL
        cdef SIDimensionalityRef result = SIDimensionalityByRaisingToPower(
            self._dim_ref, float(exponent), &error_str)
        
        if error_str != NULL:
            error_msg = _parse_c_string(<uint64_t>error_str)
            OCRelease(error_str)
            raise RMNError(f"Dimensionality power operation failed: {error_msg}")
        
        if result == NULL:
            raise RMNError("Dimensionality power operation failed")
        
        return Dimensionality._from_ref(result)
    
    def nth_root(self, n):
        """
        Take the nth root of this dimensionality.
        
        Args:
            n (int): Root to take (must be positive)
            
        Returns:
            Dimensionality: nth root dimensionality
            
        Raises:
            RMNError: If root operation fails or is invalid
        """
        if n <= 0:
            raise ValueError(f"Root must be positive, got {n}")
        
        if self._dim_ref == NULL:
            raise RMNError("Cannot take root of NULL dimensionality")
        
        cdef OCStringRef error_str = NULL
        cdef SIDimensionalityRef result = SIDimensionalityByTakingNthRoot(
            self._dim_ref, n, &error_str)
        
        if error_str != NULL:
            error_msg = _parse_c_string(<uint64_t>error_str)
            OCRelease(error_str)
            raise RMNError(f"Dimensionality root operation failed: {error_msg}")
        
        if result == NULL:
            raise RMNError("Dimensionality root operation failed")
        
        return Dimensionality._from_ref(result)
    
    def reduced(self):
        """
        Get this dimensionality with all exponents reduced to lowest terms.
        
        Returns:
            Dimensionality: Reduced form dimensionality
        """
        if self._dim_ref == NULL:
            return Dimensionality.dimensionless()
        
        cdef SIDimensionalityRef result = SIDimensionalityByReducing(self._dim_ref)
        
        if result == NULL:
            raise RMNError("Dimensionality reduction failed")
        
        return Dimensionality._from_ref(result)
    
    def show(self):
        """Print concise representation to stdout."""
        if self._dim_ref != NULL:
            SIDimensionalityShow(self._dim_ref)
    
    def show_full(self):
        """Print detailed, annotated report to stdout."""
        if self._dim_ref != NULL:
            SIDimensionalityShowFull(self._dim_ref)
    
    def __str__(self):
        """String representation using symbol."""
        return self.symbol
    
    def __repr__(self):
        """Detailed string representation."""
        return f"Dimensionality('{self.symbol}')"
    
    def __eq__(self, other):
        """Equality comparison (strict)."""
        return self.is_equal(other)
    
    def __mul__(self, other):
        """Multiplication operator."""
        return self.multiply(other)
    
    def __truediv__(self, other):
        """Division operator."""
        return self.divide(other)
    
    def __pow__(self, exponent):
        """Power operator."""
        return self.power(exponent)
