# setup.py — build Cython extensions with flexible library detection
import os
import sys
from pathlib import Path

# Force MinGW compiler on Windows for cibuildwheel builds
# This is required because our C code uses C99 VLA and complex.h which MSVC doesn't support
if sys.platform == "win32" and os.environ.get("CIBUILDWHEEL"):
    # Set environment variables to ensure MinGW is used consistently
    os.environ["CC"] = "C:/msys64/mingw64/bin/gcc.exe"
    os.environ["CXX"] = "C:/msys64/mingw64/bin/g++.exe"
    os.environ["DISTUTILS_USE_SDK"] = "1"
    os.environ["MSSdk"] = "1"

    # Also try to override distutils compiler selection
    try:
        from distutils import ccompiler

        # Override the default compiler detection to force MinGW
        def get_default_compiler(plat=None):
            return "mingw32"

        ccompiler.get_default_compiler = get_default_compiler
    except ImportError:
        pass

from Cython.Build import cythonize
from setuptools import Extension, find_packages, setup
from setuptools.command.build_ext import build_ext


# Custom build class to force MinGW on Windows during cibuildwheel builds
class CustomBuildExt(build_ext):
    def build_extensions(self):
        # Force MinGW compiler on Windows for cibuildwheel builds
        # This is required because our C code uses C99 VLA and complex.h which MSVC doesn't support
        if sys.platform == "win32" and os.environ.get("CIBUILDWHEEL"):
            # Override compiler to use MinGW
            if self.compiler.compiler_type == "msvc":
                print(
                    "WARNING: MSVC compiler detected, attempting to switch to MinGW..."
                )
                # Try to force MinGW compiler
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
                    print(f"Failed to switch to MinGW: {e}")
                    raise

        super().build_extensions()


ROOT = Path(__file__).parent.resolve()
SRC = ROOT / "src"
PKG = SRC / "rmnpy"

# Detect whether we're using local libraries or system-installed libraries
local_include = ROOT / "include"
local_lib = ROOT / "lib"

if local_include.exists() and local_lib.exists():
    # Local development mode - use libraries in ./lib and ./include
    print("Using local libraries from ./lib and ./include")
    INC = [
        str(local_include),
        str(local_include / "OCTypes"),
        str(local_include / "SITypes"),
        str(local_include / "RMNLib"),
    ]
    LIBDIRS = [str(local_lib)]

    # Platform-specific local setup
    if sys.platform == "win32":
        import os

        # Try to find MSYS2 environment
        msys2_base = os.environ.get("MSYSTEM_PREFIX")
        if not msys2_base:
            # Common MSYS2 installation paths
            for candidate in ["D:/a/_temp/msys64/mingw64", "C:/msys64/mingw64"]:
                if Path(candidate).exists():
                    msys2_base = candidate
                    break

        if msys2_base:
            print(f"Found MSYS2 environment at: {msys2_base}")
            INC.extend(
                [
                    f"{msys2_base}/include",
                    f"{msys2_base}/include/openblas",
                ]
            )
            LIBDIRS.append(f"{msys2_base}/lib")
else:
    # cibuildwheel mode - use system-installed libraries
    print("Using system-installed libraries")

    # Check for cibuildwheel installation directory first
    cibw_install = Path("/tmp/install")
    if cibw_install.exists():
        print("Found cibuildwheel installation at /tmp/install")
        INC = [
            str(cibw_install / "include"),
            str(cibw_install / "include" / "OCTypes"),
            str(cibw_install / "include" / "SITypes"),
            str(cibw_install / "include" / "RMNLib"),
        ]
        LIBDIRS = [str(cibw_install / "lib")]
    else:
        INC = ["/usr/local/include"]
        LIBDIRS = ["/usr/local/lib"]

    # Platform-specific system setup
    if sys.platform == "win32":
        INC.extend(
            [
                "C:/msys64/mingw64/include",
                "C:/msys64/mingw64/include/openblas",
            ]
        )
        if not cibw_install.exists():
            LIBDIRS = ["C:/msys64/mingw64/lib"]
    elif sys.platform == "darwin":
        INC.extend(
            [
                "/usr/local/include",
                "/opt/homebrew/include",  # Apple Silicon
                "/usr/local/opt/openblas/include",
                "/opt/homebrew/opt/openblas/include",
            ]
        )
        if not cibw_install.exists():
            LIBDIRS.extend(["/usr/local/lib", "/opt/homebrew/lib"])

# Numpy include (optional; safe to add)
try:
    import numpy as _np

    INC.append(_np.get_include())
except Exception:
    pass

# Link against the libraries in dependency order
if sys.platform == "win32":
    # Windows: explicitly link against import libraries using -l:filename syntax
    # This ensures proper symbol resolution for shared libraries
    LIBS = [":libRMN.dll.a", ":libSITypes.dll.a", ":libOCTypes.dll.a"]
else:
    # Unix-like systems: standard library naming
    LIBS = ["RMN", "SITypes", "OCTypes"]

# Platform-specific linking
EXTRA_LINK = []
if sys.platform == "darwin":
    # macOS: use rpath for bundled libraries
    EXTRA_LINK = ["-Wl,-rpath,@loader_path/_libs"]
elif sys.platform.startswith("linux"):
    # Linux: use rpath for bundled libraries
    EXTRA_LINK = ["-Wl,-rpath,$ORIGIN/_libs"]
elif sys.platform == "win32":
    # Windows: Need to use shared libraries to maintain TypeID consistency
    # Static libraries cause TypeID conflicts between Cython modules
    # Add auto-import flag to work with MinGW auto-export DLLs
    EXTRA_LINK = ["-Wl,--enable-auto-import"]
# Otherwise delvewheel will handle DLL bundling

EXTRA_COMPILE = []
if sys.platform == "win32":
    EXTRA_COMPILE = ["-std=gnu99"]
else:
    EXTRA_COMPILE = ["-std=c99"]

exts = [
    # SITypes wrappers
    Extension(
        "rmnpy.wrappers.sitypes.dimensionality",
        ["src/rmnpy/wrappers/sitypes/dimensionality.pyx"],
        include_dirs=INC,
        libraries=LIBS,
        library_dirs=LIBDIRS,
        extra_compile_args=EXTRA_COMPILE,
        extra_link_args=EXTRA_LINK,
    ),
    Extension(
        "rmnpy.wrappers.sitypes.scalar",
        ["src/rmnpy/wrappers/sitypes/scalar.pyx"],
        include_dirs=INC,
        libraries=LIBS,
        library_dirs=LIBDIRS,
        extra_compile_args=EXTRA_COMPILE,
        extra_link_args=EXTRA_LINK,
    ),
    Extension(
        "rmnpy.wrappers.sitypes.unit",
        ["src/rmnpy/wrappers/sitypes/unit.pyx"],
        include_dirs=INC,
        libraries=LIBS,
        library_dirs=LIBDIRS,
        extra_compile_args=EXTRA_COMPILE,
        extra_link_args=EXTRA_LINK,
    ),
    # RMNLib wrappers
    Extension(
        "rmnpy.wrappers.rmnlib.dependent_variable",
        ["src/rmnpy/wrappers/rmnlib/dependent_variable.pyx"],
        include_dirs=INC,
        libraries=LIBS,
        library_dirs=LIBDIRS,
        extra_compile_args=EXTRA_COMPILE,
        extra_link_args=EXTRA_LINK,
    ),
    Extension(
        "rmnpy.wrappers.rmnlib.dimension",
        ["src/rmnpy/wrappers/rmnlib/dimension.pyx"],
        include_dirs=INC,
        libraries=LIBS,
        library_dirs=LIBDIRS,
        extra_compile_args=EXTRA_COMPILE,
        extra_link_args=EXTRA_LINK,
    ),
    Extension(
        "rmnpy.wrappers.rmnlib.sparse_sampling",
        ["src/rmnpy/wrappers/rmnlib/sparse_sampling.pyx"],
        include_dirs=INC,
        libraries=LIBS,
        library_dirs=LIBDIRS,
        extra_compile_args=EXTRA_COMPILE,
        extra_link_args=EXTRA_LINK,
    ),
    # Helpers / quantities
    Extension(
        "rmnpy.helpers.octypes",
        ["src/rmnpy/helpers/octypes.pyx"],
        include_dirs=INC,
        libraries=LIBS,
        library_dirs=LIBDIRS,
        extra_compile_args=EXTRA_COMPILE,
        extra_link_args=EXTRA_LINK,
    ),
    Extension(
        "rmnpy.quantities",
        ["src/rmnpy/quantities.pyx"],
        include_dirs=INC,
        libraries=LIBS,
        library_dirs=LIBDIRS,
        extra_compile_args=EXTRA_COMPILE,
        extra_link_args=EXTRA_LINK,
    ),
]


# No custom build_ext needed for normal builds - cibuildwheel handles library bundling
setup(
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    include_package_data=True,
    cmdclass={"build_ext": CustomBuildExt},
    ext_modules=cythonize(
        exts,
        language_level=3,
        annotate=False,
        compiler_directives=dict(
            boundscheck=False, wraparound=False, initializedcheck=False
        ),
    ),
)
