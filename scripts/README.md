# Development Scripts

This directory contains development and maintenance scripts for the RMNpy project.

## Scripts

### `extract_si_constants.py`

Auto-extracts SI constants from C headers and generates `src/rmnpy/constants.pyx`.

**Usage:**

```bash
python scripts/extract_si_constants.py
```

**Integration:** This script is automatically run during the build process via `setup.py`.

### `test_error_handling.py`

Development script for testing error handling in SIUnit implementations.

**Usage:**

```bash
cd scripts
python test_error_handling.py
```

**Note:** This is a development utility and not part of the main test suite.

## Running Scripts

All scripts should be run from the RMNpy root directory unless otherwise specified:

```bash
cd /path/to/RMNpy
python scripts/script_name.py
```

## Adding New Scripts

When adding new development scripts:

1. Place them in this `scripts/` directory
2. Add a brief description to this README
3. Ensure they don't conflict with main package functionality
4. Consider adding them to `.gitignore` if they generate temporary files
