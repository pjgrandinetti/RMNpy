Quickstart Guide
================

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

Dimensions represent coordinate axes in your dataset:

.. code-block:: python

   # Create different types of dimensions using actual API
   linear_dim = rmnpy.Dimension.create_linear()
   labeled_dim = rmnpy.Dimension.create_labeled()  
   monotonic_dim = rmnpy.Dimension.create_monotonic()
   
   print(f"Linear dimension: {linear_dim}")
   print(f"Labeled dimension: {labeled_dim}")
   print(f"Monotonic dimension: {monotonic_dim}")

Working with DependentVariables
-------------------------------

DependentVariables represent data with units, accessed through SIQuantity inheritance:

.. code-block:: python

   # Create a dependent variable
   dependent_var = DependentVariable.create()
   print(f"DependentVariable created: {dependent_var}")
   
   # Units are accessed through SIQuantity interface
   # (inherited functionality)

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
~~~~~~~~~~~~~~~~

.. code-block:: python

   import rmnpy

   # Create a complete dataset using actual API
   dataset = rmnpy.Dataset.create()
   
   # Create different types of dimensions
   linear_dim = rmnpy.Dimension.create_linear()
   labeled_dim = rmnpy.Dimension.create_labeled()
   monotonic_dim = rmnpy.Dimension.create_monotonic()
   
   # Create dependent variable and datum
   dependent_var = rmnpy.DependentVariable.create()
   datum = rmnpy.Datum.create()
   
   print("RMNpy objects created successfully!")
   print(f"Dataset: {dataset}")
   print(f"Linear dimension: {linear_dim}")
   print(f"DependentVariable: {dependent_var}")
   print(f"Datum: {datum}")

Next Steps
----------

- Explore the :doc:`auto_examples/index` for more detailed examples
- Read the detailed :doc:`user_guide/index`
- Check the complete :doc:`api_reference/index`
