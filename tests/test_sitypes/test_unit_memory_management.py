"""
Test Unit memory management and error handling

This test module specifically focuses on memory management in the Unit wrapper,
particularly around fractional powers and error conditions that might cause
memory leaks in the underlying C library.
"""

import pytest

from rmnpy.exceptions import RMNError
from rmnpy.wrappers.sitypes import Unit


class TestUnitMemoryManagement:
    """Test memory management in unit operations."""

    def test_fractional_power_valid_roots(self):
        """Test valid fractional powers (integer roots)."""
        # Test square root (power = 0.5 = 1/2)
        area = Unit("m^2")
        length = area ** 0.5
        assert "m" in str(length)
        
        # Test cube root (power = 1/3)
        volume = Unit("m^3")
        length2 = volume ** (1.0/3.0)
        assert "m" in str(length2)

    def test_fractional_power_invalid_powers(self):
        """Test invalid fractional powers raise errors without leaking memory."""
        meter = Unit("m")
        
        # Test various invalid fractional powers
        invalid_powers = [0.3, 0.7, 1.5, 2.3, -0.5, -1.5]
        
        for power in invalid_powers:
            with pytest.raises(RMNError) as exc_info:
                _ = meter ** power
            assert "Cannot raise unit to fractional power" in str(exc_info.value)

    def test_multiple_fractional_operations(self):
        """Test multiple fractional operations to stress test memory management."""
        # Perform many operations to test for memory leaks
        base_unit = Unit("m^4")
        
        for i in range(10):
            # Valid operations
            sqrt_unit = base_unit ** 0.5  # m^2
            sqrt_sqrt = sqrt_unit ** 0.5  # m
            
            # Invalid operations (should not leak memory)
            try:
                _ = base_unit ** 0.3
            except RMNError:
                pass  # Expected
                
            try:
                _ = sqrt_unit ** 1.7
            except RMNError:
                pass  # Expected

    def test_power_operation_error_handling(self):
        """Test error handling in power operations."""
        meter = Unit("m")
        
        # Test with non-numeric exponent
        with pytest.raises(TypeError):
            _ = meter ** "invalid"
            
        with pytest.raises(TypeError):
            _ = meter ** None

    def test_arithmetic_error_handling(self):
        """Test error handling in arithmetic operations."""
        meter = Unit("m")
        second = Unit("s")
        
        # These should work
        velocity = meter / second
        assert velocity is not None
        
        area = meter * meter
        assert area is not None
        
        # Test with invalid operands
        with pytest.raises(TypeError):
            _ = meter * "invalid"
            
        with pytest.raises(TypeError):
            _ = meter / 5

    def test_root_operations(self):
        """Test nth root operations."""
        # Create units that support root operations
        area = Unit("m^2")
        volume = Unit("m^3")
        
        # Test square root
        length1 = area.nth_root(2)
        assert "m" in str(length1)
        
        # Test cube root
        length2 = volume.nth_root(3)
        assert "m" in str(length2)
        
        # Test invalid root values
        with pytest.raises((ValueError, TypeError)):
            area.nth_root(0)
            
        with pytest.raises((ValueError, TypeError)):
            area.nth_root(-1)
            
        with pytest.raises(TypeError):
            area.nth_root("invalid")

    def test_unit_reduction_error_handling(self):
        """Test error handling in unit reduction."""
        meter = Unit("m")
        
        # This should work
        reduced = meter.reduced()
        assert reduced is not None
        
        # Test coherent SI conversion
        coherent = meter.to_coherent_si()
        assert coherent is not None

    def test_string_operations_memory(self):
        """Test string operations don't leak memory."""
        units = ["m", "s", "kg", "m/s", "m^2", "kg*m/s^2"]
        
        for unit_str in units:
            unit = Unit(unit_str)
            
            # Access properties multiple times
            for _ in range(5):
                _ = str(unit)
                _ = unit.symbol
                _ = unit.name
                _ = unit.plural_name
                _ = unit.is_dimensionless
                _ = unit.is_derived

    def test_unit_creation_error_handling(self):
        """Test error handling during unit creation."""
        # Test empty string
        with pytest.raises(RMNError):
            Unit("")
            
        # Test invalid expressions
        invalid_expressions = ["xyz", "m/", "/s", "m^", "^2"]
        
        for expr in invalid_expressions:
            with pytest.raises(RMNError):
                Unit(expr)

    def test_comparison_operations(self):
        """Test comparison operations for memory safety."""
        meter1 = Unit("m")
        meter2 = Unit("m")
        second = Unit("s")
        
        # These operations should be memory safe
        assert meter1 == meter2
        assert meter1 != second
        
        # Test equivalence
        if hasattr(meter1, 'is_equivalent'):
            assert meter1.is_equivalent(meter2)
            assert not meter1.is_equivalent(second)
        
        # Test compatibility
        if hasattr(meter1, 'is_compatible_with'):
            assert meter1.is_compatible_with(meter2)
            assert not meter1.is_compatible_with(second)