Changelog
=========

All notable changes to the RMNpy project will be documented in this file.

The format is based on `Keep a Changelog <https://keepachangelog.com/en/1.0.0/>`__,
and this project adheres to `Semantic Versioning <https://semver.org/spec/v2.0.0.html>`__.

[Unreleased]
------------

Added
~~~~~
- Comprehensive Sphinx documentation with RTD theme
- User guide with detailed examples and best practices
- API reference documentation with autodoc
- Example gallery for common use cases
- Developer guide for contributors
- GitHub Pages deployment configuration

Changed
~~~~~~~
- Improved test coverage to 70% with comprehensive test suite
- Enhanced error messages and exception hierarchy
- Better memory management and resource cleanup

Fixed
~~~~~
- Memory management issues that could cause hanging
- Build system compatibility with workspace-relative dependencies
- Package import structure and exports

[0.1.0] - 2025-01-13
--------------------

Added
~~~~~
- Initial RMNpy Python wrapper implementation
- Core Dataset, Dimension, and DependentVariable classes
- Cython bindings for RMNLib C library
- Basic CSDM (Core Scientific Dataset Model) support
- Memory management with proper cleanup
- Exception handling and error reporting
- Basic test suite with pytest
- Package configuration and build system

Technical
~~~~~~~~~
- Cython extensions for performance-critical operations
- Automated dependency management via setup.py
- GitHub Actions CI/CD pipeline
- Cross-platform compatibility (Linux, macOS, Windows)
- Integration with RMNLib, OCTypes, and SITypes C libraries
