# dll_loader.py
"""
Windows DLL loader for RMNpy.

Goals for wheels and editable installs on Windows (Py>=3.11):
- Prefer bundled native libs in rmnpy/_libs/
- Fall back to project-root ./lib/ during local dev
- Avoid PATH pollution; use os.add_dll_directory
- Be quiet by default; opt-in logs via RMNPY_DLL_LOG=1 (or DEBUG with RMNPY_DLL_DEBUG=1)
- Optionally load a bridge DLL if present (rmnstack_bridge.dll)
"""

from __future__ import annotations

import logging
import os
import sys
from pathlib import Path
from typing import List

# -----------------------------------------------------------------------------
# Logging (opt-in)
# -----------------------------------------------------------------------------
_log_level = (
    logging.DEBUG
    if os.environ.get("RMNPY_DLL_DEBUG")
    else (logging.INFO if os.environ.get("RMNPY_DLL_LOG") else logging.WARNING)
)
_logger = logging.getLogger(__name__)
if not _logger.handlers:
    _h = logging.StreamHandler(sys.stderr)
    _h.setFormatter(logging.Formatter("[%(asctime)s] DLL_LOADER: %(message)s"))
    _logger.addHandler(_h)
_logger.setLevel(_log_level)

# -----------------------------------------------------------------------------
# State
# -----------------------------------------------------------------------------
_dll_setup_completed = False
_dll_dir_cookies: List[object] = []  # keep cookies alive for the process


# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
def _env_true(name: str) -> bool:
    v = os.environ.get(name, "")
    return v.lower() in {"1", "true", "yes", "on"}


def _existing_dirs(paths: List[Path]) -> List[Path]:
    seen = set()
    out: List[Path] = []
    for p in paths:
        p = p.resolve()
        if p.exists() and p.is_dir() and p not in seen:
            out.append(p)
            seen.add(p)
    return out


def _register_dirs(dirs: List[Path]) -> int:
    count = 0
    for d in dirs:
        try:
            if hasattr(os, "add_dll_directory"):
                cookie = os.add_dll_directory(str(d))
                _dll_dir_cookies.append(cookie)  # keep alive
                count += 1
                _logger.info(f"Registered DLL directory: {d}")
        except Exception as e:  # pragma: no cover
            _logger.warning(f"Failed to register {d}: {e}")
    return count


def _set_safe_search_mode() -> None:
    # Win 8+ only; safe if it fails.
    try:
        import ctypes

        if hasattr(ctypes, "windll"):
            kernel32 = ctypes.windll.kernel32
            LOAD_LIBRARY_SEARCH_DEFAULT_DIRS = 0x00001000
            kernel32.SetDefaultDllDirectories(LOAD_LIBRARY_SEARCH_DEFAULT_DIRS)
            _logger.info("Enabled Windows safe DLL search mode")
    except Exception as e:  # pragma: no cover
        _logger.debug(f"SetDefaultDllDirectories not applied: {e}")


def _maybe_load_bridge(base_dirs: List[Path]) -> None:
    # Optional, non-fatal: load rmnstack_bridge.dll if present.
    bridge = "rmnstack_bridge.dll"
    for d in base_dirs:
        p = d / bridge
        if p.exists():
            try:
                import ctypes

                ctypes.CDLL(str(p))
                _logger.info(f"Loaded bridge DLL: {p}")
                return
            except Exception as e:  # pragma: no cover
                _logger.warning(f"Bridge DLL found but failed to load ({p}): {e}")
    _logger.debug("Bridge DLL not found; continuing without it")


# -----------------------------------------------------------------------------
# Public API
# -----------------------------------------------------------------------------
def setup_dll_paths() -> None:
    """One-time Windows DLL path setup. Safe to call multiple times."""
    global _dll_setup_completed
    if _dll_setup_completed:
        _logger.debug("DLL setup already completed; skipping")
        return

    if sys.platform != "win32":
        _logger.debug("Non-Windows platform; no DLL setup required")
        _dll_setup_completed = True
        return

    _logger.info("Starting Windows DLL setup for RMNpy")
    _set_safe_search_mode()

    # Package layout
    pkg_dir = Path(__file__).resolve().parent  # .../rmnpy
    repo_root = pkg_dir.parent.parent  # project root (editable)
    # Preferred: bundled libs inside the wheel
    libs_dir = pkg_dir / "_libs"
    # Fallback for editable/developer layout:
    dev_libs_dir = repo_root / "lib"

    # User-provided extra directories (e.g., MSYS2 mingw64/bin)
    # Accept pathsep-separated list (;) on Windows
    extra_env = os.environ.get("RMNPY_DLL_DIRS", "")
    extra_dirs = [Path(p.strip()) for p in extra_env.split(os.pathsep) if p.strip()]

    # We also register the package dir itself so extensions can be found cleanly.
    candidate_dirs: List[Path] = [
        libs_dir,
        dev_libs_dir,
        pkg_dir,  # package folder (sometimes contains *.pyd and local dlls)
        # submodules/extensions that may sit near their dependent dlls in editable mode
        pkg_dir / "wrappers" / "sitypes",
        pkg_dir / "wrappers" / "rmnlib",
    ] + extra_dirs

    dirs = _existing_dirs(candidate_dirs)
    _logger.info(f"DLL search dirs: {[str(d) for d in dirs]}")

    registered = _register_dirs(dirs)
    _logger.info(f"Registered {registered} DLL directories")

    # Optional: load the bridge DLL if present
    _maybe_load_bridge(dirs)

    # Optional: explicitly load Python runtime DLL (rarely necessary on 3.11+)
    if _env_true("RMNPY_LOAD_PY_DLL"):
        try:
            import ctypes

            name = f"python{sys.version_info.major}{sys.version_info.minor}.dll"
            cand = [Path(sys.base_prefix) / name, Path(sys.base_prefix) / "python3.dll"]
            for p in cand:
                if p.exists() and hasattr(ctypes, "WinDLL"):
                    ctypes.WinDLL(str(p))
                    _logger.info(f"Loaded Python runtime DLL: {p}")
                    break
        except Exception as e:  # pragma: no cover
            _logger.debug(f"Could not load Python DLL explicitly: {e}")

    _dll_setup_completed = True
    _logger.info("Windows DLL setup completed")


def preload_mingw_runtime() -> None:
    """
    Back-compat no-op helper.
    Keep for callers that previously invoked it; directories are handled by setup_dll_paths().
    """
    setup_dll_paths()
