# RMNpy Test Guide

## Quick Test Commands

### Run All Tests
```bash
python -m pytest tests/ -v
```

### Run Specific Test Classes
```bash
# Import tests only
python -m pytest tests/test_basic.py::TestImports -v

# Dataset tests only  
python -m pytest tests/test_basic.py::TestDataset -v

# Datum tests only
python -m pytest tests/test_basic.py::TestDatum -v

# Exception tests only
python -m pytest tests/test_basic.py::TestErrorHandling -v
```

### Run Individual Tests
```bash
# Test basic import
python -m pytest tests/test_basic.py::TestImports::test_module_import -v

# Test dataset creation
python -m pytest tests/test_basic.py::TestDataset::test_dataset_creation -v

# Test datum creation
python -m pytest tests/test_basic.py::TestDatum::test_datum_creation -v
```

### Test with Coverage Report
```bash
python -m pytest tests/ -v --cov=rmnpy --cov-report=term-missing
```

### Test with Detailed Output
```bash
# Show print statements
python -m pytest tests/ -v -s

# Show test timings
python -m pytest tests/ -v --durations=10
```

## Quick Verification
```bash
# Just verify the package imports
python -c "import rmnpy; print('✓ RMNpy working!')"

# Test basic functionality
python -c "from rmnpy import Dataset, Datum; d = Dataset.create(); print('✓ Dataset created')"
```

## Build Requirements
The package currently requires:
- Local `include/` directory with headers from OCTypes, SITypes, RMNLib
- Local `lib/` directory with static libraries
- These are populated by `build_deps.py`

## Current Status: ✅ WORKING
- Package builds successfully with `pip install -e .`
- All tests pass
- Memory management working correctly
- No memory leaks detected
