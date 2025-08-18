#!/usr/bin/env python3
"""
Clean up _libs directory to only contain shared libraries, not extensions
"""
import glob
import os


def clean_libs_directory():
    """Remove Python extensions from _libs, keep only shared libraries"""
    libs_dir = "src/rmnpy/_libs"

    if not os.path.exists(libs_dir):
        print("No _libs directory found")
        return

    print(f"🧹 Cleaning {libs_dir}")

    # Find all files in _libs
    all_files = os.listdir(libs_dir)

    # Separate shared libraries from extensions
    shared_libs = [
        f
        for f in all_files
        if f.endswith((".dylib", ".so", ".dll")) and not ".cpython-" in f
    ]
    extensions = [f for f in all_files if ".cpython-" in f]

    print(f"📚 Shared libraries (keeping): {len(shared_libs)}")
    for lib in shared_libs:
        print(f"  ✅ {lib}")

    print(f"🐍 Python extensions (removing): {len(extensions)}")
    for ext in extensions:
        ext_path = os.path.join(libs_dir, ext)
        print(f"  🗑️  Removing {ext}")
        os.remove(ext_path)

    print("✅ Cleanup complete!")


if __name__ == "__main__":
    clean_libs_directory()
