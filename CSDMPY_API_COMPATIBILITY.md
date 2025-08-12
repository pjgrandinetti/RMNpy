# CSDMPY Dimension API Compatibility

This document tracks RMNpy dimension compatibility with the csdmpy API.

## Current Status

Based on testing against csdmpy's test suite, here are the compatibility gaps:

### Missing Properties
- `size` - should alias to `count`
- `data_structure` - JSON serialization of dimension

### Missing Methods
- `__eq__(other)` - equality comparison
- `__mul__(other)` - dimension scaling
- `copy_metadata(obj)` - copy metadata from another dimension

### Issues Found
1. **Period Setting**: Period property appears read-only but should be settable
2. **Origin Offset Type**: Returns float instead of Scalar object (impacts API consistency)
3. **Equality**: Dimensions cannot be compared with `==` operator

## Implementation Plan

### Phase 1 (Essential) - Solutions Identified

1. **Add `size` property**
   - **Solution**: Simple alias to `count` property
   - **Implementation**: `@property def size(self): return self.count`

2. **Implement `__eq__` method**
   - **Solution**: Use OCTypes C API `OCTypeEqual()` function
   - **Implementation**: Call C API to compare dimension objects properly
   - **Benefit**: Leverages existing C comparison logic

3. **Fix period property setter**
   - **Solution**: Use SIDimension C API for setting period
   - **Implementation**: Ensure period setter calls appropriate C API function
   - **Note**: C API already supports period setting

4. **Ensure origin_offset returns Scalar**
   - **Solution**: Return Scalar object consistently, not float
   - **Test Impact**: Tests expecting float values will need `.value` access

5. **Add `data_structure` property**
   - **Solution**: Use C API `CopyAsDictionary` method for dimension serialization
   - **Implementation**: Call C API method and format as JSON string
   - **Benefit**: Leverages native C serialization logic for consistency

### Phase 2 (Nice to have)
1. **Add arithmetic operators (`__mul__`, `__truediv__`)**
   - **Solution**: Use existing C API multiplication functions:
     - `SILinearDimensionMultiplyByScalar()` - in-place scaling
     - `SILinearDimensionCreateByMultiplyingByScalar()` - creates new scaled dimension
     - `SIMonotonicDimensionMultiplyByScalar()` - in-place scaling
     - `SIMonotonicDimensionCreateByMultiplyingByScalar()` - creates new scaled dimension
   - **Implementation**: Wrap C API calls for `__mul__`, `__imul__`, `__truediv__`, etc.
   - **Benefit**: Proper handling of all dimension properties (increment, coordinates, period, reciprocal)

2. **Add `copy_metadata()` method**
   - **Solution**: Copy label, description, and application properties
   - **Implementation**: Simple property copying between dimension objects

3. **Maintain Scalar consistency**
   - **Solution**: All coordinate-related properties return Scalar objects
   - **Test Strategy**: Update tests to use `.value` when float comparison needed

## Technical Notes

- **OCTypes Integration**: All RMNLib dimension types inherit from OCTypes, enabling use of `OCTypeEqual()` for robust comparison
- **C API Leverage**: Existing C APIs already support the required functionality (period setting, comparison, coordinate operations)
- **API Consistency**: Maintaining Scalar return types ensures consistent object-oriented API design
- **Backward Compatibility**: Changes are additive and don't break existing functionality

## Test Results

Our dimensions currently pass basic functionality tests but fail on:
- Missing `size` attribute
- Cannot set period values
- No equality comparison
- Missing JSON serialization

*Last Updated: August 12, 2025*
