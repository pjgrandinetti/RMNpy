"""
Basic RMNpy Example
===================

A simple example demonstrating basic RMNpy functionality.
"""

print("Hello from RMNpy Gallery!")

# Simple demonstration that doesn't require complex imports
import sys
print(f"Python version: {sys.version_info.major}.{sys.version_info.minor}")

# Create some basic data
import numpy as np
x = np.linspace(0, 10, 100)
y = np.sin(x)

print(f"Created data arrays with {len(x)} points")
print("Example completed successfully!")
