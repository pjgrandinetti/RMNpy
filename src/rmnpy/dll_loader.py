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

        # Copy Python DLLs into each extension directory so implicit loader can find them
        # Locate source python DLL in host install or exec prefix
        python3_name = "python3.dll"
        versioned_name = f"python{sys.version_info.major}{sys.version_info.minor}.dll"
        src_dll_dirs = [
            Path(sys.executable).parent,
            Path(sys.base_prefix),
            Path(getattr(sys, "exec_prefix", sys.base_prefix)),
        ]
        python_src = None
        for loc in src_dll_dirs:
            candidate = loc / python3_name
            if candidate.exists():
                python_src = candidate
                break
        # Copy to each relevant directory
        if python_src:
            ext_dirs = [
                base_dir,
                base_dir / "helpers",
                base_dir / "wrappers" / "sitypes",
                base_dir / "wrappers" / "rmnlib",
            ]
            for d in ext_dirs:
                try:
                    d.mkdir(parents=True, exist_ok=True)
                    dst = d / python3_name
                    if not dst.exists():
                        shutil.copy2(str(python_src), str(dst))
                    # also copy versioned name
                    src_ver = loc / versioned_name
                    if src_ver.exists():
                        dst_ver = d / versioned_name
                        if not dst_ver.exists():
                            shutil.copy2(str(src_ver), str(dst_ver))
                except Exception:
                    pass
        # Also try common MinGW installation paths
        common_mingw_paths = [
            Path(r"C:\msys64\mingw64\bin"),
            Path(r"C:\MinGW\bin"),
            Path(r"C:\mingw64\bin"),
        ]
        dll_dirs.extend(common_mingw_paths)

        # Prepend all existing dll_dirs to PATH for Windows DLL loader
        existing_path = os.environ.get("PATH", "")
        new_paths = [str(d) for d in dll_dirs if d.exists()]
        os.environ["PATH"] = os.pathsep.join(new_paths + [existing_path])

        # Ensure pythonXY.dll (e.g., python312.dll) exists in package dir by copying generic python3.dll
        # Ensure versioned python DLL (e.g., python312.dll) exists in package dir
        python_versioned_name = (
            f"python{sys.version_info.major}{sys.version_info.minor}.dll"
        )
        python_versioned = base_dir / python_versioned_name
        if not python_versioned.exists():
            # look for versioned python DLL alongside python executable or in install prefixes
            src_locations = [
                Path(sys.executable).parent,
                Path(sys.base_prefix),
                Path(getattr(sys, "exec_prefix", sys.base_prefix)),
            ]
            for loc in src_locations:
                candidate = loc / python_versioned_name
                if candidate.exists():
                    try:
                        shutil.copy2(str(candidate), str(python_versioned))
                    except Exception:
                        pass
                    break

        # Copy MinGW runtime and Python DLLs into package directory for direct loading
        dll_names = [
            "libwinpthread-1.dll",
            "libgcc_s_seh-1.dll",
            "libstdc++-6.dll",
            "libgomp-1.dll",
            "libquadmath-0.dll",
            "libgfortran-5.dll",
            "libopenblas.dll",
            "liblapack.dll",
            "libcurl-4.dll",
            "python3.dll",
            python_versioned_name,
        ]
        # Copy each DLL into main package directory
        for dll_name in dll_names:
            dst_path = base_dir / dll_name
            if dst_path.exists():
                continue
            for dll_dir in dll_dirs:
                src_path = dll_dir / dll_name
                if src_path.exists():
                    try:
                        shutil.copy2(str(src_path), str(dst_path))
                    except Exception:
                        pass
                    break
        # Also copy DLLs into each extension subdirectory for loader adjacency
        ext_dirs = [
            base_dir / "helpers",
            base_dir / "wrappers" / "sitypes",
            base_dir / "wrappers" / "rmnlib",
        ]
        for ext_dir in ext_dirs:
            if not ext_dir.exists():
                continue
            for dll_name in dll_names:
                dst_ext = ext_dir / dll_name
                if dst_ext.exists():
                    continue
                for dll_dir in dll_dirs:
                    src_ext = dll_dir / dll_name
                    if src_ext.exists():
                        try:
                            shutil.copy2(str(src_ext), str(dst_ext))
                        except Exception:
                            pass
                        break

        for dll_dir in dll_dirs:
            if dll_dir.exists() and hasattr(os, "add_dll_directory"):
                try:
                    os.add_dll_directory(str(dll_dir))
                except Exception:
                    # Ignore errors if directory can't be added
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
