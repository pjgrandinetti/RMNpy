Examples Gallery
================

Interactive examples and tutorials for using RMNpy effectively.

Interactive Examples Gallery
-----------------------------

**Executable examples with automatic output generation:**

The :doc:`Examples Gallery <../auto_examples/index>` provides interactive examples that are automatically executed and documented. Each example includes:

- ✅ **Live code execution** with real output
- 📊 **Generated plots and figures** (when applicable)  
- 📥 **Downloadable Python scripts**
- 📓 **Auto-generated Jupyter notebooks**
- 🚀 **One-click Binder launch** for cloud execution

Featured Gallery Examples
~~~~~~~~~~~~~~~~~~~~~~~~~

- :doc:`Installation and Basic Usage <../auto_examples/plot_01_installation_basic_usage>` - Get started with RMNpy
- :doc:`NMR Spectroscopy <../auto_examples/plot_02_nmr_spectroscopy>` - Complete NMR workflow examples

Static Examples
---------------

.. toctree::
   :maxdepth: 2

   basic_usage

Quick Start Examples
--------------------

Here are some quick examples to get you started:

**Create a Dataset:**

.. code-block:: python

   import rmnpy
   
   # Create a basic dataset
   dataset = rmnpy.Dataset.create(title="My Experiment")
   print(dataset)

**Add Dimensions:**

.. code-block:: python

   from rmnpy import LinearDimension
   
   # Create a frequency dimension
   freq_dim = LinearDimension.create(
       label="frequency",
       count=1024,
       increment=100.0,
       unit="Hz"
   )
   dataset.add_dimension(freq_dim)

**Work with Data:**

.. code-block:: python

   import numpy as np
   from rmnpy import DependentVariable
   
   # Create some sample data
   data = np.random.random(1024)
   
   # Create dependent variable
   dep_var = DependentVariable.create(
       name="intensity",
       unit="arbitrary",
       data=data
   )
   dataset.add_dependent_variable(dep_var)
