#!/usr/bin/env python3
"""Setup script for RMNpy - Python bindings for OCTypes, SITypes, and RMNLib."""

import os
import platform
import subprocess
import sys

# Import for SpinOps-style MinGW forcing and Python headers
import sysconfig

# Handle distutils imports with fallbacks for different Python versions
try:
    from distutils.ccompiler import new_compiler  # type: ignore[import-untyped]
    from distutils.sysconfig import customize_compiler  # type: ignore[import-untyped]
    from distutils.sysconfig import get_python_inc  # type: ignore[import-untyped]
except ImportError:
    try:
        from setuptools._distutils.ccompiler import (
            new_compiler,  # type: ignore[attr-defined]
        )
        from setuptools._distutils.sysconfig import (
            customize_compiler,  # type: ignore[attr-defined]
        )
        from setuptools._distutils.sysconfig import (
            get_python_inc,  # type: ignore[attr-defined]
        )
    except ImportError:
        # Ultimate fallback for testing - use sysconfig only
        from typing import Any

        def new_compiler(*args: Any, **kwargs: Any) -> Any:
            return None

        def customize_compiler(*args: Any, **kwargs: Any) -> None:
            pass

        def get_python_inc(*args: Any, **kwargs: Any) -> str:
            return sysconfig.get_path("include")


from pathlib import Path
from typing import TYPE_CHECKING

import numpy
from Cython.Build import cythonize
from setuptools import Extension, setup
from setuptools.command.build_ext import build_ext

if TYPE_CHECKING:
    pass


# Force MinGW compiler on Windows early in setup (SpinOps approach)
# This must happen before any other setup code to ensure correct compiler selection
if sys.platform == "win32":
    # Get pointer size to determine 32-bit vs 64-bit
    try:
        from distutils.sysconfig import get_config_var

        ptr_size = get_config_var("SIZEOF_VOID_P") or __import__("struct").calcsize("P")
        ptr_size = int(ptr_size)
    except Exception:
        ptr_size = 8  # Default to 64-bit

    # Set MinGW compiler environment variables early
    os.environ["CC"] = (
        "i686-w64-mingw32-gcc" if ptr_size == 4 else "x86_64-w64-mingw32-gcc"
    )
    os.environ["CXX"] = (
        "i686-w64-mingw32-g++" if ptr_size == 4 else "x86_64-w64-mingw32-g++"
    )
    print(f"[setup.py] Set MinGW compiler environment: CC={os.environ['CC']}")


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
    """Custom build extension that handles library dependencies and forces MinGW on Windows."""

    def build_extensions(self) -> None:
        """Override to force MinGW compiler on Windows like SpinOps does."""
        # First do our dependency checking
        self._check_dependencies()

        # Force MinGW compiler on Windows (SpinOps approach)
        if platform.system() == "Windows":
            compiler = new_compiler(compiler="mingw32")
            customize_compiler(compiler)
            self.compiler = compiler
            print("Forced MinGW compiler on Windows")

        # Continue with normal build
        super().build_extensions()

    def run(self) -> None:
        """Check dependencies before building extensions."""
        # Generate SI constants before building
        generate_si_constants()
        # Continue with normal build (which will call build_extensions)
        super().run()

    def _check_dependencies(self) -> None:
        """Check dependencies before building extensions."""
        print("Checking library dependencies...")

        if not self._check_libraries():
            print("\nError: Required libraries not found!")
            print("Please run one of the following commands first:")
            print("  make synclib      # Copy from local development directories")
            print("  make download-libs # Download from GitHub releases")
            sys.exit(1)

        print("[OK] All required libraries found")

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
        get_python_inc(),  # Python headers (essential for MinGW builds)
    ]

    # Common library directories and libraries
    library_dirs = ["lib"]
    libraries = ["OCTypes", "SITypes", "RMN"]

    # Common compiler/linker options (platform-specific)
    extra_link_args: list[str] = []
    define_macros: list[tuple[str, str]] = [
        ("NPY_NO_DEPRECATED_API", "NPY_1_7_API_VERSION")
    ]

    if platform.system() == "Windows":
        # On Windows, our CustomBuildExt class forces MinGW, so use GCC-style flags
        # Following SpinOps approach: don't override SIZEOF_VOID_P, let Cython handle it
        # But add the correct SIZEOF_VOID_P for x86_64 MinGW to prevent Cython check failure
        extra_compile_args = [
            "-std=c99",
            "-Wno-unused-function",
            "-Wno-sign-compare",
            "-DPy_NO_ENABLE_SHARED",  # Help with MinGW Python linking
        ]
        # Add external dependencies required by RMNLib on Windows
        # These are needed because the static libraries don't include external deps
        # For MSYS2 MinGW64, use the actual library names from the installation
        libraries.extend(["curl", "openblas", "lapack"])

        # Add MinGW runtime libraries with correct library names
        # Note: In MSYS2 MinGW64, these are the correct linker names
        libraries.extend(["gcc_s", "winpthread", "quadmath", "gomp"])

        # Try to find the correct Fortran library name
        mingw_lib_dir = os.environ.get("MINGW_LIB_DIR")
        if mingw_lib_dir and os.path.exists(mingw_lib_dir):
            library_dirs.append(mingw_lib_dir)
            # Look for Fortran library variants - check actual library names
            print(f"Checking Fortran libraries in: {mingw_lib_dir}")

            # First check what library files actually exist
            try:
                import glob

                static_libs = glob.glob(os.path.join(mingw_lib_dir, "lib*fortran*.a"))
                dll_libs = glob.glob(
                    os.path.join(
                        mingw_lib_dir.replace("/lib", "/bin"), "lib*fortran*.dll"
                    )
                )
                print(
                    f"Found static libs: {[os.path.basename(f) for f in static_libs]}"
                )
                print(f"Found DLL libs: {[os.path.basename(f) for f in dll_libs]}")

                # Also check for import libraries (.dll.a files)
                import_libs = glob.glob(
                    os.path.join(mingw_lib_dir, "lib*fortran*.dll.a")
                )
                print(
                    f"Found import libs: {[os.path.basename(f) for f in import_libs]}"
                )
            except Exception as e:
                print(f"Error checking library files: {e}")

            # In MSYS2 MinGW64, we need to link against the import library or use GCC's built-in libraries
            # Since libgfortran-5.dll exists but no static/import library, we skip explicit gfortran linking
            # GCC will automatically link the Fortran runtime when needed
            print(
                "MSYS2 MinGW64: Skipping explicit gfortran linking - GCC will handle it automatically"
            )
        # Add MinGW library directory for external dependencies
        # Add SIZEOF_VOID_P=8 for x86_64 to prevent Cython's division by zero error
        define_macros.append(("SIZEOF_VOID_P", "8"))
        print("Configured for MinGW/GCC compiler on Windows")
    else:
        # GCC/Clang flags on Unix-like systems
        extra_compile_args = ["-std=c99", "-Wno-unused-function"]
        define_macros = [("NPY_NO_DEPRECATED_API", "NPY_1_7_API_VERSION")]

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
                define_macros=define_macros,
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

    # Phase 3: RMNLib wrappers
    # Build the dependent_variable wrapper for RMNLib
    # TODO: Re-enable when dependent_variable.pyx compilation issues are fixed
    # extensions.extend([
    #     Extension(
    #         "rmnpy.wrappers.rmnlib.dependent_variable",
    #         sources=["src/rmnpy/wrappers/rmnlib/dependent_variable.pyx"],
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
