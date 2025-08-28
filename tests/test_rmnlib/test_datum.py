"""
Test suite for Datum wrapper

Based on the RMNLib C API test suite (test_Datum.c) to ensure
our Python wrappers provide equivalent functionality and behavior.
"""

import pytest

from rmnpy.exceptions import RMNError
from rmnpy.wrappers.rmnlib.datum import Datum


class TestDatumCreation:
    """Test Datum creation functionality similar to test_Datum.c"""

    def test_basic_creation(self):
        """Test basic Datum creation with valid parameters"""
        response = 10.5
        dv_index = 0
        component_index = 0
        mem_offset = 0

        datum = Datum(
            response=response,
            dependent_variable_index=dv_index,
            component_index=component_index,
            mem_offset=mem_offset,
        )

        assert datum is not None
        # Response is returned as a Scalar object
        assert datum.response.value == response
        assert datum.dependent_variable_index == dv_index
        assert datum.component_index == component_index
        assert datum.mem_offset == mem_offset
        # Coordinates count is 0 when no owner Dataset
        assert datum.coordinates_count == 0

    def test_creation_with_empty_coordinates(self):
        """Test Datum creation - coordinates are managed by Dataset, not Datum directly"""
        datum = Datum(
            response=5.0,
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        assert datum is not None
        assert datum.response.value == 5.0
        # Coordinates count is always 0 when no owner Dataset
        assert datum.coordinates_count == 0

    def test_creation_with_none_coordinates(self):
        """Test Datum creation - coordinates parameter not used"""
        datum = Datum(
            response=7.5,
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        assert datum is not None
        assert datum.response.value == 7.5
        assert datum.coordinates_count == 0

    def test_creation_with_numpy_coordinates(self):
        """Test Datum creation - numpy arrays not used for coordinates in constructor"""
        datum = Datum(
            response=12.0,
            dependent_variable_index=1,
            component_index=2,
            mem_offset=10,
        )

        assert datum is not None
        assert datum.response.value == 12.0
        # Coordinates are managed by Dataset, not Datum constructor
        assert datum.coordinates_count == 0


class TestDatumProperties:
    """Test Datum property getters and setters"""

    def _create_test_datum(self):
        """Helper to create a test datum"""
        return Datum(
            response=1.0,
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

    def test_response_property(self):
        """Test response property getter"""
        datum = self._create_test_datum()
        assert datum.response.value == 1.0

        # Test with different response value
        datum2 = Datum(
            response=-5.5,
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )
        assert datum2.response.value == -5.5

    def test_coordinates_property(self):
        """Test coordinates property getter - empty when no owner Dataset"""
        datum = Datum(
            response=1.0,
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        retrieved_coords = datum.coordinates
        # Should be empty list when no owner Dataset
        assert len(retrieved_coords) == 0
        assert retrieved_coords == []

    def test_dependent_variable_index_property(self):
        """Test dependent_variable_index property getter and setter"""
        datum = self._create_test_datum()

        # Test getter
        assert datum.dependent_variable_index == 0

        # Test setter
        datum.dependent_variable_index = 5
        assert datum.dependent_variable_index == 5

        # Test with different values
        datum.dependent_variable_index = 100
        assert datum.dependent_variable_index == 100

    def test_component_index_property(self):
        """Test component_index property getter and setter"""
        datum = self._create_test_datum()

        # Test getter
        assert datum.component_index == 0

        # Test setter
        datum.component_index = 3
        assert datum.component_index == 3

        # Test with different values
        datum.component_index = 50
        assert datum.component_index == 50

    def test_mem_offset_property(self):
        """Test mem_offset property getter and setter"""
        datum = self._create_test_datum()

        # Test getter
        assert datum.mem_offset == 0

        # Test setter
        datum.mem_offset = 1024
        assert datum.mem_offset == 1024

        # Test with different values
        datum.mem_offset = 2048
        assert datum.mem_offset == 2048

    def test_coordinates_count_property(self):
        """Test coordinates_count property getter - always 0 when no owner Dataset"""
        # All Datums without owner Dataset have 0 coordinates
        datum = Datum(
            response=1.0,
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )
        assert datum.coordinates_count == 0


class TestDatumCoordinateAccess:
    """Test Datum coordinate access functionality"""

    def test_get_coordinate(self):
        """Test get_coordinate method - should raise IndexError when no coordinates"""
        datum = Datum(
            response=1.0,
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        # Test out of range - should raise IndexError since coordinates_count is 0
        with pytest.raises(IndexError):
            datum.get_coordinate(0)

        with pytest.raises(IndexError):
            datum.get_coordinate(1)

        with pytest.raises(IndexError):
            datum.get_coordinate(2)

        # Test invalid index (should raise exception or return None)
        with pytest.raises(Exception):  # Could be IndexError or RMNError
            datum.get_coordinate(3)

        with pytest.raises(Exception):
            datum.get_coordinate(-1)

    def test_get_coordinate_empty_coordinates(self):
        """Test get_coordinate with empty coordinates"""
        datum = Datum(
            response=1.0,
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        # Any index should fail with empty coordinates
        with pytest.raises(Exception):
            datum.get_coordinate(0)


class TestDatumComparison:
    """Test Datum comparison functionality"""

    def test_has_same_reduced_dimensionalities(self):
        """Test has_same_reduced_dimensionalities method"""
        # Create two datums - both have same coordinate count (0) when no owner Dataset
        datum1 = Datum(
            response=1.0,
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        datum2 = Datum(
            response=2.0,
            dependent_variable_index=1,
            component_index=1,
            mem_offset=10,
        )

        # Should have same reduced dimensionalities (both have 0 coordinates)
        assert datum1.has_same_reduced_dimensionalities(datum2)

        # Create third datum - also has 0 coordinates
        datum3 = Datum(
            response=3.0,
            dependent_variable_index=2,
            component_index=2,
            mem_offset=20,
        )

        # Should still have same reduced dimensionalities
        assert datum1.has_same_reduced_dimensionalities(datum3)
        assert datum2.has_same_reduced_dimensionalities(datum3)

    def test_has_same_reduced_dimensionalities_empty(self):
        """Test has_same_reduced_dimensionalities - all standalone Datums have 0 coordinates"""
        datum1 = Datum(
            response=1.0,
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        datum2 = Datum(
            response=2.0,
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        # Both have 0 coordinates (no owner Dataset), should be same
        assert datum1.has_same_reduced_dimensionalities(datum2)

        # Create third datum - also has 0 coordinates
        datum3 = Datum(
            response=3.0,
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        # Should be same - all standalone Datums have 0 coordinates
        assert datum1.has_same_reduced_dimensionalities(datum3)


class TestDatumEdgeCases:
    """Test Datum edge cases and error conditions"""

    def test_negative_response(self):
        """Test Datum with negative response value"""
        datum = Datum(
            response=-100.5,
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        assert datum.response.value == -100.5

    def test_zero_response(self):
        """Test Datum with zero response value"""
        datum = Datum(
            response=0.0,
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        assert datum.response.value == 0.0

    def test_large_coordinates(self):
        """Test Datum coordinates - managed by Dataset, not Datum directly"""
        datum = Datum(
            response=1.0,
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        # Coordinates are managed by Dataset, not Datum
        assert datum.coordinates_count == 0

    def test_mixed_coordinate_types(self):
        """Test Datum coordinates - managed by Dataset, not Datum directly"""
        datum = Datum(
            response=1.0,
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        # Coordinates are managed by Dataset, not Datum
        assert datum.coordinates_count == 0


class TestDatumStringRepresentation:
    """Test Datum string representation"""

    def test_str_and_repr(self):
        """Test __str__ and __repr__ methods"""
        datum = Datum(
            response=42.5,
            dependent_variable_index=1,
            component_index=2,
            mem_offset=100,
        )

        # Test __str__
        str_repr = str(datum)
        assert isinstance(str_repr, str)
        assert "Datum" in str_repr

        # Test __repr__
        repr_str = repr(datum)
        assert isinstance(repr_str, str)
        assert "Datum" in repr_str


class TestDatumRoundTrip:
    """Test Datum serialization round trip functionality."""

    def test_basic_round_trip(self):
        """Test basic round trip with Datum serialization."""
        # Use simple numeric values like existing tests
        response = 10.5

        original = Datum(
            response=response,
            dependent_variable_index=0,
            component_index=1,
            mem_offset=42,
        )

        # Round trip
        datum_dict = original.to_dict()
        restored = Datum.from_dict(datum_dict)

        # Verify basic properties
        assert restored.dependent_variable_index == original.dependent_variable_index
        assert restored.component_index == original.component_index
        assert restored.mem_offset == original.mem_offset
        assert restored.coordinates_count == original.coordinates_count

    def test_minimal_round_trip(self):
        """Test round trip with minimal Datum (no coordinates)."""
        response = 5.0  # Simple numeric value

        original = Datum(
            response=response,
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        # Round trip
        datum_dict = original.to_dict()
        restored = Datum.from_dict(datum_dict)

        # Verify properties
        assert restored.dependent_variable_index == original.dependent_variable_index
        assert restored.component_index == original.component_index
        assert restored.mem_offset == original.mem_offset
        assert restored.coordinates_count == 0

    def test_multi_coordinate_round_trip(self):
        """Test round trip - coordinates managed by Dataset, not Datum directly."""
        response = 42.0  # Simple numeric value

        original = Datum(
            response=response,
            dependent_variable_index=2,
            component_index=1,
            mem_offset=100,
        )

        # Round trip
        datum_dict = original.to_dict()
        restored = Datum.from_dict(datum_dict)

        # Verify properties
        assert restored.dependent_variable_index == original.dependent_variable_index
        assert restored.component_index == original.component_index
        assert restored.mem_offset == original.mem_offset
        # Coordinates are managed by Dataset, not Datum directly
        assert restored.coordinates_count == 0

    def test_from_dict_error_handling(self):
        """Test from_dict error handling with invalid input."""
        # Test with non-dictionary
        with pytest.raises(TypeError):
            Datum.from_dict("not a dict")

        # Test with empty dictionary
        with pytest.raises(RMNError):
            Datum.from_dict({})

    def test_to_dict_structure(self):
        """Test that to_dict returns expected dictionary structure."""
        # Use a simple numeric response instead of Scalar
        response = 7.5

        datum = Datum(
            response=response,
            dependent_variable_index=1,
            component_index=0,
            mem_offset=50,
        )

        datum_dict = datum.to_dict()

        # Verify dictionary structure
        assert isinstance(datum_dict, dict)
        # Check for expected keys (exact structure depends on C implementation)
        # We just verify it's a valid dictionary that can be used for from_dict
        restored = Datum.from_dict(datum_dict)
        assert isinstance(restored, Datum)


if __name__ == "__main__":
    pytest.main([__file__])
