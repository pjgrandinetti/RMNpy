RMNpy API Reference
===================

This section contains the complete API reference for RMNpy, organized by module and functionality.

.. toctree::
   :maxdepth: 2
   :caption: Python API:

   sitypes
   rmnpy

Core Modules
------------

The RMNpy API is organized into two main layers:

1. **SITypes Wrappers** (:mod:`rmnpy.wrappers.sitypes`) - Physical units and dimensional analysis
2. **User API** (:mod:`rmnpy`) - High-level Pythonic interfaces (planned)

Quick Reference
---------------

Most common operations:

.. code-block:: python

   # SITypes - Physical units and dimensional analysis
   from rmnpy.wrappers.sitypes import Scalar, Unit, Dimensionality

   # Create physical quantities (clean, consistent syntax)
   distance = Scalar("100.0 m")         # 100 meters
   time = Scalar("5.0 s")               # 5 seconds
   velocity = distance / time           # 20.0 m/s

   # Unit conversion
   velocity_kmh = velocity.convert_to("km/h")  # 72.0 km/h

   # Work with units when needed
   meter_unit = Unit("m")

   # Advanced dimensional analysis
   force_dim = Dimensionality("M*L/T^2")  # Force dimension

All exceptions include descriptive error messages to help with debugging.
