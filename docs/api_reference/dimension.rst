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

   # Create a linear dimension
   dimension = rmnpy.Dimension.create_linear()
   print(f"Linear dimension created: {dimension}")

Labeled Dimension
~~~~~~~~~~~~~~~~~

.. code-block:: python

   # Create a labeled dimension
   dimension = rmnpy.Dimension.create_labeled()
   print(f"Labeled dimension created: {dimension}")

Monotonic Dimension
~~~~~~~~~~~~~~~~~~~

.. code-block:: python

   # Create a monotonic dimension
   dimension = rmnpy.Dimension.create_monotonic()
   print(f"Monotonic dimension created: {dimension}")

Notes
-----

The Dimension class provides three creation methods for different types of coordinate axes:
- `create_linear()`: For evenly spaced coordinates
- `create_labeled()`: For explicitly labeled coordinates  
- `create_monotonic()`: For monotonically increasing/decreasing coordinates
