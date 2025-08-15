#!/usr/bin/env python3
"""Setup script for RMNpy - Python bindings for OCTypes, SITypes, and RMNLib."""
# Version with automatic import library generation for Windows DLLs - commit 452219ad

import os
import platform
import subprocess
import sys

# Import for SpinOps-style MinGW forcing and Python headers
import sysconfig

# Handle distutils imports with fallbacks for different Python versions
try:
    from distutils.ccompiler import new_compiler  # type: ignore[import-untyped]

    from setuptools._distutils.sysconfig import (
        get_python_inc,  # type: ignore[attr-defined]
    )
except ImportError:
    # Ultimate fallback for testing - use sysconfig only
    from typing import Any

    def new_compiler(*args: Any, **kwargs: Any) -> Any:
        return None

    # Note: customize_compiler fallback is provided later to avoid redefinition
    def get_python_inc(*args: Any, **kwargs: Any) -> str:
        return sysconfig.get_path("include")


from pathlib import Path
from typing import TYPE_CHECKING

# Ensure customize_compiler is available; some environments provide it via
# distutils.sysconfig while others may not. Provide a safe no-op fallback.
try:
    from distutils.sysconfig import customize_compiler  # type: ignore[import-untyped]
except Exception:
    # Only define a fallback if an earlier import/fallback didn't already define it
    if "customize_compiler" not in globals():

        def customize_compiler(*args, **kwargs):
            """Fallback no-op if customize_compiler is unavailable."""
            return None


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

        try:
            # Continue with normal build
            super().build_extensions()
        finally:
            # Always restore hidden static libraries on Windows
            if platform.system() == "Windows":
                self._restore_hidden_libraries()

    def _restore_hidden_libraries(self) -> None:
        """Restore hidden static libraries on Windows after build."""
        try:
            hidden_libs = globals().get("_hidden_static_libs", [])
            if hidden_libs:
                import shutil

                print(f"Windows: Restoring {len(hidden_libs)} hidden static libraries")
                for original_path, backup_path in hidden_libs:
                    if os.path.exists(backup_path):
                        shutil.move(backup_path, original_path)
                        print(f"Windows: Restored {original_path}")
                # Clear the global variable
                globals()["_hidden_static_libs"] = []
        except Exception as e:
            print(f"Windows: Error restoring hidden libraries: {e}")

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

        # Determine library extension based on platform
        system = platform.system()
        if system == "Windows":
            lib_ext = ".dll"
        elif system == "Darwin":  # macOS
            lib_ext = ".dylib"
        else:  # Linux and other Unix-like systems
            lib_ext = ".so"

        # Required library files
        required_libs = [
            lib_dir / f"libOCTypes{lib_ext}",
            lib_dir / f"libSITypes{lib_ext}",
            lib_dir / f"libRMN{lib_ext}",
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

    # Library configuration depends on platform
    if platform.system() == "Windows":
        # On Windows with MinGW, we need to force linking against DLL import libraries
        # instead of static libraries to avoid undefined reference errors.
        #
        # The issue: MinGW linker prefers libXXX.a over libXXX.dll.a
        # Solution: Temporarily hide static libraries during linking
        import glob
        import os  # Import os here for Windows-specific operations
        import shutil

        # On Windows, check what type of libraries we have for each dependency
        # Some might have .dll.a import libraries, others might just have DLLs
        lib_info = {}
        main_libs = ["RMN", "SITypes", "OCTypes"]

        for lib_name in main_libs:
            dll_a_path = os.path.join("lib", f"lib{lib_name}.dll.a")
            dll_path = os.path.join("lib", f"lib{lib_name}.dll")
            static_path = os.path.join("lib", f"lib{lib_name}.a")

            if os.path.exists(dll_a_path):
                lib_info[lib_name] = {"type": "dll_import", "path": dll_a_path}
                print(f"Windows: Found DLL import library: {dll_a_path}")
            elif os.path.exists(dll_path):
                # For DLLs without import libraries, create a temporary import library
                temp_import_lib = f"lib/lib{lib_name}.dll.a.temp"
                if not os.path.exists(temp_import_lib):
                    print(f"Windows: Creating import library for {dll_path}")
                    try:
                        # Use objdump to extract exported symbols and create a .def file,
                        # then use dlltool to make an import library. This mirrors numpy's
                        # approach and works under MSYS2/MinGW.
                        import re
                        import subprocess

                        def _dump_table(dll_file_path: str):
                            # Try several objdump variants to account for MSYS2/toolchain differences
                            candidates = [
                                ["x86_64-w64-mingw32-objdump", "-p", dll_file_path],
                                ["objdump.exe", "-p", dll_file_path],
                                ["objdump", "-p", dll_file_path],
                                ["x86_64-w64-mingw32-objdump.exe", "-p", dll_file_path],
                            ]
                            last_exc = None
                            for cmd in candidates:
                                try:
                                    out = subprocess.check_output(
                                        cmd, stderr=subprocess.STDOUT
                                    )
                                    return out.split(b"\n")
                                except (
                                    subprocess.CalledProcessError,
                                    FileNotFoundError,
                                ) as e:
                                    last_exc = e
                                    continue
                            # If none worked, re-raise the last exception for upstream handling
                            if last_exc is not None:
                                raise last_exc
                            return []

                        def _generate_def_from_dump(dll_file_path: str, def_path: str):
                            dump = _dump_table(dll_file_path)

                            # Try several start patterns to cope with objdump formatting
                            start_patterns = [
                                r"\[Ordinal/Name Pointer\] Table",
                                r"Export Table",
                                r"Exports",
                            ]
                            start_re_list = [re.compile(p) for p in start_patterns]

                            # Table line patterns - a few variants observed in different objdump builds
                            table_patterns = [
                                r"^\s*\[\s*(\d+)\]\s*([A-Za-z0-9_@]+)",
                                r"^\s*(\d+)\s+([A-Za-z0-9_@]+)",
                            ]
                            table_re_list = [re.compile(p) for p in table_patterns]

                            # Locate start of export table
                            start_idx = None
                            for i in range(len(dump)):
                                try:
                                    line = dump[i].decode(errors="ignore")
                                except Exception:
                                    line = ""
                                for start_re in start_re_list:
                                    if start_re.search(line):
                                        start_idx = i
                                        break
                                if start_idx is not None:
                                    break

                            if start_idx is None:
                                # Dump first lines to a debug file to help CI diagnostics
                                try:
                                    debug_path = os.path.join(
                                        "lib",
                                        f"lib{os.path.basename(dll_file_path)}.objdump.txt",
                                    )
                                    with open(debug_path, "wb") as df:
                                        df.write(b"\n".join(dump[:200]))
                                    print(
                                        f"Windows: objdump format not recognized, saved sample to {debug_path}"
                                    )
                                except Exception:
                                    pass
                                raise ValueError(
                                    "Symbol table not found in DLL (objdump output differs)"
                                )

                            syms = []
                            for j in range(start_idx + 1, len(dump)):
                                try:
                                    line = dump[j].decode(errors="ignore")
                                except Exception:
                                    continue
                                matched = False
                                for table_re in table_re_list:
                                    m = table_re.match(line)
                                    if m:
                                        syms.append(m.group(2))
                                        matched = True
                                        break
                                if not matched:
                                    # Stop on first non-matching line after the table
                                    break

                            if len(syms) == 0:
                                print(
                                    f"Windows: Warning - no exported symbols found in {dll_file_path}"
                                )

                            with open(def_path, "w") as df:
                                df.write(
                                    f"LIBRARY        {os.path.basename(dll_file_path)}\n"
                                )
                                df.write(
                                    ";CODE          PRELOAD MOVEABLE DISCARDABLE\n"
                                )
                                df.write(";DATA          PRELOAD SINGLE\n")
                                df.write("\nEXPORTS\n")
                                for s in syms:
                                    df.write(f"{s}\n")

                        # Create a temporary .def file next to libs so paths are simple
                        temp_def = os.path.join("lib", f"lib{lib_name}.def")
                        try:
                            _generate_def_from_dump(dll_path, temp_def)
                            # Call dlltool with the generated def file to create import library
                            result = subprocess.run(
                                ["dlltool", "-d", temp_def, "-l", temp_import_lib],
                                capture_output=True,
                                text=True,
                            )

                            if result.returncode == 0 and os.path.exists(
                                temp_import_lib
                            ):
                                lib_info[lib_name] = {
                                    "type": "generated_import",
                                    "path": temp_import_lib,
                                }
                                print(
                                    f"Windows: Successfully created import library: {temp_import_lib}"
                                )
                            else:
                                print(
                                    f"Windows: Failed to create import library for {lib_name}: {result.stderr} {result.stdout}"
                                )
                                # Fall back to direct DLL linking (may not work)
                                lib_info[lib_name] = {
                                    "type": "dll_only",
                                    "path": dll_path,
                                }
                        finally:
                            # Clean up generated .def if it exists
                            try:
                                if os.path.exists(temp_def):
                                    os.remove(temp_def)
                            except Exception:
                                pass
                    except FileNotFoundError:
                        print(
                            f"Windows: objdump/dlltool not found, cannot create import library for {lib_name}"
                        )
                        lib_info[lib_name] = {"type": "dll_only", "path": dll_path}
                    except Exception as e:
                        print(
                            f"Windows: Error creating import library for {lib_name}: {e}"
                        )
                        lib_info[lib_name] = {"type": "dll_only", "path": dll_path}
                else:
                    lib_info[lib_name] = {
                        "type": "generated_import",
                        "path": temp_import_lib,
                    }
                    print(
                        f"Windows: Using existing generated import library: {temp_import_lib}"
                    )
            elif os.path.exists(static_path):
                lib_info[lib_name] = {"type": "static", "path": static_path}
                print(f"Windows: Found static library: {static_path}")
            else:
                print(f"Windows: WARNING - No library found for {lib_name}")

        # Strategy: Use explicit paths for all libraries to avoid MinGW confusion
        # This prevents MinGW from choosing the wrong library type
        print("Windows: Using explicit library paths to avoid linking issues")

        # Don't use library names in Extension() - use only external dependencies
        main_libraries = []  # Empty - we'll use explicit paths in extra_link_args

        external_libraries = [
            "curl",
            "openblas",
            "lapack",
            "gcc_s",
            "winpthread",
            "quadmath",
            "gomp",
        ]

        # Build explicit library paths for extra_link_args
        explicit_lib_paths = []

        # Hide static libraries if we have import libraries or DLLs available
        static_libs_to_hide = []
        try:
            for lib_name in main_libs:
                if lib_name in lib_info:
                    lib_data = lib_info[lib_name]
                    if lib_data["type"] in ["dll_import", "generated_import"]:
                        # Use the DLL import library (real or generated)
                        abs_path = os.path.abspath(lib_data["path"])
                        explicit_lib_paths.append(abs_path)
                        print(f"Windows: Will explicitly link: {abs_path}")

                        # Hide corresponding static library to prevent conflicts
                        static_path = os.path.join("lib", f"lib{lib_name}.a")
                        if os.path.exists(static_path):
                            backup_name = static_path + ".backup"
                            if not os.path.exists(backup_name):
                                shutil.move(static_path, backup_name)
                                static_libs_to_hide.append((static_path, backup_name))
                                print(
                                    f"Windows: Temporarily hiding static {static_path}"
                                )
                    elif lib_data["type"] == "dll_only":
                        # This shouldn't work with MinGW, but let's try
                        print(
                            f"Windows: WARNING - Attempting direct DLL linking for {lib_name} (may fail)"
                        )
                        # Don't add DLL to explicit paths, fall back to library name
                        external_libraries.insert(
                            0, lib_name
                        )  # Add to front so it's found first
                    else:
                        # Fall back to library name for static linking
                        print(f"Windows: Using static library for {lib_name}")
                        external_libraries.insert(0, lib_name)
                        print(f"Windows: Using static library for {lib_name}")

        except Exception as e:
            print(f"Windows: Error managing library paths: {e}")

        # Store paths and hidden libraries for later use/cleanup
        globals()["_explicit_dll_libs"] = explicit_lib_paths
        globals()["_hidden_static_libs"] = static_libs_to_hide

        # Set final libraries list to just external dependencies
        libraries = external_libraries
    else:
        # On Unix-like systems, library order matters for static linking
        # RMN depends on OCTypes/SITypes, so list RMN first
        libraries = ["RMN", "SITypes", "OCTypes"]

    # Add runtime library directory for shared libraries
    # This tells the dynamic linker where to find .dylib/.so files at runtime
    # Note: runtime_library_dirs is not supported on Windows
    import os

    # Only set runtime_library_dirs on Unix-like systems (Linux/macOS)
    runtime_library_dirs = (
        [] if platform.system() == "Windows" else [os.path.abspath("lib")]
    )

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

        # On Windows with MinGW, force linking to DLL import libraries instead of static libraries
        # The .dll.a files are the import libraries for the DLLs
        # This avoids undefined references when linking against static libraries
        extra_link_args.extend(
            [
                "-Wl,--enable-auto-import",  # Allow auto-import from DLLs
                "-Wl,--disable-auto-image-base",  # Prevent address conflicts
            ]
        )

        # Add explicit paths to DLL import libraries if available
        explicit_dll_libs = globals().get("_explicit_dll_libs", [])
        if explicit_dll_libs:
            print(
                f"Windows: Adding {len(explicit_dll_libs)} explicit library paths to linker args"
            )
            for lib_path in explicit_dll_libs:
                extra_link_args.append(lib_path)
                print(f"Windows: Added explicit linker arg: {lib_path}")
        # Add MSYS2/MinGW64 specific include directories for dependencies
        # These are needed for RMNLib which depends on BLAS/LAPACK headers
        mingw_prefix = os.environ.get("MSYSTEM_PREFIX", "/mingw64")
        include_dirs.extend(
            [
                f"{mingw_prefix}/include/openblas",  # For cblas.h, lapacke.h
                f"{mingw_prefix}/include",  # General MinGW headers
            ]
        )

        # Add MinGW library directories
        library_dirs.extend(
            [
                f"{mingw_prefix}/lib",  # MinGW libraries
            ]
        )

        # Add external dependencies required by RMNLib on Windows
        # These are needed because the static libraries don't include external deps
        # For MSYS2 MinGW64, use the actual library names from the installation
        if "external_libraries" in locals():
            # We're using explicit library paths, so combine external deps with main libraries
            libraries = external_libraries
        else:
            # Standard approach - extend the existing libraries list
            libraries.extend(["curl", "openblas", "lapack"])

        # Add MinGW runtime libraries with correct library names
        # Note: In MSYS2 MinGW64, these are the correct linker names
        if "external_libraries" not in locals():
            libraries.extend(["gcc_s", "winpthread", "quadmath", "gomp"])

        # Try to find the correct Fortran library name
        mingw_lib_dir = os.environ.get("MINGW_LIB_DIR")
        if mingw_lib_dir and os.path.exists(mingw_lib_dir):
            library_dirs.append(mingw_lib_dir)
            # Look for Fortran library variants - check actual library names
            print(f"Checking Fortran libraries in: {mingw_lib_dir}")

            # First check what library files actually exist
            try:
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
                runtime_library_dirs=runtime_library_dirs,
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
                runtime_library_dirs=runtime_library_dirs,
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
                runtime_library_dirs=runtime_library_dirs,
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
                runtime_library_dirs=runtime_library_dirs,
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

    # Phase 3A: RMNLib Dimension wrapper (ENABLED after fixing header issue)
    extensions.extend(
        [
            Extension(
                "rmnpy.wrappers.rmnlib.dimension",
                sources=["src/rmnpy/wrappers/rmnlib/dimension.pyx"],
                include_dirs=include_dirs,
                library_dirs=library_dirs,
                libraries=libraries,
                runtime_library_dirs=runtime_library_dirs,
                language="c",
                extra_compile_args=extra_compile_args,
                extra_link_args=extra_link_args,
            )
        ]
    )

    # Phase 3B+: Other RMNLib wrappers (DISABLED until Phase 3A testing complete)
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

    # Constants module - SI quantity constants
    extensions.extend(
        [
            Extension(
                "rmnpy.constants",
                sources=["src/rmnpy/constants.pyx"],
                include_dirs=include_dirs,
                library_dirs=library_dirs,
                libraries=libraries,
                runtime_library_dirs=runtime_library_dirs,
                language="c",
                extra_compile_args=extra_compile_args,
                extra_link_args=extra_link_args,
            )
        ]
    )

    return extensions


# Note: Most project configuration is now in pyproject.toml
# This setup.py only handles the Cython build process

if __name__ == "__main__":
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
