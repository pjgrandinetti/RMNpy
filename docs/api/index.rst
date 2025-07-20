RMNpy API Reference
===================

This section contains the complete API reference for RMNpy, organized by module and functionality.

.. toctree::
   :maxdepth: 2
   :caption: Python API:

   rmnpy
   helpers
   c_api

Core Modules
------------

The RMNpy API is organized into three main layers:

1. **User API** (:mod:`rmnpy`) - High-level Pythonic interfaces
2. **Helpers** (:mod:`rmnpy.helpers`) - Memory management and utilities  
3. **C API** (:mod:`rmnpy._c_api`) - Low-level C library bindings

Quick Reference
---------------

Most common operations:

.. code-block:: python

   import rmnpy as rmn
   
   # Arrays and collections
   array = rmn.Array([1, 2, 3, 4, 5])
   dictionary = rmn.Dictionary({'key': 'value'})
   
   # Physical quantities with units
   length = rmn.SIQuantity(5.0, rmn.SI.meter)
   energy = rmn.SIQuantity(2.1, rmn.SI.electronvolt)
   
   # Memory management
   with rmn.AutoreleasePool():
       # All objects automatically managed
       result = perform_calculations()

Error Handling
--------------

RMNpy uses standard Python exceptions:

- :exc:`TypeError` - Unit incompatibility or type mismatches
- :exc:`ValueError` - Invalid values or parameters
- :exc:`MemoryError` - Memory allocation failures
- :exc:`RuntimeError` - C library errors

All exceptions include descriptive error messages to help with debugging.
