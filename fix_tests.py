#!/usr/bin/env python3
"""
Script to fix test files to use the simplified Unit and Dimensionality API.

Changes:
- .symbol -> str(obj)
- .multiply(x) -> obj * x
- .divide(x) -> obj / x
- .power(x) -> obj ** x
- .is_equal(x) -> obj == x
- .is_dimensionally_equal(x) -> obj.dimensionality == x.dimensionality (or similar check)
- .show() -> str(obj) (for display)
"""

import os
import re
import sys


def fix_file(filepath: str) -> bool:
    """Fix a single test file."""
    print(f"Fixing {filepath}...")

    with open(filepath, "r") as f:
        content = f.read()

    original_content = content

    # Fix .symbol property -> str()
    content = re.sub(r"(\w+)\.symbol", r"str(\1)", content)

    # Fix .multiply() -> *
    content = re.sub(r"(\w+)\.multiply\(([^)]+)\)", r"\1 * \2", content)

    # Fix .divide() -> /
    content = re.sub(r"(\w+)\.divide\(([^)]+)\)", r"\1 / \2", content)

    # Fix .power() -> **
    content = re.sub(r"(\w+)\.power\(([^)]+)\)", r"\1 ** \2", content)

    # Fix .is_equal() -> ==
    content = re.sub(r"(\w+)\.is_equal\(([^)]+)\)", r"\1 == \2", content)

    # Fix .is_dimensionally_equal() -> comparing dimensionalities
    # This is more complex since we need to check if units have same dimensionality
    content = re.sub(
        r"(\w+)\.is_dimensionally_equal\(([^)]+)\)",
        r"\1.dimensionality == \2.dimensionality",
        content,
    )

    # Fix .show() -> print(str()) or just remove if used for testing
    content = re.sub(r"(\w+)\.show\(\)", r"str(\1)", content)

    # Fix nth_root method calls to use simpler approach
    content = re.sub(r"(\w+)\.nth_root\(([^)]+)\)", r"\1 ** (1/\2)", content)

    if content != original_content:
        with open(filepath, "w") as f:
            f.write(content)
        print(f"  Updated {filepath}")
        return True
    else:
        print(f"  No changes needed for {filepath}")
        return False


def main() -> int:
    """Fix all test files."""
    test_dir = "tests/test_sitypes"

    if not os.path.exists(test_dir):
        print(f"Test directory {test_dir} not found!")
        return 1

    files_changed = 0

    for filename in os.listdir(test_dir):
        if filename.endswith(".py") and filename.startswith("test_"):
            filepath = os.path.join(test_dir, filename)
            if fix_file(filepath):
                files_changed += 1

    print(f"\nFixed {files_changed} files.")
    print("\nNote: Some fixes may need manual review, especially:")
    print("- Complex .is_dimensionally_equal() cases")
    print("- Test assertions that may need adjustment")
    print("- Method calls within complex expressions")

    return 0


if __name__ == "__main__":
    sys.exit(main())
