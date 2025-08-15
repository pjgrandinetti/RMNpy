#!/usr/bin/env python3
"""
Extract SI Quantity Constants from SIDimensionality.h

This script extracts all kSIQuantity* constants from the SITypes C header file
and generates a Python constants module. This ensures there's only one source
of truth for the quantity names.

This script runs automatically during package builds and installations.

Manual usage:
    python extract_si_constants.py
    # or
    make generate-constants

Generates:
    src/rmnpy/quantities.pyx - Python quantities module with OCStringRef constants
"""

import re
import sys
from pathlib import Path
from typing import List, Tuple


def find_header_file() -> Path:
    """Find the SIDimensionality.h header file."""
    script_dir = Path(__file__).parent

    # Try multiple possible locations relative to RMNpy directory
    possible_paths = [
        script_dir.parent / "SITypes" / "src" / "SIDimensionality.h",
        script_dir / "include" / "SITypes" / "SIDimensionality.h",
        script_dir.parent / "include" / "SITypes" / "SIDimensionality.h",
    ]

    for path in possible_paths:
        if path.exists():
            return path

    raise FileNotFoundError(
        "Could not find SIDimensionality.h in any of these locations:\n"
        + "\n".join(f"  - {p}" for p in possible_paths)
    )


def extract_quantity_constants(header_path: Path) -> List[Tuple[str, str]]:
    """Extract all kSIQuantity* constants from the header file."""
    print(f"Reading header file: {header_path}")

    with open(header_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Pattern to match: #define kSIQuantityName STR("quantity name")
    pattern = r'#define\s+(kSIQuantity\w+)\s+STR\("([^"]+)"\)'

    matches = re.findall(pattern, content)

    if not matches:
        raise ValueError("No kSIQuantity* constants found in header file")

    print(f"Found {len(matches)} quantity constants")
    return matches


def generate_python_constants(
    constants: List[Tuple[str, str]], output_path: Path, header_path: Path
) -> None:
    """Generate Python quantities module."""
    print(f"Generating Python quantities: {output_path}")

    # Sort constants alphabetically by constant name
    constants = sorted(constants, key=lambda x: x[0])

    # Generate file content
    lines = [
        '"""',
        "SI Quantity Names - Auto-generated from SIDimensionality.h",
        "",
        "This file contains all SI quantity name constants extracted from the C header file.",
        "Do not edit manually - regenerate using extract_si_constants.py.",
        "",
        f"Generated from: {header_path.name}",
        '"""',
        "",
        "# Import the C API to get OCStringRef constants",
        "from rmnpy._c_api.sitypes cimport *",
        "",
        "# Define STR function to return Python string",
        "cdef inline object STR(const char* cStr):",
        "    return cStr.decode('utf-8')",
        "",
        "# All quantity name constants as Python strings",
    ]

    # Add each constant
    for const_name, string_value in constants:
        lines.append(f'{const_name} = STR("{string_value}")')

    # Add __all__ for proper module interface
    lines.extend(
        [
            "",
            "__all__ = [",
        ]
    )

    for const_name, _ in constants:
        lines.append(f'    "{const_name}",')

    lines.append("]")

    # Write the file
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    print(f"[OK] Generated {len(constants)} constants in {output_path}")


def main() -> None:
    """Main extraction process."""
    try:
        print("=" * 60)
        print("SI Quantity Names Extraction")
        print("=" * 60)

        # Find header file
        header_path = find_header_file()

        # Extract constants
        constants = extract_quantity_constants(header_path)

        # Generate Python constants module
        script_dir = Path(__file__).parent
        output_path = script_dir.parent / "src" / "rmnpy" / "quantities.pyx"

        generate_python_constants(constants, output_path, header_path)

        print("=" * 60)
        print("[OK] SI Quantity Names extraction completed successfully!")
        print(f"Output: {output_path}")
        print(f"Constants: {len(constants)} quantity name constants")
        print("=" * 60)

        # Show some examples
        print("\nExample quantity names generated:")
        for i, (const_name, string_value) in enumerate(constants[:5]):
            print(f'  {const_name} = STR("{string_value}")')
        if len(constants) > 5:
            print(f"  ... and {len(constants) - 5} more")

    except Exception as e:
        print(f"[X] Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
