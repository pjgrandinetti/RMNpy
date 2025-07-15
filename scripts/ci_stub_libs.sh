#!/usr/bin/env bash
# scripts/ci_stub_libs.sh
# Create stub headers and libraries for CI builds
set -e

mkdir -p lib include

# OCLibrary.h: full enum definition
cat > include/OCLibrary.h <<'EOF'
#ifndef OCLIBRARY_H
#define OCLIBRARY_H

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

#endif
EOF

# SILibrary.h: forward declaration only
cat > include/SILibrary.h <<'EOF'
#ifndef SILIBRARY_H
#define SILIBRARY_H

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

#endif
EOF

# RMNLibrary.h: forward declaration only
cat > include/RMNLibrary.h <<'EOF'
#ifndef RMNLIBRARY_H
#define RMNLIBRARY_H

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

#endif
EOF

# Create comprehensive stub implementations for CI
cat > stub_sitypes.c << 'EOF'
#include <stdlib.h>
#include <stdbool.h>
// Minimal stub struct for OCArrayCallBacks
typedef struct {
    void *retain;
    void *release;
    void *copyDescription;
    int (*equal)(const void *, const void *);
} OCArrayCallBacks;
// Provide the missing symbol with dummy values, ensure it is exported
__attribute__((visibility("default"))) const OCArrayCallBacks kOCTypeArrayCallBacks = { NULL, NULL, NULL, NULL };
// Reference the symbol to prevent optimization
void *force_export_kOCTypeArrayCallBacks(void) { return (void*)&kOCTypeArrayCallBacks; }
void RMNLibTypesShutdown(void) {
    // Do nothing in stub
}
EOF

# Compile the stub and add it to the existing libraries
gcc -fPIC -c stub_sitypes.c -o stub_sitypes.o
ar rcs lib/libSITypes.a stub_sitypes.o
ar rcs lib/libOCTypes.a stub_sitypes.o
ar rcs lib/libRMN.a stub_sitypes.o
echo "Comprehensive stub libraries created"
