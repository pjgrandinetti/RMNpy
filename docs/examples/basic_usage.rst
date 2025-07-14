Basic Usage
===========

This example demonstrates the fundamental operations in RMNpy.

Creating a Dataset
------------------

.. code-block:: python

   import rmnpy
   from rmnpy import Dataset, LinearDimension, DependentVariable
   import numpy as np

   # Create a dataset with metadata
   dataset = Dataset.create(
       title="Basic RMNpy Example",
       description="Demonstrating core functionality"
   )
   
   print(f"Created dataset: {dataset.title}")

Adding Dimensions
-----------------

.. code-block:: python

   # Create a frequency dimension
   frequency_dim = LinearDimension.create(
       label="frequency",
       count=512,
       increment=50.0,
       unit="Hz",
       origin=0.0
   )
   
   dataset.add_dimension(frequency_dim)
   print(f"Added dimension: {frequency_dim.label}")

Adding Data
-----------

.. code-block:: python

   # Generate sample data
   data = np.sin(np.linspace(0, 4*np.pi, 512)) + 0.1 * np.random.random(512)
   
   # Create dependent variable
   intensity = DependentVariable.create(
       name="intensity",
       unit="arbitrary",
       data=data
   )
   
   dataset.add_dependent_variable(intensity)
   print(f"Added variable: {intensity.name}")

Accessing Data
--------------

.. code-block:: python

   # Access dataset properties
   print(f"Dataset has {len(dataset.dimensions)} dimension(s)")
   print(f"Dataset has {len(dataset.dependent_variables)} variable(s)")
   
   # Get the data
   data_array = dataset.dependent_variables[0].components[0].quantity
   print(f"Data shape: {data_array.shape}")
   print(f"Data type: {data_array.dtype}")

This example shows the basic workflow for creating and manipulating datasets in RMNpy.
