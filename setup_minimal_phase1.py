# setup_minimal_phase1.py — Ultra-minimal setup for Phase 1A testing
# Goal: Test basic Python extension building without full dependency chain

import os
import sys
from distutils.sysconfig import get_python_inc
from typing import List

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
        """Override build_extensions with comprehensive MinGW debugging and numpy exclusion"""

        print("\n" + "=" * 80)
        print("PHASE 1A: Ultra-minimal build with MinGW compiler forcing")
        print("=" * 80)

        # CRITICAL FIX: Force MinGW compiler BEFORE any build attempts
        # Previous logs showed cl.exe (MSVC) was being used instead of gcc
        if hasattr(self.compiler, 'compiler_type'):
            print(f"Current compiler type: {self.compiler.compiler_type}")
            
        if os.name == 'nt':  # Windows
            print("Windows detected - forcing MinGW compiler...")
            self._force_mingw_compiler()
        
        # Now try the build with the correct compiler
        try:
            print("Attempting build with MinGW compiler...")
            super().build_extensions()
            print("SUCCESS: Build completed with MinGW!")
            
        except Exception as e:
            print(f"Build failed with MinGW: {e}")
            print("Doing detailed debugging...")
            self._detailed_debugging()
            raise

    def _force_mingw_compiler(self) -> None:
        """Force MinGW compiler on Windows instead of MSVC"""
        import subprocess
        from distutils.compilers.C import cygwin
        
        print("Forcing MinGW compiler...")
        
        # Create a new MinGW compiler instance
        mingw_compiler = cygwin.Compiler()
        
        # Set up MinGW paths
        mingw_compiler.set_executables(
            compiler='C:/msys64/mingw64/bin/gcc.exe',
            compiler_so='C:/msys64/mingw64/bin/gcc.exe',
            compiler_cxx='C:/msys64/mingw64/bin/g++.exe',
            linker_exe='C:/msys64/mingw64/bin/gcc.exe',
            linker_so='C:/msys64/mingw64/bin/gcc.exe',
        )
        
        # Replace the compiler
        self.compiler = mingw_compiler
        print("MinGW compiler forced successfully")

    def _detailed_debugging(self) -> None:
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
            # On Windows, let's try to run the GCC command manually to see the actual error
            if sys.platform == "win32" and os.environ.get("CIBUILDWHEEL"):
                print("Testing GCC manually before building extensions...")
                import subprocess

                # Test basic GCC functionality
                try:
                    result = subprocess.run(
                        ["C:/msys64/mingw64/bin/gcc.exe", "--version"],
                        capture_output=True,
                        text=True,
                        timeout=30,
                    )
                    print(f"GCC version test: {result.returncode}")
                    print(f"GCC stdout: {result.stdout}")
                    print(f"GCC stderr: {result.stderr}")
                except Exception as gcc_test_error:
                    print(f"GCC version test failed: {gcc_test_error}")

                # Test if we can find the test file
                test_file = "test_minimal.c"
                if os.path.exists(test_file):
                    print(f"Found test file: {test_file}")
                    print(f"File size: {os.path.getsize(test_file)} bytes")

                    # Check if we can read the file
                    try:
                        with open(test_file, "r") as f:
                            content = f.read()
                            print(f"File content length: {len(content)} chars")
                            print(f"First 100 chars: {content[:100]}")
                    except Exception as read_error:
                        print(f"File read error: {read_error}")

                    # Try simple compilation first (without verbose to avoid too much output)
                    try:
                        print("Attempting simple compilation...")
                        result = subprocess.run(
                            [
                                "C:/msys64/mingw64/bin/gcc.exe",
                                "-I",
                                r"C:\Users\runneradmin\AppData\Local\pypa\cibuildwheel\Cache\nuget-cpython\python.3.12.6\tools\include",
                                "-c",
                                test_file,
                                "-o",
                                "test_manual.o",
                                "-std=gnu99",
                            ],
                            capture_output=True,
                            text=True,
                            timeout=30,
                        )
                        print(f"Simple compilation: {result.returncode}")
                        print(f"Simple stdout: '{result.stdout}'")
                        print(f"Simple stderr: '{result.stderr}'")

                        # If simple compilation failed, try even simpler test
                        if result.returncode != 0:
                            print("Simple compilation failed, trying hello world...")
                            with open("test_hello.c", "w") as f:
                                f.write("int main() { return 0; }\n")

                            result3 = subprocess.run(
                                [
                                    "C:/msys64/mingw64/bin/gcc.exe",
                                    "-c",
                                    "test_hello.c",
                                    "-o",
                                    "test_hello.o",
                                ],
                                capture_output=True,
                                text=True,
                                timeout=30,
                            )
                            print(f"Hello world test: {result3.returncode}")
                            print(f"Hello world stderr: '{result3.stderr}'")

                            # Try with just Python.h test
                            print("Trying minimal Python.h test...")
                            with open("test_python_h.c", "w") as f:
                                f.write(
                                    "#include <Python.h>\nint main() { return 0; }\n"
                                )

                            result2 = subprocess.run(
                                [
                                    "C:/msys64/mingw64/bin/gcc.exe",
                                    "-I",
                                    r"C:\Users\runneradmin\AppData\Local\pypa\cibuildwheel\Cache\nuget-cpython\python.3.12.6\tools\include",
                                    "-c",
                                    "test_python_h.c",
                                    "-o",
                                    "test_python_h.o",
                                ],
                                capture_output=True,
                                text=True,
                                timeout=30,
                            )
                            print(f"Python.h test: {result2.returncode}")
                            print(f"Python.h stdout: '{result2.stdout}'")
                            print(f"Python.h stderr: '{result2.stderr}'")

                    except Exception as manual_test_error:
                        print(f"Manual compilation test failed: {manual_test_error}")
                else:
                    print(f"ERROR: Could not find test file: {test_file}")
                    print(f"Current directory: {os.getcwd()}")
                    print(f"Directory contents: {os.listdir('.')}")

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
