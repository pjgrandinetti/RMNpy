"""
Tests for RMNpy SIScalar wrapper.

These tests verify the Python wrapper functionality for SITypes SIScalar objects,
including creation from expressions, value/unit handling, and error conditions.
"""

import pytest
import rmnpy
from rmnpy.exceptions import RMNLibValidationError, RMNLibMemoryError


class TestSIScalarCreation:
    """Test SIScalar creation methods."""
    
    def test_from_expression_basic(self):
        """Test basic expression parsing."""
        # Simple value with unit
        scalar = rmnpy.SIScalar.from_expression("1.0 Hz")
        assert scalar.value == 1.0
        
        # Different units
        scalar2 = rmnpy.SIScalar.from_expression("5.0 m")
        assert scalar2.value == 5.0
        
        scalar3 = rmnpy.SIScalar.from_expression("2.5 kg")
        assert scalar3.value == 2.5
    
    def test_from_expression_scientific_notation(self):
        """Test expression parsing with scientific notation."""
        scalar = rmnpy.SIScalar.from_expression("1.5e-3 m")
        assert abs(scalar.value - 0.0015) < 1e-10
        
        scalar2 = rmnpy.SIScalar.from_expression("2.4E6 Hz")
        assert abs(scalar2.value - 2400000.0) < 1e-6
    
    def test_from_expression_compound_units(self):
        """Test expression parsing with compound units."""
        # Acceleration
        scalar = rmnpy.SIScalar.from_expression("9.8 m/s^2")
        assert abs(scalar.value - 9.8) < 1e-10
        
        # Force
        scalar2 = rmnpy.SIScalar.from_expression("500 N")
        assert abs(scalar2.value - 500.0) < 1e-10
        
        # Energy
        scalar3 = rmnpy.SIScalar.from_expression("4.3 eV")
        # eV is a derived unit, so exact value will be converted to Joules
        assert scalar3.value > 0  # Should be positive energy in Joules
    
    def test_from_expression_mathematical_operations(self):
        """Test expression parsing with mathematical operations."""
        # Simple arithmetic
        scalar = rmnpy.SIScalar.from_expression("2^3")
        assert abs(scalar.value - 8.0) < 1e-10
        
        # Parentheses
        scalar2 = rmnpy.SIScalar.from_expression("(2+3)(4+1)")
        assert abs(scalar2.value - 25.0) < 1e-10
        
        # Square root
        scalar3 = rmnpy.SIScalar.from_expression("√(9) m")
        assert abs(scalar3.value - 3.0) < 1e-10
    
    def test_from_value_and_unit(self):
        """Test creation from separate value and unit."""
        scalar = rmnpy.SIScalar.from_value_and_unit(100.0, "MHz")
        assert abs(scalar.value - 100000000.0) < 1e-6  # Should be converted to Hz
        
        scalar2 = rmnpy.SIScalar.from_value_and_unit(2.5, "kg")
        assert abs(scalar2.value - 2.5) < 1e-10
        
        # Dimensionless (no unit)
        scalar3 = rmnpy.SIScalar.from_value_and_unit(42.0, None)
        assert abs(scalar3.value - 42.0) < 1e-10
    
    def test_from_expression_invalid_syntax(self):
        """Test error handling for invalid expressions."""
        with pytest.raises(RMNLibValidationError):
            rmnpy.SIScalar.from_expression("invalid syntax")
        
        with pytest.raises(RMNLibValidationError):
            rmnpy.SIScalar.from_expression("1.0 invalidunit")
        
        with pytest.raises(ValueError):
            rmnpy.SIScalar.from_expression(None)
    
    def test_from_value_and_unit_invalid_unit(self):
        """Test error handling for invalid units."""
        with pytest.raises(RMNLibValidationError):
            rmnpy.SIScalar.from_value_and_unit(1.0, "invalidunit")


class TestSIScalarProperties:
    """Test SIScalar properties and methods."""
    
    def test_value_property(self):
        """Test the value property returns correct numeric values."""
        test_cases = [
            ("1.0 Hz", 1.0),
            ("2.5 m", 2.5),
            ("0.001 kg", 0.001),
            ("1000 g", 1.0),  # Should be converted to kg (coherent SI unit)
        ]
        
        for expression, expected in test_cases:
            scalar = rmnpy.SIScalar.from_expression(expression)
            assert abs(scalar.value - expected) < 1e-10, f"Failed for {expression}"
    
    def test_string_representation(self):
        """Test string representation of SIScalar objects."""
        scalar = rmnpy.SIScalar.from_expression("1.0 Hz")
        str_repr = str(scalar)
        assert "SIScalar" in str_repr
        assert "1.0" in str_repr or "1" in str_repr
        
        repr_str = repr(scalar)
        assert "SIScalar" in repr_str


class TestSIScalarHelperFunctions:
    """Test the internal helper functions used by other modules."""
    
    def test_string_expression_conversion(self):
        """Test conversion of string expressions to SIScalarRef."""
        from rmnpy.siscalar import py_to_siscalar_ref, siscalar_ref_to_py
        
        # This tests the internal helper function used by dimension creation
        ref = py_to_siscalar_ref("1.0 Hz")
        assert ref is not None
        
        value = siscalar_ref_to_py(ref)
        assert abs(value - 1.0) < 1e-10
    
    def test_siscalar_object_conversion(self):
        """Test conversion of SIScalar objects to SIScalarRef."""
        from rmnpy.siscalar import py_to_siscalar_ref, siscalar_ref_to_py
        
        scalar = rmnpy.SIScalar.from_expression("2.5 m")
        ref = py_to_siscalar_ref(scalar)
        assert ref is not None
        
        value = siscalar_ref_to_py(ref)
        assert abs(value - 2.5) < 1e-10
    
    def test_numeric_value_conversion(self):
        """Test conversion of numeric values to dimensionless scalars."""
        from rmnpy.siscalar import py_to_siscalar_ref, siscalar_ref_to_py
        
        ref = py_to_siscalar_ref(42.0)
        assert ref is not None
        
        value = siscalar_ref_to_py(ref)
        assert abs(value - 42.0) < 1e-10
        
        # Test integer conversion
        ref2 = py_to_siscalar_ref(10)
        value2 = siscalar_ref_to_py(ref2)
        assert abs(value2 - 10.0) < 1e-10
    
    def test_invalid_type_conversion(self):
        """Test error handling for invalid types."""
        from rmnpy.siscalar import py_to_siscalar_ref
        
        with pytest.raises(TypeError):
            py_to_siscalar_ref([1, 2, 3])  # List not supported
        
        with pytest.raises(TypeError):
            py_to_siscalar_ref({"value": 1.0})  # Dict not supported


class TestSIScalarMemoryManagement:
    """Test proper memory management of SIScalar objects."""
    
    def test_object_lifecycle(self):
        """Test that SIScalar objects are properly created and destroyed."""
        # Create many scalars to test memory management
        scalars = []
        for i in range(100):
            scalar = rmnpy.SIScalar.from_expression(f"{i}.0 Hz")
            scalars.append(scalar)
            assert abs(scalar.value - float(i)) < 1e-10
        
        # Clear references - this should trigger cleanup
        scalars.clear()
        
        # Create more to verify no memory leaks
        for i in range(50):
            scalar = rmnpy.SIScalar.from_value_and_unit(i * 2.0, "m")
            assert abs(scalar.value - i * 2.0) < 1e-10
    
    def test_null_reference_handling(self):
        """Test handling of NULL references."""
        from rmnpy.siscalar import siscalar_ref_to_py, siscalar_ref_to_string
        
        # These should handle NULL gracefully
        value = siscalar_ref_to_py(None)
        assert value == 0.0
        
        string_repr = siscalar_ref_to_string(None)
        assert string_repr == "0.0"


class TestSIScalarIntegrationWithDimensions:
    """Test SIScalar integration with dimension creation (when implemented)."""
    
    def test_dimension_accepts_string_expressions(self):
        """Test that dimensions can accept string expressions (future integration)."""
        # This test verifies the interface that dimensions will use
        from rmnpy.siscalar import py_to_siscalar_ref
        
        # These should work for dimension creation
        increment_ref = py_to_siscalar_ref("1.0 Hz")
        offset_ref = py_to_siscalar_ref("0.0 Hz")
        
        assert increment_ref is not None
        assert offset_ref is not None
    
    def test_dimension_accepts_siscalar_objects(self):
        """Test that dimensions can accept SIScalar objects (future integration)."""
        from rmnpy.siscalar import py_to_siscalar_ref
        
        increment = rmnpy.SIScalar.from_expression("1.0 Hz")
        offset = rmnpy.SIScalar.from_value_and_unit(0.0, "Hz")
        
        increment_ref = py_to_siscalar_ref(increment)
        offset_ref = py_to_siscalar_ref(offset)
        
        assert increment_ref is not None
        assert offset_ref is not None


class TestSIScalarEdgeCases:
    """Test edge cases and boundary conditions."""
    
    def test_zero_values(self):
        """Test handling of zero values."""
        scalar = rmnpy.SIScalar.from_expression("0.0 m")
        assert scalar.value == 0.0
        
        scalar2 = rmnpy.SIScalar.from_value_and_unit(0.0, "Hz")
        assert scalar2.value == 0.0
    
    def test_very_large_values(self):
        """Test handling of very large values."""
        scalar = rmnpy.SIScalar.from_expression("1e20 m")
        assert scalar.value == 1e20
        
        scalar2 = rmnpy.SIScalar.from_value_and_unit(1e15, "Hz")
        assert scalar2.value == 1e15
    
    def test_very_small_values(self):
        """Test handling of very small values."""
        scalar = rmnpy.SIScalar.from_expression("1e-20 m")
        assert abs(scalar.value - 1e-20) < 1e-30
        
        scalar2 = rmnpy.SIScalar.from_value_and_unit(1e-15, "s")
        assert abs(scalar2.value - 1e-15) < 1e-25
    
    def test_negative_values(self):
        """Test handling of negative values."""
        scalar = rmnpy.SIScalar.from_expression("-5.0 m")
        assert scalar.value == -5.0
        
        scalar2 = rmnpy.SIScalar.from_value_and_unit(-10.0, "kg")
        assert scalar2.value == -10.0
    
    def test_unicode_symbols(self):
        """Test handling of Unicode mathematical symbols."""
        # Test various Unicode mathematical operators supported by SITypes
        scalar = rmnpy.SIScalar.from_expression("−5 m")  # Unicode minus
        assert scalar.value == -5.0
        
        scalar2 = rmnpy.SIScalar.from_expression("6×2 kg")  # Unicode multiplication
        assert abs(scalar2.value - 12.0) < 1e-10
        
        scalar3 = rmnpy.SIScalar.from_expression("12 ÷ 4 m")  # Unicode division
        assert abs(scalar3.value - 3.0) < 1e-10


if __name__ == "__main__":
    # Run tests if executed directly
    pytest.main([__file__, "-v"])
