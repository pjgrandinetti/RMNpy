Basic Usage
===========

This example demonstrates the fundamental operations in RMNpy, aligned with RMNLib C API patterns.

Creating a Scientific Dataset
-----------------------------

.. code-block:: python

   import rmnpy
   import numpy as np
   from rmnpy import Dataset, Dimension, DependentVariable
   from rmnpy.sitypes import kSIQuantityTime, kSIQuantityFrequency, kSIQuantityElectricPotential

   # Create a dataset with scientific metadata
   dataset = Dataset.create(
       title="Complex NMR Experiment",
       description="Damped oscillation typical of NMR/ESR spectroscopy"
   )
   
   print(f"Created dataset: {dataset.title}")

Generating Complex NMR Data
---------------------------

.. code-block:: python

   # Generate damped complex oscillation data (matching RMNLib example)
   count = 1024
   frequency = 100.0    # Hz  
   decay_rate = 50.0    # s⁻¹ (decay constant)
   
   # Generate time axis and complex oscillating data
   time_axis = np.arange(count) * 1.0e-6  # 1 µs sampling interval
   amplitude = np.exp(-decay_rate * time_axis)
   phase = 2.0 * np.pi * frequency * time_axis
   complex_data = amplitude * (np.cos(phase) + 1j * np.sin(phase))

Adding Scientific Dimensions  
----------------------------

.. code-block:: python

   # Create a time dimension with proper physical quantities
   time_dim = Dimension.create_linear(
       label="time",
       count=count,
       increment="1.0 µs",           # String expression like C API
       quantity_name=kSIQuantityTime,   # Explicit quantity name
       description="Time axis for NMR acquisition"
   )
   
   dataset.add_dimension(time_dim)
   print(f"Added dimension: {time_dim.label}")

Adding Scientific Data
----------------------

.. code-block:: python

   # Create dependent variable for complex NMR signal
   signal_var = DependentVariable.create(
       data=complex_data,
       name="nmr_signal",
       description="Complex NMR signal with T2 decay",
       units="V",  # Voltage units
       quantity_name=kSIQuantityElectricPotential,  # Required for C API
       quantity_type="scalar",  # Required for C API
       element_type="complex128"  # Required for C API
   )
   
   dataset.add_dependent_variable(signal_var)
   print(f"Added variable: {signal_var.name}")

T1 Inversion Recovery Example
-----------------------------

.. code-block:: python

   # T1 inversion recovery with non-uniform time spacing (6 orders of magnitude)
   recovery_times = [
       "10.0 µs", "50.0 µs", "100.0 µs", "500.0 µs",
       "1.0 ms", "5.0 ms", "10.0 ms", "50.0 ms", 
       "100.0 ms", "500.0 ms", "1.0 s", "5.0 s", "10.0 s"
   ]
   
   # Create monotonic time dimension
   t1_recovery_dim = Dimension.create_monotonic(
       coordinates=recovery_times,
       label="recovery_time", 
       quantity_name=kSIQuantityTime,
       description="T1 inversion recovery time points"
   )
       unit="arbitrary",
       data=data
   )
   
   dataset.add_dependent_variable(intensity)
   print(f"Added variable: {intensity.name}")

Accessing Data
--------------

.. code-block:: python

   # Access dataset properties
   print(f"Dataset has {len(dataset.dimensions)} dimension(s)")
   print(f"Dataset has {len(dataset.dependent_variables)} variable(s)")
   
   # Get the data
   data_array = dataset.dependent_variables[0].components[0].quantity
   print(f"Data shape: {data_array.shape}")
   print(f"Data type: {data_array.dtype}")

This example shows the basic workflow for creating and manipulating datasets in RMNpy.
