#!/usr/bin/env python3
"""Test script to verify both linking modes work."""

import os
import subprocess
import sys


def test_dynamic_mode() -> bool:
    """Test normal dynamic/import library mode."""
    print("=== Testing Dynamic/Import Library Mode ===")
    env = os.environ.copy()
    env.pop("RMNPY_WINDOWS_STATIC_ONLY", None)  # Ensure it's not set

    cmd = [
        sys.executable,
        "-c",
        'import setup; print("Dynamic mode: Import successful")',
    ]
    result = subprocess.run(cmd, env=env, capture_output=True, text=True)

    print("STDOUT:", result.stdout)
    if result.stderr:
        print("STDERR:", result.stderr)
    print("Return code:", result.returncode)
    return result.returncode == 0


def test_static_mode() -> bool:
    """Test static library fallback mode."""
    print("\n=== Testing Static Library Mode ===")
    env = os.environ.copy()
    env["RMNPY_WINDOWS_STATIC_ONLY"] = "1"

    cmd = [
        sys.executable,
        "-c",
        'import setup; print("Static mode: Import successful")',
    ]
    result = subprocess.run(cmd, env=env, capture_output=True, text=True)

    print("STDOUT:", result.stdout)
    if result.stderr:
        print("STDERR:", result.stderr)
    print("Return code:", result.returncode)
    return result.returncode == 0


if __name__ == "__main__":
    print("Testing RMNpy setup.py linking modes...")

    dynamic_ok = test_dynamic_mode()
    static_ok = test_static_mode()

    print("=== Results ===")
    print("Dynamic mode: " + ("✓" if dynamic_ok else "✗"))
    print("Static mode: " + ("✓" if static_ok else "✗"))

    if dynamic_ok and static_ok:
        print("Both modes work - setup is ready!")
        sys.exit(0)
    else:
        print("Some modes failed - check errors above")
        sys.exit(1)
