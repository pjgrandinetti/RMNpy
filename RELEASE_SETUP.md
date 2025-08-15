# RMNpy GitHub Release Setup Guide

This document outlines the steps needed to set up automated GitHub releases for RMNpy, including PyPI publishing and wheel building for multiple platforms.

## Overview

Currently, RMNpy has only CI testing. To enable releases, we need to:
1. Add release workflow triggers
2. Build wheels for multiple platforms
3. Set up PyPI publishing
4. Create GitHub releases with artifacts

## 📋 Step-by-Step Setup

### Step 1: Create PyPI Account and API Token

1. **Create PyPI account** (if you don't have one):
   - Go to https://pypi.org/account/register/
   - Verify your email

2. **Generate API Token**:
   - Log into PyPI
   - Go to Account settings → API tokens
   - Click "Add API token"
   - Name: `RMNpy-GitHub-Actions`
   - Scope: `Entire account` (or specific to RMNpy project if it exists)
   - Copy the token (starts with `pypi-`)

### Step 2: Add PyPI Token to GitHub Secrets

1. **Navigate to GitHub repository**:
   - Go to https://github.com/pjgrandinetti/RMNpy
   - Click Settings → Secrets and variables → Actions

2. **Add new repository secret**:
   - Click "New repository secret"
   - Name: `PYPI_API_TOKEN`
   - Value: Paste your PyPI token from Step 1
   - Click "Add secret"

### Step 3: Create Release Workflow

Create a new file: `.github/workflows/release.yml`

```yaml
name: Build & Release

on:
  push:
    tags:
      - 'v*.*.*'
  workflow_dispatch:

jobs:
  build_wheels:
    name: Build wheels on ${{ matrix.os }}
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
        python-version: ["3.8", "3.9", "3.10", "3.11", "3.12"]
        exclude:
          # Reduce Windows build matrix to save CI time
          - os: windows-latest
            python-version: "3.8"
          - os: windows-latest
            python-version: "3.9"
          - os: windows-latest
            python-version: "3.10"
          - os: windows-latest
            python-version: "3.11"

    steps:
    - name: Checkout RMNpy
      uses: actions/checkout@v5

    - name: Set up Python ${{ matrix.python-version }}
      if: runner.os != 'Windows'
      uses: actions/setup-python@v5
      with:
        python-version: ${{ matrix.python-version }}

    - name: Install system dependencies (Ubuntu)
      if: runner.os == 'Linux'
      run: |
        sudo systemd-run --property="After=apt-daily.service apt-daily-upgrade.service" --wait /bin/true
        sudo apt-get update
        sudo apt-get install -y build-essential cmake pkg-config flex bison libopenblas-dev liblapacke-dev libcurl4-openssl-dev libomp5

    - name: Install system dependencies (macOS)
      if: runner.os == 'macOS'
      run: |
        brew install cmake flex bison openblas lapack curl libomp

    - name: Setup MSYS2 (Windows)
      if: matrix.os == 'windows-latest'
      uses: msys2/setup-msys2@v2
      with:
        msystem: MINGW64
        update: true
        install: |
          mingw-w64-x86_64-toolchain
          mingw-w64-x86_64-python
          mingw-w64-x86_64-python-pip
          mingw-w64-x86_64-python-numpy
          mingw-w64-x86_64-cython
          mingw-w64-x86_64-curl
          mingw-w64-x86_64-openblas
          mingw-w64-x86_64-lapack
          mingw-w64-x86_64-openmp

    # Download dependencies (same as CI workflow)
    - name: Download OCTypes from GitHub releases
      run: |
        mkdir -p lib include/OCTypes
        if [[ "${{ runner.os }}" == "Linux" ]]; then
          LIB_FILE="libOCTypes-ubuntu-latest.x64.zip"
        elif [[ "${{ runner.os }}" == "macOS" ]]; then
          LIB_FILE="libOCTypes-macos-latest.zip"
        elif [[ "${{ runner.os }}" == "Windows" ]]; then
          LIB_FILE="libOCTypes-windows-latest.zip"
        fi
        curl -L https://github.com/pjgrandinetti/OCTypes/releases/download/v0.1.0/${LIB_FILE} -o octypes-lib.zip
        curl -L https://github.com/pjgrandinetti/OCTypes/releases/download/v0.1.0/libOCTypes-headers.zip -o octypes-headers.zip
        unzip -o -j -q octypes-lib.zip -d lib/
        unzip -o -j -q octypes-headers.zip -d include/OCTypes/
        rm octypes-lib.zip octypes-headers.zip
      shell: bash

    - name: Download SITypes from GitHub releases
      run: |
        mkdir -p include/SITypes
        if [[ "${{ runner.os }}" == "Linux" ]]; then
          LIB_FILE="libSITypes-ubuntu-latest.x64.zip"
        elif [[ "${{ runner.os }}" == "macOS" ]]; then
          LIB_FILE="libSITypes-macos-latest.zip"
        elif [[ "${{ runner.os }}" == "Windows" ]]; then
          LIB_FILE="libSITypes-windows-latest.zip"
        fi
        curl -L https://github.com/pjgrandinetti/SITypes/releases/download/v0.1.0/${LIB_FILE} -o sitypes-lib.zip
        curl -L https://github.com/pjgrandinetti/SITypes/releases/download/v0.1.0/libSITypes-headers.zip -o sitypes-headers.zip
        unzip -o -j -q sitypes-lib.zip -d lib/
        unzip -o -j -q sitypes-headers.zip -d include/SITypes/
        rm sitypes-lib.zip sitypes-headers.zip
      shell: bash

    - name: Download RMNLib from GitHub releases
      run: |
        mkdir -p include/RMNLib
        if [[ "${{ runner.os }}" == "Linux" ]]; then
          LIB_FILE="libRMN-ubuntu-latest.x64.zip"
        elif [[ "${{ runner.os }}" == "macOS" ]]; then
          LIB_FILE="libRMN-macos-latest.zip"
        elif [[ "${{ runner.os }}" == "Windows" ]]; then
          LIB_FILE="libRMN-windows-latest.zip"
        fi
        curl -L https://github.com/pjgrandinetti/RMNLib/releases/download/v0.1.0/${LIB_FILE} -o rmnlib-lib.zip
        curl -L https://github.com/pjgrandinetti/RMNLib/releases/download/v0.1.0/libRMN-headers.zip -o rmnlib-headers.zip
        unzip -o -j -q rmnlib-lib.zip -d lib/
        unzip -o -q rmnlib-headers.zip -d .
        rm rmnlib-lib.zip rmnlib-headers.zip
      shell: bash

    - name: Create Windows Bridge DLL
      if: runner.os == 'Windows'
      shell: msys2 {0}
      run: |
        if [ -f lib/libOCTypes.a ] && [ -f lib/libSITypes.a ] && [ -f lib/libRMN.a ]; then
          x86_64-w64-mingw32-gcc -shared -o lib/rmnstack_bridge.dll \
            -Wl,--out-implib,lib/rmnstack_bridge.dll.a \
            -Wl,--whole-archive \
              lib/libRMN.a lib/libSITypes.a lib/libOCTypes.a \
            -Wl,--no-whole-archive \
            -Wl,--export-all-symbols \
            -lopenblas -llapack -lcurl -lgcc_s -lwinpthread -lquadmath -lgomp -lm
        fi

    - name: Install build dependencies (Linux/macOS)
      if: runner.os != 'Windows'
      run: |
        python -m pip install --upgrade pip setuptools wheel Cython "numpy>=1.21,<2" build

    - name: Generate constants (Linux/macOS)
      if: runner.os != 'Windows'
      run: |
        make generate-constants

    - name: Generate constants (Windows)
      if: runner.os == 'Windows'
      shell: msys2 {0}
      run: |
        python scripts/extract_si_constants.py

    - name: Build wheel (Linux/macOS)
      if: runner.os != 'Windows'
      run: |
        python -m build --wheel

    - name: Build wheel (Windows)
      if: runner.os == 'Windows'
      shell: msys2 {0}
      run: |
        python setup.py build_ext --inplace
        python -m pip wheel . --no-deps --wheel-dir dist/

    - name: Upload wheels
      uses: actions/upload-artifact@v4
      with:
        name: wheels-${{ matrix.os }}-py${{ matrix.python-version }}
        path: dist/*.whl

  build_sdist:
    name: Build source distribution
    runs-on: ubuntu-latest
    steps:
    - name: Checkout RMNpy
      uses: actions/checkout@v5

    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: "3.11"

    - name: Install system dependencies
      run: |
        sudo systemd-run --property="After=apt-daily.service apt-daily-upgrade.service" --wait /bin/true
        sudo apt-get update
        sudo apt-get install -y build-essential cmake pkg-config flex bison libopenblas-dev liblapacke-dev libcurl4-openssl-dev libomp5

    - name: Download dependencies
      run: |
        mkdir -p lib include/OCTypes include/SITypes include/RMNLib
        curl -L https://github.com/pjgrandinetti/OCTypes/releases/download/v0.1.0/libOCTypes-ubuntu-latest.x64.zip -o octypes-lib.zip
        curl -L https://github.com/pjgrandinetti/OCTypes/releases/download/v0.1.0/libOCTypes-headers.zip -o octypes-headers.zip
        curl -L https://github.com/pjgrandinetti/SITypes/releases/download/v0.1.0/libSITypes-ubuntu-latest.x64.zip -o sitypes-lib.zip
        curl -L https://github.com/pjgrandinetti/SITypes/releases/download/v0.1.0/libSITypes-headers.zip -o sitypes-headers.zip
        curl -L https://github.com/pjgrandinetti/RMNLib/releases/download/v0.1.0/libRMN-ubuntu-latest.x64.zip -o rmnlib-lib.zip
        curl -L https://github.com/pjgrandinetti/RMNLib/releases/download/v0.1.0/libRMN-headers.zip -o rmnlib-headers.zip
        unzip -o -j -q octypes-lib.zip -d lib/
        unzip -o -j -q octypes-headers.zip -d include/OCTypes/
        unzip -o -j -q sitypes-lib.zip -d lib/
        unzip -o -j -q sitypes-headers.zip -d include/SITypes/
        unzip -o -j -q rmnlib-lib.zip -d lib/
        unzip -o -q rmnlib-headers.zip -d .
        rm *.zip

    - name: Install build dependencies
      run: |
        python -m pip install --upgrade pip setuptools wheel Cython "numpy>=1.21,<2" build

    - name: Generate constants
      run: |
        make generate-constants

    - name: Build source distribution
      run: |
        python -m build --sdist

    - name: Upload sdist
      uses: actions/upload-artifact@v4
      with:
        name: sdist
        path: dist/*.tar.gz

  publish:
    name: Publish to PyPI and GitHub
    needs: [build_wheels, build_sdist]
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/')

    steps:
    - name: Download all artifacts
      uses: actions/download-artifact@v4
      with:
        path: dist-artifacts/

    - name: Flatten artifact directory
      run: |
        mkdir -p dist
        find dist-artifacts -name "*.whl" -exec mv {} dist/ \;
        find dist-artifacts -name "*.tar.gz" -exec mv {} dist/ \;
        ls -la dist/

    - name: Publish to PyPI
      uses: pypa/gh-action-pypi-publish@v1.8.11
      with:
        user: __token__
        password: ${{ secrets.PYPI_API_TOKEN }}
        packages_dir: dist/

    - name: Create GitHub Release
      uses: softprops/action-gh-release@v1
      with:
        files: dist/*
        generate_release_notes: true
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Step 4: Update pyproject.toml (if needed)

Ensure your `pyproject.toml` has proper metadata for PyPI:

```toml
[project]
name = "rmnpy"
version = "0.1.0"  # This should match your git tag
description = "Python bindings for OCTypes, SITypes, and RMNLib C libraries for scientific computing with units and dimensional analysis"
authors = [
    {name = "Philip Grandinetti", email = "grandinetti.1@osu.edu"}
]
readme = "README.md"
license = {text = "MIT"}
keywords = ["nmr", "scientific-computing", "chemistry", "physics", "units", "dimensional-analysis"]
classifiers = [
    "Development Status :: 3 - Alpha",
    "Intended Audience :: Science/Research",
    "License :: OSI Approved :: MIT License",
    "Operating System :: POSIX :: Linux",
    "Operating System :: MacOS",
    "Operating System :: Microsoft :: Windows",
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3.8",
    "Programming Language :: Python :: 3.9",
    "Programming Language :: Python :: 3.10",
    "Programming Language :: Python :: 3.11",
    "Programming Language :: Python :: 3.12",
    "Programming Language :: Python :: 3 :: Only",
    "Topic :: Scientific/Engineering :: Chemistry",
    "Topic :: Scientific/Engineering :: Physics",
]
requires-python = ">=3.8"
dependencies = [
    "numpy>=1.20.0",
    "cython>=0.29.24",
]

# Note: Windows builds are only available for Python 3.12 due to MSYS2 constraints
# Linux and macOS support Python 3.8-3.12

[project.urls]
Homepage = "https://github.com/pjgrandinetti/RMNpy"
Repository = "https://github.com/pjgrandinetti/RMNpy"
Documentation = "https://rmnpy.readthedocs.io"  # If you have docs
Issues = "https://github.com/pjgrandinetti/RMNpy/issues"
```

### Step 5: Test the Release Process

1. **Test locally first**:
   ```bash
   # Make sure everything builds
   python -m build --wheel --sdist

   # Check the built packages
   python -m twine check dist/*
   ```

2. **Create a test release**:
   ```bash
   # Create and push a test tag
   git tag v0.1.0-test
   git push origin v0.1.0-test
   ```

3. **Monitor the GitHub Actions**:
   - Go to your repository → Actions tab
   - Watch the release workflow run
   - Check for any failures

### Step 6: Create Your First Release

1. **Update version number**:
   - Update `version` in `pyproject.toml`
   - Update `__version__` in `src/rmnpy/__init__.py`
   - Commit these changes

2. **Create and push release tag**:
   ```bash
   git tag v0.1.0
   git push origin v0.1.0
   ```

3. **Monitor the release**:
   - Check GitHub Actions for successful completion
   - Verify package appears on PyPI
   - Verify GitHub release is created with artifacts

## 🔧 Alternative: Modify Existing CI Workflow

If you prefer to modify the existing `.github/workflows/ci.yml` instead of creating a separate release workflow:

1. **Add tag trigger** to the `on:` section:
   ```yaml
   on:
     push:
       branches: [ master, main, develop ]
       tags: [ 'v*.*.*' ]  # Add this line
   ```

2. **Add a release job** at the end of the file (after the test job).

## 📝 Additional Considerations

### Security Notes
- Never commit API tokens to git
- Use GitHub Secrets for all sensitive data
- Consider using trusted publishing instead of API tokens

### Version Management
- Keep versions consistent across `pyproject.toml`, `__init__.py`, and git tags
- Follow semantic versioning (v1.0.0, v1.0.1, etc.)
- Consider using `setuptools-scm` for automatic version management

### Testing Strategy
- Test releases on TestPyPI first
- Use pre-releases for beta versions (v1.0.0-beta1)
- Monitor download statistics and user feedback

## 🎯 Next Steps

1. Complete Steps 1-2 (PyPI account and GitHub secrets)
2. Choose between new release workflow or modifying existing CI
3. Create the workflow file
4. Test with a pre-release tag
5. Create your first official release!

## 🆘 Troubleshooting

**Common Issues:**
- **Build failures**: Check that all dependencies are correctly specified
- **PyPI upload fails**: Verify your API token and package metadata
- **Windows builds fail**: MSYS2 setup can be complex, check dependency paths
- **Version conflicts**: Ensure git tag matches version in package files

**Useful Commands:**
```bash
# Check built packages
python -m twine check dist/*

# Test upload to TestPyPI
python -m twine upload --repository testpypi dist/*

# Install from TestPyPI
pip install --index-url https://test.pypi.org/simple/ rmnpy
```

---

*This setup follows the patterns used by SpinOps and OCTypes in your ecosystem, adapted for RMNpy's specific build requirements.*
