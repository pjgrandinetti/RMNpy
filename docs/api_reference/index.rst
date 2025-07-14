API Reference
=============

Complete API documentation for all RMNpy classes and functions.

Module Overview
---------------

RMNpy provides a clean, object-oriented interface to the RMNLib C library through several key modules:

Core Module (``rmnpy.core``)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The core module contains the main classes for working with scientific datasets:

- ``Dataset``: Complete scientific dataset with metadata and structure
- ``Datum``: Individual data points with coordinates and response values  
- ``Dimension``: Coordinate axes (labeled, SI, monotonic, linear)
- ``DependentVariable``: Data variables with units and metadata

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

Exception Classes
~~~~~~~~~~~~~~~~~

.. autosummary::
   :toctree: generated/

   RMNLibError
