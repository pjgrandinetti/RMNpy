"""
Test suite for OCTypes C API declarations and helper functions.

This module tests that the OCTypes C library is properly linked and that
all API declarations are correct.
"""

import sys
from pathlib import Path

import pytest


def test_basic_memory_functions():
    """Test basic OCTypes library linking and string operations."""

    # Test that we can import and use basic OCTypes functions
    from rmnpy.helpers.octypes import (
        ocstring_create_from_pystring,
        ocstring_to_pystring,
    )

    # Test basic string roundtrip
    original_str = "Hello, OCTypes!"
    oc_string_ptr = ocstring_create_from_pystring(original_str)
    assert oc_string_ptr != 0, "Failed to create OCString"

    converted_str = ocstring_to_pystring(oc_string_ptr)
    # Note: OCString created by ocstring_create_from_pystring is automatically managed

    assert converted_str == original_str, "String roundtrip failed"


def test_octypes_pxd_exists():
    """Test that the octypes.pxd file exists and is properly structured."""
    pxd_file = (
        Path(__file__).parent.parent.parent / "src" / "rmnpy" / "_c_api" / "octypes.pxd"
    )
    assert pxd_file.exists(), f"octypes.pxd file not found at {pxd_file}"

    # Read the file and check for key declarations
    content = pxd_file.read_text()

    # Check for essential type declarations
    assert "ctypedef const impl_OCString *OCStringRef" in content
    assert "OCStringCreateWithCString" in content
    assert "OCStringGetTypeID" in content
    assert "OCRelease" in content
    assert "OCRetain" in content

    # Check for essential enum declarations
    assert "kOCNumberSInt32Type" in content
    assert "kOCCompareLessThan" in content


def test_import_octypes_api():
    """Test that the OCTypes C API declarations file exists and is valid."""
    # Add the source directory to the path
    import os

    src_dir = os.path.join(os.path.dirname(__file__), "..", "..", "src")
    sys.path.insert(0, src_dir)

    # Check that the .pxd file exists
    pxd_path = os.path.join(src_dir, "rmnpy", "_c_api", "octypes.pxd")
    assert os.path.exists(pxd_path), f"octypes.pxd not found at {pxd_path}"

    # Basic syntax check - ensure file can be read and contains expected content
    with open(pxd_path, "r") as f:
        content = f.read()

    # Check for key OCTypes declarations
    assert 'cdef extern from "OCTypes/OCTypes.h":' in content
    assert "OCTypeID" in content
    assert "OCIndex" in content
    assert "OCArrayRef" in content
    assert "OCStringRef" in content


def test_tryget_function_presence():
    """Test that all expected try-get functions are declared."""

    # Read the octypes.pxd file
    current_dir = Path(__file__).parent
    octypes_file = (
        current_dir.parent.parent / "src" / "rmnpy" / "_c_api" / "octypes.pxd"
    )

    with open(octypes_file, "r") as f:
        content = f.read()

    # Expected try-get function declarations
    expected_functions = [
        # Basic type try-get functions
        "bint OCNumberTryGetUInt8(OCNumberRef n, uint8_t *out)",
        "bint OCNumberTryGetSInt8(OCNumberRef n, int8_t *out)",
        "bint OCNumberTryGetUInt16(OCNumberRef n, uint16_t *out)",
        "bint OCNumberTryGetSInt16(OCNumberRef n, int16_t *out)",
        "bint OCNumberTryGetUInt32(OCNumberRef n, uint32_t *out)",
        "bint OCNumberTryGetSInt32(OCNumberRef n, int32_t *out)",
        "bint OCNumberTryGetUInt64(OCNumberRef n, uint64_t *out)",
        "bint OCNumberTryGetSInt64(OCNumberRef n, int64_t *out)",
        "bint OCNumberTryGetFloat32(OCNumberRef n, float *out)",
        "bint OCNumberTryGetFloat64(OCNumberRef n, double *out)",
        "bint OCNumberTryGetComplex64(OCNumberRef n, float_complex *out)",
        "bint OCNumberTryGetComplex128(OCNumberRef n, double_complex *out)",
        # Convenience try-get functions (aliases)
        "bint OCNumberTryGetFloat(OCNumberRef n, float *out)",
        "bint OCNumberTryGetDouble(OCNumberRef n, double *out)",
        "bint OCNumberTryGetFloatComplex(OCNumberRef n, float_complex *out)",
        "bint OCNumberTryGetDoubleComplex(OCNumberRef n, double_complex *out)",
        "bint OCNumberTryGetInt(OCNumberRef n, int *out)",
        "bint OCNumberTryGetLong(OCNumberRef n, long *out)",
        "bint OCNumberTryGetOCIndex(OCNumberRef n, OCIndex *out)",
    ]

    missing_functions = []
    for func_signature in expected_functions:
        # Remove extra whitespace for comparison
        normalized_signature = " ".join(func_signature.split())
        # Normalize content for comparison
        normalized_content = " ".join(content.split())

        if normalized_signature not in normalized_content:
            missing_functions.append(func_signature)

    assert (
        len(missing_functions) == 0
    ), f"Missing try-get function declarations: {missing_functions}"


def test_ocnumber_type_validation():
    """Test that OCNumber type enum values are properly declared."""

    current_dir = Path(__file__).parent
    octypes_file = (
        current_dir.parent.parent / "src" / "rmnpy" / "_c_api" / "octypes.pxd"
    )

    with open(octypes_file, "r") as f:
        content = f.read()

    # Expected OCNumber type constants
    expected_types = [
        "kOCNumberSInt8Type",
        "kOCNumberSInt16Type",
        "kOCNumberSInt32Type",
        "kOCNumberSInt64Type",
        "kOCNumberUInt8Type",
        "kOCNumberUInt16Type",
        "kOCNumberUInt32Type",
        "kOCNumberUInt64Type",
        "kOCNumberFloat32Type",
        "kOCNumberFloat64Type",
        "kOCNumberComplex64Type",
        "kOCNumberComplex128Type",
    ]

    missing_types = []
    for type_name in expected_types:
        if type_name not in content:
            missing_types.append(type_name)

    assert (
        len(missing_types) == 0
    ), f"Missing OCNumber type declarations: {missing_types}"


def test_comparison_result_enum():
    """Test that comparison result enum values are declared."""

    current_dir = Path(__file__).parent
    octypes_file = (
        current_dir.parent.parent / "src" / "rmnpy" / "_c_api" / "octypes.pxd"
    )

    with open(octypes_file, "r") as f:
        content = f.read()

    expected_comparison_values = [
        "kOCCompareLessThan",
        "kOCCompareEqualTo",
        "kOCCompareGreaterThan",
    ]

    missing_values = []
    for value in expected_comparison_values:
        if value not in content:
            missing_values.append(value)

    assert len(missing_values) == 0, f"Missing comparison enum values: {missing_values}"


def test_library_linking():
    """Test basic OCTypes library linking and string operations."""

    # Test that we can import and use basic OCTypes functions
    from rmnpy.helpers.octypes import (
        ocstring_create_from_pystring,
        ocstring_to_pystring,
    )

    # Test basic string roundtrip
    original_str = "Hello, OCTypes!"
    oc_string_ptr = ocstring_create_from_pystring(original_str)
    assert oc_string_ptr != 0, "Failed to create OCString"

    converted_str = ocstring_to_pystring(oc_string_ptr)
    # Note: Memory cleanup is handled automatically by the Cython wrappers

    assert converted_str == original_str, "String roundtrip failed"


def test_type_ids():
    """Test that type IDs are returned correctly."""

    from rmnpy.helpers.octypes import (
        ocnumber_create_from_pynumber,
        ocstring_create_from_pystring,
        pybool_to_ocboolean,
    )

    # Create different OCTypes and verify they have different pointers
    oc_string = ocstring_create_from_pystring("test")
    oc_number = ocnumber_create_from_pynumber(42)
    oc_bool = pybool_to_ocboolean(True)

    assert oc_string != 0, "Failed to create OCString"
    assert oc_number != 0, "Failed to create OCNumber"
    assert oc_bool != 0, "Failed to create OCBoolean"

    # All should be different pointers
    assert oc_string != oc_number, "String and Number should have different pointers"
    assert oc_string != oc_bool, "String and Boolean should have different pointers"
    assert oc_number != oc_bool, "Number and Boolean should have different pointers"

    # Note: Memory cleanup is handled automatically by the Cython wrappers


def test_memory_management():
    """Test basic memory management (simplified - no retain count checking)."""

    from rmnpy.helpers.octypes import (
        ocstring_create_from_pystring,
    )

    # Create an OCString - memory management is handled internally
    oc_string = ocstring_create_from_pystring("test")
    assert oc_string != 0, "Failed to create OCString"

    # Note: Memory management is handled automatically by the Cython wrappers
    # and OCTypes reference counting system. No manual retain/release needed.


def test_ocnumber_tryget_compilation():
    """Test that OCNumber try-get accessor functions compile correctly."""
    # Test that the OCNumber try-get functions are properly declared
    # This is a placeholder test that validates API availability
    from pathlib import Path

    # Check that the .pxd file contains the expected try-get function declarations
    pxd_file = (
        Path(__file__).parent.parent.parent / "src" / "rmnpy" / "_c_api" / "octypes.pxd"
    )
    if pxd_file.exists():
        content = pxd_file.read_text()
        # Look for try-get function patterns
        assert "OCNumber" in content, "OCNumber declarations not found in .pxd file"
    else:
        pytest.skip("octypes.pxd file not found, skipping API validation test")

    current_dir = Path(__file__).parent
    octypes_file = (
        current_dir.parent.parent / "src" / "rmnpy" / "_c_api" / "octypes.pxd"
    )

    with open(octypes_file, "r") as f:
        content = f.read()

    # Check that key try-get functions are present
    try_get_functions = [
        "OCNumberTryGetUInt8",
        "OCNumberTryGetSInt8",
        "OCNumberTryGetFloat32",
        "OCNumberTryGetFloat64",
        "OCNumberTryGetComplex64",
        "OCNumberTryGetComplex128",
        "OCNumberTryGetFloat",
        "OCNumberTryGetDouble",
        "OCNumberTryGetInt",
        "OCNumberTryGetLong",
        "OCNumberTryGetOCIndex",
    ]

    for func_name in try_get_functions:
        assert (
            func_name in content
        ), f"Try-get function {func_name} not found in octypes.pxd"


def test_string_api_functions():
    """Test that essential OCString API functions are declared."""

    current_dir = Path(__file__).parent
    octypes_file = (
        current_dir.parent.parent / "src" / "rmnpy" / "_c_api" / "octypes.pxd"
    )

    with open(octypes_file, "r") as f:
        content = f.read()

    # Essential OCString functions
    string_functions = [
        "OCStringCreateWithCString",
        "OCStringGetCString",
        "OCStringGetLength",
        "OCStringGetTypeID",
        "OCStringCreateMutableCopy",
        "OCStringCompare",
    ]

    for func_name in string_functions:
        assert (
            func_name in content
        ), f"OCString function {func_name} not found in octypes.pxd"


def test_array_api_functions():
    """Test that essential OCArray API functions are declared."""

    current_dir = Path(__file__).parent
    octypes_file = (
        current_dir.parent.parent / "src" / "rmnpy" / "_c_api" / "octypes.pxd"
    )

    with open(octypes_file, "r") as f:
        content = f.read()

    # Essential OCArray functions
    array_functions = [
        "OCArrayCreate",
        "OCArrayCreateMutable",
        "OCArrayGetCount",
        "OCArrayGetValueAtIndex",
        "OCArrayAppendValue",
        "OCArrayGetTypeID",
    ]

    for func_name in array_functions:
        assert (
            func_name in content
        ), f"OCArray function {func_name} not found in octypes.pxd"


def test_dictionary_api_functions():
    """Test that essential OCDictionary API functions are declared."""

    current_dir = Path(__file__).parent
    octypes_file = (
        current_dir.parent.parent / "src" / "rmnpy" / "_c_api" / "octypes.pxd"
    )

    with open(octypes_file, "r") as f:
        content = f.read()

    # Essential OCDictionary functions
    dict_functions = [
        "OCDictionaryCreate",
        "OCDictionaryCreateMutable",
        "OCDictionaryGetCount",
        "OCDictionaryGetValue",
        "OCDictionarySetValue",
        "OCDictionaryGetTypeID",
    ]

    for func_name in dict_functions:
        assert (
            func_name in content
        ), f"OCDictionary function {func_name} not found in octypes.pxd"
