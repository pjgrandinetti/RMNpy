# Core type definitions for RMNpy - simplified to match actual API
from libc.stdint cimport *

cdef extern from "RMNLibrary.h":
    # Basic types
    ctypedef void* OCTypeRef
    ctypedef signed long OCIndex
    ctypedef unsigned int OCTypeID
    
    # Range type for indexing operations
    ctypedef struct OCRange:
        uint64_t location
        uint64_t length
    
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
    ctypedef impl_OCData* OCMutableDataRef
    
    # Dictionary types
    ctypedef struct impl_OCDictionary
    ctypedef const impl_OCDictionary* OCDictionaryRef
    
    # Index array types
    ctypedef struct impl_OCIndexArray
    ctypedef const impl_OCIndexArray* OCIndexArrayRef
    ctypedef impl_OCIndexArray* OCMutableIndexArrayRef
    
    # SITypes
    ctypedef struct impl_SIScalar
    ctypedef const impl_SIScalar* SIScalarRef
    ctypedef struct impl_SIUnit
    ctypedef const impl_SIUnit* SIUnitRef
    ctypedef struct impl_SIDimensionality
    ctypedef const impl_SIDimensionality* SIDimensionalityRef
    ctypedef struct impl_SIQuantity
    ctypedef const impl_SIQuantity* SIQuantityRef
    
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
    ctypedef struct impl_SparseSampling
    ctypedef impl_SparseSampling* SparseSamplingRef
    
    # Index types from OCTypes
    ctypedef struct impl_OCIndexSet
    ctypedef const impl_OCIndexSet* OCIndexSetRef
    ctypedef impl_OCIndexSet* OCMutableIndexSetRef
    ctypedef struct impl_OCIndexPairSet
    ctypedef const impl_OCIndexPairSet* OCIndexPairSetRef
    ctypedef impl_OCIndexPairSet* OCMutableIndexPairSetRef
    
    # OCTypes number types
    ctypedef enum OCNumberType:
        kOCNumberSInt8Type = 1
        kOCNumberSInt16Type
        kOCNumberSInt32Type
        kOCNumberSInt64Type
        kOCNumberFloat32Type
        kOCNumberFloat64Type
        kOCNumberUInt8Type
        kOCNumberUInt16Type
        kOCNumberUInt32Type
        kOCNumberUInt64Type
        kOCNumberComplex64Type
        kOCNumberComplex128Type
    
    # SITypes number types  
    ctypedef enum SINumberType:
        kSINumberFloat32Type
        kSINumberFloat64Type
        kSINumberComplex64Type
        kSINumberComplex128Type
    
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
    OCMutableArrayRef DatasetGetDimensions(DatasetRef ds)
    OCMutableArrayRef DatasetGetDependentVariables(DatasetRef ds)
    OCMutableArrayRef DatasetGetTags(DatasetRef ds)
    OCDictionaryRef DatasetGetMetaData(DatasetRef ds)
    OCMutableIndexArrayRef DatasetGetDimensionPrecedence(DatasetRef ds)
    
    # OCIndexArray functions for dimension precedence
    OCMutableIndexArrayRef OCIndexArrayCreateMutable(OCIndex capacity)
    bint OCIndexArrayAppendValue(OCMutableIndexArrayRef array, OCIndex index)
    OCMutableIndexArrayRef DatasetGetDimensionPrecedence(DatasetRef ds)
    bint DatasetSetDimensionPrecedence(DatasetRef ds, OCMutableIndexArrayRef order)
    bint DatasetSetDimensions(DatasetRef ds, OCMutableArrayRef dims)
    bint DatasetSetDependentVariables(DatasetRef ds, OCMutableArrayRef dvs)
    OCIndex DatasetGetDependentVariableCount(DatasetRef ds)
    DependentVariableRef DatasetGetDependentVariableAtIndex(DatasetRef ds, OCIndex index)
    OCMutableArrayRef DatasetGetTags(DatasetRef ds)
    bint DatasetSetTags(DatasetRef ds, OCMutableArrayRef tags)
    bint DatasetSetDescription(DatasetRef ds, OCStringRef desc)
    bint DatasetSetTitle(DatasetRef ds, OCStringRef title)
    DatumRef DatasetGetFocus(DatasetRef ds)
    bint DatasetSetFocus(DatasetRef ds, DatumRef focus)
    DatumRef DatasetGetPreviousFocus(DatasetRef ds)
    bint DatasetSetPreviousFocus(DatasetRef ds, DatumRef previousFocus)
    OCDictionaryRef DatasetGetMetaData(DatasetRef ds)
    bint DatasetSetMetaData(DatasetRef ds, OCDictionaryRef md)
    
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
    OCStringRef DependentVariableGetQuantityType(DependentVariableRef dv)
    bint DependentVariableSetName(DependentVariableRef dv, OCStringRef newName)
    bint DependentVariableSetDescription(DependentVariableRef dv, OCStringRef newDesc)
    
    # SIQuantity functions (DependentVariable inherits from SIQuantity)
    SIUnitRef SIQuantityGetUnit(SIQuantityRef quantity)
    SIDimensionalityRef SIQuantityGetUnitDimensionality(SIQuantityRef quantity)
    SINumberType SIQuantityGetElementType(SIQuantityRef quantity)
    
    # SIUnit functions for getting symbol
    OCStringRef SIUnitCopyRootSymbol(SIUnitRef theUnit)
    SIUnitRef SIUnitFromExpression(OCStringRef expression, double* unit_multiplier, OCStringRef* error)
    
    # Additional SIUnit functions
    SIDimensionalityRef SIUnitGetDimensionality(SIUnitRef theUnit)
    OCStringRef SIUnitCopySymbol(SIUnitRef theUnit)
    OCStringRef SIUnitCreateSymbol(SIUnitRef theUnit)
    OCStringRef SIUnitCreateName(SIUnitRef theUnit)
    OCStringRef SIUnitCreatePluralName(SIUnitRef theUnit)
    bint SIUnitEqual(SIUnitRef theUnit1, SIUnitRef theUnit2)
    bint SIUnitAreEquivalentUnits(SIUnitRef theUnit1, SIUnitRef theUnit2)
    double SIUnitConversion(SIUnitRef initialUnit, SIUnitRef finalUnit)
    SIUnitRef SIUnitByMultiplying(SIUnitRef theUnit1, SIUnitRef theUnit2, double* unit_multiplier, OCStringRef* error)
    SIUnitRef SIUnitByDividing(SIUnitRef theUnit1, SIUnitRef theUnit2, double* unit_multiplier)
    SIUnitRef SIUnitByRaisingToPower(SIUnitRef input, double power, double* unit_multiplier, OCStringRef* error)
    SIUnitRef SIUnitFindWithName(OCStringRef input)
    SIUnitRef SIUnitFindWithUnderivedSymbol(OCStringRef symbol)
    SIUnitRef SIUnitDimensionlessAndUnderived()
    OCStringRef SIUnitGuessQuantityName(SIUnitRef theUnit)
    
    # Dimension functions (basic accessors)
    OCStringRef DimensionGetLabel(DimensionRef dim)
    OCStringRef DimensionGetDescription(DimensionRef dim)
    OCIndex DimensionGetCount(DimensionRef dim)
    
    # Dimension type declarations
    ctypedef struct impl_SILinearDimension
    ctypedef impl_SILinearDimension* SILinearDimensionRef
    ctypedef struct impl_SIMonotonicDimension
    ctypedef impl_SIMonotonicDimension* SIMonotonicDimensionRef
    ctypedef struct impl_SIDimension
    ctypedef impl_SIDimension* SIDimensionRef
    ctypedef struct impl_LabeledDimension
    ctypedef impl_LabeledDimension* LabeledDimensionRef
    
    # Scaling enum
    ctypedef enum dimensionScaling:
        kDimensionScalingNone
        
    # SILinearDimension functions  
    SILinearDimensionRef SILinearDimensionCreate(OCStringRef label, OCStringRef description,
                                               OCDictionaryRef metadata, OCStringRef quantityName,
                                               SIScalarRef offset, SIScalarRef origin,
                                               SIScalarRef period, bint periodic,
                                               dimensionScaling scaling, OCIndex count,
                                               SIScalarRef increment, bint fft,
                                               SIDimensionRef reciprocal, OCStringRef* outError)
    OCIndex SILinearDimensionGetCount(SILinearDimensionRef dim)
    SIScalarRef SILinearDimensionGetIncrement(SILinearDimensionRef dim)
    
    # SIMonotonicDimension functions
    SIMonotonicDimensionRef SIMonotonicDimensionCreate(OCStringRef label, OCStringRef description,
                                                      OCDictionaryRef metadata, OCStringRef quantityName,
                                                      SIScalarRef offset, SIScalarRef origin,
                                                      SIScalarRef period, bint periodic,
                                                      dimensionScaling scaling, OCArrayRef coordinates,
                                                      SIDimensionRef reciprocal, OCStringRef* outError)
    OCArrayRef SIMonotonicDimensionGetCoordinates(SIMonotonicDimensionRef dim)
    
    # SIDimension functions (base SI dimension)
    SIDimensionRef SIDimensionCreate(OCStringRef label, OCStringRef description,
                                    OCDictionaryRef metadata, OCStringRef quantityName,
                                    SIScalarRef offset, SIScalarRef origin,
                                    SIScalarRef period, bint periodic,
                                    dimensionScaling scaling, OCStringRef* outError)
    
    # LabeledDimension functions
    LabeledDimensionRef LabeledDimensionCreate(OCStringRef label, OCStringRef description,
                                              OCDictionaryRef metadata, OCArrayRef coordinateLabels,
                                              OCStringRef* outError)
    LabeledDimensionRef LabeledDimensionCreateWithCoordinateLabels(OCArrayRef labels)
    OCArrayRef LabeledDimensionGetCoordinateLabels(LabeledDimensionRef dim)
    OCTypeID LabeledDimensionGetTypeID()
    
    # OCTypeID function declarations
    OCTypeID SILinearDimensionGetTypeID()
    OCTypeID OCGetTypeID(OCTypeRef obj)
    
    # Datum functions (actual API from Datum.h)
    DatumRef DatumCreate(SIScalarRef response, OCArrayRef coordinates, OCIndex dependentVariableIndex, OCIndex componentIndex, OCIndex memOffset)
    SIScalarRef DatumCreateResponse(DatumRef theDatum)
    OCIndex DatumCoordinatesCount(DatumRef theDatum)
    SIScalarRef DatumGetCoordinateAtIndex(DatumRef theDatum, OCIndex index)
    OCIndex DatumGetComponentIndex(DatumRef theDatum)
    OCIndex DatumGetDependentVariableIndex(DatumRef theDatum)

    # OCArray functions (actual API from OCArray.h)
    ctypedef struct OCArrayCallBacks:
        int64_t version
        void* retain
        void* release
        void* copyDescription
        void* equal
    
    OCMutableArrayRef OCArrayCreateMutable(uint64_t capacity, const OCArrayCallBacks *callBacks)
    bint OCArrayAppendValue(OCMutableArrayRef theArray, const void *value)
    bint OCArrayAppendArray(OCMutableArrayRef theArray, OCArrayRef otherArray, OCRange range)
    uint64_t OCArrayGetCount(OCArrayRef theArray)
    const void* OCArrayGetValueAtIndex(OCArrayRef theArray, uint64_t index)
    
    # OCData functions
    OCMutableDataRef OCDataCreateMutable(uint64_t capacity)
    void OCDataSetLength(OCMutableDataRef theData, uint64_t length)
    uint8_t* OCDataGetMutableBytes(OCMutableDataRef theData)
    uint64_t OCDataGetLength(OCDataRef theData)
    uint64_t OCNumberTypeSize(OCNumberType type)
    
    # Global constants
    const OCArrayCallBacks kOCTypeArrayCallBacks
    
    # SIScalar functions (actual API from SIScalar.h)
    SIScalarRef SIScalarCreateWithDouble(double input_value, SIUnitRef unit)
    SIScalarRef SIScalarCreateFromExpression(OCStringRef string, OCStringRef* error)
    double SIScalarDoubleValueInCoherentUnit(SIScalarRef theScalar)
    
    # NOTE: SIDimensionality functions moved to separate SILibrary.h extern block below
    
    # SparseSampling functions (actual API from SparseSampling.h)
    SparseSamplingRef SparseSamplingCreate(OCIndexSetRef dimensionIndexes,
                                         OCArrayRef sparseGridVertexes,
                                         OCNumberType unsignedIntegerType,
                                         OCStringRef encoding,
                                         OCStringRef description,
                                         OCDictionaryRef metadata,
                                         OCStringRef* outError)
    OCDictionaryRef SparseSamplingCopyAsDictionary(SparseSamplingRef ss)
    SparseSamplingRef SparseSamplingCreateFromDictionary(OCDictionaryRef dict, OCStringRef* outError)
    bint validateSparseSampling(SparseSamplingRef ss, OCStringRef* outError)
    
    # SparseSampling accessors
    OCIndexSetRef SparseSamplingGetDimensionIndexes(SparseSamplingRef ss)
    bint SparseSamplingSetDimensionIndexes(SparseSamplingRef ss, OCIndexSetRef idxSet)
    OCArrayRef SparseSamplingGetSparseGridVertexes(SparseSamplingRef ss)
    bint SparseSamplingSetSparseGridVertexes(SparseSamplingRef ss, OCArrayRef verts)
    OCNumberType SparseSamplingGetUnsignedIntegerType(SparseSamplingRef ss)
    bint SparseSamplingSetUnsignedIntegerType(SparseSamplingRef ss, OCNumberType type)
    OCStringRef SparseSamplingGetEncoding(SparseSamplingRef ss)
    bint SparseSamplingSetEncoding(SparseSamplingRef ss, OCStringRef encoding)
    OCStringRef SparseSamplingGetDescription(SparseSamplingRef ss)
    bint SparseSamplingSetDescription(SparseSamplingRef ss, OCStringRef desc)
    OCDictionaryRef SparseSamplingGetMetaData(SparseSamplingRef ss)
    bint SparseSamplingSetMetaData(SparseSamplingRef ss, OCDictionaryRef metadata)
    
    # OCIndexSet functions (basic OCTypes API)
    OCMutableIndexSetRef OCIndexSetCreateMutable()
    bint OCIndexSetAddIndex(OCMutableIndexSetRef theSet, OCIndex theIndex)
    uint64_t OCIndexSetGetCount(OCIndexSetRef theSet)
    OCIndex* OCIndexSetGetBytesPtr(OCIndexSetRef theSet)
    OCArrayRef OCIndexSetCreateOCNumberArray(OCIndexSetRef theSet)
    
    # OCNumber functions for array access
    ctypedef struct impl_OCNumber
    ctypedef const impl_OCNumber* OCNumberRef
    int64_t OCNumberGetInt64Value(OCNumberRef number)
    
    # Library shutdown
    void RMNLibTypesShutdown()

    # Additional OCIndexArray functions (types already declared above)
    uint64_t OCIndexArrayGetCount(OCIndexArrayRef array)
    OCIndex OCIndexArrayGetValueAtIndex(OCIndexArrayRef array, uint64_t index)

# SIScalar arithmetic operations (declarations only, no header include to avoid conflicts)
cdef extern from *:
    """
    // Forward declarations for SIScalar arithmetic functions
    // These match the signatures in SIScalar.h but avoid header inclusion conflicts
    extern void* SIScalarCreateByAdding(void* input1, void* input2, void** error);
    extern void* SIScalarCreateBySubtracting(void* input1, void* input2, void** error);
    extern void* SIScalarCreateByMultiplying(void* input1, void* input2, void** error);
    extern void* SIScalarCreateByDividing(void* input1, void* input2, void** error);
    extern void* SIScalarCreateByRaisingToPower(void* theScalar, double power, void** error);
    extern void* SIScalarCreateUnitString(void* theScalar);
    """
    SIScalarRef SIScalarCreateByAdding(SIScalarRef input1, SIScalarRef input2, OCStringRef* error)
    SIScalarRef SIScalarCreateBySubtracting(SIScalarRef input1, SIScalarRef input2, OCStringRef* error)
    SIScalarRef SIScalarCreateByMultiplying(SIScalarRef input1, SIScalarRef input2, OCStringRef* error)
    SIScalarRef SIScalarCreateByDividing(SIScalarRef input1, SIScalarRef input2, OCStringRef* error)
    SIScalarRef SIScalarCreateByRaisingToPower(SIScalarRef theScalar, double power, OCStringRef* error)
    OCStringRef SIScalarCreateUnitString(SIScalarRef theScalar)

# Minimal SIDimensionality function declarations to avoid header conflicts
cdef extern from *:
    """
    // Forward declarations for SIDimensionality functions
    #include <stdint.h>
    
    // Enum for base dimension indices
    typedef enum {
        kSILengthIndex = 0,
        kSIMassIndex = 1,  
        kSITimeIndex = 2,
        kSICurrentIndex = 3,
        kSITemperatureIndex = 4,
        kSIAmountIndex = 5,
        kSILuminousIntensityIndex = 6,
    } SIBaseDimensionIndex;
    
    // Function declarations (these exist in the library)
    extern SIDimensionalityRef SIDimensionalityDimensionless(void);
    extern SIDimensionalityRef SIDimensionalityParseExpression(OCStringRef expression, OCStringRef *error);
    extern SIDimensionalityRef SIDimensionalityForQuantity(OCStringRef quantity, OCStringRef *error);
    extern OCStringRef SIDimensionalityGetSymbol(SIDimensionalityRef theDim);
    extern int8_t SIDimensionalityReducedExponentAtIndex(SIDimensionalityRef theDim, SIBaseDimensionIndex index);
    extern SIDimensionalityRef SIDimensionalityByMultiplying(SIDimensionalityRef theDim1, SIDimensionalityRef theDim2, OCStringRef *error);
    extern SIDimensionalityRef SIDimensionalityByDividing(SIDimensionalityRef theDim1, SIDimensionalityRef theDim2);
    extern SIDimensionalityRef SIDimensionalityByRaisingToPower(SIDimensionalityRef theDim, double power, OCStringRef *error);
    extern SIDimensionalityRef SIDimensionalityByTakingNthRoot(SIDimensionalityRef theDim, uint8_t root, OCStringRef *error);
    
    // SIUnit function that needs explicit declaration
    extern OCStringRef SIUnitCopySymbol(SIUnitRef theUnit);
    """
    
    # SIBaseDimensionIndex enum 
    ctypedef enum SIBaseDimensionIndex:
        kSILengthIndex = 0
        kSIMassIndex = 1  
        kSITimeIndex = 2
        kSICurrentIndex = 3
        kSITemperatureIndex = 4
        kSIAmountIndex = 5
        kSILuminousIntensityIndex = 6
    
    # SIDimensionality core functions
    SIDimensionalityRef SIDimensionalityParseExpression(OCStringRef expression, OCStringRef* error)
    SIDimensionalityRef SIDimensionalityDimensionless()
    SIDimensionalityRef SIDimensionalityForQuantity(OCStringRef quantity, OCStringRef* error)
    
    # SITypes quantity constants - complete list from SIDimensionality.h
    extern OCStringRef kSIQuantityDimensionless
    extern OCStringRef kSIQuantityLength
    extern OCStringRef kSIQuantityInverseLength
    extern OCStringRef kSIQuantityWavenumber
    extern OCStringRef kSIQuantityLengthRatio
    extern OCStringRef kSIQuantityPlaneAngle
    extern OCStringRef kSIQuantityMass
    extern OCStringRef kSIQuantityInverseMass
    extern OCStringRef kSIQuantityMassRatio
    extern OCStringRef kSIQuantityTime
    extern OCStringRef kSIQuantityInverseTime
    extern OCStringRef kSIQuantityFrequency
    extern OCStringRef kSIQuantityRadioactivity
    extern OCStringRef kSIQuantityTimeRatio
    extern OCStringRef kSIQuantityFrequencyRatio
    extern OCStringRef kSIQuantityInverseTimeSquared
    extern OCStringRef kSIQuantityCurrent
    extern OCStringRef kSIQuantityInverseCurrent
    extern OCStringRef kSIQuantityCurrentRatio
    extern OCStringRef kSIQuantityTemperature
    extern OCStringRef kSIQuantityInverseTemperature
    extern OCStringRef kSIQuantityTemperatureRatio
    extern OCStringRef kSIQuantityTemperatureGradient
    extern OCStringRef kSIQuantityAmount
    extern OCStringRef kSIQuantityInverseAmount
    extern OCStringRef kSIQuantityAmountRatio
    extern OCStringRef kSIQuantityLuminousIntensity
    extern OCStringRef kSIQuantityInverseLuminousIntensity
    extern OCStringRef kSIQuantityLuminousIntensityRatio
    extern OCStringRef kSIQuantityArea
    extern OCStringRef kSIQuantityInverseArea
    extern OCStringRef kSIQuantityAreaRatio
    extern OCStringRef kSIQuantitySolidAngle
    extern OCStringRef kSIQuantityVolume
    extern OCStringRef kSIQuantityInverseVolume
    extern OCStringRef kSIQuantityVolumeRatio
    extern OCStringRef kSIQuantitySpeed
    extern OCStringRef kSIQuantityVelocity
    extern OCStringRef kSIQuantityLinearMomentum
    extern OCStringRef kSIQuantityAngularMomentum
    extern OCStringRef kSIQuantityMomentOfInertia
    extern OCStringRef kSIQuantityAcceleration
    extern OCStringRef kSIQuantityMassFlowRate
    extern OCStringRef kSIQuantityMassFlux
    extern OCStringRef kSIQuantityDensity
    extern OCStringRef kSIQuantitySpecificGravity
    extern OCStringRef kSIQuantitySpecificSurfaceArea
    extern OCStringRef kSIQuantitySurfaceAreaToVolumeRatio
    extern OCStringRef kSIQuantitySurfaceDensity
    extern OCStringRef kSIQuantitySpecificVolume
    extern OCStringRef kSIQuantityCurrentDensity
    extern OCStringRef kSIQuantityMagneticFieldStrength
    extern OCStringRef kSIQuantityLuminance
    extern OCStringRef kSIQuantityRefractiveIndex
    extern OCStringRef kSIQuantityFluidity
    extern OCStringRef kSIQuantityMomentOfForce
    extern OCStringRef kSIQuantitySurfaceTension
    extern OCStringRef kSIQuantitySurfaceEnergy
    extern OCStringRef kSIQuantityAngularSpeed
    extern OCStringRef kSIQuantityAngularVelocity
    extern OCStringRef kSIQuantityAngularAcceleration
    extern OCStringRef kSIQuantityHeatFluxDensity
    extern OCStringRef kSIQuantityIrradiance
    extern OCStringRef kSIQuantitySpectralRadiantFluxDensity
    extern OCStringRef kSIQuantityHeatCapacity
    extern OCStringRef kSIQuantityEntropy
    extern OCStringRef kSIQuantitySpecificHeatCapacity
    extern OCStringRef kSIQuantitySpecificEntropy
    extern OCStringRef kSIQuantitySpecificEnergy
    extern OCStringRef kSIQuantityThermalConductance
    extern OCStringRef kSIQuantityThermalConductivity
    extern OCStringRef kSIQuantityEnergyDensity
    extern OCStringRef kSIQuantityElectricFieldStrength
    extern OCStringRef kSIQuantityElectricFieldGradient
    extern OCStringRef kSIQuantityElectricChargeDensity
    extern OCStringRef kSIQuantitySurfaceChargeDensity
    extern OCStringRef kSIQuantityElectricFlux
    extern OCStringRef kSIQuantityElectricFluxDensity
    extern OCStringRef kSIQuantityElectricDisplacement
    extern OCStringRef kSIQuantityPermittivity
    extern OCStringRef kSIQuantityPermeability
    extern OCStringRef kSIQuantityMolarEnergy
    extern OCStringRef kSIQuantityMolarEntropy
    extern OCStringRef kSIQuantityMolarHeatCapacity
    extern OCStringRef kSIQuantityMolarMass
    extern OCStringRef kSIQuantityMolality
    extern OCStringRef kSIQuantityDiffusionFlux
    extern OCStringRef kSIQuantityMassToChargeRatio
    extern OCStringRef kSIQuantityChargeToMassRatio
    extern OCStringRef kSIQuantityRadiationExposure
    extern OCStringRef kSIQuantityAbsorbedDoseRate
    extern OCStringRef kSIQuantityRadiantIntensity
    extern OCStringRef kSIQuantitySpectralRadiantIntensity
    extern OCStringRef kSIQuantityRadiance
    extern OCStringRef kSIQuantitySpectralRadiance
    extern OCStringRef kSIQuantityPorosity
    extern OCStringRef kSIQuantityAngularFrequency
    extern OCStringRef kSIQuantityForce
    extern OCStringRef kSIQuantityTorque
    extern OCStringRef kSIQuantityPressure
    extern OCStringRef kSIQuantityStress
    extern OCStringRef kSIQuantityElasticModulus
    extern OCStringRef kSIQuantityCompressibility
    extern OCStringRef kSIQuantityStressOpticCoefficient
    extern OCStringRef kSIQuantityPressureGradient
    extern OCStringRef kSIQuantityEnergy
    extern OCStringRef kSIQuantitySpectralRadiantEnergy
    extern OCStringRef kSIQuantityPower
    extern OCStringRef kSIQuantitySpectralPower
    extern OCStringRef kSIQuantityVolumePowerDensity
    extern OCStringRef kSIQuantitySpecificPower
    extern OCStringRef kSIQuantityRadiantFlux
    extern OCStringRef kSIQuantityElectricCharge
    extern OCStringRef kSIQuantityAmountOfElectricity
    extern OCStringRef kSIQuantityElectricPotentialDifference
    extern OCStringRef kSIQuantityElectromotiveForce
    extern OCStringRef kSIQuantityElectricPolarizability
    extern OCStringRef kSIQuantityElectricDipoleMoment
    extern OCStringRef kSIQuantityVoltage
    extern OCStringRef kSIQuantityCapacitance
    extern OCStringRef kSIQuantityElectricResistance
    extern OCStringRef kSIQuantityElectricResistancePerLength
    extern OCStringRef kSIQuantityElectricResistivity
    extern OCStringRef kSIQuantityElectricConductance
    extern OCStringRef kSIQuantityElectricConductivity
    extern OCStringRef kSIQuantityElectricalMobility
    extern OCStringRef kSIQuantityMolarConductivity
    extern OCStringRef kSIQuantityMagneticDipoleMoment
    extern OCStringRef kSIQuantityMagneticDipoleMomentRatio
    extern OCStringRef kSIQuantityMagneticFlux
    extern OCStringRef kSIQuantityMagneticFluxDensity
    extern OCStringRef kSIQuantityMolarMagneticSusceptibility
    extern OCStringRef kSIQuantityInverseMagneticFluxDensity
    extern OCStringRef kSIQuantityMagneticFieldGradient
    extern OCStringRef kSIQuantityInductance
    extern OCStringRef kSIQuantityLuminousFlux
    extern OCStringRef kSIQuantityLuminousFluxDensity
    extern OCStringRef kSIQuantityLuminousEnergy
    extern OCStringRef kSIQuantityIlluminance
    extern OCStringRef kSIQuantityAbsorbedDose
    extern OCStringRef kSIQuantityDoseEquivalent
    extern OCStringRef kSIQuantityCatalyticActivity
    extern OCStringRef kSIQuantityCatalyticActivityConcentration
    extern OCStringRef kSIQuantityCatalyticActivityContent
    extern OCStringRef kSIQuantityAction
    extern OCStringRef kSIQuantityReducedAction
    extern OCStringRef kSIQuantityKinematicViscosity
    extern OCStringRef kSIQuantityDiffusionCoefficient
    extern OCStringRef kSIQuantityCirculation
    extern OCStringRef kSIQuantityDynamicViscosity
    extern OCStringRef kSIQuantityAmountConcentration
    extern OCStringRef kSIQuantityMassConcentration
    extern OCStringRef kSIQuantityChargePerAmount
    extern OCStringRef kSIQuantityGravitationalConstant
    extern OCStringRef kSIQuantityLengthPerVolume
    extern OCStringRef kSIQuantityVolumePerLength
    extern OCStringRef kSIQuantityVolumetricFlowRate
    extern OCStringRef kSIQuantityFrequencyPerMagneticFluxDensity
    extern OCStringRef kSIQuantityPowerPerLuminousFlux
    extern OCStringRef kSIQuantityLuminousEfficacy
    extern OCStringRef kSIQuantityRockPermeability
    extern OCStringRef kSIQuantityGyromagneticRatio
    extern OCStringRef kSIQuantityHeatTransferCoefficient
    extern OCStringRef kSIQuantityGasPermeance
    extern OCStringRef kSIQuantityPowerPerAreaPerTemperatureToFourthPower
    extern OCStringRef kSIQuantityFirstHyperPolarizability
    extern OCStringRef kSIQuantitySecondHyperPolarizability
    extern OCStringRef kSIQuantityElectricQuadrupoleMoment
    extern OCStringRef kSIQuantityMagnetizability
    extern OCStringRef kSIQuantitySecondRadiationConstant
    extern OCStringRef kSIQuantityWavelengthDisplacementConstant
    extern OCStringRef kSIQuantityFineStructureConstant
    extern OCStringRef kSIQuantityRatePerAmountConcentrationPerTime
    OCStringRef SIDimensionalityGetSymbol(SIDimensionalityRef theDim)
    int8_t SIDimensionalityReducedExponentAtIndex(SIDimensionalityRef theDim, SIBaseDimensionIndex index)
    
    # SIDimensionality arithmetic operations
    SIDimensionalityRef SIDimensionalityByMultiplying(SIDimensionalityRef theDim1, SIDimensionalityRef theDim2, OCStringRef* error)
    SIDimensionalityRef SIDimensionalityByDividing(SIDimensionalityRef theDim1, SIDimensionalityRef theDim2)
    SIDimensionalityRef SIDimensionalityByRaisingToPower(SIDimensionalityRef theDim, double power, OCStringRef* error)
    SIDimensionalityRef SIDimensionalityByTakingNthRoot(SIDimensionalityRef theDim, uint8_t root, OCStringRef* error)
    
    # SIUnit symbol functions (from SITypes library)
    OCStringRef SIUnitCopySymbol(SIUnitRef theUnit)
    OCStringRef SIUnitCreateSymbol(SIUnitRef theUnit)
