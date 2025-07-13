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
    from rmnpy.exceptions import RMNError, RMNMemoryError, RMNLibraryError
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
        
        assert RMNError is not None
        assert RMNMemoryError is not None  
        assert RMNLibraryError is not None
        
        # Check inheritance
        assert issubclass(RMNMemoryError, RMNError)
        assert issubclass(RMNLibraryError, RMNError)


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
        
        # Should have num_datums property
        assert hasattr(dataset, 'num_datums')
        num_datums = dataset.num_datums
        assert isinstance(num_datums, int)
        assert num_datums >= 0
    
    def test_multiple_datasets(self):
        """Test creating multiple datasets."""
        datasets = []
        for i in range(5):
            dataset = Dataset.create()
            datasets.append(dataset)
        
        assert len(datasets) == 5
        for dataset in datasets:
            assert dataset is not None
            assert dataset.num_datums >= 0


@pytest.mark.skipif(not RMNPY_AVAILABLE, reason="RMNpy not available")  
class TestDatum:
    """Test Datum functionality."""
    
    def test_datum_creation(self):
        """Test basic datum creation."""
        datum = Datum.create()
        assert datum is not None
    
    def test_multiple_datums(self):
        """Test creating multiple datums."""
        datums = []
        for i in range(5):
            datum = Datum.create()
            datums.append(datum)
        
        assert len(datums) == 5
        for datum in datums:
            assert datum is not None


@pytest.mark.skipif(not RMNPY_AVAILABLE, reason="RMNpy not available")
class TestErrorHandling:
    """Test error handling."""
    
    def test_exception_types_exist(self):
        """Test that exception types are defined."""
        # Just test that we can create instances
        error = RMNError("test message")
        assert str(error) == "test message"
        
        memory_error = RMNMemoryError("memory test")
        assert str(memory_error) == "memory test"
        assert isinstance(memory_error, RMNError)
        
        library_error = RMNLibraryError("library test")  
        assert str(library_error) == "library test"
        assert isinstance(library_error, RMNError)


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
