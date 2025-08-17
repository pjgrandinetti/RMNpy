# Google Colab Installation Fix

If you're experiencing import errors in Google Colab when trying to use RMNpy, such as:

```
ImportError: libOCTypes.so: cannot open shared object file: No such file or directory
```

This is a known issue where Google Colab's pip installation doesn't properly extract all shared libraries from the wheel.

## Quick Fix

Run this one-liner in your Google Colab notebook:

```python
import rmnpy; rmnpy.quick_fix()
```

## Detailed Fix

For more detailed diagnostics and step-by-step repair:

```python
import rmnpy
rmnpy.colab_install_fix()
```

## What the Fix Does

1. **Diagnoses** the installation to identify missing shared libraries
2. **Downloads** the appropriate wheel for your Python version
3. **Extracts** the missing libraries and places them in the correct location
4. **Tests** the installation to ensure everything works

## After Running the Fix

Once the fix completes successfully, you can use RMNpy normally:

```python
from rmnpy.sitypes import Scalar, Unit, Dimensionality

# Create scalars with units
distance = Scalar("5.0 m")
time = Scalar("2.0 s")
velocity = distance / time

print(f"Velocity: {velocity}")  # Output: Velocity: 2.5 m/s
```

## Supported Python Versions

The fix automatically detects your Python version and downloads the compatible wheel:
- Python 3.9
- Python 3.10
- Python 3.11
- Python 3.12

## Alternative Installation

If the automatic fix doesn't work, you can try installing from the specific wheel URL:

```python
# For Python 3.11 (adjust version as needed)
!pip install https://github.com/pjgrandinetti/RMNpy/releases/download/v0.1.6/rmnpy-0.1.6-cp311-cp311-manylinux_2_38_x86_64.whl --force-reinstall
```

## Troubleshooting

If you continue to experience issues:

1. Make sure you're using a supported Python version
2. Try restarting your Colab runtime
3. Check that you have sufficient disk space
4. Report the issue on the [RMNpy GitHub repository](https://github.com/pjgrandinetti/RMNpy/issues)

## Technical Details

This issue occurs because Google Colab's environment has specific restrictions on shared library installation. The fix works by:

1. Detecting missing shared libraries (`libOCTypes.so`, `libSITypes.so`, `libRMN.so`)
2. Downloading the original wheel file from GitHub releases
3. Extracting only the missing libraries
4. Installing them with proper permissions in the package directory

The fix is safe and only affects the current Colab session. It doesn't modify the underlying system or other packages.
