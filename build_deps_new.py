#!/usr/bin/env python3
"""Script to check RMNLib workspace dependencies for building RMNpy."""

import os
import sys
from pathlib import Path
import argparse

def check_workspace_dependency(lib_name: str, base_path: Path, verbose: bool = False) -> bool:
    """Check that a workspace dependency is available."""
    install_dir = base_path / f"../{lib_name}/install"
    
    # Check for headers
    header_dir = install_dir / "include" / lib_name
    if not header_dir.exists():
        print(f"✗ Missing {lib_name} headers: {header_dir}")
        return False
    
    header_count = len(list(header_dir.glob("*.h")))
    if header_count == 0:
        print(f"✗ No headers found in {header_dir}")
        return False
        
    if verbose:
        print(f"  Found {header_count} headers in {header_dir}")
    
    # Check for library
    lib_file = install_dir / "lib" / f"lib{lib_name}.a"
    if not lib_file.exists():
        print(f"✗ Missing {lib_name} library: {lib_file}")
        return False
        
    if verbose:
        print(f"  Found library: {lib_file}")
    
    print(f"✓ {lib_name} workspace dependency OK")
    return True

def check_all_dependencies(verbose: bool = False) -> bool:
    """Check all required workspace dependencies."""
    script_dir = Path(__file__).parent
    required_libs = ["OCTypes", "SITypes", "RMNLib"]
    
    print("Checking workspace dependencies...")
    print("=" * 40)
    
    all_found = True
    for lib in required_libs:
        if not check_workspace_dependency(lib, script_dir, verbose):
            all_found = False
    
    if not all_found:
        print("\n" + "=" * 50)
        print("ERROR: Missing workspace dependencies!")
        print("Make sure you have built all required libraries:")
        print("  cd ../OCTypes && make install")
        print("  cd ../SITypes && make install") 
        print("  cd ../RMNLib && make install")
        print("=" * 50)
        return False
        
    print("\n✓ All workspace dependencies ready!")
    return True

def main():
    parser = argparse.ArgumentParser(description="Check RMNpy workspace dependencies")
    parser.add_argument("-v", "--verbose", action="store_true",
                       help="Verbose output")
    args = parser.parse_args()
    
    if not check_all_dependencies(args.verbose):
        sys.exit(1)
        
    print("Ready to build RMNpy!")

if __name__ == "__main__":
    main()
