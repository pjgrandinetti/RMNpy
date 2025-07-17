Changelog
=========

All notable changes to the RMNpy project will be documented in this file.

The format is based on `Keep a Changelog <https://keepachangelog.com/en/1.0.0/>`__,
and this project adheres to `Semantic Versioning <https://semver.org/spec/v2.0.0.html>`__.

[Unreleased]
------------

Added
~~~~~
- **Corrected RMNpy API to accurately map to RMNLib C library**
- Proper SIQuantity inheritance for DependentVariable unit access
- Working ``create()`` methods for all core classes (Dataset, Dimension, DependentVariable, Datum)
- Comprehensive rst documentation matching OCTypes/SITypes/RMNLib documentation style
- Individual API documentation files for each class
- Accurate examples using real, tested function calls

Fixed
~~~~~
- **Major API correction**: Removed non-existent function declarations from core.pxd
- DependentVariable unit access now works through SIQuantity casting approach
- Dataset import/export functions now use actual RMNLib API (DatasetCreateWithImport/DatasetExport)
- Datum class updated to use real RMNLib functions (DatumCreate/DatumCreateResponse)
- All documentation now accurately reflects implemented functionality

Changed
~~~~~~~
- **Converted all documentation from Markdown to reStructuredText** for consistency
- Simplified API to match actual RMNLib capabilities rather than planned features
- Updated all examples to show working code only
- Restructured documentation to match other project documentation style
- API reference now includes separate pages for each class

Technical Details
~~~~~~~~~~~~~~~~~
- ``DependentVariable`` properly inherits from ``SIQuantity`` enabling unit access
- Unit symbols accessed through ``SIQuantityGetUnit()`` and ``SIUnitCopyRootSymbol()``
- All ``create()`` methods verified to work with underlying C API
- Removed over 100 lines of non-existent function declarations
- Successfully compiles and imports without errors

**Breaking Changes from Previous Documentation**
- Removed planned but unimplemented API features
- Simplified method signatures to match actual implementation  
- Updated examples to reflect working API only

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
