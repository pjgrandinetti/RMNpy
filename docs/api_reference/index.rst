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

Core Module (``rmnpy.core``) - **Currently Implemented**
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The core module contains the main classes for working with scientific datasets:

- :doc:`dataset`: Complete scientific dataset with metadata and structure
- :doc:`datum`: Individual data points with coordinates and response values  
- :doc:`dimension`: Coordinate axes (labeled, SI, monotonic, linear)
- :doc:`dependent_variable`: Data variables with units and metadata (inherits from SIQuantity)

**Available in RMNLib but not yet wrapped in RMNpy**
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

These classes are fully implemented and tested in the underlying RMNLib C library,
but have not yet been wrapped for Python:

- ``SparseSampling``: For non-uniform, non-Cartesian sampling layouts
- ``GeographicCoordinate``: Geographic location data with latitude/longitude/altitude
- ``RMNGridUtils``: Grid utility and manipulation functions

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
