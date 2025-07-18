RMNpy Documentation
===================

.. warning::
   **🚧 DEVELOPMENT STATUS: ALPHA - NOT READY FOR USE 🚧**
   
   **⚠️ This project is in early development and is NOT suitable for production use.**
   
   - API is unstable and subject to major changes
   - Many features are incomplete or untested  
   - Documentation may be outdated or incorrect
   - Breaking changes will occur without notice
   - **DO NOT USE** in any production environment
   
   This documentation is shared for development purposes only. Check back later for stable releases.

----

RMNpy is a Python wrapper for the RMNLib C library, providing access to Core Scientific Dataset Model (CSDM) functionality from Python.
It enables Python developers to work with multidimensional scientific datasets using a clean, Pythonic interface while maintaining the performance of the underlying C implementation.

**Current Implementation Status**

✅ **Implemented Classes:**

- ``Dataset``: Complete scientific dataset with metadata and structure
- ``Dimension``: Coordinate axes (linear, labeled, monotonic)  
- ``DependentVariable``: Data variables with units (inherits from SIQuantity)
- ``Datum``: Individual data points with coordinates and response values

� **Available in RMNLib but not yet wrapped in RMNpy:**

- ``SparseSampling``: Non-uniform, non-Cartesian sampling layouts
- ``GeographicCoordinate``: Geographic location data with lat/lon/altitude
- ``RMNGridUtils``: Grid utility functions

*Note: These classes are fully implemented and tested in the underlying RMNLib C library, 
but the Python wrapper code has not been written yet.*

Requirements
~~~~~~~~~~~~

Ensure you have installed:

- Python 3.8 or later
- NumPy
- Cython (for building from source)
- A C compiler (e.g., clang or gcc)

Building and Installation
~~~~~~~~~~~~~~~~~~~~~~~~~

Install from source::

    git clone https://github.com/pjgrandinetti/RMNpy.git
    cd RMNpy
    pip install -e .

Quick Start
~~~~~~~~~~~

Scientific Example - Complex NMR Data
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: python

   import numpy as np
   import rmnpy
   from rmnpy.sitypes import kSIQuantityTime, kSIQuantityFrequency

   # Generate complex NMR data (damped oscillation matching RMNLib examples)
   count = 1024
   frequency = 100.0    # Hz
   decay_rate = 50.0    # s⁻¹ (decay constant)
   
   time_axis = np.arange(count) * 1.0e-6  # 1 µs sampling interval
   amplitude = np.exp(-decay_rate * time_axis)
   phase = 2.0 * np.pi * frequency * time_axis
   complex_data = amplitude * (np.cos(phase) + 1j * np.sin(phase))

   # Create time dimension with physical quantities
   time_dim = rmnpy.Dimension.create_linear(
       label="time",
       count=count,
       increment="1.0 µs",           # String expression like RMNLib C API
       quantity_name=kSIQuantityTime,   # Explicit quantity constant
       description="NMR acquisition time axis"
   )

   # Create dependent variable for NMR signal
   signal_var = rmnpy.DependentVariable.create(
       name="nmr_signal",
       description="Complex NMR signal with T2 decay",
       unit="V",
       data=complex_data
   )

   # Create complete scientific dataset
   dataset = rmnpy.Dataset.create(
       title="Complex NMR Experiment", 
       description="Damped oscillation typical of NMR/ESR spectroscopy",
       dimensions=[time_dim],
       dependent_variables=[signal_var]
   )
   
   print(f"Created dataset: {dataset.title}")

Basic Usage Example
^^^^^^^^^^^^^^^^^^^

.. code-block:: python

   import numpy as np
   import rmnpy

   # Simple example for getting started
   data = np.array([1.0, 2.0, 3.0, 4.0, 5.0], dtype=np.float64)
   
   # Create a dependent variable with data and metadata
   dependent_var = rmnpy.DependentVariable.create(
       data,
       name="temperature",
       description="Temperature measurements",
       units="K"
   )
   
   # Create a linear time dimension
   time_dim = rmnpy.Dimension.create_linear(
       count=100,
       increment=0.1,
       label="time",
       description="Time axis"
   )
   
   # Create a labeled dimension
   labels = ["sample_A", "sample_B", "sample_C"] 
   sample_dim = rmnpy.Dimension.create_labeled(
       labels,
       label="samples",
       description="Sample identifiers"
   )
   
   print("RMNpy objects created successfully!")
   print(f"DependentVariable: {dependent_var.name}")
   print(f"Linear dimension: {time_dim}")
   print(f"Labeled dimension: {sample_dim}")

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   installation
   quickstart
   user_guide/index
   api_reference/index
   examples/index
   auto_examples/index
   changelog

Installation
~~~~~~~~~~~~
Complete installation instructions for different platforms and use cases.

Quick Start Guide  
~~~~~~~~~~~~~~~~~
Get up and running with RMNpy in minutes with practical examples.

User Guide
~~~~~~~~~~
Comprehensive tutorials covering all major features:

- Working with Datasets and Dimensions
- Managing Scientific Data
- Advanced CSDM Operations

API Reference
~~~~~~~~~~~~~
Complete technical documentation for all classes and functions.

Examples Gallery
~~~~~~~~~~~~~~~~
Interactive examples with live code execution and visualization.

🔗 Links
---------

- **GitHub Repository**: https://github.com/pjgrandinetti/RMNpy
- **RMNLib C Library**: https://github.com/pjgrandinetti/RMNLib
- **PyPI Package**: https://pypi.org/project/rmnpy/ (coming soon)
- **Read the Docs**: https://rmnpy.readthedocs.io

📄 License
-----------

RMNpy is released under the MIT License. See the `LICENSE <https://github.com/pjgrandinetti/RMNpy/blob/main/LICENSE>`__ file for details.
