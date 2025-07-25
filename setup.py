#!/usr/bin/env python3
"""Setup script for RMNpy - Python bindings for OCTypes, SITypes, and RMNLib."""

import subprocess
import sys
from pathlib import Path
from typing import TYPE_CHECKING

import numpy
from Cython.Build import cythonize
from setuptools import Extension, setup
from setuptools.command.build_ext import build_ext

if TYPE_CHECKING:
    pass


def generate_si_constants() -> None:
    """Generate SI constants from C header file during build."""
    print("Generating SI quantity constants from C header...")

    try:
        script_path = Path(__file__).parent / "scripts" / "extract_si_constants.py"

        if script_path.exists():
            # Run the extraction script
            result = subprocess.run(
                [sys.executable, str(script_path)],
                check=True,
                capture_output=True,
                text=True,
            )
            print("[OK] SI constants generated successfully")
            if result.stdout:
                # Only print summary line, not full output
                lines = result.stdout.strip().split("\n")
                for line in lines:
                    if (
                        "SI Constants extraction completed" in line
                        or "Constants:" in line
                    ):
                        print(f"  {line.strip('=').strip()}")
        else:
            print(f"Warning: SI constants extraction script not found at {script_path}")

    except subprocess.CalledProcessError as e:
        print(f"Warning: Failed to generate SI constants: {e}")
        if e.stderr:
            print(f"Error output: {e.stderr}")
        print("Build will continue with existing constants file if available")
    except Exception as e:
        print(f"Warning: Error during SI constants generation: {e}")
        print("Build will continue with existing constants file if available")


class CustomBuildExt(build_ext):
    """Custom build extension that handles library dependencies."""

    def run(self) -> None:
        """Check dependencies before building extensions."""
        print("Checking library dependencies...")

        if not self._check_libraries():
            print("\nError: Required libraries not found!")
            print("Please run one of the following commands first:")
            print("  make synclib      # Copy from local development directories")
            print("  make download-libs # Download from GitHub releases")
            sys.exit(1)

        print("[OK] All required libraries found")

        # Generate SI constants before building
        generate_si_constants()

        # Force MinGW compiler on Windows if environment suggests it
        self._setup_windows_compiler()

        # Continue with normal build
        super().run()

    def _setup_windows_compiler(self) -> None:
        """Set up compiler for Windows builds."""
        import os
        import platform

        if platform.system() == "Windows":
            # Check if we should use MinGW based on environment
            cc_env = os.environ.get("CC", "")
            msystem = os.environ.get("MSYSTEM", "")

            if (
                "mingw32" in cc_env.lower()
                or "gcc" in cc_env.lower()
                or msystem == "MINGW64"
                or msystem == "MINGW32"
            ):
                print("Using MinGW/GCC compiler on Windows")
                # Force the compiler to be mingw32
                self.compiler = "mingw32"
            else:
                print("Using default Windows compiler (MSVC)")

    def _check_libraries(self) -> bool:
        """Check that all required libraries and headers are available."""
        base_dir = Path(__file__).parent
        lib_dir = base_dir / "lib"
        include_dir = base_dir / "include"

        # Required library files
        required_libs = [
            lib_dir / "libOCTypes.a",
            lib_dir / "libSITypes.a",
            lib_dir / "libRMN.a",
        ]

        # Required header directories
        required_headers = [
            include_dir / "OCTypes",
            include_dir / "SITypes",
            include_dir / "RMNLib",
        ]

        # Check libraries
        for lib_file in required_libs:
            if not lib_file.exists():
                print(f"[X] Missing library: {lib_file}")
                return False
            print(f"[OK] Found library: {lib_file.name}")

        # Check headers
        for header_dir in required_headers:
            if not header_dir.exists() or not header_dir.is_dir():
                print(f"[X] Missing headers: {header_dir}")
                return False
            print(f"[OK] Found headers: {header_dir.name}/")

        # On Windows, check if we have MinGW compiler for compatibility
        import os
        import platform

        if platform.system() == "Windows":
            cc_env = os.environ.get("CC", "")
            msystem = os.environ.get("MSYSTEM", "")

            if not (
                "mingw32" in cc_env.lower()
                or "gcc" in cc_env.lower()
                or msystem == "MINGW64"
                or msystem == "MINGW32"
            ):
                print("[!] Warning: Windows detected without MinGW environment.")
                print(
                    "    The C libraries were built with GCC and may not be compatible with MSVC."
                )
                print("    Consider using MSYS2/MinGW64 for compilation.")

        return True


def get_extensions() -> list[Extension]:
    """Build list of Cython extensions for the project."""

    # Common include directories
    include_dirs = [
        "src",  # For finding rmnpy._c_api modules
        "include",  # Root include directory
        "include/OCTypes",  # OCTypes headers
        "include/SITypes",  # SITypes headers
        "include/RMNLib",  # RMNLib headers
        numpy.get_include(),  # NumPy headers
    ]

    # Common library directories and libraries
    library_dirs = ["lib"]
    libraries = ["OCTypes", "SITypes", "RMN"]

    # Common compiler/linker options (platform-specific)
    import os
    import platform

    extra_link_args: list[str] = []

    if platform.system() == "Windows":
        # Check if we're in MSYS2/MinGW environment or have CC set to MinGW
        cc_env = os.environ.get("CC", "")
        msystem = os.environ.get("MSYSTEM", "")

        if (
            "mingw32" in cc_env.lower()
            or "gcc" in cc_env.lower()
            or msystem == "MINGW64"
            or msystem == "MINGW32"
        ):
            # Use GCC/MinGW flags for better C99/C11 support
            # Let Python headers define SIZEOF_VOID_P correctly
            # Add explicit pointer size for Windows MinGW builds
            extra_compile_args = [
                "-std=c99",
                "-Wno-unused-function",
                "-Wno-sign-compare",
                "-DPy_NO_ENABLE_SHARED",  # Help with MinGW Python linking
            ]
            print("Using MinGW/GCC compiler on Windows")
        else:
            # MSVC flags - but warn that complex numbers may not work
            extra_compile_args = ["/std:c11"]
            print(
                "Using MSVC compiler on Windows (Warning: C complex numbers may not be supported)"
            )
    else:
        # GCC/Clang flags - let Python headers define SIZEOF_VOID_P correctly
        extra_compile_args = ["-std=c99", "-Wno-unused-function"]

    # Start with empty extensions list - we'll add them as we implement phases
    extensions = []

    # Phase 1: OCTypes helper functions
    extensions.extend(
        [
            Extension(
                "rmnpy.helpers.octypes",
                sources=["src/rmnpy/helpers/octypes.pyx"],
                include_dirs=include_dirs,
                library_dirs=library_dirs,
                libraries=libraries,
                language="c",
                extra_compile_args=extra_compile_args,
                extra_link_args=extra_link_args,
            )
        ]
    )

    # Test modules are built separately for testing, not during installation
    # Use: python setup.py build_ext --inplace to build tests for development
    # extensions.extend([
    #     Extension(
    #         "test_octypes_linking",
    #         sources=["tests/test_helpers/test_octypes_linking.pyx"],
    #         include_dirs=include_dirs,
    #         library_dirs=library_dirs,
    #         libraries=libraries,
    #         language="c",
    #         extra_compile_args=extra_compile_args,
    #         extra_link_args=extra_link_args
    #     ),
    #     Extension(
    #         "test_octypes_roundtrip",
    #         sources=["tests/test_helpers/test_octypes_roundtrip.pyx"],
    #         include_dirs=include_dirs,
    #         library_dirs=library_dirs,
    #         libraries=libraries,
    #         language="c",
    #         extra_compile_args=extra_compile_args,
    #         extra_link_args=extra_link_args
    #     ),
    #     Extension(
    #         "test_minimal",
    #         sources=["tests/test_helpers/test_minimal.pyx"],
    #         include_dirs=include_dirs,
    #         library_dirs=library_dirs,
    #         libraries=libraries,
    #         language="c",
    #         extra_compile_args=extra_compile_args,
    #         extra_link_args=extra_link_args
    #     )
    # ])

    # Phase 2A: SIDimensionality wrapper (complete implementation)
    extensions.extend(
        [
            Extension(
                "rmnpy.wrappers.sitypes.dimensionality",
                sources=["src/rmnpy/wrappers/sitypes/dimensionality.pyx"],
                include_dirs=include_dirs,
                library_dirs=library_dirs,
                libraries=libraries,
                language="c",
                extra_compile_args=extra_compile_args,
                extra_link_args=extra_link_args,
            )
        ]
    )

    # Phase 2B: SIUnit wrapper (complete implementation)
    extensions.extend(
        [
            Extension(
                "rmnpy.wrappers.sitypes.unit",
                sources=["src/rmnpy/wrappers/sitypes/unit.pyx"],
                include_dirs=include_dirs,
                library_dirs=library_dirs,
                libraries=libraries,
                language="c",
                extra_compile_args=extra_compile_args,
                extra_link_args=extra_link_args,
            )
        ]
    )

    # Phase 2C: SIScalar wrapper (complete implementation)
    extensions.extend(
        [
            Extension(
                "rmnpy.wrappers.sitypes.scalar",
                sources=["src/rmnpy/wrappers/sitypes/scalar.pyx"],
                include_dirs=include_dirs,
                library_dirs=library_dirs,
                libraries=libraries,
                language="c",
                extra_compile_args=extra_compile_args,
                extra_link_args=extra_link_args,
            )
        ]
    )

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
            "language_level": 3,
            "embedsignature": True,
            "boundscheck": False,
            "wraparound": False,
            "initializedcheck": False,
        },
        # Add build configuration for Windows compatibility
        build_dir="build",
    ),
    cmdclass={
        "build_ext": CustomBuildExt,
    },
    zip_safe=False,
)
