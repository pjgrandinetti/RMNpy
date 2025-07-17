Core Module
===========

The core module provides the main classes for working with scientific datasets in the CSDM format.

.. currentmodule:: rmnpy

Currently Implemented Classes
-----------------------------

Dataset Class
~~~~~~~~~~~~~

The Dataset class represents a complete scientific dataset with metadata, dimensions, and dependent variables.

.. autosummary::
   :toctree: generated/

   Dataset
   Dataset.create

Dimension Class
~~~~~~~~~~~~~~~

The Dimension class represents coordinate axes for scientific data.

.. autosummary::
   :toctree: generated/

   Dimension
   Dimension.create_linear
   Dimension.create_labeled
   Dimension.create_monotonic

DependentVariable Class
~~~~~~~~~~~~~~~~~~~~~~~

The DependentVariable class represents data variables with units and metadata. 
Units are accessed through the SIQuantity inheritance interface.

.. autosummary::
   :toctree: generated/

   DependentVariable
   DependentVariable.create

Datum Class
~~~~~~~~~~~

The Datum class represents individual data points with coordinates and response values.

.. autosummary::
   :toctree: generated/

   Datum
   Datum.create

Available in RMNLib but not yet wrapped
---------------------------------------

The following classes are fully implemented and tested in the underlying RMNLib C library,
but have not yet been wrapped for Python:

- **SparseSampling**: Non-uniform, non-Cartesian sampling layouts
- **GeographicCoordinate**: Geographic location data with latitude/longitude/altitude  
- **RMNGridUtils**: Grid utility functions

These will be added to RMNpy in future releases.

   Datum
   DependentVariable
