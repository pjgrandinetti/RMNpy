# setup.py — build Cython extensions with flexible library detection
import os
import sys
from pathlib import Path

from setuptools import Extension, find_packages, setup

# Note: Windows support provided via WSL2 - use Linux wheels

# Skip building C extensions for documentation builds
SKIP_CYTHON = os.environ.get("READTHEDOCS") == "True" or "--help" in sys.argv

if not SKIP_CYTHON:
    from Cython.Build import cythonize

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
    if sys.platform == "darwin":
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

# Use C99 standard for all platforms
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
        "rmnpy.wrappers.rmnlib.dataset",
        ["src/rmnpy/wrappers/rmnlib/dataset.pyx"],
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
    Extension(
        "rmnpy.wrappers.rmnlib.datum",
        ["src/rmnpy/wrappers/rmnlib/datum.pyx"],
        include_dirs=INC,
        libraries=LIBS,
        library_dirs=LIBDIRS,
        extra_compile_args=EXTRA_COMPILE,
        extra_link_args=EXTRA_LINK,
    ),
    Extension(
        "rmnpy.wrappers.rmnlib.geographic_coordinate",
        ["src/rmnpy/wrappers/rmnlib/geographic_coordinate.pyx"],
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
        "rmnpy.sitypes.quantity",
        ["src/rmnpy/sitypes/quantity.pyx"],
        include_dirs=INC,
        libraries=LIBS,
        library_dirs=LIBDIRS,
        extra_compile_args=EXTRA_COMPILE,
        extra_link_args=EXTRA_LINK,
    ),
]


# Standard setup - cibuildwheel handles library bundling
if SKIP_CYTHON:
    print("Skipping Cython extensions for documentation build")
    setup(
        packages=find_packages(where="src"),
        package_dir={"": "src"},
        include_package_data=True,
    )
else:
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
