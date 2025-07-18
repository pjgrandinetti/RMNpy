# RMNpy Source Code Cleanup and Reorganization Plan

## Current State Analysis

### Issues Identified:
1. **Import Failures**: Constants not properly exposed from Cython modules
2. **Duplicated Code**: Both `siscalar.pyx` and `sitypes/scalar.pyx` exist
3. **Incomplete Migrations**: Mixed old/new API patterns
4. **Build Artifacts**: `.c` and `.so` files polluting source directory
5. **Over-Engineering**: Complex constant wrapper attempts that don't work
6. **Inconsistent Structure**: Some modules in root, some in sitypes/

### Working Components:
- ✅ Core RMNLib wrappers (Dataset, Dimension, etc.) - architecture sound
- ✅ Build system (Cython compilation works)
- ✅ Basic SIScalar functionality (when imports work)
- ✅ SIDimensionality core functionality (when not over-engineered)

## Proposed Cleanup Strategy

### Phase 1: Reset and Simplify (Immediate)

#### 1.1 Remove Build Artifacts
```bash
# Clean all generated files
find src/ -name "*.c" -delete
find src/ -name "*.so" -delete
find src/ -name "*.html" -delete
find src/ -name "__pycache__" -type d -exec rm -rf {} +
```

#### 1.2 Consolidate SIScalar Implementation
- **Decision**: Keep `sitypes/scalar.pyx` as primary implementation
- **Action**: Remove `siscalar.pyx` (root level) - it's redundant
- **Rationale**: sitypes/ structure aligns with architecture plan

#### 1.3 Simplify SIDimensionality
- **Remove**: Complex constant wrapper attempts that don't work
- **Keep**: Core functionality (parse_expression, arithmetic operations)
- **Simplify**: Export only basic working functionality initially

#### 1.4 Fix Import Structure
- **Verify**: Each module properly exports what it claims
- **Test**: Import chain works at each level
- **Document**: Clear import paths

### Phase 2: Stabilize Foundation (Next)

#### 2.1 Minimal Working SITypes Module
```python
# sitypes/__init__.py - Ultra-minimal until we get basics working
from .scalar import SIScalar
from .dimensionality import SIDimensionality

__all__ = ["SIScalar", "SIDimensionality"]
```

#### 2.2 Core RMNLib Stability
- **Verify**: All core wrappers (Dataset, Dimension, etc.) still work
- **Test**: Basic functionality of each wrapper
- **Document**: Known working features

#### 2.3 Build System Validation
- **Clean**: Remove all build artifacts
- **Rebuild**: Full clean build
- **Test**: Import chain works completely

### Phase 3: Incremental Enhancement (Future)

#### 3.1 SIDimensionality Enhancement
- Add back constants **one at a time** with proper testing
- Focus on most commonly used quantities first
- Test each addition before moving to next

#### 3.2 SIUnit Implementation
- Only after SIDimensionality is completely stable
- Follow architecture plan Phase 2

#### 3.3 Enhanced SIScalar
- Integration with SIUnit and SIDimensionality
- Follow architecture plan Phase 3

## Immediate Action Items

### Step 1: Emergency Cleanup (Now)
1. **Remove duplicates**: Delete `siscalar.pyx` from root
2. **Remove build artifacts**: Clean all `.c`, `.so`, `__pycache__`
3. **Simplify imports**: Minimal working imports only
4. **Test basic build**: Ensure `import rmnpy` works

### Step 2: Stabilize Imports (Next)
1. **Fix sitypes imports**: Remove broken constant imports
2. **Verify core imports**: Ensure Dataset, Dimension, etc. work
3. **Test incrementally**: Each module imports independently

### Step 3: Document Working State (Then)
1. **Test all working functionality**: What actually works now?
2. **Document API**: Clear documentation of current capabilities
3. **Update architecture plan**: Based on actual working state

## Files to Modify/Remove

### Remove (Cleanup):
- `src/rmnpy/siscalar.pyx` (duplicate of sitypes/scalar.pyx)
- `src/rmnpy/siscalar.pxd` (duplicate)
- `src/rmnpy/siscalar.c` (build artifact)
- `src/rmnpy/siscalar.cpython-312-darwin.so` (build artifact)
- `src/rmnpy/sitypes/dimensionality_fixed.pyx` (incomplete attempt)
- All `.c` files (build artifacts)
- All `.so` files (build artifacts)
- All `__pycache__` directories

### Simplify (Reduce complexity):
- `src/rmnpy/sitypes/dimensionality.pyx` - Remove complex constant wrapper
- `src/rmnpy/sitypes/__init__.py` - Minimal imports only
- `src/rmnpy/core.pxd` - Remove unused constant declarations initially

### Keep (Working foundation):
- `src/rmnpy/core.pyx` - Core RMNLib wrappers
- `src/rmnpy/dataset.pyx` - Dataset wrapper
- `src/rmnpy/dimension.pyx` - Dimension wrapper
- `src/rmnpy/sitypes/scalar.pyx` - SIScalar implementation
- `src/rmnpy/sitypes/dimensionality.pyx` - Core SIDimensionality (simplified)

## Success Criteria

### Phase 1 Success (Immediate):
- [ ] `import rmnpy` works without errors
- [ ] `from rmnpy import Dataset` works
- [ ] `from rmnpy.sitypes import SIScalar` works
- [ ] Basic Dataset creation works
- [ ] Basic SIScalar creation works

### Phase 2 Success (Next):
- [ ] All core RMNLib functionality works as before
- [ ] SIDimensionality basic operations work
- [ ] Documentation reflects actual working capabilities
- [ ] Test suite passes

### Phase 3 Success (Future):
- [ ] SIDimensionality with useful constants
- [ ] SIUnit implementation
- [ ] Enhanced SIScalar integration
- [ ] Full architecture plan implementation

## Risk Mitigation

1. **Backup Current State**: Before major changes
2. **Incremental Changes**: One file at a time
3. **Test After Each Change**: Verify imports still work
4. **Rollback Plan**: Keep working state easily recoverable

---

**Bottom Line**: The current state is over-engineered and broken. We need to step back, clean up, and build incrementally from a stable foundation.
