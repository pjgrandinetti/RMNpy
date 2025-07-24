# cython: language_level=3
"""
Minimal test to verify OCTypes C API declarations work.
"""

# Include the C headers directly
cdef extern from "OCTypes/OCString.h":
    ctypedef struct impl_OCString
    ctypedef const impl_OCString *OCStringRef

    # Function declarations
    OCStringRef OCStringCreateWithCString(const char *string)
    unsigned int OCStringGetTypeID()

cdef extern from "OCTypes/OCType.h":
    void OCRelease(const void *ptr)

def test_minimal():
    """Minimal test that creates a string and gets its type ID."""
    cdef OCStringRef test_string
    cdef const char* c_string = b"Hello"

    # Test basic string creation
    test_string = OCStringCreateWithCString(c_string)

    # Get type ID
    type_id = OCStringGetTypeID()

    # Clean up
    OCRelease(<const void*>test_string)

    return {"type_id": type_id}
