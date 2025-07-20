#!/usr/bin/env python3
"""Setup script for RMNpy - Python bindings for OCTypes, SITypes, and RMNLib."""

from setuptools import setup, Extension
from setuptools.command.build_ext import build_ext
from Cython.Build import cythonize
import numpy
import sys
from pathlib import Path

class CustomBuildExt(build_ext):
    """Custom build extension that handles library dependencies."""
    
    def run(self):
        """Check dependencies before building extensions."""
        print("Checking library dependencies...")
        
        if not self._check_libraries():
            print("\nError: Required libraries not found!")
            print("Please run one of the following commands first:")
            print("  make synclib      # Copy from local development directories")
            print("  make download-libs # Download from GitHub releases")
            sys.exit(1)
        
        print("✓ All required libraries found")
        
        # Continue with normal build
        super().run()
    
    def _check_libraries(self):
        """Check that all required libraries and headers are available."""
        base_dir = Path(__file__).parent
        lib_dir = base_dir / "lib"
        include_dir = base_dir / "include"
        
        # Required library files
        required_libs = [
            lib_dir / "libOCTypes.a",
            lib_dir / "libSITypes.a", 
            lib_dir / "libRMN.a"
        ]
        
        # Required header directories
        required_headers = [
            include_dir / "OCTypes",
            include_dir / "SITypes",
            include_dir / "RMNLib"
        ]
        
        # Check libraries
        for lib_file in required_libs:
            if not lib_file.exists():
                print(f"✗ Missing library: {lib_file}")
                return False
            print(f"✓ Found library: {lib_file.name}")
        
        # Check headers
        for header_dir in required_headers:
            if not header_dir.exists() or not header_dir.is_dir():
                print(f"✗ Missing headers: {header_dir}")
                return False
            print(f"✓ Found headers: {header_dir.name}/")
        
        return True

def get_extensions():
    """Build list of Cython extensions for the project."""
    
    # Common include directories
    include_dirs = [
        "src",               # For finding rmnpy._c_api modules
        "include",           # Root include directory
        "include/OCTypes",   # OCTypes headers
        "include/SITypes",   # SITypes headers  
        "include/RMNLib",    # RMNLib headers
        numpy.get_include()  # NumPy headers
    ]
    
    # Common library directories and libraries
    library_dirs = ["lib"]
    libraries = ["OCTypes", "SITypes", "RMN"]
    
    # Common compiler/linker options
    extra_compile_args = ["-std=c99", "-Wno-unused-function"]
    extra_link_args = []
    
    # Start with empty extensions list - we'll add them as we implement phases
    extensions = []
    
    # Phase 1: OCTypes helper functions
    extensions.extend([
        Extension(
            "rmnpy.helpers.octypes",
            sources=["src/rmnpy/helpers/octypes.pyx"],
            include_dirs=include_dirs,
            library_dirs=library_dirs,
            libraries=libraries,
            language="c",
            extra_compile_args=extra_compile_args,
            extra_link_args=extra_link_args
        )
    ])
    
    # Test modules (re-enabled now that OCTypes functions are implemented)
    extensions.extend([
        Extension(
            "rmnpy.tests.test_helpers.test_octypes_linking",
            sources=["tests/test_helpers/test_octypes_linking.pyx"],
            include_dirs=include_dirs,
            library_dirs=library_dirs,
            libraries=libraries,
            language="c",
            extra_compile_args=extra_compile_args,
            extra_link_args=extra_link_args
        ),
        Extension(
            "rmnpy.tests.test_helpers.test_octypes_roundtrip",
            sources=["tests/test_helpers/test_octypes_roundtrip.pyx"],
            include_dirs=include_dirs,
            library_dirs=library_dirs,
            libraries=libraries,
            language="c",
            extra_compile_args=extra_compile_args,
            extra_link_args=extra_link_args
        ),
        Extension(
            "rmnpy.tests.test_helpers.test_minimal",
            sources=["tests/test_helpers/test_minimal.pyx"],
            include_dirs=include_dirs,
            library_dirs=library_dirs,
            libraries=libraries,
            language="c",
            extra_compile_args=extra_compile_args,
            extra_link_args=extra_link_args
        )
    ])
    
    # Phase 2: SITypes wrappers (will be implemented after Phase 1)
    # extensions.extend([
    #     Extension(
    #         "rmnpy.wrappers.sitypes.scalar",
    #         sources=["src/rmnpy/wrappers/sitypes/scalar.pyx"],
    #         include_dirs=include_dirs,
    #         library_dirs=library_dirs,
    #         libraries=libraries,
    #         language="c",
    #         extra_compile_args=extra_compile_args,
    #         extra_link_args=extra_link_args
    #     ),
    #     Extension(
    #         "rmnpy.wrappers.sitypes.unit",
    #         sources=["src/rmnpy/wrappers/sitypes/unit.pyx"],
    #         include_dirs=include_dirs,
    #         library_dirs=library_dirs,
    #         libraries=libraries,
    #         language="c",
    #         extra_compile_args=extra_compile_args,
    #         extra_link_args=extra_link_args
    #     ),
    #     Extension(
    #         "rmnpy.wrappers.sitypes.dimensionality",
    #         sources=["src/rmnpy/wrappers/sitypes/dimensionality.pyx"],
    #         include_dirs=include_dirs,
    #         library_dirs=library_dirs,
    #         libraries=libraries,
    #         language="c",
    #         extra_compile_args=extra_compile_args,
    #         extra_link_args=extra_link_args
    #     )
    # ])
    
    # Phase 3: RMNLib wrappers (will be implemented after Phase 2)
    # extensions.extend([
    #     Extension(
    #         "rmnpy.wrappers.rmnlib.core",
    #         sources=["src/rmnpy/wrappers/rmnlib/core.pyx"],
    #         include_dirs=include_dirs,
    #         library_dirs=library_dirs,
    #         libraries=libraries,
    #         language="c",
    #         extra_compile_args=extra_compile_args,
    #         extra_link_args=extra_link_args
    #     )
    # ])
    
    return extensions

# Note: Most project configuration is now in pyproject.toml
# This setup.py only handles the Cython build process

setup(
    # Most configuration is now in pyproject.toml
    # Only specify what's needed for the build system
    ext_modules=cythonize(
        get_extensions(), 
        compiler_directives={
            'language_level': 3,
            'embedsignature': True,
            'boundscheck': False,
            'wraparound': False,
            'initializedcheck': False,
        }
    ),
    cmdclass={
        'build_ext': CustomBuildExt,
    },
    zip_safe=False,
)