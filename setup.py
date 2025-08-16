#!/usr/bin/env python3
"""Setup script for RMNpy - Python bindings for OCTypes, SITypes, and RMNLib."""

import os
import platform
import subprocess
import sys

# Import for SpinOps-style MinGW forcing and Python headers
import sysconfig
from pathlib import Path
from typing import TYPE_CHECKING, Any, List

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
        def new_compiler(*args: Any, **kwargs: Any) -> Any:
            return None

        def customize_compiler(*args: Any, **kwargs: Any) -> None:
            pass

        def get_python_inc(*args: Any, **kwargs: Any) -> str:
            return sysconfig.get_path("include")


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


# Generate SI quantities before defining extensions (required for quantities extension)
generate_si_constants()


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

        # Copy Windows bridge DLL to package directory for runtime access
        self._copy_windows_dll()

    def _copy_windows_dll(self) -> None:
        """Copy Windows bridge DLL to package directory for runtime access."""
        if platform.system() != "Windows":
            return

        lib_dir = Path(__file__).parent / "lib"
        src_rmnpy_dir = Path(__file__).parent / "src" / "rmnpy"

        bridge_dll_path = lib_dir / "rmnstack_bridge.dll"

        if bridge_dll_path.exists():
            import shutil

            dest_dll_path = src_rmnpy_dir / "rmnstack_bridge.dll"
            print(f"[setup.py] Copying bridge DLL to package: {dest_dll_path}")
            shutil.copy2(bridge_dll_path, dest_dll_path)
            print("[setup.py] Bridge DLL copied for runtime access")
        else:
            print(f"[setup.py] Warning: Bridge DLL not found at {bridge_dll_path}")
            print("[setup.py] Runtime may require DLL to be in system PATH")

    def run(self) -> None:
        """Check dependencies before building extensions."""
        # Generate SI quantities before building
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

        # Check for shared libraries (the actual runtime libraries)
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

        # Debug: list all files in lib directory
        print(f"Checking library directory: {lib_dir}")
        if lib_dir.exists():
            all_files = list(lib_dir.iterdir())
            print(f"Available files in lib/: {[f.name for f in all_files]}")
        else:
            print(f"[X] Library directory does not exist: {lib_dir}")
            return False

        # Check libraries
        for lib_file in required_libs:
            if not lib_file.exists():
                print(f"[X] Missing library: {lib_file}")
                return False
            print(f"[OK] Found library: {lib_file.name}")

        # On Windows, also check for/generate import libraries
        if system == "Windows":
            print("Windows: Checking import libraries...")
            for lib_name in ["OCTypes", "SITypes", "RMN"]:
                dll_path = lib_dir / f"lib{lib_name}.dll"
                import_lib_path = lib_dir / f"lib{lib_name}.dll.a"

                if import_lib_path.exists():
                    print(f"[OK] Found import library: {import_lib_path.name}")
                elif dll_path.exists():
                    print(
                        f"[!] Missing import library for {lib_name} - will be generated during build"
                    )
                else:
                    print(f"[X] Missing both DLL and import library for {lib_name}")
                    return False

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


def _fallback_windows_linking(lib_dir: Path) -> List[str]:
    """Fallback to individual library linking when bridge DLL fails."""
    windows_libraries = []

    for lib_name in ["OCTypes", "SITypes", "RMN"]:
        dll_a_path = lib_dir / f"lib{lib_name}.dll.a"
        dll_path = lib_dir / f"lib{lib_name}.dll"

        if dll_a_path.exists():
            # Use import library if available
            windows_libraries.append(lib_name)
            print(f"[setup.py] Using existing import library for {lib_name}")
        elif dll_path.exists():
            # Generate import library from DLL using gendef + dlltool
            print(f"[setup.py] Generating import library for {lib_name} from DLL")
            try:
                # Generate .def file from DLL
                def_file = lib_dir / f"lib{lib_name}.def"
                subprocess.run(
                    ["gendef", str(dll_path)],
                    cwd=str(lib_dir),
                    check=True,
                    capture_output=True,
                )

                # Generate import library from .def file
                subprocess.run(
                    [
                        "dlltool",
                        "-d",
                        str(def_file),
                        "-D",
                        str(dll_path),
                        "-l",
                        str(dll_a_path),
                    ],
                    check=True,
                    capture_output=True,
                )

                windows_libraries.append(lib_name)
                print(
                    f"[setup.py] Successfully generated import library for {lib_name}"
                )

            except (subprocess.CalledProcessError, FileNotFoundError) as e:
                print(
                    f"[setup.py] Failed to generate import library for {lib_name}: {e}"
                )
                # Fallback: try direct DLL linking (may work with some MinGW versions)
                windows_libraries.append(str(dll_path.absolute()))
                print(f"[setup.py] Using direct DLL path for {lib_name}: {dll_path}")
        else:
            # Fallback to library name (original behavior)
            windows_libraries.append(lib_name)
            print(f"[setup.py] Using library name fallback for {lib_name}")

    # Add external dependencies required by RMNLib on Windows
    windows_libraries.extend(["curl", "openblas", "lapack"])
    # Add MinGW runtime libraries
    windows_libraries.extend(["gcc_s", "winpthread", "quadmath", "gomp"])

    return windows_libraries


def get_extensions() -> List[Extension]:
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

    # Add platform-specific include directories
    if platform.system() == "Windows":
        # Add OpenBLAS include directory for CBLAS headers on Windows/MinGW
        msystem = os.environ.get("MSYSTEM", "").upper()
        print(f"[setup.py] MSYSTEM environment variable: {msystem}")

        # Try multiple potential OpenBLAS header locations for robustness
        potential_openblas_paths = []
        if msystem == "MINGW64":
            potential_openblas_paths = [
                "/mingw64/include/openblas",
                "D:/a/_temp/msys64/mingw64/include/openblas",
            ]
        elif msystem == "MINGW32":
            potential_openblas_paths = [
                "/mingw32/include/openblas",
                "D:/a/_temp/msys64/mingw32/include/openblas",
            ]
        else:
            # Fallback - try both architectures
            potential_openblas_paths = [
                "/mingw64/include/openblas",
                "/mingw32/include/openblas",
            ]

        for path in potential_openblas_paths:
            if os.path.exists(path):
                print(f"[setup.py] Adding OpenBLAS include path: {path}")
                include_dirs.append(path)
                break
        else:
            print(
                f"[setup.py] Warning: OpenBLAS headers not found in expected locations: {potential_openblas_paths}"
            )

    # Common library directories and libraries
    library_dirs = ["lib"]
    libraries = ["OCTypes", "SITypes", "RMN"]

    # Common compiler/linker options (platform-specific)
    extra_link_args: List[str] = []
    define_macros: List[tuple[str, str]] = [
        ("NPY_NO_DEPRECATED_API", "NPY_1_7_API_VERSION")
    ]

    if platform.system() == "Windows":
        # On Windows, our CustomBuildExt class forces MinGW, so use GCC-style flags
        extra_compile_args = [
            "-std=c99",
            "-Wno-unused-function",
            "-Wno-sign-compare",
            "-DPy_NO_ENABLE_SHARED",  # Help with MinGW Python linking
        ]

        # Windows Bridge DLL Strategy (WindowsPlan.md implementation)
        lib_dir = Path(__file__).parent / "lib"
        bridge_dll_path = lib_dir / "rmnstack_bridge.dll"
        bridge_implib_path = lib_dir / "rmnstack_bridge.dll.a"

        # Check if bridge DLL exists, if not try to create it
        bridge_dll_good = False
        if bridge_implib_path.exists() and bridge_dll_path.exists():
            # Check if import library is suspiciously small (no exports case)
            try:
                if bridge_implib_path.stat().st_size < 4096:
                    print(
                        "[setup.py] Existing bridge import lib is too small; will rebuild"
                    )
                    bridge_implib_path.unlink(missing_ok=True)
                    bridge_dll_path.unlink(missing_ok=True)
                else:
                    print("[setup.py] Using existing bridge DLL for Windows build")
                    # Use only the bridge import library
                    extra_link_args.extend(
                        [
                            "-Wl,--enable-auto-import",
                            "-Wl,--disable-auto-image-base",
                            str(bridge_implib_path.absolute()),
                        ]
                    )
                    # Only external system libraries needed
                    libraries = [
                        "curl",
                        "openblas",
                        "lapack",
                        "gcc_s",
                        "winpthread",
                        "quadmath",
                        "gomp",
                        "m",
                    ]
                    print(
                        f"[setup.py] Bridge DLL linking configured: {bridge_implib_path}"
                    )
                    bridge_dll_good = True
                    # Continue to build extensions with bridge linking
            except Exception as e:
                print(f"[setup.py] Bridge size check warning: {e}")
                # Continue to rebuild if size check fails

        if not bridge_dll_good:
            # If we reach here, we need to create/rebuild the bridge DLL
            print(
                "[setup.py] Bridge DLL not found or needs rebuilding, attempting to create it..."
            )
            # Check if we have the static libraries to create bridge
            static_libs = [
                lib_dir / "libOCTypes.a",
                lib_dir / "libSITypes.a",
                lib_dir / "libRMN.a",
            ]

            if all(lib.exists() for lib in static_libs):
                print("[setup.py] Found static libraries, creating bridge DLL...")
                try:
                    # Create bridge DLL using the same command as in Makefile
                    subprocess.run(
                        [
                            "x86_64-w64-mingw32-gcc",
                            "-shared",
                            "-o",
                            str(bridge_dll_path),
                            "-Wl,--out-implib," + str(bridge_implib_path),
                            "-Wl,--whole-archive",
                            str(lib_dir / "libRMN.a"),
                            str(lib_dir / "libSITypes.a"),
                            str(lib_dir / "libOCTypes.a"),
                            "-Wl,--no-whole-archive",
                            "-Wl,--export-all-symbols",
                            "-lopenblas",
                            "-llapack",
                            "-lcurl",
                            "-lgcc_s",
                            "-lwinpthread",
                            "-lquadmath",
                            "-lgomp",
                            "-lm",
                        ],
                        check=True,
                        capture_output=True,
                        text=True,
                    )

                    print(
                        f"[setup.py] Successfully created bridge DLL: {bridge_dll_path}"
                    )
                    print(
                        f"[setup.py] Successfully created import library: {bridge_implib_path}"
                    )

                    # Verify that the import library has reasonable size (contains exports)
                    try:
                        if (
                            bridge_implib_path.exists()
                            and bridge_implib_path.stat().st_size < 4096
                        ):
                            print(
                                "[setup.py] Bridge import lib is too small; rebuilding with --whole-archive"
                            )
                            bridge_implib_path.unlink(missing_ok=True)
                            bridge_dll_path.unlink(missing_ok=True)
                            # Re-run the same subprocess.run(...) block above
                            subprocess.run(
                                [
                                    "x86_64-w64-mingw32-gcc",
                                    "-shared",
                                    "-o",
                                    str(bridge_dll_path),
                                    "-Wl,--out-implib," + str(bridge_implib_path),
                                    "-Wl,--whole-archive",
                                    str(lib_dir / "libRMN.a"),
                                    str(lib_dir / "libSITypes.a"),
                                    str(lib_dir / "libOCTypes.a"),
                                    "-Wl,--no-whole-archive",
                                    "-Wl,--export-all-symbols",
                                    "-lopenblas",
                                    "-llapack",
                                    "-lcurl",
                                    "-lgcc_s",
                                    "-lwinpthread",
                                    "-lquadmath",
                                    "-lgomp",
                                    "-lm",
                                ],
                                check=True,
                                capture_output=True,
                                text=True,
                            )
                            print("[setup.py] Bridge DLL rebuilt successfully")
                    except Exception as e:
                        print(f"[setup.py] Bridge size check warning: {e}")

                    # Now use the bridge
                    extra_link_args.extend(
                        [
                            "-Wl,--enable-auto-import",
                            "-Wl,--disable-auto-image-base",
                            str(bridge_implib_path.absolute()),
                        ]
                    )
                    libraries = [
                        "curl",
                        "openblas",
                        "lapack",
                        "gcc_s",
                        "winpthread",
                        "quadmath",
                        "gomp",
                        "m",
                    ]

                except subprocess.CalledProcessError as e:
                    print(f"[setup.py] Failed to create bridge DLL: {e}")
                    print(f"[setup.py] stderr: {e.stderr}")
                    print("[setup.py] Falling back to individual library linking...")
                    # Fallback to original behavior
                    libraries = _fallback_windows_linking(lib_dir)
            else:
                missing = [str(lib) for lib in static_libs if not lib.exists()]
                print(f"[setup.py] Missing static libraries: {missing}")
                print("[setup.py] Falling back to individual library linking...")
                libraries = _fallback_windows_linking(lib_dir)

        # Add SIZEOF_VOID_P=8 for x86_64 to prevent Cython's division by zero error
        define_macros.append(("SIZEOF_VOID_P", "8"))
        print("Configured for MinGW/GCC compiler on Windows")
    elif platform.system() == "Darwin":  # macOS
        # macOS-specific configuration
        extra_compile_args = ["-std=c99", "-Wno-unused-function"]

        # Add RPATH for finding shared libraries at runtime
        # Get the absolute path to the lib directory
        lib_dir = Path(__file__).parent / "lib"
        lib_dir_abs = str(lib_dir.absolute())

        # Add runtime library search paths
        extra_link_args.extend(
            [
                f"-Wl,-rpath,{lib_dir_abs}",  # Local lib directory
                "-Wl,-rpath,@loader_path/../../../lib",  # Relative path from extension to lib
                "-Wl,-rpath,@loader_path/../../../../lib",  # Alternative relative path
            ]
        )

        print(f"Configured macOS RPATH for library directory: {lib_dir_abs}")
    else:
        # Linux and other Unix-like systems
        extra_compile_args = ["-std=c99", "-Wno-unused-function"]

        # Add RPATH for Linux as well
        lib_dir = Path(__file__).parent / "lib"
        lib_dir_abs = str(lib_dir.absolute())
        extra_link_args.extend(
            [
                f"-Wl,-rpath,{lib_dir_abs}",  # Local lib directory
                "-Wl,-rpath,$ORIGIN/../../../lib",  # Relative path from extension to lib
            ]
        )

    # Build extensions list
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

    # Phase 2A: SIDimensionality wrapper
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
                define_macros=define_macros,
            )
        ]
    )

    # Phase 2B: SIUnit wrapper
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
                define_macros=define_macros,
            )
        ]
    )

    # Phase 2C: SIScalar wrapper
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
                define_macros=define_macros,
            )
        ]
    )

    # Phase 3A: RMNLib dimension wrapper
    extensions.extend(
        [
            Extension(
                "rmnpy.wrappers.rmnlib.dimension",
                sources=["src/rmnpy/wrappers/rmnlib/dimension.pyx"],
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

    # Phase 3B: RMNLib sparse_sampling wrapper
    extensions.extend(
        [
            Extension(
                "rmnpy.wrappers.rmnlib.sparse_sampling",
                sources=["src/rmnpy/wrappers/rmnlib/sparse_sampling.pyx"],
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

    # Phase 3C: RMNLib dependent_variable wrapper
    extensions.extend(
        [
            Extension(
                "rmnpy.wrappers.rmnlib.dependent_variable",
                sources=["src/rmnpy/wrappers/rmnlib/dependent_variable.pyx"],
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

    # Phase 4: Quantities module (only if quantities.pyx exists)
    quantities_file = Path(__file__).parent / "src" / "rmnpy" / "quantities.pyx"
    if quantities_file.exists():
        extensions.extend(
            [
                Extension(
                    "rmnpy.quantities",
                    sources=["src/rmnpy/quantities.pyx"],
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
    else:
        print(
            f"[WARNING] quantities.pyx not found at {quantities_file} - skipping quantities extension"
        )

    return extensions


# Note: Most project configuration is now in pyproject.toml
# This setup.py only handles the Cython build process

setup(
    # All metadata is now read from pyproject.toml
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
