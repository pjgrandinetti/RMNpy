"""
Test suite for DependentVariable wrapper based on the C test suite
"""

import numpy as np

from rmnpy import DependentVariable
from rmnpy.quantities import kSIQuantityDimensionless, kSIQuantityLengthRatio
from rmnpy.sitypes import Unit


class TestDependentVariableBasics:
    """Test basic DependentVariable functionality"""

    def test_basic_creation(self):
        """Test basic DependentVariable creation following C test patterns"""
        # Create data like the C test - a simple float64 array
        data = np.array([1.0, 2.0, 3.0, 4.0], dtype=np.float64)

        # Create DependentVariable with minimal parameters (like _make_internal_scalar)
        dv = DependentVariable(
            components=[data],  # Required: array of data
            name="",  # Empty string like C test
            description="",  # Empty string like C test
            unit=" ",  # dimensionless
            quantity_name=kSIQuantityDimensionless,
            quantity_type="scalar",  # Default from C test
            element_type="float64",  # Default from C test
        )

        # Test the basic properties like in C test
        # Verify name and description are empty strings like C test expects
        assert dv.name == "", f"Expected empty name, got '{dv.name}'"
        assert (
            dv.description == ""
        ), f"Expected empty description, got '{dv.description}'"
        assert (
            dv.quantity_type == "scalar"
        ), f"Expected 'scalar', got '{dv.quantity_type}'"

    def test_property_setters(self):
        """Test property setters following C test patterns"""
        data = np.array([10.0, 20.0, 30.0], dtype=np.float64)
        dv = DependentVariable(
            components=[data],
            name="",
            description="",
            unit=" ",  # dimensionless
            quantity_name=kSIQuantityDimensionless,
            quantity_type="scalar",  # Default from C test
            element_type="float64",  # Default from C test
        )

        # Test setters like in C test: set to "foo" and "bar"
        dv.name = "foo"
        assert dv.name == "foo", f"Expected 'foo', got '{dv.name}'"

        dv.description = "bar"
        assert dv.description == "bar", f"Expected 'bar', got '{dv.description}'"

        # Test unit getter (read the current unit)
        current_unit = dv.unit
        assert current_unit is not None

        # Test quantity name setter and getter
        current_quantity_name = dv.quantity_name
        assert current_quantity_name == kSIQuantityDimensionless

        # Test quantity name setter
        dv.quantity_name = kSIQuantityLengthRatio
        assert (
            dv.quantity_name == kSIQuantityLengthRatio
        ), f"Expected '{kSIQuantityLengthRatio}', got '{dv.quantity_name}'"


class TestDependentVariableIntegration:
    """Test DependentVariable integration with SITypes"""

    def test_sitypes_integration(self):
        """Test integration with Unit objects"""
        # Create a Unit object
        unit = Unit("m/s")

        # Create DependentVariable with the Unit
        data = np.array([5.0, 10.0, 15.0], dtype=np.float64)
        dv = DependentVariable(
            components=[data],
            name="velocity_data",
            description="Test velocity data",
            unit=unit,
            quantity_name="velocity",
            quantity_type="scalar",
            element_type="float64",
        )

        # Test that the unit property works
        unit_prop = dv.unit
        assert unit_prop.symbol == "m/s"
        assert dv.quantity_name == "velocity"


class TestDependentVariableImportStyles:
    """Test different import styles work correctly"""

    def test_explicit_imports(self):
        """Test explicit imports work"""
        from rmnpy.wrappers.rmnlib.dependent_variable import (
            DependentVariable as ExplicitDV,
        )
        from rmnpy.wrappers.sitypes.unit import Unit as ExplicitUnit

        unit = ExplicitUnit("kg")
        data = np.array([1.0, 2.0], dtype=np.float64)
        dv = ExplicitDV(
            components=[data],
            name="mass_data",
            description="Mass measurements",
            unit=unit,
            quantity_name="mass",
            quantity_type="scalar",
            element_type="float64",
        )

        assert dv.name == "mass_data"
        assert dv.unit.symbol == "kg"

    def test_convenience_imports(self):
        """Test convenience imports work"""
        from rmnpy.rmnlib import DependentVariable as ConvenienceDV
        from rmnpy.sitypes import Unit as ConvenienceUnit

        unit = ConvenienceUnit("K")
        data = np.array([273.15, 298.15], dtype=np.float64)
        dv = ConvenienceDV(
            components=[data],
            name="temperature_data",
            description="Temperature measurements",
            unit=unit,
            quantity_name="temperature",
            quantity_type="scalar",
            element_type="float64",
        )

        assert dv.name == "temperature_data"
        assert dv.unit.symbol == "K"

    def test_namespace_alias_imports(self):
        """Test namespace alias imports work"""
        import rmnpy as rmn

        unit = rmn.sitypes.Unit("Pa")
        data = np.array([101325.0, 200000.0], dtype=np.float64)
        dv = rmn.DependentVariable(
            components=[data],
            name="pressure_data",
            description="Pressure measurements",
            unit=unit,
            quantity_name="pressure",
            quantity_type="scalar",
            element_type="float64",
        )

        assert dv.name == "pressure_data"
        assert dv.unit.symbol == "Pa"

        # Test accessing quantities through namespace
        assert hasattr(rmn.quantities, "kSIQuantityDimensionless")
