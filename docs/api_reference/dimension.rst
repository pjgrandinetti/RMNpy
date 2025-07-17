Dimension
=========

The Dimension class represents coordinate axes for scientific data.

Class Reference
---------------

.. currentmodule:: rmnpy

.. autoclass:: Dimension
   :members:

   .. automethod:: create_linear
   .. automethod:: create_labeled
   .. automethod:: create_monotonic

Usage Examples
--------------

Linear Dimension
~~~~~~~~~~~~~~~~

.. code-block:: python

   import rmnpy

   # Create a linear dimension with evenly spaced coordinates
   dimension = rmnpy.Dimension.create_linear(
       count=100,           # Number of points
       increment=1.0,       # Spacing between points  
       label="time",        # Optional label
       description="Time axis",  # Optional description
       quantity="time"      # Physical quantity
   )
   print(f"Linear dimension created: {dimension}")

Labeled Dimension
~~~~~~~~~~~~~~~~~

.. code-block:: python

   # Create a labeled dimension with explicit coordinate labels
   labels = ["sample1", "sample2", "sample3", "sample4"]
   dimension = rmnpy.Dimension.create_labeled(
       labels,              # Required: list of coordinate labels
       label="samples",     # Optional dimension label
       description="Sample identifiers"  # Optional description
   )
   print(f"Labeled dimension created: {dimension}")

Monotonic Dimension
~~~~~~~~~~~~~~~~~~~

.. code-block:: python

   # Create a monotonic dimension with custom coordinates
   # Note: coordinates must be SIScalar objects with appropriate units
   coordinates = [...]  # List of SIScalar objects
   dimension = rmnpy.Dimension.create_monotonic(
       coordinates,         # Required: list of SIScalar coordinates (≥2)
       label="frequency",   # Optional label  
       description="Frequency points",  # Optional description
       quantity="frequency",  # Physical quantity
       periodic=False       # Whether dimension is periodic
   )
   print(f"Monotonic dimension created: {dimension}")

Notes
-----

The Dimension class provides three creation methods for different types of coordinate axes:

- **`create_linear()`**: For evenly spaced coordinates with specified count and increment. Uses `SILinearDimensionCreate` C API.
- **`create_labeled()`**: For explicitly labeled coordinates (strings or discrete values). Uses `SILabeledDimensionCreate` C API. 
- **`create_monotonic()`**: For monotonically increasing/decreasing coordinates with custom spacing. Uses `SIMonotonicDimensionCreate` C API.

All methods preserve the NULL parameter handling behavior of their respective C API functions, allowing the underlying C implementation to apply appropriate defaults when optional parameters are `None`.

**Recent Improvements:**
All dimension creation methods have been updated to:

- Use the full C API functions (not simplified defaults)
- Match the exact parameter signatures of their C counterparts  
- Remove Python convenience parameters that don't exist in the C API
- Preserve sophisticated NULL handling behavior of the C functions
- Include comprehensive parameter validation and error handling
