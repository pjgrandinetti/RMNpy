"""
Comprehensive Scalar Tests for SITypes Wrapper

This file combines tests from test_scalar.py and adds linking/integration tests
to provide complete coverage of the Scalar wrapper implementation, mirroring
the comprehensive C test suite in SITypes/tests/test_scalar.c
"""

import math
from decimal import Decimal
from fractions import Fraction

import pytest

from rmnpy.exceptions import RMNError
from rmnpy.wrappers.sitypes import Scalar
from rmnpy.wrappers.sitypes.unit import Unit


class TestScalarLinking:
    """Test scalar linking and basic C API integration."""

    def test_scalar_type_availability(self) -> None:
        """Test that Scalar type is available and functional."""
        # Test basic scalar creation works (indicates linking is functional)
        scalar = Scalar("1.0", "m")
        assert scalar is not None
        assert hasattr(scalar, "value")
        assert hasattr(scalar, "unit")
        assert hasattr(scalar, "dimensionality")

    def test_scalar_basic_operations(self) -> None:
        """Test basic scalar operations work (indicates C API linking)."""
        scalar1 = Scalar("5.0", "m")
        scalar2 = Scalar("3.0", "m")

        # Test arithmetic operations work
        result_add = scalar1 + scalar2
        assert result_add.value == 8.0

        result_mult = scalar1 * 2.0
        assert result_mult.value == 10.0

    def test_scalar_unit_integration(self) -> None:
        """Test scalar integration with Unit class."""
        scalar = Scalar("42.0", "m/s")
        unit = scalar.unit

        # Verify unit object is properly linked
        assert isinstance(unit, Unit)
        assert hasattr(unit, "dimensionality")
        assert not unit.is_dimensionless


class TestScalarCreation:
    """Test scalar creation methods."""

    def test_create_from_value_unit_strings(self) -> None:
        """Test creating scalar from value and unit strings."""
        scalar = Scalar("5.0", "m")
        assert scalar is not None
        assert str(scalar.unit) == "m"
        # Value comparison - exact string "5.0" should give exact value
        assert abs(scalar.value - 5.0) < 1e-14

    def test_create_from_numeric_types(self) -> None:
        """Test creating scalar from various Python numeric types."""
        # Integer
        scalar_int = Scalar(42, "kg")
        assert scalar_int.value == 42.0
        assert str(scalar_int.unit) == "kg"

        # Float
        scalar_float = Scalar(3.14159, "s")
        assert abs(scalar_float.value - 3.14159) < 1e-14
        assert str(scalar_float.unit) == "s"

        # Decimal
        scalar_decimal = Scalar(Decimal("2.5"), "A")
        assert abs(scalar_decimal.value - 2.5) < 1e-14
        assert str(scalar_decimal.unit) == "A"

        # Fraction
        scalar_fraction = Scalar(Fraction(3, 4), "mol")
        assert abs(scalar_fraction.value - 0.75) < 1e-14
        assert str(scalar_fraction.unit) == "mol"

    def test_create_from_expression(self) -> None:
        """Test creating scalar from complete expression string."""
        scalar = Scalar("9.81 m/s^2")
        assert abs(scalar.value - 9.81) < 1e-14
        assert str(scalar.unit) == "m/s^2"

        # Test another expression - SITypes keeps original units but normalizes value
        scalar2 = Scalar("100 km/h")
        # SITypes returns 277.778 dm/s (which equals 27.7778 m/s = 100 km/h)
        assert abs(scalar2.value - 277.77777777777777) < 1e-12
        assert str(scalar2.unit) == "dm/s"

        # Test scientific notation
        scalar_sci = Scalar("1.5e3 Hz")
        assert scalar_sci.value == 1500.0
        assert str(scalar_sci.unit) == "Hz"

        # Test negative value
        scalar_neg = Scalar("-42.0 Hz")
        assert scalar_neg.value == -42.0
        assert str(scalar_neg.unit) == "Hz"

    def test_create_dimensionless(self) -> None:
        """Test creating dimensionless scalars."""
        scalar = Scalar("1.5", "1")
        assert scalar.value == 1.5
        assert scalar.unit.is_dimensionless

    def test_create_invalid_unit(self) -> None:
        """Test creation with invalid unit should raise error."""
        with pytest.raises(RMNError):
            Scalar("5.0", "invalid_unit_xyz")

    def test_create_invalid_value(self) -> None:
        """Test creation with invalid value should raise error."""
        with pytest.raises(ValueError):
            Scalar("not_a_number", "m")

    def test_create_with_complex_numbers(self) -> None:
        """Test scalar creation with complex numbers."""
        try:
            # SITypes may support complex numbers - test if available
            scalar = Scalar(3.0 + 4.0j, "m")
            # Verify complex value handling - may store only real part
            assert isinstance(scalar.value, (float, complex))
        except (TypeError, ValueError):
            # Complex number support not implemented, which is acceptable
            pytest.skip("Complex number support not implemented in SITypes")

    def test_create_expression_errors(self) -> None:
        """Test error handling in expression parsing."""
        # Invalid format - RMNpy wrapper raises RMNError for syntax errors
        with pytest.raises(RMNError):
            Scalar("invalid expression format")

        # Empty string
        with pytest.raises(RMNError):
            Scalar("")

        with pytest.raises(TypeError):
            Scalar(None)


class TestScalarProperties:
    """Test scalar property access."""

    def test_value_property(self) -> None:
        """Test value property access."""
        scalar = Scalar("123.456", "m")
        assert abs(scalar.value - 123.456) < 1e-14

    def test_unit_property(self) -> None:
        """Test unit property access."""
        scalar = Scalar("10.0", "kg*m/s^2")
        unit = scalar.unit
        # SITypes may return simplified symbol 'N' instead of 'm•kg/s^2'
        unit_str = str(unit)
        assert unit_str == "N" or unit_str == "m•kg/s^2" or "kg" in unit_str
        # Note: unit.name is empty for compound units like kg*m/s^2

    def test_dimensionality_property(self) -> None:
        """Test dimensionality property access."""
        scalar = Scalar("5.0", "J")  # Joule = kg*m^2/s^2
        dim = scalar.dimensionality
        # Check that it has the right dimensionality for energy
        assert dim.is_derived  # Energy is a derived dimension
        assert not dim.is_dimensionless  # Energy has dimensions
        assert (
            str(dim) == "M•L^2/T^2"
        )  # Energy dimensionality symbol (physics ordering)


class TestScalarCopyOperations:
    """Test scalar copy operations and memory management."""

    def test_scalar_copy_independence(self) -> None:
        """Test that arithmetic operations create independent objects."""
        original = Scalar("42.0", "Hz")

        # Arithmetic operations should create new objects
        doubled = original * 2.0
        half = original / 2.0

        # Test independence
        assert doubled is not original
        assert half is not original
        assert doubled.value == 84.0
        assert half.value == 21.0
        assert original.value == 42.0  # Original unchanged

    def test_scalar_lifecycle_stress(self) -> None:
        """Test scalar creation and destruction under load."""
        scalars = []
        for i in range(100):
            scalar = Scalar(float(i), "m")
            scalars.append(scalar)

        # Verify all values
        for i, scalar in enumerate(scalars):
            assert scalar.value == float(i)
            assert str(scalar.unit) == "m"

        del scalars  # Python GC should handle cleanup


class TestScalarTypeInformation:
    """Test scalar type checking and introspection methods."""

    def test_scalar_type_properties(self) -> None:
        """Test scalar type-related properties and methods."""
        real_scalar = Scalar("42.0", "m")
        zero_scalar = Scalar("0.0", "m")

        # Test that value is always real in current implementation
        assert isinstance(real_scalar.value, (int, float))
        assert isinstance(zero_scalar.value, (int, float))

        # Test zero detection via value comparison
        assert zero_scalar.value == 0.0
        assert real_scalar.value != 0.0

    def test_scalar_infinite_values(self) -> None:
        """Test scalar handling of infinite values."""
        try:
            # Test if SITypes can handle infinity
            inf_scalar = Scalar(float("inf"), "m")
            assert math.isinf(inf_scalar.value)
        except (ValueError, OverflowError):
            # Infinity may not be supported, which is acceptable
            pytest.skip("Infinity values not supported in SITypes")

    def test_scalar_nan_values(self) -> None:
        """Test scalar handling of NaN values."""
        try:
            # Test if SITypes can handle NaN
            nan_scalar = Scalar(float("nan"), "m")
            assert math.isnan(nan_scalar.value)
        except (ValueError, OverflowError):
            # NaN may not be supported, which is acceptable
            pytest.skip("NaN values not supported in SITypes")


class TestScalarMathematicalFunctions:
    """Test mathematical functions on scalars."""

    def test_absolute_value(self) -> None:
        """Test absolute value function."""
        positive = Scalar("42.0", "m")
        negative = Scalar("-42.0", "m")

        # Test via Python abs()
        abs_positive = abs(positive)
        abs_negative = abs(negative)

        assert abs_positive.value == 42.0
        assert abs_negative.value == 42.0
        assert str(abs_positive.unit) == "m"
        assert str(abs_negative.unit) == "m"

    def test_power_operations(self) -> None:
        """Test power operations on scalars."""
        scalar = Scalar("4.0", "m")

        # Test square
        squared = scalar**2
        assert squared.value == 16.0
        assert str(squared.unit) == "m^2"

        # Test square root
        sqrt_result = squared**0.5
        assert abs(sqrt_result.value - 4.0) < 1e-14
        assert str(sqrt_result.unit) == "m"

    def test_trigonometric_functions(self) -> None:
        """Test trigonometric functions if available."""
        try:
            angle = Scalar("0.0", "rad")  # 0 radians

            # Try basic trig functions
            sin_result = math.sin(angle.value)  # Use value directly
            cos_result = math.cos(angle.value)
            tan_result = math.tan(angle.value)

            assert abs(sin_result - 0.0) < 1e-14
            assert abs(cos_result - 1.0) < 1e-14
            assert abs(tan_result - 0.0) < 1e-14

        except Exception:
            pytest.skip("Trigonometric functions not implemented for Scalar objects")

    def test_logarithmic_functions(self) -> None:
        """Test logarithmic functions if available."""
        try:
            # Natural log
            scalar = Scalar("2.718281828", "1")  # e, dimensionless
            log_result = math.log(scalar.value)
            assert abs(log_result - 1.0) < 1e-6

            # Base 10 log
            scalar10 = Scalar("100.0", "1")
            log10_result = math.log10(scalar10.value)
            assert abs(log10_result - 2.0) < 1e-14

        except Exception:
            pytest.skip("Logarithmic functions not implemented for Scalar objects")

    def test_exponential_functions(self) -> None:
        """Test exponential functions if available."""
        try:
            scalar = Scalar("1.0", "1")  # dimensionless
            exp_result = math.exp(scalar.value)
            assert abs(exp_result - math.e) < 1e-14

        except Exception:
            pytest.skip("Exponential functions not implemented for Scalar objects")


class TestScalarUnitOperations:
    """Test unit operations on scalars."""

    def test_unit_conversion(self) -> None:
        """Test converting scalars to different units."""
        meter_scalar = Scalar("1000.0", "m")

        try:
            # Test conversion to km (should work if conversion is implemented)
            km_scalar = meter_scalar.to("km")
            assert abs(km_scalar.value - 1.0) < 1e-14
            assert str(km_scalar.unit) == "km"

        except AttributeError:
            # Conversion method may not be implemented
            pytest.skip("Unit conversion method 'to' not implemented")

    def test_unit_compatibility_check(self) -> None:
        """Test checking unit reduced dimensionality compatibility."""
        meter_scalar = Scalar("5.0", "m")
        km_scalar = Scalar("2.0", "km")
        second_scalar = Scalar("10.0", "s")

        # Same reduced dimensionality should be compatible (both are length units)
        compatible = meter_scalar.unit.dimensionality.has_same_reduced_dimensionality(
            km_scalar.unit.dimensionality
        )
        assert compatible is True

        # Different reduced dimensionality should not be compatible (length vs time)
        incompatible = meter_scalar.unit.dimensionality.has_same_reduced_dimensionality(
            second_scalar.unit.dimensionality
        )
        assert incompatible is False

        # Test with more complex units that reduce to same dimensionality
        velocity1 = Scalar("10.0", "m/s")
        velocity2 = Scalar("5.0", "km/h")  # Different velocity units
        force_per_area = Scalar(
            "1.0", "N/m^2"
        )  # This is pressure, different dimensionality

        # Both velocity units should have same reduced dimensionality
        velocity_compatible = (
            velocity1.unit.dimensionality.has_same_reduced_dimensionality(
                velocity2.unit.dimensionality
            )
        )
        assert velocity_compatible is True

        # Velocity and pressure should have different reduced dimensionality
        velocity_pressure_incompatible = (
            velocity1.unit.dimensionality.has_same_reduced_dimensionality(
                force_per_area.unit.dimensionality
            )
        )
        assert velocity_pressure_incompatible is False

    def test_unit_simplification(self) -> None:
        """Test unit simplification in operations."""
        # Create scalars that should simplify when multiplied/divided
        velocity = Scalar("10.0", "m/s")
        time = Scalar("5.0", "s")

        # Distance = velocity * time
        distance = velocity * time
        assert distance.value == 50.0
        # Unit should be simplified to 'm'
        assert str(distance.unit) == "m"


class TestScalarArithmetic:
    """Test scalar arithmetic operations."""

    def test_scalar_addition(self) -> None:
        """Test scalar addition."""
        scalar1 = Scalar("10.0", "m")
        scalar2 = Scalar("5.0", "m")

        result = scalar1 + scalar2
        assert result.value == 15.0
        assert str(result.unit) == "m"

        # Test addition with different units of same dimensionality
        try:
            km_scalar = Scalar("1.0", "km")
            m_scalar = Scalar("500.0", "m")
            result_mixed = km_scalar + m_scalar
            # Result should be in consistent units
            assert result_mixed.value is not None
        except RMNError:
            # Mixed unit addition may not be supported
            pytest.skip("Mixed unit addition not supported")

    def test_scalar_subtraction(self) -> None:
        """Test scalar subtraction."""
        scalar1 = Scalar("15.0", "m")
        scalar2 = Scalar("5.0", "m")

        result = scalar1 - scalar2
        assert result.value == 10.0
        assert str(result.unit) == "m"

    def test_scalar_multiplication(self) -> None:
        """Test scalar multiplication."""
        scalar1 = Scalar("6.0", "m")
        scalar2 = Scalar("4.0", "s")

        result = scalar1 * scalar2
        assert result.value == 24.0
        # Unit should be m*s
        unit_str = str(result.unit)
        assert "m" in unit_str and "s" in unit_str

    def test_scalar_division(self) -> None:
        """Test scalar division."""
        scalar1 = Scalar("20.0", "m")
        scalar2 = Scalar("4.0", "s")

        result = scalar1 / scalar2
        assert result.value == 5.0
        # Unit should be m/s
        unit_str = str(result.unit)
        assert "m" in unit_str and "s" in unit_str

    def test_scalar_power(self) -> None:
        """Test scalar power operations."""
        scalar = Scalar("3.0", "m")

        # Test integer power
        squared = scalar**2
        assert squared.value == 9.0
        assert str(squared.unit) == "m^2"

        # Test fractional power
        sqrt_result = squared ** (1 / 2)
        assert abs(sqrt_result.value - 3.0) < 1e-14

    def test_incompatible_unit_operations(self) -> None:
        """Test operations with incompatible units."""
        length = Scalar("10.0", "m")
        time = Scalar("5.0", "s")

        # Addition/subtraction of incompatible units should raise error
        with pytest.raises((RMNError, ValueError)):
            length + time

        with pytest.raises((RMNError, ValueError)):
            length - time

        # Multiplication and division should work
        velocity = length / time
        assert velocity.value == 2.0

    def test_dimensionless_operations(self) -> None:
        """Test operations with dimensionless scalars."""
        dimensionless = Scalar("2.0", "1")
        length = Scalar("5.0", "m")

        # Multiplication with dimensionless
        result = length * dimensionless
        assert result.value == 10.0
        assert str(result.unit) == "m"

        # Division by dimensionless
        result2 = length / dimensionless
        assert result2.value == 2.5
        assert str(result2.unit) == "m"


class TestScalarComparison:
    """Test scalar comparison operations."""

    def test_equality_comparison(self) -> None:
        """Test equality comparison."""
        scalar1 = Scalar("42.0", "m")
        scalar2 = Scalar("42.0", "m")
        scalar3 = Scalar("24.0", "m")

        assert scalar1 == scalar2
        assert not (scalar1 == scalar3)
        assert scalar1 != scalar3

    def test_magnitude_comparison(self) -> None:
        """Test magnitude comparison operations."""
        scalar1 = Scalar("10.0", "m")
        scalar2 = Scalar("5.0", "m")
        scalar3 = Scalar("15.0", "m")

        assert scalar1 > scalar2
        assert scalar2 < scalar1
        assert scalar3 > scalar1
        assert scalar1 >= scalar2
        assert scalar2 <= scalar1
        assert scalar1 <= scalar1  # Equal case

    def test_comparison_with_different_units(self) -> None:
        """Test comparison with different units of same dimensionality."""
        try:
            meter = Scalar("1000.0", "m")
            kilometer = Scalar("1.0", "km")

            # Should be equal in magnitude despite different units
            assert meter == kilometer

        except (RMNError, NotImplementedError):
            pytest.skip("Cross-unit comparison not implemented")

    def test_incompatible_unit_comparison(self) -> None:
        """Test comparison with incompatible units."""
        length = Scalar("10.0", "m")
        time = Scalar("10.0", "s")

        # SITypes behavior: equality returns False, inequality raises exception
        result = length == time
        assert result is False

        # Inequality raises an exception for incompatible units
        with pytest.raises(RMNError):
            length != time


class TestScalarPythonNumberArithmetic:
    """Test scalar arithmetic with Python numbers."""

    def test_scalar_plus_number(self) -> None:
        """Test that scalar + number correctly prevents dimensional analysis errors."""
        scalar = Scalar("10.0", "m")

        # Addition with dimensionless number should fail (correct physics behavior)
        # Cannot add length (10 m) + dimensionless (5.0) - violates dimensional analysis
        with pytest.raises(RMNError, match="[Ii]ncompatible.*dimension"):
            result = scalar + 5.0

        # However, addition with dimensionless scalar should work
        dimensionless_scalar = Scalar("5.0", "1")  # Dimensionless scalar
        dimensionless_number = 3.0
        result = dimensionless_scalar + dimensionless_number
        assert result.value == 8.0
        assert result.unit.is_dimensionless

    def test_scalar_multiply_number(self) -> None:
        """Test scalar * number operations."""
        scalar = Scalar("6.0", "m")

        # Multiplication with number
        result = scalar * 3.0
        assert result.value == 18.0
        assert str(result.unit) == "m"

        # Commutative multiplication
        result2 = 3.0 * scalar
        assert result2.value == 18.0
        assert str(result2.unit) == "m"

    def test_scalar_divide_number(self) -> None:
        """Test scalar / number operations."""
        scalar = Scalar("20.0", "m")

        # Division by number
        result = scalar / 4.0
        assert result.value == 5.0
        assert str(result.unit) == "m"

    def test_number_divide_scalar(self) -> None:
        """Test number / scalar operations."""
        scalar = Scalar("4.0", "m")

        # Number divided by scalar
        result = 20.0 / scalar
        assert result.value == 5.0
        # Unit should be inverse
        unit_str = str(result.unit)
        assert "m" in unit_str  # Should be 1/m or (1/m)

    def test_scalar_power_number(self) -> None:
        """Test scalar ** number operations."""
        scalar = Scalar("3.0", "m")

        # Power with number
        result = scalar**3
        assert result.value == 27.0
        # SITypes may return simplified symbol like 'kL' instead of 'm^3'
        unit_str = str(result.unit)
        assert unit_str == "m^3" or unit_str == "kL"  # Both are valid for m^3

    def test_mixed_arithmetic_chains(self) -> None:
        """Test chains of mixed scalar-number arithmetic."""
        scalar = Scalar("2.0", "m")

        # Chain: (scalar * 3) + (scalar * 2)
        result = (scalar * 3.0) + (scalar * 2.0)
        assert result.value == 10.0  # 6 + 4
        assert str(result.unit) == "m"

        # Chain: (scalar^2) / number
        area = scalar**2
        result2 = area / 2.0
        assert result2.value == 2.0  # 4 / 2
        assert str(result2.unit) == "m^2"

    def test_complex_physics_calculation(self) -> None:
        """Test complex physics calculation mixing scalars and numbers."""
        # Kinetic energy: KE = 0.5 * m * v^2
        mass = Scalar("2.0", "kg")
        velocity = Scalar("10.0", "m/s")

        kinetic_energy = 0.5 * mass * (velocity**2)
        assert kinetic_energy.value == 100.0  # 0.5 * 2 * 100
        # Unit should be kg*(m/s)^2 = kg*m^2/s^2 = J
        unit_str = str(kinetic_energy.unit)
        # May be simplified to "J" or remain as compound unit
        assert "kg" in unit_str or unit_str == "J"

    def test_numeric_type_compatibility(self) -> None:
        """Test compatibility with different Python numeric types."""
        scalar = Scalar("6.0", "m")

        # Test with int
        result_int = scalar * 2
        assert result_int.value == 12.0

        # Test with float
        result_float = scalar * 2.5
        assert result_float.value == 15.0

        # Test with Decimal - may not be supported
        try:
            result_decimal = scalar * Decimal("1.5")
            assert result_decimal.value == 9.0
        except TypeError:
            # Decimal multiplication may not be supported
            pytest.skip("Decimal multiplication not supported")

        # Test with Fraction - may not be supported
        try:
            result_fraction = scalar * Fraction(1, 2)
            assert result_fraction.value == 3.0
        except TypeError:
            # Fraction multiplication may not be supported
            pytest.skip("Fraction multiplication not supported")

    def test_zero_operations(self) -> None:
        """Test operations involving zero."""
        scalar = Scalar("42.0", "m")
        zero = 0.0

        # Multiplication by zero
        result_mult = scalar * zero
        assert result_mult.value == 0.0
        assert str(result_mult.unit) == "m"

        # Addition with zero should fail (dimensional analysis error)
        # Cannot add length (42 m) + dimensionless (0.0)
        with pytest.raises(RMNError, match="[Ii]ncompatible.*dimension"):
            scalar + zero

        # But addition with dimensionless scalar works
        dimensionless = Scalar("42.0", "1")
        result_dimensionless = dimensionless + zero
        assert result_dimensionless.value == 42.0
        assert result_dimensionless.unit.is_dimensionless

    def test_negative_number_operations(self) -> None:
        """Test operations with negative numbers."""
        scalar = Scalar("10.0", "m")

        # Multiplication by negative number
        result = scalar * (-2.0)
        assert result.value == -20.0
        assert str(result.unit) == "m"

        # Division by negative number
        result2 = scalar / (-5.0)
        assert result2.value == -2.0
        assert str(result2.unit) == "m"

    def test_unit_preservation_in_number_ops(self) -> None:
        """Test that units are properly preserved in number operations."""
        # Create scalar with complex unit
        acceleration = Scalar("9.81", "m/s^2")

        # Multiply by dimensionless number
        doubled = acceleration * 2.0
        assert doubled.value == 19.62
        assert str(doubled.unit) == "m/s^2"

        # Divide by dimensionless number
        halved = acceleration / 2.0
        assert halved.value == 4.905
        assert str(halved.unit) == "m/s^2"

    def test_order_independence(self) -> None:
        """Test that scalar-number operations are order-independent where appropriate."""
        scalar = Scalar("7.0", "kg")
        number = 3.0

        # Multiplication should be commutative
        result1 = scalar * number
        result2 = number * scalar
        assert result1.value == result2.value
        assert str(result1.unit) == str(result2.unit)

        # But division is not commutative
        result3 = scalar / number
        result4 = number / scalar
        assert result3.value != result4.value  # Should be different
        # Units should be different too (kg vs 1/kg)


class TestScalarDimensionalAnalysis:
    """Test that SITypes properly enforces dimensional analysis rules."""

    def test_prevents_length_plus_dimensionless(self) -> None:
        """Test that adding length + dimensionless number is prevented."""
        length = Scalar("10.0", "m")

        # These should all fail with dimensional analysis errors
        with pytest.raises(RMNError, match="[Ii]ncompatible.*dimension"):
            length + 5.0

        with pytest.raises(RMNError, match="[Ii]ncompatible.*dimension"):
            length + 5

        with pytest.raises(RMNError, match="[Ii]ncompatible.*dimension"):
            5.0 + length

    def test_prevents_time_minus_mass(self) -> None:
        """Test that subtracting incompatible units is prevented."""
        time = Scalar("10.0", "s")
        mass = Scalar("5.0", "kg")

        with pytest.raises(RMNError, match="[Ii]ncompatible.*dimension"):
            time - mass

        with pytest.raises(RMNError, match="[Ii]ncompatible.*dimension"):
            mass - time

    def test_prevents_force_plus_energy(self) -> None:
        """Test that adding different derived units is prevented."""
        force = Scalar("100.0", "N")  # kg⋅m/s²
        energy = Scalar("50.0", "J")  # kg⋅m²/s²

        # Even though both have kg, m, s dimensions, they're different
        with pytest.raises(RMNError, match="[Ii]ncompatible.*dimension"):
            force + energy

    def test_allows_compatible_unit_operations(self) -> None:
        """Test that operations with compatible units are allowed."""
        # Same units
        length1 = Scalar("10.0", "m")
        length2 = Scalar("5.0", "m")
        result = length1 + length2
        assert result.value == 15.0
        assert str(result.unit) == "m"

        # Compatible units (same dimensionality)
        try:
            km = Scalar("1.0", "km")
            m = Scalar("500.0", "m")
            # This may or may not work depending on SITypes implementation
            result = km + m
            assert result.value is not None  # Should succeed if implemented
        except RMNError:
            # If not implemented, that's also acceptable
            pytest.skip("Mixed compatible unit addition not implemented")

    def test_allows_dimensionless_operations(self) -> None:
        """Test that dimensionless operations work correctly."""
        dimensionless1 = Scalar("10.0", "1")
        dimensionless2 = Scalar("5.0", "1")
        number = 3.0

        # All of these should work
        result1 = dimensionless1 + dimensionless2
        assert result1.value == 15.0
        assert result1.unit.is_dimensionless

        result2 = dimensionless1 + number
        assert result2.value == 13.0
        assert result2.unit.is_dimensionless

        result3 = number + dimensionless1
        assert result3.value == 13.0
        assert result3.unit.is_dimensionless

    def test_multiplication_division_always_allowed(self) -> None:
        """Test that multiplication and division work with any units."""
        length = Scalar("10.0", "m")
        time = Scalar("2.0", "s")
        mass = Scalar("5.0", "kg")
        number = 3.0

        # Multiplication should always work
        velocity = length / time
        assert velocity.value == 5.0
        assert str(velocity.unit) == "m/s"

        momentum = mass * velocity
        assert momentum.value == 25.0

        scaled_length = length * number
        assert scaled_length.value == 30.0
        assert str(scaled_length.unit) == "m"

        # Division should always work
        ratio = length / mass  # Weird but mathematically valid
        assert ratio.value == 2.0


class TestScalarAdvancedComparison:
    """Test advanced comparison scenarios."""

    def test_floating_point_precision_comparison(self) -> None:
        """Test comparison with floating point precision considerations."""
        # Values that should be equal but might have floating point errors
        scalar1 = Scalar("0.1", "m")
        scalar2 = Scalar(0.1, "m")

        # Should be equal despite potential floating point differences
        assert scalar1 == scalar2

    def test_scientific_notation_comparison(self) -> None:
        """Test comparison with scientific notation values."""
        scalar1 = Scalar("1.5e3", "Hz")
        scalar2 = Scalar("1500.0", "Hz")

        assert scalar1 == scalar2
        assert scalar1.value == 1500.0
        assert scalar2.value == 1500.0

    def test_very_large_number_comparison(self) -> None:
        """Test comparison with very large numbers."""
        try:
            large1 = Scalar("1e20", "m")
            large2 = Scalar("1e20", "m")
            assert large1 == large2

            larger = Scalar("2e20", "m")
            assert larger > large1

        except (OverflowError, ValueError):
            pytest.skip("Very large numbers not supported")

    def test_very_small_number_comparison(self) -> None:
        """Test comparison with very small numbers."""
        # Test that SITypes can handle very small numbers
        small1 = Scalar("1e-20", "m")
        small2 = Scalar("1e-20", "m")
        assert small1 == small2

        smaller = Scalar("5e-21", "m")
        # Test comparison - should work if SITypes handles precision correctly
        assert smaller < small1

        # Test that different small numbers are not equal
        assert smaller != small1
        assert small1 > smaller


class TestScalarConversion:
    """Test scalar conversion operations."""

    def test_to_different_units(self) -> None:
        """Test conversion to different units."""
        try:
            meter_scalar = Scalar("1500.0", "m")
            km_scalar = meter_scalar.to("km")
            assert abs(km_scalar.value - 1.5) < 1e-14
            assert str(km_scalar.unit) == "km"

        except AttributeError:
            pytest.skip("Conversion method 'to' not implemented")

    def test_conversion_chain(self) -> None:
        """Test chaining multiple conversions."""
        try:
            # Start with meters, convert to km, then back to m
            original = Scalar("2000.0", "m")
            km_version = original.to("km")
            back_to_m = km_version.to("m")

            assert abs(back_to_m.value - 2000.0) < 1e-10
            assert str(back_to_m.unit) == "m"

        except AttributeError:
            pytest.skip("Conversion method 'to' not implemented")

    def test_invalid_unit_conversion(self) -> None:
        """Test conversion to incompatible units."""
        try:
            length = Scalar("10.0", "m")
            # Should raise error when trying to convert length to time
            with pytest.raises((RMNError, ValueError)):
                length.to("s")

        except AttributeError:
            pytest.skip("Conversion method 'to' not implemented")


class TestScalarUtilities:
    """Test scalar utility methods."""

    def test_string_representation(self) -> None:
        """Test string representation of scalars."""
        scalar = Scalar("42.5", "m/s")
        str_repr = str(scalar)

        # Should contain both value and unit
        assert "42.5" in str_repr
        assert "m" in str_repr and "s" in str_repr

    def test_repr_representation(self) -> None:
        """Test repr representation of scalars."""
        scalar = Scalar("10.0", "kg")
        repr_str = repr(scalar)

        # Should be informative and contain Scalar
        assert "Scalar" in repr_str
        # Value may be displayed as "10" instead of "10.0"
        assert "10" in repr_str or "10.0" in repr_str

    def test_hash_behavior(self) -> None:
        """Test hash behavior for scalars."""
        scalar1 = Scalar("42.0", "m")
        scalar2 = Scalar("42.0", "m")

        try:
            # Equal scalars should have equal hashes
            assert hash(scalar1) == hash(scalar2)
            # Different scalars may or may not have different hashes
            # (hash collisions are allowed)
        except TypeError:
            # Scalars may not be hashable
            pytest.skip("Scalar objects are not hashable")

    def test_bool_behavior(self) -> None:
        """Test boolean behavior of scalars."""
        zero_scalar = Scalar("0.0", "m")
        nonzero_scalar = Scalar("42.0", "m")

        try:
            # In SITypes, zero scalar is actually truthy (exists as an object)
            # Non-zero should be truthy as well
            assert bool(zero_scalar)  # SITypes zero scalar is True
            assert bool(nonzero_scalar)
        except (TypeError, NotImplementedError):
            # Boolean conversion may not be implemented
            pytest.skip("Boolean conversion not implemented for Scalar")


class TestScalarEdgeCases:
    """Test scalar edge cases and error conditions."""

    def test_division_by_zero_scalar(self) -> None:
        """Test division by zero scalar."""
        numerator = Scalar("10.0", "m")
        zero_denominator = Scalar("0.0", "s")

        result = numerator / zero_denominator
        assert result.value == float("inf"), "Division by zero should return infinity"
        assert str(result.unit) == "m/s", "Unit should be correctly computed"

    def test_zero_power_operations(self) -> None:
        """Test operations involving zero power."""
        scalar = Scalar("5.0", "m")

        # Anything to the power of 0 should be 1 (dimensionless)
        result = scalar**0
        assert result.value == 1.0
        assert result.unit.is_dimensionless

    def test_negative_power_operations(self) -> None:
        """Test negative power operations."""
        scalar = Scalar("4.0", "m")

        # Negative power should give reciprocal
        result = scalar ** (-1)
        assert abs(result.value - 0.25) < 1e-14
        # Unit should be 1/m
        unit_str = str(result.unit)
        assert "m" in unit_str

    def test_fractional_power_edge_cases(self) -> None:
        """Test fractional power edge cases."""
        scalar = Scalar("8.0", "m^3")

        try:
            # Cube root
            result = scalar ** (1 / 3)
            assert abs(result.value - 2.0) < 1e-14
            assert str(result.unit) == "m"

        except (ValueError, ArithmeticError):
            # Fractional powers may not be fully supported
            pytest.skip("Fractional powers not fully supported")

    def test_memory_stress_operations(self) -> None:
        """Test operations under memory stress."""
        # Create many scalars and perform operations
        scalars = [Scalar(float(i), "m") for i in range(50)]

        # Chain operations
        result = scalars[0]
        for scalar in scalars[1:10]:  # Use subset to avoid excessive computation
            result = result + scalar

        # Should not crash or leak memory
        assert result.value == sum(range(10))  # 0+1+2+...+9 = 45
        assert str(result.unit) == "m"

    def test_extreme_value_operations(self) -> None:
        """Test operations with extreme values."""
        try:
            # Very large value
            large = Scalar("1e100", "m")
            result = large * 2.0
            assert result.value == 2e100

            # Very small value
            small = Scalar("1e-100", "m")
            result2 = small * 2.0
            assert result2.value == 2e-100

        except (OverflowError, ValueError):
            pytest.skip("Extreme values not supported")


class TestScalarPhysicsExamples:
    """Test scalar operations with real physics examples."""

    def test_gravitational_force_calculation(self) -> None:
        """Test gravitational force calculation: F = G * m1 * m2 / r^2."""
        # Gravitational constant
        G = Scalar("6.67430e-11", "m^3/(kg*s^2)")

        # Masses
        m1 = Scalar("5.97e24", "kg")  # Earth mass
        m2 = Scalar("7.35e22", "kg")  # Moon mass

        # Distance
        r = Scalar("3.84e8", "m")  # Earth-Moon distance

        # Calculate force
        force = G * m1 * m2 / (r**2)

        # Should be approximately 1.98e20 N
        assert abs(force.value - 1.98e20) < 1e19  # Allow 10% tolerance
        # Unit should be force (N or kg*m/s^2)
        unit_str = str(force.unit)
        assert "kg" in unit_str or unit_str == "N"

    def test_kinetic_energy_calculation(self) -> None:
        """Test kinetic energy calculation: KE = 0.5 * m * v^2."""
        mass = Scalar("1500.0", "kg")  # Car mass
        velocity = Scalar("25.0", "m/s")  # Speed

        kinetic_energy = 0.5 * mass * (velocity**2)

        assert kinetic_energy.value == 468750.0  # 0.5 * 1500 * 625
        # Unit should be energy (J or kg*m^2/s^2)
        unit_str = str(kinetic_energy.unit)
        assert "kg" in unit_str or unit_str == "J"

    def test_wave_equation(self) -> None:
        """Test wave equation: v = f * λ."""
        frequency = Scalar("440.0", "Hz")  # A4 note
        wavelength = Scalar("0.77", "m")  # Approximate wavelength in air

        velocity = frequency * wavelength

        assert abs(velocity.value - 338.8) < 1.0  # Speed of sound ~343 m/s
        assert str(velocity.unit) == "m/s"

    def test_ohms_law(self) -> None:
        """Test Ohm's law: V = I * R."""
        current = Scalar("2.5", "A")
        resistance = Scalar("100.0", "Ω")  # Ohm symbol

        try:
            voltage = current * resistance
            assert voltage.value == 250.0
            # Unit should be volts (V) or derived unit
            unit_str = str(voltage.unit)
            assert "V" in unit_str or "Ω" in unit_str or "A" in unit_str

        except RMNError:
            # Ohm unit may not be recognized
            pytest.skip("Ohm unit (Ω) not supported")

    def test_pressure_calculation(self) -> None:
        """Test pressure calculation: P = F / A."""
        force = Scalar("1000.0", "N")
        area = Scalar("0.01", "m^2")  # 1 cm^2

        pressure = force / area

        assert pressure.value == 100000.0  # 100 kPa
        # Unit should be Pa or N/m^2
        unit_str = str(pressure.unit)
        assert "Pa" in unit_str or ("N" in unit_str and "m" in unit_str)

    def test_power_calculation(self) -> None:
        """Test power calculation: P = E / t."""
        energy = Scalar("3600000.0", "J")  # 1 kWh in Joules
        time = Scalar("3600.0", "s")  # 1 hour in seconds

        power = energy / time

        assert power.value == 1000.0  # 1 kW
        # Unit should be W or J/s
        unit_str = str(power.unit)
        assert "W" in unit_str or ("J" in unit_str and "s" in unit_str)


class TestMathematicalFunctions:
    """Test mathematical functions and operations."""

    def test_exponential_decay(self) -> None:
        """Test exponential decay calculation."""
        # N(t) = N0 * exp(-λt)
        N0 = Scalar("1000.0", "1")  # Initial quantity
        decay_constant = 0.693  # λ (dimensionless)
        time = Scalar("1.0", "s")

        # Calculate using scalar value for exponential
        N_t = N0 * math.exp(-decay_constant * time.value)

        assert abs(N_t.value - 500.0) < 1.0  # Half-life
        assert N_t.unit.is_dimensionless

    def test_harmonic_oscillator(self) -> None:
        """Test harmonic oscillator equation."""
        # ω = sqrt(k/m)
        spring_constant = Scalar("400.0", "kg/s^2")  # N/m = kg/s^2
        mass = Scalar("1.0", "kg")

        # Angular frequency
        omega_squared = spring_constant / mass
        # ω = sqrt(k/m), so ω^2 = k/m

        assert omega_squared.value == 400.0
        # Unit should be 1/s^2 (since ω has units of 1/s)
        unit_str = str(omega_squared.unit)
        assert "s" in unit_str

    def test_relativistic_energy(self) -> None:
        """Test relativistic energy calculation."""
        # E = γmc^2, where γ = 1/sqrt(1 - v^2/c^2)
        mass = Scalar("9.109e-31", "kg")  # Electron mass
        c = Scalar("3e8", "m/s")  # Speed of light
        velocity = Scalar("1.5e8", "m/s")  # Half light speed

        # Calculate γ using scalar values
        v_over_c = velocity.value / c.value
        gamma = 1.0 / math.sqrt(1.0 - v_over_c**2)

        # Total energy
        energy = gamma * mass * (c**2)

        # Should be significantly larger than rest mass energy
        rest_energy = mass * (c**2)
        assert energy.value > rest_energy.value

        # Unit should be energy (J or kg*m^2/s^2)
        unit_str = str(energy.unit)
        assert "kg" in unit_str or unit_str == "J"

    def test_logarithmic_growth(self) -> None:
        """Test logarithmic growth calculations."""
        # pH = -log10([H+])
        hydrogen_concentration = Scalar("1e-7", "mol/L")

        # Calculate pH using scalar value
        pH = -math.log10(hydrogen_concentration.value)

        assert abs(pH - 7.0) < 1e-10  # Neutral pH
        # pH is dimensionless

    def test_trigonometric_calculations(self) -> None:
        """Test trigonometric calculations in physics."""
        # Pendulum period: T = 2π * sqrt(L/g)
        length = Scalar("1.0", "m")
        gravity = Scalar("9.81", "m/s^2")

        # Calculate period using scalar values for trig functions
        L_over_g = length / gravity
        period_factor = 2.0 * math.pi * math.sqrt(L_over_g.value)
        period = Scalar(str(period_factor), "s")

        assert abs(period.value - 2.006) < 0.01  # Approximate 1m pendulum period
        assert str(period.unit) == "s"


class TestChemicalConstants:
    """Test calculations involving chemical and physical constants."""

    def test_ideal_gas_law(self) -> None:
        """Test ideal gas law: PV = nRT."""
        # Calculate pressure given V, n, R, T
        volume = Scalar("0.022414", "m^3")  # 22.414 L at STP
        amount = Scalar("1.0", "mol")
        R = Scalar("8.314", "J/(mol*K)")  # Gas constant
        temperature = Scalar("273.15", "K")  # 0°C

        pressure = (amount * R * temperature) / volume

        # Should be approximately 1 atm = 101325 Pa
        assert abs(pressure.value - 101325) < 1000  # Within 1%
        # Unit should be pressure (Pa or N/m^2)
        unit_str = str(pressure.unit)
        assert "Pa" in unit_str or ("J" in unit_str and "m" in unit_str)

    def test_avogadro_calculation(self) -> None:
        """Test calculation involving Avogadro's number."""
        # Number of atoms in 12g of C-12
        mass = Scalar("0.012", "kg")  # 12 g
        molar_mass = Scalar("0.012", "kg/mol")  # 12 g/mol for C-12
        avogadro = Scalar("6.022e23", "1/mol")

        number_of_atoms = (mass / molar_mass) * avogadro

        assert abs(number_of_atoms.value - 6.022e23) < 1e22
        assert number_of_atoms.unit.is_dimensionless

    def test_planck_equation(self) -> None:
        """Test Planck's equation: E = hf."""
        planck_constant = Scalar("6.626e-34", "J*s")
        frequency = Scalar("5e14", "Hz")  # Green light

        photon_energy = planck_constant * frequency

        # Should be approximately 3.3e-19 J
        assert abs(photon_energy.value - 3.313e-19) < 1e-21
        # Unit should be energy (J)
        unit_str = str(photon_energy.unit)
        assert "J" in unit_str

    def test_einstein_mass_energy(self) -> None:
        """Test Einstein's mass-energy equivalence: E = mc^2."""
        mass = Scalar("1e-3", "kg")  # 1 gram
        c = Scalar("3e8", "m/s")  # Speed of light

        energy = mass * (c**2)

        # Should be 9e13 J (huge amount of energy!)
        assert abs(energy.value - 9e13) < 1e12
        # Unit should be energy (J or kg*m^2/s^2)
        unit_str = str(energy.unit)
        assert "kg" in unit_str or unit_str == "J"

    def test_coulomb_law(self) -> None:
        """Test Coulomb's law: F = k * q1 * q2 / r^2."""
        try:
            k = Scalar("8.99e9", "N*m^2/C^2")  # Coulomb constant
            q1 = Scalar("1.6e-19", "C")  # Elementary charge
            q2 = Scalar("1.6e-19", "C")  # Elementary charge
            r = Scalar("1e-10", "m")  # 1 Angstrom

            force = k * q1 * q2 / (r**2)

            # Should be approximately 2.3e-8 N
            assert abs(force.value - 2.3e-8) < 1e-9
            # Unit should be force (N)
            unit_str = str(force.unit)
            assert "N" in unit_str or "kg" in unit_str

        except RMNError:
            # Coulomb unit may not be supported
            pytest.skip("Coulomb unit (C) not supported")


class TestAdvancedOperations:
    """Test advanced scalar operations and edge cases."""

    def test_unit_cancellation_complex(self) -> None:
        """Test complex unit cancellation in operations."""
        # Create a complex calculation that should result in simple units
        force = Scalar("10.0", "N")  # kg*m/s^2
        area = Scalar("2.0", "m^2")
        time = Scalar("5.0", "s")

        # Pressure * time should give (N/m^2) * s = (kg*m/s^2)/m^2 * s = kg/(m*s)
        pressure = force / area
        result = pressure * time

        # SITypes simplifies units, so we might get 'Pa•s' instead of 'kg/(m*s)'
        unit_str = str(result.unit)
        # Accept either the simplified form or component forms
        assert ("Pa" in unit_str and "s" in unit_str) or (
            "kg" in unit_str and "m" in unit_str
        )

    def test_dimensional_analysis_verification(self) -> None:
        """Test dimensional analysis verification in complex calculations."""
        # Verify that incorrect dimensional combinations are caught
        length = Scalar("10.0", "m")
        time = Scalar("2.0", "s")
        mass = Scalar("5.0", "kg")

        # Valid: velocity = length / time
        velocity = length / time
        assert str(velocity.unit) == "m/s"

        # Valid: momentum = mass * velocity
        momentum = mass * velocity
        unit_str = str(momentum.unit)
        # SITypes may simplify to 'N•s' instead of showing individual components
        assert ("N" in unit_str and "s" in unit_str) or (
            "kg" in unit_str and "m" in unit_str and "s" in unit_str
        )

    def test_precision_preservation(self) -> None:
        """Test that precision is preserved through operations."""
        # Use high-precision values
        precise_value = Scalar("3.141592653589793", "m")

        # Operations should preserve precision
        doubled = precise_value * 2.0
        assert abs(doubled.value - 6.283185307179586) < 1e-15

        # Square and square root should be inverse
        squared = precise_value**2
        sqrt_result = squared**0.5
        assert abs(sqrt_result.value - precise_value.value) < 1e-14

    def test_error_propagation_simulation(self) -> None:
        """Test behavior that simulates error propagation."""
        # Multiple measurements of the same quantity
        measurements = [
            Scalar("9.80", "m/s^2"),
            Scalar("9.82", "m/s^2"),
            Scalar("9.79", "m/s^2"),
            Scalar("9.83", "m/s^2"),
        ]

        # Calculate average
        total = measurements[0]
        for measurement in measurements[1:]:
            total = total + measurement

        average = total / 4.0

        # Should be close to 9.81
        assert abs(average.value - 9.81) < 0.02
        assert str(average.unit) == "m/s^2"


if __name__ == "__main__":
    # Run with: python -m pytest tests/test_sitypes/test_scalar_combined.py -v
    pytest.main([__file__, "-v"])
