Dataset
=======

The Dataset class represents a complete scientific dataset following the Core Scientific Dataset Model (CSDM) specification.

Class Reference
---------------

.. currentmodule:: rmnpy

.. autoclass:: Dataset
   :members:

   .. automethod:: create

Usage Examples
--------------

Basic Usage
~~~~~~~~~~~

.. code-block:: python

   import rmnpy

   # Create a new dataset
   dataset = rmnpy.Dataset.create()
   print(f"Dataset created: {dataset}")

Notes
-----

The Dataset class provides the main interface for working with scientific datasets in RMNpy.
It wraps the underlying RMNLib C library functionality with a Pythonic interface.
