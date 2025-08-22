# RMNpy cibuildwheel Implementation Plan

## Overview

This document outlines the implementation plan for building RMNpy wheels using cibuildwheel. RMNpy is a Python package for analysis that depends on three C libraries: OCTypes, SITypes, and RMNLib. Our strategy focuses on Linux and macOS builds, with Windows users supported via WSL2.

## Project Goals

### Primary Objectives
- **Automated Wheel Building:** Use cibuildwheel for consistent, reproducible builds
- **Cross-Platform Support:** Linux (manylinux2014) and macOS native builds
- **C99 Compliance:** Full support for Variable Length Arrays (VLA) and complex.h
- **Dependency Management:** Build OCTypes → SITypes → RMNLib dependency chain
- **Quality Assurance:** Automated testing and wheel validation

### Target Platforms
- **Linux:** manylinux2014 (broad glibc compatibility)
- **macOS:** Native builds (Homebrew dependencies)
- **Windows:** WSL2 strategy (use Linux wheels)

## Architecture Overview

### Package Structure
```
RMNpy/
├── src/rmnpy/           # Python package source
├── pyproject.toml       # Build configuration
├── setup.py            # Build script with C extensions
└── .github/workflows/   # CI/CD automation
```

### Dependency Chain
1. **OCTypes:** Foundation library (complex numbers, data types)
2. **SITypes:** SI units library (depends on OCTypes)
3. **RMNLib:** Signal processing library (depends on OCTypes + SITypes)
4. **RMNpy:** Python bindings (depends on all above)

## Technical Requirements

### C99 Features Required
- **Variable Length Arrays (VLA):** Dynamic array allocation in C code
- **Complex Number Support:** complex.h header and arithmetic operations
- **Math Libraries:** Linking with libm for mathematical functions
- **Standard Compliance:** Full C99 feature support across platforms

### Shared Library Strategy
- **Rationale:** Avoid static library symbol conflicts between extensions
- **Implementation:** Build all dependencies as shared libraries (.so/.dylib)
- **Benefits:** Single instance per library, consistent state management

### Build Tools
- **Linux:** GCC, Make, Bison, Flex, OpenBLAS, LAPACK
- **macOS:** Clang, Make, Bison, Flex, Accelerate framework
- **Both:** curl, unzip for dependency downloads

## cibuildwheel Configuration

### pyproject.toml Structure
```toml
[tool.cibuildwheel]
build = "cp312-*"
skip = "pp* *-win* *-manylinux_i686 *-musllinux_*"
test-command = "python -c 'import rmnpy; print(\"RMNpy import successful\")'"

[tool.cibuildwheel.linux]
manylinux-x86_64-image = "manylinux2014"
before-all = [
    # Install system dependencies
    # Download and build OCTypes
    # Download and build SITypes
    # Download and build RMNLib
]

[tool.cibuildwheel.macos]
before-all = [
    # Install Homebrew dependencies
    # Download and build dependency chain
]
```

### Dependency Build Process
1. **Download:** GitHub API to get latest release tags
2. **Extract:** Validate archive format and extract source
3. **Build:** Make-based builds with proper compiler settings
4. **Install:** Install headers and libraries to system paths
5. **Validate:** Verify successful installation

## Platform-Specific Implementation

### Linux (manylinux2014)
- **Container:** Provides broad glibc compatibility (2.17+)
- **Package Manager:** yum for system dependencies
- **Compiler:** GCC (available in container)
- **Math Libraries:** OpenBLAS + LAPACKE for linear algebra
- **Wheel Repair:** auditwheel for dependency bundling

### macOS (Native)
- **Package Manager:** Homebrew for build dependencies
- **Compiler:** Clang with Xcode Command Line Tools
- **Math Libraries:** Accelerate framework (built-in BLAS/LAPACK)
- **Wheel Repair:** delocate-wheel for dependency bundling

### Windows Strategy (WSL2)
- **Approach:** No native Windows builds
- **User Experience:** WSL2 provides excellent Linux compatibility
- **Performance:** Near-native speed with full C99 support
- **Ecosystem:** Standard Python scientific stack works perfectly
- **Installation:** Clear documentation for WSL2 setup

## Dependency Library Details

### OCTypes (Foundation)
- **Purpose:** Complex number parsing, foundational data types
- **Repository:** https://github.com/pjgrandinetti/OCTypes
- **Build System:** Make-based
- **Dependencies:** Bison, Flex for parser generation
- **Output:** libOCTypes.so/.dylib

### SITypes (SI Units)
- **Purpose:** SI unit and quantity parsing/validation
- **Repository:** https://github.com/pjgrandinetti/SITypes
- **Dependencies:** OCTypes headers and library
- **Build System:** Make-based with automatic OCTypes download
- **Output:** libSITypes.so/.dylib

### RMNLib (Signal Processing)
- **Purpose:** Multi-dimensional NMR spectroscopy signal processing
- **Repository:** https://github.com/pjgrandinetti/RMNLib
- **Dependencies:** OCTypes + SITypes + BLAS/LAPACK + OpenMP
- **Complexity:** Advanced mathematical operations
- **Output:** libRMNLib.so/.dylib

## Current Implementation Status

### Working Components
- ✅ **Basic cibuildwheel setup:** pyproject.toml configuration
- ✅ **GitHub Actions workflow:** test-minimal.yml
- ✅ **Dependency detection:** GitHub API for latest releases
- ✅ **OCTypes builds:** Successfully building with VERSION=1.0.0

### Current Issues (Active Work)
- 🔧 **SITypes macOS:** VERSION variable issues causing linker errors
- 🔧 **RMNLib Linux:** Hardcoded clang needs sed substitution to use gcc
- 🔧 **Archive validation:** Enhanced format checking needed

### Next Steps
1. **Fix dependency builds:** Ensure all libraries build consistently
2. **Wheel validation:** Verify wheels install and import correctly
3. **Testing integration:** Add comprehensive test suite
4. **Documentation:** User installation guides

## Build Automation

### GitHub Actions Workflow
```yaml
name: Build Wheels
on: [push, pull_request]

jobs:
  build_wheels:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - name: Build wheels
        uses: pypa/cibuildwheel@v2.21.0
      - uses: actions/upload-artifact@v4
        with:
          name: wheels
          path: ./wheelhouse/*.whl
```

### Testing Strategy
- **Build Tests:** Verify wheels build without errors
- **Import Tests:** Confirm Python can import rmnpy
- **Functionality Tests:** Basic C99 feature validation
- **Performance Tests:** Ensure shared libraries work correctly

## Quality Assurance

### Validation Checklist
- [ ] All dependency libraries build successfully
- [ ] Wheels contain proper shared library dependencies
- [ ] Python import succeeds on clean systems
- [ ] C99 VLA and complex.h features work
- [ ] Mathematical operations use BLAS/LAPACK correctly
- [ ] Memory management is correct (no leaks)

### Error Handling
- **Build Failures:** Clear error messages and troubleshooting guides
- **Dependency Issues:** Robust fallbacks for GitHub API
- **Platform Differences:** Consistent behavior across Linux/macOS

## Documentation Plan

### User Documentation
- **Installation Guide:** Standard pip install instructions
- **WSL2 Setup:** Detailed Windows user guidance
- **Troubleshooting:** Common issues and solutions
- **API Reference:** Python interface documentation

### Developer Documentation
- **Build Instructions:** Local development setup
- **Dependency Management:** How to update C libraries
- **Testing Procedures:** Running the full test suite
- **Release Process:** Creating and publishing wheels

## Success Metrics

### Primary Goals
- ✅ **Automated Builds:** cibuildwheel produces wheels reliably
- ✅ **Cross-Platform:** Linux and macOS wheels work correctly
- ✅ **User Experience:** Simple pip install process
- ✅ **Performance:** Efficient shared library usage

### Long-term Objectives
- **Maintenance:** Sustainable update process for dependencies
- **Community:** Clear contribution guidelines
- **Reliability:** Robust CI/CD pipeline
- **Ecosystem:** Integration with broader Python scientific stack

This plan focuses on delivering a robust, maintainable cibuildwheel implementation for RMNpy that serves the scientific Python community effectively.
