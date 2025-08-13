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
from rmnpy._c_api.sitypes cimport *

import cython

# Import Scalar class for proper SIScalar conversion
# Use duck typing instead of isinstance for better Cython performance and robustness
try:
    from rmnpy.wrappers.sitypes.scalar import Scalar
    SCALAR_AVAILABLE = True
    SCALAR_CLASS = Scalar  # Keep reference for _from_ref calls
except ImportError:
    SCALAR_AVAILABLE = False
    SCALAR_CLASS = None

# Import Unit class for proper SIUnit conversion
try:
    from rmnpy.wrappers.sitypes.unit import Unit
    UNIT_AVAILABLE = True
    UNIT_CLASS = Unit  # Keep reference for _from_ref calls
except ImportError:
    UNIT_AVAILABLE = False
    UNIT_CLASS = None

# Import Dimensionality class for proper SIDimensionality conversion
try:
    from rmnpy.wrappers.sitypes.dimensionality import Dimensionality
    DIMENSIONALITY_AVAILABLE = True
    DIMENSIONALITY_CLASS = Dimensionality  # Keep reference for _from_ref calls
except ImportError:
    DIMENSIONALITY_AVAILABLE = False
    DIMENSIONALITY_CLASS = None

# ====================================================================================
# Debug Helper Functions
# ====================================================================================

def debug_octype_ids():
    """
    Debug function to discover OCTypeID mappings.
    """
    cdef list debug_info = []

    # Get all known type IDs
    debug_info.append("OCTypeID Mappings:")
    debug_info.append(f"  OCString: {OCStringGetTypeID()}")
    debug_info.append(f"  OCNumber: {OCNumberGetTypeID()}")
    debug_info.append(f"  OCBoolean: {OCBooleanGetTypeID()}")
    debug_info.append(f"  OCData: {OCDataGetTypeID()}")
    debug_info.append(f"  OCArray: {OCArrayGetTypeID()}")
    debug_info.append(f"  OCDictionary: {OCDictionaryGetTypeID()}")
    debug_info.append(f"  OCSet: {OCSetGetTypeID()}")
    debug_info.append(f"  OCIndexArray: {OCIndexArrayGetTypeID()}")
    debug_info.append(f"  OCIndexSet: {OCIndexSetGetTypeID()}")
    debug_info.append(f"  OCIndexPairSet: {OCIndexPairSetGetTypeID()}")
    debug_info.append(f"  SIScalar: {SIScalarGetTypeID()}")
    debug_info.append(f"  SIUnit: {SIUnitGetTypeID()}")
    debug_info.append(f"  SIDimensionality: {SIDimensionalityGetTypeID()}")

    return "\n".join(debug_info)

def debug_number_creation(py_number):
    """
    Debug function to test individual number creation.
    """
    try:
        oc_num_ptr = pynumber_to_ocnumber(py_number)
        type_id = OCGetTypeID(<const void*>oc_num_ptr)
        type_name = OCTypeNameFromTypeID(type_id)
        type_name_str = type_name.decode('utf-8') if type_name else 'Unknown'
        return f"Number {py_number} -> Ptr: {oc_num_ptr}, Type: {type_id} ({type_name_str})"
    except Exception as e:
        return f"Number {py_number} -> Error: {e}"

def debug_minimal_array_creation(double value):
    """Debug function to test minimal array creation with one number."""
    # Declare all variables at the beginning
    cdef uint64_t num_ptr, count
    cdef OCTypeID num_type_id, retrieved_type_id
    cdef OCMutableArrayRef mutable_array
    cdef OCArrayRef immutable_array
    cdef const void* retrieved_ptr
    cdef const char* type_name

    print(f"=== Creating array with single number: {value} ===")

    # Step 1: Create the number
    print("Step 1: Creating number...")
    num_ptr = pynumber_to_ocnumber(value)
    num_type_id = OCGetTypeID(<const void*>num_ptr)
    print(f"Number created: ptr={num_ptr}, typeID={num_type_id}")

    # Step 2: Create mutable array
    print("Step 2: Creating mutable array...")
    mutable_array = OCArrayCreateMutable(0, &kOCTypeArrayCallBacks)
    if mutable_array == NULL:
        print("ERROR: Failed to create mutable array")
        return 0
    print(f"Mutable array created: {<uint64_t>mutable_array}")

    # Step 3: Add number to array
    print("Step 3: Adding number to array...")
    OCArrayAppendValue(mutable_array, <const void*>num_ptr)
    print("Number added to array")

    # Step 4: Check what's in the array
    print("Step 4: Checking array contents...")
    count = OCArrayGetCount(mutable_array)
    print(f"Array count: {count}")

    if count > 0:
        retrieved_ptr = OCArrayGetValueAtIndex(mutable_array, 0)
        retrieved_type_id = OCGetTypeID(retrieved_ptr)
        type_name = OCTypeNameFromTypeID(retrieved_type_id)
        type_name_str = type_name.decode('utf-8') if type_name else 'Unknown'
        print(f"Retrieved element: ptr={<uint64_t>retrieved_ptr}, typeID={retrieved_type_id} ({type_name_str})")

        # Compare pointers
        if <uint64_t>retrieved_ptr == num_ptr:
            print("✓ Pointers match")
        else:
            print("✗ Pointers don't match!")

        # Compare type IDs
        if retrieved_type_id == num_type_id:
            print("✓ Type IDs match")
        else:
            print(f"✗ Type IDs don't match! Original={num_type_id}, Retrieved={retrieved_type_id}")

    # Release references
    OCRelease(<const void*>num_ptr)

    # Step 5: Create immutable copy
    print("Step 5: Creating immutable copy...")
    immutable_array = OCArrayCreateCopy(<OCArrayRef>mutable_array)
    OCRelease(<const void*>mutable_array)

    if immutable_array == NULL:
        print("ERROR: Failed to create immutable array")
        return 0

    print(f"Immutable array created: {<uint64_t>immutable_array}")
    return <uint64_t>immutable_array

def debug_direct_number(double value):
    """Debug function to test individual number creation."""
    print(f"Creating number from: {value}")

    cdef uint64_t num_ptr = pynumber_to_ocnumber(value)
    print(f"Created pointer: {num_ptr}")

    cdef OCTypeID type_id = OCGetTypeID(<const void*>num_ptr)
    cdef const char* type_name = OCTypeNameFromTypeID(type_id)
    type_name_str = type_name.decode('utf-8') if type_name else 'Unknown'

    print(f"OCTypeID: {type_id} ({type_name_str})")
    print(f"Expected OCNumber TypeID: {OCNumberGetTypeID()}")

    if type_id == OCNumberGetTypeID():
        print("✓ Correctly created OCNumber")
        number_type = OCNumberGetType(<OCNumberRef>num_ptr)
        print(f"Internal OCNumberType: {number_type}")
    else:
        print("✗ WRONG TYPE! Created something else")

    return num_ptr

def debug_array_elements(uint64_t oc_array_ptr):
    """
    Debug function to examine array elements without full conversion.
    """
    cdef OCArrayRef oc_array = <OCArrayRef>oc_array_ptr
    if oc_array == NULL:
        return "Array is NULL"

    cdef uint64_t count = OCArrayGetCount(oc_array)
    cdef list debug_info = []
    debug_info.append(f"Array count: {count}")

    # Add type ID reference info
    debug_info.append(f"Reference OCNumber TypeID: {OCNumberGetTypeID()}")
    debug_info.append(f"Reference OCString TypeID: {OCStringGetTypeID()}")
    debug_info.append(f"Reference OCBoolean TypeID: {OCBooleanGetTypeID()}")
    debug_info.append(f"Reference OCArray TypeID: {OCArrayGetTypeID()}")
    debug_info.append(f"Reference OCDictionary TypeID: {OCDictionaryGetTypeID()}")
    debug_info.append(f"Reference OCSet TypeID: {OCSetGetTypeID()}")

    cdef uint64_t i
    cdef const void* item_ptr
    cdef OCTypeID type_id
    cdef OCNumberRef num_ptr
    cdef double double_val
    cdef const char* type_name

    for i in range(count):
        item_ptr = OCArrayGetValueAtIndex(oc_array, i)
        if item_ptr == NULL:
            debug_info.append(f"  Element {i}: NULL")
            continue

        type_id = OCGetTypeID(item_ptr)
        type_name = OCTypeNameFromTypeID(type_id)
        type_name_str = type_name.decode('utf-8') if type_name else 'Unknown'
        debug_info.append(f"  Element {i}: Type={type_id} ({type_name_str})")

        # Check against all known types
        if type_id == OCStringGetTypeID():
            debug_info.append(f"    -> OCString")
            try:
                py_value = pystring_from_ocstring(<uint64_t>item_ptr)
                debug_info.append(f"    -> Value: '{py_value}'")
            except Exception as e:
                debug_info.append(f"    -> String conversion failed: {e}")
        elif type_id == OCNumberGetTypeID():
            debug_info.append(f"    -> This IS an OCNumber (OCTypeID matches)")
            num_ptr = <OCNumberRef>item_ptr
            number_type = OCNumberGetType(num_ptr)
            debug_info.append(f"    -> Internal OCNumberType: {number_type}")
            try:
                py_value = ocnumber_to_pynumber(<uint64_t>item_ptr)
                debug_info.append(f"    -> Value: {py_value}")
            except Exception as e:
                debug_info.append(f"    -> Number conversion failed: {e}")
        elif type_id == OCBooleanGetTypeID():
            debug_info.append(f"    -> OCBoolean")
            try:
                py_value = ocboolean_to_pybool(<uint64_t>item_ptr)
                debug_info.append(f"    -> Value: {py_value}")
            except Exception as e:
                debug_info.append(f"    -> Boolean conversion failed: {e}")
        elif type_id == OCArrayGetTypeID():
            debug_info.append(f"    -> OCArray (nested)")
        elif type_id == OCDictionaryGetTypeID():
            debug_info.append(f"    -> OCDictionary")
        elif type_id == OCDataGetTypeID():
            debug_info.append(f"    -> OCData")
        else:
            debug_info.append(f"    -> Unknown type")

    return "\n".join(debug_info)

def debug_convert_single_element(uint64_t oc_array_ptr, uint64_t index):
    """
    Debug function to convert a single array element without using convert_octype_to_python.
    """
    cdef OCArrayRef oc_array = <OCArrayRef>oc_array_ptr
    if oc_array == NULL:
        raise ValueError("Array is NULL")

    cdef const void* item_ptr = OCArrayGetValueAtIndex(oc_array, index)
    if item_ptr == NULL:
        return None

    # Test direct number conversion
    cdef OCTypeID type_id = OCGetTypeID(item_ptr)
    cdef OCTypeID number_type_id = OCNumberGetTypeID()

    if type_id == number_type_id:
        return ocnumber_to_pynumber(<uint64_t>item_ptr)
    else:
        return f"Type mismatch: element_type={type_id}, number_type={number_type_id}"

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
        return ocstring_create_with_pystring(item)
    elif isinstance(item, bool):  # Check bool before int (bool is subclass of int)
        return pybool_to_ocboolean(item)
    elif isinstance(item, (int, float, complex)):
        return pynumber_to_ocnumber(item)
    elif isinstance(item, np.ndarray):
        return numpy_array_to_ocdata(item)
    # Handle Scalar objects from RMNpy wrappers using duck typing
    # We use hasattr instead of isinstance for better Cython performance
    # and to avoid circular import issues with dynamically imported classes
    elif hasattr(item, 'value') and hasattr(item, 'unit'):
        # This looks like a Scalar object - convert to SIScalar
        return pyscalar_to_siscalar(item)
    # Handle Unit objects from RMNpy wrappers using duck typing
    elif hasattr(item, '_c_unit'):
        # This looks like a Unit object - convert to SIUnit
        return pyunit_to_siunit(item)
    # Handle Dimensionality objects from RMNpy wrappers using duck typing
    elif hasattr(item, '_dim_ref'):
        # This looks like a Dimensionality object - convert to SIDimensionality
        return pydimensionality_to_sidimensionality(item)
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
        return pystring_from_ocstring(<uint64_t>oc_ptr)
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
        return siscalar_to_pyscalar(<uint64_t>oc_ptr)
    elif type_id == SIUnitGetTypeID():
        return siunit_to_pyunit(<uint64_t>oc_ptr)
    elif type_id == SIDimensionalityGetTypeID():
        return sidimensionality_to_pydimensionality(<uint64_t>oc_ptr)
    else:
        # Unknown OCType (could be from SITypes or other extensions)
        # Return as integer pointer for use by other libraries
        return <uint64_t>oc_ptr

# ====================================================================================
# String Helper Functions
# ====================================================================================

def ocstring_create_with_pystring(py_string):
    """
    Create an OCStringRef from a Python string.

    Following C API naming convention: functions with "Create" transfer ownership to caller.
    The returned OCStringRef must be released with OCRelease().

    Args:
        py_string (str or None): Python string to convert, or None

    Returns:
        uint64_t: OCTypes string reference (caller owns, needs OCRelease), or 0 if py_string is None

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

def pystring_from_ocstring(uint64_t oc_string_ptr):
    """
    Extract a Python string from an OCStringRef.

    This function does not affect ownership - the OCStringRef is not released.

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

def pystring_to_ocmutablestring(str py_string):
    """
    Convert a Python string to an OCMutableStringRef.

    Args:
        py_string (str): Python string to convert

    Returns:
        OCMutableStringRef: OCTypes mutable string reference (needs to be released)
    """
    cdef uint64_t immutable_string_ptr = ocstring_create_with_pystring(py_string)
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

def pycomplex_to_ocnumber(double real_part, double imag_part):
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

def pynumber_to_ocnumber(py_number):
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
        return pycomplex_to_ocnumber(real_part, imag_part)
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

def pylist_to_ocarray(py_list):
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
                oc_item_ptr = pylist_to_ocarray(item)
            elif isinstance(item, dict):
                oc_item_ptr = pydict_to_ocdict(item)
            elif isinstance(item, set):
                oc_item_ptr = pyset_to_ocset(item)
            elif isinstance(item, str):
                oc_item_ptr = ocstring_create_with_pystring(item)
            elif isinstance(item, bool):  # Check bool before int (bool is subclass of int)
                oc_item_ptr = pybool_to_ocboolean(item)
            elif isinstance(item, (int, float, complex)):
                oc_item_ptr = pynumber_to_ocnumber(item)
            elif isinstance(item, np.ndarray):
                oc_item_ptr = numpy_array_to_ocdata(item)
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
            py_item = pystring_from_ocstring(<uint64_t>item_ptr)
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
            py_item = siscalar_to_pyscalar(<uint64_t>item_ptr)
        elif type_id == SIUnitGetTypeID():
            py_item = siunit_to_pyunit(<uint64_t>item_ptr)
        elif type_id == SIDimensionalityGetTypeID():
            py_item = sidimensionality_to_pydimensionality(<uint64_t>item_ptr)
        else:
            # Unknown OCType - return as integer pointer
            py_item = <uint64_t>item_ptr

        result.append(py_item)

    return result

def pylist_to_ocmutablearray(list py_list):
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
                oc_item_ptr = pylist_to_ocarray(item)
            elif isinstance(item, dict):
                oc_item_ptr = pydict_to_ocdict(item)
            elif isinstance(item, set):
                oc_item_ptr = pyset_to_ocset(item)
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

def pydict_to_ocdict(py_dict):
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
            oc_key_ptr = ocstring_create_with_pystring(str_key)

            # Convert value
            # Handle collections explicitly to avoid circular dependencies
            if isinstance(value, list):
                oc_value_ptr = pylist_to_ocarray(value)
            elif isinstance(value, dict):
                oc_value_ptr = pydict_to_ocdict(value)
            elif isinstance(value, set):
                oc_value_ptr = pyset_to_ocset(value)
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

            py_key = pystring_from_ocstring(<uint64_t>keys[i])

            # Convert value using extensible converter that handles all OCTypes
            py_value = convert_octype_to_python(values[i])

            result[py_key] = py_value

        return result

    finally:
        if keys != NULL:
            free(keys)
        if values != NULL:
            free(values)

def pydict_to_ocmutabledict(dict py_dict):
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
            oc_key_ptr = ocstring_create_with_pystring(str_key)

            # Convert value
            # Handle collections explicitly to avoid circular dependencies
            if isinstance(value, list):
                oc_value_ptr = pylist_to_ocarray(value)
            elif isinstance(value, dict):
                oc_value_ptr = pydict_to_ocdict(value)
            elif isinstance(value, set):
                oc_value_ptr = pyset_to_ocset(value)
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

def pyset_to_ocset(set py_set):
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
            result.add(pystring_from_ocstring(<uint64_t>item_ptr))
        elif type_id == OCNumberGetTypeID():
            result.add(ocnumber_to_pynumber(<uint64_t>item_ptr))
        elif type_id == OCBooleanGetTypeID():
            result.add(ocboolean_to_pybool(<uint64_t>item_ptr))
        elif type_id == SIScalarGetTypeID():
            # Convert SIScalar to Scalar object (if hashable)
            scalar_obj = siscalar_to_pyscalar(<uint64_t>item_ptr)
            try:
                result.add(scalar_obj)
            except TypeError:
                # If Scalar objects aren't hashable, fall back to tuple representation
                tuple_repr = siscalar_to_pytuple(<uint64_t>item_ptr)
                result.add(tuple_repr)
        elif type_id == SIUnitGetTypeID():
            # Convert SIUnit to Unit object (if hashable)
            unit_obj = siunit_to_pyunit(<uint64_t>item_ptr)
            try:
                result.add(unit_obj)
            except TypeError:
                # If Unit objects aren't hashable, convert to string representation
                # For now, add as integer pointer - this could be improved with string conversion
                result.add(f"SIUnit({<uint64_t>item_ptr})")
        elif type_id == SIDimensionalityGetTypeID():
            # Convert SIDimensionality to Dimensionality object (if hashable)
            dim_obj = sidimensionality_to_pydimensionality(<uint64_t>item_ptr)
            try:
                result.add(dim_obj)
            except TypeError:
                # If Dimensionality objects aren't hashable, convert to string representation
                # For now, add as integer pointer - this could be improved with string conversion
                result.add(f"SIDimensionality({<uint64_t>item_ptr})")
        # Note: Can't add arrays/dicts to sets as they're not hashable

    OCRelease(<const void*>values_array)
    return result

def pyset_to_ocmutableset(set py_set):
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

def pylist_to_ocindexarray(list py_list):
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

def pyset_to_ocindexset(set py_set):
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

def pydict_to_ocindexpairset(dict py_dict):
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
# SITypes Scalar Helper Functions
# ====================================================================================

def py_number_to_siscalar(py_number, str unit_string="1"):
    """
    Convert a Python number to an SIScalarRef.

    Args:
        py_number: Python number (int, float, complex)
        unit_string (str): Unit string expression (default: "1" for dimensionless)

    Returns:
        uint64_t: SIScalarRef as integer pointer (needs to be released)

    Raises:
        RuntimeError: If scalar creation fails
        TypeError: If number type is unsupported
    """
    cdef OCStringRef unit_oc_string = NULL
    cdef OCStringRef error_string = NULL
    cdef SIScalarRef si_scalar = NULL
    cdef double complex c_complex

    try:
        # Create unit string
        unit_oc_string = OCStringCreateWithCString(unit_string.encode('utf-8'))
        if unit_oc_string == NULL:
            raise RuntimeError(f"Failed to create unit string: {unit_string}")

        # Create scalar based on number type
        if isinstance(py_number, bool):
            # Handle bool as int (bool is subclass of int in Python)
            si_scalar = SIScalarCreateWithDouble(<double>(1 if py_number else 0), <SIUnitRef>unit_oc_string)
        elif isinstance(py_number, int):
            si_scalar = SIScalarCreateWithDouble(<double>py_number, <SIUnitRef>unit_oc_string)
        elif isinstance(py_number, float):
            si_scalar = SIScalarCreateWithDouble(<double>py_number, <SIUnitRef>unit_oc_string)
        elif isinstance(py_number, complex):
            # Create complex scalar
            c_complex = <double complex>py_number
            si_scalar = SIScalarCreateWithDoubleComplex(c_complex, <SIUnitRef>unit_oc_string)
        else:
            raise TypeError(f"Unsupported number type for SIScalar: {type(py_number)}")

        if si_scalar == NULL:
            raise RuntimeError(f"Failed to create SIScalar from: {py_number}")

        return <uint64_t>si_scalar

    except Exception:
        # Clean up on error
        if si_scalar != NULL:
            OCRelease(<const void*>si_scalar)
        raise
    finally:
        # Always clean up the unit string
        if unit_oc_string != NULL:
            OCRelease(<const void*>unit_oc_string)

def pyscalar_to_siscalar(object py_scalar):
    """
    Convert a Python Scalar object to an SIScalarRef.

    This function is designed to work with Scalar objects from the RMNpy.wrappers.scalar module.
    It uses the bypass approach to avoid cross-module Cython issues.

    Args:
        py_scalar: Python Scalar object

    Returns:
        uint64_t: SIScalarRef as integer pointer (needs to be released)

    Raises:
        RuntimeError: If scalar conversion fails
        TypeError: If input is not a Scalar object
    """
    # Check if it has the expected Scalar attributes
    if not hasattr(py_scalar, 'value') or not hasattr(py_scalar, 'unit'):
        raise TypeError(f"Expected Scalar object with 'value' and 'unit' attributes, got {type(py_scalar)}")

    try:
        # Extract value and unit from the Scalar object
        py_value = py_scalar.value
        py_unit = py_scalar.unit

        # Convert unit to string representation
        if hasattr(py_unit, '__str__'):
            unit_str = str(py_unit)
        else:
            unit_str = "1"  # fallback to dimensionless

        # Use the number-to-scalar conversion
        return py_number_to_siscalar(py_value, unit_str)

    except Exception as e:
        raise RuntimeError(f"Failed to convert Scalar to SIScalar: {e}")

def pynumber_to_siscalar_expression(py_number, str expression="1"):
    """
    Convert a Python number to an SIScalarRef using expression parsing.

    This is the preferred method as it uses SIScalarCreateFromExpression which
    bypasses the need for SIUnit objects and handles complex unit expressions.

    Args:
        py_number: Python number (int, float, complex)
        expression (str): Complete scalar expression (default: "1" for dimensionless)

    Returns:
        uint64_t: SIScalarRef as integer pointer (needs to be released)

    Raises:
        RuntimeError: If scalar creation fails
    """
    cdef OCStringRef expr_string = NULL
    cdef OCStringRef error_string = NULL
    cdef SIScalarRef si_scalar = NULL

    try:
        # Create the full expression string combining value and unit
        if isinstance(py_number, complex):
            # Handle complex numbers with special formatting for SITypes parser
            real_part = py_number.real
            imag_part = py_number.imag
            if imag_part >= 0:
                # Use proper complex syntax for SITypes: (real + imag * i)
                full_expr = f"({real_part} + {imag_part} * i) * {expression}"
            else:
                # Negative imaginary part
                full_expr = f"({real_part} - {abs(imag_part)} * i) * {expression}"
        else:
            # Simple number
            full_expr = f"{py_number} * {expression}"

        # Create expression string
        expr_string = OCStringCreateWithCString(full_expr.encode('utf-8'))
        if expr_string == NULL:
            raise RuntimeError(f"Failed to create expression string: {full_expr}")

        # Parse the expression to create scalar
        si_scalar = SIScalarCreateFromExpression(expr_string, &error_string)

        if si_scalar == NULL:
            error_msg = "Unknown error"
            if error_string != NULL:
                error_c_str = OCStringGetCString(error_string)
                if error_c_str != NULL:
                    error_msg = error_c_str.decode('utf-8')
                OCRelease(<const void*>error_string)
            raise RuntimeError(f"Failed to create SIScalar from expression '{full_expr}': {error_msg}")

        return <uint64_t>si_scalar

    except Exception:
        # Clean up on error
        if si_scalar != NULL:
            OCRelease(<const void*>si_scalar)
        raise
    finally:
        # Always clean up the expression string
        if expr_string != NULL:
            OCRelease(<const void*>expr_string)

def siscalar_to_pynumber(uint64_t si_scalar_ptr):
    """
    Convert an SIScalarRef to a Python number.

    Args:
        si_scalar_ptr (uint64_t): Pointer to SIScalarRef

    Returns:
        int/float/complex: Python number (loses unit information)

    Raises:
        ValueError: If the SIScalarRef is NULL
        RuntimeError: If value extraction fails
    """
    cdef SIScalarRef si_scalar = <SIScalarRef>si_scalar_ptr
    cdef double complex complex_val
    cdef double double_val

    if si_scalar == NULL:
        raise ValueError("SIScalarRef is NULL")

    try:
        # Check if it's complex
        if SIScalarIsComplex(si_scalar):
            complex_val = SIScalarDoubleComplexValue(si_scalar)
            return complex(complex_val.real, complex_val.imag)
        elif SIScalarIsReal(si_scalar):
            double_val = SIScalarDoubleValue(si_scalar)
            # Return as int if it's a whole number, otherwise float
            if double_val == int(double_val):
                return int(double_val)
            else:
                return float(double_val)
        else:
            # Fallback to double value
            double_val = SIScalarDoubleValue(si_scalar)
            return float(double_val)

    except Exception as e:
        raise RuntimeError(f"Failed to extract value from SIScalar: {e}")

def siscalar_to_pytuple(uint64_t si_scalar_ptr):
    """
    Convert an SIScalarRef to a Python (value, unit_string) tuple.

    Args:
        si_scalar_ptr (uint64_t): Pointer to SIScalarRef

    Returns:
        tuple: (number, unit_string) where number is int/float/complex and unit_string is str

    Raises:
        ValueError: If the SIScalarRef is NULL
        RuntimeError: If value or unit extraction fails
    """
    cdef SIScalarRef si_scalar = <SIScalarRef>si_scalar_ptr
    cdef OCStringRef unit_string
    cdef const char* unit_c_str

    if si_scalar == NULL:
        raise ValueError("SIScalarRef is NULL")

    try:
        # Extract the numeric value
        py_value = siscalar_to_pynumber(si_scalar_ptr)

        # Extract the unit string
        unit_string = SIScalarCopyUnitSymbol(si_scalar)
        if unit_string != NULL:
            unit_c_str = OCStringGetCString(unit_string)
            if unit_c_str != NULL:
                py_unit_string = unit_c_str.decode('utf-8')
                # SITypes uses space " " for dimensionless units - keep it as is
            else:
                py_unit_string = " "  # fallback to SITypes dimensionless representation
            OCRelease(<const void*>unit_string)
        else:
            py_unit_string = " "  # fallback for dimensionless

        return (py_value, py_unit_string)

    except Exception as e:
        raise RuntimeError(f"Failed to extract value and unit from SIScalar: {e}")

def siscalar_to_pyscalar(uint64_t si_scalar_ptr):
    """
    Convert an SIScalarRef to a Python numeric value.

    For coordinate arrays, we want numeric values that work with numpy,
    not full Scalar objects. This avoids circular import issues and
    provides the expected numeric behavior.

    Args:
        si_scalar_ptr (uint64_t): Pointer to SIScalarRef

    Returns:
        float/int: Python numeric value (loses unit information)

    Raises:
        ValueError: If the SIScalarRef is NULL
        RuntimeError: If value extraction fails
    """
    cdef SIScalarRef si_scalar = <SIScalarRef>si_scalar_ptr

    if si_scalar == NULL:
        raise ValueError("SIScalarRef is NULL")

    # Return numeric value directly - this is what coordinate arrays need
    return siscalar_to_pynumber(si_scalar_ptr)

def py_list_to_siscalar_ocarray(list py_list, str unit_expression="1"):
    """
    Convert a Python list of numbers to an OCArrayRef containing SIScalarRef objects.

    This function is specifically designed for creating coordinate arrays for SITypes
    functions like SIMonotonicDimensionCreate that expect OCArrayRef with SIScalarRef elements.

    Args:
        py_list (list): Python list of numbers
        unit_expression (str): Unit expression for all scalars (default: "1" for dimensionless)

    Returns:
        uint64_t: OCArrayRef containing SIScalarRef objects (needs to be released)

    Raises:
        RuntimeError: If array creation fails
        TypeError: If list contains unsupported types
    """
    cdef OCMutableArrayRef mutable_array = OCArrayCreateMutable(0, &kOCTypeArrayCallBacks)
    cdef uint64_t si_scalar_ptr = 0

    if mutable_array == NULL:
        raise RuntimeError("Failed to create OCMutableArray for SIScalar objects")

    # Add each element to the array as an SIScalar
    for item in py_list:
        si_scalar_ptr = 0

        try:
            # Convert to SIScalar using expression method (more robust)
            si_scalar_ptr = pynumber_to_siscalar_expression(item, unit_expression)

            # Add to array
            OCArrayAppendValue(mutable_array, <const void*>si_scalar_ptr)

            # Release our reference (array retains it with proper callbacks)
            OCRelease(<const void*>si_scalar_ptr)

        except Exception as e:
            if si_scalar_ptr != 0:
                OCRelease(<const void*>si_scalar_ptr)
            OCRelease(<const void*>mutable_array)
            raise RuntimeError(f"Failed to convert list item {item} to SIScalar: {e}")

    # Create immutable copy
    cdef OCArrayRef immutable_array = OCArrayCreateCopy(<OCArrayRef>mutable_array)
    OCRelease(<const void*>mutable_array)

    if immutable_array == NULL:
        raise RuntimeError("Failed to create immutable OCArray copy for SIScalar objects")

    return <uint64_t>immutable_array

def py_coordinate_list_to_siscalar_ocarray(list coordinates):
    """
    Convert a list of coordinate values (numbers or Scalars) to an OCArrayRef of SIScalarRef objects.

    This function is specifically designed for coordinate arrays in dimension constructors.
    It handles both plain numbers (converted to dimensionless SIScalars) and existing Scalar objects.

    Args:
        coordinates (list): List of coordinate values (numbers or Scalar objects)

    Returns:
        uint64_t: OCArrayRef containing SIScalarRef objects (needs to be released)

    Raises:
        RuntimeError: If array creation fails
        TypeError: If list contains unsupported types
    """
    cdef OCMutableArrayRef mutable_array = OCArrayCreateMutable(0, &kOCTypeArrayCallBacks)
    cdef uint64_t si_scalar_ptr = 0

    if mutable_array == NULL:
        raise RuntimeError("Failed to create OCMutableArray for coordinate SIScalars")

    # Add each coordinate to the array as an SIScalar
    for coord in coordinates:
        si_scalar_ptr = 0

        try:
            # Check if it's already a Scalar object (has value and unit attributes)
            if hasattr(coord, 'value') and hasattr(coord, 'unit'):
                # Convert Scalar object to SIScalar
                si_scalar_ptr = pyscalar_to_siscalar(coord)
            elif isinstance(coord, (int, float, complex)):
                # Convert plain number to dimensionless SIScalar using expression method
                si_scalar_ptr = pynumber_to_siscalar_expression(coord, "1")
            else:
                raise TypeError(f"Unsupported coordinate type: {type(coord)}. Expected number or Scalar object.")

            # Add to array
            OCArrayAppendValue(mutable_array, <const void*>si_scalar_ptr)

            # Release our reference (array retains it with proper callbacks)
            OCRelease(<const void*>si_scalar_ptr)

        except Exception as e:
            if si_scalar_ptr != 0:
                OCRelease(<const void*>si_scalar_ptr)
            OCRelease(<const void*>mutable_array)
            raise RuntimeError(f"Failed to convert coordinate {coord} to SIScalar: {e}")

    # Create immutable copy
    cdef OCArrayRef immutable_array = OCArrayCreateCopy(<OCArrayRef>mutable_array)
    OCRelease(<const void*>mutable_array)

    if immutable_array == NULL:
        raise RuntimeError("Failed to create immutable OCArray copy for coordinate SIScalars")

    return <uint64_t>immutable_array

# ====================================================================================
# SIUnit Helper Functions
# ====================================================================================

def pyunit_to_siunit(object py_unit):
    """
    Convert a Python Unit object to an SIUnitRef.

    Args:
        py_unit: Python Unit object

    Returns:
        uint64_t: SIUnitRef as integer pointer (needs to be released)

    Raises:
        RuntimeError: If unit conversion fails
        TypeError: If input is not a Unit object
    """
    # Check if it has the expected Unit attributes
    if not hasattr(py_unit, '_c_unit'):
        raise TypeError(f"Expected Unit object with '_c_unit' attribute, got {type(py_unit)}")

    # Extract the C unit reference and retain it
    cdef SIUnitRef c_unit = <SIUnitRef>(<uintptr_t>py_unit._c_unit)
    if c_unit == NULL:
        raise RuntimeError("Unit object contains NULL C reference")

    # Return retained reference
    return <uint64_t>OCRetain(<const void*>c_unit)

def siunit_to_pyunit(uint64_t si_unit_ptr):
    """
    Convert an SIUnitRef to a Python Unit object.

    Args:
        si_unit_ptr (uint64_t): Pointer to SIUnitRef

    Returns:
        Unit: Python Unit object

    Raises:
        ValueError: If the SIUnitRef is NULL
        RuntimeError: If Unit class is not available or conversion fails
    """
    cdef SIUnitRef si_unit = <SIUnitRef>si_unit_ptr

    if si_unit == NULL:
        raise ValueError("SIUnitRef is NULL")

    if not UNIT_AVAILABLE:
        # Fallback to integer pointer if Unit class is not available
        return si_unit_ptr

    try:
        # Use the Unit class's _from_ref method to create a proper Unit object
        # We need to retain the reference since _from_ref takes ownership
        retained_ref = <SIUnitRef>OCRetain(<const void*>si_unit)
        return UNIT_CLASS._from_ref(<uint64_t>retained_ref)
    except Exception as e:
        raise RuntimeError(f"Failed to convert SIUnit to Unit: {e}")

# ====================================================================================
# SIDimensionality Helper Functions
# ====================================================================================

def pydimensionality_to_sidimensionality(object py_dimensionality):
    """
    Convert a Python Dimensionality object to an SIDimensionalityRef.

    Args:
        py_dimensionality: Python Dimensionality object

    Returns:
        uint64_t: SIDimensionalityRef as integer pointer (needs to be released)

    Raises:
        RuntimeError: If dimensionality conversion fails
        TypeError: If input is not a Dimensionality object
    """
    # Check if it has the expected Dimensionality attributes
    if not hasattr(py_dimensionality, '_dim_ref'):
        raise TypeError(f"Expected Dimensionality object with '_dim_ref' attribute, got {type(py_dimensionality)}")

    # Extract the C dimensionality reference and retain it
    cdef SIDimensionalityRef c_dim = <SIDimensionalityRef>(<uintptr_t>py_dimensionality._dim_ref)
    if c_dim == NULL:
        raise RuntimeError("Dimensionality object contains NULL C reference")

    # Return retained reference
    return <uint64_t>OCRetain(<const void*>c_dim)

def sidimensionality_to_pydimensionality(uint64_t si_dimensionality_ptr):
    """
    Convert an SIDimensionalityRef to a Python Dimensionality object.

    Args:
        si_dimensionality_ptr (uint64_t): Pointer to SIDimensionalityRef

    Returns:
        Dimensionality: Python Dimensionality object

    Raises:
        ValueError: If the SIDimensionalityRef is NULL
        RuntimeError: If Dimensionality class is not available or conversion fails
    """
    cdef SIDimensionalityRef si_dimensionality = <SIDimensionalityRef>si_dimensionality_ptr

    if si_dimensionality == NULL:
        raise ValueError("SIDimensionalityRef is NULL")

    if not DIMENSIONALITY_AVAILABLE:
        # Fallback to integer pointer if Dimensionality class is not available
        return si_dimensionality_ptr

    try:
        # Use the Dimensionality class's _from_ref method to create a proper Dimensionality object
        # We need to retain the reference since _from_ref takes ownership
        retained_ref = <SIDimensionalityRef>OCRetain(<const void*>si_dimensionality)
        return DIMENSIONALITY_CLASS._from_ref(<uint64_t>retained_ref)
    except Exception as e:
        raise RuntimeError(f"Failed to convert SIDimensionality to Dimensionality: {e}")
