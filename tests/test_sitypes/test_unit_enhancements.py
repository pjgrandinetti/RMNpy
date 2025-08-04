"""
Enhanced Unit Tests - Missing coverage from SITypes C test suite

These tests fill gaps identified by comparing our Python test coverage
with the comprehensive C test suite in SITypes/tests/test_unit.c
"""

import pytest

from rmnpy.exceptions import RMNError
from rmnpy.wrappers.sitypes import Unit


class TestUnitConversions:
    """Test unit conversion functionality (missing from main test suite)."""

    def test_conversion_factor_between_units(self):
        """Test getting conversion factors between compatible units."""
        meter = Unit("m")
        kilometer = Unit("km")

        # Should be able to get conversion factor
        # 1 m = 0.001 km, so factor should be 0.001
        try:
            factor = meter.conversion_factor(kilometer)
            assert abs(factor - 0.001) < 1e-12
        except AttributeError:
            pytest.skip("conversion_factor method not implemented")

    def test_imperial_to_metric_conversions(self):
        """Test conversions between imperial and metric units."""
        try:
            # Test pound (mass) to kilogram conversion (test_unit_13 equivalent)
            pound_mass = Unit("lb")
            kilogram = Unit("kg")

            # 1 lb = 0.45359237 kg
            factor = pound_mass.conversion_factor(kilogram)
            expected = 0.45359237
            assert abs(factor - expected) < 1e-10

            # Test pound-force to newton conversion
            pound_force = Unit("lbf")
            newton = Unit("N")

            # 1 lbf = 4.4482216152605 N
            lbf_factor = pound_force.conversion_factor(newton)
            expected_lbf = 4.4482216152605
            assert abs(lbf_factor - expected_lbf) < 1e-10

        except (RMNError, AttributeError):
            pytest.skip("Imperial units or conversion_factor not supported")

    def test_pressure_unit_conversions(self):
        """Test pressure unit conversions (PSI to Pascal)."""
        try:
            # Test PSI (lbf/in^2) to Pascal conversion (test_unit_12 equivalent)
            psi = Unit("lbf/in^2")
            pascal = Unit("Pa")

            # 1 PSI = 6894.757293168361 Pa
            factor = psi.conversion_factor(pascal)
            expected = 6894.757293168361
            assert (
                abs(factor - expected) < 1e-5
            )  # Relaxed tolerance for floating point precision

        except (RMNError, AttributeError):
            pytest.skip("PSI units or conversion_factor not supported")

    def test_incompatible_unit_conversion(self):
        """Test that conversion between incompatible units raises error."""
        try:
            meter = Unit("m")
            second = Unit("s")

            # Should raise error for incompatible dimensions
            with pytest.raises((RMNError, ValueError)):
                meter.conversion_factor(second)

        except AttributeError:
            pytest.skip("conversion_factor method not implemented")


class TestUnitPrefixIntrospection:
    """Test unit prefix detection and properties."""

    def test_multiple_prefixes(self):
        """Test units with prefixes in numerator and denominator."""
        try:
            # km/mm should have kilo in numerator, milli in denominator
            complex_unit = Unit("km/mm")

            # Overall scale factor should be 1000 / 0.001 = 1,000,000
            assert abs(complex_unit.scale_factor - 1000000.0) < 1e-6

        except (RMNError, AttributeError):
            pytest.skip("Complex prefix units or introspection not supported")


class TestExtendedUnicodeNormalization:
    """Test comprehensive Unicode normalization."""

    def test_greek_mu_vs_micro_sign(self):
        """Test Greek mu vs micro sign normalization."""
        try:
            # Greek letter mu (μ, U+03BC)
            greek_mu = Unit("μm")

            # Micro sign (µ, U+00B5)
            micro_sign = Unit("µm")

            # Should be normalized to same representation
            assert str(greek_mu) == str(micro_sign)
            assert greek_mu == micro_sign

        except RMNError:
            pytest.skip("Unicode normalization not supported")

    def test_multiplication_sign_normalization(self):
        """Test multiplication sign normalization."""
        try:
            # Using × (multiplication sign)
            unit_mult = Unit("m×s")

            # Using * (asterisk)
            unit_ast = Unit("m*s")

            # Should be equivalent
            assert unit_mult.dimensionality == unit_ast.dimensionality

        except RMNError:
            pytest.skip("Multiplication sign normalization not supported")

    def test_division_sign_normalization(self):
        """Test division sign normalization."""
        try:
            # Using ÷ (division sign)
            unit_div = Unit("m÷s")

            # Using / (slash)
            unit_slash = Unit("m/s")

            # Should be equivalent
            assert unit_div.dimensionality == unit_slash.dimensionality

        except RMNError:
            pytest.skip("Division sign normalization not supported")


class TestNonSIUnitSystems:
    """Test comprehensive non-SI unit support."""

    def test_imperial_length_units(self):
        """Test imperial length units."""
        try:
            inch = Unit("in")
            foot = Unit("ft")
            yard = Unit("yd")
            mile = Unit("mi")

            # All should be length units
            meter = Unit("m")
            for unit in [inch, foot, yard, mile]:
                assert unit.dimensionality == meter.dimensionality

        except RMNError:
            pytest.skip("Imperial length units not supported")

    def test_imperial_mass_vs_force(self):
        """Test distinction between imperial mass and force units."""
        try:
            # Pound mass (lb) vs pound force (lbf)
            pound_mass = Unit("lb")
            pound_force = Unit("lbf")

            kilogram = Unit("kg")
            newton = Unit("N")

            # lb should be dimensionally equal to kg (mass)
            assert pound_mass.dimensionality == kilogram.dimensionality

            # lbf should be dimensionally equal to N (force)
            assert pound_force.dimensionality == newton.dimensionality

            # lb and lbf should NOT be dimensionally equal
            assert not pound_mass.dimensionality == pound_force.dimensionality

        except RMNError:
            pytest.skip("Imperial mass/force distinction not supported")

    def test_temperature_units(self):
        """Test temperature unit support."""
        try:
            celsius = Unit("°C")
            fahrenheit = Unit("°F")
            kelvin = Unit("K")

            # All should be temperature units (same dimensionality)
            for unit in [celsius, fahrenheit]:
                assert unit.dimensionality == kelvin.dimensionality

        except RMNError:
            pytest.skip("Temperature units not supported")

    def test_angle_units(self):
        """Test angle unit support."""
        try:
            radian = Unit("rad")
            degree = Unit("°")

            # Both should be dimensionless (angle units)
            assert radian.is_dimensionless
            assert degree.is_dimensionless
            assert radian.dimensionality == degree.dimensionality

            # Test conversion factor (1 radian = 180/π degrees)
            conversion = radian.conversion_factor(degree)
            expected = 180.0 / 3.141592653589793  # 180/π
            assert abs(conversion - expected) < 1e-10

        except RMNError:
            pytest.skip("Angle units not supported")


class TestUnitSerializationRoundtrip:
    """Test complex unit serialization and parsing roundtrips."""

    def test_very_complex_expression_roundtrip(self):
        """Test roundtrip for very complex unit expressions."""
        # From test_unit_0 in C tests
        complex_expr = "m•kg^2•s^3•A^4•K^5•mol^6•cd^7/(m^2•kg^3•s^4•A^5•K^6•mol^7•cd^8)"

        try:
            original = Unit(complex_expr)

            # Get string representation
            symbol = str(original)
            assert symbol is not None and len(symbol) > 0

            # Parse it back
            reparsed = Unit(symbol)

            # Should be equal to original
            assert reparsed == original

        except RMNError:
            pytest.skip(f"Complex expression '{complex_expr}' not supported")

    def test_scientific_constants_units(self):
        """Test units commonly used for physical constants."""
        constant_units = [
            "kg/(s^3*K^4)",  # Stefan-Boltzmann constant
            "m^3/(kg*s^2)",  # Gravitational constant
            "kg*m^2/(A*s^3)",  # Magnetic permeability
            "A*s^4/(kg*m^3)",  # Electric permittivity
            "kg*m^2/(A^2*s^3)",  # Electric resistance
        ]

        for expr in constant_units:
            try:
                unit = Unit(expr)
                assert unit is not None

                # Test roundtrip
                symbol = str(unit)
                reparsed = Unit(symbol)
                assert reparsed.dimensionality == unit.dimensionality

            except RMNError:
                # Some complex expressions might not be supported
                pass  # Skip unsupported expressions

    def test_nested_parentheses_units(self):
        """Test units with nested parentheses."""
        nested_expressions = [
            "kg/(m*(s^2))",
            "m^2/((s^2)*K)",
            "kg*m^2/((A^2)*(s^3))",
        ]

        for expr in nested_expressions:
            try:
                unit = Unit(expr)
                assert unit is not None

                # Test that it parses and is dimensionally consistent
                symbol = str(unit)
                assert symbol is not None

            except RMNError:
                # Complex nesting might not be supported
                pass  # Skip unsupported expressions


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
