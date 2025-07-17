DependentVariable
=================

The DependentVariable class represents data variables with units and metadata.
It inherits from SIQuantity, providing access to unit functionality.

Class Reference
---------------

.. currentmodule:: rmnpy

.. autoclass:: DependentVariable
   :members:

   .. automethod:: create

Usage Examples
--------------

Basic Usage
~~~~~~~~~~~

.. code-block:: python

   import numpy as np
   import rmnpy

   # Create a dependent variable with data
   data = np.array([1.0, 2.0, 3.0, 4.0, 5.0], dtype=np.float64)
   dependent_var = rmnpy.DependentVariable.create(
       data,                    # Required: numpy array of data
       name="temperature",      # Optional: variable name  
       description="Temperature measurements over time",  # Optional
       units="K",              # Optional: SI unit expression (e.g., "K", "m/s")
       quantity_name="temperature",  # Optional: logical quantity name
       quantity_type="scalar",  # Optional: "scalar", "vector_3", etc.
       element_type="float64"   # Optional: data type
   )
   print(f"DependentVariable created: {dependent_var}")

Advanced Usage
~~~~~~~~~~~~~~

.. code-block:: python

   # Create with component labels for multi-component data
   vector_data = np.array([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]], dtype=np.float64)
   dependent_var = rmnpy.DependentVariable.create(
       vector_data,
       name="velocity",
       description="3D velocity vectors", 
       units="m/s",
       quantity_name="velocity",
       quantity_type="vector_3",
       component_labels=["vx", "vy", "vz"]
   )

NULL Behavior
~~~~~~~~~~~~~

The create method respects the NULL parameter behavior of the underlying C API:

.. code-block:: python

   # When optional parameters are None, C function applies appropriate defaults
   dependent_var = rmnpy.DependentVariable.create(
       data,
       name=None,          # → C function leaves name unset
       description=None,   # → C function leaves description unset  
       units=None         # → C function creates dimensionless unit
   )

Notes
-----

The DependentVariable class provides data storage with comprehensive metadata support:

**Key Features:**
- **Full C API Integration**: Uses `DependentVariableCreate` (9-parameter function) instead of simplified defaults
- **NULL Behavior Preservation**: Respects the C function's sophisticated NULL parameter handling  
- **Data Type Support**: Handles various numpy data types (float64, float32, int32, etc.)
- **Component Support**: Multi-component data with optional component labels
- **Unit Integration**: SI unit expressions automatically parsed and validated
- **Memory Management**: Proper OCData conversion and cleanup for numpy arrays

**Data Parameter:** 
The `data` parameter is required and accepts numpy arrays or array-like objects. The data is converted to OCData objects for the underlying C implementation.

**Recent Improvements:**
The `create` method has been updated to use the full `DependentVariableCreate` C API function with proper numpy array to OCData conversion, ensuring complete compatibility with the C library while providing a convenient Python interface.
