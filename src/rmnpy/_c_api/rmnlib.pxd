# cython: language_level=3
"""
RMNLib C API declarations for Cython

This file declares the C interfaces for RMNLib components:
- DependentVariable: Core data structures for measurements and analysis
- SparseSampling: Sparse sampling data structures
- Related types and enums
"""

from libc.complex cimport double_complex, float_complex
from libc.stdint cimport int64_t

# Import OCTypes and SITypes C APIs
from rmnpy._c_api.octypes cimport *
from rmnpy._c_api.sitypes cimport *


cdef extern from "RMNLibrary.h":
    # cJSON forward declaration (from included cJSON.h)
    ctypedef struct cJSON

    # Complex part enumeration (from SITypes)
    ctypedef enum complexPart:
        kSIRealPart
        kSIImaginaryPart
        kSIMagnitudePart
        kSIArgumentPart

    # OCRange structure
    ctypedef struct OCRange:
        OCIndex location
        OCIndex length

    # Forward declarations
    ctypedef struct impl_DependentVariable
    ctypedef impl_DependentVariable* DependentVariableRef

    ctypedef struct impl_SparseSampling
    ctypedef impl_SparseSampling* SparseSamplingRef

    # DependentVariable type and copying
    OCTypeID DependentVariableGetTypeID()
    DependentVariableRef DependentVariableCopy(DependentVariableRef orig)
    DependentVariableRef DependentVariableCreateComplexCopy(DependentVariableRef src, OCTypeRef owner)

    # DependentVariable creation functions
    DependentVariableRef DependentVariableCreate(
        OCStringRef name,
        OCStringRef description,
        SIUnitRef unit,
        OCStringRef quantityName,
        OCStringRef quantityType,
        OCNumberType elementType,
        OCArrayRef componentLabels,
        OCArrayRef components,
        OCStringRef *outError)

    DependentVariableRef DependentVariableCreateWithComponentsNoCopy(
        OCStringRef name,
        OCStringRef description,
        SIUnitRef unit,
        OCStringRef quantityName,
        OCStringRef quantityType,
        OCNumberType elementType,
        OCArrayRef componentLabels,
        OCArrayRef components,
        OCStringRef *outError)

    DependentVariableRef DependentVariableCreateWithSize(
        OCStringRef name,
        OCStringRef description,
        SIUnitRef unit,
        OCStringRef quantityName,
        OCStringRef quantityType,
        OCNumberType elementType,
        OCArrayRef componentLabels,
        OCIndex size,
        OCStringRef *outError)

    DependentVariableRef DependentVariableCreateDefault(
        OCStringRef quantityType,
        OCNumberType elementType,
        OCIndex size,
        OCStringRef *outError)

    DependentVariableRef DependentVariableCreateWithComponent(
        OCStringRef name,
        OCStringRef description,
        SIUnitRef unit,
        OCStringRef quantityName,
        OCNumberType elementType,
        OCArrayRef componentLabels,
        OCDataRef component,
        OCStringRef *outError)

    DependentVariableRef DependentVariableCreateExternal(
        OCStringRef name,
        OCStringRef description,
        SIUnitRef unit,
        OCStringRef quantityName,
        OCStringRef quantityType,
        OCNumberType elementType,
        OCStringRef componentsURL,
        OCStringRef *outError)

    DependentVariableRef DependentVariableCreateMinimal(
        SIUnitRef unit,
        OCStringRef quantityName,
        OCStringRef quantityType,
        OCNumberType numericType,
        OCArrayRef components,
        OCStringRef *outError)

    DependentVariableRef DependentVariableCreateFromJSON(
        cJSON *json,
        OCStringRef *outError)

    # DependentVariable mutation
    bint DependentVariableAppend(
        DependentVariableRef dv,
        DependentVariableRef appendedDV,
        OCStringRef *outError)

    # DependentVariable serialization
    OCDictionaryRef DependentVariableCopyAsDictionary(DependentVariableRef dv)
    DependentVariableRef DependentVariableCreateFromDictionary(
        OCDictionaryRef dict,
        OCStringRef *outError)
    OCDictionaryRef DependentVariableDictionaryCreateFromJSON(cJSON *json, OCStringRef *outError)
    OCDataRef DependentVariableCreateCSDMComponentsData(DependentVariableRef dv, OCArrayRef dimensions)

    # DependentVariable type checking
    bint DependentVariableIsScalarType(DependentVariableRef dv)
    bint DependentVariableIsVectorType(DependentVariableRef dv, OCIndex *outCount)
    bint DependentVariableIsPixelType(DependentVariableRef dv, OCIndex *outCount)
    bint DependentVariableIsMatrixType(DependentVariableRef dv, OCIndex *outRows, OCIndex *outCols)
    bint DependentVariableIsSymmetricMatrixType(DependentVariableRef dv, OCIndex *outN)
    OCIndex DependentVariableComponentsCountFromQuantityType(OCStringRef quantityType)

    # DependentVariable basic accessors
    OCStringRef DependentVariableGetType(DependentVariableRef dv)
    bint DependentVariableSetType(DependentVariableRef dv, OCStringRef newType)
    bint DependentVariableShouldSerializeExternally(DependentVariableRef dv)
    OCStringRef DependentVariableGetEncoding(DependentVariableRef dv)
    bint DependentVariableSetEncoding(DependentVariableRef dv, OCStringRef newEnc)
    OCStringRef DependentVariableGetComponentsURL(DependentVariableRef dv)
    bint DependentVariableSetComponentsURL(DependentVariableRef dv, OCStringRef url)
    OCStringRef DependentVariableGetName(DependentVariableRef dv)
    bint DependentVariableSetName(DependentVariableRef dv, OCStringRef newName)
    OCStringRef DependentVariableGetDescription(DependentVariableRef dv)
    bint DependentVariableSetDescription(DependentVariableRef dv, OCStringRef newDesc)
    OCStringRef DependentVariableGetQuantityName(DependentVariableRef dv)
    bint DependentVariableSetQuantityName(DependentVariableRef dv, OCStringRef quantityName)
    OCStringRef DependentVariableGetQuantityType(DependentVariableRef dv)
    bint DependentVariableSetQuantityType(DependentVariableRef dv, OCStringRef quantityType)
    OCStringRef DependentVariableGetUnitSymbol(DependentVariableRef dv)
    OCNumberType DependentVariableGetNumericType(DependentVariableRef dv)
    bint DependentVariableSetNumericType(DependentVariableRef dv, OCNumberType newType)

    # DependentVariable sparse sampling
    SparseSamplingRef DependentVariableGetSparseSampling(DependentVariableRef dv)
    bint DependentVariableSetSparseSampling(DependentVariableRef dv, SparseSamplingRef ss)

    # DependentVariable metadata and ownership
    OCDictionaryRef DependentVariableGetMetaData(DependentVariableRef dv)
    bint DependentVariableSetMetaData(DependentVariableRef dv, OCDictionaryRef dict)
    OCTypeRef DependentVariableGetOwner(DependentVariableRef dv)
    bint DependentVariableSetOwner(DependentVariableRef dv, OCTypeRef owner)

    # DependentVariable component array accessors
    OCIndex DependentVariableGetComponentCount(DependentVariableRef dv)
    OCMutableArrayRef DependentVariableGetComponents(DependentVariableRef dv)
    bint DependentVariableSetComponents(DependentVariableRef dv, OCArrayRef newComponents)
    OCMutableArrayRef DependentVariableCopyComponents(DependentVariableRef dv)
    OCDataRef DependentVariableGetComponentAtIndex(DependentVariableRef dv, OCIndex idx)
    bint DependentVariableSetComponentAtIndex(DependentVariableRef dv, OCDataRef newBuf, OCIndex idx)
    bint DependentVariableInsertComponentAtIndex(DependentVariableRef dv, OCDataRef component, OCIndex idx)
    bint DependentVariableRemoveComponentAtIndex(DependentVariableRef dv, OCIndex idx)

    # DependentVariable size and element type
    OCIndex DependentVariableGetSize(DependentVariableRef dv)
    bint DependentVariableSetSize(DependentVariableRef dv, OCIndex newSize)

    # DependentVariable component labels
    OCArrayRef DependentVariableGetComponentLabels(DependentVariableRef dv)
    bint DependentVariableSetComponentLabels(DependentVariableRef dv, OCArrayRef labels)
    OCStringRef DependentVariableCreateComponentLabelForIndex(DependentVariableRef dv, OCIndex idx)
    OCStringRef DependentVariableGetComponentLabelAtIndex(DependentVariableRef dv, OCIndex idx)
    bint DependentVariableSetComponentLabelAtIndex(DependentVariableRef dv, OCStringRef newLabel, OCIndex idx)

    # DependentVariable low-level value accessors
    float DependentVariableGetFloatValueAtMemOffset(DependentVariableRef dv, OCIndex compIdx, OCIndex memOffset)
    double DependentVariableGetDoubleValueAtMemOffset(DependentVariableRef dv, OCIndex compIdx, OCIndex memOffset)
    float_complex DependentVariableGetFloatComplexValueAtMemOffset(DependentVariableRef dv, OCIndex compIdx, OCIndex memOffset)
    double_complex DependentVariableGetDoubleComplexValueAtMemOffset(DependentVariableRef dv, OCIndex compIdx, OCIndex memOffset)
    double DependentVariableGetDoubleValueAtMemOffsetForPart(DependentVariableRef dv, OCIndex compIdx, OCIndex memOffset, complexPart part)
    float DependentVariableGetFloatValueAtMemOffsetForPart(DependentVariableRef dv, OCIndex compIdx, OCIndex memOffset, complexPart part)
    SIScalarRef DependentVariableCreateValueFromMemOffset(DependentVariableRef dv, OCIndex compIdx, OCIndex memOffset)
    bint DependentVariableSetValueAtMemOffset(DependentVariableRef dv, OCIndex compIdx, OCIndex memOffset, SIScalarRef value, OCStringRef *error)

    # DependentVariable unit conversion and data manipulation
    bint DependentVariableConvertToUnit(DependentVariableRef dv, SIUnitRef unit, OCStringRef *error)
    bint DependentVariableSetValuesToZero(DependentVariableRef dv, int64_t componentIndex)
    bint DependentVariableZeroPartInRange(DependentVariableRef dv, OCIndex componentIndex, OCRange range, complexPart part)
    bint DependentVariableTakeAbsoluteValue(DependentVariableRef dv, int64_t componentIndex)
    bint DependentVariableMultiplyValuesByDimensionlessComplexConstant(DependentVariableRef dv, int64_t componentIndex, double_complex constant)
    bint DependentVariableTakeComplexPart(DependentVariableRef dv, OCIndex componentIndex, complexPart part)
    bint DependentVariableConjugate(DependentVariableRef dv, OCIndex componentIndex)
    bint DependentVariableMultiplyValuesByDimensionlessRealConstant(DependentVariableRef dv, OCIndex componentIndex, double constant)

    # DependentVariable arithmetic operations
    bint DependentVariableAdd(DependentVariableRef dv1, DependentVariableRef dv2)
    bint DependentVariableSubtract(DependentVariableRef dv1, DependentVariableRef dv2)
    bint DependentVariableMultiply(DependentVariableRef dv1, DependentVariableRef dv2)
    bint DependentVariableDivide(DependentVariableRef dv1, DependentVariableRef dv2)

    # SparseSampling forward declaration (detailed API would be in separate section)
    OCTypeID SparseSamplingGetTypeID()

    # Note: DependentVariable inherits from SIQuantity, so all SIQuantity functions
    # (declared in sitypes.pxd) can be used with DependentVariableRef cast to SIQuantityRef
