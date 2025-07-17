Quickstart Guide
================

.. danger::
   **⚠️ STOP: DO NOT USE THIS CODE ⚠️**
   
   This quickstart guide is for **DEVELOPMENT PURPOSES ONLY**.
   
   - The API shown here **WILL CHANGE** without notice
   - Code examples may **NOT WORK** in current state
   - This is **NOT SUITABLE** for any real use
   - **DO NOT** build applications with this code
   
   This documentation exists only to guide ongoing development work.

----

This tutorial will get you up and running with RMNpy in just a few minutes using the actual working API.

Basic Imports
-------------

Start by importing the main RMNpy classes:

.. code-block:: python

   import rmnpy
   from rmnpy import Dataset, Datum, Dimension, DependentVariable

Creating Your First Dataset
----------------------------

The ``Dataset`` class represents a complete scientific dataset:

.. code-block:: python

   # Create a basic dataset using the actual API
   dataset = Dataset.create()
   print(f"Dataset created: {dataset}")

Working with Dimensions
-----------------------

Dimensions represent coordinate axes in your dataset. Each type has specific requirements:

.. code-block:: python

   import numpy as np
   
   # Linear dimension: evenly spaced coordinates
   linear_dim = rmnpy.Dimension.create_linear(
       count=100,           # Number of points
       increment=0.1,       # Spacing between points
       label="time",        # Optional label
       description="Time axis in seconds"
   )
   
   # Labeled dimension: explicit string/discrete labels  
   labels = ["sample_A", "sample_B", "sample_C", "sample_D"]
   labeled_dim = rmnpy.Dimension.create_labeled(
       labels,              # Required: list of labels
       label="samples",     # Optional dimension label
       description="Sample identifiers"
   )
   
   # Monotonic dimension: custom coordinates (requires SIScalar objects)
   # Note: For monotonic dimensions, you need SIScalar coordinate objects
   # This is a more advanced use case - see API documentation for details
   
   print(f"Linear dimension: {linear_dim}")
   print(f"Labeled dimension: {labeled_dim}")

Working with DependentVariables
-------------------------------

DependentVariables represent data arrays with comprehensive metadata:

.. code-block:: python

   import numpy as np
   
   # Create sample data
   data = np.array([1.0, 2.0, 3.0, 4.0, 5.0], dtype=np.float64)
   
   # Create a dependent variable with data and metadata
   dependent_var = rmnpy.DependentVariable.create(
       data,                        # Required: numpy array
       name="temperature",          # Optional: variable name
       description="Temperature measurements",  # Optional description
       units="K",                   # Optional: SI unit expression
       quantity_name="temperature", # Optional: physical quantity
       element_type="float64"       # Optional: data type
   )
   
   print(f"DependentVariable created: {dependent_var}")
   print(f"Data shape: {dependent_var.shape}")
   print(f"Name: {dependent_var.name}")
   print(f"Description: {dependent_var.description}")

Working with Datum Objects
--------------------------

Datum objects represent individual data points:

.. code-block:: python

   # Create a datum
   datum = Datum.create()
   print(f"Datum created: {datum}")

Complete Example
----------------

Here's a complete example using the working API:

Complete Example
----------------

Here's a complete example creating a realistic scientific dataset:

.. code-block:: python

   import numpy as np
   import rmnpy

   # Create sample experimental data
   time_data = np.linspace(0, 10, 100)  # 100 time points from 0 to 10 seconds
   temperature_data = 20 + 5 * np.sin(2 * np.pi * 0.1 * time_data)  # Oscillating temperature
   
   # Create a linear time dimension
   time_dim = rmnpy.Dimension.create_linear(
       count=100,
       increment=0.1,  # 0.1 second intervals
       label="time",
       description="Measurement time",
       quantity="time"
   )
   
   # Create a dependent variable for temperature data
   temperature_var = rmnpy.DependentVariable.create(
       temperature_data,
       name="temperature",
       description="Temperature measurements over time",
       units="°C",  # Celsius degrees
       quantity_name="temperature",
       quantity_type="scalar"
   )
   
   # Create experimental metadata using labeled dimension
   sample_labels = ["trial_1", "trial_2", "trial_3"]
   sample_dim = rmnpy.Dimension.create_labeled(
       sample_labels,
       label="trials",
       description="Experimental trial identifiers"
   )
   
   print("Complete scientific dataset created!")
   print(f"Time dimension: {time_dim} (count: {100})")
   print(f"Temperature variable: {temperature_var}")
   print(f"Data shape: {temperature_var.shape}")
   print(f"Sample dimension: {sample_dim}")

Real-World Usage Patterns
~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: python

   # Pattern 1: NULL behavior for optional parameters
   simple_var = rmnpy.DependentVariable.create(
       data,
       name=None,        # → C function leaves name unset
       description=None, # → C function leaves description unset  
       units=None       # → C function creates dimensionless unit
   )
   
   # Pattern 2: Multi-component data with labels
   vector_data = np.random.random((50, 3))  # 50 3D vectors
   velocity_var = rmnpy.DependentVariable.create(
       vector_data,
       name="velocity",
       description="3D velocity vectors",
       units="m/s",
       quantity_type="vector_3",
       component_labels=["vx", "vy", "vz"]
   )

Next Steps
----------

- Explore the :doc:`auto_examples/index` for more detailed examples
- Read the detailed :doc:`user_guide/index`
- Check the complete :doc:`api_reference/index`
