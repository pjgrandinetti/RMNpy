#!/usr/bin/env python3
"""Test what OCTypeCopyJSON returns for SIScalar objects."""

from rmnpy.wrappers.sitypes.scalar import Scalar


def test_scalar_json() -> None:
    """Test OCTypeCopyJSON output for scalar."""
    scalar = Scalar(42.0, "m")
    print(f"Scalar object: {scalar.value} {scalar.unit}")

    # Test the to_dict method
    result = scalar.to_dict()
    print(f"to_dict() result type: {type(result)}")
    print(f"to_dict() result: {repr(result)}")

    # Test copy_as_dictionary directly
    result2 = scalar.copy_as_dictionary()
    print(f"copy_as_dictionary() result type: {type(result2)}")
    print(f"copy_as_dictionary() result: {repr(result2)}")


if __name__ == "__main__":
    test_scalar_json()
