# RMNpy GitHub Workflow Setup Plan

## Current Situation

### Existing Workflows
- **`ci.yml`:** Downloads pre-built libraries, tests on push/PR
- **`release.yml`:** Uses cibuildwheel, builds from source, publishes on tags

### Key Issues
1. *### **Implementation Strategy**

**Phase 1: Fresh Start with Minimal Configuration**
- Create new pyproject.toml with minimal, proven cibuildwheel patterns
- Delete existing ci.yml and release.yml to avoid inheriting broken patterns
- Start with Python 3.12 only, expand versions once basic builds work
- **Clean Slate:** All previous tags (v0.1.0-v0.1.63) deleted - fresh start with v0.1.0

**Phase 2: Platform-by-Platform Validation**
- Begin with macOS (working reference), then Linux (manylinux standard), then Windows (MinGW)
- Add dependencies incrementally: OCTypes → SITypes → RMNLib
- Test each platform thoroughly before proceeding

**Phase 3: Gradual Complexity Addition**
- Expand Python versions once base configuration is stable
- Add comprehensive testing and release automation
- Implement version-based PyPI upload strategyation:** Different strategies (pre-built vs build-from-source)
2. **Windows Build Failures:** Python PATH conflicts in cibuildwheel
3. **Maintenance Complexity:** Two separate approaches to maintain

## Critical Requirements

### **Windows: MinGW Python ONLY - NO MSVC**
- **CRITICAL:** Absolutely NO MSVC Python allowed - MinGW Python MANDATORY
- **Why:** C99 features (VLA, complex.h) required - MSVC completely incompatible
- **Python Constraint:** Only Python 3.12 available in MinGW/MSYS2
- **Implementation:** Full MSYS2/MinGW64 environment with MinGW Python ONLY

### **Linux: manylinux Required**
- **Why:** Broad glibc compatibility (2.17+), standardized environment
- **Python Support:** 3.10, 3.11, 3.12+ in containers
- **Implementation:** cibuildwheel manylinux2014 containers

### **Shared Libraries Mandatory**
- **Critical Problem:** Static libraries (.a) cause multiple copies → symbol conflicts
- **Solution:** Shared libraries only (.so/.dylib/.dll) → single instance per library
- **Benefit:** Consistent state across all Python extensions

### **C Libraries Build Dependencies**
- **Build System:** Make (Makefile-based builds ONLY)
- **NOTE:** CMakeLists.txt files are for Xcode project generation only - IGNORE for workflow builds
- **Common Requirements:** C99 compiler (GCC/Clang), Make, Git, Math library (-lm), Bison, Flex
- **Dependency Chain:** OCTypes → SITypes → RMNLib (sequential builds required)

#### **OCTypes (Foundation Library)**
- **Unique:** Complex number parsing, dbghelp.dll (Windows only)
- **Documentation:** Doxygen, Python 3 + Sphinx + Breathe (optional)

#### **SITypes (SI Units Library)**
- **Unique:** SI unit/quantity parsing, OCTypes dependency
- **Network:** curl/unzip for OCTypes release downloads
- **Linking:** Platform-specific linker groups (Linux: --start-group/--end-group)

#### **RMNLib (Signal Processing Library)**
- **Unique:** Multi-dimensional NMR/spectroscopy signal processing
- **Dependencies:** OCTypes + SITypes libraries, libcurl development headers
- **Mathematical:** BLAS/LAPACK for linear algebra, OpenMP for parallel processing
- **Platform BLAS/LAPACK:**
  - **macOS:** Accelerate framework (built-in)
  - **Linux:** OpenBLAS + LAPACKE
  - **Windows:** mingw-w64-x86_64-openblas + mingw-w64-x86_64-lapack

#### **Platform-Specific Packages**
- **Windows (MSYS2):** mingw-w64-x86_64-{toolchain,python,curl,openblas,lapack,openmp}, bison, flex
- **Linux:** build-essential, bison, flex, curl, unzip, libcurl4-openssl-dev, libopenblas-dev, liblapacke-dev, libomp-dev
- **macOS:** Xcode Command Line Tools, Homebrew llvm + libomp, curl/unzip (built-in)

### **MANIFEST.in - Critical Packaging Configuration**
- **Purpose:** Controls what gets included in source distributions (sdist) and package data
- **Current Status:** ✅ **WELL-CONFIGURED** - properly handles all essential components
- **Shared Libraries:** Includes `.so/.dylib/.dll` files in `src/rmnpy/_libs/` for wheel distribution
- **Cython Sources:** Includes `.pyx/.pxd/.pxi` files needed for sdist builds from source
- **Build Files:** Includes `pyproject.toml`, `setup.py`, headers, and build configuration
- **Testing/Scripts:** Includes test files and scripts for complete source distribution
- **CRITICAL:** This file ensures shared libraries are properly bundled in wheels - **DO NOT MODIFY**

### **setup.cfg - Build & Quality Configuration**
- **Purpose:** Wheel configuration, package data specification, and development tool settings
- **Current Status:** ✅ **WELL-CONFIGURED** - proper settings for binary wheel builds
- **Wheel Settings:** `universal = 0` (correct for binary wheels with native libraries)
- **Package Data:** Correctly specifies `rmnpy._libs/*` for shared library inclusion
- **Code Quality:** Well-configured flake8 rules compatible with black formatting
- **CRITICAL:** Package data settings ensure shared libraries are included in wheels - **DO NOT MODIFY**

### **Workflow Impact of Packaging Files**
- **MANIFEST.in & setup.cfg:** Both work independently of workflow changes and should remain untouched
- **Critical dependency:** Our workflow success depends on these files working correctly
- **Well-designed:** Current packaging configuration properly handles shared libraries and binary wheels
## Unified Workflow Solution

### Strategy
- **Single workflow** for both CI (push/PR) and release (tags)
- **cibuildwheel everywhere** - consistent build-from-source approach
- **Platform-specific requirements** enforced via pyproject.toml

### Jobs Architecture
1. **build_wheels** - cibuildwheel on ubuntu/windows/macos
2. **test_wheels** - Install & test built wheels
3. **build_sdist** - Source distribution
4. **upload_pypi** - Minor version bumps (v*.Y.* where Y changes)
5. **github_release** - All tags (enables pip install from artifacts)

### Platform Implementation

**Windows (Python 3.12 only - MinGW ONLY):**
- MSYS2/MinGW64 environment with MinGW Python (NO MSVC PYTHON)
- Build OCTypes→SITypes→RMNLib as .dll shared libraries
- MinGW GCC for C99/VLA/complex.h support

**Linux (Python 3.10+):**
- manylinux2014 containers via cibuildwheel
- Build dependencies as .so shared libraries
- auditwheel for dependency bundling

**macOS (Python 3.10+):**
- Homebrew system dependencies
- Build dependencies as .dylib shared libraries
- delocate for dependency bundling

### Workflow Structure
```yaml
name: CI & Release
on:
  push:
    branches: [master, main]
    tags: ["v*.*.*"]
  pull_request:
    branches: [master, main]
  workflow_dispatch:
```

### Jobs
1. **build_wheels** - cibuildwheel on ubuntu/windows/macos
2. **test_wheels** - Install & test built wheels
3. **build_sdist** - Source distribution
4. **upload_pypi** - Minor version bumps only
5. **github_release** - All tags (pip install from artifacts)

#### Key Implementation Details

**Windows (Python 3.12 only - STRICTLY MinGW):**
- Complete MSYS2/MinGW64 environment for C99 support
- Build .dll shared libraries, use mingw-w64-x86_64-python ONLY
- delvewheel for dependency repair
- **CRITICAL:** NO MSVC Python allowed anywhere in the process
- **Required MSYS2 packages:** mingw-w64-x86_64-gcc, mingw-w64-x86_64-make, mingw-w64-x86_64-python, bison, flex, git

**Linux (Python 3.10+):**
- manylinux2014 containers, build .so shared libraries
- auditwheel for dependency bundling
- **Required packages:** build-essential, bison, flex, git (pre-installed in manylinux)

**macOS (Python 3.10+):**
- Homebrew dependencies, build .dylib shared libraries
- delocate for dependency bundling
- **Required packages:** bison, flex (via Homebrew: `brew install bison flex`)

**Build Process:**
- Dynamic git tag detection for latest dependency releases
- Dependency order: OCTypes → SITypes → RMNLib → RMNpy
- Shared libraries only (reject .a static libraries)

**OCTypes Build Details:**
- **Parser Generation:** Bison/Flex generate `OCComplexParser.c/.h` and `OCComplexScanner.c`
- **C99 Requirements:** Variable Length Arrays (VLA), complex.h, C99 standard compliance
- **Platform Libraries:** Math library (-lm), dbghelp.dll (Windows), platform-specific linking
- **Compiler Flags:** `-std=c99 -fPIC` for shared library compilation
- **Generated Files:** Parser/scanner must be built before other sources (dependency order)

**SITypes Build Details:**
- **Dependency Chain:** Requires OCTypes shared library before building
- **Parser Generation:** Bison/Flex generate SI unit and quantity parsers
- **Network Dependency:** Downloads OCTypes releases via curl (latest or pinned version)
- **Archive Extraction:** Unzips OCTypes headers and libraries to third_party/
- **Linking Requirements:** Math library (-lm), OCTypes shared library linkage
- **Platform Linking:** Linux uses linker groups (--start-group/--end-group) for circular deps
- **Build Order:** OCTypes download → parser generation → compilation → shared library creation

**RMNLib Build Details:**
- **Dependency Chain:** Requires OCTypes + SITypes shared libraries before building
- **Multi-dimensional Signal Processing:** Advanced mathematical operations for NMR/spectroscopy
- **Network Dependencies:** Downloads OCTypes + SITypes releases via curl (latest or pinned versions)
- **Archive Extraction:** Unzips both OCTypes and SITypes to third_party/ directory structure
- **Mathematical Libraries:**
  - **macOS:** Accelerate framework (built-in BLAS/LAPACK)
  - **Linux:** OpenBLAS + LAPACKE libraries
  - **Windows:** OpenBLAS via MinGW packages
- **Parallel Processing:** OpenMP for multi-threading numerical operations
- **Linking Requirements:** Math library (-lm), libcurl, BLAS/LAPACK, OpenMP, OCTypes + SITypes
- **Platform Linking:** Linux uses linker groups for complex circular dependencies
- **Build Order:** OCTypes + SITypes download → compilation → BLAS/LAPACK linking → shared library creation

### Release Strategy
- **PyPI uploads:** Minor version bumps (v0.1.5→v0.2.0, v1.1.3→v1.2.0)
- **GitHub releases:** All tagged versions (enables `pip install` from GitHub artifacts)
- **Artifact format:** `pip install https://github.com/pjgrandinetti/RMNpy/releases/download/v*.*.*/rmnpy-*-py3-none-*.whl`

## Implementation Status

### Current Assets
- **pyproject.toml:** ✅ Configured for build-from-source with MinGW/manylinux
- **setup.py:** ✅ MinGW enforcement and flexible library detection
- **release.yml:** ✅ Basic cibuildwheel structure (needs MinGW integration)

### Next Steps
1. Implement unified workflow with MinGW Python strategy
2. Test C99/VLA/complex.h compilation on all platforms
3. Validate shared library usage and wheel functionality
4. Deploy unified workflow, retire separate CI/release workflows

This unified approach provides consistent builds, C99 compliance, shared library safety, and simplified maintenance.

### Implementation Steps

1. **Phase 1:** Create unified workflow file
   - Merge ci.yml and release.yml logic
   - Use existing pyproject.toml cibuildwheel configuration
   - Implement STRICT MinGW Python strategy for Windows (NO MSVC)

2. **Phase 2:** Test and validate
   - Test on push/PR scenarios
   - Test wheel installation and functionality
   - Validate EXCLUSIVE MinGW Python usage on Windows (verify NO MSVC)

3. **Phase 3:** Deploy and cleanup
   - Replace existing workflows
   - Update documentation
   - Monitor first few workflow runs

### Risk Mitigation

**Build Time:** Building from source increases build time, but provides reproducibility and C99 compatibility
**Windows MinGW Requirement:** MinGW setup is mandatory (not optional) for C99/VLA/complex.h support
**MSVC PROHIBITION:** ABSOLUTELY NO MSVC Python allowed on Windows - will fail due to missing C99 features
**Linux Container Overhead:** manylinux containers add some overhead but ensure broad compatibility
**Dependency Changes:** Dynamic tag detection ensures latest stable releases
**Testing Coverage:** Wheel testing ensures artifacts work correctly across all target platforms
**Configuration Risk:** Existing pyproject.toml has failed Windows/Linux builds - requires fresh start
**Incremental Approach:** Build minimal working configuration first, add complexity gradually

### Current Status

- **pyproject.toml:** ⚠️ **PARTIALLY WORKING** - macOS builds succeed, Windows/Linux builds fail
- **setup.py:** Compatible with cibuildwheel and MinGW, enforces MinGW on Windows ✅
- **setup.cfg:** ✅ **WELL-CONFIGURED** - proper wheel configuration, package data, linting rules
- **MANIFEST.in:** ✅ **CRITICAL & WELL-CONFIGURED** - handles shared library bundling, Cython sources, sdist packaging
- **Release workflow:** Basic structure present, but relies on failing pyproject.toml configuration
- **CI workflow:** Complex and uses different strategy than release workflow
- **Assessment:** Existing configuration unreliable - recommend fresh start with proven patterns

### Implementation Strategy

**Phase 1: Fresh Start with Minimal Configuration**
- Create new pyproject.toml with minimal, proven cibuildwheel patterns
- Delete existing ci.yml and release.yml to avoid inheriting broken patterns
- Start with Python 3.12 only, expand versions once basic builds work

**Phase 2: Platform-by-Platform Validation**
- Begin with macOS (working reference), then Linux (manylinux standard), then Windows (MinGW)
- Add dependencies incrementally: OCTypes → SITypes → RMNLib
- Test each platform thoroughly before proceeding

**Phase 3: Gradual Complexity Addition**
- Expand Python versions once base configuration is stable
- Add comprehensive testing and release automation
- Implement version-based PyPI upload strategy

### Next Actions

1. Create minimal pyproject.toml using proven cibuildwheel patterns (NOT existing config)
2. Create unified workflow from scratch using working examples
3. Test platforms individually with incremental dependency addition
2. Ensure manylinux container usage for all Linux builds via cibuildwheel
3. Test workflow with current codebase, validating C99/VLA/complex.h compilation
4. Validate wheel building and testing on all platforms with EXCLUSIVE MinGW Python on Windows
5. Deploy unified workflow and retire separate CI/release workflows

This plan provides a clear path to a more maintainable, consistent, and reliable build system that leverages the proven cibuildwheel approach while meeting the mandatory requirements for C99 support (STRICTLY MinGW Python on Windows - NO MSVC) and broad Linux compatibility (manylinux containers).
