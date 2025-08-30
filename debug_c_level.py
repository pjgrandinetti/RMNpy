#!/usr/bin/env python3
"""Debug script to test C API step by step with debugging."""

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

print("=== Original Dimension ===")
print(f"Original application: {original.application}")

# Test from_dict
dim_dict = original.dict()
print("\n=== Dictionary Representation ===")
print(json.dumps(dim_dict, indent=2))
print()

print("=== Creating from Dictionary ===")
restored = BaseDimension.from_dict(dim_dict)
print(f"Restored application: {restored.application}")

# Compare all properties
print("\n=== Property Comparison ===")
print(f"Label:       Original: {original.label:<20} Restored: {restored.label}")
print(
    f"Description: Original: {original.description:<20} Restored: {restored.description}"
)
print(f"Type:        Original: {original.type:<20} Restored: {restored.type}")
print(
    f"Application: Original: {original.application}  Restored: {restored.application}"
)

# Check if the problem is the application property implementation
print("\n=== Testing Different Applications ===")
# Test setting application on the restored object
try:
    restored.application = {"test": "value"}
    print(f"After setting: {restored.application}")

    # Test setting it back to original value
    restored.application = {"encoding": "sRGB"}
    print(f"After setting original: {restored.application}")
except Exception as e:
    print(f"Error setting application: {e}")
