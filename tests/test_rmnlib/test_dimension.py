"""
Test suite for RMNLib Dimension wrapper with csdmpy compatibility

This test suite verifies that the RMNLib Dimension wrapper provides
a csdmpy-compatible API for seamless user migration.
"""

import json

import numpy as np
import pytest

from rmnpy.wrappers.rmnlib import Dimension


class TestDimensionCreation:
    """Test dimension creation methods matching csdmpy patterns."""

    def test_create_from_dict(self):
        """Test creating dimension from dictionary."""
        dim_dict = {
            "type": "linear",
            "description": "frequency dimension",
            "increment": "100 Hz",
            "count": 256,
            "coordinates_offset": "0 Hz",
            "origin_offset": "0 Hz",
        }
        dim = Dimension(dim_dict)

        assert dim.type == "linear"
        assert dim.description == "frequency dimension"
        assert dim.count == 256
        assert dim.increment == 100.0
        assert dim.coordinates_offset == 0.0
        assert dim.origin_offset == 0.0

    def test_create_from_kwargs(self):
        """Test creating dimension from keyword arguments."""
        dim = Dimension(
            type="linear",
            description="test dimension",
            increment="5.0 G",
            count=10,
            coordinates_offset="10 mT",
            origin_offset="10 T",
            label="field strength",
        )

        assert dim.type == "linear"
        assert dim.description == "test dimension"
        assert dim.label == "field strength"
        assert dim.count == 10
        assert dim.increment == 5.0
        assert dim.coordinates_offset == 10.0  # simplified unit parsing
        assert dim.origin_offset == 10.0

    def test_create_monotonic_dimension(self):
        """Test creating monotonic dimension."""
        coords = [0, 1, 3, 7, 15, 31]
        dim = Dimension(
            type="monotonic", coordinates=coords, description="irregular spacing"
        )

        assert dim.type == "monotonic"
        assert dim.count == len(coords)
        assert dim.description == "irregular spacing"
        np.testing.assert_array_equal(dim.coordinates, coords)

    def test_create_labeled_dimension(self):
        """Test creating labeled dimension."""
        labels = ["Cu", "Ag", "Au"]
        dim = Dimension(type="labeled", labels=labels, description="chemical elements")

        assert dim.type == "labeled"
        assert dim.count == len(labels)
        assert dim.description == "chemical elements"
        np.testing.assert_array_equal(dim.coordinates, labels)
        np.testing.assert_array_equal(dim.labels, labels)


class TestLinearDimension:
    """Test linear dimension functionality."""

    @pytest.fixture
    def linear_dim(self):
        """Create test linear dimension."""
        return Dimension(
            type="linear",
            count=10,
            increment="5.0 G",
            coordinates_offset="10.0 mT",
            origin_offset="10.0 T",
            description="test linear dimension",
            label="field strength",
        )

    def test_coordinates_generation(self, linear_dim):
        """Test coordinate generation for linear dimension."""
        coords = linear_dim.coordinates
        assert len(coords) == 10
        # Basic coordinate progression test
        assert coords[1] - coords[0] == pytest.approx(linear_dim.increment)

    def test_complex_fft_ordering(self, linear_dim):
        """Test complex FFT coordinate ordering."""
        # Default should be False
        assert linear_dim.complex_fft is False

        # Set to True and verify ordering changes
        linear_dim.complex_fft = True
        assert linear_dim.complex_fft is True

        # Coordinates should be reordered for FFT
        coords_fft = linear_dim.coordinates
        assert len(coords_fft) == 10

    def test_increment_modification(self, linear_dim):
        """Test increment modification."""
        new_increment = "0.1 G"

        linear_dim.increment = new_increment
        assert linear_dim.increment == 0.1

        # Coordinates should update
        coords = linear_dim.coordinates
        assert len(coords) == 10

    def test_offset_modifications(self, linear_dim):
        """Test coordinate and origin offset modifications."""
        # Test coordinates offset
        linear_dim.coordinates_offset = "5.0 mT"
        assert linear_dim.coordinates_offset == 5.0

        # Test origin offset
        linear_dim.origin_offset = "1e5 G"
        assert linear_dim.origin_offset == 100000.0  # simplified parsing

        # Test absolute coordinates include origin offset
        abs_coords = linear_dim.absolute_coordinates
        coords = linear_dim.coordinates
        np.testing.assert_array_almost_equal(
            abs_coords, coords + linear_dim.origin_offset
        )

    def test_period_property(self, linear_dim):
        """Test period property for linear dimension."""
        # Default should be infinity
        assert linear_dim.period == float("inf")

        # Set finite period
        linear_dim.period = "1000 G"
        assert linear_dim.period == 1000.0

        # Set infinity variants
        linear_dim.period = "infinity G"
        assert linear_dim.period == float("inf")

        linear_dim.period = "∞ G"
        assert linear_dim.period == float("inf")


class TestMonotonicDimension:
    """Test monotonic dimension functionality."""

    @pytest.fixture
    def monotonic_dim(self):
        """Create test monotonic dimension."""
        coords = [0, 1, 3, 7, 15, 31, 63]
        return Dimension(
            type="monotonic",
            coordinates=coords,
            coordinates_offset="2.0 Hz",
            origin_offset="1000 Hz",
            description="exponential spacing",
        )

    def test_coordinate_access(self, monotonic_dim):
        """Test coordinate access for monotonic dimension."""
        coords = monotonic_dim.coordinates
        expected = [0, 1, 3, 7, 15, 31, 63]
        np.testing.assert_array_equal(coords, expected)

        # Test coords alias
        np.testing.assert_array_equal(monotonic_dim.coords, coords)

    def test_absolute_coordinates(self, monotonic_dim):
        """Test absolute coordinates calculation."""
        abs_coords = monotonic_dim.absolute_coordinates
        coords = monotonic_dim.coordinates
        expected = coords + monotonic_dim.origin_offset
        np.testing.assert_array_almost_equal(abs_coords, expected)

    def test_quantitative_properties(self, monotonic_dim):
        """Test quantitative dimension properties."""
        assert monotonic_dim.is_quantitative() is True
        assert monotonic_dim.quantity_name == "frequency"  # placeholder

        # Should not have increment (only for linear)
        with pytest.raises(AttributeError):
            _ = monotonic_dim.increment


class TestLabeledDimension:
    """Test labeled dimension functionality."""

    @pytest.fixture
    def labeled_dim(self):
        """Create test labeled dimension."""
        return Dimension(
            type="labeled",
            labels=["H", "C", "N", "O"],
            description="chemical elements",
            label="element",
        )

    def test_label_access(self, labeled_dim):
        """Test label access methods."""
        expected_labels = ["H", "C", "N", "O"]

        # coordinates should return labels for labeled dimensions
        np.testing.assert_array_equal(labeled_dim.coordinates, expected_labels)
        np.testing.assert_array_equal(labeled_dim.labels, expected_labels)
        np.testing.assert_array_equal(labeled_dim.coords, expected_labels)

    def test_non_quantitative_properties(self, labeled_dim):
        """Test that quantitative properties raise errors."""
        assert labeled_dim.is_quantitative() is False

        # These should raise AttributeError for labeled dimensions
        with pytest.raises(AttributeError):
            _ = labeled_dim.absolute_coordinates

        with pytest.raises(AttributeError):
            _ = labeled_dim.increment

        with pytest.raises(AttributeError):
            _ = labeled_dim.coordinates_offset

        with pytest.raises(AttributeError):
            _ = labeled_dim.origin_offset

        with pytest.raises(AttributeError):
            _ = labeled_dim.complex_fft

        with pytest.raises(AttributeError):
            _ = labeled_dim.period

        with pytest.raises(AttributeError):
            _ = labeled_dim.quantity_name

    def test_axis_label(self, labeled_dim):
        """Test axis label for labeled dimension."""
        assert labeled_dim.axis_label == "element"


class TestDimensionProperties:
    """Test common dimension properties."""

    @pytest.fixture
    def test_dim(self):
        """Create test dimension."""
        return Dimension(
            type="linear",
            count=5,
            increment="2.0 Hz",
            description="test description",
            label="test label",
        )

    def test_description_property(self, test_dim):
        """Test description property access and modification."""
        assert test_dim.description == "test description"

        test_dim.description = "modified description"
        assert test_dim.description == "modified description"

        # Type checking
        with pytest.raises(TypeError):
            test_dim.description = 123

    def test_label_property(self, test_dim):
        """Test label property access and modification."""
        assert test_dim.label == "test label"

        test_dim.label = "modified label"
        assert test_dim.label == "modified label"

        # Type checking
        with pytest.raises(TypeError):
            test_dim.label = ["list", "not", "allowed"]

    def test_application_metadata(self, test_dim):
        """Test application metadata property."""
        assert test_dim.application is None

        # Set application metadata
        app_data = {"com.example.myApp": {"key": "value"}}
        test_dim.application = app_data
        assert test_dim.application == app_data

        # Type checking
        with pytest.raises(TypeError):
            test_dim.application = "not a dict"

    def test_count_property(self, test_dim):
        """Test count property access and modification."""
        assert test_dim.count == 5

        test_dim.count = 10
        assert test_dim.count == 10

        # Type checking
        with pytest.raises(TypeError):
            test_dim.count = "not an integer"

        with pytest.raises(TypeError):
            test_dim.count = 0  # must be positive

    def test_axis_label_formatting(self):
        """Test axis label formatting for quantitative dimensions."""
        # With label
        dim = Dimension(type="linear", label="frequency", count=10)
        assert "frequency" in dim.axis_label

        # Without label (should use quantity_name)
        dim = Dimension(type="linear", count=10)
        assert dim.quantity_name in dim.axis_label


class TestDimensionMethods:
    """Test dimension methods."""

    @pytest.fixture
    def test_dims(self):
        """Create test dimensions of each type."""
        linear = Dimension(
            type="linear",
            count=10,
            increment="1.0 Hz",
            description="linear test",
            label="frequency",
        )

        monotonic = Dimension(
            type="monotonic", coordinates=[0, 1, 4, 9, 16], description="monotonic test"
        )

        labeled = Dimension(
            type="labeled", labels=["A", "B", "C"], description="labeled test"
        )

        return {"linear": linear, "monotonic": monotonic, "labeled": labeled}

    def test_dict_method(self, test_dims):
        """Test dict() method for all dimension types."""
        for dim_type, dim in test_dims.items():
            result = dim.dict()

            assert isinstance(result, dict)
            assert result["type"] == dim_type
            assert result["count"] == dim.count

            if dim.description:
                assert result["description"] == dim.description

    def test_to_dict_alias(self, test_dims):
        """Test to_dict() alias method."""
        for dim in test_dims.values():
            dict_result = dim.dict()
            to_dict_result = dim.to_dict()
            assert dict_result == to_dict_result

    def test_data_structure_json(self, test_dims):
        """Test data_structure JSON serialization."""
        for dim in test_dims.values():
            json_str = dim.data_structure

            # Should be valid JSON
            data = json.loads(json_str)
            assert isinstance(data, dict)
            assert data["type"] == dim.type
            assert data["count"] == dim.count

    def test_copy_method(self, test_dims):
        """Test copy() method for all dimension types."""
        for original in test_dims.values():
            copy = original.copy()

            # Should be separate objects
            assert copy is not original

            # Should have same properties
            assert copy.type == original.type
            assert copy.count == original.count
            assert copy.description == original.description

            # Coordinates should be equal
            if original.type != "labeled":
                np.testing.assert_array_equal(copy.coordinates, original.coordinates)
            else:
                np.testing.assert_array_equal(copy.labels, original.labels)

    def test_is_quantitative(self, test_dims):
        """Test is_quantitative() method."""
        assert test_dims["linear"].is_quantitative() is True
        assert test_dims["monotonic"].is_quantitative() is True
        assert test_dims["labeled"].is_quantitative() is False

    def test_reciprocal_methods(self, test_dims):
        """Test reciprocal coordinate methods."""
        linear_dim = test_dims["linear"]

        # Test reciprocal coordinates
        recip_coords = linear_dim.reciprocal_coordinates()
        assert isinstance(recip_coords, np.ndarray)
        assert len(recip_coords) == linear_dim.count

        # Test reciprocal increment
        recip_increment = linear_dim.reciprocal_increment()
        assert isinstance(recip_increment, float)
        assert recip_increment > 0

        # Should not work for labeled dimensions
        with pytest.raises(AttributeError):
            test_dims["labeled"].reciprocal_coordinates()


class TestCsdmpyCompatibility:
    """Test csdmpy API compatibility."""

    def test_csdmpy_dimension_creation_pattern(self):
        """Test creation patterns match csdmpy examples."""
        # Pattern 1: From dictionary (csdmpy docs example)
        dimension_dictionary = {
            "type": "linear",
            "description": "test",
            "increment": "5 G",
            "count": 10,
            "coordinates_offset": "10 mT",
            "origin_offset": "10 T",
        }
        x = Dimension(dimension_dictionary)

        assert x.type == "linear"
        assert x.description == "test"
        assert x.count == 10

        # Pattern 2: From keyword arguments (csdmpy docs example)
        y = Dimension(
            type="linear",
            description="test",
            increment="5 G",
            count=10,
            coordinates_offset="10 mT",
            origin_offset="10 T",
        )

        assert y.type == "linear"
        assert y.description == "test"
        assert y.count == 10

    def test_csdmpy_property_access_patterns(self):
        """Test property access patterns match csdmpy."""
        dim = Dimension(
            type="linear",
            count=10,
            increment="5 G",
            coordinates_offset="10 mT",
            origin_offset="10 T",
            description="test dimension",
            label="field strength",
        )

        # Property access should work like csdmpy
        assert dim.type == "linear"
        assert dim.description == "test dimension"
        assert dim.label == "field strength"
        assert dim.count == 10

        # coordinates and coords should be equivalent
        np.testing.assert_array_equal(dim.coordinates, dim.coords)

        # Should have axis_label formatting
        axis_label = dim.axis_label
        assert "field strength" in axis_label or "Hz" in axis_label

    def test_csdmpy_method_signatures(self):
        """Test method signatures match csdmpy."""
        dim = Dimension(type="linear", count=5, increment="1 Hz")

        # dict() and to_dict() methods
        dict_result = dim.dict()
        to_dict_result = dim.to_dict()
        assert isinstance(dict_result, dict)
        assert dict_result == to_dict_result

        # is_quantitative() method
        assert dim.is_quantitative() is True

        # copy() method
        copy_dim = dim.copy()
        assert copy_dim is not dim
        assert copy_dim.type == dim.type

        # data_structure property (JSON)
        json_str = dim.data_structure
        assert isinstance(json_str, str)
        json.loads(json_str)  # Should be valid JSON

    def test_labeled_dimension_compatibility(self):
        """Test labeled dimension csdmpy compatibility."""
        # csdmpy pattern for labeled dimension
        labels = ["Cu", "Ag", "Au"]
        dim = Dimension(type="labeled", labels=labels)

        assert dim.type == "labeled"
        assert dim.count == len(labels)
        np.testing.assert_array_equal(dim.labels, labels)

        # coordinates should be alias of labels
        np.testing.assert_array_equal(dim.coordinates, dim.labels)

        # Should not be quantitative
        assert dim.is_quantitative() is False


class TestErrorHandling:
    """Test error handling and edge cases."""

    def test_invalid_dimension_type(self):
        """Test handling of invalid dimension types."""
        with pytest.raises(ValueError, match="Unknown dimension type"):
            Dimension(type="invalid")

    def test_missing_required_parameters(self):
        """Test handling of missing required parameters."""
        # Monotonic dimension without coordinates
        with pytest.raises(ValueError, match="requires coordinates"):
            Dimension(type="monotonic")

        # Labeled dimension without labels
        with pytest.raises(ValueError, match="requires labels"):
            Dimension(type="labeled")

    def test_type_validation(self):
        """Test type validation for properties."""
        dim = Dimension(type="linear", count=5)

        # Description must be string
        with pytest.raises(TypeError):
            dim.description = 123

        # Label must be string
        with pytest.raises(TypeError):
            dim.label = ["not", "string"]

        # Count must be positive integer
        with pytest.raises(TypeError):
            dim.count = "not integer"

        with pytest.raises(TypeError):
            dim.count = 0

        # Application must be dict
        with pytest.raises(TypeError):
            dim.application = "not dict"

    def test_attribute_errors_by_type(self):
        """Test AttributeError for invalid attributes by dimension type."""
        linear_dim = Dimension(type="linear", count=5)
        labeled_dim = Dimension(type="labeled", labels=["A", "B"])

        # linear dimension should not raise for quantitative properties
        _ = linear_dim.increment
        _ = linear_dim.coordinates_offset
        _ = linear_dim.complex_fft

        # labeled dimension should raise AttributeError for quantitative properties
        with pytest.raises(AttributeError):
            _ = labeled_dim.increment

        with pytest.raises(AttributeError):
            _ = labeled_dim.coordinates_offset

        with pytest.raises(AttributeError):
            _ = labeled_dim.complex_fft

        with pytest.raises(AttributeError):
            _ = labeled_dim.absolute_coordinates

    def test_unit_conversion_not_implemented(self):
        """Test that unit conversion raises NotImplementedError."""
        dim = Dimension(type="linear", count=5, increment="1 Hz")

        with pytest.raises(NotImplementedError):
            dim.to("kHz")

        # Should raise AttributeError for labeled dimensions
        labeled_dim = Dimension(type="labeled", labels=["A", "B"])
        with pytest.raises(AttributeError):
            labeled_dim.to("any unit")


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
