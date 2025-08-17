"""
RMNpy: Python bindings for OCTypes, SITypes, and RMNLib.

This package provides:
- helpers: Internal conversion utilities for OCTypes
- wrappers: High-level Python interfaces for SITypes and RMNLib
- rmnlib: Convenient access to RMNLib classes (DependentVariable, Dimensions, etc.)
- sitypes: Convenient access to SITypes classes (Unit, Dimensionality, Scalar)
- quantities: SI quantity name constants
"""

from __future__ import annotations

import ctypes
import os
import sys
from pathlib import Path

# -------------------------------
# Shared libraries bootstrap
# -------------------------------
_pkg_dir = Path(__file__).parent
_candidate_dirs = [
    _pkg_dir / "_libs",  # preferred location inside the wheel
    _pkg_dir,  # fallback: libs dropped next to package
    _pkg_dir.parent.parent / "lib",  # fallback: project-root/lib during dev
]


def _existing_dirs() -> list[Path]:
    seen = set()
    out = []
    for d in _candidate_dirs:
        p = d.resolve()
        if p.exists() and p.is_dir() and p not in seen:
            out.append(p)
            seen.add(p)
    return out


if sys.platform == "win32":
    # Centralized Windows handling (PATH, add_dll_directory, bridge DLL, runtimes)
    try:
        from .dll_loader import setup_dll_paths

        setup_dll_paths()
    except Exception as e:
        # Keep import working even if optional loader setup fails
        sys.stderr.write(f"[RMNpy] dll_loader setup failed: {e}\n")
else:
    # Preload libs on Linux/macOS so that Cython extensions can resolve symbols
    lib_ext = ".so" if sys.platform.startswith("linux") else ".dylib"
    lib_names = [f"libOCTypes{lib_ext}", f"libSITypes{lib_ext}", f"libRMN{lib_ext}"]

    loaded_any = False
    for d in _existing_dirs():
        for name in lib_names:
            p = d / name
            if p.exists():
                try:
                    # RTLD_GLOBAL makes symbols visible to subsequently loaded modules
                    ctypes.CDLL(str(p), mode=ctypes.RTLD_GLOBAL)
                    loaded_any = True
                except OSError:
                    # Continue; the next dir may have a working copy
                    pass

    # On Linux, optionally add the first valid dir to LD_LIBRARY_PATH for subprocesses
    if sys.platform.startswith("linux"):
        dirs = _existing_dirs()
        if dirs:
            current = os.environ.get("LD_LIBRARY_PATH", "")
            if str(dirs[0]) not in current.split(os.pathsep):
                os.environ["LD_LIBRARY_PATH"] = (
                    f"{dirs[0]}{os.pathsep}{current}" if current else str(dirs[0])
                )

# -------------------------------
# Package metadata
# -------------------------------
try:
    import importlib.metadata as _im

    __version__ = _im.version("rmnpy")
except Exception:
    __version__ = "unknown"

__author__ = "Philip Grandinetti"
__email__ = "grandinetti.1@osu.edu"

# -------------------------------
# Public API imports
# -------------------------------
from . import rmnlib, sitypes  # noqa: E402
from .rmnlib import DependentVariable  # noqa: E402

# Optional helpers (graceful fallback in editable/dev installs)
try:
    from .colab_fix import colab_install_fix, quick_fix  # noqa: E402
except Exception:  # pragma: no cover

    def colab_install_fix() -> bool:
        print("Colab fix utility not available in this installation")
        return False

    def quick_fix() -> bool:
        print("Quick fix utility not available in this installation")
        return False


# Optional compiled quantities module
try:
    from . import quantities  # noqa: F401,E402
except Exception:
    pass
