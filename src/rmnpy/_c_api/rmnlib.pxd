# cython: language_level=3
"""
RMNLib C API declarations for Cython

This file declares the C interfaces for RMNLib components in dependency order:
- Phase 3A: Dimension (coordinate systems and axes)
- Phase 3B: SparseSampling (sparse sampling schemes)
- Phase 3C: DependentVariable (core data structures)
- Phase 3D: Dataset (high-level containers)
- Utility functions and metadata handling

Following the proven pattern from sitypes.pxd for comprehensive API coverage.
"""

from libc.complex cimport double_complex, float_complex
from libc.stdbool cimport bool
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
    # Phase 3A: Dimension API (Foundation Component)
    # ====================================================================================

    # Dimension (Abstract Base) - Core coordinate system functionality
    OCTypeID DimensionGetTypeID()
    OCStringRef DimensionGetLabel(DimensionRef dim)
    bool DimensionSetLabel(DimensionRef dim, OCStringRef label, OCStringRef *outError)
    OCStringRef DimensionGetDescription(DimensionRef dim)
    bool DimensionSetDescription(DimensionRef dim, OCStringRef desc, OCStringRef *outError)
    OCMutableDictionaryRef DimensionGetMetadata(DimensionRef dim)
    bool DimensionSetMetadata(DimensionRef dim, OCDictionaryRef dict, OCStringRef *outError)

    # LabeledDimension - Discrete labeled coordinate systems
    OCTypeID LabeledDimensionGetTypeID()
    LabeledDimensionRef LabeledDimensionCreate(OCStringRef label, OCStringRef description,
                                               OCArrayRef labels, OCStringRef *outError)
    OCArrayRef LabeledDimensionGetLabels(LabeledDimensionRef dim)
    bool LabeledDimensionSetLabels(LabeledDimensionRef dim, OCArrayRef labels, OCStringRef *outError)
    OCStringRef LabeledDimensionGetLabelAtIndex(LabeledDimensionRef dim, OCIndex index)

    # SIDimension - SI unit-based coordinate systems
    OCTypeID SIDimensionGetTypeID()
    SIDimensionRef SIDimensionCreate(OCStringRef label, OCStringRef description,
                                     SIUnitRef unit, OCArrayRef coordinates,
                                     OCStringRef *outError)
    SIUnitRef SIDimensionGetUnit(SIDimensionRef dim)
    bool SIDimensionSetUnit(SIDimensionRef dim, SIUnitRef unit, OCStringRef *outError)
    OCArrayRef SIDimensionGetCoordinates(SIDimensionRef dim)
    bool SIDimensionSetCoordinates(SIDimensionRef dim, OCArrayRef coords, OCStringRef *outError)
    SIScalarRef SIDimensionGetCoordinateAtIndex(SIDimensionRef dim, OCIndex index)

    # SIMonotonicDimension - Monotonic coordinate systems
    OCTypeID SIMonotonicDimensionGetTypeID()
    SIMonotonicDimensionRef SIMonotonicDimensionCreate(OCStringRef label, OCStringRef description,
                                                       SIUnitRef unit, OCArrayRef coordinates,
                                                       OCStringRef *outError)
    bool SIMonotonicDimensionIsMonotonic(SIMonotonicDimensionRef dim)
    bool SIMonotonicDimensionIsIncreasing(SIMonotonicDimensionRef dim)
    SIScalarRef SIMonotonicDimensionGetMinimum(SIMonotonicDimensionRef dim)
    SIScalarRef SIMonotonicDimensionGetMaximum(SIMonotonicDimensionRef dim)

    # SILinearDimension - Linearly spaced coordinate systems
    OCTypeID SILinearDimensionGetTypeID()
    SILinearDimensionRef SILinearDimensionCreate(OCStringRef label, OCStringRef description,
                                                 SIScalarRef start, SIScalarRef increment,
                                                 OCIndex count, OCStringRef *outError)
    SIScalarRef SILinearDimensionGetStart(SILinearDimensionRef dim)
    bool SILinearDimensionSetStart(SILinearDimensionRef dim, SIScalarRef start, OCStringRef *outError)
    SIScalarRef SILinearDimensionGetIncrement(SILinearDimensionRef dim)
    bool SILinearDimensionSetIncrement(SILinearDimensionRef dim, SIScalarRef increment, OCStringRef *outError)
    OCIndex SILinearDimensionGetCount(SILinearDimensionRef dim)
    SIScalarRef SILinearDimensionGetCoordinateAtIndex(SILinearDimensionRef dim, OCIndex index)

    # Dimension Utilities - Polymorphic operations across all dimension types
    OCStringRef DimensionGetType(DimensionRef dim)
    OCDictionaryRef DimensionCopyAsDictionary(DimensionRef dim)
    DimensionRef DimensionCreateFromDictionary(OCDictionaryRef dict, OCStringRef *outError)
    OCIndex DimensionGetCount(DimensionRef dim)
    OCStringRef CreateDimensionLongLabel(DimensionRef dim, OCIndex index)

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
    bool SparseSamplingSetDimensionIndexes(SparseSamplingRef ss, OCIndexSetRef indexes, OCStringRef *outError)
    OCArrayRef SparseSamplingGetSparseGridVertexes(SparseSamplingRef ss)
    bool SparseSamplingSetSparseGridVertexes(SparseSamplingRef ss, OCArrayRef vertexes, OCStringRef *outError)
    OCNumberType SparseSamplingGetUnsignedIntegerType(SparseSamplingRef ss)
    bool SparseSamplingSetUnsignedIntegerType(SparseSamplingRef ss, OCNumberType type, OCStringRef *outError)
    OCStringRef SparseSamplingGetEncoding(SparseSamplingRef ss)
    bool SparseSamplingSetEncoding(SparseSamplingRef ss, OCStringRef encoding, OCStringRef *outError)
    OCStringRef SparseSamplingGetDescription(SparseSamplingRef ss)
    bool SparseSamplingSetDescription(SparseSamplingRef ss, OCStringRef description, OCStringRef *outError)
    OCDictionaryRef SparseSamplingGetMetadata(SparseSamplingRef ss)
    bool SparseSamplingSetMetadata(SparseSamplingRef ss, OCDictionaryRef metadata, OCStringRef *outError)

    # SparseSampling utility functions
    OCIndex SparseSamplingGetVertexCount(SparseSamplingRef ss)
    OCIndexPairSetRef SparseSamplingGetVertexAtIndex(SparseSamplingRef ss, OCIndex index)
    bool SparseSamplingContainsVertex(SparseSamplingRef ss, OCIndexPairSetRef vertex)

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
    bool DependentVariableAppend(
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
    bool DependentVariableIsScalarType(DependentVariableRef dv)
    bool DependentVariableIsVectorType(DependentVariableRef dv, OCIndex *outCount)
    bool DependentVariableIsPixelType(DependentVariableRef dv, OCIndex *outCount)
    bool DependentVariableIsMatrixType(DependentVariableRef dv, OCIndex *outRows, OCIndex *outCols)
    bool DependentVariableIsSymmetricMatrixType(DependentVariableRef dv, OCIndex *outN)
    OCIndex DependentVariableComponentsCountFromQuantityType(OCStringRef quantityType)

    # DependentVariable basic accessors
    OCStringRef DependentVariableGetType(DependentVariableRef dv)
    bool DependentVariableSetType(DependentVariableRef dv, OCStringRef newType)
    OCStringRef DependentVariableGetEncoding(DependentVariableRef dv)
    bool DependentVariableSetEncoding(DependentVariableRef dv, OCStringRef newEnc)
    OCStringRef DependentVariableGetComponentsURL(DependentVariableRef dv)
    bool DependentVariableSetComponentsURL(DependentVariableRef dv, OCStringRef url)
    OCStringRef DependentVariableGetName(DependentVariableRef dv)
    bool DependentVariableSetName(DependentVariableRef dv, OCStringRef newName)
    OCStringRef DependentVariableGetDescription(DependentVariableRef dv)
    bool DependentVariableSetDescription(DependentVariableRef dv, OCStringRef newDesc)
    OCStringRef DependentVariableGetQuantityName(DependentVariableRef dv)
    bool DependentVariableSetQuantityName(DependentVariableRef dv, OCStringRef quantityName)
    OCStringRef DependentVariableGetQuantityType(DependentVariableRef dv)
    bool DependentVariableSetQuantityType(DependentVariableRef dv, OCStringRef quantityType)
    OCNumberType DependentVariableGetNumericType(DependentVariableRef dv)
    bool DependentVariableSetNumericType(DependentVariableRef dv, OCNumberType newType)

    # DependentVariable sparse sampling
    SparseSamplingRef DependentVariableGetSparseSampling(DependentVariableRef dv)
    bool DependentVariableSetSparseSampling(DependentVariableRef dv, SparseSamplingRef ss)

    # DependentVariable metadata and ownership
    OCDictionaryRef DependentVariableGetMetaData(DependentVariableRef dv)
    bool DependentVariableSetMetaData(DependentVariableRef dv, OCDictionaryRef dict)
    OCTypeRef DependentVariableGetOwner(DependentVariableRef dv)
    bool DependentVariableSetOwner(DependentVariableRef dv, OCTypeRef owner)

    # DependentVariable component array accessors
    OCIndex DependentVariableGetComponentCount(DependentVariableRef dv)
    OCMutableArrayRef DependentVariableGetComponents(DependentVariableRef dv)
    bool DependentVariableSetComponents(DependentVariableRef dv, OCArrayRef newComponents)
    OCMutableArrayRef DependentVariableCopyComponents(DependentVariableRef dv)

    # DependentVariable size and element type
    OCIndex DependentVariableGetSize(DependentVariableRef dv)
    bool DependentVariableSetSize(DependentVariableRef dv, OCIndex newSize)

    # DependentVariable component labels
    OCArrayRef DependentVariableGetComponentLabels(DependentVariableRef dv)
    bool DependentVariableSetComponentLabels(DependentVariableRef dv, OCArrayRef labels)

    # DependentVariable low-level value accessors
    float DependentVariableGetFloatValueAtMemOffset(DependentVariableRef dv, OCIndex compIdx, OCIndex memOffset)
    double DependentVariableGetDoubleValueAtMemOffset(DependentVariableRef dv, OCIndex compIdx, OCIndex memOffset)
    float_complex DependentVariableGetFloatComplexValueAtMemOffset(DependentVariableRef dv, OCIndex compIdx, OCIndex memOffset)
    double_complex DependentVariableGetDoubleComplexValueAtMemOffset(DependentVariableRef dv, OCIndex compIdx, OCIndex memOffset)
    double DependentVariableGetDoubleValueAtMemOffsetForPart(DependentVariableRef dv, OCIndex compIdx, OCIndex memOffset, complexPart part)
    float DependentVariableGetFloatValueAtMemOffsetForPart(DependentVariableRef dv, OCIndex compIdx, OCIndex memOffset, complexPart part)
    SIScalarRef DependentVariableCreateValueFromMemOffset(DependentVariableRef dv, OCIndex compIdx, OCIndex memOffset)
    bool DependentVariableSetValueAtMemOffset(DependentVariableRef dv, OCIndex compIdx, OCIndex memOffset, SIScalarRef value, OCStringRef *error)

    # DependentVariable unit conversion and data manipulation
    bool DependentVariableConvertToUnit(DependentVariableRef dv, SIUnitRef unit, OCStringRef *error)
    bool DependentVariableSetValuesToZero(DependentVariableRef dv, int64_t componentIndex)
    bool DependentVariableZeroPartInRange(DependentVariableRef dv, OCIndex componentIndex, OCRange range, complexPart part)
    bool DependentVariableTakeAbsoluteValue(DependentVariableRef dv, int64_t componentIndex)
    bool DependentVariableMultiplyValuesByDimensionlessComplexConstant(DependentVariableRef dv, int64_t componentIndex, double_complex constant)
    bool DependentVariableTakeComplexPart(DependentVariableRef dv, OCIndex componentIndex, complexPart part)
    bool DependentVariableConjugate(DependentVariableRef dv, OCIndex componentIndex)
    bool DependentVariableMultiplyValuesByDimensionlessRealConstant(DependentVariableRef dv, OCIndex componentIndex, double constant)

    # DependentVariable arithmetic operations
    bool DependentVariableAdd(DependentVariableRef dv1, DependentVariableRef dv2)
    bool DependentVariableSubtract(DependentVariableRef dv1, DependentVariableRef dv2)
    bool DependentVariableMultiply(DependentVariableRef dv1, DependentVariableRef dv2)
    bool DependentVariableDivide(DependentVariableRef dv1, DependentVariableRef dv2)

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
    bool DatasetSetName(DatasetRef dataset, OCStringRef name, OCStringRef *outError)
    OCStringRef DatasetGetDescription(DatasetRef dataset)
    bool DatasetSetDescription(DatasetRef dataset, OCStringRef description, OCStringRef *outError)

    # Dataset dimensions management
    OCArrayRef DatasetGetDimensions(DatasetRef dataset)
    bool DatasetSetDimensions(DatasetRef dataset, OCArrayRef dimensions, OCStringRef *outError)
    bool DatasetAddDimension(DatasetRef dataset, DimensionRef dimension, OCStringRef *outError)

    # Dataset dependent variables management
    OCArrayRef DatasetGetDependentVariables(DatasetRef dataset)
    bool DatasetSetDependentVariables(DatasetRef dataset, OCArrayRef variables, OCStringRef *outError)
    bool DatasetAddDependentVariable(DatasetRef dataset, DependentVariableRef variable, OCStringRef *outError)

    # Dataset metadata
    OCDictionaryRef DatasetGetMetadata(DatasetRef dataset)
    bool DatasetSetMetadata(DatasetRef dataset, OCDictionaryRef metadata, OCStringRef *outError)

    # ====================================================================================
    # Utility Functions and Metadata Handling
    # ====================================================================================

    # Internal library management (not exposed to Python users)
    void RMNLibTypesShutdown()
