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

        # Determine valid directories
        existing_path = os.environ.get("PATH", "")
        valid_dirs = [d for d in dll_dirs if d.exists()]
        # Prepend only Python installation and MinGW bin dirs to PATH
        path_dirs = []
        # Python base and DLL dirs
        py_base = Path(sys.base_prefix)
        if py_base.exists():
            path_dirs.append(py_base)
            path_dirs.append(py_base / "DLLs")
        # Virtual environment exec_prefix if different
        if hasattr(sys, "exec_prefix") and sys.exec_prefix != sys.base_prefix:
            py_exec = Path(sys.exec_prefix)
            if py_exec.exists():
                path_dirs.append(py_exec)
                path_dirs.append(py_exec / "DLLs")
        # MinGW bin if present
        for d in valid_dirs:
            if "msys64" in str(d).lower() and d.is_dir():
                path_dirs.append(d)
        # Apply new PATH
        os.environ["PATH"] = os.pathsep.join(
            [str(d) for d in path_dirs] + [existing_path]
        )
        # Register all valid dirs for DLL search
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
        # Copy MinGW runtime DLLs adjacent to extension modules for loader adjacency
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
        # Remove any python*.dll in extension directories to avoid loading mismatched Python DLL
        for ext_dir in ext_dirs:
            try:
                for py_dll in Path(ext_dir).glob("python*.dll"):
                    py_dll.unlink()
            except Exception:
                pass
        # Explicitly load Python runtime DLL globally to resolve extension module symbols
        try:
            import ctypes

            # Determine Python DLL path
            dll_name = f"python{sys.version_info.major}{sys.version_info.minor}.dll"
            py_dll = Path(sys.base_prefix) / dll_name
            if not py_dll.exists():
                # fallback to generic python3.dll
                py_dll = Path(sys.base_prefix) / "python3.dll"
            if py_dll.exists():
                ctypes.CDLL(str(py_dll))
        except Exception:
            pass


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
        # Register runtime dirs for DLL search without modifying PATH
        for d in runtime_dirs:
            if d.exists() and hasattr(os, "add_dll_directory"):
                try:
                    os.add_dll_directory(str(d))
                except Exception:
                    pass
