#!/usr/bin/env python3

import sys
from pathlib import Path

# Add the src directory to Python path (works from scripts/ directory)
script_dir = Path(__file__).parent
src_dir = script_dir.parent / "src"
sys.path.insert(0, str(src_dir))

from rmnpy.exceptions import RMNError  # noqa: E402
from rmnpy.wrappers.sitypes.unit import Unit  # noqa: E402


def test_empty_string_handling() -> bool:
    """Test that empty string raises RMNError as expected."""
    print("Testing empty string handling...")

    try:
        result = Unit.parse("")
        print(f"ERROR: Empty string parsing should have failed but returned: {result}")
        return False
    except RMNError as e:
        print(f"✓ Empty string correctly raised RMNError: {e}")
        return True
    except Exception as e:
        print(f"ERROR: Empty string raised unexpected exception type {type(e)}: {e}")
        return False


def test_invalid_expression_handling() -> bool:
    """Test that invalid expression raises RMNError as expected."""
    print("Testing invalid expression handling...")

    try:
        result = Unit.parse("invalid_unit_xyz")
        print(
            f"ERROR: Invalid expression parsing should have failed but returned: {result}"
        )
        return False
    except RMNError as e:
        print(f"✓ Invalid expression correctly raised RMNError: {e}")
        return True
    except Exception as e:
        print(
            f"ERROR: Invalid expression raised unexpected exception type {type(e)}: {e}"
        )
        return False


if __name__ == "__main__":
    print("Testing RMNpy Unit.parse error handling...")

    empty_ok = test_empty_string_handling()
    invalid_ok = test_invalid_expression_handling()

    if empty_ok and invalid_ok:
        print("\n✅ All error handling tests passed!")
    else:
        print(
            f"\n❌ Some tests failed: empty_string={empty_ok}, invalid_expr={invalid_ok}"
        )
