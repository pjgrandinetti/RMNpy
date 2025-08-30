#!/usr/bin/env python3
"""Debug script to inspect the JSON conversion and C API calls step by step."""

import json

from rmnpy.wrappers.rmnlib.dimension import BaseDimension, LabeledDimension

# Create a LabeledDimension with application metadata
labels = ["red", "green", "blue", "alpha"]
original = LabeledDimension(
    labels=labels,
    label="color_channel",
    description="RGBA color channels",
    application={"encoding": "sRGB"},
)

print("=== Original Dimension ===")
print(f"Application: {original.application}")
print()

# Convert to dictionary
dim_dict = original.dict()
print("=== Python Dictionary ===")
print(json.dumps(dim_dict, indent=2))
print()

# Test the actual from_dict method
print("=== Testing from_dict Method ===")
try:
    restored = BaseDimension.from_dict(dim_dict)
    print(f"Restored dimension type: {type(restored)}")
    print(f"Restored application: {restored.application}")

    if restored.application == original.application:
        print("✅ from_dict preserves application metadata")
    else:
        print("❌ from_dict loses application metadata")
        print(f"Original: {original.application}")
        print(f"Restored: {restored.application}")

        # Let's check if the issue is in the property access
        # Try to access application directly from C API
        print("\n=== Debugging Application Property ===")
        print(f"Original type: {original.type}")
        print(f"Restored type: {restored.type}")
        print(f"Original label: {original.label}")
        print(f"Restored label: {restored.label}")
        print(f"Original description: {original.description}")
        print(f"Restored description: {restored.description}")

except Exception as e:
    print(f"❌ from_dict failed: {e}")
    import traceback

    traceback.print_exc()
