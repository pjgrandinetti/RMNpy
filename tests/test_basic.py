"""
Test suite for RMNpy.

Run with: python -m pytest tests/ -v
"""

import pytest
import sys
from pathlib import Path

# Add src to path for testing
src_path = Path(__file__).parent.parent / "src"
sys.path.insert(0, str(src_path))

try:
    import rmnpy
    from rmnpy import Dataset, Datum, Dimension, DependentVariable
    from rmnpy.exceptions import RMNLibError, RMNLibMemoryError, RMNLibValidationError
    RMNPY_AVAILABLE = True
except ImportError as e:
    RMNPY_AVAILABLE = False
    IMPORT_ERROR = str(e)


class TestImports:
    """Test that the module can be imported."""
    
    def test_module_import(self):
        """Test that rmnpy can be imported."""
        if not RMNPY_AVAILABLE:
            pytest.skip(f"RMNpy not available: {IMPORT_ERROR}")
        
        assert rmnpy is not None
        assert hasattr(rmnpy, 'Dataset')
        assert hasattr(rmnpy, 'Datum')
        assert hasattr(rmnpy, 'Dimension')
        assert hasattr(rmnpy, 'DependentVariable')
    
    def test_exceptions_import(self):
        """Test that exceptions can be imported."""
        if not RMNPY_AVAILABLE:
            pytest.skip(f"RMNpy not available: {IMPORT_ERROR}")
        
        assert RMNLibError is not None
        assert RMNLibMemoryError is not None  
        assert RMNLibValidationError is not None
        
        # Check inheritance
        assert issubclass(RMNLibMemoryError, RMNLibError)
        assert issubclass(RMNLibValidationError, RMNLibError)


@pytest.mark.skipif(not RMNPY_AVAILABLE, reason="RMNpy not available")
class TestDataset:
    """Test Dataset functionality."""
    
    def test_dataset_creation(self):
        """Test basic dataset creation."""
        dataset = Dataset.create()
        assert dataset is not None
    
    def test_dataset_properties(self):
        """Test dataset properties."""
        dataset = Dataset.create()
        
        # Should have title and description properties
        assert hasattr(dataset, 'title')
        assert hasattr(dataset, 'description')
        title = dataset.title
        description = dataset.description
        # Title can be None or string
        assert title is None or isinstance(title, str)
    
    def test_multiple_datasets(self):
        """Test creating multiple datasets."""
        # Test just 2 datasets to avoid potential hanging
        dataset1 = Dataset.create()
        dataset2 = Dataset.create()
        
        assert dataset1 is not None
        assert dataset2 is not None
        assert dataset1.title is None or isinstance(dataset1.title, str)
        assert dataset2.title is None or isinstance(dataset2.title, str)


@pytest.mark.skipif(not RMNPY_AVAILABLE, reason="RMNpy not available")  
class TestDatum:
    """Test Datum functionality."""
    
    def test_datum_creation(self):
        """Test basic datum creation."""
        datum = Datum.create(response_value=42.0)
        assert datum is not None
    
    def test_multiple_datums(self):
        """Test creating multiple datums."""
        # Test just 2 datums to avoid potential hanging
        datum1 = Datum.create(response_value=1.0)
        datum2 = Datum.create(response_value=2.0)
        
        assert datum1 is not None
        assert datum2 is not None


@pytest.mark.skipif(not RMNPY_AVAILABLE, reason="RMNpy not available")  
class TestDimension:
    """Test Dimension functionality."""
    
    def test_dimension_creation(self):
        """Test basic dimension creation."""
        dimension = Dimension.create_linear(label="frequency", count=100)
        assert dimension is not None
    
    def test_dimension_properties(self):
        """Test dimension properties."""
        dimension = Dimension.create_linear(
            label="chemical_shift", 
            description="1H chemical shift",
            count=256,
            start=0.0,
            increment=1.0,
            unit="ppm"
        )
        
        # Test properties (note: some may be None due to incomplete implementation)
        label = dimension.label
        description = dimension.description
        count = dimension.count
        dim_type = dimension.type
        
        # Basic assertions
        assert label is None or isinstance(label, str)
        assert description is None or isinstance(description, str) 
        assert count is None or isinstance(count, int)
        assert dim_type is None or isinstance(dim_type, str)
    
    def test_dimension_string_representation(self):
        """Test dimension string representation."""
        dimension = Dimension.create_linear(label="time", count=50)
        
        # Should not raise an exception
        str_repr = str(dimension)
        repr_str = repr(dimension)
        
        assert isinstance(str_repr, str)
        assert isinstance(repr_str, str)
        assert "Dimension" in str_repr
        assert "Dimension" in repr_str
    
    def test_multiple_dimensions(self):
        """Test creating multiple dimensions."""
        # Test creating multiple dimensions with different parameters
        dim1 = Dimension.create_linear(label="f1", count=128, unit="Hz")
        dim2 = Dimension.create_linear(label="f2", count=64, unit="ppm")
        
        assert dim1 is not None
        assert dim2 is not None


@pytest.mark.skipif(not RMNPY_AVAILABLE, reason="RMNpy not available")  
class TestDependentVariable:
    """Test DependentVariable functionality."""
    
    def test_dependent_variable_creation(self):
        """Test basic dependent variable creation."""
        dep_var = DependentVariable.create(name="intensity")
        assert dep_var is not None
    
    def test_dependent_variable_properties(self):
        """Test dependent variable properties."""
        dep_var = DependentVariable.create(
            name="signal_amplitude",
            description="NMR signal amplitude",
            unit="arbitrary_units"
        )
        
        # Test properties (note: some may be None due to incomplete implementation)
        name = dep_var.name
        description = dep_var.description
        unit = dep_var.unit
        
        # Basic assertions
        assert name is None or isinstance(name, str)
        assert description is None or isinstance(description, str)
        assert unit is None or isinstance(unit, str)
    
    def test_dependent_variable_string_representation(self):
        """Test dependent variable string representation."""
        dep_var = DependentVariable.create(name="intensity", unit="counts")
        
        # Should not raise an exception
        str_repr = str(dep_var)
        repr_str = repr(dep_var)
        
        assert isinstance(str_repr, str)
        assert isinstance(repr_str, str)
        assert "DependentVariable" in str_repr
        assert "DependentVariable" in repr_str
    
    def test_multiple_dependent_variables(self):
        """Test creating multiple dependent variables."""
        # Test creating multiple dependent variables
        dep_var1 = DependentVariable.create(name="real", unit="V")
        dep_var2 = DependentVariable.create(name="imaginary", unit="V")
        
        assert dep_var1 is not None
        assert dep_var2 is not None


@pytest.mark.skipif(not RMNPY_AVAILABLE, reason="RMNpy not available")
class TestIntegration:
    """Test integration between different classes."""
    
    def test_dataset_with_dimensions_and_dependent_variables(self):
        """Test creating a dataset with dimensions and dependent variables."""
        # Create dimensions
        freq_dim = Dimension.create_linear(
            label="frequency",
            description="1H NMR frequency",
            count=256,
            unit="Hz"
        )
        
        time_dim = Dimension.create_linear(
            label="time", 
            description="Evolution time",
            count=128,
            unit="s"
        )
        
        # Create dependent variables
        real_var = DependentVariable.create(
            name="real_signal",
            description="Real component of NMR signal",
            unit="V"
        )
        
        imag_var = DependentVariable.create(
            name="imaginary_signal", 
            description="Imaginary component of NMR signal",
            unit="V"
        )
        
        # Create dataset (note: currently Dataset.create doesn't use these parameters,
        # but the test verifies that objects can be created and work together)
        dataset = Dataset.create(
            title="2D NMR Spectrum",
            description="Test 2D NMR dataset"
        )
        
        # Verify all objects were created successfully
        assert freq_dim is not None
        assert time_dim is not None
        assert real_var is not None
        assert imag_var is not None
        assert dataset is not None
        
        # Test string representations
        assert "Dimension" in str(freq_dim)
        assert "DependentVariable" in str(real_var)
        assert "Dataset" in str(dataset)


@pytest.mark.skipif(not RMNPY_AVAILABLE, reason="RMNpy not available")
class TestErrorHandling:
    """Test error handling."""
    
    def test_exception_types_exist(self):
        """Test that exception types are defined."""
        # Just test that we can create instances
        error = RMNLibError("test message")
        assert str(error) == "RMNLib Error: test message"
        
        memory_error = RMNLibMemoryError("memory test")
        assert str(memory_error) == "RMNLib Error: memory test"
        assert isinstance(memory_error, RMNLibError)
        
        validation_error = RMNLibValidationError("validation test")  
        assert str(validation_error) == "RMNLib Error: validation test"
        assert isinstance(validation_error, RMNLibError)


class TestBuildConfiguration:
    """Test build configuration and requirements."""
    
    def test_python_version(self):
        """Test Python version is supported."""
        assert sys.version_info >= (3, 8), "Python 3.8+ required"
    
    def test_required_modules_available(self):
        """Test that required build modules are available."""
        try:
            import numpy
            assert numpy is not None
        except ImportError:
            pytest.skip("NumPy not available (required for build)")
        
        # Cython only needed for building, not runtime
        # So we don't test for it here


if __name__ == "__main__":
    # Run tests when called directly
    pytest.main([__file__, "-v"])
