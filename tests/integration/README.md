# Integration Tests

This directory contains integration tests that test component interactions and full workflows:

- `test_phase_1_4_integration.py` - Comprehensive Phase 1-4 integration tests
- `test_complete_constants.py` - Complete constants integration testing
- `test_enhanced_dimension.py` - Enhanced dimension integration tests
- `test_final_comprehensive.py` - Final comprehensive integration tests
- `test_complete_quantities.py` - Complete quantities testing
- `test_confirmed_working.py` - Confirmed working functionality tests

## Running Integration Tests

```bash
# Run all integration tests
python -m pytest tests/integration/ -v

# Run Phase 1-4 integration tests specifically
python -m pytest tests/integration/test_phase_1_4_integration.py -v
```
