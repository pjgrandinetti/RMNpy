# cython: language_level=3

# Include all required headers - order matters!
cdef extern from "OCLibrary.h":
    # Basic OCTypes
    ctypedef unsigned long OCOptionFlags
    ctypedef signed long OCIndex
    ctypedef unsigned int OCTypeID
    
    # OCRange structure
    ctypedef struct OCRange:
        unsigned long location
        unsigned long length
    
    # OCTypes Ref types
    ctypedef struct impl_OCString
    ctypedef const impl_OCString* OCStringRef
    ctypedef struct impl_OCString* OCMutableStringRef
    
    ctypedef struct impl_OCArray
    ctypedef const impl_OCArray* OCArrayRef
    ctypedef struct impl_OCArray* OCMutableArrayRef
    
    ctypedef struct impl_OCDictionary
    ctypedef const impl_OCDictionary* OCDictionaryRef
    ctypedef struct impl_OCDictionary* OCMutableDictionaryRef
    
    ctypedef struct impl_OCNumber
    ctypedef const impl_OCNumber* OCNumberRef
    
    # Memory management
    void OCRetain(const void* ptr)
    void OCRelease(const void* ptr)
    
    # String functions
    OCStringRef OCStringCreateWithCString(const char* cStr)
    const char* OCStringGetCString(OCStringRef str)
    OCStringRef OCStringCreateCopy(OCStringRef str)
    
    # Array functions
    OCArrayRef OCArrayCreate(const void* const* values, OCIndex numValues, void* callbacks)
    OCIndex OCArrayGetCount(OCArrayRef array)
    const void* OCArrayGetValueAtIndex(OCArrayRef array, OCIndex idx)
    OCMutableArrayRef OCArrayCreateMutable(OCIndex capacity)
    void OCArrayAppendValue(OCMutableArrayRef array, const void* value)
    
    # Number functions
    OCNumberRef OCNumberCreateWithDouble(double value)
    double OCNumberGetDoubleValue(OCNumberRef number)

cdef extern from "SILibrary.h":
    # SITypes Ref types  
    ctypedef struct impl_SIScalar
    ctypedef const impl_SIScalar* SIScalarRef
    ctypedef struct impl_SIScalar* SIMutableScalarRef
    
    ctypedef struct impl_SIUnit
    ctypedef const impl_SIUnit* SIUnitRef
    
    ctypedef struct impl_SIQuantity  
    ctypedef const impl_SIQuantity* SIQuantityRef
    
    ctypedef struct impl_SIDimensionality
    ctypedef const impl_SIDimensionality* SIDimensionalityRef
    
    # SIScalar functions
    SIScalarRef SIScalarCreateWithDouble(double value, SIUnitRef unit)
    double SIScalarGetDoubleValue(SIScalarRef scalar)
    SIUnitRef SIScalarGetUnit(SIScalarRef scalar)
    OCStringRef SIScalarCreateStringValue(SIScalarRef scalar)
    
    # SIUnit functions
    SIUnitRef SIUnitCreateWithString(OCStringRef unitString, OCStringRef* outError)
    OCStringRef SIUnitCreateStringValue(SIUnitRef unit)
    
    # Cleanup
    void SITypesShutdown()

cdef extern from "RMNLibrary.h":
    # Dimension scaling enum
    ctypedef enum dimensionScaling:
        kDimensionScalingNone
        kDimensionScalingNMR
    
    # RMNLib types - these depend on OCTypes and SITypes above
    ctypedef struct impl_Dataset
    ctypedef impl_Dataset* DatasetRef
    
    ctypedef struct impl_Datum  
    ctypedef impl_Datum* DatumRef
    
    ctypedef struct impl_Dimension
    ctypedef impl_Dimension* DimensionRef
    
    ctypedef struct impl_LabeledDimension
    ctypedef impl_LabeledDimension* LabeledDimensionRef
    
    ctypedef struct impl_SIDimension
    ctypedef impl_SIDimension* SIDimensionRef
    
    ctypedef struct impl_SILinearDimension
    ctypedef impl_SILinearDimension* SILinearDimensionRef
    
    ctypedef struct impl_SIMonotonicDimension
    ctypedef impl_SIMonotonicDimension* SIMonotonicDimensionRef
    
    ctypedef struct impl_DependentVariable
    ctypedef impl_DependentVariable* DependentVariableRef
    
    ctypedef struct impl_GeographicCoordinate
    ctypedef impl_GeographicCoordinate* GeographicCoordinateRef
    
    ctypedef struct impl_SparseSampling
    ctypedef impl_SparseSampling* SparseSamplingRef
    
    # RMNLib functions
    DatasetRef DatasetCreate(OCArrayRef dimensions, 
                           OCArrayRef dimensionPrecedence,
                           OCArrayRef dependentVariables,
                           OCArrayRef tags,
                           OCStringRef description, 
                           OCStringRef title,
                           DatumRef focus,
                           OCDictionaryRef metadata,
                           OCStringRef* outError)
    
    OCStringRef DatasetGetTitle(DatasetRef dataset)
    OCStringRef DatasetGetDescription(DatasetRef dataset)
    OCArrayRef DatasetGetDimensions(DatasetRef dataset)
    OCArrayRef DatasetGetDependentVariables(DatasetRef dataset)
    
    DatumRef DatumCreate(SIScalarRef response,
                        OCArrayRef coordinates, 
                        OCIndex dependentVariableIndex,
                        OCIndex componentIndex,
                        OCIndex memOffset)
    
    SIScalarRef DatumGetResponse(DatumRef datum)
    OCArrayRef DatumGetCoordinates(DatumRef datum)
    OCIndex DatumGetComponentIndex(DatumRef datum)
    OCIndex DatumGetDependentVariableIndex(DatumRef datum)
    
    # Dimension functions
    OCStringRef DimensionGetLabel(DimensionRef dim)
    OCStringRef DimensionGetDescription(DimensionRef dim)
    OCStringRef DimensionGetType(DimensionRef dim)
    OCIndex DimensionGetCount(DimensionRef dim)
    
    # LabeledDimension functions
    LabeledDimensionRef LabeledDimensionCreateWithCoordinateLabels(OCArrayRef labels)
    OCArrayRef LabeledDimensionGetCoordinateLabels(LabeledDimensionRef dim)
    
    # SILinearDimension functions  
    SILinearDimensionRef SILinearDimensionCreate(OCStringRef label,
                                                OCStringRef description,
                                                OCDictionaryRef metadata,
                                                OCStringRef quantity,
                                                SIScalarRef offset,
                                                SIScalarRef origin,
                                                SIScalarRef period,
                                                bint periodic,
                                                dimensionScaling scaling,
                                                OCIndex count,
                                                SIScalarRef increment,
                                                bint fft,
                                                SIDimensionRef reciprocal,
                                                OCStringRef* outError)
    
    OCIndex SILinearDimensionGetCount(SILinearDimensionRef dim)
    SIScalarRef SILinearDimensionGetIncrement(SILinearDimensionRef dim)
    
    # Utility functions
    OCDictionaryRef DimensionCopyAsDictionary(DimensionRef dim)
    DimensionRef DimensionCreateFromDictionary(OCDictionaryRef dict, OCStringRef* outError)
    
    # Cleanup
    void RMNLibTypesShutdown()
