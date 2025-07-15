#!/usr/bin/env python3
"""Setup script for RMNpy - Python wrapper for RMNLib scientific data library."""

from setuptools import setup, Extension, find_packages
from setuptools.command.build_ext import build_ext
from Cython.Build import cythonize
import numpy
import os
import subprocess
import sys
from pathlib import Path

from pathlib import Path
import zipfile
import shutil
import platform
import io
import urllib.request
import ssl

class CustomBuildExt(build_ext):
    """Custom build extension that downloads dependencies from GitHub releases."""
    
    def run(self):
        """Download dependencies from GitHub releases before building extensions."""
        print("Setting up dependencies from GitHub releases...")
        
        if not self._download_github_dependencies():
            print("Warning: Failed to download from GitHub, attempting local dependency copy...")
            self._fallback_to_local_copy()
        
        # Continue with normal build
        super().run()
    
    def _download_github_dependencies(self):
        """Download dependencies from GitHub releases."""
        try:
            # Check if CI stub libraries are available
            if os.environ.get('CI_STUB_LIBRARIES') == 'true':
                print("CI stub libraries detected - skipping GitHub downloads")
                print("Using pre-built stub libraries for CI build")
                return True
                
            base_dir = Path(__file__).parent
            lib_dir = base_dir / "lib"
            include_dir = base_dir / "include"
            
            # Create directories
            lib_dir.mkdir(exist_ok=True)
            include_dir.mkdir(exist_ok=True)
            
            # Detect platform
            system = platform.system().lower()
            machine = platform.machine().lower()
            
            if system == "darwin":
                ocotypes_suffix = "macos-latest"
                sitypes_suffix = "macos-latest"
                rmnlib_suffix = "macos-latest"
            elif system == "linux":
                if machine in ["aarch64", "arm64"]:
                    ocotypes_suffix = "ubuntu-latest.arm64"
                    sitypes_suffix = "ubuntu-latest.arm64"
                    rmnlib_suffix = "ubuntu-latest.arm64"
                else:
                    ocotypes_suffix = "ubuntu-latest.x64"
                    sitypes_suffix = "ubuntu-latest.x64"
                    rmnlib_suffix = "ubuntu-latest.x64"
            elif system == "windows":
                ocotypes_suffix = "windows-latest"
                sitypes_suffix = "windows-latest"
                rmnlib_suffix = "windows-latest"
            else:
                print(f"Unsupported platform: {system}")
                return False
            
            # Download configurations
            downloads = [
                {
                    "name": "OCTypes",
                    "repo": "pjgrandinetti/OCTypes",
                    "version": "v0.1.1",
                    "lib_asset": f"libOCTypes-{ocotypes_suffix}.zip",
                    "headers_asset": "libOCTypes-headers.zip",
                    "lib_file": "libOCTypes.a"
                },
                {
                    "name": "SITypes", 
                    "repo": "pjgrandinetti/SITypes",
                    "version": "v0.1.0",
                    "lib_asset": f"libSITypes-{sitypes_suffix}.zip",
                    "headers_asset": "libSITypes-headers.zip",
                    "lib_file": "libSITypes.a"
                },
                {
                    "name": "RMNLib",
                    "repo": "pjgrandinetti/RMNLib", 
                    "version": "v0.1.0",
                    "lib_asset": f"libRMN-{rmnlib_suffix}.zip",
                    "headers_asset": "libRMN-headers.zip", 
                    "lib_file": "libRMN.a"
                }
            ]
            
            success = True
            for download in downloads:
                if not self._download_library(download, lib_dir, include_dir):
                    success = False
                    
            return success
            
        except Exception as e:
            print(f"Error downloading dependencies: {e}")
            return False
    
    def _download_library(self, config, lib_dir, include_dir):
        """Download a single library from GitHub releases."""
        try:
            name = config["name"]
            repo = config["repo"]
            version = config["version"]
            
            print(f"Downloading {name} {version}...")
            
            # Check if library already exists
            lib_file = lib_dir / config["lib_file"]
            header_dir = include_dir / name
            
            if lib_file.exists() and header_dir.exists():
                print(f"  {name} already exists, skipping")
                return True
            
            # Download library
            lib_url = f"https://github.com/{repo}/releases/download/{version}/{config['lib_asset']}"
            if not self._download_and_extract(lib_url, lib_dir):
                return False
                
            # Download headers
            headers_url = f"https://github.com/{repo}/releases/download/{version}/{config['headers_asset']}"
            if not self._download_and_extract(headers_url, header_dir, create_target=True):
                return False
                
            print(f"  ✓ {name} downloaded successfully")
            return True
            
        except Exception as e:
            print(f"  ✗ Failed to download {config['name']}: {e}")
            return False
    
    def _download_and_extract(self, url, target_dir, create_target=False):
        """Download and extract a zip file."""
        try:
            if create_target:
                target_dir.mkdir(parents=True, exist_ok=True)
                
            # Download with urllib
            print(f"    Downloading {url}")
            
            # Create SSL context that doesn't verify certificates (for GitHub)
            ssl_context = ssl.create_default_context()
            ssl_context.check_hostname = False
            ssl_context.verify_mode = ssl.CERT_NONE
            
            with urllib.request.urlopen(url, context=ssl_context) as response:
                content = response.read()
            
            # Extract directly to target
            with zipfile.ZipFile(io.BytesIO(content)) as zf:
                zf.extractall(target_dir)
                
            return True
            
        except Exception as e:
            print(f"    Download/extract failed: {e}")
            return False
    
    def _fallback_to_local_copy(self):
        """Fallback to copying from local workspace if available."""
        try:
            script_path = Path(__file__).parent / "scripts" / "build_deps_old.py"
            if script_path.exists():
                result = subprocess.run([sys.executable, str(script_path)], 
                                      capture_output=True, text=True, check=True)
                print("Local dependencies copied successfully!")
                if result.stdout:
                    print(result.stdout)
        except subprocess.CalledProcessError as e:
            print(f"Warning: Local fallback also failed: {e}")
            print("Attempting to continue with existing bundled dependencies...")

# Define the extension with complete header dependencies
extensions = [
    Extension(
        "rmnpy.core",
        sources=["src/rmnpy/core.pyx"],
        include_dirs=[
            "include",           # Bundled headers root
            "include/OCTypes",   # OCTypes headers
            "include/SITypes",   # SITypes headers
            "include/RMNLib",    # RMNLib headers
            numpy.get_include()
        ],
        library_dirs=[
            "lib"               # Bundled libraries
        ],
        libraries=["curl", "SITypes", "OCTypes", "RMN"],
        language="c",
        # Add any needed compiler flags
        extra_compile_args=["-std=c99", "-Wno-unused-function"],
        extra_link_args=[]
    )
]

# Read long description from README
long_description = ""
if os.path.exists("README.md"):
    with open("README.md", "r", encoding="utf-8") as fh:
        long_description = fh.read()

setup(
    name="RMNpy",
    version="0.1.0",
    author="Philip Grandinetti",
    author_email="grandinetti.1@osu.edu",
    description="Python wrapper for RMNLib scientific data library",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/pjgrandinetti/RMNpy",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    ext_modules=cythonize(extensions, compiler_directives={'language_level': 3}),
    cmdclass={
        'build_ext': CustomBuildExt,
    },
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Science/Research",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Topic :: Scientific/Engineering",
    ],
    python_requires=">=3.8",
    install_requires=[
        "numpy>=1.20.0",
        "cython>=0.29.0",
    ],
    extras_require={
        "dev": [
            "pytest>=6.0",
            "pytest-cov",
            "black",
            "flake8",
            "mypy",
        ]
    },
    zip_safe=False,
)
