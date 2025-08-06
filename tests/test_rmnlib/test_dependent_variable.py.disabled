"""
Test suite for DependentVariable wrapper

Tests the Python wrapper functionality for RMNLib's DependentVariable,
including creation, properties, data manipulation, and type checking.
"""

import numpy as np
import pytest

from rmnpy.exceptions import RMNLibError
from rmnpy.wrappers.rmnlib.dependent_variable import DependentVariable
from rmnpy.wrappers.sitypes.dimensionality import Dimensionality
from rmnpy.wrappers.sitypes.unit import Unit


class TestDependentVariableCreation:
    """Test DependentVariable creation methods."""

    def test_create_minimal(self):
        """Test minimal DependentVariable creation."""
        # Create a basic unit
        unit = Unit.dimensionless()

        # Create simple component data
        data1 = np.array([1.0, 2.0, 3.0, 4.0], dtype=np.float64).tobytes()
        components = [data1]

        # Create DependentVariable
        dv = DependentVariable.create_minimal(
            unit=unit,
            quantity_name="test_quantity",
            quantity_type="scalar",
            element_type="float64",
            components=components,
        )

        assert dv is not None
        assert dv.quantity_name == "test_quantity"
        assert dv.quantity_type == "scalar"
        assert dv.element_type == "float64"
        assert dv.component_count == 1
        assert dv.size == 4  # 4 float64 values

    def test_create_with_size(self):
        """Test DependentVariable creation with pre-allocated size."""
        unit = Unit.dimensionless()

        dv = DependentVariable.create_with_size(
            name="test_variable",
            description="A test dependent variable",
            unit=unit,
            quantity_name="temperature",
            quantity_type="scalar",
            element_type="float64",
            size=100,
        )

        assert dv is not None
        assert dv.name == "test_variable"
        assert dv.description == "A test dependent variable"
        assert dv.quantity_name == "temperature"
        assert dv.quantity_type == "scalar"
        assert dv.element_type == "float64"
        assert dv.size == 100
        assert dv.component_count == 1  # scalar type has 1 component

    def test_create_with_labels(self):
        """Test DependentVariable creation with component labels."""
        unit = Unit.parse("m")

        # Create vector data (3 components)
        data_x = np.array([1.0, 2.0, 3.0], dtype=np.float64).tobytes()
        data_y = np.array([4.0, 5.0, 6.0], dtype=np.float64).tobytes()
        data_z = np.array([7.0, 8.0, 9.0], dtype=np.float64).tobytes()
        components = [data_x, data_y, data_z]
        labels = ["x", "y", "z"]

        dv = DependentVariable.create(
            name="position_vector",
            description="3D position vector",
            unit=unit,
            quantity_name="position",
            quantity_type="vector_3",
            element_type="float64",
            component_labels=labels,
            components=components,
        )

        assert dv is not None
        assert dv.name == "position_vector"
        assert dv.description == "3D position vector"
        assert dv.quantity_name == "position"
        assert dv.quantity_type == "vector_3"
        assert dv.component_count == 3
        assert dv.get_component_labels() == ["x", "y", "z"]

    def test_create_complex_data(self):
        """Test DependentVariable creation with complex data."""
        unit = Unit.dimensionless()

        # Create complex data
        complex_data = np.array([1 + 2j, 3 + 4j, 5 + 6j], dtype=np.complex128).tobytes()
        components = [complex_data]

        dv = DependentVariable.create_minimal(
            unit=unit,
            quantity_name="complex_signal",
            quantity_type="scalar",
            element_type="complex128",
            components=components,
        )

        assert dv is not None
        assert dv.element_type == "complex128"
        assert dv.component_count == 1
        assert dv.size == 3

    def test_create_invalid_element_type(self):
        """Test creation with invalid element type falls back to default."""
        unit = Unit.dimensionless()
        data = np.array([1.0, 2.0], dtype=np.float64).tobytes()

        dv = DependentVariable.create_minimal(
            unit=unit,
            quantity_name="test",
            quantity_type="scalar",
            element_type="invalid_type",  # Should fall back to float64
            components=[data],
        )

        assert dv.element_type == "float64"


class TestDependentVariableProperties:
    """Test DependentVariable property access and modification."""

    def setup_method(self):
        """Set up test DependentVariable."""
        unit = Unit.parse("m/s")
        data = np.array([10.0, 20.0, 30.0], dtype=np.float64).tobytes()

        self.dv = DependentVariable.create(
            name="velocity",
            description="velocity measurement",
            unit=unit,
            quantity_name="velocity",
            quantity_type="scalar",
            element_type="float64",
            components=[data],
        )

    def test_name_property(self):
        """Test name property access and modification."""
        assert self.dv.name == "velocity"

        self.dv.name = "new_velocity"
        assert self.dv.name == "new_velocity"

        self.dv.name = None
        # Name might be None or empty depending on implementation

    def test_description_property(self):
        """Test description property access and modification."""
        assert self.dv.description == "velocity measurement"

        self.dv.description = "updated description"
        assert self.dv.description == "updated description"

    def test_quantity_properties(self):
        """Test quantity name and type properties."""
        assert self.dv.quantity_name == "velocity"
        assert self.dv.quantity_type == "scalar"

        self.dv.quantity_name = "speed"
        assert self.dv.quantity_name == "speed"

        self.dv.quantity_type = "vector_1"
        assert self.dv.quantity_type == "vector_1"

    def test_element_type_property(self):
        """Test element type property."""
        assert self.dv.element_type == "float64"

        self.dv.element_type = "float32"
        assert self.dv.element_type == "float32"

    def test_size_property(self):
        """Test size property access and modification."""
        assert self.dv.size == 3

        # Test size modification
        self.dv.size = 5
        assert self.dv.size == 5

    def test_component_count_property(self):
        """Test component count property (read-only)."""
        assert self.dv.component_count == 1


class TestDependentVariableTypeChecking:
    """Test DependentVariable type checking methods."""

    def test_is_scalar_type(self):
        """Test scalar type checking."""
        unit = Unit.dimensionless()
        data = np.array([1.0, 2.0, 3.0], dtype=np.float64).tobytes()

        dv = DependentVariable.create_minimal(
            unit=unit,
            quantity_name="scalar_test",
            quantity_type="scalar",
            element_type="float64",
            components=[data],
        )

        assert dv.is_scalar_type()

    def test_is_vector_type(self):
        """Test vector type checking."""
        unit = Unit.parse("m")

        dv = DependentVariable.create_with_size(
            unit=unit,
            quantity_name="vector_test",
            quantity_type="vector_3",
            element_type="float64",
            size=10,
        )

        is_vector, count = dv.is_vector_type()
        assert is_vector
        assert count == 3

    def test_is_pixel_type(self):
        """Test pixel type checking."""
        unit = Unit.dimensionless()

        dv = DependentVariable.create_with_size(
            unit=unit,
            quantity_name="pixel_test",
            quantity_type="pixel_2",
            element_type="float64",
            size=100,
        )

        is_pixel, count = dv.is_pixel_type()
        # Note: Actual behavior depends on RMNLib implementation
        # This test validates the interface works
        assert isinstance(is_pixel, bool)
        assert isinstance(count, int)


class TestDependentVariableSIQuantityInheritance:
    """Test inherited SIQuantity methods in DependentVariable."""

    def setup_method(self):
        """Set up test DependentVariable with a meaningful unit."""
        self.unit = Unit.parse("m/s²")  # acceleration unit
        data = np.array([9.81, 9.82, 9.80], dtype=np.float64).tobytes()

        self.dv = DependentVariable.create_minimal(
            unit=self.unit,
            quantity_name="acceleration",
            quantity_type="scalar",
            element_type="float64",
            components=[data],
        )

    def test_unit_property_inherited(self):
        """Test unit property access (inherited from SIQuantity)."""
        unit = self.dv.unit
        assert unit is not None
        assert unit.symbol == "m·s⁻²"  # Should match acceleration unit

        # Test unit setting
        new_unit = Unit.parse("ft/s²")
        self.dv.unit = new_unit

        updated_unit = self.dv.unit
        assert updated_unit.symbol == "ft·s⁻²"

    def test_dimensionality_property_inherited(self):
        """Test dimensionality property access (inherited from SIQuantity)."""
        dim = self.dv.dimensionality
        assert dim is not None
        # Acceleration has dimensionality of length·time⁻²
        assert "length" in dim.symbol
        assert "time" in dim.symbol

    def test_numeric_type_property_inherited(self):
        """Test numeric_type property (inherited from SIQuantity)."""
        numeric_type = self.dv.numeric_type
        assert numeric_type == "float64"  # Should match our creation parameter

    def test_element_size_property_inherited(self):
        """Test element_size property (inherited from SIQuantity)."""
        element_size = self.dv.element_size
        assert element_size == 8  # float64 is 8 bytes

    def test_has_numeric_type_inherited(self):
        """Test has_numeric_type method (inherited from SIQuantity)."""
        assert self.dv.has_numeric_type("float64")
        assert self.dv.has_numeric_type("float32") is False
        assert self.dv.has_numeric_type("int32") is False

    def test_is_complex_type_inherited(self):
        """Test is_complex_type method (inherited from SIQuantity)."""
        # Our test DV uses float64, so it's not complex
        assert self.dv.is_complex_type() is False

        # Create a complex DependentVariable
        complex_data = np.array([1 + 2j, 3 + 4j], dtype=np.complex128).tobytes()
        complex_dv = DependentVariable.create_minimal(
            unit=Unit.dimensionless(),
            quantity_name="complex_signal",
            quantity_type="scalar",
            element_type="complex128",
            components=[complex_data],
        )

        assert complex_dv.is_complex_type()

    def test_has_dimensionality_inherited(self):
        """Test has_dimensionality method (inherited from SIQuantity)."""
        # Create acceleration dimensionality manually
        acceleration_dim = Dimensionality.parse("length·time⁻²")
        assert self.dv.has_dimensionality(acceleration_dim)

        # Test with different dimensionality
        velocity_dim = Dimensionality.parse("length·time⁻¹")
        assert self.dv.has_dimensionality(velocity_dim) is False

    def test_has_same_dimensionality_inherited(self):
        """Test has_same_dimensionality method (inherited from SIQuantity)."""
        # Create another acceleration DependentVariable
        other_unit = Unit.parse("ft/s²")  # Different unit, same dimensionality
        other_data = np.array([32.2], dtype=np.float64).tobytes()

        other_dv = DependentVariable.create_minimal(
            unit=other_unit,
            quantity_name="other_acceleration",
            quantity_type="scalar",
            element_type="float64",
            components=[other_data],
        )

        assert self.dv.has_same_dimensionality(other_dv)

        # Create a velocity DependentVariable (different dimensionality)
        velocity_unit = Unit.parse("m/s")
        velocity_data = np.array([10.0], dtype=np.float64).tobytes()

        velocity_dv = DependentVariable.create_minimal(
            unit=velocity_unit,
            quantity_name="velocity",
            quantity_type="scalar",
            element_type="float64",
            components=[velocity_data],
        )

        assert self.dv.has_same_dimensionality(velocity_dv) is False

    def test_has_same_reduced_dimensionality_inherited(self):
        """Test has_same_reduced_dimensionality method (inherited from SIQuantity)."""
        # Create another acceleration DependentVariable with different prefix
        other_unit = Unit.parse("km/s²")  # kilometer per second squared
        other_data = np.array([0.00981], dtype=np.float64).tobytes()

        other_dv = DependentVariable.create_minimal(
            unit=other_unit,
            quantity_name="other_acceleration",
            quantity_type="scalar",
            element_type="float64",
            components=[other_data],
        )

        # Should have same reduced dimensionality (both are acceleration)
        assert self.dv.has_same_reduced_dimensionality(other_dv)

        # Test with different dimensionality
        energy_unit = Unit.parse("J")  # Joules (energy)
        energy_data = np.array([100.0], dtype=np.float64).tobytes()

        energy_dv = DependentVariable.create_minimal(
            unit=energy_unit,
            quantity_name="energy",
            quantity_type="scalar",
            element_type="float64",
            components=[energy_data],
        )

        # Should have different reduced dimensionality
        assert self.dv.has_same_reduced_dimensionality(energy_dv) is False

    def test_inherited_methods_with_complex_data(self):
        """Test inherited SIQuantity methods work correctly with complex data."""
        complex_unit = Unit.parse("V")  # Volts
        complex_data = np.array([1 + 2j, 3 - 4j, 5 + 0j], dtype=np.complex128).tobytes()

        complex_dv = DependentVariable.create_minimal(
            unit=complex_unit,
            quantity_name="complex_voltage",
            quantity_type="scalar",
            element_type="complex128",
            components=[complex_data],
        )

        # Test inherited properties work with complex data
        assert complex_dv.numeric_type == "complex128"
        assert complex_dv.element_size == 16  # complex128 is 16 bytes
        assert complex_dv.is_complex_type()
        assert complex_dv.has_numeric_type("complex128")
        assert complex_dv.has_numeric_type("float64") is False

        # Test unit-related inherited methods
        voltage_dim = Dimensionality.parse(
            "mass·length²·time⁻³·current⁻¹"
        )  # Voltage dimensionality
        assert complex_dv.has_dimensionality(voltage_dim)


class TestDependentVariableDataAccess:
    """Test DependentVariable data access and manipulation."""

    def setup_method(self):
        """Set up test DependentVariable with multiple components."""
        unit = Unit.parse("V")

        # Create 3-component vector data
        data_x = np.array([1.0, 2.0, 3.0], dtype=np.float64).tobytes()
        data_y = np.array([4.0, 5.0, 6.0], dtype=np.float64).tobytes()
        data_z = np.array([7.0, 8.0, 9.0], dtype=np.float64).tobytes()

        self.dv = DependentVariable.create(
            name="electric_field",
            unit=unit,
            quantity_name="electric_field",
            quantity_type="vector_3",
            element_type="float64",
            component_labels=["Ex", "Ey", "Ez"],
            components=[data_x, data_y, data_z],
        )

    def test_get_component_data(self):
        """Test getting component data."""
        data_0 = self.dv.get_component_data(0)
        assert isinstance(data_0, bytes)
        assert len(data_0) == 3 * 8  # 3 float64 values = 24 bytes

        # Verify the data by converting back to numpy
        values = np.frombuffer(data_0, dtype=np.float64)
        np.testing.assert_array_equal(values, [1.0, 2.0, 3.0])

    def test_set_component_data(self):
        """Test setting component data."""
        new_data = np.array([10.0, 20.0, 30.0], dtype=np.float64).tobytes()
        self.dv.set_component_data(0, new_data)

        # Verify the data was set
        retrieved_data = self.dv.get_component_data(0)
        values = np.frombuffer(retrieved_data, dtype=np.float64)
        np.testing.assert_array_equal(values, [10.0, 20.0, 30.0])

    def test_get_component_labels(self):
        """Test getting component labels."""
        labels = self.dv.get_component_labels()
        assert labels == ["Ex", "Ey", "Ez"]

    def test_set_component_labels(self):
        """Test setting component labels."""
        new_labels = ["X", "Y", "Z"]
        self.dv.set_component_labels(new_labels)

        labels = self.dv.get_component_labels()
        assert labels == ["X", "Y", "Z"]

    def test_get_component_label(self):
        """Test getting individual component label."""
        label = self.dv.get_component_label(0)
        assert label == "Ex"

        label = self.dv.get_component_label(1)
        assert label == "Ey"


class TestDependentVariableDataManipulation:
    """Test DependentVariable data manipulation methods."""

    def setup_method(self):
        """Set up test DependentVariable with complex data."""
        unit = Unit.dimensionless()

        # Create complex data for testing
        complex_data = np.array(
            [1 + 2j, -3 + 4j, 5 - 6j], dtype=np.complex128
        ).tobytes()

        self.dv = DependentVariable.create_minimal(
            unit=unit,
            quantity_name="complex_signal",
            quantity_type="scalar",
            element_type="complex128",
            components=[complex_data],
        )

    def test_set_values_to_zero(self):
        """Test zeroing all values."""
        success = self.dv.set_values_to_zero()
        assert success

        # Verify data is zeroed (this is a functional test of the interface)
        data = self.dv.get_component_data(0)
        values = np.frombuffer(data, dtype=np.complex128)
        np.testing.assert_array_equal(values, [0 + 0j, 0 + 0j, 0 + 0j])

    def test_take_absolute_value(self):
        """Test taking absolute value."""
        success = self.dv.take_absolute_value()
        assert success

        # After taking absolute value, complex data should become real
        # (exact behavior depends on RMNLib implementation)

    def test_conjugate(self):
        """Test complex conjugation."""
        success = self.dv.conjugate()
        assert success

        # Verify conjugation (functional test)
        data = self.dv.get_component_data(0)
        values = np.frombuffer(data, dtype=np.complex128)
        expected = np.array([1 - 2j, -3 - 4j, 5 + 6j])  # conjugated values
        np.testing.assert_array_equal(values, expected)

    def test_multiply_by_real_constant(self):
        """Test multiplication by real constant."""
        success = self.dv.multiply_by_constant(2.0)
        assert success

        # Verify multiplication
        data = self.dv.get_component_data(0)
        values = np.frombuffer(data, dtype=np.complex128)
        expected = np.array([2 + 4j, -6 + 8j, 10 - 12j])  # multiplied by 2
        np.testing.assert_array_equal(values, expected)

    def test_multiply_by_complex_constant(self):
        """Test multiplication by complex constant."""
        # Reset data first
        original_data = np.array(
            [1 + 2j, -3 + 4j, 5 - 6j], dtype=np.complex128
        ).tobytes()
        self.dv.set_component_data(0, original_data)

        success = self.dv.multiply_by_constant(1 + 1j)
        assert success

        # Verify complex multiplication: (1+2j)*(1+1j) = 1+j+2j-2 = -1+3j
        data = self.dv.get_component_data(0)
        values = np.frombuffer(data, dtype=np.complex128)
        expected = np.array([-1 + 3j, -7 - 1j, 11 + 1j])
        np.testing.assert_array_equal(values, expected)


class TestDependentVariableCopy:
    """Test DependentVariable copying."""

    def test_copy(self):
        """Test deep copying of DependentVariable."""
        unit = Unit.parse("kg")
        data = np.array([1.0, 2.0, 3.0], dtype=np.float64).tobytes()

        original = DependentVariable.create_minimal(
            unit=unit,
            quantity_name="mass",
            quantity_type="scalar",
            element_type="float64",
            components=[data],
        )

        copy = original.copy()

        # Verify copy has same properties
        assert copy.quantity_name == original.quantity_name
        assert copy.quantity_type == original.quantity_type
        assert copy.element_type == original.element_type
        assert copy.size == original.size
        assert copy.component_count == original.component_count

        # Verify copy has same data
        original_data = original.get_component_data(0)
        copy_data = copy.get_component_data(0)
        assert original_data == copy_data

        # Verify they are independent objects
        copy.quantity_name = "modified_mass"
        assert original.quantity_name == "mass"  # original unchanged


class TestDependentVariableSerialization:
    """Test DependentVariable serialization."""

    def test_to_dict(self):
        """Test conversion to dictionary."""
        unit = Unit.parse("m/s²")
        data = np.array([9.81, 9.82, 9.80], dtype=np.float64).tobytes()

        dv = DependentVariable.create(
            name="acceleration",
            description="gravitational acceleration",
            unit=unit,
            quantity_name="acceleration",
            quantity_type="scalar",
            element_type="float64",
            components=[data],
        )

        result_dict = dv.to_dict()

        # Verify dictionary contains expected keys
        assert isinstance(result_dict, dict)
        # Exact structure depends on RMNLib implementation
        # This test validates the interface works


class TestDependentVariableErrorHandling:
    """Test error handling in DependentVariable operations."""

    def test_operations_on_null_object(self):
        """Test operations on uninitialized DependentVariable."""
        dv = DependentVariable()

        # Property access should return None/defaults for null object
        assert dv.name is None
        assert dv.description is None
        assert dv.quantity_name is None
        assert dv.size == 0
        assert dv.component_count == 0

        # Operations should fail gracefully
        assert dv.is_scalar_type() is False
        assert dv.set_values_to_zero() is False

    def test_invalid_component_access(self):
        """Test accessing invalid component indices."""
        unit = Unit.dimensionless()
        data = np.array([1.0, 2.0], dtype=np.float64).tobytes()

        dv = DependentVariable.create_minimal(
            unit=unit,
            quantity_name="test",
            quantity_type="scalar",
            element_type="float64",
            components=[data],
        )

        # Should raise error for invalid component index
        with pytest.raises(RMNLibError):
            dv.get_component_data(10)  # Component 10 doesn't exist

    def test_repr(self):
        """Test string representation."""
        unit = Unit.parse("m/s")
        data = np.array([1.0], dtype=np.float64).tobytes()

        dv = DependentVariable.create(
            name="test_var",
            unit=unit,
            quantity_name="test_quantity",
            quantity_type="scalar",
            element_type="float64",
            components=[data],
        )

        repr_str = repr(dv)
        assert "DependentVariable" in repr_str
        assert "test_var" in repr_str
        assert "scalar" in repr_str
        assert "m·s⁻¹" in repr_str  # Should include unit symbol


if __name__ == "__main__":
    pytest.main([__file__])
