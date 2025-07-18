# Unit Tests

This directory contains unit tests that test individual components in isolation:

- `test_constants.py` - Tests for physical constants functionality
- `test_unit.py` - Tests for SIUnit wrapper functionality  
- `test_c_constants.py` - Tests for C-level constants integration

## Running Unit Tests

```bash
# Run all unit tests
python -m pytest tests/unit/ -v

# Run specific unit test
python -m pytest tests/unit/test_constants.py -v
```
