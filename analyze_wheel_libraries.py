#!/usr/bin/env python3
"""
Comprehensive wheel library analysis tool to detect:
1. Multiple copies of the same C library
2. Symbol conflicts between libraries
3. Missing dependencies
4. Library size and duplication issues
"""
import hashlib
import os
import subprocess
import sys
import tempfile
import zipfile
from collections import defaultdict


def get_file_hash(file_path):
    """Get SHA256 hash of a file"""
    hasher = hashlib.sha256()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hasher.update(chunk)
    return hasher.hexdigest()


def get_library_symbols(lib_path):
    """Get all exported symbols from a library"""
    try:
        result = subprocess.run(["nm", "-gU", lib_path], capture_output=True, text=True)
        symbols = set()
        for line in result.stdout.split("\n"):
            if line.strip() and not line.startswith(" "):
                # Extract symbol name (last part after spaces)
                parts = line.strip().split()
                if len(parts) >= 3:
                    symbols.add(parts[2])
        return symbols
    except Exception as e:
        print(f"Error getting symbols from {lib_path}: {e}")
        return set()


def get_library_dependencies(lib_path):
    """Get library dependencies"""
    try:
        result = subprocess.run(
            ["otool", "-L", lib_path], capture_output=True, text=True
        )
        deps = []
        for line in result.stdout.split("\n")[1:]:  # Skip first line (self-reference)
            line = line.strip()
            if line:
                # Extract library name
                dep = line.split("(")[0].strip()
                deps.append(dep)
        return deps
    except Exception as e:
        print(f"Error getting dependencies from {lib_path}: {e}")
        return []


def analyze_wheel_libraries(wheel_path):
    """Comprehensive analysis of wheel libraries"""
    print(f"🔍 Analyzing wheel: {wheel_path}")
    print("=" * 80)

    with tempfile.TemporaryDirectory() as temp_dir:
        # Extract wheel
        with zipfile.ZipFile(wheel_path, "r") as zip_ref:
            zip_ref.extractall(temp_dir)

        # Find all shared libraries and extensions
        all_libs = []
        for root, dirs, files in os.walk(temp_dir):
            for file in files:
                if file.endswith((".dylib", ".so")) or ".cpython-" in file:
                    full_path = os.path.join(root, file)
                    rel_path = os.path.relpath(full_path, temp_dir)
                    all_libs.append((file, full_path, rel_path))

        if not all_libs:
            print("❌ No shared libraries found in wheel")
            return

        print(f"📚 Found {len(all_libs)} shared libraries/extensions:")
        for name, _, rel_path in all_libs:
            size = os.path.getsize(_)
            print(f"  • {rel_path} ({size:,} bytes)")

        print("\n" + "=" * 80)

        # 1. Check for duplicate libraries by name and hash
        print("🔍 DUPLICATE LIBRARY DETECTION")
        print("-" * 40)

        lib_by_name = defaultdict(list)
        lib_by_hash = defaultdict(list)

        for name, full_path, rel_path in all_libs:
            if name.endswith(".dylib"):  # Focus on .dylib files for duplicates
                lib_by_name[name].append((full_path, rel_path))
                file_hash = get_file_hash(full_path)
                lib_by_hash[file_hash].append((name, rel_path))

        # Check for same-name libraries
        duplicates_found = False
        for lib_name, paths in lib_by_name.items():
            if len(paths) > 1:
                duplicates_found = True
                print(f"⚠️  Multiple copies of {lib_name}:")
                for full_path, rel_path in paths:
                    size = os.path.getsize(full_path)
                    file_hash = get_file_hash(full_path)[:12]
                    print(f"    {rel_path} ({size:,} bytes, hash: {file_hash}...)")

        # Check for identical files with different names
        for file_hash, libs in lib_by_hash.items():
            if len(libs) > 1:
                duplicates_found = True
                print(f"⚠️  Identical files (hash: {file_hash[:12]}...):")
                for name, rel_path in libs:
                    print(f"    {rel_path}")

        if not duplicates_found:
            print("✅ No duplicate libraries detected")

        print("\n" + "=" * 80)

        # 2. Analyze symbol conflicts
        print("🔍 SYMBOL CONFLICT ANALYSIS")
        print("-" * 40)

        symbol_to_libs = defaultdict(set)
        lib_symbols = {}

        # Collect symbols from all dylib files
        dylib_files = [
            (name, full_path, rel_path)
            for name, full_path, rel_path in all_libs
            if name.endswith(".dylib")
        ]

        for name, full_path, rel_path in dylib_files:
            print(f"📖 Analyzing symbols in {name}...")
            symbols = get_library_symbols(full_path)
            lib_symbols[name] = symbols

            for symbol in symbols:
                symbol_to_libs[symbol].add(name)

        # Find conflicting symbols
        conflicts = {
            symbol: libs for symbol, libs in symbol_to_libs.items() if len(libs) > 1
        }

        if conflicts:
            print(f"\n⚠️  Found {len(conflicts)} symbol conflicts:")

            # Group by library pairs for cleaner output
            lib_pairs = defaultdict(list)
            for symbol, libs in conflicts.items():
                libs_tuple = tuple(sorted(libs))
                lib_pairs[libs_tuple].append(symbol)

            for libs_tuple, symbols in lib_pairs.items():
                print(
                    f"\n🔥 Conflict between {' and '.join(libs_tuple)} ({len(symbols)} symbols):"
                )
                # Show first 10 symbols as examples
                for symbol in sorted(symbols)[:10]:
                    print(f"    • {symbol}")
                if len(symbols) > 10:
                    print(f"    ... and {len(symbols) - 10} more")
        else:
            print("✅ No symbol conflicts detected between libraries")

        print("\n" + "=" * 80)

        # 3. Check dependencies
        print("🔍 DEPENDENCY ANALYSIS")
        print("-" * 40)

        for name, full_path, rel_path in dylib_files:
            print(f"\n📦 {name} dependencies:")
            deps = get_library_dependencies(full_path)
            for dep in deps:
                if "/usr/lib/" in dep or "/System/" in dep:
                    print(f"  ✅ {dep}")  # System library
                elif "@rpath/" in dep or "@loader_path/" in dep:
                    print(f"  🔗 {dep}")  # Relative dependency
                else:
                    print(f"  ⚠️  {dep}")  # Absolute path - potential issue

        print("\n" + "=" * 80)

        # 4. Size analysis
        print("🔍 SIZE ANALYSIS")
        print("-" * 40)

        total_size = sum(os.path.getsize(full_path) for _, full_path, _ in all_libs)
        print(
            f"📊 Total size of all libraries: {total_size:,} bytes ({total_size/1024/1024:.1f} MB)"
        )

        # Show largest libraries
        libs_by_size = sorted(
            all_libs, key=lambda x: os.path.getsize(x[1]), reverse=True
        )
        print(f"\n🔝 Largest libraries:")
        for name, full_path, rel_path in libs_by_size[:5]:
            size = os.path.getsize(full_path)
            print(f"  • {rel_path}: {size:,} bytes ({size/1024/1024:.1f} MB)")


def main():
    if len(sys.argv) != 2:
        print("Usage: python analyze_wheel_libraries.py <wheel_path>")
        print("\nThis tool analyzes a Python wheel for:")
        print("  • Duplicate libraries")
        print("  • Symbol conflicts")
        print("  • Dependency issues")
        print("  • Size analysis")
        sys.exit(1)

    wheel_path = sys.argv[1]
    if not os.path.exists(wheel_path):
        print(f"Error: Wheel file {wheel_path} does not exist")
        sys.exit(1)

    analyze_wheel_libraries(wheel_path)


if __name__ == "__main__":
    main()
