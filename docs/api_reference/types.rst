Type Definitions
================

RMNpy uses various type definitions for better type safety and documentation.

.. currentmodule:: rmnpy

Common Types
------------

RMNpy uses standard Python and NumPy types for most operations:

- **str**: Text strings for labels, descriptions, units
- **int**: Integer values for counts, indices  
- **float**: Floating point values for measurements, coordinates
- **complex**: Complex values for frequency domain data
- **numpy.ndarray**: N-dimensional arrays for bulk data storage

Data Types
----------

Scientific data in RMNpy can be:

**Real Data**
   Floating point measurements (temperatures, concentrations, etc.)

**Complex Data** 
   Complex-valued measurements (NMR frequency domain, etc.)

**Integer Data**
   Discrete measurements (counts, indices, etc.)

Unit Types
----------

Units are represented as strings following standard scientific notation:

- **Frequency**: "Hz", "kHz", "MHz", "GHz"
- **Time**: "s", "ms", "μs", "ns"  
- **Magnetic Field**: "T", "mT", "G"
- **Chemical Shift**: "ppm"
- **Temperature**: "K", "°C"

Example:

.. code-block:: python

   import numpy as np
   from rmnpy import LinearDimension
   
   # Create dimension with proper types
   freq_dim = LinearDimension.create(
       label="frequency",        # str
       count=1024,              # int
       increment=100.0,         # float
       unit="Hz"                # str
   )
   
   # Data arrays use numpy types
   data = np.random.random(1024).astype(np.float64)
   complex_data = data + 1j * np.random.random(1024)
