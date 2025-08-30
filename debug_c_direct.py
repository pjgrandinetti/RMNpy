#!/usr/bin/env python3
"""Debug script to test direct C API calls."""

import json

from rmnpy.wrappers.rmnlib.dimension import BaseDimension, LabeledDimension

# Create test data
labels = ["red", "green", "blue", "alpha"]
original = LabeledDimension(
    labels=labels,
    label="color_channel",
    description="RGBA color channels",
    application={"encoding": "sRGB"},
)

dim_dict = original.dict()
print("=== Test Data ===")
print(json.dumps(dim_dict, indent=2))

print("\n=== Testing BaseDimension.from_dict ===")
try:
    restored = BaseDimension.from_dict(dim_dict)
    print(f"Created wrapper: {type(restored)}")
    print(f"Label: {restored.label}")
    print(f"Description: {restored.description}")
    print(f"Application: {restored.application}")

    # Let's check if the C object actually has the metadata
    print("\n=== Checking Internal State ===")
    c_ref_hex = hex(restored._c_ref) if hasattr(restored, "_c_ref") else "Not found"
    print(f"C reference: {c_ref_hex}")

except Exception as e:
    print(f"❌ from_dict failed: {e}")
    import traceback

    traceback.print_exc()
