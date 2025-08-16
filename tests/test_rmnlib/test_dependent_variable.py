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

    def test_size_property_setter(self):
        """Test size property getter and setter functionality"""
        # Create a DependentVariable with initial data
        data = np.array([1.0, 2.0, 3.0], dtype=np.float64)
        dv = DependentVariable(
            components=[data],
            name="test_data",
            description="Test data for size manipulation",
            unit=" ",  # dimensionless
            quantity_name=kSIQuantityDimensionless,
            quantity_type="scalar",
            element_type="float64",
        )

        # Test initial size getter
        assert dv.size == 3, f"Expected size 3, got {dv.size}"

        # Test increasing size
        dv.size = 5
        assert dv.size == 5, f"Expected size 5 after setting, got {dv.size}"

        # Test decreasing size
        dv.size = 2
        assert dv.size == 2, f"Expected size 2 after setting, got {dv.size}"

        # Test setting size to 0 (should be valid)
        dv.size = 0
        assert dv.size == 0, f"Expected size 0 after setting, got {dv.size}"

        # Test invalid size (negative)
        try:
            dv.size = -1
            assert False, "Expected ValueError for negative size"
        except ValueError as e:
            assert "non-negative" in str(e)


class TestDependentVariableAppend:
    """Test DependentVariable append functionality"""

    def test_append_basic(self):
        """Test basic append functionality"""
        # Create first DependentVariable
        data1 = np.array([1.0, 2.0, 3.0], dtype=np.float64)
        dv1 = DependentVariable(
            components=[data1],
            name="data1",
            description="First dataset",
            unit=" ",  # dimensionless
            quantity_name=kSIQuantityDimensionless,
            quantity_type="scalar",
            element_type="float64",
        )

        # Create second DependentVariable with compatible properties
        data2 = np.array([4.0, 5.0], dtype=np.float64)
        dv2 = DependentVariable(
            components=[data2],
            name="data2",
            description="Second dataset",
            unit=" ",  # dimensionless
            quantity_name=kSIQuantityDimensionless,
            quantity_type="scalar",
            element_type="float64",
        )

        # Check initial sizes
        assert dv1.size == 3
        assert dv2.size == 2

        # Append dv2 to dv1
        dv1.append(dv2)

        # Verify the size increased
        assert dv1.size == 5  # 3 + 2

    def test_append_error_cases(self):
        """Test error cases for append"""
        data = np.array([1.0, 2.0, 3.0], dtype=np.float64)
        dv = DependentVariable(
            components=[data],
            name="test",
            description="Test data",
            unit=" ",
            quantity_name=kSIQuantityDimensionless,
            quantity_type="scalar",
            element_type="float64",
        )

        # Test appending non-DependentVariable
        import pytest

        with pytest.raises(TypeError, match="other must be a DependentVariable"):
            dv.append("not a dependent variable")

        with pytest.raises(TypeError, match="other must be a DependentVariable"):
            dv.append([1, 2, 3])

        # Test appending to uninitialized DependentVariable
        uninitialized_dv = DependentVariable.__new__(DependentVariable)
        with pytest.raises(ValueError, match="DependentVariable not initialized"):
            uninitialized_dv.append(dv)

        # Test appending uninitialized DependentVariable
        other_uninitialized = DependentVariable.__new__(DependentVariable)
        with pytest.raises(ValueError, match="other DependentVariable not initialized"):
            dv.append(other_uninitialized)


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

    def test_components_property(self):
        """Test components property getter and setter functionality"""
        # Create initial test data
        original_data = np.array([1.0, 2.0, 3.0, 4.0], dtype=np.float64)

        # Create DependentVariable with initial components
        dv = DependentVariable(
            components=[original_data],
            name="test_components",
            description="Test components property",
            unit=" ",  # dimensionless
            quantity_name=kSIQuantityDimensionless,
            quantity_type="scalar",
            element_type="float64",
        )

        # Test components getter - should return a copy of the original data
        retrieved_components = dv.components
        assert (
            len(retrieved_components) == 1
        ), f"Expected 1 component, got {len(retrieved_components)}"

        # Check that the retrieved data matches original
        retrieved_data = np.array(retrieved_components[0])
        np.testing.assert_array_equal(retrieved_data, original_data)

        # Test components setter with new data
        new_data1 = np.array([10.0, 20.0, 30.0], dtype=np.float64)
        new_data2 = np.array([100.0, 200.0, 300.0], dtype=np.float64)

        # Set single component
        dv.components = [new_data1]
        updated_components = dv.components
        assert len(updated_components) == 1
        updated_data = np.array(updated_components[0])
        np.testing.assert_array_equal(updated_data, new_data1)

        # Test that size was updated correctly
        assert dv.size == 3  # new_data1 has 3 elements

        # Set multiple components
        dv.components = [new_data1, new_data2]
        multi_components = dv.components
        assert len(multi_components) == 2

        # Check both components
        comp1_data = np.array(multi_components[0])
        comp2_data = np.array(multi_components[1])
        np.testing.assert_array_equal(comp1_data, new_data1)
        np.testing.assert_array_equal(comp2_data, new_data2)

        # Test that component count was updated
        assert dv.component_count == 2

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
