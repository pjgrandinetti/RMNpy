# RMNpy/RMNLib Documentation Examples Consistency Analysis

## Summary of Findings

After analyzing the documentation examples in both RMNpy (Python wrapper) and RMNLib (C library), I found several areas where the examples should be more consistent to provide a better user experience and clearer mapping between the C API and Python wrapper.

## Key Inconsistencies Found

### 1. **Dataset Creation Examples**

**RMNLib Pattern (C):**
```c
// Complex NMR/ESR data with damped oscillation
OCIndex count = 1024;
double complex *values = malloc(count * sizeof(double complex));
double frequency = 100.0;    // Hz
double decayRate = 50.0;     // s⁻¹ (decay constant)

for (int i = 0; i < count; i++) {
    double time = i * 1.0e-6;  // 1 µs sampling interval
    double amplitude = exp(-decayRate * time);
    double phase = 2.0 * M_PI * frequency * time;
    values[i] = amplitude * (cos(phase) + I * sin(phase));
}
```

**RMNpy Pattern (Current):**
```python
# Simple test data
test_data = np.array([1.0, 2.0, 3.0, 4.0, 5.0], dtype=np.float64)
```

**Recommended RMNpy Pattern:**
```python
# Complex NMR/ESR data with damped oscillation (matching RMNLib)
import numpy as np

count = 1024
frequency = 100.0    # Hz
decay_rate = 50.0    # s⁻¹ (decay constant)

# Generate damped complex oscillation data
time_axis = np.arange(count) * 1.0e-6  # 1 µs sampling interval
amplitude = np.exp(-decay_rate * time_axis)
phase = 2.0 * np.pi * frequency * time_axis
complex_data = amplitude * (np.cos(phase) + 1j * np.sin(phase))
```

### 2. **Dimension Creation Examples**

**RMNLib Pattern (C):**
```c
SIScalarRef increment = SIScalarCreateFromExpression(STR("1.0 µs"), &error);
SILinearDimensionRef timeDim = SILinearDimensionCreateMinimal(
    kSIQuantityTime,  // quantityName
    count,            // count  
    increment,        // increment
    freqDim,          // reciprocal
    &error);          // outError
```

**RMNpy Pattern (Current):**
```python
frequency_dim = LinearDimension.create(
    label="frequency",
    count=512,
    increment=50.0,
    unit="Hz",
    origin=0.0
)
```

**Recommended RMNpy Pattern:**
```python
# Match the C API more closely
time_dim = rmnpy.Dimension.create_linear(
    label="time",
    count=1024,
    increment="1.0 µs",    # String expression like C API
    quantity_name="time",   # Explicit quantity name
    reciprocal=freq_dim     # Include reciprocal relationship
)
```

### 3. **Physical Units and Quantities**

**RMNLib Pattern (C):**
- Uses kSIQuantityTime, kSIQuantityFrequency, kSIQuantityElectricPotential
- String expressions: "1.0 µs", "V", "dimensionless"
- Explicit quantity names for dimensionality

**RMNpy Pattern (Current):**
- Uses simple strings: "Hz", "V" 
- Lacks explicit quantity name mapping

**Recommended RMNpy Improvement:**
```python
from rmnpy.sitypes import (
    kSIQuantityTime, kSIQuantityFrequency
)

# Use explicit quantity constants like C API
time_dim = rmnpy.Dimension.create_linear(
    quantity_name=kSIQuantityTime,  # Match C API kSIQuantityTime
    increment="1.0 µs",
    count=1024
)
```

### 4. **Monotonic Dimension Examples**

**RMNLib Pattern (C):**
```c
// T1 inversion recovery with non-uniform time spacing
OCStringRef timeExpressions[] = {
    STR("10.0 µs"), STR("50.0 µs"), STR("100.0 µs"), STR("500.0 µs")
};
```

**RMNpy Pattern (Current):**
```python
time_points = ["0.0 s", "0.1 s", "0.25 s", "0.5 s", "1.0 s", "2.0 s", "5.0 s", "10.0 s"]
```

**Recommended RMNpy Pattern:**
```python
# Match the T1 inversion recovery example from RMNLib
recovery_times = [
    "10.0 µs", "50.0 µs", "100.0 µs", "500.0 µs",
    "1.0 ms", "5.0 ms", "10.0 ms", "50.0 ms", 
    "100.0 ms", "500.0 ms", "1.0 s", "5.0 s", "10.0 s"
]

t1_recovery_dim = rmnpy.Dimension.create_monotonic(
    coordinates=recovery_times,
    label="recovery_time",
    quantity_name=kSIQuantityTime,
    description="T1 inversion recovery time points"
)
```

### 5. **Dataset Export Examples**

**RMNLib Pattern (C):**
```c
bool success = DatasetExport(
    dataset,              // ds
    "experiment.csdf",    // json_path
    NULL,                 // binary_dir (auto-determined)
    &error);              // outError
```

**RMNpy Pattern (Missing):**
```python
# Should add CSDM export capability
dataset.export("experiment.csdf")  # Should match C API functionality
```

## Specific Example Improvements Needed

### 1. Update `basic_usage.py` to match RMNLib complexity
### 2. Add T1 inversion recovery example in RMNpy
### 3. Include complex data generation examples  
### 4. Add CSDM file export examples
### 5. Use consistent physical quantity naming

## Recommended Actions

1. **Align Examples**: Update RMNpy examples to use similar data patterns as RMNLib
2. **Add Scientific Context**: Include NMR/ESR-specific examples that demonstrate real scientific use cases
3. **Consistent API**: Ensure Python API examples show the same conceptual operations as C API
4. **Documentation Sync**: Cross-reference examples between RMNpy and RMNLib docs
5. **Physical Units**: Standardize on string expressions for physical quantities

This will provide users with a clearer path from C library concepts to Python wrapper usage.
