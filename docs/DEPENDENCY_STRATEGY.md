# RMNpy Dependency Strategy

## Current Status: Bundled Dependencies (Working) ✅

**Decision: Continue using bundled headers and libraries for stability**

### Why Bundled Dependencies Work Better:
1. **Proven Stability**: The bundled approach successfully builds and installs
2. **No Path Dependencies**: Avoids complex workspace setup requirements  
3. **Self-Contained**: RMNpy includes everything needed to build
4. **Cross-Platform**: Works consistently across different environments

### Current Implementation Status:
- ✅ **Build System**: Successfully compiles with bundled dependencies
- ✅ **Installation**: `pip install -e .` works without external setup
- ⚠️ **Runtime Stability**: Some hanging issues in comprehensive tests (investigation needed)
- ✅ **Basic Functionality**: Import and simple operations work

### Workspace Dependencies Investigation Results:
- ❌ **Missing Libraries**: RMNLib and SITypes don't have complete install/ directories
- ❌ **Build Failures**: Workspace-relative paths caused linker errors
- ❌ **Complexity**: Would require users to build all dependencies first

### Current Bundled Implementation

```
RMNpy/                       # Self-contained Python wrapper
├── src/rmnpy/              # Python/Cython source
├── include/                # Bundled headers
│   ├── OCTypes/           # From OCTypes repository  
│   ├── SITypes/           # From SITypes repository
│   └── RMNLib/            # From RMNLib repository
├── lib/                   # Bundled libraries
│   ├── libOCTypes.a      # Compiled OCTypes
│   ├── libSITypes.a      # Compiled SITypes  
│   └── libRMN.a       # Compiled RMNLib
├── setup.py              # Points to bundled include/ and lib/
└── build_deps.py         # Verifies bundled dependencies
```

### Current Status

- ✅ **Build System**: Successfully compiles with bundled dependencies
- ✅ **Installation**: `pip install -e .` works without external setup
- ⚠️ **Runtime Stability**: Some hanging issues in comprehensive tests (needs investigation)
- ✅ **Basic Functionality**: Import and simple operations work

### Next Steps

1. **Debug Runtime Issues**: Investigate hanging behavior in comprehensive tests
2. **Memory Management**: Review Cython memory management for edge cases
3. **Test Suite**: Ensure all test cases run without hanging
4. **Documentation**: Update README to reflect bundled dependency approach

### Future Migration Path:

**Phase 1 (Current)**: Bundled dependencies
- Keep current setup for development and early adopters
- Add clear documentation about bundled dependencies

**Phase 2 (Future)**: Package manager distribution
- When stable, create conda packages with proper dependency chains
- Provide wheels for common platforms (no compilation needed)

**Phase 3 (Mature)**: System dependencies
- When widely adopted, move to system-installed dependencies
- Keep bundled option for development builds

## Implementation Notes:

### .gitignore Strategy:
```gitignore
# Keep dependencies but ignore build artifacts
# include/     # KEEP - needed for building
# lib/         # KEEP - needed for building

# Ignore generated files only
src/rmnpy/*.c
build/
dist/
*.egg-info/
```

### Documentation:
Make it clear that dependencies are bundled:
```markdown
## Dependencies
RMNpy includes the required C libraries (OCTypes, SITypes, RMNLib) 
for easy building. No separate installation required.
```

### Licensing:
- Verify redistribution rights for bundled libraries
- Include appropriate license notices
- Consider fair use for academic/research purposes

## Conclusion:
**Keep the current approach** - it's appropriate for a specialized scientific library in active development. The 2.2MB overhead is acceptable for the convenience it provides to the scientific community.
