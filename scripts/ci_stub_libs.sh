#!/usr/bin/env bash
# scripts/ci_stub_libs.sh
# Create stub headers and libraries for CI builds
set -e

# Clean up old files
rm -f stub_sitypes.c stub_sitypes.o
rm -rf lib/* include/*
mkdir -p lib include/OCTypes include/SITypes include/RMNLib

# OCLibrary.h: full enum definition
cat > include/OCLibrary.h <<'EOF'
#ifndef OCLIBRARY_H
#define OCLIBRARY_H
#ifndef _OCLIBRARY_INCLUDED
#define _OCLIBRARY_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

typedef void* SIUnitRef;
typedef void* SIScalarRef;
typedef void* SIDimensionRef;
typedef void* SILinearDimensionRef;
typedef void* SIMonotonicDimensionRef;
typedef void* SIQuantityRef;
typedef void* SIDimensionalityRef;
typedef void* OCStringRef;
typedef void* OCTypeRef;
typedef void* OCArrayRef;
typedef void* OCMutableArrayRef;
typedef void* OCDictionaryRef;
typedef void* OCMutableDictionaryRef;
typedef void* OCNumberRef;
typedef void* OCIndexArrayRef;
typedef void* OCMutableIndexArrayRef;
typedef void* DatasetRef;
typedef void* DatumRef;
typedef void* DimensionRef;
typedef void* LabeledDimensionRef;
typedef void* DependentVariableRef;
typedef void* GeographicCoordinateRef;
typedef void* SparseSamplingRef;
typedef signed long OCIndex;
typedef unsigned long OCOptionFlags;
typedef unsigned int OCTypeID;
typedef int bint;
typedef enum { kDimensionScalingNone, kDimensionScalingNMR } dimensionScaling;

// OCArrayCallBacks struct
typedef struct {
    void *retain;
    void *release;
    void *copyDescription;
    int (*equal)(const void *, const void *);
} OCArrayCallBacks;

// Export the missing symbol
extern const OCArrayCallBacks kOCTypeArrayCallBacks;

// OCTypes function declarations
OCStringRef OCStringCreateWithCString(const char* cStr);
const char* OCStringGetCString(OCStringRef ocString);
OCMutableArrayRef OCArrayCreateMutable(OCIndex capacity, const OCArrayCallBacks* callBacks);
int OCArrayAppendValue(OCMutableArrayRef array, const void* value);
OCIndex OCArrayGetCount(OCArrayRef array);
const void* OCArrayGetValueAtIndex(OCArrayRef array, OCIndex idx);
OCIndexArrayRef OCIndexArrayCreateMutable(OCIndex capacity);
int OCIndexArrayAppendValue(OCMutableIndexArrayRef array, OCIndex value);
OCIndex OCIndexArrayGetCount(OCIndexArrayRef array);
OCIndex OCIndexArrayGetValueAtIndex(OCIndexArrayRef array, OCIndex idx);
void OCRelease(OCTypeRef ref);
OCTypeRef OCRetain(OCTypeRef ref);

#ifdef __cplusplus
}
#endif

#endif /* _OCLIBRARY_INCLUDED */
#endif /* OCLIBRARY_H */
EOF

# SILibrary.h: forward declaration only
cat > include/SILibrary.h <<'EOF'
#ifndef SILIBRARY_H
#define SILIBRARY_H
#ifndef _SILIBRARY_INCLUDED
#define _SILIBRARY_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

typedef void* SIUnitRef;
typedef void* SIScalarRef;
typedef void* SIDimensionRef;
typedef void* SILinearDimensionRef;
typedef void* SIMonotonicDimensionRef;
typedef void* SIQuantityRef;
typedef void* SIDimensionalityRef;
typedef void* OCStringRef;
typedef void* OCTypeRef;
typedef void* OCArrayRef;
typedef void* OCMutableArrayRef;
typedef void* OCDictionaryRef;
typedef void* OCMutableDictionaryRef;
typedef void* OCNumberRef;
typedef void* OCIndexArrayRef;
typedef void* OCMutableIndexArrayRef;
typedef void* DatasetRef;
typedef void* DatumRef;
typedef void* DimensionRef;
typedef void* LabeledDimensionRef;
typedef void* DependentVariableRef;
typedef void* GeographicCoordinateRef;
typedef void* SparseSamplingRef;
typedef signed long OCIndex;
typedef unsigned long OCOptionFlags;
typedef unsigned int OCTypeID;
typedef int bint;

// SITypes function declarations
SIScalarRef SIScalarCreateWithDouble(double value, SIUnitRef unit);
double SIScalarDoubleValueInCoherentUnit(SIScalarRef scalar);

#ifdef __cplusplus
}
#endif

#endif /* _SILIBRARY_INCLUDED */
#endif /* SILIBRARY_H */
EOF

# RMNLibrary.h: forward declaration only
cat > include/RMNLibrary.h <<'EOF'
#ifndef RMNLIBRARY_H
#define RMNLIBRARY_H

#ifdef __cplusplus
extern "C" {
#endif

typedef void* SIUnitRef;
typedef void* SIScalarRef;
typedef void* SIDimensionRef;
typedef void* SILinearDimensionRef;
typedef void* SIMonotonicDimensionRef;
typedef void* SIQuantityRef;
typedef void* SIDimensionalityRef;
typedef void* OCStringRef;
typedef void* OCTypeRef;
typedef void* OCArrayRef;
typedef void* OCMutableArrayRef;
typedef void* OCDictionaryRef;
typedef void* OCMutableDictionaryRef;
typedef void* OCNumberRef;
typedef void* OCIndexArrayRef;
typedef void* OCMutableIndexArrayRef;
typedef void* OCIndexSetRef;
typedef void* DatasetRef;
typedef void* DatumRef;
typedef void* DimensionRef;
typedef void* LabeledDimensionRef;
typedef void* DependentVariableRef;
typedef void* GeographicCoordinateRef;
typedef void* SparseSamplingRef;
typedef signed long OCIndex;
typedef unsigned long OCOptionFlags;
typedef unsigned int OCTypeID;
typedef int bint;

// Additional types needed for RMNpy
typedef void* OCDataRef;
typedef void* OCMutableDataRef;
typedef unsigned int OCNumberType;
typedef enum { kDimensionScalingNone, kDimensionScalingNMR } dimensionScaling;

// OCArrayCallBacks struct
typedef struct {
    void *retain;
    void *release;
    void *copyDescription;
    int (*equal)(const void *, const void *);
} OCArrayCallBacks;

// Export the missing symbol
extern const OCArrayCallBacks kOCTypeArrayCallBacks;

// Constants for OCNumberType
#define kOCNumberFloat64Type 1
#define kOCNumberFloat32Type 2
#define kOCNumberSInt32Type 3
#define kOCNumberSInt64Type 4
#define kOCNumberUInt32Type 5
#define kOCNumberUInt64Type 6
#define kOCNumberSInt16Type 7
#define kOCNumberUInt16Type 8
#define kOCNumberSInt8Type 9
#define kOCNumberUInt8Type 10
#define kOCNumberComplex64Type 11
#define kOCNumberComplex128Type 12

// ALL function declarations in one place

// OCTypes function declarations
OCStringRef OCStringCreateWithCString(const char* cStr);
const char* OCStringGetCString(OCStringRef ocString);
OCMutableArrayRef OCArrayCreateMutable(OCIndex capacity, const OCArrayCallBacks* callBacks);
int OCArrayAppendValue(OCMutableArrayRef array, const void* value);
OCIndex OCArrayGetCount(OCArrayRef array);
const void* OCArrayGetValueAtIndex(OCArrayRef array, OCIndex idx);
OCIndexArrayRef OCIndexArrayCreateMutable(OCIndex capacity);
int OCIndexArrayAppendValue(OCMutableIndexArrayRef array, OCIndex value);
OCIndex OCIndexArrayGetCount(OCIndexArrayRef array);
OCIndex OCIndexArrayGetValueAtIndex(OCIndexArrayRef array, OCIndex idx);
void OCRelease(OCTypeRef ref);
OCTypeRef OCRetain(OCTypeRef ref);

// SITypes function declarations
SIScalarRef SIScalarCreateWithDouble(double value, SIUnitRef unit);
double SIScalarDoubleValueInCoherentUnit(SIScalarRef scalar);
SIUnitRef SIUnitFromExpression(const char* expr, void* p1, void* p2);

// RMNLib function declarations
DatasetRef DatasetCreate(OCArrayRef dimensions, OCIndexArrayRef precedence, OCArrayRef depVars, OCArrayRef tags, OCStringRef desc, OCStringRef title, void* p1, void* p2, OCDictionaryRef meta, void* error);
DatasetRef DatasetCreateWithImport(const char* path, const char* binDir, void* error);
int DatasetExport(DatasetRef dataset, const char* path, const char* binDir, void* error);
OCStringRef DatasetGetTitle(DatasetRef dataset);
int DatasetSetTitle(DatasetRef dataset, OCStringRef title);
OCStringRef DatasetGetDescription(DatasetRef dataset);
int DatasetSetDescription(DatasetRef dataset, OCStringRef desc);
OCMutableArrayRef DatasetGetDimensions(DatasetRef dataset);
OCMutableArrayRef DatasetGetDependentVariables(DatasetRef dataset);
OCMutableIndexArrayRef DatasetGetDimensionPrecedence(DatasetRef dataset);
int DatasetSetDimensionPrecedence(DatasetRef dataset, OCIndexArrayRef precedence);
OCMutableArrayRef DatasetGetTags(DatasetRef dataset);
OCDictionaryRef DatasetGetMetaData(DatasetRef dataset);
void RMNLibTypesShutdown(void);

// Additional function declarations
OCIndex OCNumberTypeSize(OCNumberType type);
OCMutableDataRef OCDataCreateMutable(OCIndex capacity);
void OCDataSetLength(OCMutableDataRef data, OCIndex length);
void* OCDataGetMutableBytes(OCMutableDataRef data);
DependentVariableRef DependentVariableCreate(OCStringRef name, OCStringRef desc, SIUnitRef units, OCStringRef quantityName, OCStringRef quantityType, OCNumberType elementType, OCArrayRef componentLabels, OCArrayRef components, void* error);
OCStringRef DependentVariableGetName(DependentVariableRef depVar);
OCStringRef DependentVariableGetDescription(DependentVariableRef depVar);
SIQuantityRef DependentVariableGetQuantityType(DependentVariableRef var);
SIUnitRef SIQuantityGetUnit(SIQuantityRef quantity);
OCStringRef SIUnitCopyRootSymbol(SIUnitRef unit);

// Dimension function declarations
DimensionRef SILinearDimensionCreate(OCStringRef label, OCStringRef desc, OCDictionaryRef metadata, SIQuantityRef quantity, OCNumberRef offset, OCNumberRef origin, OCNumberRef period, OCOptionFlags flags1, dimensionScaling scaling, OCOptionFlags flags2, OCNumberRef increment, OCOptionFlags flags3, SIDimensionRef reciprocal, OCStringRef* error);
DimensionRef SIMonotonicDimensionCreate(OCStringRef label, OCStringRef desc, OCDictionaryRef metadata, SIQuantityRef quantity, OCNumberRef offset, OCNumberRef origin, OCNumberRef period, OCOptionFlags flags, dimensionScaling scaling, OCArrayRef coordinates, SIDimensionRef reciprocal, OCStringRef* error);
DimensionRef SIDimensionCreate(OCStringRef label, OCStringRef desc, OCDictionaryRef metadata, SIQuantityRef quantity, OCNumberRef offset, OCNumberRef origin, OCNumberRef period, OCOptionFlags flags, dimensionScaling scaling, OCStringRef* error);
DimensionRef LabeledDimensionCreateWithCoordinateLabels(OCArrayRef labels);
DimensionRef LabeledDimensionCreate(OCStringRef label, OCStringRef desc, OCDictionaryRef metadata, OCArrayRef labels, OCStringRef* error);
OCStringRef DimensionGetLabel(DimensionRef dimension);
OCStringRef DimensionGetDescription(DimensionRef dimension);
OCIndex DimensionGetCount(DimensionRef dimension);
OCTypeID OCGetTypeID(OCTypeRef obj);
OCTypeID SILinearDimensionGetTypeID(void);
OCTypeID LabeledDimensionGetTypeID(void);

// Datum function declarations
DatumRef DatumCreate(SIScalarRef response, OCArrayRef coords, OCIndex p1, OCIndex p2, OCIndex p3);
SIScalarRef DatumCreateResponse(DatumRef datum);
OCIndex DatumCoordinatesCount(DatumRef datum);
SIScalarRef DatumGetCoordinateAtIndex(DatumRef datum, OCIndex index);
OCIndex DatumGetComponentIndex(DatumRef datum);
OCIndex DatumGetDependentVariableIndex(DatumRef datum);

// Sparse sampling function declarations
SparseSamplingRef SparseSamplingCreate(OCIndexSetRef dimIndexes, void* gridVertexes, OCNumberType numberType, OCStringRef encoding, OCStringRef description, OCDictionaryRef metadata, OCStringRef* error);
OCStringRef SparseSamplingGetDescription(SparseSamplingRef sparseSampling);
int SparseSamplingSetDescription(SparseSamplingRef sparseSampling, OCStringRef description);
OCStringRef SparseSamplingGetEncoding(SparseSamplingRef sparseSampling);
int SparseSamplingSetEncoding(SparseSamplingRef sparseSampling, OCStringRef encoding);
OCNumberType SparseSamplingGetUnsignedIntegerType(SparseSamplingRef sparseSampling);
int SparseSamplingSetUnsignedIntegerType(SparseSamplingRef sparseSampling, OCNumberType numberType);
OCIndexSetRef SparseSamplingGetDimensionIndexes(SparseSamplingRef sparseSampling);
OCIndex OCIndexSetGetCount(OCIndexSetRef indexSet);
OCIndex* OCIndexSetGetBytesPtr(OCIndexSetRef indexSet);
OCArrayRef SparseSamplingGetSparseGridVertexes(SparseSamplingRef sparseSampling);
OCDictionaryRef SparseSamplingGetMetaData(SparseSamplingRef sparseSampling);
int validateSparseSampling(SparseSamplingRef sparseSampling, OCStringRef* error);

#ifdef __cplusplus
}
#endif

#endif
EOF

# Create comprehensive stub implementations for CI
cat > stub_sitypes.c << 'EOF'
#include <stdlib.h>
#include <stdbool.h>
#ifdef __cplusplus
extern "C" {
#endif

// Type definitions
typedef void* SIUnitRef;
typedef void* SIScalarRef;
typedef void* SIDimensionRef;
typedef void* SILinearDimensionRef;
typedef void* SIMonotonicDimensionRef;
typedef void* SIQuantityRef;
typedef void* SIDimensionalityRef;
typedef void* OCStringRef;
typedef void* OCTypeRef;
typedef void* OCArrayRef;
typedef void* OCMutableArrayRef;
typedef void* OCDictionaryRef;
typedef void* OCMutableDictionaryRef;
typedef void* OCNumberRef;
typedef void* OCIndexArrayRef;
typedef void* OCMutableIndexArrayRef;
typedef void* OCIndexSetRef;
typedef void* DatasetRef;
typedef void* DatumRef;
typedef void* DimensionRef;
typedef void* LabeledDimensionRef;
typedef void* DependentVariableRef;
typedef void* GeographicCoordinateRef;
typedef void* SparseSamplingRef;
typedef signed long OCIndex;
typedef unsigned long OCOptionFlags;
typedef unsigned int OCTypeID;
typedef int bint;

// OCArrayCallBacks struct
typedef struct {
    void *retain;
    void *release;
    void *copyDescription;
    int (*equal)(const void *, const void *);
} OCArrayCallBacks;

// Export the missing symbol
__attribute__((visibility("default"))) const OCArrayCallBacks kOCTypeArrayCallBacks = { NULL, NULL, NULL, NULL };

// OCTypes function stubs
void* OCStringCreateWithCString(const char* cStr) { return NULL; }
const char* OCStringGetCString(void* ocString) { return ""; }
void* OCArrayCreateMutable(OCIndex capacity, const OCArrayCallBacks* callBacks) { return NULL; }
int OCArrayAppendValue(void* array, const void* value) { return 0; }
OCIndex OCArrayGetCount(void* array) { return 0; }
void* OCArrayGetValueAtIndex(void* array, OCIndex idx) { return NULL; }
void* OCIndexArrayCreateMutable(OCIndex capacity) { return NULL; }
int OCIndexArrayAppendValue(void* array, OCIndex value) { return 0; }
OCIndex OCIndexArrayGetCount(void* array) { return 0; }
OCIndex OCIndexArrayGetValueAtIndex(void* array, OCIndex idx) { return 0; }
void OCRelease(void* ref) { }
void* OCRetain(void* ref) { return ref; }

// SITypes function stubs
void* SIScalarCreateWithDouble(double value, void* unit) { return NULL; }
double SIScalarDoubleValueInCoherentUnit(void* scalar) { return 0.0; }

// RMNLib function stubs
void* DatasetCreate(void* dimensions, void* precedence, void* depVars, void* tags, void* desc, void* title, void* p1, void* p2, void* meta, void* error) { return NULL; }
void* DatasetCreateWithImport(const char* path, const char* binDir, void* error) { return NULL; }
int DatasetExport(void* dataset, const char* path, const char* binDir, void* error) { return 0; }
void* DatasetGetTitle(void* dataset) { return NULL; }
int DatasetSetTitle(void* dataset, void* title) { return 0; }
void* DatasetGetDescription(void* dataset) { return NULL; }
int DatasetSetDescription(void* dataset, void* desc) { return 0; }
void* DatasetGetDimensions(void* dataset) { return NULL; }
void* DatasetGetDependentVariables(void* dataset) { return NULL; }
void* DatasetGetDimensionPrecedence(void* dataset) { return NULL; }
int DatasetSetDimensionPrecedence(void* dataset, void* precedence) { return 0; }
void* DatasetGetTags(void* dataset) { return NULL; }
void* DatasetGetMetaData(void* dataset) { return NULL; }
void RMNLibTypesShutdown(void) { }

// Additional function stubs needed for RMNpy
void* SIUnitFromExpression(const char* expr, void* p1, void* p2) { return NULL; }
OCIndex OCNumberTypeSize(unsigned int type) { return 8; } // Default to 8 bytes
void* OCDataCreateMutable(OCIndex capacity) { return NULL; }
void OCDataSetLength(void* data, OCIndex length) { }
void* OCDataGetMutableBytes(void* data) { return NULL; }
void* DependentVariableCreate(void* name, void* desc, void* units, void* quantityName, void* quantityType, unsigned int elementType, void* componentLabels, void* components, void* error) { return NULL; }
void* DependentVariableGetName(void* depVar) { return NULL; }
void* DependentVariableGetDescription(void* depVar) { return NULL; }
void* DependentVariableGetQuantityType(void* depVar) { return NULL; }
void* SIQuantityGetUnit(void* quantity) { return NULL; }
void* SIUnitCopyRootSymbol(void* unit) { return NULL; }

// Dimension function stubs
void* SILinearDimensionCreate(void* label, void* desc, void* metadata, void* quantity, void* offset, void* origin, void* period, void* p1, int scaling, void* p2, void* increment, void* p3, void* reciprocal, void* error) { return NULL; }
void* SIMonotonicDimensionCreate(void* label, void* desc, void* metadata, void* quantity, void* offset, void* origin, void* period, void* p1, int scaling, void* coordinates, void* reciprocal, void* error) { return NULL; }
void* SIDimensionCreate(void* label, void* desc, void* metadata, void* quantity, void* offset, void* origin, void* period, void* p1, int scaling, void* error) { return NULL; }
void* LabeledDimensionCreateWithCoordinateLabels(void* labels) { return NULL; }
void* LabeledDimensionCreate(void* label, void* desc, void* metadata, void* labels, void* error) { return NULL; }
void* DimensionGetLabel(void* dimension) { return NULL; }
void* DimensionGetDescription(void* dimension) { return NULL; }
OCIndex DimensionGetCount(void* dimension) { return 0; }
unsigned int OCGetTypeID(void* obj) { return 0; }
unsigned int SILinearDimensionGetTypeID(void) { return 1; }
unsigned int LabeledDimensionGetTypeID(void) { return 2; }

// Datum function stubs
void* DatumCreate(void* response, void* coords, OCIndex p1, OCIndex p2, OCIndex p3) { return NULL; }
void* DatumCreateResponse(void* datum) { return NULL; }
OCIndex DatumCoordinatesCount(void* datum) { return 0; }
void* DatumGetCoordinateAtIndex(void* datum, OCIndex index) { return NULL; }
OCIndex DatumGetComponentIndex(void* datum) { return 0; }
OCIndex DatumGetDependentVariableIndex(void* datum) { return 0; }

// Sparse sampling function stubs
void* SparseSamplingCreate(void* dimIndexes, void* gridVertexes, unsigned int numberType, void* encoding, void* description, void* metadata, void* error) { return NULL; }
void* SparseSamplingGetDescription(void* sparseSampling) { return NULL; }
int SparseSamplingSetDescription(void* sparseSampling, void* description) { return 0; }
void* SparseSamplingGetEncoding(void* sparseSampling) { return NULL; }
int SparseSamplingSetEncoding(void* sparseSampling, void* encoding) { return 0; }
unsigned int SparseSamplingGetUnsignedIntegerType(void* sparseSampling) { return 0; }
int SparseSamplingSetUnsignedIntegerType(void* sparseSampling, unsigned int numberType) { return 0; }
void* SparseSamplingGetDimensionIndexes(void* sparseSampling) { return NULL; }
OCIndex OCIndexSetGetCount(void* indexSet) { return 0; }
OCIndex* OCIndexSetGetBytesPtr(void* indexSet) { return NULL; }
void* SparseSamplingGetSparseGridVertexes(void* sparseSampling) { return NULL; }
void* SparseSamplingGetMetaData(void* sparseSampling) { return NULL; }
int validateSparseSampling(void* sparseSampling, void* error) { return 1; }

// Reference the symbol to prevent optimization
void *force_export_kOCTypeArrayCallBacks(void) { return (void*)&kOCTypeArrayCallBacks; }

#ifdef __cplusplus
}
#endif
EOF

gcc -fPIC -c stub_sitypes.c -o stub_sitypes.o
ar rcs lib/libSITypes.a stub_sitypes.o
ar rcs lib/libOCTypes.a stub_sitypes.o
ar rcs lib/libRMN.a stub_sitypes.o

# Copy headers to expected directories
cp include/OCLibrary.h include/OCTypes/
cp include/SILibrary.h include/SITypes/
cp include/RMNLibrary.h include/RMNLib/

# Also add function declarations to each subdirectory header
# Update OCTypes header with all function declarations
cat >> include/OCTypes/OCLibrary.h <<'EOF'

// Additional function declarations for OCTypes stub
OCStringRef OCStringCreateWithCString(const char* cStr);
const char* OCStringGetCString(OCStringRef ocString);
OCMutableArrayRef OCArrayCreateMutable(OCIndex capacity, const OCArrayCallBacks* callBacks);
int OCArrayAppendValue(OCMutableArrayRef array, const void* value);
OCIndex OCArrayGetCount(OCArrayRef array);
const void* OCArrayGetValueAtIndex(OCArrayRef array, OCIndex idx);
OCIndexArrayRef OCIndexArrayCreateMutable(OCIndex capacity);
int OCIndexArrayAppendValue(OCMutableIndexArrayRef array, OCIndex value);
OCIndex OCIndexArrayGetCount(OCIndexArrayRef array);
OCIndex OCIndexArrayGetValueAtIndex(OCIndexArrayRef array, OCIndex idx);
void OCRelease(OCTypeRef ref);
OCTypeRef OCRetain(OCTypeRef ref);
EOF

# Update SITypes header with function declarations
cat >> include/SITypes/SILibrary.h <<'EOF'

// Additional function declarations for SITypes stub
SIScalarRef SIScalarCreateWithDouble(double value, SIUnitRef unit);
double SIScalarDoubleValueInCoherentUnit(SIScalarRef scalar);
SIUnitRef SIUnitFromExpression(const char* expr, void* p1, void* p2);
EOF

# Check for symbol presence
if ! nm -g lib/libSITypes.a | grep -q kOCTypeArrayCallBacks; then
  echo "WARNING: kOCTypeArrayCallBacks not found in libSITypes.a!"
  nm -g lib/libSITypes.a
else
  echo "kOCTypeArrayCallBacks present in libSITypes.a"
fi

echo "Comprehensive stub libraries created"
