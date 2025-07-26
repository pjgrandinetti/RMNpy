# dll_loader.py
"""
Windows DLL loader module for RMNpy.
Implements Claude Opus 4's recommendation for pre-loading critical DLLs
and setting up proper DLL search paths.
"""
import os
import shutil
import sys
from pathlib import Path


def setup_dll_paths() -> None:
    """Setup DLL paths for Windows"""
    if sys.platform == "win32":
        # Add DLL directories (including subdirectories for extension modules)
        base_dir = Path(__file__).parent  # Package directory
        dll_dirs = [
            base_dir,
            base_dir / "helpers",  # Helper extensions
            base_dir / "wrappers" / "sitypes",  # SITypes extensions
            base_dir / "wrappers" / "rmnlib",  # RMNLib extensions
            base_dir.parent.parent.parent / "lib",  # lib directory
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

        # Register all dll_dirs: prepend to PATH and add via add_dll_directory
        existing_path = os.environ.get("PATH", "")
        valid_dirs = [d for d in dll_dirs if d.exists()]
        # Prepend to PATH
        os.environ["PATH"] = os.pathsep.join(
            [str(d) for d in valid_dirs] + [existing_path]
        )
        # Register directories for DLL search
        for d in valid_dirs:
            if hasattr(os, "add_dll_directory"):
                try:
                    os.add_dll_directory(str(d))
                except Exception:
                    pass
        # Copy MinGW runtime DLLs adjacent to extension modules for loader adjacency
        runtime_dlls = [
            "libwinpthread-1.dll",
            "libgcc_s_seh-1.dll",
            "libstdc++-6.dll",
            "libgomp-1.dll",
            "libquadmath-0.dll",
            "libgfortran-5.dll",
            "libopenblas.dll",
            "liblapack.dll",
            "libcurl-4.dll",
        ]
        # Extension directories including package root
        ext_dirs = [
            base_dir,
            base_dir / "wrappers" / "sitypes",
            base_dir / "wrappers" / "rmnlib",
        ]
        for dll_name in runtime_dlls:
            for ext_dir in ext_dirs:
                try:
                    ext_dir.mkdir(parents=True, exist_ok=True)
                except Exception:
                    continue
                dst = ext_dir / dll_name
                if dst.exists():
                    continue
                for src_dir in valid_dirs:
                    src = Path(src_dir) / dll_name
                    if src.exists():
                        try:
                            shutil.copy2(str(src), str(dst))
                        except Exception:
                            pass
                        break


def preload_mingw_runtime() -> None:
    """Register MinGW runtime directories for Windows DLL loader without loading DLLs explicitly"""
    if sys.platform == "win32":
        base_dir = Path(__file__).parent
        # Directories where runtime DLLs reside
        runtime_dirs = [
            base_dir,
            base_dir / "wrappers" / "sitypes",
            Path(r"D:\a\_temp\msys64\mingw64\bin"),
            Path(r"C:\msys64\mingw64\bin"),
        ]
        # Prepend directories to PATH and register via add_dll_directory
        for d in runtime_dirs:
            if d.exists():
                try:
                    os.environ["PATH"] = (
                        str(d) + os.pathsep + os.environ.get("PATH", "")
                    )
                    if hasattr(os, "add_dll_directory"):
                        os.add_dll_directory(str(d))
                except Exception:
                    pass
