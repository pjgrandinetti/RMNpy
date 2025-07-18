# Cython implementation for SITypes helper functions

from ..core cimport (
    SIScalarRef, SIUnitRef, SIDimensionalityRef, OCStringRef,
    SIScalarCreateWithDouble, SIScalarDoubleValueInCoherentUnit,
    OCRelease, OCRetain
)
from ..helpers cimport _py_to_ocstring, _ocstring_to_py
from ..exceptions import RMNLibValidationError, RMNLibMemoryError
from .scalar cimport _get_scalar_ref

cdef SIScalarRef py_to_siscalar_ref(object value_or_expression) except NULL:
    """Convert various Python types to SIScalarRef."""
    cdef SIScalarRef result = NULL
    
    if isinstance(value_or_expression, str):
        # Import here to avoid circular imports
        from .scalar import SIScalar
        # Use the from_expression method which handles simple "value unit" parsing
        try:
            scalar_obj = SIScalar.from_expression(value_or_expression)
            # Get the _ref using a helper function in scalar module
            result = _extract_scalar_ref(scalar_obj)
            if result != NULL:
                OCRetain(result)  # Caller owns the reference
            else:
                raise ValueError("Failed to create SIScalar from expression")
        except Exception as e:
            raise TypeError(f"Cannot convert string '{value_or_expression}' to SIScalar: {e}")
    elif hasattr(value_or_expression, '_ref'):  # Duck typing for SIScalar
        # Extract reference using helper function
        try:
            result = _extract_scalar_ref(value_or_expression)
            if result != NULL:
                OCRetain(result)  # Caller owns the reference
            else:
                raise ValueError("SIScalar object has NULL reference")
        except:
            raise TypeError("Object has _ref but reference extraction failed")
    elif isinstance(value_or_expression, (int, float)):
        # Create dimensionless scalar
        result = SIScalarCreateWithDouble(float(value_or_expression), NULL)
        if result == NULL:
            raise RMNLibMemoryError("Failed to create dimensionless SIScalar")
    else:
        raise TypeError(f"Cannot convert {type(value_or_expression)} to SIScalar")
    
    return result

# Helper function to extract SIScalarRef from Python object
cdef SIScalarRef _extract_scalar_ref(object scalar_obj):
    """Extract SIScalarRef from a Python SIScalar object."""
    # Use Python attribute access to get the capsule
    ref_capsule = getattr(scalar_obj, '_ref', None)
    if ref_capsule is None:
        return NULL
    
    # Use the proper extraction from the scalar module
    return _get_scalar_ref(scalar_obj)

cdef double siscalar_ref_to_py(SIScalarRef scalar_ref):
    """Convert SIScalarRef to Python float value."""
    if scalar_ref == NULL:
        return 0.0
    return SIScalarDoubleValueInCoherentUnit(scalar_ref)

cdef object siscalar_ref_to_string(SIScalarRef scalar_ref):
    """Convert SIScalarRef to string representation."""
    if scalar_ref == NULL:
        return "0.0"
    # TODO: Add proper string conversion with units
    # For now, just return the numeric value
    cdef double value = SIScalarDoubleValueInCoherentUnit(scalar_ref)
    return str(value)
