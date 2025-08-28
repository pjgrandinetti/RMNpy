#!/usr/bin/env python3

import sys
import traceback

# Add src to path so we can import rmnpy
sys.path.insert(0, "src")

from rmnpy.wrappers.rmnlib.dataset import Dataset  # noqa: E402
from rmnpy.wrappers.rmnlib.dependent_variable import DependentVariable  # noqa: E402
from rmnpy.wrappers.rmnlib.dimension import SIDimension  # noqa: E402


def create_minimal_dataset() -> Dataset:
    """Create a minimal dataset for testing"""
    # Create a simple dimension
    dim = SIDimension.new(
        label="time", quantity_name="time", description="Time dimension"
    )

    # Create a dependent variable
    dv = DependentVariable.new(
        quantity_name="signal", description="A test signal", dimensions=[dim]
    )

    # Create dataset
    dataset = Dataset.new(
        title="Test Dataset", description="A test dataset", dependent_variables=[dv]
    )

    return dataset


def test_envelope_handling() -> None:
    """Test envelope handling in detail"""
    print("Creating minimal dataset...")
    original = create_minimal_dataset()
    print("✓ Created dataset")

    print("\nCalling to_dict()...")
    data_dict = original.to_dict()
    print(f"✓ to_dict() returned type: {type(data_dict)}")
    print(
        f"✓ Keys: {list(data_dict.keys()) if isinstance(data_dict, dict) else 'Not a dict'}"
    )

    # Check if CSDM envelope
    if isinstance(data_dict, dict) and "csdm" in data_dict and len(data_dict) == 1:
        print("✓ Has CSDM envelope")
        inner_dict = data_dict["csdm"]
        print(f"✓ Inner dict type: {type(inner_dict)}")
        print(
            f"✓ Inner dict keys: {list(inner_dict.keys()) if isinstance(inner_dict, dict) else 'Not a dict'}"
        )

        # Check for specific problematic keys
        for key in ["dependent_variables", "dimensions", "application"]:
            if key in inner_dict:
                print(f"✓ Found {key}: {type(inner_dict[key])}")
                if key == "dependent_variables" and isinstance(inner_dict[key], list):
                    print(f"  - Length: {len(inner_dict[key])}")
                    if inner_dict[key]:
                        print(f"  - First item type: {type(inner_dict[key][0])}")
                        if isinstance(inner_dict[key][0], dict):
                            print(
                                f"  - First item keys: {list(inner_dict[key][0].keys())}"
                            )

        # Test manual from_dict call
        print("\nTesting manual from_dict call...")
        try:
            # Try with a very minimal dict first
            minimal_dict = {
                "title": inner_dict.get("title", "Test"),
                "description": inner_dict.get("description", "Test description"),
            }
            print(f"Trying with minimal dict: {minimal_dict}")

            # This should reveal where the segfault happens
            Dataset.from_dict({"csdm": minimal_dict})
            print("✓ Minimal from_dict succeeded!")

        except Exception as e:
            print(f"✗ Minimal from_dict failed: {e}")
            traceback.print_exc()

    else:
        print("✗ No CSDM envelope found")
        print(f"Data: {data_dict}")


if __name__ == "__main__":
    test_envelope_handling()
