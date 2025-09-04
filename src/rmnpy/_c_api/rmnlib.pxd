# cython: language_level=3
"""
RMNLib C API declarations for Cython

This file declares the C interfaces for RMNLib components.
Based on the actual RMNLibrary.h header file.
Organized by component hierarchy and functionality.
"""

from libc.stdint cimport int64_t

# Import OCTypes and SITypes C APIs
from rmnpy._c_api.octypes cimport *
from rmnpy._c_api.sitypes cimport *

# ====================================================================================
# External Dependencies
# ====================================================================================

# cJSON declarations for JSON-based serialization
cdef extern from "cJSON.h":
    ctypedef struct cJSON:
        pass
    void cJSON_Delete(cJSON *c)

# ====================================================================================
# RMNLib Core Types and Forward Declarations
# ====================================================================================

# Core RMNLib object reference types
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

# ====================================================================================
# RMNLib C API Function Declarations
# ====================================================================================

cdef extern from "RMNLibrary.h":

    # ================================================================================
    # 1. TypeID Functions - Object type identification
    # ================================================================================

    OCTypeID DimensionGetTypeID()
    OCTypeID LabeledDimensionGetTypeID()
    OCTypeID SIDimensionGetTypeID()
    OCTypeID SILinearDimensionGetTypeID()
    OCTypeID SIMonotonicDimensionGetTypeID()
    OCTypeID DependentVariableGetTypeID()
    OCTypeID SparseSamplingGetTypeID()
    OCTypeID GeographicCoordinateGetTypeID()
    OCTypeID DatumGetTypeID()
    OCTypeID DatasetGetTypeID()

    # ================================================================================
    # 2. Dimension API - Coordinate system definitions
    # ================================================================================

    # 2.1 Dimension (Abstract Base Class)
    # Core functionality for all coordinate systems
    DimensionRef DimensionCreateFromJSON(cJSON *json, OCStringRef *outError)
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

    # 2.2 LabeledDimension - Discrete labeled coordinate systems
    LabeledDimensionRef LabeledDimensionCreate(OCStringRef label, OCStringRef description,
                                               OCDictionaryRef metadata, OCArrayRef coordinateLabels,
                                               OCStringRef *outError)
    OCArrayRef LabeledDimensionCopyCoordinateLabels(LabeledDimensionRef dim)
    bint LabeledDimensionSetCoordinateLabels(LabeledDimensionRef dim, OCArrayRef labels, OCStringRef *outError)
    bint LabeledDimensionSetCoordinateLabelAtIndex(LabeledDimensionRef dim, OCIndex index, OCStringRef label)

    # 2.3 SIDimension - SI unit-based coordinate systems (base class)
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

    # 2.4 SILinearDimension - Linearly spaced coordinate systems
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

    # 2.5 SIMonotonicDimension - Monotonic coordinate systems
    SIMonotonicDimensionRef SIMonotonicDimensionCreate(OCStringRef label, OCStringRef description,
                                                       OCDictionaryRef metadata, OCStringRef quantityName,
                                                       SIScalarRef offset, SIScalarRef origin, SIScalarRef period,
                                                       dimensionScaling scaling, OCArrayRef coordinates,
                                                       SIDimensionRef reciprocal, OCStringRef *outError)
    OCArrayRef SIMonotonicDimensionCopyCoordinates(SIMonotonicDimensionRef dim)
    bint SIMonotonicDimensionSetCoordinates(SIMonotonicDimensionRef dim, OCArrayRef coords, OCStringRef *outError)
    OCArrayRef SIMonotonicDimensionCreateAbsoluteCoordinates(SIMonotonicDimensionRef dim)
    SIDimensionRef SIMonotonicDimensionCopyReciprocal(SIMonotonicDimensionRef dim)
    bint SIMonotonicDimensionSetReciprocal(SIMonotonicDimensionRef dim, SIDimensionRef rec, OCStringRef *outError)

    # ================================================================================
    # 3. SparseSampling API - Sparse sampling pattern definitions
    # ================================================================================

    SparseSamplingRef SparseSamplingCreate(OCIndexSetRef dimensionIndexes,
                                           OCArrayRef sparseGridVertexes,
                                           OCNumberType unsignedIntegerType,
                                           OCStringRef encoding,
                                           OCStringRef description,
                                           OCDictionaryRef metadata,
                                           OCStringRef *outError)
    SparseSamplingRef SparseSamplingCreateFromJSON(cJSON *json, OCStringRef *outError)
    OCDictionaryRef SparseSamplingCopyAsDictionary(SparseSamplingRef ss)

    # SparseSampling property accessors
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

    # ================================================================================
    # 4. DependentVariable API - Dataset variables with metadata and components
    # ================================================================================

    # 4.1 Core creation and management
    DependentVariableRef DependentVariableCreate(OCStringRef name, OCStringRef description,
                                                  SIUnitRef unit, OCStringRef quantityName,
                                                  OCStringRef quantityType, OCNumberType elementType,
                                                  OCArrayRef componentLabels, OCArrayRef components,
                                                  OCStringRef *outError)
    DependentVariableRef DependentVariableCreateFromJSON(cJSON *json, OCStringRef *outError)
    DependentVariableRef DependentVariableCopy(DependentVariableRef orig)

    # 4.2 Property accessors (string properties - memory-safe copy functions)
    OCStringRef DependentVariableCopyName(DependentVariableRef dv)
    OCStringRef DependentVariableCopyDescription(DependentVariableRef dv)
    OCStringRef DependentVariableCopyQuantityType(DependentVariableRef dv)
    OCStringRef DependentVariableCopyQuantityName(DependentVariableRef dv)
    OCStringRef DependentVariableCopyEncoding(DependentVariableRef dv)
    OCStringRef DependentVariableCopyType(DependentVariableRef dv)

    # 4.3 Property setters
    bint DependentVariableSetName(DependentVariableRef dv, OCStringRef name)
    bint DependentVariableSetDescription(DependentVariableRef dv, OCStringRef desc)
    bint DependentVariableSetQuantityName(DependentVariableRef dv, OCStringRef quantityName)

    # 4.4 Numeric and structural properties
    OCNumberType DependentVariableGetNumericType(DependentVariableRef dv)
    OCIndex DependentVariableGetComponentCount(DependentVariableRef dv)
    OCIndex DependentVariableGetSize(DependentVariableRef dv)
    bint DependentVariableSetSize(DependentVariableRef dv, OCIndex new_size)

    # 4.5 Component management
    OCMutableArrayRef DependentVariableCopyComponents(DependentVariableRef dv)
    bint DependentVariableSetComponents(DependentVariableRef dv, OCArrayRef components_array)

    # 4.6 Sparse sampling management
    SparseSamplingRef DependentVariableCopySparseSampling(DependentVariableRef dv)
    bint DependentVariableSetSparseSampling(DependentVariableRef dv, SparseSamplingRef sparse_ref)

    # 4.7 Data access and manipulation
    bint DependentVariableSetValueAtMemOffset(DependentVariableRef dv, OCIndex compIdx, OCIndex memOffset, SIScalarRef value, OCStringRef *error)

    # 4.8 Unit conversion and data manipulation
    bint DependentVariableConvertToUnit(DependentVariableRef dv, SIUnitRef unit, OCStringRef *error)
    bint DependentVariableSetValuesToZero(DependentVariableRef dv, int64_t componentIndex)
    bint DependentVariableZeroPartInRange(DependentVariableRef dv, OCIndex componentIndex, OCRange range, complexPart part)
    bint DependentVariableTakeAbsoluteValue(DependentVariableRef dv, int64_t componentIndex)
    bint DependentVariableMultiplyValuesByDimensionlessComplexConstant(DependentVariableRef dv, int64_t componentIndex, double complex constant)
    bint DependentVariableTakeComplexPart(DependentVariableRef dv, OCIndex componentIndex, complexPart part)
    bint DependentVariableConjugate(DependentVariableRef dv, OCIndex componentIndex)
    bint DependentVariableMultiplyValuesByDimensionlessRealConstant(DependentVariableRef dv, OCIndex componentIndex, double constant)

    # 4.9 Arithmetic operations between DependentVariables
    bint DependentVariableAdd(DependentVariableRef dv1, DependentVariableRef dv2)
    bint DependentVariableSubtract(DependentVariableRef dv1, DependentVariableRef dv2)
    bint DependentVariableMultiply(DependentVariableRef dv1, DependentVariableRef dv2)
    bint DependentVariableDivide(DependentVariableRef dv1, DependentVariableRef dv2)

    # 4.10 Operations with other DependentVariables
    bint DependentVariableAppend(DependentVariableRef dv, DependentVariableRef other_dv, OCStringRef *err_ocstr)

    # Note: DependentVariable inherits from SIQuantity, so all SIQuantity functions
    # (declared in sitypes.pxd) can be used with DependentVariableRef cast to SIQuantityRef

    # ================================================================================
    # 5. GeographicCoordinate API - Geospatial location metadata
    # ================================================================================

    GeographicCoordinateRef GeographicCoordinateCreate(SIScalarRef latitude, SIScalarRef longitude,
                                                       SIScalarRef altitude, OCDictionaryRef metadata,
                                                       OCStringRef *outError)
    GeographicCoordinateRef GeographicCoordinateCreateFromJSON(cJSON *json, OCStringRef *outError)
    OCDictionaryRef GeographicCoordinateCopyAsDictionary(GeographicCoordinateRef gc)
    GeographicCoordinateRef GeographicCoordinateCreateCopy(GeographicCoordinateRef gc)

    # GeographicCoordinate property accessors
    SIScalarRef GeographicCoordinateGetLatitude(GeographicCoordinateRef gc)
    SIScalarRef GeographicCoordinateGetLongitude(GeographicCoordinateRef gc)
    SIScalarRef GeographicCoordinateGetAltitude(GeographicCoordinateRef gc)
    OCDictionaryRef GeographicCoordinateGetApplicationMetaData(GeographicCoordinateRef gc)

    # GeographicCoordinate property setters
    bint GeographicCoordinateSetLatitude(GeographicCoordinateRef gc, SIScalarRef latitude)
    bint GeographicCoordinateSetLongitude(GeographicCoordinateRef gc, SIScalarRef longitude)
    bint GeographicCoordinateSetAltitude(GeographicCoordinateRef gc, SIScalarRef altitude)
    bint GeographicCoordinateSetApplicationMetaData(GeographicCoordinateRef gc, OCDictionaryRef metadata)

    # ================================================================================
    # 6. Datum API - Focus points and coordinate references
    # ================================================================================

    DatumRef DatumCreate(SIScalarRef response,
                        OCIndex dependentVariableIndex, OCIndex componentIndex, OCIndex memOffset,
                        OCTypeRef owner, OCStringRef *outError)
    DatumRef DatumCopy(DatumRef theDatum)
    bint DatumHasSameReducedDimensionalities(DatumRef input1, DatumRef input2)
    OCDictionaryRef DatumCopyAsDictionary(DatumRef theDatum)
    DatumRef DatumCreateFromJSON(cJSON *json, OCStringRef *outError)

    # Datum property accessors
    OCIndex DatumGetComponentIndex(DatumRef theDatum)
    OCIndex DatumGetDependentVariableIndex(DatumRef theDatum)
    OCIndex DatumGetMemOffset(DatumRef theDatum)
    OCTypeRef DatumGetCoordinateAtIndex(DatumRef theDatum, OCIndex index)
    SIScalarRef DatumCreateResponse(DatumRef theDatum)
    OCIndex DatumCoordinatesCount(DatumRef theDatum)

    # Datum property setters
    void DatumSetComponentIndex(DatumRef theDatum, OCIndex componentIndex)
    void DatumSetDependentVariableIndex(DatumRef theDatum, OCIndex dependentVariableIndex)
    void DatumSetMemOffset(DatumRef theDatum, OCIndex memOffset)

    # ================================================================================
    # 7. Dataset API - Complete data structure with all components
    # ================================================================================

    # 7.1 Core creation and management
    DatasetRef DatasetCreate(OCArrayRef dimensions, OCIndexArrayRef dimensionPrecedence,
                           OCArrayRef dependentVariables, OCArrayRef tags,
                           OCStringRef description, OCStringRef title,
                           DatumRef focus, DatumRef previousFocus,
                           OCDictionaryRef metaData, OCStringRef *outError)
    DatasetRef DatasetCreateFromJSON(cJSON *json, OCStringRef *outError)
    DatasetRef DatasetCreateCopy(DatasetRef ds)
    DatasetRef DatasetCreateWithImport(const char *json_path, const char *binary_dir, OCStringRef *outError)
    bint DatasetExport(DatasetRef ds, const char *json_path, const char *binary_dir, OCStringRef *outError)

    # 7.2 Core structure accessors and mutators
    OCMutableArrayRef DatasetGetDimensions(DatasetRef dataset)
    bint DatasetSetDimensions(DatasetRef dataset, OCMutableArrayRef dims)
    OCMutableIndexArrayRef DatasetGetDimensionPrecedence(DatasetRef dataset)
    bint DatasetSetDimensionPrecedence(DatasetRef dataset, OCMutableIndexArrayRef order)
    OCMutableArrayRef DatasetGetDependentVariables(DatasetRef dataset)
    bint DatasetSetDependentVariables(DatasetRef dataset, OCMutableArrayRef dvs)
    OCIndex DatasetGetDependentVariableCount(DatasetRef dataset)
    DependentVariableRef DatasetAddEmptyDependentVariable(DatasetRef dataset, OCStringRef quantityType,
                                                          OCNumberType elementType, OCIndex size)

    # 7.3 Metadata accessors and mutators
    OCMutableArrayRef DatasetGetTags(DatasetRef ds)
    bint DatasetSetTags(DatasetRef ds, OCMutableArrayRef tags)
    OCStringRef DatasetGetDescription(DatasetRef ds)
    bint DatasetSetDescription(DatasetRef ds, OCStringRef desc)
    OCStringRef DatasetGetTitle(DatasetRef ds)
    bint DatasetSetTitle(DatasetRef ds, OCStringRef title)
    DatumRef DatasetGetFocus(DatasetRef ds)
    bint DatasetSetFocus(DatasetRef ds, DatumRef focus)
    DatumRef DatasetGetPreviousFocus(DatasetRef ds)
    bint DatasetSetPreviousFocus(DatasetRef ds, DatumRef previousFocus)
    OCDictionaryRef DatasetGetApplicationMetaData(DatasetRef dataset)
    bint DatasetSetApplicationMetaData(DatasetRef dataset, OCDictionaryRef md)

    # 7.4 CSDM-1.0 specific fields
    OCStringRef DatasetGetVersion(DatasetRef ds)
    bint DatasetSetVersion(DatasetRef ds, OCStringRef version)
    OCStringRef DatasetGetTimestamp(DatasetRef ds)
    bint DatasetSetTimestamp(DatasetRef ds, OCStringRef timestamp)
    GeographicCoordinateRef DatasetGetGeographicCoordinate(DatasetRef ds)
    bint DatasetSetGeographicCoordinate(DatasetRef ds, GeographicCoordinateRef gc)
    bint DatasetGetReadOnly(DatasetRef ds)
    bint DatasetSetReadOnly(DatasetRef ds, bint readOnly)

    # ================================================================================
    # 8. Utility Functions and Metadata Handling
    # ================================================================================

    # Universal accessors for RMNLib object properties
    OCStringRef RMNLibGetDescription(OCTypeRef theType, OCStringRef *outError)
    bint RMNLibSetDescription(OCTypeRef theType, OCStringRef description, OCStringRef *outError)
    OCDictionaryRef RMNLibGetApplicationMetaData(OCTypeRef theType, OCStringRef *outError)
    bint RMNLibSetApplicationMetaData(OCTypeRef theType, OCDictionaryRef metadata, OCStringRef *outError)

    # Internal library management (not exposed to Python users)
    void RMNLibTypesShutdown()
