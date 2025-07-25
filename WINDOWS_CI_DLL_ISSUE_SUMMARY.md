# Windows CI DLL Import Failure - Issue Summary and Help Request

## Problem Overview

Our GitHub Actions Windows CI workflow is consistently failing with a DLL import error despite successful compilation of Python extensions. The error occurs when trying to import the `dimensionality` module from our `rmnpy` package.

**Error Message:**
```
ImportError: DLL load failed while importing dimensionality: The specified module could not be found.
```

## Project Context

- **Project**: RMNpy - Python bindings for RMNLib (scientific computing library)
- **Build System**: Cython extensions compiled with MinGW64 on Windows
- **Dependencies**: OCTypes, SITypes, RMNLib (static libraries), OpenBLAS, LAPACK, curl
- **Target**: Python 3.12 on Windows GitHub Actions runner

## What We've Tried

### 1. Basic DLL Copying Approach
- Copied essential MinGW runtime DLLs to package directory
- Copied dependency DLLs (curl, OpenBLAS, LAPACK, Python runtime)
- Added DLL directories to Python's DLL search path using `os.add_dll_directory()`

### 2. Comprehensive Dependency Analysis
- Used `objdump` to analyze .pyd file dependencies
- Found that compiled extensions only depend on basic runtime DLLs:
  - `libgcc_s_seh-1.dll`
  - `KERNEL32.dll`
  - `msvcrt.dll`
  - `libpython3.12.dll`
  - `libwinpthread-1.dll`

### 3. Enhanced CI Workflow
- Added Steps 5-6 to CI workflow for deep dependency analysis
- Implemented automatic detection of missing DLLs
- Added recursive search of MinGW installation for missing dependencies
- Implemented automatic copying of found DLLs
- Added retry logic after DLL fixes

### 4. Performance Optimizations
- Successfully optimized build performance (build time reduced significantly)
- Maintained comprehensive debugging capabilities

## Current Status

The workflow reaches the import testing phase but fails at:
```
Step 3: Testing package structure
Traceback (most recent call last):
  File "D:\a\RMNpy\RMNpy\src\rmnpy\__init__.py", line 19, in <module>
    from .wrappers.sitypes import Dimensionality, Scalar, Unit
  File "D:\a\RMNpy\RMNpy\src\rmnpy\wrappers\sitypes\__init__.py", line 8, in <module>
    from .dimensionality import Dimensionality
ImportError: DLL load failed while importing dimensionality: The specified module could not be found.
```

## Key Observations

1. **Compilation Success**: All .pyd files compile successfully with MinGW64
2. **DLL Dependencies Met**: `objdump` analysis shows all required DLLs are present
3. **Runtime Failure**: Import fails despite apparent dependency satisfaction
4. **Static vs Dynamic Linking**: Our C libraries (OCTypes, SITypes, RMNLib) are statically linked (.a files)

## Technical Details

### Build Environment
- **OS**: Windows Server 2022 (GitHub Actions)
- **Compiler**: MinGW64 GCC 15.1.0
- **Python**: 3.12.10 (GitHub Actions hosted)
- **MSYS2**: Latest with mingw-w64-x86_64 packages

### Dependency Analysis Results
```
dimensionality.cp312-win_amd64.pyd dependencies:
- libgcc_s_seh-1.dll ✓ (present)
- KERNEL32.dll ✓ (system)
- msvcrt.dll ✓ (system)
- libpython3.12.dll ✓ (present)
- libwinpthread-1.dll ✓ (present)
```

### Current CI Workflow Enhancement
- Added comprehensive DLL dependency analysis using objdump
- Implemented auto-detection and resolution of missing DLLs
- Added recursive MinGW installation searching
- Implemented automatic copying of missing dependencies
- Added retry logic after DLL fixes
- Enhanced error reporting and diagnostics

## Successful Aspects

1. **Build Performance**: Significantly improved CI build times
2. **Library Detection**: Successfully downloads and integrates static libraries
3. **Compilation**: All Cython extensions compile without errors
4. **DLL Analysis**: Comprehensive dependency analysis framework working

## Help Needed

We need assistance with resolving this Windows-specific DLL import issue. Despite having:
- All required DLLs present and accessible
- Proper DLL search paths configured
- Successful compilation
- Comprehensive dependency analysis

The Python import still fails with "DLL load failed while importing dimensionality: The specified module could not be found."

### Specific Questions

1. **Hidden Dependencies**: Could there be implicit dependencies not shown by objdump?
2. **Python Extension Loading**: Are there Windows-specific requirements for loading MinGW-compiled .pyd files?
3. **DLL Loading Order**: Could the order of DLL loading or search paths be causing issues?
4. **MinGW vs MSVC**: Are there compatibility issues between MinGW-compiled extensions and the MSVC-compiled Python from GitHub Actions?
5. **Static Library Integration**: Could our statically linked C libraries be causing runtime issues?

### What We'd Like to Try Next

1. **Alternative Dependency Tools**: Use different tools to analyze dependencies (e.g., Dependency Walker, Process Monitor)
2. **Python Debug Logging**: Enable verbose Python import logging to see exactly where the failure occurs
3. **Alternative Build Approaches**: Consider MSVC compilation or different linking strategies
4. **Runtime Environment Debugging**: Examine the exact runtime environment when the import fails
5. **Symbol Analysis**: Check if all required symbols are properly exported from the .pyd files

## Build Toolchain Constraints

**MinGW vs MSVC Considerations:**

We are **NOT able to switch from MinGW to MSVC** for Windows builds due to critical technical requirements. Our use of MinGW is mandatory for:

1. **C99 Standard Compliance**: Our codebase extensively uses C99 features including:
   - `complex.h` for complex number arithmetic
   - Variable-length arrays (VLAs)
   - C99 designated initializers
   - Other C99/C11 standard library features

2. **Cross-platform consistency**: MinGW provides GCC-compatible compilation ensuring identical behavior across Linux, macOS, and Windows

3. **Static library compatibility**: Our C dependencies (OCTypes, SITypes, RMNLib) are built with GCC and rely on C99 features

**MSVC limitations that prevent adoption:**

- **Incomplete C99 support**: MSVC lacks support for `complex.h` and other essential C99 features
- **Compatibility issues**: Our scientific computing libraries require full C99 compliance
- **Legacy constraints**: MSVC focuses on C++ and has limited C standard support
- **Dependency chain**: All our static libraries would need complete rewrites to avoid C99 features

**Technical constraints:**

- The `complex.h` header and complex arithmetic are fundamental to our mathematical computations
- Variable-length arrays are used throughout the codebase
- C99 standard library functions are extensively utilized
- Scientific computing libraries (OpenBLAS, LAPACK integration) expect C99 compliance

**Answer: No, we cannot switch to MSVC due to mandatory C99 feature requirements (`complex.h`, VLAs, etc.) that MSVC does not support. MinGW/GCC is a strict requirement for our project.**

**Alternative approaches needed:**

- Solutions must work within the MinGW/GCC toolchain
- Focus on DLL loading and Python extension compatibility issues specific to MinGW-compiled extensions
- Investigate MinGW-specific runtime library requirements

## Files and Context

- **CI Workflow**: `.github/workflows/ci.yml` (enhanced with comprehensive DLL debugging)
- **Build Configuration**: `setup.py` (configured for MinGW compilation)
- **Package Structure**: Cython extensions in `src/rmnpy/wrappers/sitypes/`
- **Dependencies**: Static libraries from OCTypes, SITypes, RMNLib releases

Any insights, suggestions, or alternative approaches would be greatly appreciated. We're particularly interested in Windows-specific solutions for Python extension DLL loading issues.
