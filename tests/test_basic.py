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
    from rmnpy import Dataset, Datum
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
