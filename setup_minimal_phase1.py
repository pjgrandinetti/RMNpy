# setup_minimal_phase1.py — Ultra-minimal setup for Phase 1A testing
# Goal: Test basic Python extension building without full dependency chain

import os
import sys
from distutils.sysconfig import get_python_inc

from setuptools import Extension, find_packages, setup
from setuptools.command.build_ext import build_ext

print("=" * 50)
print("Phase 1A: Ultra-minimal build test")
print("Goal: Test basic extension building")
print("=" * 50)

# Force MinGW compiler on Windows for cibuildwheel builds
if sys.platform == "win32" and os.environ.get("CIBUILDWHEEL"):
    print("Windows cibuildwheel detected - forcing MinGW...")
    os.environ["CC"] = "C:/msys64/mingw64/bin/gcc.exe"
    os.environ["CXX"] = "C:/msys64/mingw64/bin/g++.exe"
    os.environ["DISTUTILS_USE_SDK"] = "1"
    os.environ["MSSdk"] = "1"

    try:
        from distutils import ccompiler

        def get_default_compiler(plat=None) -> str:
            return "mingw32"

        ccompiler.get_default_compiler = get_default_compiler
    except ImportError:
        pass


class MinimalBuildExt(build_ext):
    def build_extensions(self) -> None:
        print(f"Building extensions with compiler: {self.compiler}")

        # Force MinGW on Windows during cibuildwheel
        if sys.platform == "win32" and os.environ.get("CIBUILDWHEEL"):
            if (
                hasattr(self.compiler, "compiler_type")
                and self.compiler.compiler_type == "msvc"
            ):
                print("WARNING: MSVC detected, attempting MinGW switch...")
                try:
                    from distutils.cygwinccompiler import Mingw32CCompiler

                    self.compiler = Mingw32CCompiler()
                    self.compiler.set_executables(
                        compiler="C:/msys64/mingw64/bin/gcc.exe",
                        compiler_so="C:/msys64/mingw64/bin/gcc.exe",
                        compiler_cxx="C:/msys64/mingw64/bin/g++.exe",
                        linker_exe="C:/msys64/mingw64/bin/gcc.exe",
                        linker_so="C:/msys64/mingw64/bin/gcc.exe",
                    )
                    print("Successfully switched to MinGW compiler")
                except Exception as e:
                    print(f"MinGW switch failed: {e}")

        # Try to build extensions and capture any errors
        try:
            super().build_extensions()
        except Exception as e:
            print(f"Extension building failed with error: {e}")
            # Try to get more details about the failure
            import traceback

            print("Full traceback:")
            traceback.print_exc()
            raise


# Minimal includes - Python headers and numpy
INC: list[str] = []

# Add Python include directory
python_inc = get_python_inc()
INC.append(python_inc)
print(f"Python include: {python_inc}")

try:
    import numpy as np

    INC.append(np.get_include())
    print(f"Found numpy include: {np.get_include()}")
except ImportError:
    print("WARNING: numpy not found")

# No external libraries for Phase 1A - just test Python extension building
LIBS: list[str] = []
LIBDIRS: list[str] = []

# Add Python library for linking on Windows
if sys.platform == "win32":
    from distutils.sysconfig import get_config_var

    # Try to get library directory from config
    python_lib = get_config_var("LIBDIR")
    if python_lib:
        LIBDIRS.append(python_lib)
        print(f"Python library dir: {python_lib}")
    else:
        # In cibuildwheel, LIBDIR might be None, so try multiple locations
        python_exe = sys.executable
        print(f"Python executable: {python_exe}")

        # Try common library locations
        potential_dirs = [
            # Standard installation: libs next to exe
            os.path.join(os.path.dirname(python_exe), "libs"),
            # Virtual env: libs in base Python
            (
                os.path.join(sys.base_prefix, "libs")
                if hasattr(sys, "base_prefix")
                else None
            ),
            # Alternative: libs in prefix
            os.path.join(sys.prefix, "libs"),
            # cibuildwheel nuget cache location (from log path pattern)
            r"C:\Users\runneradmin\AppData\Local\pypa\cibuildwheel\Cache\nuget-cpython\python.3.12.6\tools\libs",
        ]

        for lib_dir in potential_dirs:
            if lib_dir and os.path.exists(lib_dir):
                LIBDIRS.append(lib_dir)
                print(f"Python library dir (found): {lib_dir}")
                break
        else:
            print(
                f"WARNING: Could not find Python library directory in any of: {potential_dirs}"
            )
            # On Windows with MinGW, we might not need explicit library linking
            print(
                "Continuing without explicit Python library - MinGW may handle this automatically"
            )

    # Add python library name - but only if we found a library directory
    if LIBDIRS:
        python_version = f"python{sys.version_info.major}.{sys.version_info.minor}"
        LIBS.append(python_version)
        print(f"Python library: {python_version}")
    else:
        print(
            "No Python library directory found - skipping explicit Python library linking"
        )
        print("MinGW should automatically handle Python API linking for extensions")

EXTRA_LINK: list[str] = []
EXTRA_COMPILE: list[str] = []

if sys.platform == "win32":
    EXTRA_COMPILE = ["-std=gnu99"]
else:
    EXTRA_COMPILE = ["-std=c99"]

print(f"Platform: {sys.platform}")
print(f"Include dirs: {INC}")
print(f"Libraries: {LIBS}")
print(f"Library dirs: {LIBDIRS}")
print(f"Extra compile args: {EXTRA_COMPILE}")

# Create a minimal test extension that doesn't require external libraries
# This will test if the basic build system works
test_extension = Extension(
    "rmnpy._test_minimal",
    ["test_minimal.c"],  # We'll create this
    include_dirs=INC,
    libraries=LIBS,
    library_dirs=LIBDIRS,
    extra_compile_args=EXTRA_COMPILE,
    extra_link_args=EXTRA_LINK,
)

setup(
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    include_package_data=True,
    cmdclass={"build_ext": MinimalBuildExt},
    ext_modules=[test_extension],
)
