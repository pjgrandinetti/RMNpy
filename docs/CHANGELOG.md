# RMNpy Changelog

## Version 0.1.13 (August 2025)

### Fixed
- Windows CI build failures due to static inline function export issues
- Updated to OCTypes v0.1.4 and RMNLib v0.1.4 with DLL export fixes
- All platforms now building successfully

### Added
- CI status badge to README

---

## Version 0.1.0 (In Development)

### Recent Changes

- Added Unit multiplier validation in `__init__()` method
- Removed redundant `Unit.parse()` method - use constructor instead
- Removed redundant `Dimensionality.parse()` method - use constructor instead
- Updated all tests to use constructor patterns
- Updated documentation to reflect simplified API

### Current Status

Work in progress - following the MasterPlan for full implementation.
