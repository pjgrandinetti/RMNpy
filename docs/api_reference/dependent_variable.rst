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

   import rmnpy

   # Create a new dependent variable
   dependent_var = rmnpy.DependentVariable.create()
   print(f"DependentVariable created: {dependent_var}")

Accessing Units
~~~~~~~~~~~~~~~

Units are accessible through the SIQuantity inheritance:

.. code-block:: python

   # DependentVariable inherits from SIQuantity
   # Units can be accessed through the SIQuantity interface
   dependent_var = rmnpy.DependentVariable.create()
   
   # Unit access through inherited SIQuantity functionality
   # (specific methods available through SIQuantity interface)

Notes
-----

The DependentVariable class inherits from SIQuantity, which provides unit handling
functionality. This design allows access to units through the established SIQuantity
interface rather than direct DependentVariable methods.
