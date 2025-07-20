# cython: language_level=3
"""
OCTypes Helper Functions

This module provides conversion utilities between Python types and OCTypes C structures.
These helpers enable seamless integration between Python objects and the OCTypes library.
"""

from rmnpy._c_api.octypes cimport *
from libc.stdint cimport uint8_t, int8_t, uint16_t, int16_t
from libc.stdint cimport uint32_t, int32_t, uint64_t, int64_t
from libc.stdlib cimport malloc, free
from libc.string cimport memcpy
import cython

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
    
    # First check if it's already an OCType (could be from SITypes or other extensions)
    # TEMPORARILY DISABLED: This check causes segfaults
    # if hasattr(item, '__int__') and hasattr(item, '__index__'):
    #     # This might be an OCType pointer stored as an integer
    #     try:
    #         item_ptr = int(item)
    #         if item_ptr != 0 and OCGetTypeID(<const void*>item_ptr) != kOCNotATypeID:
    #             # It's a valid OCType, retain it and use directly
    #             return <uint64_t>OCRetain(<const void*>item_ptr)
    #     except:
    #         pass  # Fall through to regular Python type handling
    
    # Handle built-in Python types
    if isinstance(item, str):
        return py_string_to_ocstring(item)
    elif isinstance(item, bool):  # Check bool before int (bool is subclass of int)
        return py_bool_to_ocboolean(item)
    elif isinstance(item, (int, float, complex)):
        return py_number_to_ocnumber(item)
    elif isinstance(item, np.ndarray):
        return numpy_array_to_ocdata(item)
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
        return ocstring_to_py_string(<uint64_t>oc_ptr)
    elif type_id == OCNumberGetTypeID():
        return ocnumber_to_py_number(<uint64_t>oc_ptr)
    elif type_id == OCBooleanGetTypeID():
        return ocboolean_to_py_bool(<uint64_t>oc_ptr)
    elif type_id == OCDataGetTypeID():
        # Default to uint8 array for OCData
        return ocdata_to_numpy_array(<uint64_t>oc_ptr, np.uint8)
    elif type_id == OCArrayGetTypeID():
        return ocarray_to_py_list(<uint64_t>oc_ptr)
    elif type_id == OCDictionaryGetTypeID():
        return ocdictionary_to_py_dict(<uint64_t>oc_ptr)
    elif type_id == OCSetGetTypeID():
        return ocset_to_py_set(<uint64_t>oc_ptr)
    elif type_id == OCIndexArrayGetTypeID():
        return ocindexarray_to_py_list(<uint64_t>oc_ptr)
    elif type_id == OCIndexSetGetTypeID():
        return ocindexset_to_py_set(<uint64_t>oc_ptr)
    elif type_id == OCIndexPairSetGetTypeID():
        return ocindexpairset_to_py_dict(<uint64_t>oc_ptr)
    else:
        # Unknown OCType (could be from SITypes or other extensions)
        # Return as integer pointer for use by other libraries
        return <uint64_t>oc_ptr

# ====================================================================================
# String Helper Functions
# ====================================================================================

def py_string_to_ocstring(str py_string):
    """
    Convert a Python string to an OCStringRef.
    
    Args:
        py_string (str): Python string to convert
        
    Returns:
        OCStringRef: OCTypes string reference (needs to be released)
        
    Raises:
        RuntimeError: If string creation fails
    """
    cdef bytes utf8_bytes = py_string.encode('utf-8')
    cdef const char* c_string = utf8_bytes
    
    cdef OCStringRef oc_string = OCStringCreateWithCString(c_string)
    if oc_string == NULL:
        raise RuntimeError(f"Failed to create OCString from: {py_string}")
    
    return <uint64_t>oc_string

def ocstring_to_py_string(uint64_t oc_string_ptr):
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

def py_string_to_ocmutablestring(str py_string):
    """
    Convert a Python string to an OCMutableStringRef.
    
    Args:
        py_string (str): Python string to convert
        
    Returns:
        OCMutableStringRef: OCTypes mutable string reference (needs to be released)
    """
    cdef uint64_t immutable_string_ptr = py_string_to_ocstring(py_string)
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

def py_number_to_ocnumber(object py_number):
    """
    Convert a Python number (int, float, complex) to an OCNumberRef.
    
    Args:
        py_number: Python number (int, float, complex)
        
    Returns:
        OCNumberRef: OCTypes number reference (needs to be released)
    """
    cdef OCNumberRef oc_number = NULL
    cdef double_complex c_val
    
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
        c_val.real = py_number.real
        c_val.imag = py_number.imag
        oc_number = OCNumberCreateWithDoubleComplex(c_val)
    else:
        raise TypeError(f"Unsupported number type: {type(py_number)}")
    
    if oc_number == NULL:
        raise RuntimeError(f"Failed to create OCNumber from: {py_number}")
    
    return <uint64_t>oc_number

def ocnumber_to_py_number(uint64_t oc_number_ptr):
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
            return complex(complex_val.real, complex_val.imag)
    
    # Fallback: try double extraction
    if OCNumberTryGetFloat64(oc_number, &double_val):
        return float(double_val)
    
    raise RuntimeError(f"Failed to extract value from OCNumber with type: {number_type}")

# ====================================================================================
# Boolean Helper Functions
# ====================================================================================

def py_bool_to_ocboolean(bint py_bool):
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

def ocboolean_to_py_bool(uint64_t oc_boolean_ptr):
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

def numpy_array_to_ocdata(object numpy_array):
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

def py_list_to_ocarray(list py_list):
    """
    Convert a Python list to an OCArrayRef.
    
    Args:
        py_list (list): Python list to convert
        
    Returns:
        OCArrayRef: OCTypes array reference (needs to be released)
        
    Raises:
        RuntimeError: If array creation fails
    """
    cdef OCMutableArrayRef mutable_array = OCArrayCreateMutable(0, NULL)
    cdef uint64_t oc_item_ptr = 0
    
    if mutable_array == NULL:
        raise RuntimeError("Failed to create OCMutableArray")
    
    # Add each element to the array
    for item in py_list:
        oc_item_ptr = 0
        
        try:
            # Handle collections explicitly to avoid circular dependencies
            if isinstance(item, list):
                oc_item_ptr = py_list_to_ocarray(item)
            elif isinstance(item, dict):
                oc_item_ptr = py_dict_to_ocdictionary(item)
            elif isinstance(item, set):
                oc_item_ptr = py_set_to_ocset(item)
            elif isinstance(item, str):
                oc_item_ptr = py_string_to_ocstring(item)
            elif isinstance(item, bool):  # Check bool before int (bool is subclass of int)
                oc_item_ptr = py_bool_to_ocboolean(item)
            elif isinstance(item, (int, float, complex)):
                oc_item_ptr = py_number_to_ocnumber(item)
            elif isinstance(item, np.ndarray):
                oc_item_ptr = numpy_array_to_ocdata(item)
            else:
                raise TypeError(f"Unsupported item type for array: {type(item)}")
            
            # Add to array
            OCArrayAppendValue(mutable_array, <const void*>oc_item_ptr)
            
            # Release our reference (array retains it)
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

def ocarray_to_py_list(uint64_t oc_array_ptr):
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
        
        # Use generic converter that handles known and unknown OCTypes
        py_item = convert_octype_to_python(item_ptr)
        result.append(py_item)
    
    return result

def py_list_to_ocmutablearray(list py_list):
    """
    Convert a Python list to an OCMutableArrayRef.
    
    Args:
        py_list (list): Python list to convert
        
    Returns:
        OCMutableArrayRef: OCTypes mutable array reference (needs to be released)
    """
    cdef OCMutableArrayRef mutable_array = OCArrayCreateMutable(0, NULL)
    cdef uint64_t oc_item_ptr = 0
    
    if mutable_array == NULL:
        raise RuntimeError("Failed to create OCMutableArray")
    
    # Add each element to the array
    for item in py_list:
        oc_item_ptr = 0
        
        try:
            # Handle collections explicitly to avoid circular dependencies
            if isinstance(item, list):
                oc_item_ptr = py_list_to_ocarray(item)
            elif isinstance(item, dict):
                oc_item_ptr = py_dict_to_ocdictionary(item)
            elif isinstance(item, set):
                oc_item_ptr = py_set_to_ocset(item)
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

def py_dict_to_ocdictionary(dict py_dict):
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
            oc_key_ptr = py_string_to_ocstring(str_key)
            
            # Convert value
            # Handle collections explicitly to avoid circular dependencies
            if isinstance(value, list):
                oc_value_ptr = py_list_to_ocarray(value)
            elif isinstance(value, dict):
                oc_value_ptr = py_dict_to_ocdictionary(value)
            elif isinstance(value, set):
                oc_value_ptr = py_set_to_ocset(value)
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

def ocdictionary_to_py_dict(uint64_t oc_dict_ptr):
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
            
            py_key = ocstring_to_py_string(<uint64_t>keys[i])
            
            # Convert value using extensible converter that handles all OCTypes
            py_value = convert_octype_to_python(values[i])
            
            result[py_key] = py_value
        
        return result
        
    finally:
        if keys != NULL:
            free(keys)
        if values != NULL:
            free(values)

def py_dict_to_ocmutabledictionary(dict py_dict):
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
            oc_key_ptr = py_string_to_ocstring(str_key)
            
            # Convert value
            # Handle collections explicitly to avoid circular dependencies
            if isinstance(value, list):
                oc_value_ptr = py_list_to_ocarray(value)
            elif isinstance(value, dict):
                oc_value_ptr = py_dict_to_ocdictionary(value)
            elif isinstance(value, set):
                oc_value_ptr = py_set_to_ocset(value)
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

def py_set_to_ocset(set py_set):
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

def ocset_to_py_set(uint64_t oc_set_ptr):
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
            result.add(ocstring_to_py_string(<uint64_t>item_ptr))
        elif type_id == OCNumberGetTypeID():
            result.add(ocnumber_to_py_number(<uint64_t>item_ptr))
        elif type_id == OCBooleanGetTypeID():
            result.add(ocboolean_to_py_bool(<uint64_t>item_ptr))
        # Note: Can't add arrays/dicts to sets as they're not hashable
    
    OCRelease(<const void*>values_array)
    return result

def py_set_to_ocmutableset(set py_set):
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

def py_list_to_ocindexarray(list py_list):
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

def ocindexarray_to_py_list(uint64_t oc_indexarray_ptr):
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

def py_set_to_ocindexset(set py_set):
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

def ocindexset_to_py_set(uint64_t oc_indexset_ptr):
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

def py_dict_to_ocindexpairset(dict py_dict):
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

def ocindexpairset_to_py_dict(uint64_t oc_indexpairset_ptr):
    """
    Convert an OCIndexPairSetRef to a Python dict[int, int].
    
    Note: This function has very limited functionality because OCIndexPairSet 
    doesn't provide a way to iterate over all pairs. You need to know the 
    indices in advance to look up their values.
    
    Args:
        oc_indexpairset_ptr (uint64_t): Pointer to OCIndexPairSetRef
        
    Returns:
        dict[int, int]: Python dictionary (empty due to API limitations)
        
    Raises:
        ValueError: If the OCIndexPairSetRef is NULL
    """
    cdef OCIndexPairSetRef oc_indexpairset = <OCIndexPairSetRef>oc_indexpairset_ptr
    if oc_indexpairset == NULL:
        raise ValueError("OCIndexPairSetRef is NULL")
    
    # OCIndexPairSet doesn't provide pair iteration, so we return empty dict
    # This is a limitation of the OCTypes API - you need to know indices 
    # in advance to call OCIndexPairSetValueForIndex()
    return {}

# ====================================================================================
# Mutable Data Helper Functions
# ====================================================================================

def numpy_array_to_ocmutabledata(object numpy_array):
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
# Type Introspection Helper Functions
# ====================================================================================

def octype_get_type_id(uint64_t oc_object_ptr):
    """
    Get the type ID of an OCTypes object.
    
    Args:
        oc_object_ptr (uint64_t): Pointer to any OCTypes object
        
    Returns:
        int: OCTypeID value
        
    Raises:
        ValueError: If the object pointer is NULL
    """
    if oc_object_ptr == 0:
        raise ValueError("OCTypes object pointer is NULL")
    
    return int(OCGetTypeID(<const void*>oc_object_ptr))

def octype_equal(uint64_t oc_object1_ptr, uint64_t oc_object2_ptr):
    """
    Test equality between two OCTypes objects.
    
    Args:
        oc_object1_ptr (uint64_t): Pointer to first OCTypes object
        oc_object2_ptr (uint64_t): Pointer to second OCTypes object
        
    Returns:
        bool: True if objects are equal, False otherwise
    """
    if oc_object1_ptr == 0 and oc_object2_ptr == 0:
        return True
    if oc_object1_ptr == 0 or oc_object2_ptr == 0:
        return False
        
    return bool(OCTypeEqual(<const void*>oc_object1_ptr, <const void*>oc_object2_ptr))

def octype_deep_copy(uint64_t oc_object_ptr):
    """
    Create a deep copy of an OCTypes object.
    
    Args:
        oc_object_ptr (uint64_t): Pointer to OCTypes object to copy
        
    Returns:
        uint64_t: Pointer to copied object (needs to be released)
        
    Raises:
        ValueError: If the object pointer is NULL
        RuntimeError: If copying fails
    """
    if oc_object_ptr == 0:
        raise ValueError("OCTypes object pointer is NULL")
    
    cdef void* copied_object = OCTypeDeepCopy(<const void*>oc_object_ptr)
    if copied_object == NULL:
        raise RuntimeError("Failed to create deep copy of OCTypes object")
    
    return <uint64_t>copied_object

# ====================================================================================
# Utility Functions
# ====================================================================================

def release_octype(uint64_t oc_object_ptr):
    """
    Release an OCTypes object.
    
    Args:
        oc_object_ptr (uint64_t): Pointer to any OCTypes object
    """
    if oc_object_ptr != 0:
        OCRelease(<const void*>oc_object_ptr)

def retain_octype(uint64_t oc_object_ptr):
    """
    Retain an OCTypes object.
    
    Args:
        oc_object_ptr (uint64_t): Pointer to any OCTypes object
        
    Returns:
        uint64_t: Same pointer (retained)
    """
    if oc_object_ptr != 0:
        OCRetain(<const void*>oc_object_ptr)
    return oc_object_ptr

def get_retain_count(uint64_t oc_object_ptr):
    """
    Get the retain count of an OCTypes object.
    
    Args:
        oc_object_ptr (uint64_t): Pointer to any OCTypes object
        
    Returns:
        int: Retain count
    """
    if oc_object_ptr == 0:
        return 0
    return OCTypeGetRetainCount(<const void*>oc_object_ptr)
