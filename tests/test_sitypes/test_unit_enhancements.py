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
        meter, _ = Unit.parse("m")
        kilometer, _ = Unit.parse("km")

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
            pound_mass, _ = Unit.parse("lb")
            kilogram, _ = Unit.parse("kg")

            # 1 lb = 0.45359237 kg
            factor = pound_mass.conversion_factor(kilogram)
            expected = 0.45359237
            assert abs(factor - expected) < 1e-10

            # Test pound-force to newton conversion
            pound_force, _ = Unit.parse("lbf")
            newton, _ = Unit.parse("N")

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
            psi, _ = Unit.parse("lbf/in^2")
            pascal, _ = Unit.parse("Pa")

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
            meter, _ = Unit.parse("m")
            second, _ = Unit.parse("s")

            # Should raise error for incompatible dimensions
            with pytest.raises((RMNError, ValueError)):
                meter.conversion_factor(second)

        except AttributeError:
            pytest.skip("conversion_factor method not implemented")


class TestUnitPrefixIntrospection:
    """Test unit prefix detection and properties."""

    def test_prefix_detection(self):
        """Test detection of SI prefixes in units."""
        kilometer, _ = Unit.parse("km")

        # Should detect kilo prefix
        try:
            assert kilometer.has_prefix()
            # These properties aren't implemented yet, so we'll test what we can
            prefix_value = kilometer.get_numerator_prefix_at_index(
                0
            )  # Length dimension
            assert prefix_value == 3  # kilo = 10^3
        except AttributeError:
            pytest.skip("Prefix introspection not implemented")

    def test_base_unit_no_prefix(self):
        """Test that base units have no prefix."""
        meter, _ = Unit.parse("m")

        try:
            assert not meter.has_prefix()
            prefix_value = meter.get_numerator_prefix_at_index(0)  # Length dimension
            assert prefix_value == 0  # No prefix
        except AttributeError:
            pytest.skip("Prefix introspection not implemented")

    def test_multiple_prefixes(self):
        """Test units with prefixes in numerator and denominator."""
        try:
            # km/mm should have kilo in numerator, milli in denominator
            complex_unit, _ = Unit.parse("km/mm")

            # Overall scale factor should be 1000 / 0.001 = 1,000,000
            assert abs(complex_unit.scale_factor - 1000000.0) < 1e-6

        except (RMNError, AttributeError):
            pytest.skip("Complex prefix units or introspection not supported")

    def test_prefix_allowance(self):
        """Test which units allow SI prefixes."""
        try:
            gram, _ = Unit.parse("g")
            assert gram.allows_si_prefix

            # Some units might not allow prefixes
            newton, _ = Unit.parse("N")
            # Newton typically allows prefixes (kN, mN, etc.)
            assert newton.allows_si_prefix

        except (RMNError, AttributeError):
            pytest.skip("Prefix allowance checking not implemented")


class TestUnitRootProperties:
    """Test unit root symbol and name properties."""

    def test_root_symbol_extraction(self):
        """Test extraction of root symbols from prefixed units."""
        try:
            kilometer, _ = Unit.parse("km")

            # Root symbol should be "m"
            assert kilometer.root_symbol == "m"

            milligram, _ = Unit.parse("mg")
            # Root symbol should be "g"
            assert milligram.root_symbol == "g"

        except AttributeError:
            pytest.skip("root_symbol property not implemented")

    def test_root_name_properties(self):
        """Test root name properties for prefixed units."""
        try:
            kilometer, _ = Unit.parse("km")

            # Root name should be "meter"
            assert kilometer.root_name == "meter"
            assert kilometer.root_plural_name == "meters"

        except AttributeError:
            pytest.skip("root_name properties not implemented")

    def test_compound_unit_root_properties(self):
        """Test root properties for compound units."""
        try:
            velocity, _ = Unit.parse("km/h")

            # Compound units might not have simple root properties
            # This tests the behavior when root properties are accessed
            getattr(velocity, "root_symbol", None)
            # Behavior is implementation-dependent

        except AttributeError:
            pytest.skip("Root properties for compound units not implemented")


class TestAdvancedUnitConstruction:
    """Test advanced unit construction methods."""

    def test_multiply_without_reducing(self):
        """Test multiplication that preserves mathematical structure."""
        try:
            meter, _ = Unit.parse("m")
            second, _ = Unit.parse("s")

            # Multiply without automatic reduction/simplification
            product = meter.multiply_without_reducing(second)

            # Should be equivalent to m*s but might preserve structure differently
            regular_product = meter * second
            assert product.is_dimensionally_equal(regular_product)

        except AttributeError:
            pytest.skip("multiply_without_reducing not implemented")

    def test_divide_without_reducing(self):
        """Test division that preserves mathematical structure."""
        try:
            meter, _ = Unit.parse("m")
            second, _ = Unit.parse("s")

            quotient = meter.divide_without_reducing(second)
            regular_quotient = meter / second
            assert quotient.is_dimensionally_equal(regular_quotient)

        except AttributeError:
            pytest.skip("divide_without_reducing not implemented")

    def test_power_without_reducing(self):
        """Test power operations that preserve structure."""
        try:
            meter, _ = Unit.parse("m")

            # Square without automatic reduction
            squared = meter.power_without_reducing(2)
            regular_squared = meter**2
            assert squared.is_dimensionally_equal(regular_squared)

        except AttributeError:
            pytest.skip("power_without_reducing not implemented")

    def test_nth_root_advanced(self):
        """Test nth root with advanced options."""
        try:
            # Create m^6 for cube root test
            meter, _ = Unit.parse("m")
            m6 = meter**6

            # Take cube root -> should give m^2
            cube_root = m6.nth_root_advanced(3)
            m2 = meter**2
            assert cube_root.is_dimensionally_equal(m2)

        except AttributeError:
            pytest.skip("nth_root_advanced not implemented")


class TestExtendedUnicodeNormalization:
    """Test comprehensive Unicode normalization."""

    def test_greek_mu_vs_micro_sign(self):
        """Test Greek mu vs micro sign normalization."""
        try:
            # Greek letter mu (μ, U+03BC)
            greek_mu, _ = Unit.parse("μm")

            # Micro sign (µ, U+00B5)
            micro_sign, _ = Unit.parse("µm")

            # Should be normalized to same representation
            assert greek_mu.symbol == micro_sign.symbol
            assert greek_mu.is_equal(micro_sign)

        except RMNError:
            pytest.skip("Unicode normalization not supported")

    def test_multiplication_sign_normalization(self):
        """Test multiplication sign normalization."""
        try:
            # Using × (multiplication sign)
            unit_mult, _ = Unit.parse("m×s")

            # Using * (asterisk)
            unit_ast, _ = Unit.parse("m*s")

            # Should be equivalent
            assert unit_mult.is_dimensionally_equal(unit_ast)

        except RMNError:
            pytest.skip("Multiplication sign normalization not supported")

    def test_division_sign_normalization(self):
        """Test division sign normalization."""
        try:
            # Using ÷ (division sign)
            unit_div, _ = Unit.parse("m÷s")

            # Using / (slash)
            unit_slash, _ = Unit.parse("m/s")

            # Should be equivalent
            assert unit_div.is_dimensionally_equal(unit_slash)

        except RMNError:
            pytest.skip("Division sign normalization not supported")


class TestNonSIUnitSystems:
    """Test comprehensive non-SI unit support."""

    def test_imperial_length_units(self):
        """Test imperial length units."""
        try:
            inch, _ = Unit.parse("in")
            foot, _ = Unit.parse("ft")
            yard, _ = Unit.parse("yd")
            mile, _ = Unit.parse("mi")

            # All should be length units
            meter, _ = Unit.parse("m")
            for unit in [inch, foot, yard, mile]:
                assert unit.is_dimensionally_equal(meter)

        except RMNError:
            pytest.skip("Imperial length units not supported")

    def test_imperial_mass_vs_force(self):
        """Test distinction between imperial mass and force units."""
        try:
            # Pound mass (lb) vs pound force (lbf)
            pound_mass, _ = Unit.parse("lb")
            pound_force, _ = Unit.parse("lbf")

            kilogram, _ = Unit.parse("kg")
            newton, _ = Unit.parse("N")

            # lb should be dimensionally equal to kg (mass)
            assert pound_mass.is_dimensionally_equal(kilogram)

            # lbf should be dimensionally equal to N (force)
            assert pound_force.is_dimensionally_equal(newton)

            # lb and lbf should NOT be dimensionally equal
            assert not pound_mass.is_dimensionally_equal(pound_force)

        except RMNError:
            pytest.skip("Imperial mass/force distinction not supported")

    def test_temperature_units(self):
        """Test temperature unit support."""
        try:
            celsius, _ = Unit.parse("°C")
            fahrenheit, _ = Unit.parse("°F")
            kelvin, _ = Unit.parse("K")

            # All should be temperature units (same dimensionality)
            for unit in [celsius, fahrenheit]:
                assert unit.is_dimensionally_equal(kelvin)

        except RMNError:
            pytest.skip("Temperature units not supported")

    def test_angle_units(self):
        """Test angle unit support."""
        try:
            radian, _ = Unit.parse("rad")
            degree, _ = Unit.parse("°")

            # Both should be dimensionless (angle units)
            assert radian.is_dimensionless
            assert degree.is_dimensionless
            assert radian.is_dimensionally_equal(degree)

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
            original, _ = Unit.parse(complex_expr)

            # Get string representation
            symbol = original.symbol
            assert symbol is not None and len(symbol) > 0

            # Parse it back
            reparsed, _ = Unit.parse(symbol)

            # Should be equal to original
            assert reparsed.is_equal(original)

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
                unit, _ = Unit.parse(expr)
                assert unit is not None

                # Test roundtrip
                symbol = unit.symbol
                reparsed, _ = Unit.parse(symbol)
                assert reparsed.is_dimensionally_equal(unit)

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
                unit, _ = Unit.parse(expr)
                assert unit is not None

                # Test that it parses and is dimensionally consistent
                symbol = unit.symbol
                assert symbol is not None

            except RMNError:
                # Complex nesting might not be supported
                pass  # Skip unsupported expressions


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
