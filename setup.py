# setup.py — build Cython extensions with flexible library detection
import sys
from pathlib import Path

from Cython.Build import cythonize
from setuptools import Extension, find_packages, setup

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

        msys2_base = os.environ.get("MSYSTEM_PREFIX")
        if msys2_base:
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
        LIBDIRS.extend(["/usr/local/lib", "/opt/homebrew/lib"])

# Numpy include (optional; safe to add)
try:
    import numpy as _np

    INC.append(_np.get_include())
except Exception:
    pass

# Link against the libraries in dependency order
LIBS = ["RMN", "SITypes", "OCTypes"]

# Platform-specific linking
EXTRA_LINK = []
if sys.platform == "darwin":
    # macOS: use rpath for bundled libraries
    EXTRA_LINK = ["-Wl,-rpath,@loader_path/_libs"]
elif sys.platform.startswith("linux"):
    # Linux: use rpath for bundled libraries
    EXTRA_LINK = ["-Wl,-rpath,$ORIGIN/_libs"]
# Windows: delvewheel will handle DLL bundling

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


# No custom build_ext needed - cibuildwheel handles library bundling
setup(
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    include_package_data=True,
    ext_modules=cythonize(
        exts,
        language_level=3,
        annotate=False,
        compiler_directives=dict(
            boundscheck=False, wraparound=False, initializedcheck=False
        ),
    ),
)
