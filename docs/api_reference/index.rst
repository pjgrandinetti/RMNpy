API Reference
=============

Complete API documentation for all RMNpy classes and functions.

.. toctree::
   :maxdepth: 2

   core
   dataset
   dimension
   dependent_variable
   datum
   exceptions
   types

Module Overview
---------------

RMNpy provides a clean, object-oriented interface to the RMNLib C library through several key modules:

Core Module (``rmnpy.core``)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The core module contains the main classes for working with scientific datasets:

- :doc:`dataset`: Complete scientific dataset with metadata and structure
- :doc:`datum`: Individual data points with coordinates and response values  
- :doc:`dimension`: Coordinate axes (labeled, SI, monotonic, linear)
- :doc:`dependent_variable`: Data variables with units and metadata (inherits from SIQuantity)

Exceptions Module (``rmnpy.exceptions``)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Exception classes for robust error handling:

- ``RMNLibError``: Base exception for all RMNLib errors

Types Module (``rmnpy.types``)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Type definitions and enumerations:

- ``DimensionType``: Enumeration of dimension types
- ``DataType``: Enumeration of data types
- Common type aliases and constants

Quick Reference
---------------

Most Common Classes
~~~~~~~~~~~~~~~~~~~

.. currentmodule:: rmnpy

.. autosummary::
   :toctree: generated/

   Dataset
   Dimension
   Datum
   DependentVariable
   DependentVariable

Exception Classes
~~~~~~~~~~~~~~~~~

.. autosummary::
   :toctree: generated/

   RMNLibError
