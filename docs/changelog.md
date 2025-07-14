# Changelog

All notable changes to the RMNpy project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive Sphinx documentation with RTD theme
- User guide with detailed examples and best practices
- API reference documentation with autodoc
- Example gallery for common use cases
- Developer guide for contributors
- GitHub Pages deployment configuration

### Changed
- Improved test coverage to 70% with comprehensive test suite
- Enhanced error messages and exception hierarchy
- Better memory management and resource cleanup

### Fixed
- Memory management issues that could cause hanging
- Build system compatibility with workspace-relative dependencies
- Package import structure and exports

## [0.1.0] - 2025-01-13

### Added
- Initial RMNpy package structure
- Core Cython wrapper classes:
  - `Dataset`: Scientific dataset representation
  - `Datum`: Individual data point handling
  - `Dimension`: Coordinate axis management
  - `DependentVariable`: Data variable representation
- Exception hierarchy:
  - `RMNLibError`: Base exception class
  - `RMNLibMemoryError`: Memory-related errors
  - `RMNLibValidationError`: Input validation errors
- Bundled dependency system with OCTypes, SITypes, and RMNLib
- Comprehensive test suite with pytest
- Build system with setuptools and Cython
- Memory safety with automatic cleanup
- String representation support for all classes

### Implementation Details
- Cython-based C library integration
- Automatic memory management using OCRetain/OCRelease
- Cross-platform build support (macOS, Linux, Windows)
- Zero-dependency installation (bundled libraries)
- Thread-safe object creation and destruction

### Testing
- 19 comprehensive tests covering all functionality
- Unit tests for individual classes
- Integration tests for multi-class workflows
- Error handling and memory management tests
- Build configuration validation tests
- Continuous integration setup

### Documentation
- README with installation and usage instructions
- Inline code documentation and docstrings
- Development status and project roadmap
- Dependency strategy documentation
- Testing methodology documentation

### Known Limitations
- Placeholder implementations for some advanced features
- CSDM file I/O not yet implemented
- Data array operations planned for future releases
- Limited mathematical operations (planned expansion)

### Dependencies
- Python 3.8+ required
- NumPy for numerical support
- Cython for C integration
- Bundled C libraries: RMNLib, OCTypes, SITypes

### Platform Support
- macOS (Intel and Apple Silicon)
- Linux (x86_64)
- Windows (x64) - planned

## Development Roadmap

### Version 0.2.0 (Planned)
- CSDM file format I/O operations
- Data array manipulation with NumPy integration
- Advanced dimension types (logarithmic, custom)
- Enhanced metadata management
- Performance optimizations

### Version 0.3.0 (Planned)  
- Mathematical operations on datasets
- Spectral processing functions
- Multi-threading support
- Advanced visualization integration
- Extended unit system support

### Version 1.0.0 (Planned)
- Full CSDM compliance
- Comprehensive spectroscopic analysis tools
- Production-ready API stability
- Complete documentation and tutorials
- Performance benchmarks and optimizations

## Contributing

See the [GitHub repository](https://github.com/pjgrandinetti/RMNpy) for development guidelines and how to contribute to RMNpy.

## License

This project is licensed under the MIT License - see the [LICENSE file](https://github.com/pjgrandinetti/RMNpy/blob/main/LICENSE) for details.

## Acknowledgments

- RMNLib C library development team
- OCTypes and SITypes library contributors  
- Cython project for excellent Python-C integration
- NumPy community for numerical computing foundation
- Sphinx and Read the Docs for documentation infrastructure
