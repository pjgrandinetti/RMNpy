Exceptions
==========

RMNpy defines several custom exception classes for error handling.

.. currentmodule:: rmnpy

Exception Classes
-----------------

.. autosummary::
   :toctree: generated/

   RMNLibError

Error Handling
--------------

RMNpy exceptions provide detailed information about errors that occur during:

- Dataset creation and manipulation
- File I/O operations  
- Data validation
- Memory allocation

Example usage:

.. code-block:: python

   try:
       dataset = Dataset.create()
       # ... operations ...
   except RMNLibError as e:
       print(f"RMNpy error: {e}")
   except Exception as e:
       print(f"Unexpected error: {e}")
