# dll_loader.py
"""
Windows DLL loader module for RMNpy.
Implements Claude Opus 4's recommendation for pre-loading critical DLLs
and setting up proper DLL search paths.
"""
import ctypes
import os
import sys
from pathlib import Path


def setup_dll_paths() -> None:
    """Setup DLL paths for Windows"""
    if sys.platform == "win32":
        # Add DLL directories
        dll_dirs = [
            Path(__file__).parent,  # Package directory
            Path(__file__).parent.parent.parent / "lib",  # lib directory
            Path(r"D:\a\_temp\msys64\mingw64\bin"),  # MinGW bin (CI environment)
        ]
        # Add Python installation directories for runtime DLL resolution
        # Always include host Python base installation directories
        dll_dirs.append(Path(sys.base_prefix))
        dll_dirs.append(Path(sys.base_prefix) / "DLLs")
        # Also include venv exec_prefix if different from base_prefix
        if hasattr(sys, "exec_prefix") and sys.exec_prefix != sys.base_prefix:
            dll_dirs.append(Path(sys.exec_prefix))
            dll_dirs.append(Path(sys.exec_prefix) / "DLLs")

        # Also try common MinGW installation paths
        common_mingw_paths = [
            Path(r"C:\msys64\mingw64\bin"),
            Path(r"C:\MinGW\bin"),
            Path(r"C:\mingw64\bin"),
        ]
        dll_dirs.extend(common_mingw_paths)

        for dll_dir in dll_dirs:
            if dll_dir.exists() and hasattr(os, "add_dll_directory"):
                try:
                    os.add_dll_directory(str(dll_dir))
                except Exception:
                    # Ignore errors if directory can't be added
                    pass

        # Pre-load critical MinGW DLLs (include C++ and OpenMP runtimes)
        critical_dlls = [
            "libwinpthread-1.dll",
            "libgcc_s_seh-1.dll",
            "libstdc++-6.dll",
            "libgomp-1.dll",
            "libquadmath-0.dll",
            "libgfortran-5.dll",
        ]
        for dll_name in critical_dlls:
            for dll_dir in dll_dirs:
                dll_path = dll_dir / dll_name
                if dll_path.exists():
                    try:
                        ctypes.CDLL(str(dll_path))
                        break
                    except Exception:
                        pass


def preload_mingw_runtime() -> None:
    """Pre-load MinGW runtime libraries in the correct order"""
    if sys.platform == "win32":
        # Order matters for dependency loading
        runtime_dlls = [
            "libwinpthread-1.dll",
            "libgcc_s_seh-1.dll",
            "libstdc++-6.dll",
            "libgomp-1.dll",
            "libquadmath-0.dll",  # Sometimes needed for Fortran libraries
            "libgfortran-5.dll",  # Fortran runtime
        ]

        # Search paths
        search_paths = [
            Path(__file__).parent,
            Path(__file__).parent.parent.parent / "lib",
            Path(r"D:\a\_temp\msys64\mingw64\bin"),
            Path(r"C:\msys64\mingw64\bin"),
        ]

        for dll_name in runtime_dlls:
            for search_path in search_paths:
                dll_path = search_path / dll_name
                if dll_path.exists():
                    try:
                        ctypes.CDLL(str(dll_path))
                        break
                    except Exception:
                        continue


# Call this before any imports
if __name__ != "__main__":
    setup_dll_paths()
    preload_mingw_runtime()
