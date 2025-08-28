#!/usr/bin/env python3

import os
import sys

# Add src to path so we can import rmnpy
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "src"))

from rmnpy.wrappers.rmnlib.dataset import Dataset  # noqa: E402
from rmnpy.wrappers.rmnlib.dependent_variable import DependentVariable  # noqa: E402
from rmnpy.wrappers.rmnlib.dimension import LinearDimension  # noqa: E402


def test_debug() -> None:
    """Debug the from_dict issue."""

    # Create a simple dataset
    dim = LinearDimension(
        count=3,
        increment=1.0,
        coordinates_offset=0.0,
        label="Test Dimension",
        unit="Hz",
    )

    dv = DependentVariable(
        components=[[1.0, 2.0, 3.0]],
        name="test_data",
        unit="V",
    )

    original = Dataset(
        dependent_variables=[dv],
        dimensions=[dim],
        title="Test Dataset",
        description="Test description",
    )

    print("Created original dataset")

    # Convert to dictionary
    data_dict = original.to_dict()
    print(f"to_dict() returned type: {type(data_dict)}")
    print(
        f"to_dict() keys: {list(data_dict.keys()) if isinstance(data_dict, dict) else 'Not a dict'}"
    )

    if isinstance(data_dict, dict):
        if "csdm" in data_dict and len(data_dict) == 1:
            print("Dictionary has CSDM envelope")
            inner_dict = data_dict["csdm"]
            print(f"Inner dict type: {type(inner_dict)}")
            print(
                f"Inner dict keys: {list(inner_dict.keys()) if isinstance(inner_dict, dict) else 'Not a dict'}"
            )
        else:
            print("Dictionary does not have CSDM envelope")
            print(f"Raw dict keys: {list(data_dict.keys())}")

    print("About to call from_dict...")

    # This is where it crashes
    try:
        Dataset.from_dict(data_dict)
        print("Successfully created dataset")
    except Exception as e:
        print(f"Exception: {e}")


if __name__ == "__main__":
    test_debug()
