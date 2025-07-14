# RMNpy Build Scripts

This directory contains build and deployment scripts for RMNpy.

## Build Dependency Scripts

- **`build_deps.py`** - Main dependency download script (downloads from GitHub releases)
- **`build_deps_old.py`** - Legacy local workspace dependency builder
- **`build_deps_new.py`** - Workspace dependency checker (validates local builds)

## Shell Scripts

- **`build.sh`** - Main build script for RMNpy
- **`deploy_docs.sh`** - Documentation deployment script

## Usage

From the RMNpy root directory:

```bash
# Check/build dependencies
python scripts/build_deps.py

# Check workspace dependencies
python scripts/build_deps_new.py -v

# Build the package
./scripts/build.sh

# Deploy documentation
./scripts/deploy_docs.sh
```
