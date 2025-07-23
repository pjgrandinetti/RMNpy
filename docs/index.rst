Welcome to RMNpy's documentation!
====================================

RMNpy is a Python library that provides high-level bindings for scientific computing with units and dataset management. It is built on top of the `SITypes`_ and `RMNLib`_ C libraries, using `OCTypes`_ as the underlying foundation for memory management and data structures.

.. _OCTypes: https://github.com/drpjkgrandinetti/OCTypes
.. _SITypes: https://github.com/drpjkgrandinetti/SITypes  
.. _RMNLib: https://github.com/drpjkgrandinetti/RMNLib

Overview
--------

RMNpy provides Python access to two specialized C libraries:

- **SITypes**: Scientific units and physical constants with automatic unit conversion
- **RMNLib**: Core Scientific Dataset Model (CSDM) file handling and multidimensional scientific data

The library uses OCTypes internally for memory management and data structures, but this is transparent to users.

Key Features
~~~~~~~~~~~~

* **Memory Management**: Automatic memory management (transparent to users)
* **Unit Safety**: Comprehensive unit checking and automatic conversions via SITypes
* **Scientific Data**: CSDM format support for multidimensional scientific datasets
* **Pythonic Interface**: Clean, intuitive API that follows Python conventions
* **Type Safety**: Strong typing support with comprehensive error handling

Installation
------------

RMNpy requires Python 3.8+ and can be installed from source:

.. code-block:: bash

   git clone https://github.com/drpjkgrandinetti/RMNpy.git
   cd RMNpy
   conda env create -f environment-dev.yml
   conda activate rmnpy-dev
   make synclib  # Sync C libraries
   pip install -e .

.. note::
   RMNpy is currently in development. The Python API is not yet implemented.
   This documentation describes the planned interface and underlying C libraries.

User Guide
----------

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   background
   sitypes_demo
   
API Reference
-------------

The RMNpy API provides Python interfaces for scientific computing with units and datasets.

.. toctree::
   :maxdepth: 3
   :caption: API Documentation:

   api/index

C Libraries
-----------

.. note::
   Documentation for the underlying C libraries (OCTypes, SITypes, RMNLib) will be
   linked here as the integration is completed.

Development
-----------

.. note::
   Development documentation will be added as the project progresses.

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
