"""
Test suite for Datum wrapper

Based on the RMNLib C API test suite (test_Datum.c) to ensure
our Python wrappers provide equivalent functionality and behavior.
"""

import numpy as np
import pytest

from rmnpy.wrappers.rmnlib.datum import Datum


class TestDatumCreation:
    """Test Datum creation functionality similar to test_Datum.c"""

    def test_basic_creation(self):
        """Test basic Datum creation with valid parameters"""
        response = 10.5
        coordinates = [1.0, 2.0, 3.0]
        dv_index = 0
        component_index = 0
        mem_offset = 0

        datum = Datum(
            response=response,
            coordinates=coordinates,
            dependent_variable_index=dv_index,
            component_index=component_index,
            mem_offset=mem_offset,
        )

        assert datum is not None
        assert datum.response == response
        assert datum.dependent_variable_index == dv_index
        assert datum.component_index == component_index
        assert datum.mem_offset == mem_offset
        assert datum.coordinates_count == len(coordinates)

    def test_creation_with_empty_coordinates(self):
        """Test Datum creation with empty coordinates list"""
        datum = Datum(
            response=5.0,
            coordinates=[],
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        assert datum is not None
        assert datum.response == 5.0
        assert datum.coordinates_count == 0

    def test_creation_with_none_coordinates(self):
        """Test Datum creation with None coordinates"""
        datum = Datum(
            response=7.5,
            coordinates=None,
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        assert datum is not None
        assert datum.response == 7.5
        assert datum.coordinates_count == 0

    def test_creation_with_numpy_coordinates(self):
        """Test Datum creation with numpy array coordinates"""
        coordinates = np.array([1.5, 2.5, 3.5])

        datum = Datum(
            response=12.0,
            coordinates=coordinates,
            dependent_variable_index=1,
            component_index=2,
            mem_offset=10,
        )

        assert datum is not None
        assert datum.response == 12.0
        assert datum.coordinates_count == len(coordinates)


class TestDatumProperties:
    """Test Datum property getters and setters"""

    def _create_test_datum(self):
        """Helper to create a test datum"""
        return Datum(
            response=1.0,
            coordinates=[1.0, 2.0],
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

    def test_response_property(self):
        """Test response property getter"""
        datum = self._create_test_datum()
        assert datum.response == 1.0

        # Test with different response value
        datum2 = Datum(
            response=-5.5,
            coordinates=[],
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )
        assert datum2.response == -5.5

    def test_coordinates_property(self):
        """Test coordinates property getter"""
        coordinates = [1.5, 2.5, 3.5, 4.5]
        datum = Datum(
            response=1.0,
            coordinates=coordinates,
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        retrieved_coords = datum.coordinates
        assert len(retrieved_coords) == len(coordinates)
        for i, coord in enumerate(coordinates):
            assert retrieved_coords[i] == coord

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
        """Test coordinates_count property getter"""
        # Test with various coordinate counts
        test_cases = [[], [1.0], [1.0, 2.0], [1.0, 2.0, 3.0, 4.0, 5.0]]

        for coordinates in test_cases:
            datum = Datum(
                response=1.0,
                coordinates=coordinates,
                dependent_variable_index=0,
                component_index=0,
                mem_offset=0,
            )
            assert datum.coordinates_count == len(coordinates)


class TestDatumCoordinateAccess:
    """Test Datum coordinate access functionality"""

    def test_get_coordinate(self):
        """Test get_coordinate method"""
        coordinates = [10.5, 20.5, 30.5]
        datum = Datum(
            response=1.0,
            coordinates=coordinates,
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        # Test valid indices
        assert datum.get_coordinate(0) == 10.5
        assert datum.get_coordinate(1) == 20.5
        assert datum.get_coordinate(2) == 30.5

        # Test invalid index (should raise exception or return None)
        with pytest.raises(Exception):  # Could be IndexError or RMNError
            datum.get_coordinate(3)

        with pytest.raises(Exception):
            datum.get_coordinate(-1)

    def test_get_coordinate_empty_coordinates(self):
        """Test get_coordinate with empty coordinates"""
        datum = Datum(
            response=1.0,
            coordinates=[],
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
        # Create two datums with same coordinate count
        datum1 = Datum(
            response=1.0,
            coordinates=[1.0, 2.0, 3.0],
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        datum2 = Datum(
            response=2.0,
            coordinates=[4.0, 5.0, 6.0],
            dependent_variable_index=1,
            component_index=1,
            mem_offset=10,
        )

        # Should have same reduced dimensionalities (same coordinate count)
        assert datum1.has_same_reduced_dimensionalities(datum2)

        # Create datum with different coordinate count
        datum3 = Datum(
            response=3.0,
            coordinates=[7.0, 8.0],  # Different count
            dependent_variable_index=2,
            component_index=2,
            mem_offset=20,
        )

        # Should not have same reduced dimensionalities
        assert not datum1.has_same_reduced_dimensionalities(datum3)
        assert not datum2.has_same_reduced_dimensionalities(datum3)

    def test_has_same_reduced_dimensionalities_empty(self):
        """Test has_same_reduced_dimensionalities with empty coordinates"""
        datum1 = Datum(
            response=1.0,
            coordinates=[],
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        datum2 = Datum(
            response=2.0,
            coordinates=[],
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        # Both have empty coordinates, should be same
        assert datum1.has_same_reduced_dimensionalities(datum2)

        # Create datum with non-empty coordinates
        datum3 = Datum(
            response=3.0,
            coordinates=[1.0],
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        # Should not be same
        assert not datum1.has_same_reduced_dimensionalities(datum3)


class TestDatumEdgeCases:
    """Test Datum edge cases and error conditions"""

    def test_negative_response(self):
        """Test Datum with negative response value"""
        datum = Datum(
            response=-100.5,
            coordinates=[1.0, 2.0],
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        assert datum.response == -100.5

    def test_zero_response(self):
        """Test Datum with zero response value"""
        datum = Datum(
            response=0.0,
            coordinates=[1.0, 2.0],
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        assert datum.response == 0.0

    def test_large_coordinates(self):
        """Test Datum with large number of coordinates"""
        large_coordinates = list(range(1000))  # 1000 coordinates

        datum = Datum(
            response=1.0,
            coordinates=large_coordinates,
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        assert datum.coordinates_count == 1000
        assert datum.get_coordinate(0) == 0.0
        assert datum.get_coordinate(999) == 999.0

    def test_mixed_coordinate_types(self):
        """Test Datum with mixed numeric types in coordinates"""
        mixed_coords = [1, 2.5, 3.0, 4]  # Mix of int and float

        datum = Datum(
            response=1.0,
            coordinates=mixed_coords,
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        assert datum.coordinates_count == 4
        # All should be converted to float
        assert datum.get_coordinate(0) == 1.0
        assert datum.get_coordinate(1) == 2.5
        assert datum.get_coordinate(2) == 3.0
        assert datum.get_coordinate(3) == 4.0


class TestDatumStringRepresentation:
    """Test Datum string representation"""

    def test_str_and_repr(self):
        """Test __str__ and __repr__ methods"""
        datum = Datum(
            response=42.5,
            coordinates=[1.0, 2.0, 3.0],
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


if __name__ == "__main__":
    pytest.main([__file__])
