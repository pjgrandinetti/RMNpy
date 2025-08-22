# RMNpy Release Guide

This document outlines the release strategy for RMNpy with automated GitHub releases and PyPI publishing.

## 🎯 Release Strategy

RMNpy uses a **dual-tier release strategy**:

1. **📦 GitHub Releases**: Created for **every tagged commit** (patch, minor, major)
   - Includes: Wheels for Linux/macOS + source distribution
   - Artifacts: Available for immediate download
   - Use case: Development builds, patch releases, immediate access

2. **🐍 PyPI Releases**: Only for **minor version updates** (ending in `.0`)
   - Examples: `v1.0.0`, `v0.2.0`, `v2.1.0` ✅
   - Not: `v0.1.1`, `v0.1.2`, `v1.0.1` ❌
   - Use case: Stable releases for pip installation

## 🏗️ Current Implementation Status

✅ **COMPLETED**: Automated release workflow is fully implemented
- Combined CI/Release workflow in `.github/workflows/build-and-release.yml`
- Tests run on every push/PR
- Wheels built and released on every tag
- PyPI uploads only for minor versions
- Windows support via WSL2 (no MinGW complexity)

## 📋 How to Make a Release

### Making a Release

1. **Prepare the release**:
   ```bash
   # Update version in pyproject.toml and src/rmnpy/_version.py
   # Update CHANGELOG.md
   # Commit changes
   git add .
   git commit -m "Prepare release v1.2.0"
   ```

2. **Create and push tag**:
   ```bash
   # For patch releases (GitHub release only):
   git tag v1.2.1
   git push origin v1.2.1

   # For minor releases (GitHub + PyPI):
   git tag v1.3.0
   git push origin v1.3.0
   ```

3. **Automated workflow will**:
   - ✅ Run tests on Linux/macOS + Python 3.11/3.12
   - ✅ Build wheels using cibuildwheel
   - ✅ Create GitHub release with artifacts
   - ✅ Upload to PyPI (only for `.0` versions)

## 🔧 Technical Details

### Supported Platforms
- **Linux**: manylinux2014 (x86_64, aarch64)
- **macOS**: 11.0+ (x86_64, arm64)
- **Windows**: Use Linux wheels via WSL2

### Dependencies
- C libraries built from source (OCTypes → SITypes → RMNLib)
- Dynamic version detection from GitHub releases
- cibuildwheel handles library bundling automatically

## 🛠️ Setup Requirements (One-time)

### PyPI API Token Setup

If not already configured, you need to set up PyPI credentials:

1. **Create PyPI account**: Go to https://pypi.org/account/register/
2. **Generate API Token**:
   - Log into PyPI → Account settings → API tokens
   - Click "Add API token"
   - Name: `RMNpy-GitHub-Actions`
   - Scope: `Entire account` (or project-specific)
   - Copy the token (starts with `pypi-`)

3. **Add to GitHub Secrets**:
   - Go to https://github.com/pjgrandinetti/RMNpy
   - Settings → Secrets and variables → Actions
   - New repository secret: `PYPI_API_TOKEN`
   - Paste your PyPI token

## 📊 Workflow Summary

The combined workflow (`.github/workflows/build-and-release.yml`) handles:

### On Every Push/PR:
- ✅ Tests on Linux/macOS with Python 3.11/3.12
- ✅ Builds and installs dependencies from source
- ✅ Runs smoke tests and full test suite

### On Tagged Releases:
- ✅ All testing steps above
- ✅ Builds wheels for Linux (manylinux2014) and macOS
- ✅ Creates source distribution
- ✅ Uploads artifacts to GitHub release (ALL tags)
- ✅ Uploads to PyPI (only minor versions ending in `.0`)

## 🏷️ Version Tagging Examples

| Tag | GitHub Release | PyPI Upload | Use Case |
|-----|---------------|-------------|----------|
| `v1.0.0` | ✅ | ✅ | Major release |
| `v1.1.0` | ✅ | ✅ | Minor release |
| `v1.1.1` | ✅ | ❌ | Patch/hotfix |
| `v1.1.2` | ✅ | ❌ | Another patch |
| `v1.2.0` | ✅ | ✅ | Next minor |

This strategy ensures:
- 📦 **All releases** get GitHub artifacts for immediate access
- 🐍 **Stable releases** get PyPI distribution for pip install
- 🚀 **Rapid patches** don't clutter PyPI but are available via GitHub

---

**Note**: This implementation replaces the previous separate CI and release workflows with a single, comprehensive workflow that handles both testing and releasing based on the event trigger.
