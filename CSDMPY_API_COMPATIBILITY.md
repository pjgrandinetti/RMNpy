# CSDMPY Dimension API Compatibility Plan

This document outlines the plan to make RMNpy dimension objects fully compatible with the csdmpy dimension API.

## Overview

The goal is to ensure that RMNpy dimensions can be used as drop-in replacements for csdmpy dimensions, maintaining full API compatibility while leveraging the performance benefits of the underlying RMNLib C API.

**Reference:** [csdmpy Dimension API](https://csdmpy.readthedocs.io/en/stable/_modules/csdmpy/dimension.html#Dimension)

## Status Legend
- ✅ **Already implemented** - Fully compatible
- ⚠️ **Partially implemented** - Exists but may need adjustments
- ❌ **Missing** - Needs to be implemented

---

## Core Properties (Required)

| Property | Status | Notes |
|----------|--------|-------|
| `type` | ✅ | Returns dimension subtype ('linear', 'monotonic', 'labeled') |
| `coordinates` | ✅ | Recently refactored to use C API dispatch |
| `coords` | ✅ | Alias for coordinates property |
| `absolute_coordinates` | ✅ | Recently refactored to use C API dispatch |
| `count` | ✅ | Number of coordinates along dimension |
| `description` | ✅ | Brief description string |
| `label` | ✅ | Label associated with dimension |
| `application` | ✅ | Application metadata dictionary |

---

## Quantitative Dimension Properties

### Linear & Monotonic Dimensions

| Property | Status | Applies To | Notes |
|----------|--------|------------|-------|
| `increment` | ✅ | Linear only | Constant spacing between coordinates |
| `coordinates_offset` | ✅ | All SI | Offset for coordinate calculation |
| `origin_offset` | ✅ | All SI | Origin offset for absolute coordinates |
| `period` | ✅ | All SI | Period for periodic dimensions |
| `quantity_name` | ✅ | All SI | Physical quantity name |
| `complex_fft` | ✅ | Linear only | FFT ordering flag |
| `axis_label` | ✅ | All | Formatted label for axes - **Recently fixed to use C API properly** |

### Labeled Dimensions

| Property | Status | Notes |
|----------|--------|-------|
| `labels` | ✅ | List of category labels |
| `coordinate_labels` | ✅ | Internal property name |

---

## Methods (Core API)

### Currently Implemented

| Method | Status | Description |
|--------|--------|-------------|
| `dict()` | ✅ | Alias for `to_dict()` |
| `to_dict()` | ✅ | Convert to Python dictionary |
| `copy()` | ✅ | Create deep copy of dimension |
| `is_quantitative()` | ✅ | Check if dimension is quantitative |

### Missing Methods (Priority 1)

| Method | Status | Description | Implementation Notes |
|--------|--------|-------------|---------------------|
| `copy_metadata(obj)` | ❌ | Copy metadata from another dimension | Copy label, description, application |
| `reciprocal_coordinates()` | ❌ | Get reciprocal coordinates | Use Nyquist-Shannon theorem |
| `reciprocal_increment()` | ✅ | Get reciprocal increment | **RMNpy correct, csdmpy has bug!** Uses proper C API |

### Missing Methods (Priority 2)

| Method | Status | Description | Implementation Notes |
|--------|--------|-------------|---------------------|
| `to(unit, equivalencies, update_attrs)` | ❌ | Unit conversion | Requires units library integration |

---

## Special Properties (Read-only)

| Property | Status | Description | Implementation Notes |
|----------|--------|-------------|---------------------|
| `data_structure` | ❌ | JSON serialized view | Use `json.dumps(self.to_dict(), indent=2)` |
| `size` | ❌ | Alias for `count` | Simple property returning `self.count` |
| `reciprocal` | ⚠️ | ReciprocalDimension object | May need separate class |

---

## Magic Methods (Operators)

### Comparison Operators

| Method | Status | Description |
|--------|--------|-------------|
| `__eq__(other)` | ❌ | Equality comparison |
| `__repr__()` | ✅ | String representation |
| `__str__()` | ⚠️ | May need adjustment |

### Arithmetic Operators

| Method | Status | Description | Notes |
|--------|--------|-------------|-------|
| `__mul__(other)` | ❌ | Right multiplication | Scale coordinates |
| `__rmul__(other)` | ❌ | Left multiplication | Scale coordinates |
| `__imul__(other)` | ❌ | In-place multiplication | Scale coordinates |
| `__truediv__(other)` | ❌ | Division | Scale coordinates |
| `__itruediv__(other)` | ❌ | In-place division | Scale coordinates |

### Indexing

| Method | Status | Description | Notes |
|--------|--------|-------------|-------|
| `__getitem__(indices)` | ❌ | Subscript access | Return new dimension with subset |

---

## Implementation Plan

### Phase 1: Essential Missing Methods
**Target: Next release**

1. **Add `copy_metadata(obj)` method**
   ```python
   def copy_metadata(self, obj):
       """Copy metadata from another dimension object."""
       self.label = getattr(obj, 'label', '')
       self.description = getattr(obj, 'description', '')
       self.application = getattr(obj, 'application', None)
   ```

2. **Add `size` property**
   ```python
   @property
   def size(self):
       """Return the dimension count (alias for count)."""
       return self.count
   ```

3. **Add `data_structure` property**
   ```python
   @property
   def data_structure(self):
       """JSON serialized string of dimension object."""
       import json
       return json.dumps(self.to_dict(), indent=2)
   ```

4. **Add `reciprocal_coordinates()` method**
   - Implement Nyquist-Shannon theorem calculations
   - Return reciprocal coordinate array

### Phase 2: Unit Conversion Support
**Target: Future release**

1. **Add `to(unit, equivalencies, update_attrs)` method**
   - Integrate with units library (astropy.units or pint)
   - Handle coordinate unit conversions
   - Update related attributes when units change

2. **Enhanced unit handling**
   - Ensure all properties return proper Quantity objects
   - Maintain unit consistency across operations

### Phase 3: Operators & Advanced Features
**Target: Future release**

1. **Comparison operators**
   ```python
   def __eq__(self, other):
       """Compare dimensions for equality."""
       # Compare type, coordinates, and metadata
   ```

2. **Arithmetic operators**
   ```python
   def __mul__(self, other):
       """Scale dimension by scalar."""
       # Return new dimension with scaled coordinates
   ```

3. **Indexing support**
   ```python
   def __getitem__(self, indices):
       """Return dimension subset."""
       # Return new dimension with subset of coordinates
   ```

### Phase 4: Advanced Features & Polish
**Target: Future release**

1. **ReciprocalDimension class**
   - Separate class for reciprocal dimension properties
   - Full reciprocal dimension support

2. **Enhanced error handling**
   - Match csdmpy exception types and messages
   - Comprehensive input validation

3. **Performance optimizations**
   - Cache expensive calculations
   - Optimize coordinate generation

---

## Testing Strategy

### Unit Tests
- **API Compatibility Tests**: Ensure all methods match csdmpy signatures
- **Property Tests**: Verify all properties return expected types
- **Edge Case Tests**: Handle invalid inputs gracefully

### Integration Tests
- **csdmpy Interoperability**: Test with existing csdmpy code
- **Performance Benchmarks**: Compare against pure Python implementations
- **Memory Management**: Verify proper C API resource cleanup

### Compatibility Tests
- **Drop-in Replacement**: Use RMNpy dimensions in csdmpy applications
- **Serialization**: Ensure dictionary output matches csdmpy format
- **Unit Conversion**: Test with various unit libraries

---

## Dependencies

### Required
- **RMNLib C API**: Core coordinate calculations
- **NumPy**: Array operations and compatibility
- **OCTypes/SITypes**: Memory management and scalar operations

### Optional (for full compatibility)
- **astropy.units** or **pint**: Unit conversion support
- **json**: Serialization for `data_structure` property

---

## Migration Notes

### For Users
- Existing RMNpy code should continue to work unchanged
- New csdmpy-compatible methods will be additive
- Performance improvements from C API will be transparent

### For Developers
- Maintain backward compatibility with existing API
- Follow csdmpy naming conventions for new methods
- Ensure proper memory management in C API calls

---

## Timeline

### Immediate (Phase 1)
- Essential missing methods: `copy_metadata`, `size`, `data_structure`
- Basic reciprocal coordinate support
- Target completion: Next minor release

### Short-term (Phase 2)
- Unit conversion system
- Enhanced property validation
- Target completion: Next major release

### Long-term (Phase 3-4)
- Full operator support
- Advanced reciprocal dimension features
- Comprehensive csdmpy compatibility
- Target completion: Future releases

---

## Success Criteria

1. **API Completeness**: All csdmpy dimension methods and properties implemented
2. **Drop-in Compatibility**: RMNpy dimensions work in existing csdmpy applications
3. **Performance**: C API provides measurable performance improvements
4. **Test Coverage**: >95% test coverage for all new functionality
5. **Documentation**: Complete API documentation matching csdmpy standards

---

*Last Updated: August 10, 2025*
*Status: Phase 1 Ready - Core functionality verified, build system fixed, C API integration completed*

## Recent Session Progress (August 10, 2025)

### ✅ **Major Fixes Completed:**
1. **Fixed `axis_label` C API Integration** - Now properly uses `DimensionCreateAxisLabel()` from RMNLib C API instead of manual implementation
2. **Fixed RMNLib Build System** - Updated Makefile to build both static (.a) and shared (.dylib) libraries by default
3. **Verified All Dimension Types** - Systematic testing confirmed all dimension types work correctly:
   - `LabeledDimension` ✅ (`axis_label` returns `'samples-N'` format)
   - `SIMonotonicDimension` ✅ (`axis_label` returns `'time-N/s'` format with units)
   - `SILinearDimension` ✅ (both string and Scalar increments work, `axis_label` returns `'frequency-N/Hz'` format)
   - `SIDimension` ✅ (base class functionality confirmed)

### ✅ **API Clarifications:**
- Confirmed Scalar API: `.unit` property returns `Unit` object with `.symbol`, `.dimensionality` returns `Dimensionality` object
- Verified unit handling: `Scalar("10.0 Hz")` vs `Scalar("10.0")` (dimensionless) work correctly in dimensions
- C API integration working properly with memory management (`OCRelease` and `ocstring_to_pystring` helper)

### **Ready for Phase 1 Implementation:**
Core infrastructure is now solid. Missing csdmpy compatibility methods can be implemented:
- `size` property (alias for `count`)
- `copy_metadata(obj)` method
- `data_structure` property (JSON serialization)
- `reciprocal_coordinates()` method
- `__eq__(other)` comparison operator
