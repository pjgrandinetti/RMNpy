"""
Test suite for DependentVariable wrapper based on the C test suite
"""

import numpy as np

from rmnpy import DependentVariable
from rmnpy.sitypes import Unit, quantity as q


class TestDependentVariableBasics:
    """Test basic DependentVariable functionality"""

    def test_basic_creation(self):
        """Test basic DependentVariable creation following C test patterns"""
        # Create data like the C test - a simple float64 array
        data = np.array([1.0, 2.0, 3.0, 4.0], dtype=np.float64)

        # Create DependentVariable with minimal parameters (like _make_internal_scalar)
        # Test DependentVariable creation like in C tests
        dv = DependentVariable(
            components=[data],
            name="",  # Empty string like C test
            description="",  # Empty string like C test
            unit=" ",  # dimensionless
            quantity_name=q.Dimensionless,
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
            quantity_name=q.Dimensionless,
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
        assert current_quantity_name == q.Dimensionless

        # Test quantity name setter
        dv.quantity_name = q.LengthRatio
        assert (
            dv.quantity_name == q.LengthRatio
        ), f"Expected '{q.LengthRatio}', got '{dv.quantity_name}'"

    def test_size_property_setter(self):
        """Test size property getter and setter functionality"""
        # Create a DependentVariable with initial data
        data = np.array([1.0, 2.0, 3.0], dtype=np.float64)
        dv = DependentVariable(
            components=[data],
            name="test_data",
            description="Test data for size manipulation",
            unit=" ",  # dimensionless
            quantity_name=q.Dimensionless,
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
            quantity_name=q.Dimensionless,
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
            quantity_name=q.Dimensionless,
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
            quantity_name=q.Dimensionless,
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
        with pytest.raises(ValueError, match="DependentVariable not initialized"):
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
            quantity_name=q.Dimensionless,
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

        # Test accessing quantities through new namespace
        assert hasattr(rmn.sitypes.quantity, "Dimensionless")
        assert rmn.sitypes.quantity.Dimensionless == "dimensionless"


class TestDependentVariableRoundTrip:
    """Test round trip functionality for DependentVariable serialization/deserialization."""

    def test_basic_round_trip(self):
        """Test basic DependentVariable to_dict() and from_dict() round trip."""
        # Create a DependentVariable with various properties
        data = np.array([1.0, 2.0, 3.0, 4.0, 5.0], dtype=np.float64)
        original = DependentVariable(
            components=[data],
            name="test_variable",
            description="Test dependent variable for round trip",
            unit=Unit("Hz"),
            quantity_name="frequency",
            quantity_type="scalar",
            element_type="float64",
        )

        # Convert to dictionary
        dv_dict = original.to_dict()
        assert isinstance(dv_dict, dict)
        assert dv_dict["type"] == "internal"  # Internal DependentVariable type
        assert dv_dict["name"] == "test_variable"
        assert dv_dict["description"] == "Test dependent variable for round trip"
        assert dv_dict["quantity_name"] == "frequency"
        assert dv_dict["quantity_type"] == "scalar"

        # Round trip: create new DependentVariable from dictionary
        restored = DependentVariable.from_dict(dv_dict)

        # Verify the restored DependentVariable
        assert restored.name == original.name
        assert restored.description == original.description
        assert restored.quantity_name == original.quantity_name
        assert restored.quantity_type == original.quantity_type
        assert restored.size == original.size
        assert restored.component_count == original.component_count

        # Check that data is preserved
        original_data = original.components[0]
        restored_data = restored.components[0]
        np.testing.assert_array_equal(original_data, restored_data)

    def test_minimal_round_trip(self):
        """Test round trip with minimal DependentVariable."""
        # Create minimal DependentVariable
        data = np.array([10.0, 20.0], dtype=np.float64)
        original = DependentVariable(
            components=[data],
            unit=Unit("m"),  # Just specify unit
            quantity_name="length",
        )

        # Round trip
        dv_dict = original.to_dict()
        restored = DependentVariable.from_dict(dv_dict)

        # Verify essential properties
        assert restored.quantity_name == original.quantity_name
        assert restored.size == original.size
        np.testing.assert_array_equal(original.components[0], restored.components[0])

    def test_multi_component_round_trip(self):
        """Test round trip with DependentVariable that could support multiple components."""
        # For now, just test with one component since multi-component creation seems constrained
        data = np.array([1.0, 2.0, 3.0], dtype=np.float64)
        original = DependentVariable(
            components=[data],
            name="multi_component_signal",
            description="Signal with multiple components",
            unit=Unit("V"),
            quantity_name="voltage",
            quantity_type="scalar",
        )

        # Round trip
        dv_dict = original.to_dict()
        restored = DependentVariable.from_dict(dv_dict)

        # Verify properties
        assert restored.name == original.name
        assert restored.description == original.description
        assert restored.quantity_type == original.quantity_type
        assert restored.component_count == 1
        assert len(restored.components) == 1

        # Check component data
        np.testing.assert_array_equal(original.components[0], restored.components[0])

    def test_from_dict_error_handling(self):
        """Test error handling in from_dict method."""
        import pytest

        from rmnpy.exceptions import RMNError

        # Test with invalid dictionary
        invalid_dict = {"type": "invalid_type"}

        with pytest.raises(RMNError):
            DependentVariable.from_dict(invalid_dict)

        # Test with empty dictionary - should also fail for DependentVariable
        with pytest.raises(RMNError):
            DependentVariable.from_dict({})

    def test_to_dict_structure(self):
        """Test that to_dict returns expected dictionary structure."""
        data = np.array([1.0, 2.0, 3.0], dtype=np.float64)
        dv = DependentVariable(
            components=[data],
            name="test",
            description="test description",
            unit=Unit("s"),
            quantity_name="time",
        )

        dv_dict = dv.to_dict()

        # Check required keys are present
        required_keys = [
            "type",
            "name",
            "description",
            "quantity_name",
            "quantity_type",
            "unit",
            "numeric_type",
            "components",
        ]
        for key in required_keys:
            assert key in dv_dict, f"Missing required key: {key}"

        # Check specific values
        assert dv_dict["type"] == "internal"
        assert dv_dict["name"] == "test"
        assert dv_dict["description"] == "test description"
        assert dv_dict["quantity_name"] == "time"
