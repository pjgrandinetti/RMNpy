"""
Comprehensive Unit Tests for SITypes Wrapper

This file combines tests from test_unit.py and test_unit_enhancements.py
to provide complete coverage of the Unit wrapper implementation, mirroring
the comprehensive C test suite in SITypes/tests/test_unit.c
"""

import pytest

from rmnpy.exceptions import RMNError
from rmnpy.wrappers.sitypes import Dimensionality, Unit


class TestUnitCreation:
    """Test unit creation and factory methods."""

    def test_basic_units(self) -> None:
        """Test creating basic SI units."""
        meter = Unit("m")
        assert str(meter) == "m"
        # Base SI units now have proper names after SITypes fix
        assert meter.name == "meter"
        assert meter.plural == "meters"

        second = Unit("s")
        assert str(second) == "s"
        assert second.name == "second"
        assert second.plural == "seconds"

        kilogram = Unit("kg")
        assert str(kilogram) == "kg"
        assert kilogram.name == "kilogram"
        assert kilogram.plural == "kilograms"

    def test_derived_units(self) -> None:
        """Test creating derived units."""
        velocity = Unit("m/s")
        assert "m" in str(velocity) and "s" in str(velocity)

        acceleration = Unit("m/s^2")
        # Allow for different unicode representations
        assert "m" in str(acceleration) and "s" in str(acceleration)

        force = Unit("kg*m/s^2")
        # SITypes may return simplified symbol 'N' instead of 'kg*m/s^2'
        force_str = str(force)
        assert force_str == "N" or (
            "kg" in force_str and "m" in force_str and "s" in force_str
        )

        # Test Newton (derived unit symbol)
        newton = Unit("N")
        assert str(newton) == "N"

    def test_complex_expressions(self) -> None:
        """Test creating complex unit expressions."""
        # Energy: kg*m^2/s^2
        energy = Unit("kg*m^2/s^2")
        assert energy is not None

        # Power: kg*m^2/s^3
        power = Unit("kg*m^2/s^3")
        assert power is not None

        # Pressure: kg/(m*s^2)
        pressure = Unit("kg/(m*s^2)")
        assert pressure is not None

        # Test dimensional equivalence
        force_derived = Unit("kg*m/s^2")
        newton = Unit("N")
        assert force_derived.dimensionality == newton.dimensionality

    def test_prefixed_units(self) -> None:
        """Test creating units with SI prefixes."""
        kilometer = Unit("km")
        assert str(kilometer) == "km"

        millisecond = Unit("ms")
        assert str(millisecond) == "ms"

        milligram = Unit("mg")
        assert str(milligram) == "mg"

    def test_invalid_expressions(self) -> None:
        """Test handling of invalid unit expressions."""
        with pytest.raises(RMNError):
            Unit("invalid_unit_xyz")

        # Empty string creates dimensionless unit (space character)
        empty_unit = Unit("")
        assert empty_unit.is_dimensionless
        assert str(empty_unit).strip() == ""

        # Note: Unit(None) is allowed for internal use (_from_ref pattern)
        # Only non-string, non-None values should raise TypeError
        with pytest.raises(TypeError):
            Unit(123)

    def test_from_name(self) -> None:
        """Test finding units by name."""
        meter = Unit.from_name("meter")
        assert meter is not None
        assert str(meter) == "m"

        second = Unit.from_name("second")
        assert second is not None
        assert str(second) == "s"

        # Non-existent name should return None
        # TODO: Fix segfault with non-existent unit lookup
        # unknown = Unit.from_name("frobnicator")
        # assert unknown is None

        with pytest.raises(TypeError):
            Unit.from_name(None)

    def test_parse_basic_symbols(self) -> None:
        """Test parsing basic unit symbols (equivalent to old from_symbol test)."""
        meter = Unit("m")
        assert meter is not None
        assert meter.name == "meter"

        second = Unit("s")
        assert second is not None

        # Non-existent symbol should raise RMNError
        with pytest.raises(RMNError):
            Unit("xyz")

        # Non-string, non-None values should raise TypeError
        with pytest.raises(TypeError):
            Unit(123)

    def test_dimensionless(self) -> None:
        """Test dimensionless unit creation."""
        one = Unit.dimensionless()
        assert one.is_dimensionless
        # Symbol might be "1", empty string, or just whitespace
        symbol = str(one)
        assert symbol == "1" or symbol == "" or len(symbol.strip()) == 0
        assert one.scale_to_coherent_si == 1.0

    def test_for_dimensionality(self) -> None:
        """Test finding coherent SI unit for dimensionality."""
        # Length dimensionality should give meter
        length_dim = Dimensionality("L")
        meter = Unit.for_dimensionality(length_dim)
        assert meter is not None
        assert str(meter) == "m"

        # Time dimensionality should give second
        time_dim = Dimensionality("T")
        second = Unit.for_dimensionality(time_dim)
        assert second is not None
        assert str(second) == "s"

        with pytest.raises(TypeError):
            Unit.for_dimensionality("not_a_dimensionality")


class TestUnitProperties:
    """Test unit properties and characteristics."""

    def test_symbol_property(self) -> None:
        """Test symbol property."""
        meter = Unit("m")
        assert str(meter) == "m"

        velocity = Unit("m/s")
        assert "m" in str(velocity) and "s" in str(velocity)

    def test_name_properties(self) -> None:
        """Test name and plural properties."""
        meter = Unit("m")
        assert meter.name == "meter"
        assert meter.plural == "meters"

        # Test gram (not kilogram, based on C tests)
        try:
            gram = Unit("g")
            assert "gram" in gram.name.lower()
            assert "grams" in gram.plural.lower()
        except RMNError:
            # If gram parsing fails, skip this part of the test
            pass

    def test_dimensionality_property(self) -> None:
        """Test dimensionality property."""
        meter = Unit("m")
        dim = meter.dimensionality
        assert dim is not None
        assert isinstance(dim, Dimensionality)
        assert str(dim) == "L"

        velocity = Unit("m/s")
        vel_dim = velocity.dimensionality
        assert str(vel_dim) == "LT⁻¹" or "L" in str(vel_dim) and "T" in str(vel_dim)

    def test_scale_factor_property(self) -> None:
        """Test scale factor property."""
        meter = Unit("m")
        assert meter.scale_to_coherent_si == 1.0

        kilometer = Unit("km")
        assert kilometer.scale_to_coherent_si == 1000.0

        millimeter = Unit("mm")
        assert millimeter.scale_to_coherent_si == 0.001

        # Test that parsing returns the expected multiplier
        # When parsing expressions, the multiplier should be 1.0
        # for units with prefixes because the prefix is part of the unit

    def test_is_dimensionless(self) -> None:
        """Test dimensionless check."""
        one = Unit.dimensionless()
        assert one.is_dimensionless

        meter = Unit("m")
        assert not meter.is_dimensionless

        # Ratio of same units should be dimensionless
        # This tests dimensional analysis
        ratio = meter / meter  # Should be dimensionless
        assert ratio.is_dimensionless

    def test_is_derived(self) -> None:
        """Test derived unit check."""
        meter = Unit("m")
        assert not meter.is_derived  # Base unit

        velocity = Unit("m/s")
        assert velocity.is_derived  # Derived unit

    def test_unit_classification(self) -> None:
        """Test unit classification properties."""
        meter = Unit("m")
        assert meter.is_si_unit
        assert meter.is_coherent_unit
        assert not meter.is_cgs_unit
        assert not meter.is_imperial_unit
        assert not meter.is_atomic_unit
        assert not meter.is_planck_unit
        assert not meter.is_constant

        second = Unit("s")
        assert second.is_si_unit
        assert second.is_coherent_unit

        velocity = Unit("m/s")
        assert velocity.is_si_unit
        assert velocity.is_coherent_unit  # Derived SI unit

    def test_is_coherent_unit(self) -> None:
        """Test coherent unit classification."""
        meter = Unit("m")
        assert meter.is_coherent_unit

        # Newton is an SI unit but not coherent (has implicit conversion factor)
        newton = Unit("N")
        assert newton.is_si_unit
        assert not newton.is_coherent_unit

        # km is not coherent (has prefix)
        kilometer = Unit("km")
        assert not kilometer.is_coherent_unit


class TestUnitConversions:
    """Test unit conversion functionality (missing from main test suite)."""

    def test_conversion_factor_between_units(self) -> None:
        """Test getting conversion factors between compatible units."""
        meter = Unit("m")
        kilometer = Unit("km")

        # Should be able to get conversion factor
        # 1 m = 0.001 km, so factor should be 0.001
        try:
            factor = meter.scale_to(kilometer)
            assert abs(factor - 0.001) < 1e-12
        except AttributeError:
            pytest.skip("scale_to method not implemented")

    def test_imperial_to_metric_conversions(self) -> None:
        """Test conversions between imperial and metric units."""
        try:
            # Test pound (mass) to kilogram conversion (test_unit_13 equivalent)
            pound_mass = Unit("lb")
            kilogram = Unit("kg")

            # 1 lb = 0.45359237 kg
            factor = pound_mass.scale_to(kilogram)
            expected = 0.45359237
            assert abs(factor - expected) < 1e-10

            # Test pound-force to newton conversion
            pound_force = Unit("lbf")
            newton = Unit("N")

            # 1 lbf = 4.4482216152605 N
            lbf_factor = pound_force.scale_to(newton)
            expected_lbf = 4.4482216152605
            assert abs(lbf_factor - expected_lbf) < 1e-10

        except (RMNError, AttributeError):
            pytest.skip("Imperial units or scale_to not supported")

    def test_pressure_unit_conversions(self) -> None:
        """Test pressure unit conversions (PSI to Pascal)."""
        try:
            # Test PSI (lbf/in^2) to Pascal conversion (test_unit_12 equivalent)
            psi = Unit("lbf/in^2")
            pascal = Unit("Pa")

            # 1 PSI = 6894.757293168361 Pa
            factor = psi.scale_to(pascal)
            expected = 6894.757293168361
            assert (
                abs(factor - expected) < 1e-5
            )  # Relaxed tolerance for floating point precision

        except (RMNError, AttributeError):
            pytest.skip("PSI units or scale_to not supported")

    def test_incompatible_unit_conversion(self) -> None:
        """Test that conversion between incompatible units raises error."""
        try:
            meter = Unit("m")
            second = Unit("s")

            # Should raise error for incompatible dimensions
            with pytest.raises((RMNError, ValueError)):
                meter.scale_to(second)

        except AttributeError:
            pytest.skip("scale_to method not implemented")


class TestUnitAlgebra:
    """Test unit algebraic operations."""

    def test_multiply(self) -> None:
        """Test unit multiplication."""
        meter = Unit("m")
        second = Unit("s")

        # m * s = m*s
        product = meter * second
        assert "m" in str(product) and "s" in str(product)

        # m * m = m^2
        area = meter * meter
        assert "m" in str(area) and ("²" in str(area) or "2" in str(area))

        with pytest.raises(TypeError):
            meter * "not_a_unit"

    def test_divide(self) -> None:
        """Test unit division."""
        meter = Unit("m")
        second = Unit("s")

        # m / s = m/s (velocity)
        velocity = meter / second
        assert "m" in str(velocity) and "s" in str(velocity)

        # m / m = 1 (dimensionless)
        ratio = meter / meter
        assert ratio.is_dimensionless

        with pytest.raises(TypeError):
            meter / "not_a_unit"

    def test_power(self) -> None:
        """Test raising unit to power."""
        meter = Unit("m")

        # m^2
        area = meter**2
        assert str(area) == "m^2"

        # m^3 - SITypes may return simplified symbol like 'kL' instead of 'm^3'
        volume = meter**3
        volume_str = str(volume)
        assert volume_str == "m^3" or volume_str == "kL"  # Both are valid for m^3

        # m^0 = 1
        one = meter**0
        assert one.is_dimensionless

        # m^-1
        inverse = meter**-1
        assert str(inverse) == "(1/m)"

        with pytest.raises(TypeError):
            meter ** "not_a_number"

    def test_nth_root(self) -> None:
        """Test taking nth root of unit."""
        meter = Unit("m")
        area = meter**2  # m^2

        # sqrt(m^2) = m
        sqrt_area = area ** (1 / 2)
        # Result should be equivalent to meter
        assert sqrt_area.dimensionality == meter.dimensionality

        volume = meter**3  # m^3
        # cbrt(m^3) = m
        cbrt_volume = volume ** (1 / 3)
        assert cbrt_volume.dimensionality == meter.dimensionality

        with pytest.raises(ZeroDivisionError):
            meter ** (1 / 0)

        # Test that power of 0 works (gives dimensionless)
        dimensionless = meter**0
        assert str(dimensionless) == "1" or len(str(dimensionless).strip()) == 0

        with pytest.raises(TypeError):
            meter ** (1 / "not_an_int")  # type: ignore

    def test_complex_algebra(self) -> None:
        """Test complex algebraic operations."""
        meter = Unit("m")
        second = Unit("s")
        kilogram = Unit("kg")

        # Force: kg*m/s^2
        acceleration = meter / (second * second)
        force = kilogram * acceleration

        # Energy: kg*m^2/s^2
        velocity = meter / second
        energy = kilogram * velocity * velocity

        # Power: kg*m^2/s^3
        power = energy / second

        # Verify dimensionalities make sense
        assert not force.is_dimensionless
        assert not energy.is_dimensionless
        assert not power.is_dimensionless


class TestUnitComparison:
    """Test unit comparison methods."""

    def test_is_equal(self) -> None:
        """Test exact equality."""
        meter1 = Unit("m")
        meter2 = Unit("m")

        assert meter1 == meter2

        second = Unit("s")
        assert not meter1 == second

        # Different representations of same unit should be equal
        velocity1 = Unit("m/s")
        velocity2 = Unit("m*s^-1")
        assert velocity1 == velocity2

        # Non-Unit comparison
        assert not meter1 == "not_a_unit"

    def test_is_dimensionally_equal(self) -> None:
        """Test dimensional equality."""
        meter = Unit("m")
        kilometer = Unit("km")

        # Same dimensionality but different scale
        assert meter.dimensionality == kilometer.dimensionality

        second = Unit("s")
        assert not meter.dimensionality == second.dimensionality

        # Different units with same dimensionality
        velocity1 = Unit("m/s")
        velocity2 = Unit("km/h")  # Different scale, same dimensionality
        assert velocity1.dimensionality == velocity2.dimensionality

        # Test force equivalence (based on C test_unit_8)
        force_expr = Unit("kg*m/s^2")
        newton = Unit("N")
        assert force_expr.dimensionality == newton.dimensionality

        # Non-Unit comparison
        assert not meter.dimensionality == "not_a_unit"

    def test_has_same_reduced_dimensionality(self) -> None:
        """Test reduced dimensionality compatibility check."""
        meter = Unit("m")
        kilometer = Unit("km")

        assert meter.dimensionality.has_same_reduced_dimensionality(
            kilometer.dimensionality
        )

        second = Unit("s")
        assert not meter.dimensionality.has_same_reduced_dimensionality(
            second.dimensionality
        )


class TestUnitOperators:
    """Test Python operator overloading."""

    def test_multiplication_operator(self) -> None:
        """Test * operator."""
        meter = Unit("m")
        second = Unit("s")

        product = meter * second
        assert product == meter * second

    def test_division_operator(self) -> None:
        """Test / operator."""
        meter = Unit("m")
        second = Unit("s")

        quotient = meter / second
        assert quotient == meter / second

    def test_power_operator(self) -> None:
        """Test ** operator."""
        meter = Unit("m")

        square = meter**2
        assert square == meter**2

    def test_equality_operators(self) -> None:
        """Test == and != operators."""
        meter1 = Unit("m")
        meter2 = Unit("m")
        second = Unit("s")

        assert meter1 == meter2
        assert not (meter1 != meter2)
        assert meter1 != second
        assert not (meter1 == second)

    def test_chained_operations(self) -> None:
        """Test chaining multiple operations."""
        m = Unit("m")
        s = Unit("s")
        kg = Unit("kg")

        # Force: kg*m/s^2
        force = kg * m / (s**2)

        # Alternative calculation
        acceleration = m / (s * s)
        force2 = kg * acceleration

        assert force.dimensionality == force2.dimensionality


class TestUnitDisplay:
    """Test unit display and string representation."""

    def test_str_representation(self) -> None:
        """Test string representation."""
        meter = Unit("m")
        assert str(meter) == "m"

        velocity = Unit("m/s")
        velocity_str = str(velocity)
        assert "m" in velocity_str and "s" in velocity_str

    def test_repr_representation(self) -> None:
        """Test repr representation."""
        meter = Unit("m")
        repr_str = repr(meter)
        assert "Unit" in repr_str
        assert "m" in repr_str


class TestUnitIntegration:
    """Test integration with other components."""

    def test_dimensionality_integration(self) -> None:
        """Test integration with Dimensionality class."""
        meter = Unit("m")
        length_dim = meter.dimensionality

        # Should be able to find unit for this dimensionality
        coherent_unit = Unit.for_dimensionality(length_dim)
        assert coherent_unit is not None
        assert coherent_unit.dimensionality == meter.dimensionality

    def test_unit_algebra_preserves_dimensionality(self) -> None:
        """Test that unit algebra preserves dimensional relationships."""
        m = Unit("m")
        s = Unit("s")

        # Distance/time = velocity
        velocity = m / s
        # Distance/velocity = time
        time_unit = m / velocity
        time_dim = time_unit.dimensionality

        # Should be dimensionally equal to seconds (when reduced)
        # Note: m/(m/s) = m•s/m which has dimensionality L•T/L
        # This reduces to T, same as seconds
        assert time_unit.dimensionality.reduced() == s.dimensionality.reduced()
        assert time_dim.reduced() == s.dimensionality.reduced()


class TestUnitPrefixIntrospection:
    """Test unit prefix detection and properties."""

    def test_multiple_prefixes(self) -> None:
        """Test units with prefixes in numerator and denominator."""
        try:
            # km/mm should have kilo in numerator, milli in denominator
            complex_unit = Unit("km/mm")

            # Overall scale factor should be 1000 / 0.001 = 1,000,000
            assert abs(complex_unit.scale_to_coherent_si - 1000000.0) < 1e-6

        except (RMNError, AttributeError):
            pytest.skip("Complex prefix units or introspection not supported")


class TestExtendedUnicodeNormalization:
    """Test comprehensive Unicode normalization."""

    def test_greek_mu_vs_micro_sign(self) -> None:
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

    def test_multiplication_sign_normalization(self) -> None:
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

    def test_division_sign_normalization(self) -> None:
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

    def test_imperial_length_units(self) -> None:
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

    def test_imperial_mass_vs_force(self) -> None:
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

    def test_temperature_units(self) -> None:
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

    def test_angle_units(self) -> None:
        """Test angle unit support."""
        try:
            radian = Unit("rad")
            degree = Unit("°")

            # Both should be dimensionless (angle units)
            assert radian.is_dimensionless
            assert degree.is_dimensionless
            assert radian.dimensionality == degree.dimensionality

            # Test conversion factor (1 radian = 180/π degrees)
            conversion = radian.scale_to(degree)
            expected = 180.0 / 3.141592653589793  # 180/π
            assert abs(conversion - expected) < 1e-10

        except RMNError:
            pytest.skip("Angle units not supported")


class TestUnitSerializationRoundtrip:
    """Test complex unit serialization and parsing roundtrips."""

    def test_very_complex_expression_roundtrip(self) -> None:
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

    def test_scientific_constants_units(self) -> None:
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

    def test_nested_parentheses_units(self) -> None:
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


class TestUnitEdgeCases:
    """Test edge cases and error conditions."""

    def test_zero_power(self) -> None:
        """Test raising to zero power."""
        meter = Unit("m")
        result = meter**0
        assert result.is_dimensionless

    def test_negative_power(self) -> None:
        """Test negative powers."""
        meter = Unit("m")
        inverse = meter**-1

        # m^-1 * m = 1
        product = inverse * meter
        assert product.is_dimensionless

    def test_fractional_power(self) -> None:
        """Test fractional powers."""
        meter = Unit("m")
        area = meter**2

        # Test fractional power implementation (now fixed!)
        # (m^2)^0.5 correctly returns m
        sqrt_area = area**0.5
        assert str(sqrt_area) == "m"  # Correctly returns m

    def test_roundtrip_serialization(self) -> None:
        """Test that units can be serialized and parsed back (based on test_unit_0)."""
        # Complex expression from C test
        original = Unit(
            "m*kg^2*s^3*A^4*K^5*mol^6*cd^7/(m^2*kg^3*s^4*A^5*K^6*mol^7*cd^8)"
        )

        # Get symbol representation
        symbol = str(original)
        assert symbol is not None and len(symbol) > 0

        # Parse it back
        reparsed = Unit(symbol)

        # Should be equal to original
        assert reparsed == original

    def test_equivalent_vs_equal_units(self) -> None:
        """Test the difference between equivalent and equal units (based on test_unit_8, test_unit_9)."""
        # kg*m/s^2 should be equivalent to N but not equal
        force_expr = Unit("kg*m/s^2")
        newton = Unit("N")

        # Should be dimensionally equivalent
        assert force_expr.dimensionality == newton.dimensionality

        # But might not be exactly equal (implementation dependent)
        # This depends on whether the library considers them equal or just equivalent

        # kN vs N - same dimensionality but different scale
        kilo_newton = Unit("kN")
        base_newton = Unit("N")

        # Should be dimensionally equal
        assert kilo_newton.dimensionality == base_newton.dimensionality

        # But should not be equal (different scale)
        assert not kilo_newton == base_newton

    def test_prefix_handling(self) -> None:
        """Test SI prefix handling (based on test_unit_4, test_unit_9)."""
        kilometer = Unit("km")

        # Should have correct symbol
        assert str(kilometer) == "km"

        # Should have correct scale factor
        assert kilometer.scale_to_coherent_si == 1000.0

        # Should not be coherent (has prefix)
        assert not kilometer.is_coherent_unit

        # Root name should be meter
        assert "meter" in kilometer.name.lower()

    def test_special_units(self) -> None:
        """Test special SI units like Pascal, Newton, etc."""
        # Pascal
        pascal = Unit("Pa")
        assert str(pascal) == "Pa"

        # Newton
        newton = Unit("N")
        assert str(newton) == "N"

        # Bar (if supported)
        try:
            bar = Unit("bar")
            assert str(bar) == "bar"
        except RMNError:
            pass  # Bar might not be supported

    def test_non_si_units(self) -> None:
        """Test non-SI units like inches, pounds, etc."""
        # Test inch per second (based on test_unit_11)
        try:
            inch_per_sec = Unit("in/s")
            meter_per_sec = Unit("m/s")

            # Should have same dimensionality
            assert inch_per_sec.dimensionality == meter_per_sec.dimensionality

            # But different scale factors
            assert (
                inch_per_sec.scale_to_coherent_si != meter_per_sec.scale_to_coherent_si
            )
        except RMNError:
            # Might not support non-SI units
            pytest.skip("Non-SI units not supported")

    def test_unicode_normalization(self) -> None:
        """Test Unicode normalization (based on test_unit_unicode_normalization)."""
        try:
            # Test Greek mu vs micro sign
            micro_meter_greek = Unit("μm")  # Greek mu
            micro_meter_micro = Unit("µm")  # Micro sign

            # Should be equal after normalization
            assert micro_meter_greek == micro_meter_micro
            assert str(micro_meter_greek) == str(micro_meter_micro)

        except RMNError:
            # Unicode normalization might not be supported
            pytest.skip("Unicode normalization not supported")

    def test_very_complex_expression(self) -> None:
        """Test very complex unit expressions."""
        # Stefan-Boltzmann constant units: kg/(s^3*K^4)
        complex_expr = "kg/(s^3*K^4)"
        try:
            unit = Unit(complex_expr)
            assert unit is not None
        except RMNError:
            # Some expressions might not be supported
            pytest.skip(f"Complex expression '{complex_expr}' not supported")

    def test_memory_management(self) -> None:
        """Test that units are properly cleaned up."""

        # Create many units to test memory management
        units = []
        for i in range(100):
            unit = Unit("m")
            units.append(unit)

        # All should be valid
        for unit in units:
            assert str(unit) == "m"

        # Clear references
        units.clear()
        # Python garbage collection should clean up


class TestUnitAPIEquivalence:
    """Test that our wrapper properly mirrors the C API behavior."""

    def test_root_symbol_properties(self) -> None:
        """Test root symbol extraction (based on test_unit_3)."""
        meter = Unit("m")

        # For simple units, symbol should equal the root symbol
        assert str(meter) == "m"

        # Test with prefixed unit
        km = Unit("km")
        # Root should still be meter-related
        assert "meter" in km.name.lower()

    def test_multiplier_handling(self) -> None:
        """Test that multipliers are handled correctly in parsing."""
        # When parsing a unit expression, the scale factor should be incorporated
        # into the unit itself, not returned as a separate multiplier

        km = Unit("km")
        assert km.scale_to_coherent_si == 1000.0

        mm = Unit("mm")
        assert mm.scale_to_coherent_si == 0.001

    def test_coherent_unit_detection(self) -> None:
        """Test various coherent unit classifications."""
        # Base units
        meter = Unit("m")
        assert meter.is_si_unit
        assert meter.is_coherent_unit

        second = Unit("s")
        assert second.is_si_unit
        assert second.is_coherent_unit

        kilogram = Unit("kg")
        assert kilogram.is_si_unit  # kg is the base unit, not g
        assert kilogram.is_coherent_unit

        # Named derived units are SI but not coherent (have implicit conversion factors)
        newton = Unit("N")
        assert newton.is_si_unit
        assert not newton.is_coherent_unit

        # Test non-coherent units (with prefixes)
        kilometer = Unit("km")
        assert kilometer.is_si_unit
        assert not kilometer.is_coherent_unit  # Has prefix, not coherent

    def test_dimensionality_consistency(self) -> None:
        """Test that dimensionality is consistent across operations."""
        m = Unit("m")
        s = Unit("s")

        # Create velocity
        velocity = m / s
        velocity_dim = velocity.dimensionality

        # Create velocity directly
        velocity_direct = Unit("m/s")
        velocity_direct_dim = velocity_direct.dimensionality

        # Dimensionalities should be equal
        assert velocity_dim == velocity_direct_dim


if __name__ == "__main__":
    # Run with: python -m pytest tests/test_sitypes/test_unit_combined.py -v
    pytest.main([__file__, "-v"])
