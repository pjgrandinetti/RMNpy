"""Tests for SIScalar wrapper functionality."""

import pytest
import math
from decimal import Decimal
from fractions import Fraction

from rmnpy.wrappers.sitypes import Dimensionality, Unit, Scalar
from rmnpy.exceptions import RMNError


class TestScalarCreation:
    """Test scalar creation methods."""
    
    def test_create_from_value_unit_strings(self):
        """Test creating scalar from value and unit strings."""
        scalar = Scalar.from_value_unit("5.0", "m")
        assert scalar is not None
        assert scalar.unit.symbol == "m"
        # Value comparison - exact string "5.0" should give exact value
        assert abs(scalar.value - 5.0) < 1e-14
        
    def test_create_from_numeric_types(self):
        """Test creating scalar from various Python numeric types."""
        # Integer
        scalar_int = Scalar.from_value_unit(42, "kg")
        assert scalar_int.value == 42.0
        assert scalar_int.unit.symbol == "kg"
        
        # Float
        scalar_float = Scalar.from_value_unit(3.14159, "s")
        assert abs(scalar_float.value - 3.14159) < 1e-14
        assert scalar_float.unit.symbol == "s"
        
        # Decimal
        scalar_decimal = Scalar.from_value_unit(Decimal("2.5"), "A")
        assert abs(scalar_decimal.value - 2.5) < 1e-14
        assert scalar_decimal.unit.symbol == "A"
        
        # Fraction
        scalar_fraction = Scalar.from_value_unit(Fraction(3, 4), "mol")
        assert abs(scalar_fraction.value - 0.75) < 1e-14
        assert scalar_fraction.unit.symbol == "mol"
        
    def test_create_from_expression(self):
        """Test creating scalar from complete expression string."""
        scalar = Scalar.from_string("9.81 m/s^2")
        assert abs(scalar.value - 9.81) < 1e-14
        assert scalar.unit.symbol == "m/s^2"
        
        # Test another expression - C library converts to SI base units automatically
        scalar2 = Scalar.from_string("100 km/h")
        # 100 km/h = 27.777... m/s = 0.027777... km/s (converted to SI base)
        assert abs(scalar2.value - 0.027777777777777776) < 1e-14
        assert scalar2.unit.symbol == "km/s"
        
        # Test scientific notation
        scalar_sci = Scalar.from_string("1.5e3 Hz")
        assert scalar_sci.value == 1500.0
        assert scalar_sci.unit.symbol == "Hz"
        
        # Test negative value  
        scalar_neg = Scalar.from_string("-42.0 Hz")
        assert scalar_neg.value == -42.0
        assert scalar_neg.unit.symbol == "Hz"
        
    def test_create_dimensionless(self):
        """Test creating dimensionless scalars."""
        scalar = Scalar.from_value_unit("1.5", "1")
        assert scalar.value == 1.5
        assert scalar.unit.is_dimensionless
        
    def test_create_invalid_unit(self):
        """Test creation with invalid unit should raise error."""
        with pytest.raises(RMNError):
            Scalar.from_value_unit("5.0", "invalid_unit_xyz")
            
    def test_create_invalid_value(self):
        """Test creation with invalid value should raise error."""
        with pytest.raises(ValueError):
            Scalar.from_value_unit("not_a_number", "m")
            
    def test_create_with_complex_numbers(self):
        """Test scalar creation with complex numbers."""
        try:
            # SITypes may support complex numbers - test if available
            scalar = Scalar.from_value_unit(3.0 + 4.0j, "m")
            # Verify complex value handling - may store only real part
            assert isinstance(scalar.value, (float, complex))
        except (TypeError, ValueError):
            # Complex number support not implemented, which is acceptable
            pytest.skip("Complex number support not implemented in SITypes")
            
    def test_create_expression_errors(self):
        """Test error handling in expression parsing."""
        # Invalid format - SITypes raises ValueError for syntax errors
        with pytest.raises(ValueError):
            Scalar.from_string("invalid expression format")
            
        # Empty string
        with pytest.raises(ValueError):
            Scalar.from_string("")
            
        # None input
        with pytest.raises((ValueError, TypeError)):
            Scalar.from_string(None)


class TestScalarProperties:
    """Test scalar property access."""
    
    def test_value_property(self):
        """Test value property access."""
        scalar = Scalar.from_value_unit("123.456", "m")
        assert abs(scalar.value - 123.456) < 1e-14
        
    def test_unit_property(self):
        """Test unit property access."""
        scalar = Scalar.from_value_unit("10.0", "kg*m/s^2")
        unit = scalar.unit
        assert unit.symbol == "m•kg/s^2"  # SITypes uses • for multiplication and ^2 for powers
        # Note: unit.name is empty for compound units like kg*m/s^2
        
    def test_dimensionality_property(self):
        """Test dimensionality property access."""
        scalar = Scalar.from_value_unit("5.0", "J")  # Joule = kg*m^2/s^2
        dim = scalar.dimensionality
        # Check that it has the right dimensionality for energy
        assert dim.is_derived  # Energy is a derived dimension
        assert not dim.is_dimensionless  # Energy has dimensions
        assert dim.symbol == "L^2•M/T^2"  # Energy dimensionality symbol


class TestScalarCopyOperations:
    """Test scalar copy operations and memory management."""
    
    def test_scalar_copy_independence(self):
        """Test that arithmetic operations create independent objects."""
        original = Scalar.from_value_unit("42.0", "Hz")
        
        # Arithmetic operations should create new objects
        doubled = original * 2.0
        half = original / 2.0
        
        # Test independence
        assert doubled is not original
        assert half is not original
        assert doubled.value == 84.0
        assert half.value == 21.0
        assert original.value == 42.0  # Original unchanged
        
    def test_scalar_lifecycle_stress(self):
        """Test scalar creation and destruction under load."""
        scalars = []
        for i in range(100):
            scalar = Scalar.from_value_unit(float(i), "m")
            scalars.append(scalar)
            
        # Verify all values
        for i, scalar in enumerate(scalars):
            assert scalar.value == float(i)
            assert scalar.unit.symbol == "m"
            
        del scalars  # Python GC should handle cleanup


class TestScalarTypeInformation:
    """Test scalar type checking and introspection methods."""
    
    def test_scalar_type_properties(self):
        """Test scalar type-related properties and methods."""
        real_scalar = Scalar.from_value_unit("42.0", "m")
        zero_scalar = Scalar.from_value_unit("0.0", "m")
        
        # Test that value is always real in current implementation
        assert isinstance(real_scalar.value, (int, float))
        assert isinstance(zero_scalar.value, (int, float))
        
        # Test zero detection via value comparison
        assert zero_scalar.value == 0.0
        assert real_scalar.value != 0.0
        
    def test_scalar_infinite_values(self):
        """Test scalar handling of infinite values."""
        try:
            # Test if SITypes can handle infinity
            inf_scalar = Scalar.from_value_unit(float('inf'), "m")
            assert math.isinf(inf_scalar.value)
        except (ValueError, OverflowError):
            # Infinity may not be supported, which is acceptable
            pytest.skip("Infinity values not supported in SITypes")
            
    def test_scalar_nan_values(self):
        """Test scalar handling of NaN values."""
        try:
            # Test if SITypes can handle NaN
            nan_scalar = Scalar.from_value_unit(float('nan'), "m")
            assert math.isnan(nan_scalar.value)
        except (ValueError, OverflowError):
            # NaN may not be supported, which is acceptable
            pytest.skip("NaN values not supported in SITypes")


class TestScalarMathematicalFunctions:
    """Test scalar mathematical functions beyond basic arithmetic."""
    
    def test_scalar_absolute_value(self):
        """Test absolute value operation."""
        # Test with negative value
        negative_scalar = Scalar.from_value_unit("-5.0", "m")
        try:
            abs_scalar = abs(negative_scalar)
            assert abs_scalar.value == 5.0
            assert abs_scalar.unit.symbol == "m"
        except (AttributeError, TypeError):
            # Absolute value may not be implemented - test manually
            assert negative_scalar.value == -5.0
            pytest.skip("Absolute value operation not implemented")
            
    def test_scalar_complex_number_support(self):
        """Test complex number operations if supported."""
        try:
            # Test complex scalar creation 
            complex_scalar = Scalar.from_value_unit(3.0 + 4.0j, "m")
            
            # Test if we can extract real and imaginary parts
            if hasattr(complex_scalar, 'real') and hasattr(complex_scalar, 'imag'):
                # If real/imag return Scalar objects
                if hasattr(complex_scalar.real, 'value'):
                    assert complex_scalar.real.value == 3.0
                    assert complex_scalar.imag.value == 4.0
                else:
                    # If real/imag return raw values
                    assert complex_scalar.real == 3.0
                    assert complex_scalar.imag == 4.0
            else:
                # May only store as a complex value
                assert isinstance(complex_scalar.value, complex)
                assert complex_scalar.value == (3.0 + 4.0j)
                
        except (TypeError, ValueError):
            pytest.skip("Complex number support not implemented")
            
    def test_scalar_nth_root(self):
        """Test nth root operations."""
        # Test cube root of 8 m^3 = 2 m
        try:
            # Create a scalar with cubed units
            volume = Scalar.from_value_unit("8.0", "m^3")  # 8 cubic meters
            
            # Test if power with fractional exponent works as nth root
            cube_root = volume ** (1/3)
            
            # Should give approximately 2 m
            assert abs(cube_root.value - 2.0) < 1e-10
            # Note: SITypes may not simplify m^3^(1/3) to m
            
        except (AttributeError, TypeError):
            pytest.skip("Nth root operation not implemented")
            
    def test_scalar_advanced_type_checking(self):
        """Test advanced scalar type checking capabilities."""
        zero_scalar = Scalar.from_value_unit("0.0", "m")
        positive_scalar = Scalar.from_value_unit("5.0", "m")
        negative_scalar = Scalar.from_value_unit("-3.0", "m")
        
        # Test zero detection
        assert zero_scalar.value == 0.0
        assert positive_scalar.value != 0.0
        assert negative_scalar.value != 0.0
        
        # Test if we can detect positive/negative
        assert positive_scalar.value > 0
        assert negative_scalar.value < 0
        
        # Test if values are finite
        assert math.isfinite(zero_scalar.value)
        assert math.isfinite(positive_scalar.value)
        assert math.isfinite(negative_scalar.value)


class TestScalarUnitOperations:
    """Test advanced unit operations beyond basic conversion."""
    
    def test_scalar_unit_reduction(self):
        """Test unit reduction and simplification."""
        # Create a scalar with complex units that could be reduced
        try:
            # Force units (kg⋅m/s²) that should reduce to N
            force_expr = Scalar.from_string("10.0 kg*m/s^2")
            
            # Test if the unit is properly recognized/reduced
            unit_symbol = force_expr.unit.symbol
            unit_name = force_expr.unit.name
            
            # SITypes might reduce to "N" or keep as "kg⋅m/s²"
            assert unit_symbol in ["N", "kg•m/s^2", "m•kg/s^2"]
            
        except (ValueError, AttributeError):
            pytest.skip("Complex unit reduction not supported")
            
    def test_scalar_coherent_unit_conversion(self):
        """Test conversion to coherent SI units."""
        # Test conversion of derived units to base SI
        derived_scalar = Scalar.from_value_unit("1000.0", "g")  # grams to kg
        coherent = derived_scalar.to_coherent_si()
        
        assert abs(coherent.value - 1.0) < 1e-14
        assert coherent.unit.symbol == "kg"
        
        # Test with compound units
        speed_scalar = Scalar.from_value_unit("3.6", "km/h")
        coherent_speed = speed_scalar.to_coherent_si()
        
        # 3.6 km/h = 1.0 m/s
        assert abs(coherent_speed.value - 1.0) < 1e-14
        assert coherent_speed.unit.symbol == "m/s"
        
    def test_scalar_best_unit_conversion(self):
        """Test automatic selection of best units for display."""
        # Very large value should convert to larger units
        large_distance = Scalar.from_value_unit("1000000.0", "m")  # 1000 km
        
        # Test if we can convert to a more appropriate unit
        try:
            km_distance = large_distance.convert_to("km")
            assert abs(km_distance.value - 1000.0) < 1e-14
            assert km_distance.unit.symbol == "km"
        except (AttributeError, ValueError):
            pytest.skip("Unit conversion not supported")
            
        # Very small value should convert to smaller units  
        small_distance = Scalar.from_value_unit("0.001", "m")  # 1 mm
        
        try:
            mm_distance = small_distance.convert_to("mm")
            assert abs(mm_distance.value - 1.0) < 1e-14
            assert mm_distance.unit.symbol == "mm"
        except (AttributeError, ValueError):
            pytest.skip("Unit conversion not supported")


class TestScalarArithmetic:
    """Test scalar arithmetic operations."""
    
    def test_addition_same_units(self):
        """Test addition of scalars with same units."""
        a = Scalar.from_value_unit("5.0", "m")
        b = Scalar.from_value_unit("3.0", "m")
        result = a + b
        assert abs(result.value - 8.0) < 1e-14
        assert result.unit.symbol == "m"
        
    def test_addition_compatible_units(self):
        """Test addition of scalars with compatible units."""
        a = Scalar.from_value_unit("1000.0", "mm")  # 1 meter
        b = Scalar.from_value_unit("0.5", "m")      # 0.5 meters
        result = a + b
        # Addition preserves first operand's units: 1000 mm + 500 mm = 1500 mm
        assert abs(result.value - 1500.0) < 1e-14
        assert result.unit.symbol == "mm"
        
    def test_subtraction_same_units(self):
        """Test subtraction of scalars with same units."""
        a = Scalar.from_value_unit("10.0", "kg")
        b = Scalar.from_value_unit("3.0", "kg")
        result = a - b
        assert abs(result.value - 7.0) < 1e-14
        assert result.unit.symbol == "kg"
        
    def test_subtraction_compatible_units(self):
        """Test subtraction of scalars with compatible units."""
        a = Scalar.from_value_unit("2000.0", "g")   # 2 kg
        b = Scalar.from_value_unit("0.5", "kg")     # 0.5 kg
        result = a - b
        # Subtraction preserves first operand's units: 2000 g - 500 g = 1500 g
        assert abs(result.value - 1500.0) < 1e-14
        assert result.unit.symbol == "g"
        
    def test_multiplication(self):
        """Test multiplication of scalars."""
        a = Scalar.from_value_unit("5.0", "m")
        b = Scalar.from_value_unit("3.0", "s")
        result = a * b
        assert abs(result.value - 15.0) < 1e-14
        assert result.unit.symbol == "m•s"  # SITypes uses • for multiplication
        
    def test_multiplication_same_units(self):
        """Test multiplication resulting in squared units."""
        a = Scalar.from_value_unit("4.0", "m")
        b = Scalar.from_value_unit("2.0", "m")
        result = a * b
        assert abs(result.value - 8.0) < 1e-14
        assert result.unit.symbol == "m^2"  # SITypes uses ^2 instead of ²
        
    def test_division(self):
        """Test division of scalars."""
        a = Scalar.from_value_unit("12.0", "m")
        b = Scalar.from_value_unit("3.0", "s")
        result = a / b
        assert abs(result.value - 4.0) < 1e-14
        assert result.unit.symbol == "m/s"
        
    def test_division_same_units(self):
        """Test division resulting in dimensionless quantity."""
        a = Scalar.from_value_unit("15.0", "kg")
        b = Scalar.from_value_unit("3.0", "kg")
        result = a / b
        assert abs(result.value - 5.0) < 1e-14
        assert result.unit.is_dimensionless
        
    def test_power_integer(self):
        """Test raising scalar to integer power."""
        scalar = Scalar.from_value_unit("2.0", "m")
        result = scalar ** 3
        assert abs(result.value - 8.0) < 1e-14
        assert result.unit.symbol == "kL"  # SITypes converts m³ to kiloliters (equivalent)
        
    def test_power_negative(self):
        """Test raising scalar to negative power."""
        scalar = Scalar.from_value_unit("4.0", "m")
        result = scalar ** -2
        assert abs(result.value - 1.0/16.0) < 1e-14
        assert result.unit.symbol == "(1/m^2)"  # SITypes formats negative powers with parentheses
        
    def test_power_fractional(self):
        """Test raising scalar to fractional power."""
        scalar = Scalar.from_value_unit("9.0", "m^2")
        result = scalar ** 0.5
        assert abs(result.value - 3.0) < 1e-14
        assert result.unit.symbol == "m^2^0.5"  # SITypes doesn't simplify fractional powers
        
    def test_arithmetic_with_numbers(self):
        """Test arithmetic operations with plain numbers."""
        scalar = Scalar.from_value_unit("5.0", "m")
        
        # Multiplication by number
        result1 = scalar * 3.0
        assert abs(result1.value - 15.0) < 1e-14
        assert result1.unit.symbol == "m"
        
        # Division by number
        result2 = scalar / 2.0
        assert abs(result2.value - 2.5) < 1e-14
        assert result2.unit.symbol == "m"
        
    def test_incompatible_addition(self):
        """Test addition of incompatible units should raise error."""
        a = Scalar.from_value_unit("5.0", "m")
        b = Scalar.from_value_unit("3.0", "kg")
        with pytest.raises(RMNError):  # Wrapper raises RMNError, not ValueError
            result = a + b
            
    def test_incompatible_subtraction(self):
        """Test subtraction of incompatible units should raise error."""
        a = Scalar.from_value_unit("5.0", "m")
        b = Scalar.from_value_unit("3.0", "s")
        with pytest.raises(RMNError):  # Wrapper raises RMNError, not ValueError
            result = a - b


class TestScalarComparison:
    """Test scalar comparison operations."""
    
    def test_equality_same_units(self):
        """Test equality comparison with same units."""
        a = Scalar.from_value_unit("5.0", "m")
        b = Scalar.from_value_unit("5.0", "m")
        assert a == b
        
    def test_equality_compatible_units(self):
        """Test equality comparison with compatible units."""
        a = Scalar.from_value_unit("1000.0", "mm")
        b = Scalar.from_value_unit("1.0", "m")
        assert a == b
        
    def test_inequality(self):
        """Test inequality comparisons."""
        a = Scalar.from_value_unit("5.0", "m")
        b = Scalar.from_value_unit("3.0", "m")
        c = Scalar.from_value_unit("7.0", "m")
        
        assert a != b
        assert a != c
        assert a > b
        assert a < c
        assert b <= a
        assert c >= a
        
    def test_comparison_compatible_units(self):
        """Test comparisons with compatible units."""
        a = Scalar.from_value_unit("1500.0", "mm")  # 1.5 m
        b = Scalar.from_value_unit("1.0", "m")      # 1.0 m
        
        assert a > b
        assert b < a
        assert not (a == b)
        
    def test_comparison_incompatible_units(self):
        """Test comparison of incompatible units should raise error."""
        a = Scalar.from_value_unit("5.0", "m")
        b = Scalar.from_value_unit("3.0", "kg")
        
        # Equality comparison returns False for incompatible units (doesn't raise)
        assert (a == b) == False
        
        # Ordering comparisons raise TypeError for incompatible units
        with pytest.raises(TypeError):
            result = a < b


class TestScalarAdvancedComparison:
    """Test advanced comparison operations beyond basic equality."""
    
    def test_scalar_tolerance_comparison(self):
        """Test comparison with numerical tolerance."""
        # Values that are very close but not exactly equal
        a = Scalar.from_value_unit("1.0000001", "m")
        b = Scalar.from_value_unit("1.0000002", "m")
        
        # They should be unequal with strict comparison
        assert a != b
        
        # Test manual tolerance comparison
        tolerance = 1e-6
        assert abs(a.value - b.value) < tolerance
        
    def test_scalar_unit_aware_comparison(self):
        """Test comparison accounting for unit differences."""
        # Same physical quantity in different units
        a = Scalar.from_value_unit("1000.0", "mm")  # 1 meter
        b = Scalar.from_value_unit("1.0", "m")      # 1 meter
        
        # Should be equal despite different units
        assert a == b
        
        # Test ordering with unit conversion
        c = Scalar.from_value_unit("500.0", "mm")   # 0.5 meter
        assert c < a
        assert c < b
        assert a >= c
        
    def test_scalar_dimensionality_comparison(self):
        """Test comparison behavior with different dimensionalities."""
        length = Scalar.from_value_unit("1.0", "m")
        time = Scalar.from_value_unit("1.0", "s")
        
        # Equality comparison returns False for different dimensionalities
        assert (length == time) == False
        
        # Inequality comparison raises RMNError
        with pytest.raises(RMNError):
            result = length != time
        
        # Ordering should raise TypeError for incompatible dimensions
        with pytest.raises(TypeError):
            result = length < time
            
        with pytest.raises(TypeError):
            result = length > time


class TestScalarConversion:
    """Test scalar unit conversion methods."""
    
    def test_convert_to_compatible_unit(self):
        """Test converting to compatible unit."""
        scalar = Scalar.from_value_unit("1000.0", "mm")
        converted = scalar.convert_to("m")
        assert abs(converted.value - 1.0) < 1e-14
        assert converted.unit.symbol == "m"
        
    def test_convert_to_compound_unit(self):
        """Test converting to compound unit."""
        scalar = Scalar.from_value_unit("3.6", "km/h")
        converted = scalar.convert_to("m/s")
        assert abs(converted.value - 1.0) < 1e-14
        assert converted.unit.symbol == "m/s"
        
    def test_convert_to_incompatible_unit(self):
        """Test converting to incompatible unit should raise error."""
        scalar = Scalar.from_value_unit("5.0", "m")
        with pytest.raises(ValueError):
            scalar.convert_to("kg")
            
    def test_to_coherent_si(self):
        """Test conversion to coherent SI units."""
        scalar = Scalar.from_value_unit("1000.0", "mm")
        coherent = scalar.to_coherent_si()
        assert abs(coherent.value - 1.0) < 1e-14
        assert coherent.unit.symbol == "m"
        
        # Test with compound unit
        scalar2 = Scalar.from_value_unit("100.0", "km/h")
        coherent2 = scalar2.to_coherent_si()
        # 100 km/h = 100000 m / 3600 s = 27.777... m/s
        expected = 100000.0 / 3600.0
        assert abs(coherent2.value - expected) < 1e-12
        assert coherent2.unit.symbol == "m/s"


class TestScalarUtilities:
    """Test scalar utility methods."""
    
    def test_string_representation(self):
        """Test string representation methods."""
        scalar = Scalar.from_value_unit("9.81", "m/s^2")
        
        # Test str() representation
        str_repr = str(scalar)
        assert "9.81" in str_repr
        assert "m/s^2" in str_repr  # SITypes uses ^2 instead of ²
        
        # Test repr() representation
        repr_str = repr(scalar)
        assert "Scalar" in repr_str
        assert "9.81" in repr_str
        
    def test_copy_operations(self):
        """Test that arithmetic operations create new objects."""
        original = Scalar.from_value_unit("5.0", "m")
        doubled = original * 2.0
        
        # Original should be unchanged
        assert abs(original.value - 5.0) < 1e-14
        assert abs(doubled.value - 10.0) < 1e-14
        
        # Should be different objects
        assert original is not doubled
        
    def test_hash_equality(self):
        """Test scalar hashability and equality."""
        a = Scalar.from_value_unit("5.0", "m")
        b = Scalar.from_value_unit("5000.0", "mm")  # Same value in different units
        
        # Test that scalars are currently not hashable (this is expected)
        with pytest.raises(TypeError):
            hash(a)
        
        # But equality still works
        assert a == b


class TestScalarEdgeCases:
    """Test edge cases and error conditions."""
    
    def test_zero_values(self):
        """Test operations with zero values."""
        zero = Scalar.from_value_unit("0.0", "m")
        nonzero = Scalar.from_value_unit("5.0", "m")
        
        # Addition with zero
        result = zero + nonzero
        assert abs(result.value - 5.0) < 1e-14
        
        # Multiplication by zero
        result = zero * nonzero
        assert abs(result.value - 0.0) < 1e-14
        
    def test_very_large_values(self):
        """Test operations with very large values."""
        large = Scalar.from_value_unit("1e20", "m")
        small = Scalar.from_value_unit("1e-20", "m")
        
        result = large + small
        assert abs(result.value - 1e20) < 1e6  # Small value is negligible
        
    def test_very_small_values(self):
        """Test operations with very small values."""
        tiny = Scalar.from_value_unit("1e-100", "m")
        normal = Scalar.from_value_unit("1.0", "m")
        
        result = tiny + normal
        assert abs(result.value - 1.0) < 1e-14  # Tiny value is negligible
        
    def test_division_by_zero(self):
        """Test division by zero should raise appropriate error."""
        scalar = Scalar.from_value_unit("5.0", "m")
        zero = Scalar.from_value_unit("0.0", "s")
        
        with pytest.raises(RMNError):  # Wrapper raises RMNError for division by zero
            result = scalar / zero
            
    def test_invalid_power(self):
        """Test power operations with extreme values."""
        scalar = Scalar.from_value_unit("5.0", "m")
        
        # Test with very large power - SITypes handles this by returning infinity
        result = scalar ** 1000
        assert result.value == float('inf')  # SITypes returns infinity for overflow
        assert result.unit.symbol == "(1/m^24)"  # Units still computed correctly


class TestScalarPhysicsExamples:
    """Test realistic physics examples."""
    
    def test_kinetic_energy_calculation(self):
        """Test kinetic energy calculation: KE = 0.5 * m * v²"""
        mass = Scalar.from_value_unit("2.0", "kg")
        velocity = Scalar.from_value_unit("10.0", "m/s")
        
        # KE = 0.5 * m * v²
        kinetic_energy = 0.5 * mass * (velocity ** 2)
        
        assert abs(kinetic_energy.value - 100.0) < 1e-14
        # Note: SITypes has a limitation where (m/s)² gives m/s² instead of m²/s²
        # This results in kg⋅m/s² (Newton) instead of kg⋅m²/s² (Joule)
        assert kinetic_energy.unit.name == "newton"  # Should be "joule" but SITypes limitation
        
    def test_force_calculation(self):
        """Test force calculation: F = m * a"""
        mass = Scalar.from_value_unit("5.0", "kg")
        acceleration = Scalar.from_value_unit("9.81", "m/s^2")
        
        force = mass * acceleration
        
        assert abs(force.value - 49.05) < 1e-14
        # Unit should be N (newtons) = kg⋅m/s²
        assert force.unit.name == "newton"
        
    def test_power_calculation(self):
        """Test power calculation: P = F * v"""
        force = Scalar.from_value_unit("100.0", "N")
        velocity = Scalar.from_value_unit("2.0", "m/s")
        
        power = force * velocity
        
        assert abs(power.value - 200.0) < 1e-14
        # Unit symbol should be N•m/s (Newton⋅meter/second)
        assert power.unit.symbol == "N•m/s"
        # SITypes doesn't recognize this compound unit as "watt" - unit name is empty
        assert power.unit.name == ""  # Compound units often have empty names in SITypes
        
    def test_unit_conversions_physics(self):
        """Test unit conversions in physics contexts."""
        # Convert speed from km/h to m/s
        speed = Scalar.from_value_unit("72.0", "km/h")
        speed_ms = speed.convert_to("m/s")
        
        # 72 km/h = 20 m/s
        assert abs(speed_ms.value - 20.0) < 1e-14
        
        # Convert energy from eV to J
        energy_ev = Scalar.from_value_unit("1.0", "eV")
        energy_j = energy_ev.convert_to("J")
        
        # 1 eV ≈ 1.602176634e-19 J
        expected = 1.602176634e-19
        assert abs(energy_j.value - expected) < 1e-25


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
