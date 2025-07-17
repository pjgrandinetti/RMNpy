# Core type definitions for RMNpy - simplified to match actual API
from libc.stdint cimport *

cdef extern from "RMNLibrary.h":
    # Basic types
    ctypedef void* OCTypeRef
    ctypedef signed long OCIndex
    ctypedef unsigned int OCTypeID
    
    # String types
    ctypedef struct impl_OCString
    ctypedef const impl_OCString* OCStringRef
    OCStringRef OCStringCreateWithCString(const char* cstr)
    const char* OCStringGetCString(OCStringRef string)
    
    # Array types  
    ctypedef struct impl_OCArray
    ctypedef const impl_OCArray* OCArrayRef
    ctypedef impl_OCArray* OCMutableArrayRef
    
    # Data types
    ctypedef struct impl_OCData
    ctypedef const impl_OCData* OCDataRef
    
    # Dictionary types
    ctypedef struct impl_OCDictionary
    ctypedef const impl_OCDictionary* OCDictionaryRef
    
    # Index array types
    ctypedef struct impl_OCIndexArray
    ctypedef const impl_OCIndexArray* OCIndexArrayRef
    
    # SITypes
    ctypedef struct impl_SIScalar
    ctypedef const impl_SIScalar* SIScalarRef
    ctypedef struct impl_SIUnit
    ctypedef const impl_SIUnit* SIUnitRef
    
    # RMNLib core types
    ctypedef struct impl_Dataset
    ctypedef impl_Dataset* DatasetRef
    ctypedef struct impl_DependentVariable
    ctypedef impl_DependentVariable* DependentVariableRef
    ctypedef struct impl_Dimension
    ctypedef impl_Dimension* DimensionRef
    ctypedef struct impl_Datum
    ctypedef impl_Datum* DatumRef
    ctypedef struct impl_GeographicCoordinate
    ctypedef impl_GeographicCoordinate* GeographicCoordinateRef
    
    # OCTypes number types
    ctypedef enum OCNumberType:
        kOCNumberFloat64Type
    
    # Memory management
    void OCRetain(const void* obj)
    void OCRelease(const void* obj)
    
    # Dataset functions (actual API from Dataset.h)
    DatasetRef DatasetCreate(OCArrayRef dimensions, OCIndexArrayRef dimensionPrecedence, 
                           OCArrayRef dependentVariables, OCArrayRef tags,
                           OCStringRef description, OCStringRef title,
                           DatumRef focus, DatumRef previousFocus,
                           OCDictionaryRef metaData, OCStringRef* outError)
    DatasetRef DatasetCreateWithImport(const char* json_path, const char* binary_dir, OCStringRef* outError) 
    bint DatasetExport(DatasetRef ds, const char* json_path, const char* binary_dir, OCStringRef* outError)
    OCStringRef DatasetGetTitle(DatasetRef ds)
    OCStringRef DatasetGetDescription(DatasetRef ds)
    OCArrayRef DatasetGetDimensions(DatasetRef ds)
    OCArrayRef DatasetGetDependentVariables(DatasetRef ds)
    OCIndex DatasetGetDependentVariableCount(DatasetRef ds)
    DependentVariableRef DatasetGetDependentVariableAtIndex(DatasetRef ds, OCIndex index)
    
    # DependentVariable functions (actual API from DependentVariable.h)
    DependentVariableRef DependentVariableCreate(OCStringRef name, OCStringRef description,
                                                SIUnitRef unit, OCStringRef quantityName,
                                                OCStringRef quantityType, OCNumberType elementType,
                                                OCArrayRef componentLabels, OCArrayRef components,
                                                OCStringRef* outError)
    DependentVariableRef DependentVariableCreateDefault(OCStringRef quantityType, OCNumberType elementType,
                                                       OCIndex size, OCStringRef* outError)
    OCStringRef DependentVariableGetName(DependentVariableRef dv)
    OCStringRef DependentVariableGetDescription(DependentVariableRef dv)
    OCStringRef DependentVariableGetUnitSymbol(DependentVariableRef dv)
    bint DependentVariableSetName(DependentVariableRef dv, OCStringRef newName)
    bint DependentVariableSetDescription(DependentVariableRef dv, OCStringRef newDesc)
    
    # Dimension functions (basic accessors)
    OCStringRef DimensionGetLabel(DimensionRef dim)
    OCStringRef DimensionGetDescription(DimensionRef dim)
    OCIndex DimensionGetCount(DimensionRef dim)
    
    # Library shutdown
    void RMNLibTypesShutdown()
