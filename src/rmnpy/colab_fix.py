"""
Google Colab compatibility fix for RMNpy.

This module provides utilities to fix library installation issues in Google Colab.
"""

import sys
import tempfile
import urllib.request
import zipfile
from pathlib import Path


def diagnose_installation() -> tuple[list[str], list[str]]:
    """Diagnose the current RMNpy installation and identify missing libraries."""
    import rmnpy

    package_dir = Path(rmnpy.__file__).parent
    print(f"Package directory: {package_dir}")

    # Check for expected libraries
    expected_libs = ["libOCTypes.so", "libSITypes.so", "libRMN.so"]
    missing_libs = []
    found_libs = []

    for lib_name in expected_libs:
        lib_path = package_dir / lib_name
        if lib_path.exists():
            found_libs.append(lib_name)
            print(f"✓ Found: {lib_name}")
        else:
            missing_libs.append(lib_name)
            print(f"✗ Missing: {lib_name}")

    # List all files in package directory
    try:
        all_files = list(package_dir.iterdir())
        so_files = [f.name for f in all_files if f.name.endswith(".so")]
        print(f"All .so files in package: {so_files}")
    except Exception as e:
        print(f"Error listing package directory: {e}")

    return missing_libs, found_libs


def fix_missing_libraries(version: str = "0.1.5") -> bool:
    """Download and extract missing libraries from the wheel."""
    import rmnpy

    package_dir = Path(rmnpy.__file__).parent
    missing_libs, found_libs = diagnose_installation()

    if not missing_libs:
        print("All libraries are present!")
        return True

    print(f"Attempting to fix missing libraries: {missing_libs}")

    # Detect Python version for correct wheel
    python_version = f"{sys.version_info.major}.{sys.version_info.minor}"
    python_tag = f"cp{sys.version_info.major}{sys.version_info.minor}"

    # Try different wheel URLs based on Python version
    possible_wheels = [
        f"rmnpy-{version}-{python_tag}-{python_tag}-manylinux_2_38_x86_64.whl",
        f"rmnpy-{version}-cp311-cp311-manylinux_2_38_x86_64.whl",  # Fallback
        f"rmnpy-{version}-cp310-cp310-manylinux_2_38_x86_64.whl",  # Fallback
        f"rmnpy-{version}-cp39-cp39-manylinux_2_38_x86_64.whl",  # Fallback
    ]

    wheel_url = None
    for wheel_name in possible_wheels:
        test_url = f"https://github.com/pjgrandinetti/RMNpy/releases/download/v{version}/{wheel_name}"
        try:
            # Test if the URL exists
            req = urllib.request.Request(test_url, method="HEAD")
            urllib.request.urlopen(req)
            wheel_url = test_url
            print(f"Found compatible wheel: {wheel_name}")
            break
        except Exception:
            continue

    if not wheel_url:
        print(f"Error: No compatible wheel found for Python {python_version}")
        return False

    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        wheel_path = temp_path / "rmnpy.whl"

        print(f"Downloading wheel from: {wheel_url}")
        try:
            urllib.request.urlretrieve(wheel_url, wheel_path)
            print("Wheel downloaded successfully")
        except Exception as e:
            print(f"Error downloading wheel: {e}")
            return False

        # Extract the wheel
        extract_dir = temp_path / "wheel_contents"
        with zipfile.ZipFile(wheel_path, "r") as zip_ref:
            zip_ref.extractall(extract_dir)

        # Copy missing libraries
        wheel_rmnpy_dir = extract_dir / "rmnpy"
        success_count = 0

        for lib_name in missing_libs:
            source_path = wheel_rmnpy_dir / lib_name
            dest_path = package_dir / lib_name

            if source_path.exists():
                try:
                    import shutil

                    shutil.copy2(source_path, dest_path)
                    # Make it executable
                    dest_path.chmod(0o755)
                    print(f"✓ Copied {lib_name}")
                    success_count += 1
                except Exception as e:
                    print(f"✗ Error copying {lib_name}: {e}")
            else:
                print(f"✗ {lib_name} not found in wheel")

        if success_count == len(missing_libs):
            print("All missing libraries have been fixed!")
            return True
        else:
            print(f"Fixed {success_count}/{len(missing_libs)} libraries")
            return False


def colab_install_fix() -> bool:
    """One-click fix for Google Colab RMNpy installation issues."""
    print("=== RMNpy Google Colab Installation Fix ===")
    print()

    # First, diagnose the issue
    print("1. Diagnosing installation...")
    try:
        missing_libs, found_libs = diagnose_installation()
    except ImportError as e:
        print("Error: Cannot import rmnpy. Please install it first: pip install rmnpy")
        print(f"Import error: {e}")
        return False

    if not missing_libs:
        print("✓ No issues found! RMNpy should work correctly.")
        return True

    print()
    print("2. Fixing missing libraries...")
    success = fix_missing_libraries()

    if success:
        print()
        print("3. Testing the fix...")
        try:
            # Try to import the modules that were failing
            from rmnpy.sitypes import Dimensionality, Scalar, Unit  # noqa: F401

            print("✓ Import test successful!")
            print()
            print("RMNpy installation has been fixed and should now work correctly!")
            return True
        except Exception as e:
            print(f"✗ Import test failed: {e}")
            print("The fix may not have worked completely.")
            return False
    else:
        print("✗ Could not fix all missing libraries.")
        return False


if __name__ == "__main__":
    colab_install_fix()


# Convenience function for direct import
def install_fix() -> bool:
    """Quick fix function for Google Colab - same as colab_install_fix()."""
    return colab_install_fix()


# Also provide a one-liner fix
def quick_fix() -> bool:
    """One-line fix for Google Colab RMNpy issues."""
    print("🔧 Running RMNpy Google Colab quick fix...")
    try:
        import rmnpy  # noqa: F401

        result = colab_install_fix()
        if result:
            print("✅ Fix completed successfully! You can now use RMNpy.")
            # Test import
            try:
                from rmnpy.sitypes import Dimensionality, Scalar, Unit  # noqa: F401

                print("✅ Test import successful!")
                return True
            except Exception as e:
                print(f"❌ Test import failed: {e}")
                return False
        else:
            print("❌ Fix failed. Please check the error messages above.")
            return False
    except Exception as e:
        print(f"❌ Error during fix: {e}")
        return False
