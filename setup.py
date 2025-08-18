# setup.py — build Cython extensions using system-installed libraries
import sys
from pathlib import Path

from Cython.Build import cythonize
from setuptools import Extension, find_packages, setup

ROOT = Path(__file__).parent.resolve()
SRC = ROOT / "src"
PKG = SRC / "rmnpy"

# Use system include directories for libraries built by cibuildwheel
INC = ["/usr/local/include"]

# Platform-specific include directories
if sys.platform == "win32":
    # MinGW system includes
    INC.extend(
        [
            "C:/msys64/mingw64/include",
            "C:/msys64/mingw64/include/openblas",
        ]
    )
elif sys.platform == "darwin":
    # macOS homebrew includes
    INC.extend(
        [
            "/usr/local/include",
            "/opt/homebrew/include",  # Apple Silicon
            "/usr/local/opt/openblas/include",
            "/opt/homebrew/opt/openblas/include",
        ]
    )

# Numpy include (optional; safe to add)
try:
    import numpy as _np

    INC.append(_np.get_include())
except Exception:
    pass

# Use system-installed libraries built by cibuildwheel
LIBDIRS = ["/usr/local/lib"]
if sys.platform == "win32":
    LIBDIRS = ["C:/msys64/mingw64/lib"]
elif sys.platform == "darwin":
    LIBDIRS.extend(["/usr/local/lib", "/opt/homebrew/lib"])

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
