Datum
=====

The Datum class represents individual data points with coordinates and response values.

Class Reference
---------------

.. currentmodule:: rmnpy

.. autoclass:: Datum
   :members:

   .. automethod:: create

Usage Examples
--------------

Basic Usage
~~~~~~~~~~~

.. code-block:: python

   import rmnpy

   # Create a new datum
   datum = rmnpy.Datum.create()
   print(f"Datum created: {datum}")

Notes
-----

The Datum class provides functionality for working with individual data points
in scientific datasets.
