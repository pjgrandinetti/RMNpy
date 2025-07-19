# RMNpy Documentation Updates - Scientific Examples Implementation

## Summary of Changes

This document summarizes the comprehensive updates made to RMNpy documentation and examples to align with RMNLib C API patterns and provide scientifically realistic examples.

## Files Updated

### 1. Core Examples (`examples/`)

#### `basic_usage.py` - Major Overhaul
- **Before**: Simple test data `[1.0, 2.0, 3.0, 4.0, 5.0]`
- **After**: Complex NMR data generation with damped oscillations
- **Key Improvements**:
  - Complex data: `amplitude * (cos(phase) + 1j * sin(phase))`
  - Physical parameters: 100 Hz frequency, 50 s⁻¹ decay rate
  - 1024 data points with 1 µs sampling interval
  - Proper physical quantity constants (`kSIQuantityTime`, `kSIQuantityFrequency`)
  - String expressions for units (`"1.0 µs"`)

#### `t1_inversion_recovery.py` - New File
- **Purpose**: Demonstrates T1 relaxation measurement
- **Scientific Accuracy**: Matches RMNLib C API monotonic dimension example
- **Key Features**:
  - Non-uniform time sampling over 6 orders of magnitude
  - Time points: 10 µs to 10 s (13 logarithmically spaced points)
  - T1 recovery equation: `M(t) = M0 * (1 - 2 * exp(-t/T1))`
  - Realistic T1 = 500 ms relaxation time
  - Complete analysis and export workflow

### 2. Documentation (`docs/`)

#### `examples/basic_usage.rst` - Complete Rewrite
- **Before**: Simple frequency dimension with 50 Hz increment
- **After**: Complete NMR workflow with complex data generation
- **Additions**:
  - Complex NMR data generation section
  - Scientific dimension creation with physical quantities
  - T1 inversion recovery example
  - Proper unit handling examples

#### `quickstart.rst` - Scientific Focus
- **Before**: Generic dimension examples
- **After**: Scientific dimension examples with proper context
- **Improvements**:
  - NMR acquisition time axis example
  - Treatment condition labels (realistic experimental design)
  - T1 recovery time points (6 orders of magnitude)
  - Physical quantity constants usage

#### `index.rst` - Scientific Emphasis
- **Before**: Basic programming examples
- **After**: Leading with scientific examples
- **Structure**:
  - Scientific example first (complex NMR data)
  - Basic usage second (for simple cases)
  - Emphasis on spectroscopy and signal processing applications

### 3. Main Documentation (`README.md`)

#### Quick Start Section - Complete Replacement
- **Before**: Simple dimension with basic data
- **After**: Complex NMR experiment workflow
- **Features**:
  - Damped oscillation generation
  - Physical quantity handling
  - Complete dataset creation
  - Scientific context explanation

## Scientific Accuracy Improvements

### 1. Data Generation Patterns
- **RMNLib Pattern**: Complex oscillating data with exponential decay
- **RMNpy Implementation**: Exact mathematical match
- **Formula**: `amplitude * exp(-decay_rate * time) * (cos(2πft) + i*sin(2πft))`

### 2. Physical Quantities
- **RMNLib Pattern**: Explicit quantity constants (`kSIQuantityTime`)
- **RMNpy Implementation**: Python constants (`kSIQuantityTime`)
- **Usage**: Proper dimensionality checking and unit handling

### 3. Time Sampling
- **RMNLib Pattern**: String expressions (`"1.0 µs"`, `"10.0 ms"`)
- **RMNpy Implementation**: Identical string expression handling
- **Advantage**: Precise unit specification without floating-point precision issues

### 4. Experimental Design
- **RMNLib Pattern**: Realistic experimental parameters
- **RMNpy Implementation**: Matching parameters and workflows
- **Examples**: T1 recovery times, NMR frequencies, decay constants

## API Consistency Achievements

### 1. Creation Patterns
```c
// RMNLib C API
DependentVariableRef depVar = DependentVariableCreateMinimal(
    voltUnit,                    // unit (required)
    kSIQuantityElectricPotential, // quantityName (required)
    STR("scalar"),               // quantityType (required)
    kOCNumberComplex128Type,     // numericType (required)
    components,                  // components (required)
    &error);                     // outError
```

```python
# RMNpy Python API
signal_var = DependentVariable.create(
    data=complex_data,           # data (required)
    units="V",                   # units (required)
    quantity_name=kSIQuantityElectricPotential,  # quantity_name (required)
    quantity_type="scalar",      # quantity_type (required)
    element_type="complex128",   # element_type (required)
    name="nmr_signal",          # optional
    description="Complex signal" # optional
)
```

### 2. Data Handling
- **C API**: Direct memory management with complex data types
- **Python API**: NumPy arrays with proper dtype handling
- **Consistency**: Same mathematical operations, same physical meaning

### 3. Error Handling
- **C API**: `OCStringRef *outError` pattern
- **Python API**: Exception hierarchy (`RMNError`, `RMNLibraryError`)
- **Mapping**: Consistent error reporting and debugging information

## Educational Value Improvements

### 1. Learning Progression
1. **Scientific Context First**: Lead with realistic examples
2. **Conceptual Understanding**: Explain physical meaning
3. **Implementation Details**: Show how to implement
4. **Advanced Topics**: T1 recovery, 2D NMR, etc.

### 2. Cross-Reference Benefits
- Users can learn C API concepts through Python examples
- Python users understand the underlying scientific library
- Consistent terminology between C and Python documentation

### 3. Real-World Relevance
- Examples based on actual NMR/ESR experiments
- Realistic parameter ranges and data sizes
- Complete workflows from data generation to analysis

## Impact Summary

### For RMNpy Users
- **Better Learning Curve**: Scientific examples provide context
- **Realistic Expectations**: Examples show real-world complexity
- **Proper Usage**: Correct physical quantity handling from the start

### For RMNLib Users
- **Python Migration Path**: Clear mapping between C and Python APIs
- **Validation**: Python examples validate C API design
- **Documentation Consistency**: Unified approach across libraries

### For Scientific Community
- **Reproducible Examples**: Same mathematical formulations
- **Standard Compliance**: Proper CSDM implementation
- **Best Practices**: Correct unit handling and data structure usage

## Next Steps

1. **Example Expansion**: Add more spectroscopy techniques (2D NMR, EPR, etc.)
2. **Data Analysis**: Include fitting routines and visualization
3. **Export Functionality**: Implement CSDM file export matching C API
4. **Performance Benchmarks**: Compare Python wrapper performance to C library
5. **Integration Tests**: Ensure Python examples work with actual RMNLib builds

## Conclusion

These updates successfully align RMNpy documentation with RMNLib patterns while providing scientifically accurate and educationally valuable examples. The changes maintain the Pythonic interface while respecting the underlying C library's design philosophy and scientific accuracy requirements.
