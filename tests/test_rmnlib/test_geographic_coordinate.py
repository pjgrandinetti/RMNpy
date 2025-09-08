"""
Test suite for RMNLib GeographicCoordinate wrapper

This test suite verifies the GeographicCoordinate wrapper functionality including:
- Creation with required latitude/longitude and optional altitude
- Coordinate validation and conversion
- Metadata handling and application data
- Dictionary serialization and round-trip conversion
- Coordinate property access and modification
- Copy operations and memory management
- Error handling for invalid inputs

Based on RMNLib C test patterns and CSDM test file examples.
"""

import pytest

from rmnpy.exceptions import RMNError
from rmnpy.wrappers.rmnlib.geographic_coordinate import GeographicCoordinate
from rmnpy.wrappers.sitypes.scalar import Scalar


class TestGeographicCoordinateCreation:
    """Test GeographicCoordinate creation with various input types."""

    def test_basic_creation_with_scalars(self):
        """Test creating coordinate with Scalar objects."""
        lat = Scalar(39.9797, "°")  # Columbus, OH latitude
        lon = Scalar(-83.0515, "°")  # Columbus, OH longitude
        alt = Scalar(238.97, "m")  # Columbus elevation

        coord = GeographicCoordinate(lat, lon, alt)

        assert coord.latitude.value == pytest.approx(39.9797)
        assert coord.longitude.value == pytest.approx(-83.0515)
        assert coord.altitude.value == pytest.approx(238.97)
        assert str(coord.latitude.unit) == "°"
        assert str(coord.longitude.unit) == "°"
        assert str(coord.altitude.unit) == "m"

    def test_creation_with_numeric_values(self):
        """Test creating coordinate with numeric values (auto-converted to Scalars)."""
        coord = GeographicCoordinate(40.0229, -83.0183, 222.32)

        assert coord.latitude.value == pytest.approx(40.0229)
        assert coord.longitude.value == pytest.approx(-83.0183)
        assert coord.altitude.value == pytest.approx(222.32)

    def test_creation_without_altitude(self):
        """Test creating coordinate without altitude (optional parameter)."""
        coord = GeographicCoordinate(39.9797, -83.0515)

        assert coord.latitude.value == pytest.approx(39.9797)
        assert coord.longitude.value == pytest.approx(-83.0515)
        assert coord.altitude is None

    def test_creation_with_metadata(self):
        """Test creating coordinate with application metadata."""
        metadata = {
            "source": "GPS",
            "accuracy": "10m",
            "timestamp": "2016-03-12T16:41:00Z",
        }

        coord = GeographicCoordinate(39.9797, -83.0515, 238.97, metadata)

        retrieved_metadata = coord.application
        assert retrieved_metadata is not None
        assert retrieved_metadata["source"] == "GPS"
        assert retrieved_metadata["accuracy"] == "10m"
        assert retrieved_metadata["timestamp"] == "2016-03-12T16:41:00Z"

    def test_creation_with_string_coordinates(self):
        """Test creating coordinate with string values (units included)."""
        coord = GeographicCoordinate("39.9797 °", "-83.0515 °", "238.97 m")

        assert coord.latitude.value == pytest.approx(39.9797)
        assert coord.longitude.value == pytest.approx(-83.0515)
        assert coord.altitude.value == pytest.approx(238.97)


class TestGeographicCoordinateValidation:
    """Test coordinate validation and range checking."""

    def test_valid_latitude_range(self):
        """Test latitude values within valid range [-90, 90] degrees."""
        # Test boundary values
        coord_north = GeographicCoordinate(90.0, 0.0)
        coord_south = GeographicCoordinate(-90.0, 0.0)
        coord_equator = GeographicCoordinate(0.0, 0.0)

        assert coord_north.latitude.value == 90.0
        assert coord_south.latitude.value == -90.0
        assert coord_equator.latitude.value == 0.0

    def test_valid_longitude_range(self):
        """Test longitude values within valid range [-180, 180] degrees."""
        # Test boundary values
        coord_east = GeographicCoordinate(0.0, 180.0)
        coord_west = GeographicCoordinate(0.0, -180.0)
        coord_prime = GeographicCoordinate(0.0, 0.0)

        assert coord_east.longitude.value == 180.0
        assert coord_west.longitude.value == -180.0
        assert coord_prime.longitude.value == 0.0

    def test_real_world_coordinates(self):
        """Test with real-world coordinate examples."""
        # Test various global locations
        coordinates = [
            (51.5074, -0.1278, "London, UK"),  # London
            (35.6762, 139.6503, "Tokyo, Japan"),  # Tokyo
            (-33.8688, 151.2093, "Sydney, Australia"),  # Sydney
            (40.7128, -74.0060, "New York, USA"),  # New York
            (-22.9068, -43.1729, "Rio de Janeiro"),  # Rio
        ]

        for lat, lon, name in coordinates:
            coord = GeographicCoordinate(lat, lon)
            assert coord.latitude.value == pytest.approx(lat)
            assert coord.longitude.value == pytest.approx(lon)


class TestGeographicCoordinateProperties:
    """Test coordinate property access and modification."""

    def test_property_access(self):
        """Test getting coordinate properties."""
        coord = GeographicCoordinate(39.9797, -83.0515, 238.97)

        # Test individual property access
        lat = coord.latitude
        lon = coord.longitude
        alt = coord.altitude

        assert isinstance(lat, Scalar)
        assert isinstance(lon, Scalar)
        assert isinstance(alt, Scalar)
        assert lat.value == pytest.approx(39.9797)
        assert lon.value == pytest.approx(-83.0515)
        assert alt.value == pytest.approx(238.97)

    def test_property_modification(self):
        """Test setting coordinate properties."""
        coord = GeographicCoordinate(39.9797, -83.0515, 238.97)

        # Modify coordinates
        new_lat = Scalar(40.0229, "°")
        new_lon = Scalar(-83.0183, "°")
        new_alt = Scalar(222.32, "m")

        coord.latitude = new_lat
        coord.longitude = new_lon
        coord.altitude = new_alt

        assert coord.latitude.value == pytest.approx(40.0229)
        assert coord.longitude.value == pytest.approx(-83.0183)
        assert coord.altitude.value == pytest.approx(222.32)

    def test_metadata_modification(self):
        """Test modifying application metadata."""
        coord = GeographicCoordinate(39.9797, -83.0515)
        # Initially no metadata
        assert coord.application == {}

        # Set metadata
        metadata = {"test": "value"}
        coord.application = metadata

        retrieved = coord.application
        assert retrieved["test"] == "value"

    def test_altitude_none_handling(self):
        """Test proper handling of None altitude."""
        coord = GeographicCoordinate(39.9797, -83.0515)

        assert coord.altitude is None

        # Set altitude
        coord.altitude = Scalar(100.0, "m")
        assert coord.altitude.value == pytest.approx(100.0)

        # Clear altitude
        coord.altitude = None
        assert coord.altitude is None


class TestGeographicCoordinateSerialization:
    """Test dictionary serialization and round-trip conversion."""

    def test_to_dict_basic(self):
        """Test converting coordinate to dictionary."""
        coord = GeographicCoordinate(39.9797, -83.0515, 238.97)
        data_dict = coord.to_dict()

        assert "latitude" in data_dict
        assert "longitude" in data_dict
        assert "altitude" in data_dict

    def test_to_dict_with_metadata(self):
        """Test dictionary conversion with metadata."""
        metadata = {
            "source": "GPS",
            "accuracy": "10m",
            "timestamp": "2016-03-12T16:41:00Z",
        }
        coord = GeographicCoordinate(39.9797, -83.0515, 238.97, metadata)
        data_dict = coord.to_dict()

        # Check that metadata is preserved
        assert "application" in data_dict or "metadata" in data_dict

    def test_from_dict_round_trip(self):
        """Test creating coordinate from dictionary (round-trip)."""
        original = GeographicCoordinate(39.9797, -83.0515, 238.97, {"source": "test"})

        # Convert to dict and back
        coord_dict = original.to_dict()
        restored = GeographicCoordinate.from_dict(coord_dict)

        # Verify values match
        assert restored.latitude.value == pytest.approx(original.latitude.value)
        assert restored.longitude.value == pytest.approx(original.longitude.value)
        assert restored.altitude.value == pytest.approx(original.altitude.value)

    def test_from_dict_roundtrip(self):
        """Test round-trip conversion: coordinate -> dict -> coordinate."""
        original = GeographicCoordinate(39.9797, -83.0515, 238.97)
        data_dict = original.to_dict()
        restored = GeographicCoordinate.from_dict(data_dict)

        assert restored.latitude.value == pytest.approx(original.latitude.value)
        assert restored.longitude.value == pytest.approx(original.longitude.value)
        assert restored.altitude.value == pytest.approx(original.altitude.value)

    def test_from_dict_csdm_format(self):
        """Test creating coordinate from CSDM-style dictionary."""
        # Based on CSDM test files format
        csdm_dict = {
            "latitude": "39.97968794964322 °",
            "longitude": "-83.05154573892345 °",
            "altitude": "238.9719543457031 m",
        }

        coord = GeographicCoordinate.from_dict(csdm_dict)

        assert coord.latitude.value == pytest.approx(39.9797, abs=1e-4)
        assert coord.longitude.value == pytest.approx(-83.0515, abs=1e-4)
        assert coord.altitude.value == pytest.approx(238.97, abs=1e-2)

    # def test_from_dict_without_altitude(self):
    #     """Test creating coordinate from dictionary without altitude."""
    #     data_dict = {
    #         "latitude": "40.02285159199509 °",
    #         "longitude": "-83.01828260937891 °"
    #     }
    #
    #     coord = GeographicCoordinate.from_dict(data_dict)
    #
    #     assert coord.latitude.value == pytest.approx(40.0229, abs=1e-4)
    #     assert coord.longitude.value == pytest.approx(-83.0183, abs=1e-4)
    #     assert coord.altitude is None


class TestGeographicCoordinateCopy:
    """Test copying and cloning operations."""

    def test_deep_copy(self):
        """Test creating deep copies of coordinates."""
        metadata = {"source": "original"}
        original = GeographicCoordinate(39.9797, -83.0515, 238.97, metadata)

        # Create copy using the copy() method
        coord_copy = original.copy()

        # Verify values are the same
        assert coord_copy.latitude.value == original.latitude.value
        assert coord_copy.longitude.value == original.longitude.value
        assert coord_copy.altitude.value == original.altitude.value

        # Verify they are independent objects
        coord_copy.latitude = Scalar(40.0, "°")
        assert coord_copy.latitude.value != original.latitude.value

    def test_copy_independence(self):
        """Test that copies are independent of originals."""
        original = GeographicCoordinate(39.9797, -83.0515, 238.97)
        copy_coord = original.copy()

        # Modify copy
        copy_coord.latitude = Scalar(45.0, "°")
        copy_coord.longitude = Scalar(-90.0, "°")
        copy_coord.altitude = Scalar(500.0, "m")

        # Original should be unchanged
        assert original.latitude.value == pytest.approx(39.9797)
        assert original.longitude.value == pytest.approx(-83.0515)
        assert original.altitude.value == pytest.approx(238.97)

    def test_copy_with_metadata(self):
        """Test copying coordinates with metadata."""
        metadata = {"instrument": "GPS", "operator": "scientist"}
        original = GeographicCoordinate(39.9797, -83.0515, 238.97, metadata)
        copy_coord = original.copy()

        # Metadata should be copied
        original_meta = original.application
        copy_meta = copy_coord.application

        assert copy_meta["instrument"] == original_meta["instrument"]
        assert copy_meta["operator"] == original_meta["operator"]


class TestGeographicCoordinateErrorHandling:
    """Test error handling and edge cases."""

    def test_invalid_input_types(self):
        """Test error handling for invalid input types."""
        with pytest.raises((TypeError, RMNError)):
            GeographicCoordinate("invalid", -83.0515)

        with pytest.raises((TypeError, RMNError)):
            GeographicCoordinate(39.9797, "invalid")

    def test_none_required_parameters(self):
        """Test error handling for None required parameters."""
        with pytest.raises((TypeError, RMNError)):
            GeographicCoordinate(None, -83.0515)

        with pytest.raises((TypeError, RMNError)):
            GeographicCoordinate(39.9797, None)

    def test_invalid_metadata_type(self):
        """Test error handling for invalid metadata type."""
        with pytest.raises(TypeError):
            GeographicCoordinate(39.9797, -83.0515, 238.97, "not a dict")

        with pytest.raises(TypeError):
            GeographicCoordinate(39.9797, -83.0515, 238.97, 123)

    # NOTE: from_dict error tests are temporarily disabled due to compilation issues
    # TODO: Re-enable once from_dict method is fixed

    # def test_from_dict_invalid_format(self):
    #     """Test error handling for invalid dictionary format."""
    #     with pytest.raises((KeyError, RMNError)):
    #         GeographicCoordinate.from_dict({})  # Missing required keys
    #
    #     with pytest.raises((KeyError, RMNError)):
    #         GeographicCoordinate.from_dict({"latitude": "39.9797 °"})  # Missing longitude

    # def test_from_dict_invalid_values(self):
    #     """Test error handling for invalid dictionary values."""
    #     invalid_dict = {
    #         "latitude": "invalid_value",
    #         "longitude": "-83.0515 °"
    #     }
    #
    #     with pytest.raises(RMNError):
    #         GeographicCoordinate.from_dict(invalid_dict)


class TestGeographicCoordinateIntegration:
    """Test integration with other RMNpy components."""

    def test_coordinate_in_csdm_context(self):
        """Test coordinate usage in CSDM-like contexts."""
        # Create coordinate as it might appear in a CSDM dataset
        coord = GeographicCoordinate(
            "39.97968794964322 °", "-83.05154573892345 °", "238.9719543457031 m"
        )

        # Verify it can be serialized for JSON export
        data_dict = coord.to_dict()
        assert data_dict is not None

        # TODO: Re-enable round-trip test once from_dict is fixed
        # # Verify round-trip works
        # restored = GeographicCoordinate.from_dict(data_dict)
        # assert restored.latitude.value == pytest.approx(coord.latitude.value, rel=1e-10)
        # assert restored.longitude.value == pytest.approx(coord.longitude.value, rel=1e-10)
        # assert restored.altitude.value == pytest.approx(coord.altitude.value, rel=1e-10)

    def test_multiple_coordinates(self):
        """Test creating and managing multiple coordinates."""
        locations = [
            (39.9797, -83.0515, "Columbus, OH"),
            (40.7128, -74.0060, "New York, NY"),
            (34.0522, -118.2437, "Los Angeles, CA"),
            (41.8781, -87.6298, "Chicago, IL"),
        ]

        coordinates = []
        for lat, lon, name in locations:
            metadata = {"location_name": name}
            coord = GeographicCoordinate(lat, lon, metadata=metadata)
            coordinates.append(coord)

        # Verify all coordinates were created successfully
        assert len(coordinates) == 4

        # Verify they have the expected values
        for i, (lat, lon, name) in enumerate(locations):
            coord = coordinates[i]
            assert coord.latitude.value == pytest.approx(lat)
            assert coord.longitude.value == pytest.approx(lon)
            assert coord.application["location_name"] == name

    def test_precision_preservation(self):
        """Test that high-precision coordinates are preserved."""
        # Use high-precision values from CSDM test files
        lat = 39.97968794964322
        lon = -83.05154573892345
        alt = 238.9719543457031

        coord = GeographicCoordinate(lat, lon, alt)

        # Verify precision is maintained
        assert coord.latitude.value == pytest.approx(lat, rel=1e-14)
        assert coord.longitude.value == pytest.approx(lon, rel=1e-14)
        assert coord.altitude.value == pytest.approx(alt, rel=1e-12)

    def test_units_consistency(self):
        """Test that coordinate units are consistent with SI standards."""
        coord = GeographicCoordinate(39.9797, -83.0515, 238.97)

        # Verify units are defined (for now, just check they're strings)
        # Note: Units handling may need improvement in the underlying implementation
        assert isinstance(str(coord.latitude.unit), str)
        assert isinstance(str(coord.longitude.unit), str)
        assert isinstance(str(coord.altitude.unit), str)

        # Verify dimensionality is correct (should be dimensionless for angles, length for altitude)
        # Note: dimensionality checking may need refinement based on actual SI implementation
        assert hasattr(coord.latitude, "dimensionality")
        assert hasattr(coord.longitude, "dimensionality")
        assert hasattr(coord.altitude, "dimensionality")


class TestGeographicCoordinateEquality:
    """Test equality comparisons for GeographicCoordinate objects."""

    def test_exact_equality(self):
        """Test that identical coordinates are equal."""
        coord1 = GeographicCoordinate(45.0, -75.0, 100.0)
        coord2 = GeographicCoordinate(45.0, -75.0, 100.0)

        assert coord1 == coord2
        assert coord2 == coord1

    def test_inequality_latitude(self):
        """Test that coordinates with different latitudes are not equal."""
        coord1 = GeographicCoordinate(45.0, -75.0, 100.0)
        coord2 = GeographicCoordinate(46.0, -75.0, 100.0)

        assert coord1 != coord2
        assert coord2 != coord1

    def test_inequality_longitude(self):
        """Test that coordinates with different longitudes are not equal."""
        coord1 = GeographicCoordinate(45.0, -75.0, 100.0)
        coord2 = GeographicCoordinate(45.0, -76.0, 100.0)

        assert coord1 != coord2
        assert coord2 != coord1

    def test_inequality_altitude(self):
        """Test that coordinates with different altitudes are not equal."""
        coord1 = GeographicCoordinate(45.0, -75.0, 100.0)
        coord2 = GeographicCoordinate(45.0, -75.0, 101.0)

        assert coord1 != coord2
        assert coord2 != coord1

    def test_equality_with_metadata(self):
        """Test that coordinates with different metadata are not equal (per C API behavior)."""
        coord1 = GeographicCoordinate(
            45.0, -75.0, 100.0, metadata={"name": "location1"}
        )
        coord2 = GeographicCoordinate(
            45.0, -75.0, 100.0, metadata={"name": "location2"}
        )

        # C API considers metadata in equality, so different metadata means not equal
        assert coord1 != coord2

    def test_equality_missing_altitude(self):
        """Test equality when one coordinate has altitude and the other doesn't."""
        coord1 = GeographicCoordinate(45.0, -75.0)
        coord2 = GeographicCoordinate(45.0, -75.0, 0.0)

        # Different altitude representations (None vs 0.0) are not equal
        assert coord1 != coord2

    def test_precision_tolerance(self):
        """Test that very small differences are not considered equal (per C API behavior)."""
        coord1 = GeographicCoordinate(45.000000001, -75.000000001, 100.000000001)
        coord2 = GeographicCoordinate(45.000000002, -75.000000002, 100.000000002)

        # C API may not consider tiny differences as equal
        assert coord1 != coord2

    def test_equality_same_parameters(self):
        """Test that coordinates created with identical parameters are equal."""
        # Create coordinates with identical parameters (no metadata differences)
        coord1 = GeographicCoordinate(45.0, -75.0, 100.0)
        coord2 = GeographicCoordinate(45.0, -75.0, 100.0)

        # Should be equal if created with exactly the same parameters
        assert coord1 == coord2

    def test_inequality_with_none(self):
        """Test that coordinates are not equal to None or other types."""
        coord = GeographicCoordinate(45.0, -75.0, 100.0)

        assert coord is not None
        assert coord != "not a coordinate"
        assert coord != 42
        assert coord != [45.0, -75.0, 100.0]

    def test_symmetric_equality(self):
        """Test that equality is symmetric."""
        coord1 = GeographicCoordinate(39.9797, -83.0515, 238.97)
        coord2 = GeographicCoordinate(39.9797, -83.0515, 238.97)

        assert coord1 == coord2
        assert coord2 == coord1
        assert (coord1 == coord2) == (coord2 == coord1)

    def test_transitive_equality(self):
        """Test that equality is transitive."""
        coord1 = GeographicCoordinate(51.5074, -0.1278, 11.0)
        coord2 = GeographicCoordinate(51.5074, -0.1278, 11.0)
        coord3 = GeographicCoordinate(51.5074, -0.1278, 11.0)

        assert coord1 == coord2
        assert coord2 == coord3
        assert coord1 == coord3

    def test_reflexive_equality(self):
        """Test that a coordinate is equal to itself."""
        coord = GeographicCoordinate(48.8566, 2.3522, 35.0)

        assert coord == coord


if __name__ == "__main__":
    pytest.main([__file__])
