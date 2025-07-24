#!/bin/bash
# CI script to create stub libraries and headers for documentation builds
# This allows docs to build without needing full C library compilation

set -e

echo "Creating stub libraries and headers for CI documentation build..."

# Create directories
mkdir -p lib
mkdir -p include/OCTypes
mkdir -p include/SITypes  
mkdir -p include/RMNLib

# Create minimal stub libraries (empty archives)
touch lib/libOCTypes.a
touch lib/libSITypes.a
touch lib/libRMNLib.a

# Create minimal stub headers for OCTypes
cat > include/OCTypes/OCLibrary.h << 'EOF'
#ifndef OC_LIBRARY_H
#define OC_LIBRARY_H

// Stub header for documentation builds

typedef struct OCType OCType;
typedef struct OCArray OCArray;
typedef struct OCString OCString;
typedef struct OCNumber OCNumber;
typedef struct OCDictionary OCDictionary;

#endif // OC_LIBRARY_H
EOF

# Create minimal stub headers for SITypes  
cat > include/SITypes/SILibrary.h << 'EOF'
#ifndef SI_LIBRARY_H
#define SI_LIBRARY_H

// Stub header for documentation builds

typedef struct SIScalar SIScalar;
typedef struct SIQuantity SIQuantity;
typedef struct SIConstants SIConstants;

#endif // SI_LIBRARY_H
EOF

# Create minimal stub headers for RMNLib
cat > include/RMNLib/RMNLibrary.h << 'EOF'
#ifndef RMN_LIBRARY_H  
#define RMN_LIBRARY_H

// Stub header for documentation builds

typedef struct RMNSpectrum RMNSpectrum;
typedef struct RMNSignal RMNSignal;

// Stub LAPACKE definitions to avoid missing header
#ifndef LAPACK_COL_MAJOR
#define LAPACK_COL_MAJOR 102
#endif

typedef int lapack_int;

#endif // RMN_LIBRARY_H
EOF

echo "Stub libraries and headers created successfully"
