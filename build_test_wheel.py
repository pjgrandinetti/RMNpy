#!/usr/bin/env python3
"""
Build a wheel locally for testing
"""
import glob
import os
import subprocess
import sys


def build_test_wheel():
    """Build a wheel for testing"""
    print("🔨 Building test wheel...")

    # Clean previous builds
    if os.path.exists("dist"):
        subprocess.run(["rm", "-rf", "dist"], check=True)
    if os.path.exists("build"):
        subprocess.run(["rm", "-rf", "build"], check=True)

    # Build wheel
    result = subprocess.run(
        [sys.executable, "setup.py", "bdist_wheel"], capture_output=True, text=True
    )

    if result.returncode != 0:
        print("❌ Wheel build failed:")
        print(result.stderr)
        return None

    # Find the built wheel
    wheels = glob.glob("dist/*.whl")
    if not wheels:
        print("❌ No wheel found in dist/")
        return None

    wheel_path = wheels[0]
    print(f"✅ Built wheel: {wheel_path}")
    return wheel_path


if __name__ == "__main__":
    wheel_path = build_test_wheel()
    if wheel_path:
        print(f"\nTo analyze the wheel, run:")
        print(f"python analyze_wheel_libraries.py {wheel_path}")
