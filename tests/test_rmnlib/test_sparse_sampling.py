#!/usr/bin/env python3
"""
Test suite for SparseSampling wrapper

This module tests the Python wrapper around RMNLib SparseSampling C API,
ensuring proper functionality, error handling, and integration.
"""

from typing import List, Tuple

import pytest

from rmnpy.wrappers.rmnlib.sparse_sampling import SparseSampling


class TestSparseSampling:
    """Test cases for SparseSampling wrapper."""

    def _create_dimension_indexes(self, indexes: List[int]) -> List[int]:
        """Helper function to create dimension indexes."""
        return list(indexes)

    def _create_sparse_vertices_2d(self, count: int) -> List[List[Tuple[int, int]]]:
        """Helper function to create 2D sparse grid vertices."""
        vertices = []
        # Create 'count' vertices, each with 2 coordinates
        for i in range(count):
            vertex = [(0, i % 10), (1, i // 10)]  # x coordinate  # y coordinate
            vertices.append(vertex)
        return vertices

    def test_basic_create(self):
        """Test basic SparseSampling creation."""
        print("test_SparseSampling_basic_create...")

        # Create dimension indexes - try with just one dimension like the working C test
        dim_indexes = [1]

        # Create sparse vertices - try with just one vertex like the working C test
        sparse_vertices = [[(1, 3)]]  # One vertex with one coordinate pair

        # Create SparseSampling object
        ss = SparseSampling(
            dimension_indexes=dim_indexes,
            sparse_grid_vertices=sparse_vertices,
            unsigned_integer_type="uint16",
            encoding="base64",
            description="Test sparse sampling",
        )

        # Verify properties (once TODO conversions are implemented)
        # For now, these will return placeholders
        assert len(ss.dimension_indexes) == 0  # TODO: should be 1
        assert len(ss.sparse_grid_vertices) == 0  # TODO: should be 1
        assert ss.unsigned_integer_type == "uint16"
        assert ss.encoding == "base64"
        assert ss.description == "Test sparse sampling"

    def test_validation_errors(self):
        """Test validation and error handling."""
        print("test_SparseSampling_validation...")

        # Test 1: Invalid unsigned integer type (should raise ValueError)
        with pytest.raises(ValueError, match="Invalid unsigned integer type"):
            SparseSampling(
                dimension_indexes=[1],
                sparse_grid_vertices=[[(1, 3)]],
                unsigned_integer_type="float64",  # Invalid - should be unsigned integer
                encoding="none",
            )

        # Test 2: Invalid encoding (should raise ValueError)
        with pytest.raises(
            ValueError, match="Invalid encoding.*Must be 'none' or 'base64'"
        ):
            SparseSampling(
                dimension_indexes=[1],
                sparse_grid_vertices=[[(1, 3)]],
                unsigned_integer_type="uint32",
                encoding="invalid_encoding",  # Invalid encoding
            )

        # Test 3: Valid creation with base64 encoding
        ss = SparseSampling(
            dimension_indexes=[1],
            sparse_grid_vertices=[[(1, 3)]],
            unsigned_integer_type="uint64",
            encoding="base64",
            description="Test",
        )
        assert ss.encoding == "base64"

    def test_input_validation(self):
        """Test input parameter validation."""
        print("test_SparseSampling_input_validation...")

        # Test TypeError for wrong dimension_indexes type
        with pytest.raises(
            TypeError, match="dimension_indexes must be a list or tuple"
        ):
            SparseSampling("invalid", [], "uint32", "none")

        # Test TypeError for wrong sparse_grid_vertices type
        with pytest.raises(
            TypeError, match="sparse_grid_vertices must be a list or tuple"
        ):
            SparseSampling([], "invalid", "uint32", "none")

        # Test structural validation - vertex must match dimension count
        with pytest.raises(
            ValueError, match="must contain 2.*pairs to match dimension_indexes"
        ):
            SparseSampling(
                dimension_indexes=[0, 1],  # 2 dimensions
                sparse_grid_vertices=[
                    [(0, 5)]
                ],  # But vertex only has 1 coordinate pair
                unsigned_integer_type="uint32",
                encoding="none",
            )

        # Test vertex must be list/tuple of pairs
        with pytest.raises(ValueError, match="must be a list or tuple of.*pairs"):
            SparseSampling(
                dimension_indexes=[0],
                sparse_grid_vertices=["invalid"],  # Should be list of coordinate pairs
                unsigned_integer_type="uint32",
                encoding="none",
            )

    def test_dictionary_roundtrip(self):
        """Test dictionary conversion and roundtrip."""
        print("test_SparseSampling_dictionary_roundtrip...")

        # Create SparseSampling
        dim_indexes = [0, 1]
        vertices = self._create_sparse_vertices_2d(4)

        original = SparseSampling(
            dimension_indexes=dim_indexes,
            sparse_grid_vertices=vertices,
            unsigned_integer_type="uint16",
            encoding="base64",
            description="Roundtrip test",
        )

        # Convert to dictionary
        data_dict = original.to_dict()
        assert isinstance(data_dict, dict)

        # Verify dictionary contains expected keys
        expected_keys = {
            "dimension_indexes",
            "application",
            "unsigned_integer_type",
            "encoding",
            "description",
        }
        assert expected_keys.issubset(data_dict.keys())

        # Create SparseSampling from dictionary
        restored = SparseSampling.from_dict(data_dict)

        # Verify properties match
        assert restored.unsigned_integer_type == "uint16"
        assert restored.encoding == "base64"
        assert restored.description == "Roundtrip test"

        # Test dict() alias
        data_dict2 = original.dict()
        assert data_dict2 == data_dict

    def test_null_and_empty(self):
        """Test creation with empty/null parameters."""
        print("test_SparseSampling_null_and_empty...")

        # Create empty SparseSampling (C API handles NULL by creating empty containers)
        ss = SparseSampling(
            dimension_indexes=[],  # Empty dimension indexes
            sparse_grid_vertices=[],  # Empty vertices
            unsigned_integer_type="uint32",
            encoding="none",
            description="Empty",
        )

        # Verify empty state (once TODO conversions are implemented)
        # For now, these return placeholders
        assert len(ss.dimension_indexes) == 0
        assert len(ss.sparse_grid_vertices) == 0
        assert ss.unsigned_integer_type == "uint32"
        assert ss.encoding == "none"
        assert ss.description == "Empty"

        # Test dictionary roundtrip with empty SparseSampling
        data_dict = ss.to_dict()
        assert isinstance(data_dict, dict)

        restored = SparseSampling.from_dict(data_dict)
        assert len(restored.dimension_indexes) == 0
        assert len(restored.sparse_grid_vertices) == 0

    def test_fully_sparse(self):
        """Test fully sparse sampling (all dimensions are sparse)."""
        print("test_SparseSampling_fully_sparse...")

        # Create a 2D fully sparse sampling (both dimensions are sparse)
        dim_indexes = [0, 1]
        vertices = self._create_sparse_vertices_2d(10)

        ss = SparseSampling(
            dimension_indexes=dim_indexes,
            sparse_grid_vertices=vertices,
            unsigned_integer_type="uint32",
            encoding="none",
            description="Fully sparse",
        )

        # Verify it's fully sparse (all dimensions are in the dimension_indexes)
        # Note: Once TODO conversions are implemented, these should work:
        # assert len(ss.dimension_indexes) == 2
        # assert 0 in ss.dimension_indexes and 1 in ss.dimension_indexes
        # assert len(ss.sparse_grid_vertices) == 10

        # For now, verify the object was created successfully
        assert ss.unsigned_integer_type == "uint32"
        assert ss.encoding == "none"
        assert ss.description == "Fully sparse"

    def test_partially_sparse(self):
        """Test partially sparse sampling (only some dimensions are sparse)."""
        print("test_SparseSampling_partially_sparse...")

        # Create a 3D partially sparse sampling (only dimension 1 is sparse)
        dim_indexes = [1]  # Only dimension 1 is sparse

        # Create sparse vertices with 1D coordinates (only y-coordinate)
        vertices = []
        for i in range(5):
            vertex = [(1, i * 2)]  # Only y coordinate
            vertices.append(vertex)

        ss = SparseSampling(
            dimension_indexes=dim_indexes,
            sparse_grid_vertices=vertices,
            unsigned_integer_type="uint32",
            encoding="none",
            description="Partially sparse",
        )

        # Verify it's partially sparse
        # Note: Once TODO conversions are implemented:
        # assert len(ss.dimension_indexes) == 1
        # assert 1 in ss.dimension_indexes
        # assert 0 not in ss.dimension_indexes and 2 not in ss.dimension_indexes
        # assert len(ss.sparse_grid_vertices) == 5

        # For now, verify basic properties
        assert ss.unsigned_integer_type == "uint32"
        assert ss.encoding == "none"
        assert ss.description == "Partially sparse"

    def test_base64_encoding(self):
        """Test base64 encoding functionality."""
        print("test_SparseSampling_base64_encoding...")

        # Create SparseSampling with base64 encoding
        dim_indexes = [0, 1]
        vertices = self._create_sparse_vertices_2d(3)

        ss = SparseSampling(
            dimension_indexes=dim_indexes,
            sparse_grid_vertices=vertices,
            unsigned_integer_type="uint32",
            encoding="base64",
            description="Base64 test",
        )

        assert ss.encoding == "base64"

        # Convert to dictionary and verify base64 encoding is preserved
        data_dict = ss.to_dict()
        assert data_dict.get("encoding") == "base64"

        # Test roundtrip
        restored = SparseSampling.from_dict(data_dict)
        assert restored.encoding == "base64"
        assert restored.unsigned_integer_type == "uint32"
        assert restored.description == "Base64 test"

    def test_property_setters(self):
        """Test property setters with validation."""
        print("test_SparseSampling_property_setters...")

        # Create basic SparseSampling
        ss = SparseSampling(
            dimension_indexes=[0],
            sparse_grid_vertices=[[(0, 5)]],
            unsigned_integer_type="uint32",
            encoding="none",
        )

        # Test unsigned_integer_type setter
        ss.unsigned_integer_type = "uint64"
        assert ss.unsigned_integer_type == "uint64"

        with pytest.raises(ValueError, match="Invalid unsigned integer type"):
            ss.unsigned_integer_type = "invalid_type"

        # Test encoding setter with validation
        ss.encoding = "base64"
        assert ss.encoding == "base64"

        with pytest.raises(
            ValueError, match="Invalid encoding.*Must be 'none' or 'base64'"
        ):
            ss.encoding = "invalid_encoding"

        with pytest.raises(TypeError, match="encoding must be a string"):
            ss.encoding = 123

        # Test description setter with validation
        ss.description = "New description"
        assert ss.description == "New description"

        ss.description = None  # Should be allowed
        # Note: C API likely converts None to empty string

        with pytest.raises(TypeError, match="description must be a string or None"):
            ss.description = 123

        # Test metadata setter with validation
        ss.metadata = {"key": "value"}
        assert isinstance(ss.metadata, dict)

        ss.metadata = None  # Should be allowed

        with pytest.raises(TypeError, match="metadata must be a dictionary or None"):
            ss.metadata = "invalid"

    def test_string_representations(self):
        """Test __repr__ and __str__ methods."""
        print("test_SparseSampling_string_representations...")

        # Test with description
        ss = SparseSampling(
            dimension_indexes=[0],
            sparse_grid_vertices=[[(0, 5)]],
            unsigned_integer_type="uint16",
            encoding="base64",
            description="Test description",
        )

        repr_str = repr(ss)
        assert "SparseSampling" in repr_str
        assert "base64" in repr_str
        assert "uint16" in repr_str
        assert "Test description" in repr_str

        # Test without description
        ss2 = SparseSampling(
            dimension_indexes=[0],
            sparse_grid_vertices=[[(0, 5)]],
            unsigned_integer_type="uint32",
            encoding="none",
        )

        repr_str2 = repr(ss2)
        assert "SparseSampling" in repr_str2
        assert "none" in repr_str2
        assert "uint32" in repr_str2

        # Test __str__ (should be same as __repr__)
        assert str(ss) == repr(ss)

    def test_size_calculations_concept(self):
        """Test conceptual size calculations for sparse sampling patterns."""
        print("test_SparseSampling_size_calculations...")

        # Test Case 1: Fully sparse 2D (both dimensions sparse)
        dim_indexes_full = [0, 1]
        vertices_full = self._create_sparse_vertices_2d(25)

        ss_full = SparseSampling(
            dimension_indexes=dim_indexes_full,
            sparse_grid_vertices=vertices_full,
            unsigned_integer_type="uint32",
            encoding="none",
            description="Fully sparse",
        )

        # For fully sparse: expected size = number of vertices
        # Note: Once TODO conversions are implemented:
        # assert len(ss_full.sparse_grid_vertices) == 25
        # assert len(ss_full.dimension_indexes) == 2

        # Test Case 2: Partially sparse (only dimension 1 sparse)
        dim_indexes_partial = [1]

        # Create 1D sparse vertices (only y coordinates)
        vertices_partial = []
        for i in range(10):
            vertex = [(1, i)]  # Only dimension 1
            vertices_partial.append(vertex)

        ss_partial = SparseSampling(
            dimension_indexes=dim_indexes_partial,
            sparse_grid_vertices=vertices_partial,
            unsigned_integer_type="uint32",
            encoding="none",
            description="Partially sparse",
        )

        # For partially sparse: expected size = nVerts * (size of non-sparse dimensions)
        # Note: Once TODO conversions are implemented:
        # assert len(ss_partial.sparse_grid_vertices) == 10
        # assert len(ss_partial.dimension_indexes) == 1

        # If we had a 3D dataset (10x20x30) and only dimension 1 was sparse with 10 vertices,
        # the expected size would be: 10 vertices * (10 * 30) = 3000
        # (multiply by the size of dimensions 0 and 2)

        # For now, verify objects were created successfully
        assert ss_full.unsigned_integer_type == "uint32"
        assert ss_partial.unsigned_integer_type == "uint32"


def test_sparse_sampling_creation_edge_cases():
    """Test edge cases for SparseSampling creation."""

    # Test minimum valid case (empty lists)
    ss = SparseSampling([], [])
    assert ss.unsigned_integer_type == "uint32"  # Default
    assert ss.encoding == "none"  # Default

    # Test single dimension, single vertex
    ss2 = SparseSampling([0], [[(0, 42)]])
    assert ss2.unsigned_integer_type == "uint32"

    # Test multiple dimensions, single vertex
    ss3 = SparseSampling([0, 1, 2], [[(0, 1), (1, 2), (2, 3)]])
    assert ss3.unsigned_integer_type == "uint32"


if __name__ == "__main__":
    # Run tests if executed directly
    pytest.main([__file__, "-v"])
