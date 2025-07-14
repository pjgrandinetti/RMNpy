#!/usr/bin/env python3
"""Script to copy RMNLib dependencies for building RMNpy."""

import os
import shutil
from pathlib import Path
import argparse
import sys

def copy_headers(base_path: Path, include_dir: Path, verbose: bool = False):
    """Copy all required header files."""
    
    def copy_header_dir(src_name: str, dst_name: str):
        src_dir = base_path / src_name / "src"
        dst_dir = include_dir / dst_name
        
        if not src_dir.exists():
            print(f"WARNING: Source directory {src_dir} does not exist!")
            return
        
        dst_dir.mkdir(parents=True, exist_ok=True)
        
        copied_count = 0
        for header in src_dir.glob("*.h"):
            dst_file = dst_dir / header.name
            shutil.copy2(header, dst_file)
            copied_count += 1
            if verbose:
                print(f"  Copied {header.name}")
        
        print(f"Copied {copied_count} headers from {src_name} to {dst_name}/")
    
    # Copy all header directories
    copy_header_dir("RMNLib", "RMNLib")
    copy_header_dir("OCTypes", "OCTypes") 
    copy_header_dir("SITypes", "SITypes")

def copy_libraries(base_path: Path, lib_dir: Path, verbose: bool = False):
    """Copy all required library files."""
    lib_dir.mkdir(exist_ok=True)
    
    # Define library locations grouped by library name
    library_search_paths = {
        "libRMN.a": [
            base_path / "RMNLib" / "build" / "lib" / "libRMN.a",
            base_path / "RMNLib" / "lib" / "libRMN.a",
        ],
        "libOCTypes.a": [
            base_path / "OCTypes" / "lib" / "libOCTypes.a",
            base_path / "OCTypes" / "install" / "lib" / "libOCTypes.a",
            base_path / "OCTypes" / "build" / "lib" / "libOCTypes.a",
        ],
        "libSITypes.a": [
            base_path / "SITypes" / "libSITypes.a",
            base_path / "SITypes" / "install" / "lib" / "libSITypes.a",
            base_path / "SITypes" / "build" / "lib" / "libSITypes.a",
        ],
    }
    
    copied_count = 0
    for lib_name, search_paths in library_search_paths.items():
        for src_path in search_paths:
            if src_path.exists():
                dst_path = lib_dir / lib_name
                shutil.copy2(src_path, dst_path)
                copied_count += 1
                if verbose:
                    print(f"  Copied {src_path} -> {dst_path}")
                break  # Only copy the first one found for this library
            elif verbose:
                print(f"  Not found: {src_path}")
    
    print(f"Copied {copied_count} libraries to lib/")
    
    # Check if we got all required libraries
    required_libs = ["libRMN.a", "libOCTypes.a", "libSITypes.a"]
    missing_libs = []
    for lib_name in required_libs:
        if not (lib_dir / lib_name).exists():
            missing_libs.append(lib_name)
    
    if missing_libs:
        print(f"WARNING: Missing required libraries: {missing_libs}")
        print("Make sure the libraries are built before running this script.")
        return False
    
    return True

def check_build_requirements():
    """Check if build requirements are available."""
    print("Checking build requirements...")
    
    requirements = [
        ("python3", "Python 3"),
        ("pip", "pip package manager"),
    ]
    
    missing = []
    for cmd, desc in requirements:
        if shutil.which(cmd) is None:
            missing.append(desc)
    
    if missing:
        print(f"ERROR: Missing required tools: {', '.join(missing)}")
        return False
    
    # Check Python packages
    try:
        import numpy
        print(f"  ✓ numpy {numpy.__version__}")
    except ImportError:
        print("  ✗ numpy (install with: pip install numpy)")
        missing.append("numpy")
    
    try:
        import Cython
        print(f"  ✓ Cython {Cython.__version__}")
    except ImportError:
        print("  ✗ Cython (install with: pip install cython)")
        missing.append("Cython")
    
    return len(missing) == 0

def main():
    parser = argparse.ArgumentParser(description="Setup RMNpy build dependencies")
    parser.add_argument("--base-path", type=Path, 
                       default=Path(".."), 
                       help="Base path to OCTypes-SITypes directory")
    parser.add_argument("--verbose", "-v", action="store_true",
                       help="Verbose output")
    parser.add_argument("--check-only", action="store_true",
                       help="Only check requirements, don't copy files")
    
    args = parser.parse_args()
    
    # Convert to absolute path
    base_path = args.base_path.resolve()
    
    print(f"RMNpy Build Dependencies Setup")
    print(f"Base path: {base_path}")
    print()
    
    # Check if base path exists and contains expected directories
    if not base_path.exists():
        print(f"ERROR: Base path {base_path} does not exist!")
        sys.exit(1)
    
    required_dirs = ["RMNLib", "OCTypes", "SITypes"]
    missing_dirs = [d for d in required_dirs if not (base_path / d).exists()]
    if missing_dirs:
        print(f"ERROR: Missing required directories in {base_path}: {missing_dirs}")
        sys.exit(1)
    
    # Check build requirements
    if not check_build_requirements():
        print("Please install missing requirements and try again.")
        sys.exit(1)
    
    if args.check_only:
        print("Requirements check passed!")
        return
    
    # Setup paths
    current_dir = Path.cwd()
    include_dir = current_dir / "include"
    lib_dir = current_dir / "lib"
    
    print(f"Setting up dependencies in: {current_dir}")
    print()
    
    # Copy headers
    print("Copying header files...")
    copy_headers(base_path, include_dir, args.verbose)
    print()
    
    # Copy libraries  
    print("Copying library files...")
    success = copy_libraries(base_path, lib_dir, args.verbose)
    print()
    
    if success:
        print("✓ Setup completed successfully!")
        print()
        print("Next steps:")
        print("  1. Install Python dependencies: pip install -r requirements.txt")
        print("  2. Build the extension: python setup.py build_ext --inplace")
        print("  3. Install in development mode: pip install -e .")
    else:
        print("✗ Setup completed with warnings.")
        print("Check that all required libraries are built.")
        sys.exit(1)

if __name__ == "__main__":
    main()
