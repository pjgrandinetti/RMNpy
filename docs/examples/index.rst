Examples Gallery
================

Interactive examples and tutorials for using RMNpy with the actual working API.

Basic Usage Examples
--------------------

**Working with the actual RMNpy API:**

These examples use the real, tested API that successfully compiles and runs:

.. code-block:: python

   import rmnpy

   # Basic object creation using actual API
   dataset = rmnpy.Dataset.create()
   dimension = rmnpy.Dimension.create()
   dependent_var = rmnpy.DependentVariable.create()
   datum = rmnpy.Datum.create()
   
   print("All RMNpy objects created successfully!")

Core Classes
~~~~~~~~~~~~

**Dataset Class**

.. code-block:: python

   # Create a dataset
   dataset = rmnpy.Dataset.create()
   print(f"Dataset: {dataset}")

**Dimension Class**

.. code-block:: python

   # Create a dimension
   dimension = rmnpy.Dimension.create()
   print(f"Dimension: {dimension}")

**DependentVariable Class**

.. code-block:: python

   # Create a dependent variable with SIQuantity inheritance
   dependent_var = rmnpy.DependentVariable.create()
   print(f"DependentVariable: {dependent_var}")
   # Units accessible through SIQuantity interface

**Datum Class**

.. code-block:: python

   # Create a datum
   datum = rmnpy.Datum.create()
   print(f"Datum: {datum}")

Auto-Generated Examples
-----------------------

**Interactive Gallery:**

Visit the :doc:`Examples Gallery <../auto_examples/index>` for automatically executed examples with live output.

   basic_usage

Quick Start Examples
--------------------

Here are some quick examples to get you started:

**Create a Dataset:**

.. code-block:: python

   import rmnpy
   
   # Create a basic dataset
   dataset = rmnpy.Dataset.create(title="My Experiment")
   print(dataset)

**Add Dimensions:**

.. code-block:: python

   from rmnpy import LinearDimension
   
   # Create a frequency dimension
   freq_dim = LinearDimension.create(
       label="frequency",
       count=1024,
       increment=100.0,
       unit="Hz"
   )
   dataset.add_dimension(freq_dim)

**Work with Data:**

.. code-block:: python

   import numpy as np
   from rmnpy import DependentVariable
   
   # Create some sample data
   data = np.random.random(1024)
   
   # Create dependent variable
   dep_var = DependentVariable.create(
       name="intensity",
       unit="arbitrary",
       data=data
   )
   dataset.add_dependent_variable(dep_var)
