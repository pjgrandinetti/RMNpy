# cython: language_level=3
"""
RMNLib C API declarations for Cython

This file declares the C interfaces for RMNLib components.
Based on the actual RMNLibrary.h header file.
"""

from libc.stdint cimport int64_t

# Import OCTypes and SITypes C APIs
from rmnpy._c_api.octypes cimport *
from rmnpy._c_api.sitypes cimport *

# ====================================================================================
# RMNLib Core Types and Forward Declarations (from RMNLibrary.h)
# ====================================================================================

# Forward declarations from RMNLibrary.h
ctypedef void *GeographicCoordinateRef
ctypedef void *DatumRef
ctypedef void *SparseSamplingRef
ctypedef void *DependentVariableRef
ctypedef void *DimensionRef
ctypedef void *LabeledDimensionRef
ctypedef void *SIDimensionRef
ctypedef void *SIMonotonicDimensionRef
ctypedef void *SILinearDimensionRef
ctypedef void *DatasetRef

# Enumerations
ctypedef enum dimensionScaling:
    kDimensionScalingNone
    kDimensionScalingNMR

cdef extern from "RMNLibrary.h":
    # ====================================================================================
    # Dimension API - Only functions actually used in dimension.pyx
    # ====================================================================================

    # Dimension (Abstract Base) - Core coordinate system functionality
    OCStringRef DimensionGetType(DimensionRef dim)
    OCStringRef DimensionCopyLabel(DimensionRef dim)
    bint DimensionSetLabel(DimensionRef dim, OCStringRef label, OCStringRef *outError)
    OCStringRef DimensionCopyDescription(DimensionRef dim)
    bint DimensionSetDescription(DimensionRef dim, OCStringRef desc, OCStringRef *outError)
    OCMutableDictionaryRef DimensionGetApplicationMetaData(DimensionRef dim)
    bint DimensionSetApplicationMetaData(DimensionRef dim, OCDictionaryRef dict, OCStringRef *outError)
    OCIndex DimensionGetCount(DimensionRef dim)
    OCDictionaryRef DimensionCopyAsDictionary(DimensionRef dim)
    bint DimensionIsQuantitative(DimensionRef dim)
    OCStringRef DimensionCreateAxisLabel(DimensionRef dim, OCIndex index)

    # LabeledDimension - Discrete labeled coordinate systems
    LabeledDimensionRef LabeledDimensionCreate(OCStringRef label, OCStringRef description,
                                               OCDictionaryRef metadata, OCArrayRef coordinateLabels,
                                               OCStringRef *outError)
    OCArrayRef LabeledDimensionCopyCoordinateLabels(LabeledDimensionRef dim)
    bint LabeledDimensionSetCoordinateLabels(LabeledDimensionRef dim, OCArrayRef labels, OCStringRef *outError)
    bint LabeledDimensionSetCoordinateLabelAtIndex(LabeledDimensionRef dim, OCIndex index, OCStringRef label)

    # SIDimension - SI unit-based coordinate systems (base class)
    SIDimensionRef SIDimensionCreate(OCStringRef label, OCStringRef description,
                                     OCDictionaryRef metadata, OCStringRef quantityName,
                                     SIScalarRef offset, SIScalarRef origin, SIScalarRef period,
                                     dimensionScaling scaling, OCStringRef *outError)
    OCStringRef SIDimensionCopyQuantityName(SIDimensionRef dim)
    bint SIDimensionSetQuantityName(SIDimensionRef dim, OCStringRef name, OCStringRef *outError)
    SIScalarRef SIDimensionCopyCoordinatesOffset(SIDimensionRef dim)
    bint SIDimensionSetCoordinatesOffset(SIDimensionRef dim, SIScalarRef val, OCStringRef *outError)
    SIScalarRef SIDimensionCopyOriginOffset(SIDimensionRef dim)
    bint SIDimensionSetOriginOffset(SIDimensionRef dim, SIScalarRef val, OCStringRef *outError)
    SIScalarRef SIDimensionCopyPeriod(SIDimensionRef dim)
    bint SIDimensionSetPeriod(SIDimensionRef dim, SIScalarRef val, OCStringRef *outError)
    bint SIDimensionIsPeriodic(SIDimensionRef dim)
    dimensionScaling SIDimensionGetScaling(SIDimensionRef dim)
    bint SIDimensionSetScaling(SIDimensionRef dim, dimensionScaling scaling)

    # SILinearDimension - Linearly spaced coordinate systems
    SILinearDimensionRef SILinearDimensionCreate(OCStringRef label, OCStringRef description,
                                                 OCDictionaryRef metadata, OCStringRef quantityName,
                                                 SIScalarRef offset, SIScalarRef origin, SIScalarRef period,
                                                 dimensionScaling scaling, OCIndex count,
                                                 SIScalarRef increment, bint fft, SIDimensionRef reciprocal,
                                                 OCStringRef *outError)
    OCIndex SILinearDimensionGetCount(SILinearDimensionRef dim)
    bint SILinearDimensionSetCount(SILinearDimensionRef dim, OCIndex count)
    SIScalarRef SILinearDimensionCopyIncrement(SILinearDimensionRef dim)
    bint SILinearDimensionSetIncrement(SILinearDimensionRef dim, SIScalarRef inc)
    SIScalarRef SILinearDimensionCreateReciprocalIncrement(SILinearDimensionRef dim)
    bint SILinearDimensionGetComplexFFT(SILinearDimensionRef dim)
    bint SILinearDimensionSetComplexFFT(SILinearDimensionRef dim, bint fft)
    SIDimensionRef SILinearDimensionCopyReciprocal(SILinearDimensionRef dim)
    bint SILinearDimensionSetReciprocal(SILinearDimensionRef dim, SIDimensionRef rec, OCStringRef *outError)
    OCArrayRef SILinearDimensionCreateCoordinates(SILinearDimensionRef dim)
    OCArrayRef SILinearDimensionCreateAbsoluteCoordinates(SILinearDimensionRef dim)

    # SIMonotonicDimension - Monotonic coordinate systems
    SIMonotonicDimensionRef SIMonotonicDimensionCreate(OCStringRef label, OCStringRef description,
                                                       OCDictionaryRef metadata, OCStringRef quantityName,
                                                       SIScalarRef offset, SIScalarRef origin, SIScalarRef period,
                                                       dimensionScaling scaling, OCArrayRef coordinates,
                                                       SIDimensionRef reciprocal, OCStringRef *outError)
    OCArrayRef SIMonotonicDimensionCopyCoordinates(SIMonotonicDimensionRef dim)
    bint SIMonotonicDimensionSetCoordinates(SIMonotonicDimensionRef dim, OCArrayRef coords)
    OCArrayRef SIMonotonicDimensionCreateAbsoluteCoordinates(SIMonotonicDimensionRef dim)
    SIDimensionRef SIMonotonicDimensionCopyReciprocal(SIMonotonicDimensionRef dim)
    bint SIMonotonicDimensionSetReciprocal(SIMonotonicDimensionRef dim, SIDimensionRef rec, OCStringRef *outError)

    # ====================================================================================
    # Phase 3B: SparseSampling API (Depends on Dimension)
    # ====================================================================================

    # SparseSampling - Sparse sampling pattern definitions
    OCTypeID SparseSamplingGetTypeID()
    SparseSamplingRef SparseSamplingCreate(OCIndexSetRef dimensionIndexes,
                                           OCArrayRef sparseGridVertexes,
                                           OCNumberType unsignedIntegerType,
                                           OCStringRef encoding,
                                           OCStringRef description,
                                           OCDictionaryRef metadata,
                                           OCStringRef *outError)
    SparseSamplingRef SparseSamplingCreateFromDictionary(OCDictionaryRef dict, OCStringRef *outError)
    OCDictionaryRef SparseSamplingCopyAsDictionary(SparseSamplingRef ss)

    # SparseSampling accessors
    OCIndexSetRef SparseSamplingGetDimensionIndexes(SparseSamplingRef ss)
    bint SparseSamplingSetDimensionIndexes(SparseSamplingRef ss, OCIndexSetRef indexes)
    OCArrayRef SparseSamplingGetSparseGridVertexes(SparseSamplingRef ss)
    bint SparseSamplingSetSparseGridVertexes(SparseSamplingRef ss, OCArrayRef vertexes)
    OCNumberType SparseSamplingGetUnsignedIntegerType(SparseSamplingRef ss)
    bint SparseSamplingSetUnsignedIntegerType(SparseSamplingRef ss, OCNumberType type)
    OCStringRef SparseSamplingGetEncoding(SparseSamplingRef ss)
    bint SparseSamplingSetEncoding(SparseSamplingRef ss, OCStringRef encoding)
    OCStringRef SparseSamplingGetDescription(SparseSamplingRef ss)
    bint SparseSamplingSetDescription(SparseSamplingRef ss, OCStringRef description)
    OCDictionaryRef SparseSamplingGetApplicationMetaData(SparseSamplingRef ss)
    bint SparseSamplingSetApplicationMetaData(SparseSamplingRef ss, OCDictionaryRef metadata)

    # SparseSampling utility functions
    OCIndex SparseSamplingGetVertexCount(SparseSamplingRef ss)
    OCIndexPairSetRef SparseSamplingGetVertexAtIndex(SparseSamplingRef ss, OCIndex index)
    bint SparseSamplingContainsVertex(SparseSamplingRef ss, OCIndexPairSetRef vertex)

    # ====================================================================================
    # Phase 3C: DependentVariable API (Depends on Dimension + SparseSampling)
    # ====================================================================================
    # ====================================================================================
    # Phase 3C: DependentVariable API (Depends on Dimension + SparseSampling)
    # ====================================================================================

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
    OCDataRef DependentVariableCreateCSDMComponentsData(DependentVariableRef dv, OCArrayRef dimensions)

    # DependentVariable type checking
    bint DependentVariableIsScalarType(DependentVariableRef dv)
    bint DependentVariableIsVectorType(DependentVariableRef dv, OCIndex *outCount)
    bint DependentVariableIsPixelType(DependentVariableRef dv, OCIndex *outCount)
    bint DependentVariableIsMatrixType(DependentVariableRef dv, OCIndex *outRows, OCIndex *outCols)
    bint DependentVariableIsSymmetricMatrixType(DependentVariableRef dv, OCIndex *outN)
    OCIndex DependentVariableComponentsCountFromQuantityType(OCStringRef quantityType)

    # DependentVariable basic accessors (using copy functions for memory safety)
    OCStringRef DependentVariableCopyType(DependentVariableRef dv)
    OCStringRef DependentVariableCopyEncoding(DependentVariableRef dv)
    OCStringRef DependentVariableGetComponentsURL(DependentVariableRef dv)
    bint DependentVariableSetComponentsURL(DependentVariableRef dv, OCStringRef url)
    OCStringRef DependentVariableCopyName(DependentVariableRef dv)
    bint DependentVariableSetName(DependentVariableRef dv, OCStringRef name)
    OCStringRef DependentVariableCopyDescription(DependentVariableRef dv)
    bint DependentVariableSetDescription(DependentVariableRef dv, OCStringRef description)
    OCStringRef DependentVariableCopyQuantityName(DependentVariableRef dv)
    OCStringRef DependentVariableCopyQuantityType(DependentVariableRef dv)
    OCNumberType DependentVariableGetNumericType(DependentVariableRef dv)
    bint DependentVariableSetNumericType(DependentVariableRef dv, OCNumberType newType)

    # DependentVariable sparse sampling
    SparseSamplingRef DependentVariableCopySparseSampling(DependentVariableRef dv)
    bint DependentVariableSetSparseSampling(DependentVariableRef dv, SparseSamplingRef ss)

    # DependentVariable metadata and ownership
    OCDictionaryRef DependentVariableGetApplicationMetaData(DependentVariableRef dv)
    bint DependentVariableSetApplicationMetaData(DependentVariableRef dv, OCDictionaryRef dict)
    OCTypeRef DependentVariableGetOwner(DependentVariableRef dv)
    bint DependentVariableSetOwner(DependentVariableRef dv, OCTypeRef owner)

    # DependentVariable component array accessors
    OCIndex DependentVariableGetComponentCount(DependentVariableRef dv)
    OCMutableArrayRef DependentVariableGetComponents(DependentVariableRef dv)
    bint DependentVariableSetComponents(DependentVariableRef dv, OCArrayRef newComponents)
    OCMutableArrayRef DependentVariableCopyComponents(DependentVariableRef dv)

    # DependentVariable size and element type
    OCIndex DependentVariableGetSize(DependentVariableRef dv)
    bint DependentVariableSetSize(DependentVariableRef dv, OCIndex newSize)

    # DependentVariable component labels
    OCArrayRef DependentVariableGetComponentLabels(DependentVariableRef dv)
    bint DependentVariableSetComponentLabels(DependentVariableRef dv, OCArrayRef labels)

    # DependentVariable low-level value accessors
    float DependentVariableGetFloatValueAtMemOffset(DependentVariableRef dv, OCIndex compIdx, OCIndex memOffset)
    double DependentVariableGetDoubleValueAtMemOffset(DependentVariableRef dv, OCIndex compIdx, OCIndex memOffset)
    float complex DependentVariableGetFloatComplexValueAtMemOffset(DependentVariableRef dv, OCIndex compIdx, OCIndex memOffset)
    double complex DependentVariableGetDoubleComplexValueAtMemOffset(DependentVariableRef dv, OCIndex compIdx, OCIndex memOffset)
    double DependentVariableGetDoubleValueAtMemOffsetForPart(DependentVariableRef dv, OCIndex compIdx, OCIndex memOffset, complexPart part)
    float DependentVariableGetFloatValueAtMemOffsetForPart(DependentVariableRef dv, OCIndex compIdx, OCIndex memOffset, complexPart part)
    SIScalarRef DependentVariableCreateValueFromMemOffset(DependentVariableRef dv, OCIndex compIdx, OCIndex memOffset)
    bint DependentVariableSetValueAtMemOffset(DependentVariableRef dv, OCIndex compIdx, OCIndex memOffset, SIScalarRef value, OCStringRef *error)

    # DependentVariable unit conversion and data manipulation
    bint DependentVariableConvertToUnit(DependentVariableRef dv, SIUnitRef unit, OCStringRef *error)
    bint DependentVariableSetValuesToZero(DependentVariableRef dv, int64_t componentIndex)
    bint DependentVariableZeroPartInRange(DependentVariableRef dv, OCIndex componentIndex, OCRange range, complexPart part)
    bint DependentVariableTakeAbsoluteValue(DependentVariableRef dv, int64_t componentIndex)
    bint DependentVariableMultiplyValuesByDimensionlessComplexConstant(DependentVariableRef dv, int64_t componentIndex, double complex constant)
    bint DependentVariableTakeComplexPart(DependentVariableRef dv, OCIndex componentIndex, complexPart part)
    bint DependentVariableConjugate(DependentVariableRef dv, OCIndex componentIndex)
    bint DependentVariableMultiplyValuesByDimensionlessRealConstant(DependentVariableRef dv, OCIndex componentIndex, double constant)

    # DependentVariable arithmetic operations
    bint DependentVariableAdd(DependentVariableRef dv1, DependentVariableRef dv2)
    bint DependentVariableSubtract(DependentVariableRef dv1, DependentVariableRef dv2)
    bint DependentVariableMultiply(DependentVariableRef dv1, DependentVariableRef dv2)
    bint DependentVariableDivide(DependentVariableRef dv1, DependentVariableRef dv2)

    # Note: DependentVariable inherits from SIQuantity, so all SIQuantity functions
    # (declared in sitypes.pxd) can be used with DependentVariableRef cast to SIQuantityRef

    # ====================================================================================
    # Phase 3D: Dataset API (Depends on all previous components)
    # ====================================================================================

    # Dataset - High-level data container and workflow orchestration
    OCTypeID DatasetGetTypeID()
    DatasetRef DatasetCreate(OCStringRef name, OCStringRef description, OCStringRef *outError)
    DatasetRef DatasetCreateFromDictionary(OCDictionaryRef dict, OCStringRef *outError)
    OCDictionaryRef DatasetCopyAsDictionary(DatasetRef dataset)

    # Dataset basic accessors
    OCStringRef DatasetGetName(DatasetRef dataset)
    bint DatasetSetName(DatasetRef dataset, OCStringRef name, OCStringRef *outError)
    OCStringRef DatasetGetDescription(DatasetRef dataset)
    bint DatasetSetDescription(DatasetRef dataset, OCStringRef description, OCStringRef *outError)

    # Dataset dimensions management
    OCArrayRef DatasetGetDimensions(DatasetRef dataset)
    bint DatasetSetDimensions(DatasetRef dataset, OCArrayRef dimensions, OCStringRef *outError)
    bint DatasetAddDimension(DatasetRef dataset, DimensionRef dimension, OCStringRef *outError)

    # Dataset dependent variables management
    OCArrayRef DatasetGetDependentVariables(DatasetRef dataset)
    bint DatasetSetDependentVariables(DatasetRef dataset, OCArrayRef variables, OCStringRef *outError)
    bint DatasetAddDependentVariable(DatasetRef dataset, DependentVariableRef variable, OCStringRef *outError)

    # Dataset metadata
    OCDictionaryRef DatasetGetApplicationMetaData(DatasetRef dataset)
    bint DatasetSetApplicationMetaData(DatasetRef dataset, OCDictionaryRef metadata, OCStringRef *outError)

    # ====================================================================================
    # DependentVariable API - Dataset variables with metadata and components
    # ====================================================================================

    # Core creation and management
    DependentVariableRef DependentVariableCreate(OCStringRef name, OCStringRef description,
                                                  SIUnitRef unit, OCStringRef quantityName,
                                                  OCStringRef quantityType, OCNumberType elementType,
                                                  OCArrayRef componentLabels, OCArrayRef components,
                                                  OCStringRef *outError)
    DependentVariableRef DependentVariableCopy(DependentVariableRef orig)

    # String property accessors (memory-safe copy functions)
    OCStringRef DependentVariableCopyName(DependentVariableRef dv)
    OCStringRef DependentVariableCopyDescription(DependentVariableRef dv)
    OCStringRef DependentVariableCopyQuantityType(DependentVariableRef dv)
    OCStringRef DependentVariableCopyQuantityName(DependentVariableRef dv)
    OCStringRef DependentVariableCopyEncoding(DependentVariableRef dv)
    OCStringRef DependentVariableCopyType(DependentVariableRef dv)

    # Property setters
    bint DependentVariableSetName(DependentVariableRef dv, OCStringRef name)
    bint DependentVariableSetDescription(DependentVariableRef dv, OCStringRef desc)
    bint DependentVariableSetQuantityName(DependentVariableRef dv, OCStringRef quantityName)

    # Numeric and structural properties
    OCNumberType DependentVariableGetNumericType(DependentVariableRef dv)
    OCIndex DependentVariableGetComponentCount(DependentVariableRef dv)
    OCIndex DependentVariableGetSize(DependentVariableRef dv)

    # ====================================================================================
    # TypeID Functions for OCType Identification
    # ====================================================================================

    # Dimension TypeIDs for convert_octype_to_python function
    OCTypeID DimensionGetTypeID()
    OCTypeID LabeledDimensionGetTypeID()
    OCTypeID SIDimensionGetTypeID()
    OCTypeID SILinearDimensionGetTypeID()
    OCTypeID SIMonotonicDimensionGetTypeID()
    OCTypeID DependentVariableGetTypeID()

    # ====================================================================================
    # Utility Functions and Metadata Handling
    # ====================================================================================

    # Internal library management (not exposed to Python users)
    void RMNLibTypesShutdown()
