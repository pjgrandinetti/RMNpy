Quickstart Guide
================

This tutorial will get you up and running with RMNpy in just a few minutes.

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

   # Create a basic dataset
   dataset = Dataset.create()
   print(f"Empty dataset: {dataset}")

   # Create a dataset with metadata
   dataset = Dataset.create(
       title="My NMR Experiment",
       description="1H NMR spectrum of benzene"
   )
   print(f"Dataset with metadata: {dataset}")

Working with Dimensions
-----------------------

Dimensions represent coordinate axes in your dataset:

.. code-block:: python

   # Create a frequency dimension
   frequency_dim = Dimension.create_linear(
       label="frequency",
       description="1H NMR frequency axis", 
       count=256,
       coordinates_offset=0.0,
       increment=10.0,
       unit="Hz"
   )

   print(f"Frequency dimension: {frequency_dim}")
   print(f"  Label: {frequency_dim.label}")
   print(f"  Count: {frequency_dim.count}")
   print(f"  Type: {frequency_dim.type}")

Next Steps
----------

- Explore the :doc:`examples/index`
- Read the detailed :doc:`user_guide/index`
- Check the complete :doc:`api_reference/index`
