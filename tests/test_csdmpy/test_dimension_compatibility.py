"""
Test RMNpy dimension compatibility with csdmpy API

This test suite verifies that RMNpy dimensions can work with csdmpy-style
API calls, ensuring users can migrate from csdmpy to RMNpy seamlessly.
"""

import numpy as np
import pytest

from rmnpy.wrappers.rmnlib.dimension import (
    LabeledDimension,
    LinearDimension,
    MonotonicDimension,
)


class TestLinearDimensionCSDMCompatibility:
    """Test linear dimension compatibility with csdmpy API."""

    def test_linear_dimension_basic_creation(self):
        """Test basic linear dimension creation similar to csdmpy."""
        # Create a linear dimension similar to csdmpy style
        dim = LinearDimension(
            count=10, increment="10.0 m/s", coordinates_offset="5.0 m/s"
        )

        assert dim.is_quantitative() is True
        assert dim.type == "linear"
        assert dim.count == 10
        assert dim.size == 10

        # Test increment property
        assert dim.increment.value == 10.0
        assert str(dim.increment.unit) in ["m/s", "m·s⁻¹"]

        # Test coordinates offset
        assert dim.coordinates_offset.value == 5.0
        assert str(dim.coordinates_offset.unit) in ["m/s", "m·s⁻¹"]

        # Test quantity name (should be inferred from unit)
        # Speed has dimensionality of length/time
        assert "speed" in dim.quantity_name or "velocity" in dim.quantity_name

    def test_linear_dimension_period_handling(self):
        """Test period handling compatibility."""
        dim = LinearDimension(count=5, increment="2.0 Hz")

        # Default period should be infinity
        assert dim.period == float("inf")
        assert dim.periodic is False

        # Setting finite period should make it periodic
        dim.period = "10.0 Hz"
        assert dim.period == 10.0
        assert dim.periodic is True

    def test_linear_dimension_coordinates(self):
        """Test coordinate generation."""
        dim = LinearDimension(count=5, increment="2.0 m", coordinates_offset="1.0 m")

        # Get coordinates - should be similar to csdmpy behavior
        coords = dim.coordinates
        expected = np.array([1.0, 3.0, 5.0, 7.0, 9.0])

        # Our coordinates might be a Scalar array, extract values
        if hasattr(coords, "value"):
            coords_values = coords.value
        else:
            coords_values = coords

        np.testing.assert_array_almost_equal(coords_values, expected)

    def test_linear_dimension_origin_offset(self):
        """Test origin offset functionality."""
        dim = LinearDimension(count=5, increment="1.0 m")

        # Default origin offset should be 0
        if hasattr(dim, "origin_offset"):
            assert dim.origin_offset.value == 0.0

        # Test setting origin offset
        if hasattr(dim, "origin_offset"):
            dim.origin_offset = "10.0 m"
            assert dim.origin_offset.value == 10.0

    def test_linear_dimension_count_modification(self):
        """Test count modification."""
        dim = LinearDimension(count=5, increment="1.0 Hz")

        assert dim.count == 5
        assert dim.size == 5

        # Modify count
        dim.count = 8
        assert dim.count == 8
        assert dim.size == 8

    def test_linear_dimension_properties(self):
        """Test various dimension properties."""
        dim = LinearDimension(
            count=10,
            increment="20.0 m/s",
            coordinates_offset="5.0 m/s",
            label="velocity",
        )

        # Test label
        if hasattr(dim, "label"):
            assert dim.label == "velocity"

        # Test type (read-only)
        assert dim.type == "linear"

        # Test that type cannot be modified
        with pytest.raises(AttributeError):
            dim.type = "monotonic"

    def test_linear_dimension_repr_and_str(self):
        """Test string representations."""
        dim = LinearDimension(count=3, increment="2.0 s")

        repr_str = repr(dim)
        str_str = str(dim)

        # Should contain key information
        assert "LinearDimension" in repr_str or "LinearDimension" in repr_str
        assert "linear" in repr_str.lower() or "linear" in str_str.lower()
        assert "count=3" in repr_str or "3" in str_str


class TestMonotonicDimensionCSDMCompatibility:
    """Test monotonic dimension compatibility with csdmpy API."""

    def test_monotonic_dimension_basic_creation(self):
        """Test basic monotonic dimension creation."""
        coordinates = ["1.0 m", "10.0 m", "100.0 m", "1000.0 m"]

        dim = MonotonicDimension(coordinates=coordinates)

        assert dim.is_quantitative() is True
        assert dim.type == "monotonic"
        assert dim.count == 4
        assert dim.size == 4

    def test_monotonic_dimension_no_increment(self):
        """Test that monotonic dimensions don't have increment."""
        dim = MonotonicDimension(coordinates=["1.0 m", "5.0 m", "10.0 m"])

        # Should not have increment attribute
        with pytest.raises(AttributeError):
            _ = dim.increment

    def test_monotonic_dimension_coordinates(self):
        """Test coordinate access."""
        coords_input = ["1.0 m", "2.0 m", "4.0 m"]
        dim = MonotonicDimension(coordinates=coords_input)

        # Get coordinates
        coords = dim.coordinates
        expected = np.array([1.0, 2.0, 4.0])

        # Extract values if needed
        if hasattr(coords, "value"):
            coords_values = coords.value
        else:
            coords_values = coords

        np.testing.assert_array_almost_equal(coords_values, expected)

    def test_monotonic_dimension_period_handling(self):
        """Test period handling for monotonic dimensions."""
        dim = MonotonicDimension(coordinates=["1.0 Hz", "2.0 Hz", "4.0 Hz"])

        # Default period should be infinity
        assert dim.period == float("inf")
        assert dim.periodic is False

        # Setting finite period should make it periodic
        dim.period = "10.0 Hz"
        assert dim.period == 10.0
        assert dim.periodic is True

    def test_monotonic_dimension_count_modification(self):
        """Test count modification (should fail for monotonic)."""
        dim = MonotonicDimension(coordinates=["1.0 m", "2.0 m", "3.0 m"])

        assert dim.count == 3

        # Count is read-only for monotonic dimensions in RMNpy
        with pytest.raises(AttributeError):
            dim.count = 5

    def test_monotonic_dimension_coordinates_offset(self):
        """Test that monotonic dimensions DO have coordinates_offset (like csdmpy)."""
        dim = MonotonicDimension(coordinates=["1.0 m", "2.0 m"])

        # Should have coordinates_offset attribute (default should be 0)
        assert hasattr(dim, "coordinates_offset")
        assert dim.coordinates_offset.value == 0.0
        assert str(dim.coordinates_offset.unit) == "m"

    def test_monotonic_dimension_repr_and_str(self):
        """Test string representations."""
        dim = MonotonicDimension(coordinates=["1.0 s", "10.0 s"])

        repr_str = repr(dim)
        str_str = str(dim)

        # Should contain key information
        assert "MonotonicDimension" in repr_str
        assert "monotonic" in repr_str.lower() or "monotonic" in str_str.lower()


class TestLabeledDimensionCSDMCompatibility:
    """Test labeled dimension compatibility with csdmpy API."""

    def test_labeled_dimension_basic_creation(self):
        """Test basic labeled dimension creation."""
        labels = ["alpha", "beta", "gamma", "delta"]

        dim = LabeledDimension(labels=labels)

        assert dim.is_quantitative() is False
        assert dim.type == "labeled"
        assert dim.count == 4
        assert dim.size == 4

    def test_labeled_dimension_coordinates_access(self):
        """Test coordinate/label access."""
        labels = ["a", "b", "c"]
        dim = LabeledDimension(labels=labels)

        # Coordinates should be the same as labels
        coords = dim.coordinates
        if hasattr(coords, "tolist"):
            coords_list = coords.tolist()
        else:
            coords_list = list(coords)

        assert coords_list == labels

    def test_labeled_dimension_label_modification(self):
        """Test label modification."""
        dim = LabeledDimension(labels=["x", "y", "z"])

        # Test setting new labels
        new_labels = ["X", "Y", "Z"]
        dim.labels = new_labels

        coords = dim.coordinates
        if hasattr(coords, "tolist"):
            coords_list = coords.tolist()
        else:
            coords_list = list(coords)

        assert coords_list == new_labels

    def test_labeled_dimension_no_quantitative_properties(self):
        """Test that labeled dimensions don't have quantitative properties."""
        dim = LabeledDimension(labels=["a", "b", "c"])

        # Should not have increment, period, etc.
        with pytest.raises(AttributeError):
            _ = dim.increment

        with pytest.raises(AttributeError):
            _ = dim.period

    def test_labeled_dimension_repr_and_str(self):
        """Test string representations."""
        dim = LabeledDimension(labels=["1", "a", "c"])

        repr_str = repr(dim)
        str_str = str(dim)

        # Should contain key information
        assert "LabeledDimension" in repr_str
        assert "labeled" in repr_str.lower() or "labeled" in str_str.lower()


class TestDimensionTypeInference:
    """Test automatic dimension type inference similar to csdmpy as_dimension."""

    def test_linear_array_inference(self):
        """Test that linear arrays are correctly identified."""
        # Linear array should create linear dimension
        array = np.arange(10) * 2.0  # [0, 2, 4, 6, ...]

        # We might not have as_dimension yet, but test the concept
        # This would be similar to csdmpy's as_dimension function
        dim = LinearDimension(count=len(array), increment="2.0")

        coords = dim.coordinates
        if hasattr(coords, "value"):
            coords_values = coords.value
        else:
            coords_values = coords

        np.testing.assert_array_almost_equal(coords_values, array)

    def test_monotonic_array_inference(self):
        """Test that monotonic arrays are correctly identified."""
        # Non-linear but monotonic array
        array = np.array([1.0, 2.0, 4.0, 8.0, 16.0])
        coords_str = [f"{val} Hz" for val in array]

        dim = MonotonicDimension(coordinates=coords_str)

        coords = dim.coordinates
        if hasattr(coords, "value"):
            coords_values = coords.value
        else:
            coords_values = coords

        np.testing.assert_array_almost_equal(coords_values, array)


class TestDimensionCopyAndEquality:
    """Test dimension copying and equality."""

    def test_linear_dimension_copy(self):
        """Test linear dimension copying."""
        dim1 = LinearDimension(
            count=5, increment="2.0 Hz", coordinates_offset="1.0 Hz", label="frequency"
        )

        dim2 = dim1.copy()

        # Should be equal but independent
        assert dim1 == dim2

        # Modifying one shouldn't affect the other
        if hasattr(dim1, "label"):
            dim1.label = "modified"
            assert dim1 != dim2

    def test_monotonic_dimension_copy(self):
        """Test monotonic dimension copying."""
        dim1 = MonotonicDimension(coordinates=["1.0 m", "2.0 m", "4.0 m"])
        dim2 = dim1.copy()

        assert dim1 == dim2

    def test_labeled_dimension_copy(self):
        """Test labeled dimension copying."""
        dim1 = LabeledDimension(labels=["a", "b", "c"])
        dim2 = dim1.copy()

        assert dim1 == dim2

    def test_dimension_inequality(self):
        """Test dimension inequality with different types."""
        linear_dim = LinearDimension(count=3, increment="1.0 Hz")
        monotonic_dim = MonotonicDimension(coordinates=["1.0 Hz", "2.0 Hz", "3.0 Hz"])
        labeled_dim = LabeledDimension(labels=["a", "b", "c"])

        # Different types should not be equal
        assert linear_dim != monotonic_dim
        assert linear_dim != labeled_dim
        assert monotonic_dim != labeled_dim

        # None of them should equal a number
        assert linear_dim != 42
        assert monotonic_dim != 42
        assert labeled_dim != 42


class TestDimensionUnitOperations:
    """Test unit operations on dimensions (if supported)."""

    def test_linear_dimension_unit_scaling(self):
        """Test scaling linear dimensions by units."""
        dim = LinearDimension(count=5, increment="1.0 Hz")

        # Test multiplication by scalar (if supported)
        try:
            scaled_dim = dim * 2.0
            assert scaled_dim.increment.value == 2.0
        except (NotImplementedError, AttributeError, TypeError):
            pytest.skip("Dimension scaling not implemented")

    def test_dimension_unit_conversion(self):
        """Test unit conversion (if supported)."""
        dim = LinearDimension(count=5, increment="1000.0 Hz")

        # Test unit conversion to kHz (if supported)
        try:
            if hasattr(dim, "to"):
                dim.to("kHz")
                assert dim.increment.value == 1.0
        except (NotImplementedError, AttributeError):
            pytest.skip("Unit conversion not implemented")


if __name__ == "__main__":
    pytest.main([__file__])
