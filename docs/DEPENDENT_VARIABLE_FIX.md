# DependentVariable.create() Parameter Requirements - Fix Summary

## Issue Identified

The user correctly pointed out that our `DependentVariable.create()` calls were missing required parameters that match the C API `DependentVariableCreateMinimal()` function signature:

```c
DependentVariableRef depVar = DependentVariableCreateMinimal(
    voltUnit,                    // unit (required)
    kSIQuantityElectricPotential, // quantityName (required)
    STR("scalar"),               // quantityType (required)
    kOCNumberComplex128Type,     // numericType (required)
    components,                  // components (required)
    &error);                     // outError
```

## Changes Made

### 1. Added Missing Quantity Constant
- **Added**: `kSIQuantityElectricPotential = "electric_potential"` to sitypes module
- **Updated**: `__all__` export list to include the new constant

### 2. Fixed All DependentVariable.create() Calls

#### Before (Incomplete):
```python
signal_var = DependentVariable.create(
    name="nmr_signal",
    description="Complex NMR signal with T2 decay",
    unit="V",  # Wrong parameter name
    data=complex_data
)
```

#### After (Complete):
```python
signal_var = DependentVariable.create(
    data=complex_data,           # Required: data first
    name="nmr_signal",
    description="Complex NMR signal with T2 decay",
    units="V",                   # Fixed parameter name
    quantity_name=kSIQuantityElectricPotential,  # Required
    quantity_type="scalar",      # Required
    element_type="complex128"    # Required
)
```

### 3. Updated Files

#### Core Examples:
- `examples/basic_usage.py` - Fixed 4 DependentVariable.create() calls
- `examples/t1_inversion_recovery.py` - Fixed 1 DependentVariable.create() call

#### Documentation:
- `README.md` - Updated quick start example
- `docs/examples/basic_usage.rst` - Fixed example with proper parameters
- `docs/SCIENTIFIC_EXAMPLES_IMPLEMENTATION.md` - Updated API comparison

#### Constants Module:
- `src/rmnpy/sitypes/__init__.py` - Added kSIQuantityElectricPotential

## Required Parameters Summary

Based on C API requirements, `DependentVariable.create()` now correctly requires:

1. **data** - The actual data array (corresponds to `components` in C API)
2. **units** - SI unit string (corresponds to `unit` in C API)
3. **quantity_name** - Physical quantity constant (corresponds to `quantityName`)
4. **quantity_type** - Semantic type like "scalar" (corresponds to `quantityType`)
5. **element_type** - Data type like "complex128" (corresponds to `numericType`)

Optional parameters include `name`, `description`, etc.

## Validation

```bash
$ python -c "from rmnpy.sitypes import kSIQuantityElectricPotential; print(kSIQuantityElectricPotential)"
electric_potential
```

All examples now provide the complete set of required parameters matching the C API signature.
