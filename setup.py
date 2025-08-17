# setup.py — build Cython extensions and bundle shared libs from ./lib into rmnpy/_libs
import glob
import shutil
import sys
from pathlib import Path

from Cython.Build import cythonize
from setuptools import Extension, find_packages, setup
from setuptools.command.build_ext import build_ext as _build_ext

ROOT = Path(__file__).parent.resolve()
SRC = ROOT / "src"
PKG = SRC / "rmnpy"

# Headers staged by your Makefile (make synclib / update-deps)
INC = [
    str(ROOT / "include"),
    str(ROOT / "include" / "OCTypes"),
    str(ROOT / "include" / "SITypes"),
    str(ROOT / "include" / "RMNLib"),
]

# Numpy include (optional; safe to add)
try:
    import numpy as _np

    INC.append(_np.get_include())
except Exception:
    pass

# Link against all three libraries in dependency order
LIBDIRS = [str(ROOT / "lib")]
if sys.platform == "win32":
    # Windows/MINGW: Use explicit static library linking to avoid DLL/import library issues
    # Specify full paths to static libraries to ensure proper symbol resolution
    lib_dir = ROOT / "lib"
    EXTRA_LINK_LIBS = [
        str(lib_dir / "libOCTypes.a"),  # Base library, no dependencies
        str(lib_dir / "libSITypes.a"),  # Depends on OCTypes
        str(lib_dir / "libRMN.a"),  # Depends on both SITypes and OCTypes
    ]
    LIBS = []  # Don't use -l flags, use direct file paths instead
else:
    # On Unix-like systems, RMN should pull in its dependencies
    LIBS = ["RMN"]
    EXTRA_LINK_LIBS = []

# rpath so extensions find bundled libs at runtime
if sys.platform == "darwin":
    EXTRA_LINK = ["-Wl,-rpath,@loader_path/_libs", f"-Wl,-rpath,{ROOT / 'lib'}"]
elif sys.platform.startswith("linux"):
    EXTRA_LINK = ["-Wl,-rpath,$ORIGIN/_libs", f"-Wl,-rpath,{ROOT / 'lib'}"]
else:
    # Windows: Add static library files directly to linker command
    EXTRA_LINK = EXTRA_LINK_LIBS

EXTRA_COMPILE = []
if sys.platform == "win32":
    # MinGW recommended (C99/VLA/complex.h); users will build wheels in CI
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


class build_ext(_build_ext):
    """After building extensions, copy shared libs from ./lib into wheel under rmnpy/_libs."""

    def run(self):
        super().run()
        self._copy_shared_libs()

    def _copy_shared_libs(self):
        src_lib = ROOT / "lib"
        if not src_lib.is_dir():
            return
        patterns = ["*.so", "*.so.*", "*.dylib", "*.dll"]
        files = []
        for pat in patterns:
            files.extend(glob.glob(str(src_lib / pat)))
        if not files:
            return

        # For editable installs, copy to package directory too
        pkg_dir = PKG / "_libs"
        pkg_dir.mkdir(parents=True, exist_ok=True)
        for f in files:
            shutil.copy2(f, pkg_dir)

        # For wheel builds, copy to build lib
        if hasattr(self, "build_lib") and self.build_lib:
            out_pkg = Path(self.build_lib) / "rmnpy" / "_libs"
            out_pkg.mkdir(parents=True, exist_ok=True)
            for f in files:
                shutil.copy2(f, out_pkg)


setup(
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    include_package_data=True,  # picks up rmnpy/_libs/* via MANIFEST.in or package-data
    ext_modules=cythonize(
        exts,
        language_level=3,
        annotate=False,
        compiler_directives=dict(
            boundscheck=False, wraparound=False, initializedcheck=False
        ),
    ),
    cmdclass={"build_ext": build_ext},
)
