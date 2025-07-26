# dll_loader.py
"""
Windows DLL loader module for RMNpy.
Implements Claude Opus 4's recommendation for pre-loading critical DLLs
and setting up proper DLL search paths.
"""
import logging
import os
import sys
from pathlib import Path

# Configure logging for DLL loader diagnostics
_logger = logging.getLogger(__name__)
_handler = logging.StreamHandler(sys.stderr)
_handler.setFormatter(logging.Formatter("[%(asctime)s] DLL_LOADER: %(message)s"))
_logger.addHandler(_handler)
_logger.setLevel(logging.INFO)


def setup_dll_paths() -> None:
    """Setup DLL paths for Windows"""
    if sys.platform == "win32":
        _logger.info("Starting Windows DLL path setup")

        # Set Windows DLL search strategy to safe defaults
        try:
            import ctypes

            kernel32 = ctypes.windll.kernel32
            # LOAD_LIBRARY_SEARCH_DEFAULT_DIRS = 0x1000
            kernel32.SetDefaultDllDirectories(0x1000)
            _logger.info("Set default DLL directories to safe search mode")
        except Exception as e:
            _logger.warning(f"Failed to set default DLL directories: {e}")

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
        _logger.info(
            f"Found {len(valid_dirs)} valid DLL directories: {[str(d) for d in valid_dirs]}"
        )

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
        new_path = os.pathsep.join([str(d) for d in path_dirs] + [existing_path])
        os.environ["PATH"] = new_path
        _logger.info(f"Updated PATH with {len(path_dirs)} directories")

        # Register all valid dirs for DLL search
        registered_dirs = 0
        for d in valid_dirs:
            if hasattr(os, "add_dll_directory"):
                try:
                    cookie = os.add_dll_directory(str(d))
                    registered_dirs += 1
                    _logger.info(f"Registered DLL directory: {d} (cookie: {cookie})")
                except Exception as e:
                    _logger.warning(f"Failed to register DLL directory {d}: {e}")
        _logger.info(
            f"Successfully registered {registered_dirs}/{len(valid_dirs)} DLL directories"
        )

        # SIMPLIFIED: Skip DLL copying for now to isolate the issue
        # We'll rely only on PATH and add_dll_directory for this diagnostic run
        _logger.info("Skipping DLL copying - using PATH and add_dll_directory only")

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
                # Use WinDLL for proper Windows loader semantics
                _logger.info(f"Loading Python DLL: {py_dll}")
                handle = ctypes.WinDLL(str(py_dll))
                _logger.info(f"Successfully loaded Python DLL, handle: {handle}")
            else:
                _logger.warning(f"Python DLL not found at {py_dll}")
        except Exception as e:
            _logger.error(f"Failed to load Python DLL: {e}")

        # Explicitly preload MinGW runtime DLLs to ensure all dependencies are loaded
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
            # GMP, MPFR, and MPC for SITypes
            "libgmp-10.dll",
            "libmpfr-6.dll",
            "libmpc-3.dll",
        ]

        _logger.info(f"Attempting to preload {len(runtime_dlls)} MinGW runtime DLLs")
        loaded_dlls = 0
        try:
            import ctypes as _ct

            for _dll in runtime_dlls:
                dll_found = False
                for _dir in valid_dirs:
                    _path = Path(_dir) / _dll
                    if _path.exists():
                        try:
                            # Load each runtime DLL with standard calling convention
                            _logger.info(f"Loading MinGW DLL: {_path}")
                            handle = _ct.CDLL(str(_path))
                            _logger.info(
                                f"Successfully loaded {_dll}, handle: {handle}"
                            )
                            loaded_dlls += 1
                            dll_found = True
                            break
                        except Exception as e:
                            _logger.error(f"Failed to load {_dll} from {_path}: {e}")
                if not dll_found:
                    _logger.warning(f"MinGW DLL not found: {_dll}")
        except Exception as e:
            _logger.error(f"Critical error during MinGW DLL preloading: {e}")

        _logger.info(
            f"Successfully loaded {loaded_dlls}/{len(runtime_dlls)} MinGW runtime DLLs"
        )
        _logger.info("Windows DLL path setup completed")


def preload_mingw_runtime() -> None:
    """Register MinGW runtime directories for Windows DLL loader without loading DLLs explicitly"""
    if sys.platform == "win32":
        _logger.info("Starting MinGW runtime directory registration")
        base_dir = Path(__file__).parent
        # Directories where runtime DLLs reside
        runtime_dirs = [
            base_dir,
            base_dir / "wrappers" / "sitypes",
            Path(r"D:\a\_temp\msys64\mingw64\bin"),
            Path(r"C:\msys64\mingw64\bin"),
        ]
        # Register runtime dirs for DLL search without modifying PATH
        registered = 0
        for d in runtime_dirs:
            if d.exists() and hasattr(os, "add_dll_directory"):
                try:
                    cookie = os.add_dll_directory(str(d))
                    registered += 1
                    _logger.info(
                        f"Registered MinGW runtime directory: {d} (cookie: {cookie})"
                    )
                except Exception as e:
                    _logger.warning(
                        f"Failed to register MinGW runtime directory {d}: {e}"
                    )
        _logger.info(
            f"MinGW runtime registration completed: {registered}/{len(runtime_dirs)} directories"
        )
