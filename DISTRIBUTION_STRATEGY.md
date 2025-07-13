# RMNpy Distribution Strategy

## Current Issue
The repository currently includes ~2.2MB of header files and static libraries from OCTypes, SITypes, and RMNLib. This is not ideal for several reasons:

## Problems with Current Approach
1. **Repository Bloat**: 37 header files + 3 static libraries
2. **Licensing**: Redistributing headers may violate licensing terms
3. **Version Lock**: Headers are tied to specific library versions
4. **Maintenance**: Headers must be manually updated

## Recommended Solutions

### Option 1: System Dependencies (Recommended)
Remove headers/libraries from repo and require system installation:

```bash
# Users install dependencies first:
sudo apt-get install librmnlib-dev liboctypes-dev libsitypes-dev  # Ubuntu
brew install rmnlib octypes sitypes                              # macOS
```

**Pros**: Clean repo, proper dependency management, no licensing issues
**Cons**: Users must install dependencies separately

### Option 2: Package Manager Integration
Use conda-forge or similar to distribute compiled packages:

```yaml
# conda recipe
requirements:
  build:
    - {{ compiler('c') }}
    - cython
    - numpy
  host:
    - octypes
    - sitypes 
    - rmnlib
  run:
    - numpy
```

**Pros**: Automatic dependency resolution, binary distribution
**Cons**: Requires package manager setup

### Option 3: Submodules (If Open Source)
If libraries are open source, use git submodules:

```bash
git submodule add https://github.com/org/OCTypes.git deps/OCTypes
git submodule add https://github.com/org/SITypes.git deps/SITypes
git submodule add https://github.com/org/RMNLib.git deps/RMNLib
```

**Pros**: Version controlled, no binary storage
**Cons**: Requires libraries to be open source

### Option 4: Header-Only Distribution
Include only the minimal headers needed for compilation:

```
include/
├── rmnlib_minimal.h     # Only essential declarations
├── octypes_minimal.h    # Only what's used by RMNpy
└── sitypes_minimal.h    # Only what's used by RMNpy
```

**Pros**: Smaller footprint, focused interface
**Cons**: May break with library updates

## Recommendation

**Use Option 1 (System Dependencies)** because:
- ✅ Clean repository
- ✅ Proper dependency management
- ✅ No licensing issues
- ✅ Standard practice for Python C extensions
- ✅ Users control library versions

Update `build_deps.py` to find system-installed libraries instead of copying them.
