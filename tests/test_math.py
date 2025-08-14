# -*- coding: utf-8 -*-
"""
Tests for rmnpy.math module - Mathematical functions for Scalar objects.

This module tests all mathematical functions that work with RMNpy Scalar objects,
including trigonometric, hyperbolic, exponential, logarithmic, and power functions.
"""

import cmath
import math

import pytest

from rmnpy.math import (
    acos,
    acosh,
    asin,
    asinh,
    atan,
    atan2,
    atanh,
    cbrt,
    cos,
    cosh,
    e,
    exp,
    log,
    log2,
    log10,
    pi,
    pow,
    sin,
    sinh,
    sqrt,
    tan,
    tanh,
    tau,
)
from rmnpy.wrappers.sitypes.scalar import Scalar


class TestTrigonometricFunctions:
    """Test trigonometric functions."""

    def test_sin_degrees(self):
        """Test sine with degree inputs."""
        result = sin(Scalar(90, "°"))
        assert abs(result.value - 1.0) < 1e-10
        assert str(result.unit) == " "  # dimensionless (API changed to single space)

        result = sin(Scalar(30, "°"))
        assert abs(result.value - 0.5) < 1e-10

        result = sin(Scalar(0, "°"))
        assert abs(result.value - 0.0) < 1e-10

    def test_sin_radians(self):
        """Test sine with radian inputs."""
        result = sin(Scalar("π/2"))
        assert abs(result.value - 1.0) < 1e-10

        result = sin(Scalar("π"))
        assert abs(result.value - 0.0) < 1e-10

        result = sin(Scalar(0, "rad"))
        assert abs(result.value - 0.0) < 1e-10

    def test_sin_complex(self):
        """Test sine with complex inputs."""
        result = sin(Scalar(1 + 2j, "rad"))
        expected = cmath.sin(1 + 2j)
        assert abs(result.value - expected) < 1e-10
        assert result.is_complex

    def test_cos_degrees(self):
        """Test cosine with degree inputs."""
        result = cos(Scalar(0, "°"))
        assert abs(result.value - 1.0) < 1e-10

        result = cos(Scalar(60, "°"))
        assert abs(result.value - 0.5) < 1e-10

        result = cos(Scalar(90, "°"))
        assert abs(result.value - 0.0) < 1e-10

    def test_cos_radians(self):
        """Test cosine with radian inputs."""
        result = cos(Scalar(0, "rad"))
        assert abs(result.value - 1.0) < 1e-10

        result = cos(Scalar("π"))
        assert abs(result.value - (-1.0)) < 1e-10

    def test_tan_degrees(self):
        """Test tangent with degree inputs."""
        result = tan(Scalar(45, "°"))
        assert abs(result.value - 1.0) < 1e-10

        result = tan(Scalar(0, "°"))
        assert abs(result.value - 0.0) < 1e-10

    def test_tan_radians(self):
        """Test tangent with radian inputs."""
        result = tan(Scalar("π/4"))
        assert abs(result.value - 1.0) < 1e-10

    def test_asin(self):
        """Test arcsine function."""
        result = asin(Scalar(1.0))
        assert abs(result.value - math.pi / 2) < 1e-10
        assert str(result.unit) == "rad"  # angles in radians

        result = asin(Scalar(0.5))
        assert abs(result.value - math.pi / 6) < 1e-10

        result = asin(Scalar(0.0))
        assert abs(result.value - 0.0) < 1e-10

    def test_acos(self):
        """Test arccosine function."""
        result = acos(Scalar(1.0))
        assert abs(result.value - 0.0) < 1e-10
        assert str(result.unit) == "rad"  # angles in radians

        result = acos(Scalar(0.0))
        assert abs(result.value - math.pi / 2) < 1e-10

        result = acos(Scalar(-1.0))
        assert abs(result.value - math.pi) < 1e-10

    def test_atan(self):
        """Test arctangent function."""
        result = atan(Scalar(1.0))
        assert abs(result.value - math.pi / 4) < 1e-10
        assert str(result.unit) == "rad"  # angles in radians

        result = atan(Scalar(0.0))
        assert abs(result.value - 0.0) < 1e-10

    def test_atan2(self):
        """Test atan2 function."""
        # Test with same units
        result = atan2(Scalar(1, "m"), Scalar(1, "m"))
        assert abs(result.value - math.pi / 4) < 1e-10
        assert str(result.unit) == "rad"  # angles in radians

        # Test with different units but same dimensionality
        result = atan2(Scalar(1000, "mm"), Scalar(1, "m"))
        assert abs(result.value - math.pi / 4) < 1e-10

        # Test quadrants
        result = atan2(Scalar(0, "kg"), Scalar(-1, "kg"))
        assert abs(result.value - math.pi) < 1e-10

    def test_trig_invalid_units(self):
        """Test trigonometric functions with invalid units."""
        with pytest.raises(ValueError, match="angular dimensionality"):
            sin(Scalar(1, "m"))

        with pytest.raises(ValueError, match="angular dimensionality"):
            cos(Scalar(1, "kg"))

        with pytest.raises(ValueError, match="angular dimensionality"):
            tan(Scalar(1, "s"))

    def test_inverse_trig_invalid_units(self):
        """Test inverse trigonometric functions with invalid units."""
        with pytest.raises(ValueError, match="dimensionless"):
            asin(Scalar(1, "m"))

        with pytest.raises(ValueError, match="dimensionless"):
            acos(Scalar(1, "kg"))

        with pytest.raises(ValueError, match="dimensionless"):
            atan(Scalar(1, "s"))


class TestHyperbolicFunctions:
    """Test hyperbolic functions."""

    def test_sinh(self):
        """Test hyperbolic sine."""
        result = sinh(Scalar(0.0))
        assert abs(result.value - 0.0) < 1e-10
        assert str(result.unit) == " "  # dimensionless (API changed to single space)

        result = sinh(Scalar(1.0))
        assert abs(result.value - math.sinh(1.0)) < 1e-10

    def test_cosh(self):
        """Test hyperbolic cosine."""
        result = cosh(Scalar(0.0))
        assert abs(result.value - 1.0) < 1e-10
        assert str(result.unit) == " "  # dimensionless (API changed to single space)

        result = cosh(Scalar(1.0))
        assert abs(result.value - math.cosh(1.0)) < 1e-10

    def test_tanh(self):
        """Test hyperbolic tangent."""
        result = tanh(Scalar(0.0))
        assert abs(result.value - 0.0) < 1e-10
        assert str(result.unit) == " "  # dimensionless (API changed to single space)

        result = tanh(Scalar(1.0))
        assert abs(result.value - math.tanh(1.0)) < 1e-10

    def test_asinh(self):
        """Test inverse hyperbolic sine."""
        result = asinh(Scalar(0.0))
        assert abs(result.value - 0.0) < 1e-10
        assert str(result.unit) == " "  # dimensionless (API changed to single space)

        result = asinh(Scalar(1.0))
        assert abs(result.value - math.asinh(1.0)) < 1e-10

    def test_acosh(self):
        """Test inverse hyperbolic cosine."""
        result = acosh(Scalar(1.0))
        assert abs(result.value - 0.0) < 1e-10
        assert str(result.unit) == " "  # dimensionless (API changed to single space)

        result = acosh(Scalar(2.0))
        assert abs(result.value - math.acosh(2.0)) < 1e-10

    def test_atanh(self):
        """Test inverse hyperbolic tangent."""
        result = atanh(Scalar(0.0))
        assert abs(result.value - 0.0) < 1e-10
        assert str(result.unit) == " "  # dimensionless (API changed to single space)

        result = atanh(Scalar(0.5))
        assert abs(result.value - math.atanh(0.5)) < 1e-10

    def test_hyperbolic_complex(self):
        """Test hyperbolic functions with complex inputs."""
        z = 1 + 2j

        result = sinh(Scalar(z))
        expected = cmath.sinh(z)
        assert abs(result.value - expected) < 1e-10
        assert result.is_complex

        result = cosh(Scalar(z))
        expected = cmath.cosh(z)
        assert abs(result.value - expected) < 1e-10
        assert result.is_complex

    def test_hyperbolic_invalid_units(self):
        """Test hyperbolic functions with invalid units."""
        with pytest.raises(ValueError, match="dimensionless"):
            sinh(Scalar(1, "m"))

        with pytest.raises(ValueError, match="dimensionless"):
            cosh(Scalar(1, "kg"))


class TestExponentialLogarithmicFunctions:
    """Test exponential and logarithmic functions."""

    def test_exp(self):
        """Test exponential function."""
        result = exp(Scalar(0.0))
        assert abs(result.value - 1.0) < 1e-10
        assert str(result.unit) == " "  # dimensionless (API changed to single space)

        result = exp(Scalar(1.0))
        assert abs(result.value - math.e) < 1e-10

        result = exp(Scalar(2.0))
        assert abs(result.value - math.exp(2.0)) < 1e-10

    def test_exp_complex(self):
        """Test exponential with complex input."""
        z = 1 + 2j
        result = exp(Scalar(z))
        expected = cmath.exp(z)
        assert abs(result.value - expected) < 1e-10
        assert result.is_complex

    def test_log(self):
        """Test natural logarithm."""
        result = log(Scalar(1.0))
        assert abs(result.value - 0.0) < 1e-10
        assert str(result.unit) == " "  # dimensionless (API changed to single space)

        result = log(Scalar(math.e))
        assert abs(result.value - 1.0) < 1e-10

        result = log(Scalar(math.e**2))
        assert abs(result.value - 2.0) < 1e-10

    def test_log10(self):
        """Test base-10 logarithm."""
        result = log10(Scalar(1.0))
        assert abs(result.value - 0.0) < 1e-10
        assert str(result.unit) == " "  # dimensionless (API changed to single space)

        result = log10(Scalar(10.0))
        assert abs(result.value - 1.0) < 1e-10

        result = log10(Scalar(100.0))
        assert abs(result.value - 2.0) < 1e-10

    def test_log2(self):
        """Test base-2 logarithm."""
        result = log2(Scalar(1.0))
        assert abs(result.value - 0.0) < 1e-10
        assert str(result.unit) == " "  # dimensionless (API changed to single space)

        result = log2(Scalar(2.0))
        assert abs(result.value - 1.0) < 1e-10

        result = log2(Scalar(8.0))
        assert abs(result.value - 3.0) < 1e-10

    def test_log_complex(self):
        """Test logarithm with complex input."""
        z = 1 + 2j
        result = log(Scalar(z))
        expected = cmath.log(z)
        assert abs(result.value - expected) < 1e-10
        assert result.is_complex

    def test_exp_log_invalid_units(self):
        """Test exp/log functions with invalid units."""
        with pytest.raises(ValueError, match="dimensionless"):
            exp(Scalar(1, "m"))

        with pytest.raises(ValueError, match="dimensionless"):
            log(Scalar(1, "kg"))

        with pytest.raises(ValueError, match="dimensionless"):
            log10(Scalar(1, "s"))


class TestPowerFunctions:
    """Test power functions."""

    def test_sqrt(self):
        """Test square root function."""
        result = sqrt(Scalar(4.0))
        assert abs(result.value - 2.0) < 1e-10
        assert str(result.unit) == " "  # dimensionless (API changed to single space)

        result = sqrt(Scalar(9.0))
        assert abs(result.value - 3.0) < 1e-10

        # Test with units
        result = sqrt(Scalar(4, "m^2"))
        assert abs(result.value - 2.0) < 1e-10
        assert str(result.unit) == "m"

    def test_cbrt(self):
        """Test cube root function."""
        result = cbrt(Scalar(8.0))
        assert abs(result.value - 2.0) < 1e-10
        assert str(result.unit) == " "  # dimensionless (API changed to single space)

        result = cbrt(Scalar(27.0))
        assert abs(result.value - 3.0) < 1e-10

        # Test with units
        result = cbrt(Scalar(8, "m^3"))
        assert abs(result.value - 2.0) < 1e-10
        assert str(result.unit) == "m"

    def test_pow(self):
        """Test power function."""
        result = pow(Scalar(2.0), 3)
        assert abs(result.value - 8.0) < 1e-10
        assert str(result.unit) == " "  # dimensionless (API changed to single space)

        result = pow(Scalar(4.0), 0.5)
        assert abs(result.value - 2.0) < 1e-10

        # Test with units - SITypes may convert to equivalent units
        result = pow(Scalar(2, "m"), 3)
        assert abs(result.value - 8.0) < 1e-10
        # Check that units are volume units (may be kL, m^3, etc.)
        expected_m3 = Scalar(1, "m^3")
        try:
            result.to(expected_m3.unit)  # If this doesn't throw, they're compatible
        except (ValueError, Exception):
            assert False, f"Expected volume unit, got {result.unit}"


class TestConstants:
    """Test mathematical constants."""

    def test_pi_constant(self):
        """Test pi constant."""
        assert abs(pi.value - math.pi) < 1e-10
        assert str(pi.unit) == "rad"  # pi is in radians

    def test_e_constant(self):
        """Test e constant."""
        assert abs(e.value - math.e) < 1e-10
        assert str(e.unit) == " "  # dimensionless (API changed to single space)

    def test_tau_constant(self):
        """Test tau constant."""
        assert abs(tau.value - (2 * math.pi)) < 1e-10
        assert str(tau.unit) == "rad"  # tau is in radians

    def test_constants_in_calculations(self):
        """Test using constants in calculations."""
        # sin(π/2) = 1
        result = sin(pi / 2)
        assert abs(result.value - 1.0) < 1e-10

        # cos(π) = -1
        result = cos(pi)
        assert abs(result.value - (-1.0)) < 1e-10

        # exp(1) = e
        result = exp(Scalar(1.0))
        assert abs(result.value - e.value) < 1e-10


class TestInputValidation:
    """Test input validation for all functions."""

    def test_non_scalar_input(self):
        """Test functions with non-Scalar inputs."""
        with pytest.raises(TypeError, match="requires a Scalar object"):
            sin(1.0)

        with pytest.raises(TypeError, match="requires a Scalar object"):
            cos("90")

        with pytest.raises(TypeError, match="requires a Scalar object"):
            exp([1, 2, 3])

        with pytest.raises(TypeError, match="requires a Scalar object"):
            sqrt(None)

    def test_dimensional_validation(self):
        """Test dimensional validation across all function categories."""
        # Angular functions need angular units
        with pytest.raises(ValueError, match="angular dimensionality"):
            sin(Scalar(1, "m"))

        # Dimensionless functions need dimensionless inputs
        with pytest.raises(ValueError, match="dimensionless"):
            exp(Scalar(1, "m"))

        with pytest.raises(ValueError, match="dimensionless"):
            sinh(Scalar(1, "kg"))

        with pytest.raises(ValueError, match="dimensionless"):
            asin(Scalar(1, "s"))


class TestEdgeCases:
    """Test edge cases and special values."""

    def test_zero_values(self):
        """Test functions with zero inputs."""
        assert abs(sin(Scalar(0, "rad")).value - 0.0) < 1e-10
        assert abs(cos(Scalar(0, "rad")).value - 1.0) < 1e-10
        assert abs(tan(Scalar(0, "rad")).value - 0.0) < 1e-10
        assert abs(exp(Scalar(0.0)).value - 1.0) < 1e-10
        assert abs(log(Scalar(1.0)).value - 0.0) < 1e-10

    def test_unit_consistency(self):
        """Test that output units are consistent."""
        # Trig functions should return dimensionless
        result = sin(Scalar(45, "°"))
        assert str(result.unit) == " "  # dimensionless (API changed to single space)

        # Inverse trig functions should return angles in radians
        result = asin(Scalar(0.5))
        assert str(result.unit) == "rad"

        # Exp/log functions should return dimensionless
        result = exp(Scalar(1.0))
        assert str(result.unit) == " "  # dimensionless (API changed to single space)

        result = log(Scalar(2.0))
        assert str(result.unit) == " "  # dimensionless (API changed to single space)

    def test_mixed_unit_angles(self):
        """Test trigonometric functions with various angular units."""
        # These should all give the same result (sin(90°) = sin(π/2 rad) = 1)
        result_deg = sin(Scalar(90, "°"))
        result_rad = sin(Scalar("π/2"))

        assert abs(result_deg.value - result_rad.value) < 1e-10
        assert abs(result_deg.value - 1.0) < 1e-10


if __name__ == "__main__":
    pytest.main([__file__])
