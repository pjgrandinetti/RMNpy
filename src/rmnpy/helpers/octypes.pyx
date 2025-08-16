# cython: language_level=3
# cython: nonecheck=False
# cython: boundscheck=False
# cython: wraparound=False
# distutils: define_macros=NPY_NO_DEPRECATED_API=NPY_1_7_API_VERSION
"""
OCTypes Helper Functions

This module provides conversion utilities between Python types and OCTypes C structures.
These helpers enable seamless integration between Python objects and the OCTypes library.
"""

from libc.stdint cimport (
    int8_t,
    int16_t,
    int32_t,
    int64_t,
    uint8_t,
    uint16_t,
    uint32_t,
    uint64_t,
    uintptr_t,
)
from libc.stdlib cimport free, malloc
from libc.string cimport memcpy

from rmnpy._c_api.octypes cimport *
from rmnpy._c_api.rmnlib cimport *
from rmnpy._c_api.sitypes cimport *

import cython
import numpy as np

# Import moved inside functions to avoid circular import
# from rmnpy.wrappers.sitypes.dimensionality import sidimensionality_to_dimensionality

# Comment out imports that create circular dependencies
# from rmnpy.wrappers.sitypes.scalar import (
#     siscalar_create_from_pyscalar,
#     siscalar_to_scalar,
# )
# from rmnpy.wrappers.sitypes.unit import siunit_to_pyunit

# Comment out to avoid circular imports - use lazy imports instead
# try:
#     from rmnpy.wrappers.sitypes.scalar import Scalar
#     SCALAR_AVAILABLE = True
#     SCALAR_CLASS = Scalar  # Keep reference for _from_c_ref calls
# except ImportError:
#     SCALAR_AVAILABLE = False
#     SCALAR_CLASS = None

# Import Unit class for proper SIUnit conversion
# try:
#     from rmnpy.wrappers.sitypes.unit import Unit
#     UNIT_AVAILABLE = True
#     UNIT_CLASS = Unit  # Keep reference for _from_c_ref calls
# except ImportError:
#     UNIT_AVAILABLE = False
#     UNIT_CLASS = None

# Import Dimensionality class for proper SIDimensionality conversion
# try:
#     from rmnpy.wrappers.sitypes.dimensionality import Dimensionality
#     DIMENSIONALITY_AVAILABLE = True
#     DIMENSIONALITY_CLASS = Dimensionality  # Keep reference for _from_c_ref calls
# except ImportError:
#     DIMENSIONALITY_AVAILABLE = False
#     DIMENSIONALITY_CLASS = None

# Set constants for availability flags
DIMENSION_AVAILABLE = False
DIMENSION_CLASSES = {}
SCALAR_AVAILABLE = False
UNIT_AVAILABLE = False
DIMENSIONALITY_AVAILABLE = False

# Import Dimension classes for proper RMNLib Dimension conversion
# try:
#     from rmnpy.wrappers.rmnlib.dimension import (
#         BaseDimension,
#         LabeledDimension,
#         SIDimension,
#         SILinearDimension,
#         SIMonotonicDimension,
#     )
#     DIMENSION_AVAILABLE = True
#     DIMENSION_CLASSES = {
#         'BaseDimension': BaseDimension,
#         'LabeledDimension': LabeledDimension,
#         'SIDimension': SIDimension,
#         'SILinearDimension': SILinearDimension,
#         'SIMonotonicDimension': SIMonotonicDimension,
#     }
# except ImportError:
#     DIMENSION_AVAILABLE = False
#     DIMENSION_CLASSES = {}

# ====================================================================================
# Internal Helper Functions
# ====================================================================================

cdef uint64_t convert_python_to_octype(object item) except 0:
    """
    Convert a Python object to an OCType pointer.

    This function handles:
    1. Existing OCType pointers (from SITypes or other extensions)
    2. Built-in Python types (str, int, float, complex, bool)
    3. NumPy arrays

    NOTE: Does not handle collections (list, dict, set) to avoid circular dependencies.

    Args:
        item: Python object to convert

    Returns:
        uint64_t: OCType pointer (caller must release)

    Raises:
        TypeError: If the item type cannot be converted
    """
    cdef uint64_t oc_ptr = 0

    if isinstance(item, str):
        return ocstring_create_from_pystring(item)
    elif isinstance(item, bool):  # Check bool before int (bool is subclass of int)
        return pybool_to_ocboolean(item)
    elif isinstance(item, (int, float, complex)):
        return ocnumber_create_from_pynumber(item)
    elif isinstance(item, np.ndarray):
        return ocdata_create_from_numpy_array(item)
    # Handle Scalar objects from RMNpy wrappers using duck typing
    # We use hasattr instead of isinstance for better Cython performance
    # and to avoid circular import issues with dynamically imported classes
    elif hasattr(item, 'value') and hasattr(item, 'unit'):
        # This looks like a Scalar object - convert to SIScalar
        from rmnpy.wrappers.sitypes.scalar import siscalar_create_from_pyscalar
        return siscalar_create_from_pyscalar(item)
    # Handle Unit objects from RMNpy wrappers using duck typing
    elif hasattr(item, '_c_ref') and hasattr(item, 'name'):
        # This looks like a Unit object - get the C reference directly
        return <uint64_t>(<object>item)._c_ref
    # Handle Dimensionality objects from RMNpy wrappers using duck typing
    elif hasattr(item, '_c_ref') and hasattr(item, 'dimensionality_string'):
        # This looks like a Dimensionality object - get the C reference directly
        return <uint64_t>(<object>item)._c_ref
    # Handle Dimension objects from RMNpy wrappers using duck typing
    elif hasattr(item, '_c_ref') and hasattr(item, 'count'):
        # This looks like a Dimension object - get the C reference directly
        return <uint64_t>(<object>item)._c_ref
    else:
        raise TypeError(f"Unsupported item type: {type(item)}. For collections, use specific conversion functions. For OCTypes from other libraries, pass as integer pointer.")

cdef object convert_octype_to_python(const void* oc_ptr):
    """
    Convert an OCType pointer to a Python object.

    This function handles:
    1. Known OCTypes (String, Number, Boolean, Data, Array, Dictionary, Set)
    2. Unknown OCTypes (returns as integer pointer for use by other libraries)

    Args:
        oc_ptr: OCType pointer to convert

    Returns:
        object: Python object or integer pointer for unknown types
    """
    if oc_ptr == NULL:
        return None

    cdef OCTypeID type_id = OCGetTypeID(oc_ptr)

    # Handle known OCTypes
    if type_id == OCStringGetTypeID():
        return ocstring_to_pystring(<uint64_t>oc_ptr)
    elif type_id == OCNumberGetTypeID():
        return ocnumber_to_pynumber(<uint64_t>oc_ptr)
    elif type_id == OCBooleanGetTypeID():
        return ocboolean_to_pybool(<uint64_t>oc_ptr)
    elif type_id == OCDataGetTypeID():
        # Default to uint8 array for OCData
        return ocdata_to_numpy_array(<uint64_t>oc_ptr, np.uint8)
    elif type_id == OCArrayGetTypeID():
        return ocarray_to_pylist(<uint64_t>oc_ptr)
    elif type_id == OCDictionaryGetTypeID():
        return ocdict_to_pydict(<uint64_t>oc_ptr)
    elif type_id == OCSetGetTypeID():
        return ocset_to_pyset(<uint64_t>oc_ptr)
    elif type_id == OCIndexArrayGetTypeID():
        return ocindexarray_to_pylist(<uint64_t>oc_ptr)
    elif type_id == OCIndexSetGetTypeID():
        return ocindexset_to_pyset(<uint64_t>oc_ptr)
    elif type_id == OCIndexPairSetGetTypeID():
        return ocindexpairset_to_pydict(<uint64_t>oc_ptr)
    elif type_id == SIScalarGetTypeID():
        from rmnpy.wrappers.sitypes.scalar import siscalar_to_scalar
        return siscalar_to_scalar(<uint64_t>oc_ptr)
    elif type_id == SIUnitGetTypeID():
        from rmnpy.wrappers.sitypes.unit import siunit_to_pyunit
        return siunit_to_pyunit(<uint64_t>oc_ptr)
    elif type_id == SIDimensionalityGetTypeID():
        # Use lazy import to avoid circular import
        from rmnpy.wrappers.sitypes.dimensionality import (
            sidimensionality_to_dimensionality,
        )
        return sidimensionality_to_dimensionality(<uint64_t>oc_ptr)
    # Handle RMNLib Dimension types
    elif type_id == DimensionGetTypeID():
        return dimension_to_pydimension(<uint64_t>oc_ptr)
    elif type_id == LabeledDimensionGetTypeID():
        return dimension_to_pydimension(<uint64_t>oc_ptr)
    elif type_id == SIDimensionGetTypeID():
        return dimension_to_pydimension(<uint64_t>oc_ptr)
    elif type_id == SILinearDimensionGetTypeID():
        return dimension_to_pydimension(<uint64_t>oc_ptr)
    elif type_id == SIMonotonicDimensionGetTypeID():
        return dimension_to_pydimension(<uint64_t>oc_ptr)
    else:
        # Unknown OCType (could be from SITypes or other extensions)
        # Return as integer pointer for use by other libraries
        return <uint64_t>oc_ptr

# ====================================================================================
# String Helper Functions
# ====================================================================================

def ocstring_create_from_pystring(py_string):
    """
    Convert a Python string to an OCStringRef.

    Args:
        py_string (str or None): Python string to convert, or None

    Returns:
        uint64_t: OCTypes string reference (needs to be released), or 0 if py_string is None

    Raises:
        RuntimeError: If string creation fails
        TypeError: If input is not str or None
    """
    if py_string is None:
        return 0  # Return NULL pointer as uint64_t for None

    if not isinstance(py_string, str):
        raise TypeError(f"Expected str or None, got {type(py_string)}")

    cdef bytes utf8_bytes = py_string.encode('utf-8')
    cdef const char* c_string = utf8_bytes

    cdef OCStringRef oc_string = OCStringCreateWithCString(c_string)
    if oc_string == NULL:
        raise RuntimeError(f"Failed to create OCString from: {py_string}")

    return <uint64_t>oc_string

def ocstring_to_pystring(uint64_t oc_string_ptr):
    """
    Convert an OCStringRef to a Python string.

    Args:
        oc_string_ptr (uint64_t): Pointer to OCStringRef

    Returns:
        str: Python string

    Raises:
        ValueError: If the OCStringRef is NULL
    """
    cdef OCStringRef oc_string = <OCStringRef>oc_string_ptr
    if oc_string == NULL:
        raise ValueError("OCStringRef is NULL")

    cdef const char* c_string = OCStringGetCString(oc_string)
    if c_string == NULL:
        raise RuntimeError("Failed to get C string from OCStringRef")

    return c_string.decode('utf-8')

def ocmutablestring_create_from_pystring(str py_string):
    """
    Convert a Python string to an OCMutableStringRef.

    Args:
        py_string (str): Python string to convert

    Returns:
        OCMutableStringRef: OCTypes mutable string reference (needs to be released)
    """
    cdef uint64_t immutable_string_ptr = ocstring_create_from_pystring(py_string)
    cdef OCStringRef immutable_string = <OCStringRef>immutable_string_ptr
    cdef OCMutableStringRef mutable_string = OCStringCreateMutableCopy(immutable_string)

    # Release the temporary immutable string
    OCRelease(<const void*>immutable_string)

    if mutable_string == NULL:
        raise RuntimeError(f"Failed to create OCMutableString from: {py_string}")

    return <uint64_t>mutable_string

# ====================================================================================
# Number Helper Functions
# ====================================================================================

def ocnumber_create_from_pycomplex(double real_part, double imag_part):
    """
    Convert separate real and imaginary parts to an OCNumberRef.

    Args:
        real_part (float): Real component
        imag_part (float): Imaginary component

    Returns:
        OCNumberRef: OCTypes complex number reference (needs to be released)
    """
    # Create complex number using array approach (C99 complex is array[2] of double)
    cdef double complex_array[2]
    complex_array[0] = real_part   # real part
    complex_array[1] = imag_part   # imaginary part

    # Cast to double_complex
    cdef double_complex* c_complex_ptr = <double_complex*>complex_array
    cdef OCNumberRef oc_number = OCNumberCreateWithDoubleComplex(c_complex_ptr[0])
    if oc_number == NULL:
        raise RuntimeError(f"Failed to create complex OCNumber from {real_part}+{imag_part}j")
    return <uint64_t>oc_number

def ocnumber_create_from_pynumber(py_number):
    """
    Convert a Python number (int, float, complex) to an OCNumberRef.

    Args:
        py_number: Python number (int, float, complex)

    Returns:
        OCNumberRef: OCTypes number reference (needs to be released)
    """
    cdef OCNumberRef oc_number = NULL
    cdef double_complex c_val
    cdef complex py_complex
    cdef double real_part, imag_part

    if isinstance(py_number, bool):
        # Handle bool as int32 (bool is subclass of int in Python)
        oc_number = OCNumberCreateWithSInt32(1 if py_number else 0)
    elif isinstance(py_number, int):
        # Determine appropriate integer type based on value
        if -2147483648 <= py_number <= 2147483647:
            oc_number = OCNumberCreateWithSInt32(<int32_t>py_number)
        else:
            oc_number = OCNumberCreateWithSInt64(<int64_t>py_number)
    elif isinstance(py_number, float):
        oc_number = OCNumberCreateWithDouble(<double>py_number)
    elif isinstance(py_number, complex):
        # Direct complex number handling without wrapper to avoid circular imports
        real_part = py_number.real
        imag_part = py_number.imag
        return ocnumber_create_from_pycomplex(real_part, imag_part)
    else:
        raise TypeError(f"Unsupported number type: {type(py_number)}")

    if oc_number == NULL:
        raise RuntimeError(f"Failed to create OCNumber from: {py_number}")

    return <uint64_t>oc_number

def ocnumber_to_pynumber(uint64_t oc_number_ptr):
    """
    Convert an OCNumberRef to a Python number.

    Args:
        oc_number_ptr (uint64_t): Pointer to OCNumberRef

    Returns:
        int/float/complex: Python number
    """
    cdef OCNumberRef oc_number = <OCNumberRef>oc_number_ptr
    if oc_number == NULL:
        raise ValueError("OCNumberRef is NULL")

    cdef OCNumberType number_type = OCNumberGetType(oc_number)

    # Try different extraction methods based on type
    cdef int32_t int32_val
    cdef int64_t int64_val
    cdef double double_val
    cdef double_complex complex_val
    cdef double* components

    # Integer types
    if (number_type == kOCNumberSInt8Type or number_type == kOCNumberSInt16Type or
        number_type == kOCNumberSInt32Type or number_type == kOCNumberUInt8Type or
        number_type == kOCNumberUInt16Type or number_type == kOCNumberUInt32Type):

        if OCNumberTryGetSInt32(oc_number, &int32_val):
            return int(int32_val)
        elif OCNumberTryGetSInt64(oc_number, &int64_val):
            return int(int64_val)

    # 64-bit integers
    elif (number_type == kOCNumberSInt64Type or number_type == kOCNumberUInt64Type):
        if OCNumberTryGetSInt64(oc_number, &int64_val):
            return int(int64_val)

    # Floating-point types
    elif (number_type == kOCNumberFloat32Type or number_type == kOCNumberFloat64Type):
        if OCNumberTryGetFloat64(oc_number, &double_val):
            return float(double_val)

    # Complex types
    elif (number_type == kOCNumberComplex64Type or number_type == kOCNumberComplex128Type):
        if OCNumberTryGetComplex128(oc_number, &complex_val):
            # Extract components using array approach (C99 complex is array[2] of double)
            components = <double*>&complex_val
            return complex(components[0], components[1])

    # Fallback: try double extraction
    if OCNumberTryGetFloat64(oc_number, &double_val):
        return float(double_val)

    raise RuntimeError(f"Failed to extract value from OCNumber with type: {number_type}")

# ====================================================================================
# Boolean Helper Functions
# ====================================================================================

def pybool_to_ocboolean(bint py_bool):
    """
    Convert a Python bool to an OCBooleanRef.

    Args:
        py_bool (bool): Python boolean value

    Returns:
        OCBooleanRef: OCTypes boolean reference (singleton, no need to release)
    """
    if py_bool:
        return <uint64_t>kOCBooleanTrue
    else:
        return <uint64_t>kOCBooleanFalse

def ocboolean_to_pybool(uint64_t oc_boolean_ptr):
    """
    Convert an OCBooleanRef to a Python bool.

    Args:
        oc_boolean_ptr (uint64_t): Pointer to OCBooleanRef

    Returns:
        bool: Python boolean value
    """
    cdef OCBooleanRef oc_boolean = <OCBooleanRef>oc_boolean_ptr
    return OCBooleanGetValue(oc_boolean)

# ====================================================================================
# Data Helper Functions (NumPy-focused)
# ====================================================================================

import numpy as np

cimport numpy as cnp

# Initialize NumPy C API
cnp.import_array()

def ocdata_create_from_numpy_array(object numpy_array):
    """
    Convert a NumPy array to an OCDataRef.

    Args:
        numpy_array: NumPy array

    Returns:
        OCDataRef: OCTypes data reference (needs to be released)

    Raises:
        RuntimeError: If data creation fails
        TypeError: If input type is not a NumPy array
    """
    if not isinstance(numpy_array, np.ndarray):
        raise TypeError(f"Expected numpy.ndarray, got {type(numpy_array)}. Use numpy arrays for OCData.")

    # Ensure array is contiguous
    if not numpy_array.flags.c_contiguous:
        numpy_array = np.ascontiguousarray(numpy_array)

    cdef const unsigned char* data_ptr = <const unsigned char*>cnp.PyArray_DATA(numpy_array)
    cdef uint64_t length = numpy_array.nbytes

    cdef OCDataRef oc_data = OCDataCreate(data_ptr, length)
    if oc_data == NULL:
        raise RuntimeError("Failed to create OCData from NumPy array")

    return <uint64_t>oc_data

def ocdata_to_numpy_array(uint64_t oc_data_ptr, object dtype, object shape=None):
    """
    Convert an OCDataRef to a NumPy array.

    Args:
        oc_data_ptr (uint64_t): Pointer to OCDataRef
        dtype: NumPy dtype for the output array
        shape: Shape tuple for the output array (if None, returns 1D array)

    Returns:
        numpy.ndarray: NumPy array with specified dtype and shape

    Raises:
        ValueError: If the OCDataRef is NULL or data cannot be reshaped
        TypeError: If dtype is not specified
    """
    cdef OCDataRef oc_data = <OCDataRef>oc_data_ptr
    if oc_data == NULL:
        raise ValueError("OCDataRef is NULL")

    if dtype is None:
        raise TypeError("dtype must be specified. NumPy dtype required for array conversion.")

    cdef const unsigned char* data_ptr = OCDataGetBytesPtr(oc_data)
    cdef uint64_t length = OCDataGetLength(oc_data)

    if data_ptr == NULL:
        return np.array([], dtype=dtype)

    # Validate dtype and shape
    np_dtype = np.dtype(dtype)
    expected_bytes = np_dtype.itemsize

    if shape is None:
        # 1D array
        if length % expected_bytes != 0:
            raise ValueError(f"Data length {length} is not compatible with dtype {dtype} (itemsize {expected_bytes})")
        count = length // expected_bytes
        shape = (count,)
    else:
        # Specified shape
        expected_total = np.prod(shape) * expected_bytes
        if length != expected_total:
            raise ValueError(f"Data length {length} does not match expected size {expected_total} for shape {shape} and dtype {dtype}")

    # Create NumPy array from memory view
    cdef cnp.ndarray result = np.frombuffer(data_ptr[:length], dtype=dtype)

    if len(shape) > 1:
        result = result.reshape(shape)

    return result.copy()  # Return a copy to avoid memory issues

# ====================================================================================
# Array Helper Functions
# ====================================================================================

def ocarray_create_from_pylist(py_list):
    """
    Convert a Python list to an OCArrayRef.

    Args:
        py_list (list): Python list to convert

    Returns:
        OCArrayRef: OCTypes array reference (needs to be released)

    Raises:
        RuntimeError: If array creation fails
    """
    if py_list is None:
        return <uint64_t>0

    cdef OCMutableArrayRef mutable_array = OCArrayCreateMutable(0, &kOCTypeArrayCallBacks)
    cdef uint64_t oc_item_ptr = 0

    if mutable_array == NULL:
        raise RuntimeError("Failed to create OCMutableArray")

    # Add each element to the array
    for item in py_list:
        oc_item_ptr = 0

        try:
            # Handle collections explicitly to avoid circular dependencies
            if isinstance(item, list):
                oc_item_ptr = ocarray_create_from_pylist(item)
            elif isinstance(item, dict):
                oc_item_ptr = ocdict_create_from_pydict(item)
            elif isinstance(item, set):
                oc_item_ptr = ocset_create_from_pyset(item)
            elif isinstance(item, str):
                oc_item_ptr = ocstring_create_from_pystring(item)
            elif isinstance(item, bool):  # Check bool before int (bool is subclass of int)
                oc_item_ptr = pybool_to_ocboolean(item)
            elif isinstance(item, (int, float, complex)):
                oc_item_ptr = ocnumber_create_from_pynumber(item)
            elif isinstance(item, np.ndarray):
                oc_item_ptr = ocdata_create_from_numpy_array(item)
            else:
                raise TypeError(f"Unsupported item type for array: {type(item)}")

            # Add to array
            OCArrayAppendValue(mutable_array, <const void*>oc_item_ptr)

            # Release our reference (array retains it with proper callbacks)
            OCRelease(<const void*>oc_item_ptr)

        except Exception as e:
            if oc_item_ptr != 0:
                OCRelease(<const void*>oc_item_ptr)
            OCRelease(<const void*>mutable_array)
            raise

    # Create immutable copy
    cdef OCArrayRef immutable_array = OCArrayCreateCopy(<OCArrayRef>mutable_array)
    OCRelease(<const void*>mutable_array)

    if immutable_array == NULL:
        raise RuntimeError("Failed to create immutable OCArray copy")

    return <uint64_t>immutable_array

def ocarray_to_pylist(uint64_t oc_array_ptr):
    """
    Convert an OCArrayRef to a Python list.

    Args:
        oc_array_ptr (uint64_t): Pointer to OCArrayRef

    Returns:
        list: Python list

    Raises:
        ValueError: If the OCArrayRef is NULL
    """
    cdef OCArrayRef oc_array = <OCArrayRef>oc_array_ptr
    if oc_array == NULL:
        raise ValueError("OCArrayRef is NULL")

    cdef uint64_t count = OCArrayGetCount(oc_array)
    cdef list result = []

    cdef uint64_t i
    cdef const void* item_ptr
    cdef OCTypeID type_id

    for i in range(count):
        item_ptr = OCArrayGetValueAtIndex(oc_array, i)
        if item_ptr == NULL:
            result.append(None)
            continue

        # Direct conversion instead of using convert_octype_to_python to avoid recursion issues
        type_id = OCGetTypeID(item_ptr)

        # Handle known OCTypes directly
        if type_id == OCStringGetTypeID():
            py_item = ocstring_to_pystring(<uint64_t>item_ptr)
        elif type_id == OCNumberGetTypeID():
            py_item = ocnumber_to_pynumber(<uint64_t>item_ptr)
        elif type_id == OCBooleanGetTypeID():
            py_item = ocboolean_to_pybool(<uint64_t>item_ptr)
        elif type_id == OCDataGetTypeID():
            # Default to uint8 array for OCData
            py_item = ocdata_to_numpy_array(<uint64_t>item_ptr, np.uint8)
        elif type_id == OCArrayGetTypeID():
            # Recursive call - this could be the source of issues
            py_item = ocarray_to_pylist(<uint64_t>item_ptr)
        elif type_id == OCDictionaryGetTypeID():
            py_item = ocdict_to_pydict(<uint64_t>item_ptr)
        elif type_id == OCSetGetTypeID():
            py_item = ocset_to_pyset(<uint64_t>item_ptr)
        elif type_id == OCIndexArrayGetTypeID():
            py_item = ocindexarray_to_pylist(<uint64_t>item_ptr)
        elif type_id == OCIndexSetGetTypeID():
            py_item = ocindexset_to_pyset(<uint64_t>item_ptr)
        elif type_id == OCIndexPairSetGetTypeID():
            py_item = ocindexpairset_to_pydict(<uint64_t>item_ptr)
        elif type_id == SIScalarGetTypeID():
            from rmnpy.wrappers.sitypes.scalar import siscalar_to_scalar
            py_item = siscalar_to_scalar(<uint64_t>item_ptr)
        elif type_id == SIUnitGetTypeID():
            from rmnpy.wrappers.sitypes.unit import siunit_to_pyunit
            py_item = siunit_to_pyunit(<uint64_t>item_ptr)
        elif type_id == SIDimensionalityGetTypeID():
            # Use lazy import to avoid circular import
            from rmnpy.wrappers.sitypes.dimensionality import (
                sidimensionality_to_dimensionality,
            )
            py_item = sidimensionality_to_dimensionality(<uint64_t>item_ptr)
        # Handle RMNLib Dimension types
        elif type_id == DimensionGetTypeID():
            py_item = dimension_to_pydimension(<uint64_t>item_ptr)
        elif type_id == LabeledDimensionGetTypeID():
            py_item = dimension_to_pydimension(<uint64_t>item_ptr)
        elif type_id == SIDimensionGetTypeID():
            py_item = dimension_to_pydimension(<uint64_t>item_ptr)
        elif type_id == SILinearDimensionGetTypeID():
            py_item = dimension_to_pydimension(<uint64_t>item_ptr)
        elif type_id == SIMonotonicDimensionGetTypeID():
            py_item = dimension_to_pydimension(<uint64_t>item_ptr)
        else:
            # Unknown OCType - return as integer pointer
            py_item = <uint64_t>item_ptr

        result.append(py_item)

    return result

def ocmutablearray_create_from_pylist(list py_list):
    """
    Convert a Python list to an OCMutableArrayRef.

    Args:
        py_list (list): Python list to convert

    Returns:
        OCMutableArrayRef: OCTypes mutable array reference (needs to be released)
    """
    cdef OCMutableArrayRef mutable_array = OCArrayCreateMutable(0, &kOCTypeArrayCallBacks)
    cdef uint64_t oc_item_ptr = 0

    if mutable_array == NULL:
        raise RuntimeError("Failed to create OCMutableArray")

    # Add each element to the array
    for item in py_list:
        oc_item_ptr = 0

        try:
            # Handle collections explicitly to avoid circular dependencies
            if isinstance(item, list):
                oc_item_ptr = ocarray_create_from_pylist(item)
            elif isinstance(item, dict):
                oc_item_ptr = ocdict_create_from_pydict(item)
            elif isinstance(item, set):
                oc_item_ptr = ocset_create_from_pyset(item)
            else:
                # Use the generic converter for basic types and OCTypes (including SITypes, RMNLib)
                oc_item_ptr = convert_python_to_octype(item)

            # Add to array
            OCArrayAppendValue(mutable_array, <const void*>oc_item_ptr)

            # Release our reference (array retains it)
            OCRelease(<const void*>oc_item_ptr)

        except Exception as e:
            if oc_item_ptr != 0:
                OCRelease(<const void*>oc_item_ptr)
            OCRelease(<const void*>mutable_array)
            raise

    return <uint64_t>mutable_array

# ====================================================================================
# Dictionary Helper Functions
# ====================================================================================

def ocdict_create_from_pydict(py_dict):
    """
    Convert a Python dict to an OCDictionaryRef.

    Note: OCDictionary only supports string keys. All keys will be converted to strings.

    Args:
        py_dict (dict): Python dictionary to convert

    Returns:
        OCDictionaryRef: OCTypes dictionary reference (needs to be released)

    Raises:
        RuntimeError: If dictionary creation fails
    """
    # Return NULL pointer if no dictionary provided
    if py_dict is None:
        return <uint64_t>0
    # Ensure correct type
    if not isinstance(py_dict, dict):
        raise TypeError(f"Expected dict or None, got {type(py_dict)}")
    cdef OCMutableDictionaryRef mutable_dict = OCDictionaryCreateMutable(0)
    cdef uint64_t oc_key_ptr = 0
    cdef uint64_t oc_value_ptr = 0
    cdef str str_key

    if mutable_dict == NULL:
        raise RuntimeError("Failed to create OCMutableDictionary")

    # Add each key-value pair
    for key, value in py_dict.items():
        oc_key_ptr = 0
        oc_value_ptr = 0

        try:
            # Convert key to string (OCDictionary requires string keys)
            if isinstance(key, str):
                str_key = key
            else:
                str_key = str(key)  # Convert to string representation
            oc_key_ptr = ocstring_create_from_pystring(str_key)

            # Convert value
            # Handle collections explicitly to avoid circular dependencies
            if isinstance(value, list):
                oc_value_ptr = ocarray_create_from_pylist(value)
            elif isinstance(value, dict):
                oc_value_ptr = ocdict_create_from_pydict(value)
            elif isinstance(value, set):
                oc_value_ptr = ocset_create_from_pyset(value)
            else:
                # Use the generic converter for basic types and OCTypes (including SITypes, RMNLib)
                oc_value_ptr = convert_python_to_octype(value)

            # Add to dictionary
            OCDictionarySetValue(mutable_dict, <OCStringRef>oc_key_ptr, <const void*>oc_value_ptr)

            # Release our references (dictionary retains them)
            OCRelease(<const void*>oc_key_ptr)
            OCRelease(<const void*>oc_value_ptr)

        except Exception:
            if oc_key_ptr != 0:
                OCRelease(<const void*>oc_key_ptr)
            if oc_value_ptr != 0:
                OCRelease(<const void*>oc_value_ptr)
            OCRelease(<const void*>mutable_dict)
            raise

    # Create immutable copy
    cdef OCDictionaryRef immutable_dict = OCDictionaryCreateCopy(<OCDictionaryRef>mutable_dict)
    OCRelease(<const void*>mutable_dict)

    if immutable_dict == NULL:
        raise RuntimeError("Failed to create immutable OCDictionary copy")

    return <uint64_t>immutable_dict

def ocdict_to_pydict(uint64_t oc_dict_ptr):
    """
    Convert an OCDictionaryRef to a Python dict.

    Args:
        oc_dict_ptr (uint64_t): Pointer to OCDictionaryRef

    Returns:
        dict: Python dictionary

    Raises:
        ValueError: If the OCDictionaryRef is NULL
        RuntimeError: If key-value extraction fails
    """
    cdef OCDictionaryRef oc_dict = <OCDictionaryRef>oc_dict_ptr
    cdef const void** keys
    cdef const void** values
    cdef dict result = {}
    cdef uint64_t i
    cdef OCTypeID key_type_id
    cdef str py_key
    cdef object py_value

    if oc_dict == NULL:
        raise ValueError("OCDictionaryRef is NULL")

    cdef uint64_t count = OCDictionaryGetCount(oc_dict)
    if count == 0:
        return {}

    # Allocate arrays for keys and values
    keys = <const void**>malloc(count * sizeof(void*))
    values = <const void**>malloc(count * sizeof(void*))

    if keys == NULL or values == NULL:
        if keys != NULL:
            free(keys)
        if values != NULL:
            free(values)
        raise MemoryError("Failed to allocate memory for keys/values arrays")

    try:
        # Get all keys and values
        if not OCDictionaryGetKeysAndValues(oc_dict, keys, values):
            raise RuntimeError("Failed to get keys and values from OCDictionary")

        for i in range(count):
            if keys[i] == NULL or values[i] == NULL:
                continue

            # Convert key (should be OCString)
            key_type_id = OCGetTypeID(keys[i])
            if key_type_id != OCStringGetTypeID():
                continue  # Skip non-string keys

            py_key = ocstring_to_pystring(<uint64_t>keys[i])

            # Convert value using extensible converter that handles all OCTypes
            py_value = convert_octype_to_python(values[i])

            result[py_key] = py_value

        return result

    finally:
        if keys != NULL:
            free(keys)
        if values != NULL:
            free(values)

def ocmutabledict_create_from_pydict(dict py_dict):
    """
    Convert a Python dict to an OCMutableDictionaryRef.

    Note: OCDictionary only supports string keys. All keys will be converted to strings.

    Args:
        py_dict (dict): Python dictionary to convert

    Returns:
        OCMutableDictionaryRef: OCTypes mutable dictionary reference (needs to be released)
    """
    cdef OCMutableDictionaryRef mutable_dict = OCDictionaryCreateMutable(0)
    cdef uint64_t oc_key_ptr = 0
    cdef uint64_t oc_value_ptr = 0
    cdef str str_key

    if mutable_dict == NULL:
        raise RuntimeError("Failed to create OCMutableDictionary")

    # Add each key-value pair (same logic as immutable version)
    for key, value in py_dict.items():
        oc_key_ptr = 0
        oc_value_ptr = 0

        try:
            # Convert key to string (OCDictionary requires string keys)
            if isinstance(key, str):
                str_key = key
            else:
                str_key = str(key)  # Convert to string representation
            oc_key_ptr = ocstring_create_from_pystring(str_key)

            # Convert value
            # Handle collections explicitly to avoid circular dependencies
            if isinstance(value, list):
                oc_value_ptr = ocarray_create_from_pylist(value)
            elif isinstance(value, dict):
                oc_value_ptr = ocdict_create_from_pydict(value)
            elif isinstance(value, set):
                oc_value_ptr = ocset_create_from_pyset(value)
            else:
                # Use the generic converter for basic types and OCTypes (including SITypes, RMNLib)
                oc_value_ptr = convert_python_to_octype(value)

            # Add to dictionary
            OCDictionarySetValue(mutable_dict, <OCStringRef>oc_key_ptr, <const void*>oc_value_ptr)

            # Release our references
            OCRelease(<const void*>oc_key_ptr)
            OCRelease(<const void*>oc_value_ptr)

        except Exception:
            if oc_key_ptr != 0:
                OCRelease(<const void*>oc_key_ptr)
            if oc_value_ptr != 0:
                OCRelease(<const void*>oc_value_ptr)
            OCRelease(<const void*>mutable_dict)
            raise

    return <uint64_t>mutable_dict

# ====================================================================================
# Set Helper Functions
# ====================================================================================

def ocset_create_from_pyset(set py_set):
    """
    Convert a Python set to an OCSetRef.

    Args:
        py_set (set): Python set to convert

    Returns:
        OCSetRef: OCTypes set reference (needs to be released)

    Raises:
        RuntimeError: If set creation fails
    """
    cdef OCMutableSetRef mutable_set = OCSetCreateMutable(0)
    cdef uint64_t oc_item_ptr = 0

    if mutable_set == NULL:
        raise RuntimeError("Failed to create OCMutableSet")

    # Add each element to the set
    for item in py_set:
        oc_item_ptr = 0

        try:
            # Use the generic converter for basic types and OCTypes (including SITypes, RMNLib)
            # Note: Collections (list, dict, set) are not hashable so not allowed in sets
            oc_item_ptr = convert_python_to_octype(item)

            # Add to set
            OCSetAddValue(mutable_set, <OCTypeRef>oc_item_ptr)

            # Release our reference (set retains it)
            OCRelease(<const void*>oc_item_ptr)

        except Exception as e:
            if oc_item_ptr != 0:
                OCRelease(<const void*>oc_item_ptr)
            OCRelease(<const void*>mutable_set)
            raise

    # Create immutable copy
    cdef OCSetRef immutable_set = OCSetCreateCopy(<OCSetRef>mutable_set)
    OCRelease(<const void*>mutable_set)

    if immutable_set == NULL:
        raise RuntimeError("Failed to create immutable OCSet copy")

    return <uint64_t>immutable_set

def ocset_to_pyset(uint64_t oc_set_ptr):
    """
    Convert an OCSetRef to a Python set.

    Args:
        oc_set_ptr (uint64_t): Pointer to OCSetRef

    Returns:
        set: Python set

    Raises:
        ValueError: If the OCSetRef is NULL
    """
    cdef OCSetRef oc_set = <OCSetRef>oc_set_ptr
    if oc_set == NULL:
        raise ValueError("OCSetRef is NULL")

    cdef uint64_t count = OCSetGetCount(oc_set)
    if count == 0:
        return set()

    # Get all values as array
    cdef OCArrayRef values_array = OCSetCreateValueArray(oc_set)
    if values_array == NULL:
        return set()

    cdef set result = set()
    cdef uint64_t i
    cdef const void* item_ptr
    cdef OCTypeID type_id

    for i in range(count):
        item_ptr = OCArrayGetValueAtIndex(values_array, i)
        if item_ptr == NULL:
            continue

        type_id = OCGetTypeID(item_ptr)

        # Convert based on type (only hashable types for sets)
        if type_id == OCStringGetTypeID():
            result.add(ocstring_to_pystring(<uint64_t>item_ptr))
        elif type_id == OCNumberGetTypeID():
            result.add(ocnumber_to_pynumber(<uint64_t>item_ptr))
        elif type_id == OCBooleanGetTypeID():
            result.add(ocboolean_to_pybool(<uint64_t>item_ptr))
        elif type_id == SIScalarGetTypeID():
            # Convert SIScalar to Scalar object
            from rmnpy.wrappers.sitypes.scalar import siscalar_to_scalar
            scalar_obj = siscalar_to_scalar(<uint64_t>item_ptr)
            result.add(scalar_obj)
        elif type_id == SIUnitGetTypeID():
            # Convert SIUnit to Unit object (if hashable)
            from rmnpy.wrappers.sitypes.unit import siunit_to_pyunit
            unit_obj = siunit_to_pyunit(<uint64_t>item_ptr)
            try:
                result.add(unit_obj)
            except TypeError:
                # If Unit objects aren't hashable, convert to string representation
                # For now, add as integer pointer - this could be improved with string conversion
                result.add(f"SIUnit({<uint64_t>item_ptr})")
        elif type_id == SIDimensionalityGetTypeID():
            # Convert SIDimensionality to Dimensionality object (if hashable)
            # Use lazy import to avoid circular import
            from rmnpy.wrappers.sitypes.dimensionality import (
                sidimensionality_to_dimensionality,
            )
            dim_obj = sidimensionality_to_dimensionality(<uint64_t>item_ptr)
            try:
                result.add(dim_obj)
            except TypeError:
                # If Dimensionality objects aren't hashable, convert to string representation
                # For now, add as integer pointer - this could be improved with string conversion
                result.add(f"SIDimensionality({<uint64_t>item_ptr})")
        # Note: Can't add arrays/dicts to sets as they're not hashable

    OCRelease(<const void*>values_array)
    return result

def ocmutableset_create_from_pyset(set py_set):
    """
    Convert a Python set to an OCMutableSetRef.

    Args:
        py_set (set): Python set to convert

    Returns:
        OCMutableSetRef: OCTypes mutable set reference (needs to be released)
    """
    cdef OCMutableSetRef mutable_set = OCSetCreateMutable(0)
    cdef uint64_t oc_item_ptr = 0

    if mutable_set == NULL:
        raise RuntimeError("Failed to create OCMutableSet")

    # Add each element to the set
    for item in py_set:
        oc_item_ptr = 0

        try:
            # Use the generic converter for basic types and OCTypes (including SITypes, RMNLib)
            # Note: Collections (list, dict, set) are not hashable so not allowed in sets
            oc_item_ptr = convert_python_to_octype(item)

            # Add to set
            OCSetAddValue(mutable_set, <OCTypeRef>oc_item_ptr)

            # Release our reference (set retains it)
            OCRelease(<const void*>oc_item_ptr)

        except Exception as e:
            if oc_item_ptr != 0:
                OCRelease(<const void*>oc_item_ptr)
            OCRelease(<const void*>mutable_set)
            raise

    return <uint64_t>mutable_set

# ====================================================================================
# Index Collection Helper Functions
# ====================================================================================

def ocindexarray_create_from_pylist(list py_list):
    """
    Convert a Python list of integers to an OCIndexArrayRef.

    Args:
        py_list (list[int]): Python list of integers

    Returns:
        OCIndexArrayRef: OCTypes index array reference (needs to be released)

    Raises:
        RuntimeError: If index array creation fails
        TypeError: If list contains non-integer values
    """
    # Validate all items are integers
    for item in py_list:
        if not isinstance(item, int):
            raise TypeError(f"All items must be integers, got {type(item)}")

    cdef uint64_t count = len(py_list)
    cdef OCIndex* indices = <OCIndex*>malloc(count * sizeof(OCIndex))
    cdef uint64_t i
    cdef OCIndexArrayRef index_array

    if indices == NULL and count > 0:
        raise MemoryError("Failed to allocate memory for indices")

    try:
        # Copy values
        for i in range(count):
            indices[i] = <OCIndex>py_list[i]

        # Create index array
        index_array = OCIndexArrayCreate(indices, count)
        if index_array == NULL:
            raise RuntimeError("Failed to create OCIndexArray")

        return <uint64_t>index_array

    finally:
        if indices != NULL:
            free(indices)

def ocindexarray_to_pylist(uint64_t oc_indexarray_ptr):
    """
    Convert an OCIndexArrayRef to a Python list of integers.

    Args:
        oc_indexarray_ptr (uint64_t): Pointer to OCIndexArrayRef

    Returns:
        list[int]: Python list of integers

    Raises:
        ValueError: If the OCIndexArrayRef is NULL
    """
    cdef OCIndexArrayRef oc_indexarray = <OCIndexArrayRef>oc_indexarray_ptr
    if oc_indexarray == NULL:
        raise ValueError("OCIndexArrayRef is NULL")

    cdef uint64_t count = OCIndexArrayGetCount(oc_indexarray)
    cdef list result = []

    cdef uint64_t i
    for i in range(count):
        result.append(int(OCIndexArrayGetValueAtIndex(oc_indexarray, i)))

    return result

def ocindexset_create_from_pyset(set py_set):
    """
    Convert a Python set of integers to an OCIndexSetRef.

    Args:
        py_set (set[int]): Python set of integers

    Returns:
        OCIndexSetRef: OCTypes index set reference (needs to be released)

    Raises:
        RuntimeError: If index set creation fails
        TypeError: If set contains non-integer values
    """
    # Validate all items are integers
    for item in py_set:
        if not isinstance(item, int):
            raise TypeError(f"All items must be integers, got {type(item)}")

    cdef OCMutableIndexSetRef mutable_indexset = OCIndexSetCreateMutable()
    if mutable_indexset == NULL:
        raise RuntimeError("Failed to create OCMutableIndexSet")

    # Add each index
    for item in py_set:
        OCIndexSetAddIndex(mutable_indexset, <OCIndex>item)

    # Create immutable copy
    cdef OCIndexSetRef immutable_indexset
    if len(py_set) == 0:
        # For empty sets, create a new empty immutable set
        immutable_indexset = OCIndexSetCreate()
    else:
        # For non-empty sets, copy from the mutable version
        immutable_indexset = OCIndexSetCreateCopy(<OCIndexSetRef>mutable_indexset)

    OCRelease(<const void*>mutable_indexset)

    if immutable_indexset == NULL:
        raise RuntimeError("Failed to create immutable OCIndexSet copy")

    return <uint64_t>immutable_indexset

def ocindexset_to_pyset(uint64_t oc_indexset_ptr):
    """
    Convert an OCIndexSetRef to a Python set of integers.

    Note: This function has limited functionality because OCIndexSet doesn't
    provide a way to iterate over all indices. It can only return the first
    and last indices if the set is contiguous.

    Args:
        oc_indexset_ptr (uint64_t): Pointer to OCIndexSetRef

    Returns:
        set[int]: Python set of integers (may be incomplete)

    Raises:
        ValueError: If the OCIndexSetRef is NULL
    """
    cdef OCIndexSetRef oc_indexset = <OCIndexSetRef>oc_indexset_ptr
    if oc_indexset == NULL:
        raise ValueError("OCIndexSetRef is NULL")

    cdef uint64_t count = OCIndexSetGetCount(oc_indexset)
    if count == 0:
        return set()

    # Limited functionality: can only get first and last indices
    # This is a limitation of the OCTypes IndexSet API
    cdef set result = set()

    cdef OCIndex first_index = OCIndexSetFirstIndex(oc_indexset)
    cdef OCIndex last_index = OCIndexSetLastIndex(oc_indexset)

    # If it's a single index
    if count == 1:
        result.add(int(first_index))
    # If it might be a contiguous range
    elif last_index - first_index + 1 == count:
        # Assume contiguous range (this is a guess)
        for i in range(first_index, last_index + 1):
            result.add(int(i))
    else:
        # Non-contiguous set - we can't determine all values
        # Just return the first and last as a best effort
        result.add(int(first_index))
        if first_index != last_index:
            result.add(int(last_index))

    return result

def ocindexpairset_create_from_pydict(dict py_dict):
    """
    Convert a Python dict[int, int] to an OCIndexPairSetRef.

    Args:
        py_dict (dict[int, int]): Python dictionary mapping integers to integers

    Returns:
        OCIndexPairSetRef: OCTypes index pair set reference (needs to be released)

    Raises:
        RuntimeError: If index pair set creation fails
        TypeError: If dict contains non-integer keys or values
    """
    # Validate all keys and values are integers
    for key, value in py_dict.items():
        if not isinstance(key, int):
            raise TypeError(f"All keys must be integers, got {type(key)}")
        if not isinstance(value, int):
            raise TypeError(f"All values must be integers, got {type(value)}")

    cdef OCMutableIndexPairSetRef mutable_pairset = OCIndexPairSetCreateMutable()
    if mutable_pairset == NULL:
        raise RuntimeError("Failed to create OCMutableIndexPairSet")

    # Add each pair
    for key, value in py_dict.items():
        OCIndexPairSetAddIndexPair(mutable_pairset, <OCIndex>key, <OCIndex>value)

    # Create immutable copy using the now-available function
    cdef OCIndexPairSetRef immutable_pairset = OCIndexPairSetCreateCopy(mutable_pairset)
    if immutable_pairset == NULL:
        OCRelease(<OCTypeRef>mutable_pairset)
        raise RuntimeError("Failed to create immutable copy of OCIndexPairSet")

    # Release the mutable version and return immutable
    OCRelease(<OCTypeRef>mutable_pairset)
    return <uint64_t>immutable_pairset

def ocindexpairset_to_pydict(uint64_t oc_indexpairset_ptr):
    """
    Convert an OCIndexPairSetRef to a Python dict[int, int].

    Args:
        oc_indexpairset_ptr (uint64_t): Pointer to OCIndexPairSetRef

    Returns:
        dict[int, int]: Python dictionary mapping indices to values

    Raises:
        ValueError: If the OCIndexPairSetRef is NULL
    """
    cdef OCIndexPairSetRef oc_indexpairset = <OCIndexPairSetRef>oc_indexpairset_ptr
    if oc_indexpairset == NULL:
        raise ValueError("OCIndexPairSetRef is NULL")

    cdef uint64_t count = OCIndexPairSetGetCount(oc_indexpairset)
    if count == 0:
        return {}

    cdef dict result = {}

    # Use a brute force approach to find all indices with reasonable bounds
    # Based on the input keys, search around that range
    cdef OCIndex potential_index
    cdef OCIndex value

    for potential_index in range(0, 1000):  # reasonable search range
        if OCIndexPairSetContainsIndex(oc_indexpairset, potential_index):
            value = OCIndexPairSetValueForIndex(oc_indexpairset, potential_index)
            result[int(potential_index)] = int(value)

            # Stop when we've found all pairs
            if len(result) >= count:
                break

    return result

# ====================================================================================
# Mutable Data Helper Functions
# ====================================================================================

def ocmutabledata_create_from_numpy_array(object numpy_array):
    """
    Convert a NumPy array to an OCMutableDataRef.

    Args:
        numpy_array: NumPy array

    Returns:
        OCMutableDataRef: OCTypes mutable data reference (needs to be released)

    Raises:
        RuntimeError: If data creation fails
        TypeError: If input type is not a NumPy array
    """
    if not isinstance(numpy_array, np.ndarray):
        raise TypeError(f"Expected numpy.ndarray, got {type(numpy_array)}. Use numpy arrays for OCMutableData.")

    # Ensure array is contiguous
    if not numpy_array.flags.c_contiguous:
        numpy_array = np.ascontiguousarray(numpy_array)

    cdef const unsigned char* data_ptr = <const unsigned char*>cnp.PyArray_DATA(numpy_array)
    cdef uint64_t length = numpy_array.nbytes

    cdef OCMutableDataRef oc_mutable_data = OCDataCreateMutable(length)
    if oc_mutable_data == NULL:
        raise RuntimeError("Failed to create OCMutableData from NumPy array")

    # Copy the data into the mutable data object
    # Note: This assumes OCMutableData provides a way to set the data
    # The exact API for this might need verification

    return <uint64_t>oc_mutable_data

# ====================================================================================
# Dimension Helper Functions (RMNLib)
# ====================================================================================

def dimension_to_pydimension(uint64_t dimension_ptr):
    """
    Convert an RMNLib dimension pointer to the appropriate Python dimension object.

    Args:
        dimension_ptr (uint64_t): Pointer to RMNLib dimension reference

    Returns:
        BaseDimension subclass: Appropriate Python dimension wrapper

    Raises:
        ValueError: If dimension_ptr is NULL
        RuntimeError: If dimension type is unknown
    """
    if dimension_ptr == 0:
        raise ValueError("Dimension pointer is NULL")

    if not DIMENSION_AVAILABLE:
        # Fall back to returning the raw pointer if dimension classes not available
        return dimension_ptr

    cdef const void* dim_ptr = <const void*>dimension_ptr
    cdef OCTypeID type_id = OCGetTypeID(dim_ptr)

    # Determine the specific dimension type and create appropriate wrapper
    if type_id == DimensionGetTypeID():
        # Generic BaseDimension (shouldn't happen in practice, but handle it)
        return DIMENSION_CLASSES['BaseDimension']._from_c_ref(dimension_ptr)
    elif type_id == LabeledDimensionGetTypeID():
        return DIMENSION_CLASSES['LabeledDimension']._from_c_ref(dimension_ptr)
    elif type_id == SIDimensionGetTypeID():
        return DIMENSION_CLASSES['SIDimension']._from_c_ref(dimension_ptr)
    elif type_id == SILinearDimensionGetTypeID():
        return DIMENSION_CLASSES['SILinearDimension']._from_c_ref(dimension_ptr)
    elif type_id == SIMonotonicDimensionGetTypeID():
        return DIMENSION_CLASSES['SIMonotonicDimension']._from_c_ref(dimension_ptr)
    else:
        # Unknown dimension type - fall back to raw pointer
        return dimension_ptr

def pydimension_to_dimension_ptr(object dimension_obj):
    """
    Extract the C dimension pointer from a Python dimension object.

    Args:
        dimension_obj: Python dimension object with _c_ref attribute

    Returns:
        uint64_t: C dimension pointer

    Raises:
        TypeError: If object doesn't have _c_ref attribute
    """
    if not hasattr(dimension_obj, '_c_ref'):
        raise TypeError(f"Object {type(dimension_obj)} doesn't have _c_ref attribute")

    return <uint64_t>dimension_obj._c_ref


def element_type_to_numpy_dtype(str element_type_str):
    """Convert OCNumberType name to corresponding NumPy dtype.

    Args:
        element_type_str (str): OCNumberType name (e.g., "float64", "sint32", etc.)

    Returns:
        numpy.dtype: Corresponding NumPy dtype

    Note:
        This function maps OCNumberType names to their NumPy equivalents.
        Returns np.float64 as default for unknown types.
    """
    # Map OCNumberType names to NumPy dtypes
    dtype_map = {
        "sint8": np.int8,
        "sint16": np.int16,
        "sint32": np.int32,
        "sint64": np.int64,
        "uint8": np.uint8,
        "uint16": np.uint16,
        "uint32": np.uint32,
        "uint64": np.uint64,
        "float32": np.float32,
        "float64": np.float64,
        "complex64": np.complex64,
        "complex128": np.complex128,
    }
    return dtype_map.get(element_type_str.lower(), np.float64)


def enum_to_element_type(OCNumberType elem_type):
    """Convert OCNumberType enum to string using OCTypes helper.

    Args:
        elem_type (OCNumberType): OCNumberType enum value

    Returns:
        str: String representation of the OCNumberType (e.g., "float64", "sint32", etc.)

    Note:
        This function uses the OCTypes API to convert enum values to their string names.
        Returns "unknown" for invalid or unrecognized types.
    """
    cdef const char* type_name = OCNumberGetTypeName(elem_type)
    if type_name == NULL:
        return "unknown"
    return type_name.decode('utf-8')


# ====================================================================================
# End of File
# ===================================================================================
