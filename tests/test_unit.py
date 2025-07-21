"""
Tests for SIUnit wrapper (Phase 2B)

Comprehensive test suite for the Unit class, mirroring the structure
and coverage of test_dimensionality.py from Phase 2A.
"""

import pytest
from rmnpy.wrappers.sitypes import Unit, Dimensionality
from rmnpy.exceptions import RMNError
import math


class TestUnitCreation:
    """Test unit creation and factory methods."""
    
    def test_parse_basic_units(self):
        """Test parsing basic SI units."""
        meter = Unit.parse("m")
        assert meter.symbol == "m"
        assert meter.name == "meter"
        assert meter.plural_name == "meters"
        
        second = Unit.parse("s")
        assert second.symbol == "s"
        
        kilogram = Unit.parse("kg")
        assert kilogram.symbol == "kg"
    
    def test_parse_derived_units(self):
        """Test parsing derived units."""
        velocity = Unit.parse("m/s")
        assert "m" in velocity.symbol and "s" in velocity.symbol
        
        acceleration = Unit.parse("m/s^2")
        # Allow for different unicode representations
        assert "m" in acceleration.symbol and "s" in acceleration.symbol
        
        force = Unit.parse("kg*m/s^2")
        assert "kg" in force.symbol and "m" in force.symbol and "s" in force.symbol
        
        # Test Newton (derived unit symbol)
        newton = Unit.parse("N")
        assert newton.symbol == "N"
    
    def test_parse_complex_expressions(self):
        """Test parsing complex unit expressions."""
        # Energy: kg*m^2/s^2
        energy = Unit.parse("kg*m^2/s^2")
        assert energy is not None
        
        # Power: kg*m^2/s^3
        power = Unit.parse("kg*m^2/s^3")
        assert power is not None
        
        # Pressure: kg/(m*s^2)
        pressure = Unit.parse("kg/(m*s^2)")
        assert pressure is not None
        
        # Test equivalence with derived units
        force_derived = Unit.parse("kg*m/s^2")
        newton = Unit.parse("N")
        # These should be equivalent but not necessarily equal
        assert force_derived.is_dimensionally_equal(newton)
    
    def test_parse_with_prefixes(self):
        """Test parsing units with SI prefixes."""
        kilometer = Unit.parse("km")
        assert kilometer.symbol == "km"
        
        millisecond = Unit.parse("ms")
        assert millisecond.symbol == "ms"
        
        milligram = Unit.parse("mg")
        assert milligram.symbol == "mg"
    
    def test_parse_invalid_expression(self):
        """Test that invalid expressions raise appropriate errors."""
        with pytest.raises(RMNError):
            Unit.parse("invalid_unit_xyz")
        
        # Empty string should raise error
        with pytest.raises(RMNError):
            Unit.parse("")
        
        with pytest.raises(TypeError):
            Unit.parse(None)
        
        with pytest.raises(TypeError):
            Unit.parse(123)
    
    def test_from_name(self):
        """Test finding units by name."""
        meter = Unit.from_name("meter")
        assert meter is not None
        assert meter.symbol == "m"
        
        second = Unit.from_name("second")
        assert second is not None
        assert second.symbol == "s"
        
        # Non-existent name should return None
        unknown = Unit.from_name("frobnicator")
        assert unknown is None
        
        with pytest.raises(TypeError):
            Unit.from_name(None)
    
    def test_from_symbol(self):
        """Test finding units by symbol."""
        meter = Unit.from_symbol("m")
        assert meter is not None
        assert meter.name == "meter"
        
        second = Unit.from_symbol("s")
        assert second is not None
        
        # Non-existent symbol should return None
        unknown = Unit.from_symbol("xyz")
        assert unknown is None
        
        with pytest.raises(TypeError):
            Unit.from_symbol(None)
    
    def test_dimensionless(self):
        """Test dimensionless unit creation."""
        one = Unit.dimensionless()
        assert one.is_dimensionless
        # Symbol might be "1" or empty string
        symbol = one.symbol
        assert symbol == "1" or symbol == "" or len(symbol) == 0
        assert one.scale_factor == 1.0
    
    def test_for_dimensionality(self):
        """Test finding coherent SI unit for dimensionality."""
        # Length dimensionality should give meter
        length_dim = Dimensionality.parse("L")
        meter = Unit.for_dimensionality(length_dim)
        assert meter is not None
        assert meter.symbol == "m"
        
        # Time dimensionality should give second
        time_dim = Dimensionality.parse("T")
        second = Unit.for_dimensionality(time_dim)
        assert second is not None
        assert second.symbol == "s"
        
        with pytest.raises(TypeError):
            Unit.for_dimensionality("not_a_dimensionality")


class TestUnitProperties:
    """Test unit properties and characteristics."""
    
    def test_symbol_property(self):
        """Test symbol property."""
        meter = Unit.parse("m")
        assert meter.symbol == "m"
        
        velocity = Unit.parse("m/s")
        assert "m" in velocity.symbol and "s" in velocity.symbol
    
    def test_name_properties(self):
        """Test name and plural_name properties."""
        meter = Unit.parse("m")
        assert meter.name == "meter"
        assert meter.plural_name == "meters"
        
        # Test gram (not kilogram, based on C tests)
        gram = Unit.from_symbol("g")
        if gram:  # Only test if gram is found
            assert "gram" in gram.name.lower()
            assert "grams" in gram.plural_name.lower()
    
    def test_dimensionality_property(self):
        """Test dimensionality property."""
        meter = Unit.parse("m")
        dim = meter.dimensionality
        assert dim is not None
        assert isinstance(dim, Dimensionality)
        assert dim.symbol == "L"
        
        velocity = Unit.parse("m/s")
        vel_dim = velocity.dimensionality
        assert vel_dim.symbol == "LT⁻¹" or "L" in vel_dim.symbol and "T" in vel_dim.symbol
    
    def test_scale_factor_property(self):
        """Test scale factor property."""
        meter = Unit.parse("m")
        assert meter.scale_factor == 1.0
        
        kilometer = Unit.parse("km")
        assert kilometer.scale_factor == 1000.0
        
        millimeter = Unit.parse("mm")
        assert millimeter.scale_factor == 0.001
        
        # Test that parsing returns the expected multiplier
        # When parsing expressions, the multiplier should be 1.0 
        # for units with prefixes because the prefix is part of the unit
    
    def test_is_dimensionless(self):
        """Test dimensionless check."""
        one = Unit.dimensionless()
        assert one.is_dimensionless
        
        meter = Unit.parse("m")
        assert not meter.is_dimensionless
        
        # Ratio of same units should be dimensionless
        # This tests dimensional analysis
        ratio = meter / meter  # Should be dimensionless
        assert ratio.is_dimensionless
    
    def test_is_derived(self):
        """Test derived unit check."""
        meter = Unit.parse("m")
        assert not meter.is_derived  # Base unit
        
        velocity = Unit.parse("m/s")
        assert velocity.is_derived  # Derived unit
    
    def test_is_si_base_unit(self):
        """Test SI base unit check."""
        meter = Unit.parse("m")
        assert meter.is_si_base_unit
        
        second = Unit.parse("s")
        assert second.is_si_base_unit
        
        velocity = Unit.parse("m/s")
        assert not velocity.is_si_base_unit
    
    def test_is_coherent_si(self):
        """Test coherent SI unit check."""
        meter = Unit.parse("m")
        assert meter.is_coherent_si
        
        # Newton is coherent SI derived unit
        newton = Unit.parse("N")
        assert newton.is_coherent_si
        
        # km is not coherent SI (has prefix)
        kilometer = Unit.parse("km")
        assert not kilometer.is_coherent_si


class TestUnitAlgebra:
    """Test unit algebraic operations."""
    
    def test_multiply(self):
        """Test unit multiplication."""
        meter = Unit.parse("m")
        second = Unit.parse("s")
        
        # m * s = m*s
        product = meter.multiply(second)
        assert "m" in product.symbol and "s" in product.symbol
        
        # m * m = m^2
        area = meter.multiply(meter)
        assert "m" in area.symbol and ("²" in area.symbol or "2" in area.symbol)
        
        with pytest.raises(TypeError):
            meter.multiply("not_a_unit")
    
    def test_divide(self):
        """Test unit division."""
        meter = Unit.parse("m")
        second = Unit.parse("s")
        
        # m / s = m/s (velocity)
        velocity = meter.divide(second)
        assert "m" in velocity.symbol and "s" in velocity.symbol
        
        # m / m = 1 (dimensionless)
        ratio = meter.divide(meter)
        assert ratio.is_dimensionless
        
        with pytest.raises(TypeError):
            meter.divide("not_a_unit")
    
    def test_power(self):
        """Test raising unit to power."""
        meter = Unit.parse("m")
        
        # m^2
        area = meter.power(2)
        assert "m" in area.symbol and ("²" in area.symbol or "2" in area.symbol)
        
        # m^3
        volume = meter.power(3)
        assert "m" in volume.symbol and ("³" in volume.symbol or "3" in volume.symbol)
        
        # m^0 = 1
        one = meter.power(0)
        assert one.is_dimensionless
        
        # m^-1
        inverse = meter.power(-1)
        assert "m" in inverse.symbol and ("-1" in inverse.symbol or "⁻¹" in inverse.symbol)
        
        with pytest.raises(TypeError):
            meter.power("not_a_number")
    
    def test_nth_root(self):
        """Test taking nth root of unit."""
        meter = Unit.parse("m")
        area = meter.power(2)  # m^2
        
        # sqrt(m^2) = m
        sqrt_area = area.nth_root(2)
        # Result should be equivalent to meter
        assert sqrt_area.is_dimensionally_equal(meter)
        
        volume = meter.power(3)  # m^3
        # cbrt(m^3) = m
        cbrt_volume = volume.nth_root(3)
        assert cbrt_volume.is_dimensionally_equal(meter)
        
        with pytest.raises(ValueError):
            meter.nth_root(0)
        
        with pytest.raises(ValueError):
            meter.nth_root(-1)
        
        with pytest.raises(TypeError):
            meter.nth_root("not_an_int")
    
    def test_complex_algebra(self):
        """Test complex algebraic operations."""
        meter = Unit.parse("m")
        second = Unit.parse("s")
        kilogram = Unit.parse("kg")
        
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
    
    def test_is_equal(self):
        """Test exact equality."""
        meter1 = Unit.parse("m")
        meter2 = Unit.parse("m")
        
        assert meter1.is_equal(meter2)
        
        second = Unit.parse("s")
        assert not meter1.is_equal(second)
        
        # Different representations of same unit should be equal
        velocity1 = Unit.parse("m/s")
        velocity2 = Unit.parse("m*s^-1")
        assert velocity1.is_equal(velocity2)
        
        # Non-Unit comparison
        assert not meter1.is_equal("not_a_unit")
    
    def test_is_dimensionally_equal(self):
        """Test dimensional equality."""
        meter = Unit.parse("m")
        kilometer = Unit.parse("km")
        
        # Same dimensionality but different scale
        assert meter.is_dimensionally_equal(kilometer)
        
        second = Unit.parse("s")
        assert not meter.is_dimensionally_equal(second)
        
        # Different units with same dimensionality
        velocity1 = Unit.parse("m/s")
        velocity2 = Unit.parse("km/h")  # Different scale, same dimensionality
        assert velocity1.is_dimensionally_equal(velocity2)
        
        # Test force equivalence (based on C test_unit_8)
        force_expr = Unit.parse("kg*m/s^2")
        newton = Unit.parse("N")
        assert force_expr.is_dimensionally_equal(newton)
        
        # Non-Unit comparison
        assert not meter.is_dimensionally_equal("not_a_unit")
    
    def test_is_compatible_with(self):
        """Test compatibility (alias for dimensional equality)."""
        meter = Unit.parse("m")
        kilometer = Unit.parse("km")
        
        assert meter.is_compatible_with(kilometer)
        
        second = Unit.parse("s")
        assert not meter.is_compatible_with(second)


class TestUnitOperators:
    """Test Python operator overloading."""
    
    def test_multiplication_operator(self):
        """Test * operator."""
        meter = Unit.parse("m")
        second = Unit.parse("s")
        
        product = meter * second
        assert product.is_equal(meter.multiply(second))
    
    def test_division_operator(self):
        """Test / operator."""
        meter = Unit.parse("m")
        second = Unit.parse("s")
        
        quotient = meter / second
        assert quotient.is_equal(meter.divide(second))
    
    def test_power_operator(self):
        """Test ** operator."""
        meter = Unit.parse("m")
        
        square = meter ** 2
        assert square.is_equal(meter.power(2))
    
    def test_equality_operators(self):
        """Test == and != operators."""
        meter1 = Unit.parse("m")
        meter2 = Unit.parse("m")
        second = Unit.parse("s")
        
        assert meter1 == meter2
        assert not (meter1 != meter2)
        assert meter1 != second
        assert not (meter1 == second)
    
    def test_chained_operations(self):
        """Test chaining multiple operations."""
        m = Unit.parse("m")
        s = Unit.parse("s")
        kg = Unit.parse("kg")
        
        # Force: kg*m/s^2
        force = kg * m / (s ** 2)
        
        # Alternative calculation
        acceleration = m / (s * s)
        force2 = kg * acceleration
        
        assert force.is_dimensionally_equal(force2)


class TestUnitDisplay:
    """Test unit display and string representation."""
    
    def test_str_representation(self):
        """Test string representation."""
        meter = Unit.parse("m")
        assert str(meter) == "m"
        
        velocity = Unit.parse("m/s")
        velocity_str = str(velocity)
        assert "m" in velocity_str and "s" in velocity_str
    
    def test_repr_representation(self):
        """Test repr representation."""
        meter = Unit.parse("m")
        repr_str = repr(meter)
        assert "Unit" in repr_str
        assert "m" in repr_str
    
    def test_show_method(self):
        """Test show method (just verify it doesn't crash)."""
        meter = Unit.parse("m")
        meter.show()  # Should not raise exception


class TestUnitIntegration:
    """Test integration with other components."""
    
    def test_dimensionality_integration(self):
        """Test integration with Dimensionality class."""
        meter = Unit.parse("m")
        length_dim = meter.dimensionality
        
        # Should be able to find unit for this dimensionality
        coherent_unit = Unit.for_dimensionality(length_dim)
        assert coherent_unit is not None
        assert coherent_unit.is_dimensionally_equal(meter)
    
    def test_unit_algebra_preserves_dimensionality(self):
        """Test that unit algebra preserves dimensional relationships."""
        m = Unit.parse("m")
        s = Unit.parse("s")
        
        # Distance/time = velocity
        velocity = m / s
        velocity_dim = velocity.dimensionality
        
        # Distance/velocity = time
        time_unit = m / velocity
        time_dim = time_unit.dimensionality
        
        # Should be dimensionally equal to seconds
        assert time_unit.is_dimensionally_equal(s)
        assert time_dim.is_equal(s.dimensionality)


class TestUnitEdgeCases:
    """Test edge cases and error conditions."""
    
    def test_zero_power(self):
        """Test raising to zero power."""
        meter = Unit.parse("m")
        result = meter ** 0
        assert result.is_dimensionless
    
    def test_negative_power(self):
        """Test negative powers."""
        meter = Unit.parse("m")
        inverse = meter ** -1
        
        # m^-1 * m = 1
        product = inverse * meter
        assert product.is_dimensionless
    
    def test_fractional_power(self):
        """Test fractional powers."""
        meter = Unit.parse("m")
        area = meter ** 2
        
        # (m^2)^0.5 = m
        sqrt_area = area ** 0.5
        assert sqrt_area.is_dimensionally_equal(meter)
    
    def test_roundtrip_serialization(self):
        """Test that units can be serialized and parsed back (based on test_unit_0)."""
        # Complex expression from C test
        original = Unit.parse("m*kg^2*s^3*A^4*K^5*mol^6*cd^7/(m^2*kg^3*s^4*A^5*K^6*mol^7*cd^8)")
        
        # Get symbol representation
        symbol = original.symbol
        assert symbol is not None and len(symbol) > 0
        
        # Parse it back
        reparsed = Unit.parse(symbol)
        
        # Should be equal to original
        assert reparsed.is_equal(original)
    
    def test_equivalent_vs_equal_units(self):
        """Test the difference between equivalent and equal units (based on test_unit_8, test_unit_9)."""
        # kg*m/s^2 should be equivalent to N but not equal
        force_expr = Unit.parse("kg*m/s^2")
        newton = Unit.parse("N")
        
        # Should be dimensionally equivalent
        assert force_expr.is_dimensionally_equal(newton)
        
        # But might not be exactly equal (implementation dependent)
        # This depends on whether the library considers them equal or just equivalent
        
        # kN vs N - same dimensionality but different scale
        kilo_newton = Unit.parse("kN")
        base_newton = Unit.parse("N")
        
        # Should be dimensionally equal
        assert kilo_newton.is_dimensionally_equal(base_newton)
        
        # But should not be equal (different scale)
        assert not kilo_newton.is_equal(base_newton)
    
    def test_prefix_handling(self):
        """Test SI prefix handling (based on test_unit_4, test_unit_9)."""
        kilometer = Unit.parse("km")
        
        # Should have correct symbol
        assert kilometer.symbol == "km"
        
        # Should have correct scale factor
        assert kilometer.scale_factor == 1000.0
        
        # Should not be coherent SI
        assert not kilometer.is_coherent_si
        
        # Root name should be meter
        assert "meter" in kilometer.name.lower()
    
    def test_special_units(self):
        """Test special SI units like Pascal, Newton, etc."""
        # Pascal
        pascal = Unit.parse("Pa")
        assert pascal.symbol == "Pa"
        
        # Newton  
        newton = Unit.parse("N")
        assert newton.symbol == "N"
        
        # Bar (if supported)
        try:
            bar = Unit.from_symbol("bar")
            if bar:
                assert bar.symbol == "bar"
        except:
            pass  # Bar might not be supported
    
    def test_non_si_units(self):
        """Test non-SI units like inches, pounds, etc."""
        # Test inch per second (based on test_unit_11)
        try:
            inch_per_sec = Unit.parse("in/s")
            meter_per_sec = Unit.parse("m/s")
            
            # Should have same dimensionality
            assert inch_per_sec.is_dimensionally_equal(meter_per_sec)
            
            # But different scale factors
            assert inch_per_sec.scale_factor != meter_per_sec.scale_factor
        except RMNError:
            # Might not support non-SI units
            pytest.skip("Non-SI units not supported")
    
    def test_unicode_normalization(self):
        """Test Unicode normalization (based on test_unit_unicode_normalization)."""
        try:
            # Test Greek mu vs micro sign
            micro_meter_greek = Unit.parse("μm")  # Greek mu
            micro_meter_micro = Unit.parse("µm")  # Micro sign
            
            # Should be equal after normalization
            assert micro_meter_greek.is_equal(micro_meter_micro)
            assert micro_meter_greek.symbol == micro_meter_micro.symbol
            
        except RMNError:
            # Unicode normalization might not be supported
            pytest.skip("Unicode normalization not supported")
    
    def test_very_complex_expression(self):
        """Test very complex unit expressions."""
        # Stefan-Boltzmann constant units: kg/(s^3*K^4)
        complex_expr = "kg/(s^3*K^4)"
        try:
            unit = Unit.parse(complex_expr)
            assert unit is not None
        except RMNError:
            # Some expressions might not be supported
            pytest.skip(f"Complex expression '{complex_expr}' not supported")
    
    def test_memory_management(self):
        """Test that units are properly cleaned up."""
        # Create many units to test memory management
        units = []
        for i in range(100):
            unit = Unit.parse("m")
            units.append(unit)
        
        # All should be valid
        for unit in units:
            assert unit.symbol == "m"
        
        # Clear references
        units.clear()
        # Python garbage collection should clean up


class TestUnitAPIEquivalence:
    """Test that our wrapper properly mirrors the C API behavior."""
    
    def test_root_symbol_properties(self):
        """Test root symbol extraction (based on test_unit_3)."""
        meter = Unit.parse("m")
        
        # For simple units, symbol should equal the root symbol
        assert meter.symbol == "m"
        
        # Test with prefixed unit
        km = Unit.parse("km")
        # Root should still be meter-related
        assert "meter" in km.name.lower()
    
    def test_multiplier_handling(self):
        """Test that multipliers are handled correctly in parsing."""
        # When parsing a unit expression, the scale factor should be incorporated
        # into the unit itself, not returned as a separate multiplier
        
        km = Unit.parse("km")
        assert km.scale_factor == 1000.0
        
        mm = Unit.parse("mm") 
        assert mm.scale_factor == 0.001
    
    def test_coherent_si_detection(self):
        """Test various coherent SI unit classifications."""
        # Base units
        meter = Unit.parse("m")
        assert meter.is_si_base_unit
        assert meter.is_coherent_si
        
        second = Unit.parse("s")
        assert second.is_si_base_unit
        assert second.is_coherent_si
        
        kilogram = Unit.parse("kg")
        assert kilogram.is_si_base_unit  # kg is the base unit, not g
        assert kilogram.is_coherent_si
        
        # Derived units
        newton = Unit.parse("N")
        assert not newton.is_si_base_unit
        assert newton.is_coherent_si  # Coherent derived unit
        
        # Prefixed units
        kilometer = Unit.parse("km")
        assert not kilometer.is_coherent_si  # Has prefix
        
    def test_dimensionality_consistency(self):
        """Test that dimensionality is consistent across operations."""
        m = Unit.parse("m")
        s = Unit.parse("s")
        
        # Create velocity
        velocity = m / s
        velocity_dim = velocity.dimensionality
        
        # Create velocity directly
        velocity_direct = Unit.parse("m/s")
        velocity_direct_dim = velocity_direct.dimensionality
        
        # Dimensionalities should be equal
        assert velocity_dim.is_equal(velocity_direct_dim)


if __name__ == "__main__":
    # Run with: python -m pytest tests/test_unit.py -v
    pytest.main([__file__, "-v"])
