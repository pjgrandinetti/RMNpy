# cython: language_level=3
"""
OCTypes C API declarations for Cython

This file contains Cython external declarations for the OCTypes C library.
It defines the C types, structures, and functions needed to interface with
OCTypes from Python using Cython.
"""

from libc.stddef cimport size_t
from libc.stdint cimport (
    int8_t,
    int16_t,
    int32_t,
    int64_t,
    uint8_t,
    uint16_t,
    uint32_t,
    uint64_t,
)
from libc.stdio cimport FILE


# Complex number types (C99 complex)
cdef extern from "complex.h":
    ctypedef struct float_complex "float complex":
        pass
    ctypedef struct double_complex "double complex":
        pass

# Forward declarations of opaque structs
cdef extern from "OCTypes/OCTypes.h":
    # Forward declarations for all opaque struct types
    ctypedef struct impl_OCType
    ctypedef struct impl_OCString
    ctypedef struct impl_OCArray
    ctypedef struct impl_OCSet
    ctypedef struct impl_OCDictionary
    ctypedef struct impl_OCBoolean
    ctypedef struct impl_OCData
    ctypedef struct impl_OCNumber
    ctypedef struct impl_OCIndexSet
    ctypedef struct impl_OCIndexArray
    ctypedef struct impl_OCIndexPairSet

    # Basic type definitions
    ctypedef uint32_t OCTypeID
    ctypedef signed long OCIndex
    ctypedef unsigned long OCOptionFlags

    # Range structure
    ctypedef struct OCRange:
        OCIndex location
        OCIndex length

    # Ref typedefs (const pointers)
    ctypedef const impl_OCType *OCTypeRef
    ctypedef const impl_OCString *OCStringRef
    ctypedef const impl_OCArray *OCArrayRef
    ctypedef const impl_OCSet *OCSetRef
    ctypedef const impl_OCDictionary *OCDictionaryRef
    ctypedef const impl_OCBoolean *OCBooleanRef
    ctypedef const impl_OCData *OCDataRef
    ctypedef const impl_OCNumber *OCNumberRef
    ctypedef const impl_OCIndexSet *OCIndexSetRef
    ctypedef const impl_OCIndexArray *OCIndexArrayRef
    ctypedef const impl_OCIndexPairSet *OCIndexPairSetRef

    # Mutable Ref typedefs (non-const pointers)
    ctypedef impl_OCArray *OCMutableArrayRef
    ctypedef impl_OCSet *OCMutableSetRef
    ctypedef impl_OCData *OCMutableDataRef
    ctypedef impl_OCDictionary *OCMutableDictionaryRef
    ctypedef impl_OCString *OCMutableStringRef
    ctypedef impl_OCIndexSet *OCMutableIndexSetRef
    ctypedef impl_OCIndexArray *OCMutableIndexArrayRef
    ctypedef impl_OCIndexPairSet *OCMutableIndexPairSetRef

    # Comparison and option types
    ctypedef enum OCComparisonResult:
        kOCCompareLessThan = -1
        kOCCompareEqualTo = 0
        kOCCompareGreaterThan = 1
        kOCCompareUnequalDimensionalities = 2
        kOCCompareNoSingleValue = 3
        kOCCompareError = 99

    ctypedef OCComparisonResult (*OCComparatorFunction)(const void *val1,
                                                        const void *val2,
                                                        void *context)

    ctypedef OCOptionFlags OCStringCompareFlags

    # Common constants
    cdef enum:
        kOCNotFound = -1
        kOCNotATypeID = 0

# Core OCType functions
cdef extern from "OCTypes/OCType.h":
    # Type introspection
    OCTypeID OCGetTypeID(const void *obj)
    const char *OCTypeNameFromTypeID(OCTypeID typeID)

    # Memory management
    const void *OCRetain(const void *ptr)
    void OCRelease(const void *ptr)
    int OCTypeGetRetainCount(const void *ptr)

    # Object operations
    bint OCTypeEqual(const void *theType1, const void *theType2)
    void *OCTypeDeepCopy(const void *obj)
    void *OCTypeDeepCopyMutable(const void *obj)
    OCStringRef OCTypeCopyFormattingDesc(const void *ptr)

# OCString functions
cdef extern from "OCTypes/OCString.h":
    # Type identifier
    OCTypeID OCStringGetTypeID()

    # String creation
    OCStringRef OCStringCreateWithCString(const char *string)
    OCMutableStringRef OCStringCreateMutableCopy(OCStringRef theString)
    OCMutableStringRef OCStringCreateMutable(uint64_t maxLength)
    OCStringRef impl_OCStringMakeConstantString(const char *cStr)
    const char* OCStringGetCString(OCStringRef str)
    OCStringRef OCStringCreateWithCString(const char *string)  # For STR() macro support

    # String access
    const char *OCStringGetCString(OCStringRef theString)
    uint64_t OCStringGetLength(OCStringRef theString)

    # String operations
    OCComparisonResult OCStringCompare(OCStringRef theString1,
                                      OCStringRef theString2,
                                      OCStringCompareFlags compareOptions)

    # Mutable string operations
    void OCStringAppend(OCMutableStringRef theString, OCStringRef appendedString)
    void OCStringAppendCString(OCMutableStringRef theString, const char *cStr)

# OCNumber functions
cdef extern from "OCTypes/OCNumber.h":
    # Number types
    ctypedef enum OCNumberType:
        kOCNumberSInt8Type = 1
        kOCNumberSInt16Type = 2
        kOCNumberSInt32Type = 3
        kOCNumberSInt64Type = 4
        kOCNumberFloat32Type = 5
        kOCNumberFloat64Type = 6
        kOCNumberUInt8Type = 7
        kOCNumberUInt16Type = 8
        kOCNumberUInt32Type = 9
        kOCNumberUInt64Type = 10
        kOCNumberComplex64Type = 11
        kOCNumberComplex128Type = 12

    # Type identifier
    OCTypeID OCNumberGetTypeID()

    # Number creation
    OCNumberRef OCNumberCreateWithSInt8(int8_t value)
    OCNumberRef OCNumberCreateWithSInt16(int16_t value)
    OCNumberRef OCNumberCreateWithSInt32(int32_t value)
    OCNumberRef OCNumberCreateWithSInt64(int64_t value)
    OCNumberRef OCNumberCreateWithUInt8(uint8_t value)
    OCNumberRef OCNumberCreateWithUInt16(uint16_t value)
    OCNumberRef OCNumberCreateWithUInt32(uint32_t value)
    OCNumberRef OCNumberCreateWithUInt64(uint64_t value)
    OCNumberRef OCNumberCreateWithInt(int value)
    OCNumberRef OCNumberCreateWithLong(long value)
    OCNumberRef OCNumberCreateWithOCIndex(OCIndex value)
    OCNumberRef OCNumberCreateWithFloat(float value)
    OCNumberRef OCNumberCreateWithDouble(double value)
    OCNumberRef OCNumberCreateWithFloatComplex(float_complex value)
    OCNumberRef OCNumberCreateWithDoubleComplex(double_complex value)

    # Number access
    OCNumberType OCNumberGetType(OCNumberRef number)
    bint OCNumberGetValue(OCNumberRef number, OCNumberType theType, void *valuePtr)

    # Try-get accessors (safe value extraction)
    bint OCNumberTryGetUInt8(OCNumberRef n, uint8_t *out)
    bint OCNumberTryGetSInt8(OCNumberRef n, int8_t *out)
    bint OCNumberTryGetUInt16(OCNumberRef n, uint16_t *out)
    bint OCNumberTryGetSInt16(OCNumberRef n, int16_t *out)
    bint OCNumberTryGetUInt32(OCNumberRef n, uint32_t *out)
    bint OCNumberTryGetSInt32(OCNumberRef n, int32_t *out)
    bint OCNumberTryGetUInt64(OCNumberRef n, uint64_t *out)
    bint OCNumberTryGetSInt64(OCNumberRef n, int64_t *out)
    bint OCNumberTryGetFloat32(OCNumberRef n, float *out)
    bint OCNumberTryGetFloat64(OCNumberRef n, double *out)
    bint OCNumberTryGetComplex64(OCNumberRef n, float_complex *out)
    bint OCNumberTryGetComplex128(OCNumberRef n, double_complex *out)

    # Convenience try-get accessors (aliases)
    bint OCNumberTryGetFloat(OCNumberRef n, float *out)
    bint OCNumberTryGetDouble(OCNumberRef n, double *out)
    bint OCNumberTryGetFloatComplex(OCNumberRef n, float_complex *out)
    bint OCNumberTryGetDoubleComplex(OCNumberRef n, double_complex *out)
    bint OCNumberTryGetInt(OCNumberRef n, int *out)
    bint OCNumberTryGetLong(OCNumberRef n, long *out)
    bint OCNumberTryGetOCIndex(OCNumberRef n, OCIndex *out)

    # Number operations
    OCComparisonResult OCNumberCompare(OCNumberRef number1, OCNumberRef number2)

    # OCNumberType helper functions
    const char *OCNumberGetTypeName(OCNumberType type)
    OCNumberType OCNumberTypeFromName(const char *name)

# OCArray functions
cdef extern from "OCTypes/OCArray.h":
    # Array callbacks structure
    ctypedef const void *(*OCArrayRetainCallBack)(const void *value)
    ctypedef void (*OCArrayReleaseCallBack)(const void *value)
    ctypedef OCStringRef (*OCArrayCopyDescriptionCallBack)(const void *value)
    ctypedef bint (*OCArrayEqualCallBack)(const void *value1, const void *value2)

    ctypedef struct OCArrayCallBacks:
        int64_t version
        OCArrayRetainCallBack retain
        OCArrayReleaseCallBack release
        OCArrayCopyDescriptionCallBack copyDescription
        OCArrayEqualCallBack equal

    # Predefined callbacks
    const OCArrayCallBacks kOCTypeArrayCallBacks

    # Type identifier
    OCTypeID OCArrayGetTypeID()

    # Array creation
    OCArrayRef OCArrayCreate(const void **values, uint64_t numValues,
                            const OCArrayCallBacks *callBacks)
    OCArrayRef OCArrayCreateCopy(OCArrayRef theArray)
    OCMutableArrayRef OCArrayCreateMutable(uint64_t capacity,
                                          const OCArrayCallBacks *callBacks)
    OCMutableArrayRef OCArrayCreateMutableCopy(OCArrayRef theArray)

    # Array access
    uint64_t OCArrayGetCount(OCArrayRef theArray)
    const void *OCArrayGetValueAtIndex(OCArrayRef theArray, uint64_t idx)

    # Mutable array operations
    bint OCArrayAppendValue(OCMutableArrayRef theArray, const void *value)
    bint OCArrayInsertValueAtIndex(OCMutableArrayRef theArray, uint64_t idx, const void *value)
    bint OCArrayRemoveValueAtIndex(OCMutableArrayRef theArray, uint64_t idx)
    bint OCArraySetValueAtIndex(OCMutableArrayRef theArray, OCIndex idx, const void *value)

# OCData functions
cdef extern from "OCTypes/OCData.h":
    # Type identifier
    OCTypeID OCDataGetTypeID()

    # Data creation
    OCDataRef OCDataCreate(const uint8_t *bytes, uint64_t length)
    OCMutableDataRef OCDataCreateMutable(uint64_t capacity)
    OCMutableDataRef OCDataCreateMutableCopy(OCDataRef theData)

    # Data access
    uint64_t OCDataGetLength(OCDataRef theData)
    const uint8_t *OCDataGetBytesPtr(OCDataRef theData)

    # Mutable data operations
    bint OCDataAppendBytes(OCMutableDataRef theData, const uint8_t *bytes, uint64_t length)

# OCBoolean functions
cdef extern from "OCTypes/OCBoolean.h":
    # Type identifier
    OCTypeID OCBooleanGetTypeID()

    # Boolean singletons
    OCBooleanRef kOCBooleanTrue
    OCBooleanRef kOCBooleanFalse

    # Boolean operations
    bint OCBooleanGetValue(OCBooleanRef boolean)

# OCDictionary functions
cdef extern from "OCTypes/OCDictionary.h":
    # Type identifier
    OCTypeID OCDictionaryGetTypeID()

    # Dictionary creation
    OCDictionaryRef OCDictionaryCreate(const void **keys, const void **values, uint64_t numValues)
    OCMutableDictionaryRef OCDictionaryCreateMutable(uint64_t capacity)
    OCDictionaryRef OCDictionaryCreateCopy(OCDictionaryRef theDictionary)
    OCMutableDictionaryRef OCDictionaryCreateMutableCopy(OCDictionaryRef theDictionary)

    # Dictionary access
    uint64_t OCDictionaryGetCount(OCDictionaryRef theDict)
    const void *OCDictionaryGetValue(OCDictionaryRef theDict, OCStringRef key)
    bint OCDictionaryContainsKey(OCDictionaryRef theDict, OCStringRef key)
    bint OCDictionaryGetKeysAndValues(OCDictionaryRef theDictionary, const void **keys, const void **values)

    # Mutable dictionary operations
    bint OCDictionarySetValue(OCMutableDictionaryRef theDict, OCStringRef key, const void *value)
    bint OCDictionaryRemoveValue(OCMutableDictionaryRef theDict, OCStringRef key)

# OCSet functions
cdef extern from "OCTypes/OCSet.h":
    # Type identifier
    OCTypeID OCSetGetTypeID()

    # Set creation
    OCSetRef OCSetCreate()
    OCMutableSetRef OCSetCreateMutable(OCIndex capacity)
    OCSetRef OCSetCreateCopy(OCSetRef theSet)
    OCMutableSetRef OCSetCreateMutableCopy(OCSetRef theSet)

    # Set access
    OCIndex OCSetGetCount(OCSetRef theSet)
    bint OCSetContainsValue(OCSetRef theSet, OCTypeRef value)
    OCArrayRef OCSetCreateValueArray(OCSetRef theSet)

    # Mutable set operations
    bint OCSetAddValue(OCMutableSetRef theSet, OCTypeRef value)
    bint OCSetRemoveValue(OCMutableSetRef theSet, OCTypeRef value)
    void OCSetRemoveAllValues(OCMutableSetRef theSet)

# OCIndexArray functions
cdef extern from "OCTypes/OCIndexArray.h":
    # Type identifier
    OCTypeID OCIndexArrayGetTypeID()

    # Index array creation
    OCIndexArrayRef OCIndexArrayCreate(OCIndex *indexes, OCIndex numValues)
    OCMutableIndexArrayRef OCIndexArrayCreateMutable(OCIndex capacity)
    OCIndexArrayRef OCIndexArrayCreateCopy(OCIndexArrayRef theIndexArray)
    OCMutableIndexArrayRef OCIndexArrayCreateMutableCopy(OCIndexArrayRef theIndexArray)

    # Index array access
    OCIndex OCIndexArrayGetCount(OCIndexArrayRef theArray)
    OCIndex OCIndexArrayGetValueAtIndex(OCIndexArrayRef theArray, OCIndex idx)
    bint OCIndexArrayContainsIndex(OCIndexArrayRef theArray, OCIndex index)

    # Mutable index array operations
    bint OCIndexArrayAppendValue(OCMutableIndexArrayRef theArray, OCIndex value)
    bint OCIndexArraySetValueAtIndex(OCMutableIndexArrayRef theArray, OCIndex idx, OCIndex value)
    bint OCIndexArrayRemoveValueAtIndex(OCMutableIndexArrayRef theArray, OCIndex idx)

# OCIndexSet functions
cdef extern from "OCTypes/OCIndexSet.h":
    # Type identifier
    OCTypeID OCIndexSetGetTypeID()

    # Index set creation
    OCIndexSetRef OCIndexSetCreate()
    OCMutableIndexSetRef OCIndexSetCreateMutable()
    OCIndexSetRef OCIndexSetCreateCopy(OCIndexSetRef theIndexSet)
    OCMutableIndexSetRef OCIndexSetCreateMutableCopy(OCIndexSetRef theIndexSet)
    OCIndexSetRef OCIndexSetCreateWithIndex(OCIndex index)
    OCIndexSetRef OCIndexSetCreateWithIndexesInRange(OCIndex location, OCIndex length)

    # Index set access
    OCIndex OCIndexSetGetCount(OCIndexSetRef theSet)
    bint OCIndexSetContainsIndex(OCIndexSetRef theSet, OCIndex index)
    OCIndex OCIndexSetFirstIndex(OCIndexSetRef theSet)
    OCIndex OCIndexSetLastIndex(OCIndexSetRef theSet)

    # Mutable index set operations
    bint OCIndexSetAddIndex(OCMutableIndexSetRef theSet, OCIndex index)

# OCIndexPairSet functions
cdef extern from "OCTypes/OCIndexPairSet.h":
    # Index pair structure
    ctypedef struct OCIndexPair:
        OCIndex index
        OCIndex value

    # Type identifier
    OCTypeID OCIndexPairSetGetTypeID()

    # Index pair set creation
    OCIndexPairSetRef OCIndexPairSetCreate()
    OCMutableIndexPairSetRef OCIndexPairSetCreateMutable()
    OCIndexPairSetRef OCIndexPairSetCreateCopy(OCIndexPairSetRef source)
    OCMutableIndexPairSetRef OCIndexPairSetCreateMutableCopy(OCIndexPairSetRef source)
    OCIndexPairSetRef OCIndexPairSetCreateWithIndexPair(OCIndex index, OCIndex value)

    # Index pair set access
    OCIndex OCIndexPairSetGetCount(OCIndexPairSetRef theSet)
    bint OCIndexPairSetContainsIndex(OCIndexPairSetRef theSet, OCIndex index)
    bint OCIndexPairSetContainsIndexPair(OCIndexPairSetRef theSet, OCIndexPair pair)
    OCIndex OCIndexPairSetValueForIndex(OCIndexPairSetRef theSet, OCIndex index)

    # Index pair set conversion
    OCIndexSetRef OCIndexPairSetCreateIndexSetOfIndexes(OCIndexPairSetRef theSet)
    OCIndexArrayRef OCIndexPairSetCreateIndexArrayOfValues(OCIndexPairSetRef theSet)

    # Mutable index pair set operations
    bint OCIndexPairSetAddIndexPair(OCMutableIndexPairSetRef theSet, OCIndex index, OCIndex value)
    bint OCIndexPairSetRemoveIndexPairWithIndex(OCMutableIndexPairSetRef theSet, OCIndex index)
