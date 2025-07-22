# RMNpy Development Workflow

This document describes the development workflow for RMNpy, including library management, building, testing, and documentation.

## Prerequisites

- Python 3.8+
- Conda (recommended for environment management)
- Make
- Git
- Doxygen (for documentation)

## Initial Setup

### 1. Clone and Setup Environment

```bash
git clone https://github.com/drpjkgrandinetti/RMNpy.git
cd RMNpy
conda env create -f environment-dev.yml
conda activate rmnpy-dev
```

### 2. Library Management

RMNpy depends on three C libraries: OCTypes, SITypes, and RMNLib. You can work with either local development versions or released versions.

#### Using Local Development Libraries (Recommended for Development)

If you have the C libraries checked out locally in adjacent directories:

```text
parent-directory/
├── OCTypes/          # Local OCTypes development
├── SITypes/          # Local SITypes development  
├── RMNLib/           # Local RMNLib development
└── RMNpy/            # This project
```

Sync libraries from local development:

```bash
make synclib
```

This copies the latest compiled libraries and headers from your local development directories.

#### Using Released Libraries

To download libraries from GitHub releases:

```bash
make download-libs
```

This downloads and extracts the latest release versions.

#### Cleaning Libraries

To remove libraries and force re-download/sync:

```bash
make clean-libs
```

## Build Process

### 1. Install in Development Mode

```bash
pip install -e .
```

This installs RMNpy in "editable" mode, so changes to Python files are immediately available.

### 2. Rebuild After C Changes

When C extension files change:

```bash
make rebuild
```

This cleans build artifacts and reinstalls the package.

### 3. Clean Build Artifacts

```bash
make clean
```

Removes generated C files, build directories, and compiled extensions.

## Development Cycle

### Typical Development Workflow

1. **Update C libraries** (if using local development):

   ```bash
   cd ../OCTypes && make        # Build OCTypes
   cd ../SITypes && make        # Build SITypes  
   cd ../RMNLib && make         # Build RMNLib
   cd ../RMNpy && make synclib  # Sync to RMNpy
   ```

2. **Make changes** to RMNpy code

3. **Rebuild if needed**:

   ```bash
   make rebuild  # If Cython files changed
   # OR just:
   pip install -e .  # If only Python files changed
   ```

4. **Run tests**:

   ```bash
   pytest tests/
   ```

5. **Update documentation**:

   ```bash
   cd docs && make html
   ```

### Working with Different Library Versions

- **Switch to released versions**: `make clean-libs && make download-libs`
- **Switch to local development**: `make clean-libs && make synclib`
- **Update to latest releases**: `make clean-libs && make download-libs`

## Testing

### Running Tests

```bash
# All tests
pytest

# Specific test module
pytest tests/test_helpers/

# With coverage
pytest --cov=rmnpy

# Verbose output
pytest -v
```

### Test Organization

```text
tests/
├── test_helpers/        # OCTypes helper function tests
├── test_sitypes/        # SITypes wrapper tests
├── test_rmnlib/         # RMNLib wrapper tests
└── conftest.py          # Shared test fixtures
```

## Documentation

### Building Documentation

```bash
cd docs
make html
```

Built documentation will be in `docs/_build/html/`.

### Documentation Structure

- **Source**: `docs/` directory with reStructuredText files
- **API docs**: Auto-generated from Python docstrings
- **C library docs**: Integration with Doxygen via Breathe
- **Theme**: Sphinx RTD theme for consistency

### Viewing Documentation Locally

```bash
cd docs
make html
open _build/html/index.html  # macOS
# OR
python -m http.server 8000 -d _build/html  # Any platform, then visit http://localhost:8000
```

## Makefile Reference

| Command | Purpose |
|---------|---------|
| `make synclib` | Copy libraries from local `../OCTypes`, `../SITypes`, `../RMNLib` |
| `make download-libs` | Download libraries from GitHub releases |
| `make clean-libs` | Remove local libraries |
| `make clean` | Remove build artifacts and generated C files |
| `make rebuild` | Clean and reinstall package |

## Library Dependencies

### Expected Library Structure

```text
lib/
├── libOCTypes.a         # OCTypes static library
├── libSITypes.a         # SITypes static library  
└── libRMN.a            # RMNLib static library (note: renamed from libRMN.a)

include/
├── OCTypes/
│   ├── OCType.h
│   ├── OCString.h
│   ├── OCArray.h
│   └── ...
├── SITypes/
│   ├── SIScalar.h
│   ├── SIUnit.h
│   └── ...
└── RMNLib/
    ├── RMNLibrary.h
    └── ...
```

### Library Naming

Note that RMNLib's static library is renamed from `libRMN.a` to `libRMN.a` for consistency with linking conventions.

## Troubleshooting

### Common Issues

1. **Library not found errors**:
   - Run `make synclib` or `make download-libs`
   - Check that libraries exist in `lib/` directory
   - Verify headers exist in `include/` directory

2. **Build failures after C library updates**:
   - Run `make clean && make rebuild`
   - Check for API changes in C libraries

3. **Import errors**:
   - Ensure conda environment is activated
   - Run `pip install -e .` to reinstall in development mode

4. **Documentation build failures**:
   - Install documentation dependencies: `pip install -r docs/requirements.txt`
   - Check for missing Doxygen installation

### Environment Issues

If you encounter environment issues:

```bash
# Recreate conda environment
conda env remove -n rmnpy-dev
conda env create -f environment-dev.yml
conda activate rmnpy-dev
pip install -e .
```

## Release Workflow

### Version Management

1. Update version in `pyproject.toml`
2. Update `CHANGELOG.md`
3. Tag release: `git tag v0.1.0`
4. Push: `git push && git push --tags`

### Package Building

```bash
# Build source distribution and wheel
python -m build

# Upload to PyPI (when ready)
python -m twine upload dist/*
```

## Development Best Practices

### Code Style

- Follow PEP 8 for Python code
- Use type hints where possible
- Document all public APIs
- Write tests for new functionality

### Memory Management

- Always test for memory leaks when working with C extensions
- Use proper error handling for C library calls
- Follow OCTypes memory management patterns

### Performance

- Profile critical paths during development
- Minimize Python ↔ C conversion overhead
- Use appropriate data structures for different use cases

This workflow ensures consistent development practices and makes it easy to work with the complex multi-library dependencies of RMNpy.
