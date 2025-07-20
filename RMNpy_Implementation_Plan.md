# RMNpy Implementation Plan

## Overview
This document outlines a systematic approach to creating RMNpy, a Python package that exposes three C libraries (OCTypes, SITypes, and RMNLib) using Cython. The plan follows a phased approach, building complexity incrementally.

## Project Architecture

### Directory Structure

```
RMNpy/
├── setup.py
├── pyproject.toml
├── README.md
├── requirements.txt
├── src/
│   └── rmnpy/
│       ├── __init__.py
│       ├── _c_api/
│       │   ├── __init__.py
│       │   ├── octypes.pxd
│       │   ├── sitypes.pxd
│       │   └── rmnlib.pxd
│       ├── helpers/
│       │   ├── __init__.py
│       │   └── octypes.pyx
│       └── wrappers/
│           ├── __init__.py
│           ├── sitypes/
│           │   ├── __init__.py
│           │   ├── scalar.pyx
│           │   ├── unit.pyx
│           │   └── dimensionality.pyx
│           └── rmnlib/
│               ├── __init__.py
│               └── core.pyx
├── tests/
│   ├── test_helpers/
│   ├── test_sitypes/
│   └── test_rmnlib/
└── docs/
```

## Phase 1: Project Foundation and OCTypes Helpers

### 1.1 Initial Setup
- [x] Create empty RMNpy directory
- [x] Set up basic Python package structure
- [x] Create `setup.py` with minimal configuration
- [x] Create `pyproject.toml` for modern Python packaging
- [ ] Set up version control and basic documentation
- [x] **Create Makefile for library management**:
  - `synclib`: Copy libraries from local ../OCTypes, ../SITypes, ../RMNLib directories
  - `download-libs`: Download libraries from GitHub releases
  - `clean-libs`: Remove local libraries to force re-download
  - `clean`: Remove generated C files and build artifacts
  - `rebuild`: Clean and rebuild the package
- [x] **Set up library dependency management**:
  - Create `lib/` directory structure for compiled libraries (.a files)
  - Create `include/` directory structure for C headers (OCTypes/, SITypes/, RMNLib/)
  - Handle both local development and GitHub release scenarios
- [x] **Configure build system integration**:
  - Ensure setup.py can locate libraries in `lib/` directory
  - Ensure setup.py can find headers in `include/` directory
  - Support for different library naming conventions (libRMNLib.a → libRMN.a)
- [x] **Set up documentation system** (following OCTypes/SITypes approach):
  - Create `docs/` directory with Sphinx + Breathe + Doxygen integration
  - Create `docs/conf.py` for Sphinx configuration with Python autodoc support
  - Create `docs/requirements.txt` (sphinx>=3.1.0, sphinx-rtd-theme>=0.5.2, breathe>=4.13.0)
  - Create `docs/index.rst` with project overview and API reference structure
  - Create `docs/background.rst` for conceptual documentation
  - Create `docs/_static/` directory for custom CSS and assets
  - Create `docs/api/` directory structure for API documentation
  - Create `.readthedocs.yaml` for Read the Docs integration
  - Configure Sphinx extensions: autodoc, napoleon, breathe for Python + C integration
  - Set up `sphinx_rtd_theme` for consistent styling with OCTypes/SITypes
- [x] **Create development workflow documentation**:
  - Instructions for using local libraries vs GitHub releases
  - Build and installation procedures
  - Makefile usage guide
  - Documentation building and publishing workflow

### 1.2 OCTypes C API Declaration ✅ COMPLETE
**Goal**: Define the C interface for OCTypes in Cython

**Status**: ✅ **COMPLETED** - All OCTypes C API functions successfully declared in Cython

**Files created**:
- [x] `src/rmnpy/_c_api/octypes.pxd` (285+ lines of comprehensive API declarations)

**Key components completed**:
- [x] OCString: creation, manipulation, conversion functions (OCStringGetCString fix applied)
- [x] OCArray: creation, element access, iteration with callback support
- [x] OCNumber: comprehensive numeric type handling with 19 try-get accessor functions
- [x] OCData: binary data management (mutable and immutable)
- [x] OCBoolean: boolean type support with kOCBooleanTrue/kOCBooleanFalse
- [x] OCDictionary: key-value storage with retain/release/hash callbacks
- [x] OCSet: unordered collections with full callback structure
- [x] OCIndexArray: index management and manipulation
- [x] OCIndexSet: index set operations
- [x] OCIndexPairSet: paired index relationships
- [x] Memory management functions (OCRetain/OCRelease, simplified approach)
- [x] Complex number support (C99 float_complex, double_complex)
- [x] All callback structures and default configurations

**Advanced features implemented**:
- [x] **OCNumber Try-Get Accessors**: All 19 safe extraction functions (OCNumberTryGetUInt8, OCNumberTryGetSInt8, OCNumberTryGetFloat32, OCNumberTryGetFloat64, OCNumberTryGetComplex64, OCNumberTryGetComplex128, etc.)
- [x] **Complex Number Creation**: OCNumberCreateWithFloatComplex, OCNumberCreateWithDoubleComplex
- [x] **Type Safety**: Proper const/mutable distinctions throughout API
- [x] **Build Integration**: Library linking (libOCTypes.a, libSITypes.a, libRMN.a) and header inclusion

**Testing strategy completed**:
- [x] Create simple test to verify C library linking ✅
- [x] Test basic function declarations compile ✅  
- [x] Comprehensive validation of all 19 try-get accessor functions ✅
- [x] Complex number type declaration validation ✅
- [x] Build system integration testing ✅

**Validation Results**:
```
✅ Found all 19 expected try-get accessor function declarations
✅ Complex number types properly declared  
✅ Complex number creation functions properly declared
✅ OCTypes .pxd syntax validated successfully
```

**Technical Achievements**:
1. **Complete API Coverage**: 285+ lines covering entire OCTypes C library
2. **User Feedback Integration**: Removed autorelease pools, fixed function names, simplified memory management
3. **Advanced Numeric Support**: All 19 numeric types with safe try-get conversion functions
4. **Complex Numbers**: Full C99 complex support with proper Cython integration
5. **Robust Build System**: Automatic library detection and linking verification

### 1.3 OCTypes Helper Functions
**Goal**: Create conversion helpers between Python types and OCTypes

**Files to create**:
- `src/rmnpy/helpers/octypes.pyx`
- `tests/test_helpers/test_octypes.py`

**Key helper functions**:

1. **String Helpers**:
   - `py_string_to_ocstring(str) -> OCStringRef`
   - `ocstring_to_py_string(OCStringRef) -> str`
   - `py_string_to_ocmutablestring(str) -> OCMutableStringRef`

2. **Array Helpers**:
   - `py_list_to_ocarray(list) -> OCArrayRef`
   - `ocarray_to_py_list(OCArrayRef) -> list`
   - `py_list_to_ocmutablearray(list) -> OCMutableArrayRef`

3. **Number Helpers**:
   - `py_number_to_ocnumber(int/float/complex) -> OCNumberRef`
   - `ocnumber_to_py_number(OCNumberRef) -> int/float/complex`
   - Support for all OCNumber types: int8, int16, int32, int64, uint8, uint16, uint32, uint64, float32, float64, complex float, complex double

4. **Data Helpers**:
   - `py_bytes_to_ocdata(bytes) -> OCDataRef`
   - `ocdata_to_py_bytes(OCDataRef) -> bytes`
   - `py_bytes_to_ocmutabledata(bytes) -> OCMutableDataRef`

5. **Boolean Helpers**:
   - `py_bool_to_ocboolean(bool) -> OCBooleanRef`
   - `ocboolean_to_py_bool(OCBooleanRef) -> bool`
   - Handle singleton kOCBooleanTrue/kOCBooleanFalse constants

6. **Index Collection Helpers**:
   - `py_list_to_ocindexarray(list[int]) -> OCIndexArrayRef`
   - `ocindexarray_to_py_list(OCIndexArrayRef) -> list[int]`
   - `py_set_to_ocindexset(set[int]) -> OCIndexSetRef`
   - `ocindexset_to_py_set(OCIndexSetRef) -> set[int]`
   - `py_dict_to_ocindexpairset(dict[int, int]) -> OCIndexPairSetRef`
   - `ocindexpairset_to_py_dict(OCIndexPairSetRef) -> dict[int, int]`

7. **Dictionary Helpers**:
   - `py_dict_to_ocdictionary(dict) -> OCDictionaryRef`
   - `ocdictionary_to_py_dict(OCDictionaryRef) -> dict`
   - `py_dict_to_ocmutabledictionary(dict) -> OCMutableDictionaryRef`

8. **Set Helpers**:
   - `py_set_to_ocset(set) -> OCSetRef`
   - `ocset_to_py_set(OCSetRef) -> set`
   - `py_set_to_ocmutableset(set) -> OCMutableSetRef`

9. **Memory Management Helpers**:
   - `octype_retain(OCTypeRef) -> OCTypeRef`
   - `octype_release(OCTypeRef) -> None`
   - `octype_get_retain_count(OCTypeRef) -> int`

10. **Type Introspection Helpers**:
    - `octype_get_type_id(OCTypeRef) -> OCTypeID`
    - `octype_equal(OCTypeRef, OCTypeRef) -> bool`
    - `octype_deep_copy(OCTypeRef) -> OCTypeRef`

**Testing checklist**:
- [ ] Convert Python string ↔ OCString/OCMutableString
- [ ] Convert Python list ↔ OCArray/OCMutableArray  
- [ ] Convert Python numbers ↔ OCNumber (all numeric types)
- [ ] Convert Python bytes ↔ OCData/OCMutableData
- [ ] Convert Python bool ↔ OCBoolean (singleton handling)
- [ ] Convert Python int collections ↔ OCIndexArray/OCIndexSet/OCIndexPairSet
- [ ] Convert Python dict ↔ OCDictionary/OCMutableDictionary
- [ ] Convert Python set ↔ OCSet/OCMutableSet
- [ ] Test Unicode handling in strings
- [ ] Test memory management (no leaks, proper retain/release)
- [ ] Test edge cases (empty collections, None values, large data)
- [ ] Test type validation and error handling
- [ ] Test all numeric type conversions (int8-uint64, float32/64, complex)
- [ ] Test nested collection conversions

### 1.4 Phase 1 Integration
**Goal**: Ensure all OCTypes helpers work correctly

**Tasks**:
- [ ] Create comprehensive integration tests
- [ ] Test helper function combinations
- [ ] Optimize memory management across conversions
- [ ] Document helper function usage patterns
- [ ] Performance testing for conversion overhead

## Phase 2: SITypes Integration

### 2.1 SITypes C API Declaration
**Goal**: Define the C interface for SITypes

**Files to create**:
- `src/rmnpy/_c_api/sitypes.pxd`

**Key components**:
- Unit system definitions
- Dimensionality handling
- Scalar value management
- Conversion functions
- Dependencies on OCTypes

### 2.2 SITypes Core Implementation
**Goal**: Implement fundamental SITypes functionality

**Files to create**:
- `src/rmnpy/wrappers/sitypes/scalar.pyx`
- `src/rmnpy/wrappers/sitypes/unit.pyx`
- `src/rmnpy/wrappers/sitypes/dimensionality.pyx`

**Implementation priorities**:
1. **Scalar**: Physical quantities with units
2. **Unit**: Unit definitions and conversions
3. **Dimensionality**: Dimensional analysis

### 2.3 SITypes Testing
**Goal**: Comprehensive testing of SITypes functionality

**Files to create**:
- `tests/test_sitypes/test_scalar.py`
- `tests/test_sitypes/test_unit.py`
- `tests/test_sitypes/test_dimensionality.py`

**Testing focus**:
- Unit conversions accuracy
- Dimensional analysis correctness
- Integration with OCTypes
- Performance with large datasets

### 2.4 Phase 2 Integration
**Goal**: Ensure SITypes works seamlessly with OCTypes

**Tasks**:
- [ ] Test OCTypes + SITypes interoperability
- [ ] Optimize data flow between libraries
- [ ] Create combined usage examples
- [ ] Performance benchmarking

## Phase 3: RMNLib Integration

### 3.1 RMNLib C API Declaration
**Goal**: Define the C interface for RMNLib

**Files to create**:
- `src/rmnpy/_c_api/rmnlib.pxd`

**Key components**:
- High-level RMN functions
- Data processing algorithms
- Analysis tools
- Dependencies on OCTypes and SITypes

### 3.2 RMNLib Core Implementation
**Goal**: Implement main RMNLib functionality

**Files to create**:
- `src/rmnpy/wrappers/rmnlib/core.pyx`

**Implementation approach**:
- Focus on most commonly used functions first
- Leverage existing OCTypes and SITypes infrastructure
- Implement high-level Python-friendly interfaces

### 3.3 RMNLib Testing
**Goal**: Test complete RMNLib functionality

**Files to create**:
- `tests/test_rmnlib/test_core.py`

**Testing strategy**:
- End-to-end workflow testing
- Integration with real scientific data
- Performance testing with large datasets

## Phase 4: Polish and Optimization

### 4.1 Documentation
- [ ] Complete API documentation
- [ ] Usage examples and tutorials
- [ ] Performance guidelines
- [ ] Migration guide (if applicable)

### 4.2 Performance Optimization
- [ ] Profile critical paths
- [ ] Optimize memory allocation patterns
- [ ] Minimize Python ↔ C conversion overhead
- [ ] Parallel processing where applicable

### 4.3 Quality Assurance
- [ ] Comprehensive test suite (>90% coverage)
- [ ] Memory leak testing
- [ ] Cross-platform testing
- [ ] Continuous integration setup

### 4.4 Packaging and Distribution
- [ ] Wheel building for multiple platforms
- [ ] PyPI packaging
- [ ] Conda packaging
- [ ] Installation documentation

## Implementation Guidelines

### Development Principles
1. **Incremental Development**: Complete one component before moving to the next
2. **Test-Driven**: Write tests as you implement features
3. **Memory Safety**: Careful attention to C memory management
4. **Error Handling**: Proper exception handling for C errors
5. **Performance**: Minimize overhead in critical paths
6. **Helper-Based Architecture**: OCTypes serve as conversion utilities, not user-facing classes

### Quality Standards
- **Code Coverage**: Target >90% test coverage
- **Documentation**: Every public API must be documented
- **Memory Safety**: Zero memory leaks in normal operation
- **Performance**: Benchmarks for critical operations
- **Compatibility**: Support Python 3.8+

### OCTypes Design Philosophy
- **Internal Use Only**: OCTypes are not exposed to end users
- **Conversion Focused**: Helper functions handle Python ↔ C conversions
- **Memory Efficient**: Minimize allocation/deallocation overhead
- **Type Safety**: Clear conversion paths with proper error handling

### Risk Mitigation
- **Complexity Management**: Keep each phase focused and limited
- **Integration Testing**: Test library interactions early and often
- **Fallback Plans**: Identify minimum viable functionality for each phase
- **Performance Monitoring**: Regular benchmarking to catch regressions

## Success Criteria

### Phase 1 Success
- [ ] All OCTypes helper functions implemented and tested
- [ ] Memory management verified (no leaks)
- [ ] Python ↔ C conversions working correctly
- [ ] Performance acceptable for typical conversion loads

### Phase 2 Success
- [ ] SITypes integrated with OCTypes helpers
- [ ] Unit conversions working correctly
- [ ] Scientific computation workflows functional
- [ ] Performance acceptable for typical use cases

### Phase 3 Success
- [ ] Complete RMNLib functionality available
- [ ] End-to-end scientific workflows working
- [ ] Documentation complete
- [ ] Package ready for distribution

## Timeline Estimate
- **Phase 1**: 1-2 weeks (OCTypes helpers)
- **Phase 2**: 1-2 weeks (SITypes integration)
- **Phase 3**: 1-2 weeks (RMNLib integration)
- **Phase 4**: 1 week (Polish and packaging)

**Total**: 4-7 weeks for complete implementation

This plan provides a structured approach to building RMNpy incrementally, with OCTypes serving as internal conversion utilities rather than user-facing classes. The focus on helper functions in Phase 1 creates a solid foundation for the higher-level SITypes and RMNLib wrappers.
