"""
Test suite for Dataset wrapper

Based on the RMNLib C API test suite (test_Dataset.c) to ensure
our Python wrappers provide equivalent functionality and behavior.
"""

import numpy as np
import pytest

from rmnpy.wrappers.rmnlib.dataset import Dataset
from rmnpy.wrappers.rmnlib.datum import Datum
from rmnpy.wrappers.rmnlib.dependent_variable import DependentVariable
from rmnpy.wrappers.rmnlib.geographic_coordinate import GeographicCoordinate


class TestDatasetCreation:
    """Test Dataset creation functionality similar to test_Dataset.c"""

    def _make_mock_dependent_variable(self):
        """Helper to create a simple DependentVariable (like _make_mock_dv in C tests)"""
        components = [np.array([1.0], dtype=np.float64)]
        return DependentVariable(
            components=components,
            name="test_dv",
            description="Test dependent variable",
            unit=" ",  # dimensionless
            quantity_name="dimensionless",
            quantity_type="scalar",
            element_type="float64",
        )

    def test_minimal_create(self):
        """Test minimal Dataset creation - equivalent to test_Dataset_minimal_create"""
        # Create a dependent variable
        dv = self._make_mock_dependent_variable()
        dependent_variables = [dv]

        # Create with only dependent variables, other params default to None
        dataset = Dataset(
            dimensions=None,
            dependent_variables=dependent_variables,
            dimension_precedence=None,
            tags=None,
            description=None,
            title=None,
            focus=None,
            previous_focus=None,
            application_metadata=None,
        )

        assert dataset is not None

        # Sanity checks (equivalent to C test assertions)
        assert len(dataset.dependent_variables) == 1
        assert len(dataset.dimensions) == 0
        assert len(dataset.tags) == 0
        assert len(dataset.dimension_precedence) == 0
        assert len(dataset.application_metadata) == 0

    def test_create_with_all_parameters(self):
        """Test Dataset creation with all parameters specified"""
        dv = self._make_mock_dependent_variable()
        dependent_variables = [dv]

        # Create datum - coordinates managed by Dataset, not Datum
        datum = Datum(
            response=5.0,
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

        dataset = Dataset(
            title="Test Dataset",
            description="A test dataset for validation",
            dimensions=None,  # We'll test with actual dimensions separately
            dependent_variables=dependent_variables,
            application_metadata={"test_key": "test_value"},
            dimension_precedence=[],
            tags=["test", "dataset"],
            focus=datum,
            previous_focus=None,
        )

        assert dataset is not None
        assert dataset.title == "Test Dataset"
        assert dataset.description == "A test dataset for validation"
        assert len(dataset.dependent_variables) == 1
        assert len(dataset.tags) == 2
        assert "test" in dataset.tags
        assert "dataset" in dataset.tags
        assert dataset.application_metadata["test_key"] == "test_value"
        assert dataset.focus is not None
        assert dataset.previous_focus is None

    def test_from_dict(self):
        """Test Dataset creation from dictionary"""
        # Create a simple dataset first
        dv = self._make_mock_dependent_variable()
        original = Dataset(
            title="Original Dataset",
            description="Original description",
            dependent_variables=[dv],
        )

        # Convert to dictionary
        data_dict = original.to_dict()
        assert isinstance(data_dict, dict)

        # Create new dataset from dictionary
        restored = Dataset.from_dict(data_dict)
        assert restored is not None
        assert restored.title == "Original Dataset"
        assert restored.description == "Original description"

    def test_invalid_creation(self):
        """Test invalid Dataset creation scenarios"""
        # Test with None dependent_variables (should fail since it's required)
        with pytest.raises(Exception):  # Could be RMNError or TypeError
            Dataset(dependent_variables=None)

        # Test with empty dependent_variables
        with pytest.raises(Exception):
            Dataset(dependent_variables=[])


class TestDatasetMutators:
    """Test Dataset property setters - equivalent to test_Dataset_mutators in C"""

    def _create_test_dataset(self):
        """Helper to create a test dataset"""
        dv = DependentVariable(
            components=[np.array([1.0], dtype=np.float64)],
            name="test_dv",
            description="Test dependent variable",
            unit=" ",  # dimensionless
            quantity_name="dimensionless",
            quantity_type="scalar",
            element_type="float64",
        )
        return Dataset(dependent_variables=[dv])

    def test_title_property(self):
        """Test title getter and setter"""
        dataset = self._create_test_dataset()

        # Test setter
        dataset.title = "New Title"
        assert dataset.title == "New Title"

        # Test with empty string
        dataset.title = ""
        assert dataset.title == ""

    def test_description_property(self):
        """Test description getter and setter"""
        dataset = self._create_test_dataset()

        # Test setter
        dataset.description = "New Description"
        assert dataset.description == "New Description"

        # Test with empty string
        dataset.description = ""
        assert dataset.description == ""

    def test_tags_property(self):
        """Test tags getter and setter"""
        dataset = self._create_test_dataset()

        # Test setting tags
        new_tags = ["tag1", "tag2", "tag3"]
        dataset.tags = new_tags
        retrieved_tags = dataset.tags
        assert len(retrieved_tags) == 3
        assert "tag1" in retrieved_tags
        assert "tag2" in retrieved_tags
        assert "tag3" in retrieved_tags

        # Test setting empty tags
        dataset.tags = []
        assert len(dataset.tags) == 0

    def test_read_only_property(self):
        """Test read_only flag getter and setter"""
        dataset = self._create_test_dataset()

        # Test default value
        assert isinstance(dataset.read_only, bool)

        # Test setting to True
        dataset.read_only = True
        assert dataset.read_only is True

        # Test setting to False
        dataset.read_only = False
        assert dataset.read_only is False

    def test_version_property(self):
        """Test version getter and setter"""
        dataset = self._create_test_dataset()

        # Test default version
        version = dataset.version
        assert isinstance(version, str)
        assert len(version) > 0

        # Test setting version
        dataset.version = "2.0"
        assert dataset.version == "2.0"

    def test_application_metadata_property(self):
        """Test application metadata getter and setter"""
        dataset = self._create_test_dataset()

        # Test setting metadata
        metadata = {
            "key1": "value1",
            "key2": 42,
            "key3": [1, 2, 3],
            "nested": {"inner": "value"},
        }
        dataset.application_metadata = metadata

        retrieved = dataset.application_metadata
        assert retrieved["key1"] == "value1"
        assert retrieved["key2"] == 42
        assert retrieved["key3"] == [1, 2, 3]
        assert retrieved["nested"]["inner"] == "value"


class TestDatasetDependentVariables:
    """Test Dataset dependent variable management"""

    def test_dependent_variables_property(self):
        """Test dependent variables getter and setter"""
        # Create multiple dependent variables
        dv1 = DependentVariable(
            components=[np.array([1.0, 2.0], dtype=np.float64)],
            name="dv1",
            quantity_type="scalar",
            element_type="float64",
        )
        dv2 = DependentVariable(
            components=[np.array([3.0, 4.0], dtype=np.float64)],
            name="dv2",
            quantity_type="scalar",
            element_type="float64",
        )

        dataset = Dataset(dependent_variables=[dv1])
        assert len(dataset.dependent_variables) == 1

        # Test setting new dependent variables
        dataset.dependent_variables = [dv1, dv2]
        retrieved_dvs = dataset.dependent_variables
        assert len(retrieved_dvs) == 2
        assert retrieved_dvs[0].name == "dv1"
        assert retrieved_dvs[1].name == "dv2"

    def test_get_dependent_variable_count(self):
        """Test dependent variable count method"""
        dv1 = DependentVariable(
            components=[np.array([1.0], dtype=np.float64)],
            quantity_type="scalar",
            element_type="float64",
        )
        dv2 = DependentVariable(
            components=[np.array([2.0], dtype=np.float64)],
            quantity_type="scalar",
            element_type="float64",
        )

        dataset = Dataset(dependent_variables=[dv1, dv2])
        assert dataset.get_dependent_variable_count() == 2


class TestDatasetFocusDatum:
    """Test Dataset focus and previous focus functionality"""

    def _create_test_datum(self):
        """Helper to create a test datum"""
        return Datum(
            response=10.0,
            dependent_variable_index=0,
            component_index=0,
            mem_offset=0,
        )

    def test_focus_property(self):
        """Test focus datum getter and setter"""
        dv = DependentVariable(
            components=[np.array([1.0], dtype=np.float64)],
            quantity_type="scalar",
            element_type="float64",
        )
        dataset = Dataset(dependent_variables=[dv])

        # Test default (should be None)
        assert dataset.focus is None

        # Test setting focus
        datum = self._create_test_datum()
        dataset.focus = datum
        retrieved_focus = dataset.focus
        assert retrieved_focus is not None
        assert retrieved_focus.response.value == 10.0

        # Test clearing focus
        dataset.focus = None
        assert dataset.focus is None

    def test_previous_focus_property(self):
        """Test previous focus datum getter and setter"""
        dv = DependentVariable(
            components=[np.array([1.0], dtype=np.float64)],
            quantity_type="scalar",
            element_type="float64",
        )
        dataset = Dataset(dependent_variables=[dv])

        # Test default (should be None)
        assert dataset.previous_focus is None

        # Test setting previous focus
        datum = self._create_test_datum()
        dataset.previous_focus = datum
        retrieved_prev_focus = dataset.previous_focus
        assert retrieved_prev_focus is not None
        assert retrieved_prev_focus.response.value == 10.0

        # Test clearing previous focus
        dataset.previous_focus = None
        assert dataset.previous_focus is None


class TestDatasetGeographicCoordinate:
    """Test Dataset geographic coordinate functionality"""

    def test_geographic_coordinate_property(self):
        """Test geographic coordinate getter and setter"""
        dv = DependentVariable(
            components=[np.array([1.0], dtype=np.float64)],
            quantity_type="scalar",
            element_type="float64",
        )
        dataset = Dataset(dependent_variables=[dv])

        # Test default (should be None)
        assert dataset.geographic_coordinate is None

        # Test setting geographic coordinate
        geo_coord = GeographicCoordinate(
            latitude=37.7749, longitude=-122.4194, altitude=50.0
        )
        dataset.geographic_coordinate = geo_coord

        retrieved = dataset.geographic_coordinate
        assert retrieved is not None
        assert retrieved.latitude.value == 37.7749
        assert (
            abs(retrieved.longitude.value - (-122.4194)) < 0.001
        )  # Allow small precision difference
        assert retrieved.altitude.value == 50.0

        # Test clearing geographic coordinate
        dataset.geographic_coordinate = None
        assert dataset.geographic_coordinate is None


class TestDatasetSerialization:
    """Test Dataset serialization and deserialization"""

    def test_to_dict_and_dict_alias(self):
        """Test to_dict() method and dict() alias"""
        dv = DependentVariable(
            components=[np.array([1.0, 2.0], dtype=np.float64)],
            name="test_dv",
            quantity_type="scalar",
            element_type="float64",
        )

        dataset = Dataset(
            title="Test Dataset",
            description="Test Description",
            dependent_variables=[dv],
            tags=["test"],
            application_metadata={"key": "value"},
        )

        # Test to_dict()
        data_dict = dataset.to_dict()
        assert isinstance(data_dict, dict)

        # Test dict() alias
        data_dict_alias = dataset.dict()
        assert isinstance(data_dict_alias, dict)

        # Both should be equivalent
        assert data_dict == data_dict_alias

    def test_copy(self):
        """Test dataset copy functionality"""
        dv = DependentVariable(
            components=[np.array([1.0, 2.0], dtype=np.float64)],
            name="original_dv",
            quantity_type="scalar",
            element_type="float64",
        )

        original = Dataset(
            title="Original",
            description="Original Description",
            dependent_variables=[dv],
            tags=["original"],
        )

        # Create copy
        copy = original.copy()
        assert copy is not None
        assert copy is not original  # Different objects

        # Verify content is the same
        assert copy.title == original.title
        assert copy.description == original.description
        assert len(copy.dependent_variables) == len(original.dependent_variables)
        assert len(copy.tags) == len(original.tags)


class TestDatasetStringRepresentation:
    """Test Dataset string representation methods"""

    def test_repr_and_str(self):
        """Test __repr__ and __str__ methods"""
        dv = DependentVariable(
            components=[np.array([1.0], dtype=np.float64)],
            quantity_type="scalar",
            element_type="float64",
        )

        dataset = Dataset(title="Test Dataset", dependent_variables=[dv])

        # Test __repr__
        repr_str = repr(dataset)
        assert isinstance(repr_str, str)
        assert "Dataset" in repr_str

        # Test __str__
        str_str = str(dataset)
        assert isinstance(str_str, str)
        assert str_str == repr_str  # Should be the same


if __name__ == "__main__":
    pytest.main([__file__])
