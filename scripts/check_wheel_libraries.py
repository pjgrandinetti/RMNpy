#!/usr/bin/env python3
"""
Test script to verify that shared libraries are properly included in RMNpy builds.
Run this script after building a wheel to check if the libraries are included.
"""

import os
import sys
import zipfile
from pathlib import Path
from typing import Union


def check_wheel_libraries(wheel_path: Union[str, Path]) -> bool:
    """Check if a wheel contains the required shared libraries."""
    wheel_name = str(wheel_path)
    print(f"Checking wheel: {wheel_name}")

    # Determine required library names based on platform info in wheel name
    if "linux" in wheel_name.lower():
        required_libs = ["libOCTypes.so", "libSITypes.so", "libRMN.so"]
        lib_extensions = [".so"]
    elif "macos" in wheel_name.lower() or "darwin" in wheel_name.lower():
        required_libs = ["libOCTypes.dylib", "libSITypes.dylib", "libRMN.dylib"]
        lib_extensions = [".dylib"]
    elif "win" in wheel_name.lower():
        required_libs = ["rmnstack_bridge.dll"]
        lib_extensions = [".dll"]
    else:
        # Default to checking for all possible extensions
        required_libs = ["libOCTypes", "libSITypes", "libRMN"]  # Base names
        lib_extensions = [".so", ".dylib", ".dll"]

    found_libs = []

    try:
        with zipfile.ZipFile(wheel_path, "r") as zf:
            files = zf.namelist()
            # Find all shared library files
            so_files = [
                f
                for f in files
                if any(f.endswith(ext) or ext in f for ext in lib_extensions)
            ]

            print(f"All shared library files in wheel: {len(so_files)}")
            for so_file in so_files:
                print(f"  - {so_file}")

            # Check for required libraries (flexible matching)
            for lib in required_libs:
                if any(lib in f for f in so_files):
                    found_libs.append(lib)
                    print(f"✓ Found: {lib}")
                else:
                    print(f"✗ Missing: {lib}")

            print(
                f"\nSummary: {len(found_libs)}/{len(required_libs)} required libraries found"
            )

            if len(found_libs) == len(required_libs):
                print("✅ All required libraries are included in the wheel!")
                return True
            else:
                print("❌ Some required libraries are missing from the wheel.")
                return False

    except Exception as e:
        print(f"Error reading wheel: {e}")
        return False


def main() -> None:
    """Main function to check wheels in dist directory."""
    if len(sys.argv) > 1:
        wheel_path = sys.argv[1]
        if not os.path.exists(wheel_path):
            print(f"Error: Wheel file not found: {wheel_path}")
            sys.exit(1)
        success = check_wheel_libraries(wheel_path)
    else:
        # Check all wheels in dist directory
        dist_dir = Path("dist")
        if not dist_dir.exists():
            print("Error: dist directory not found. Build a wheel first.")
            sys.exit(1)

        wheel_files = list(dist_dir.glob("*.whl"))
        if not wheel_files:
            print("Error: No wheel files found in dist directory.")
            sys.exit(1)

        success = True
        for wheel_file in wheel_files:
            print(f"\n{'='*60}")
            if not check_wheel_libraries(wheel_file):
                success = False

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
