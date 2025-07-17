Working with Datasets
=====================

The ``Dataset`` class is the central component of RMNpy, representing complete scientific datasets based on the Core Scientific Dataset Model (CSDM).

Creating Datasets
------------------

Basic Dataset Creation
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: python

   from rmnpy import Dataset

   # Create a dataset using the actual API
   dataset = Dataset.create()
   print(f"Dataset created: {dataset}")

Working with Dimensions
-----------------------

Dimensions represent coordinate axes in your dataset:

.. code-block:: python

   from rmnpy import Dimension

   # Create different types of dimensions
   linear_dim = Dimension.create_linear()
   labeled_dim = Dimension.create_labeled()
   monotonic_dim = Dimension.create_monotonic()
   
   print(f"Linear dimension: {linear_dim}")
   print(f"Labeled dimension: {labeled_dim}") 
   print(f"Monotonic dimension: {monotonic_dim}")

Working with DependentVariables
-------------------------------

DependentVariables represent the actual data with units and metadata:

.. code-block:: python

   from rmnpy import DependentVariable

   # Create a dependent variable
   dependent_var = DependentVariable.create()
   print(f"DependentVariable created: {dependent_var}")
   
   # Units are accessed through SIQuantity inheritance
   # The DependentVariable inherits from SIQuantity providing unit functionality

Working with Datum Objects
--------------------------

Datum objects represent individual data points:

.. code-block:: python

   from rmnpy import Datum

   # Create a datum
   datum = Datum.create()
   print(f"Datum created: {datum}")

Complete Workflow Example
-------------------------

Here's how to work with all the core RMNpy classes together:

.. code-block:: python

   import rmnpy

   # Create core dataset components
   dataset = rmnpy.Dataset.create()
   
   # Create different dimension types
   linear_dim = rmnpy.Dimension.create_linear()
   labeled_dim = rmnpy.Dimension.create_labeled()
   monotonic_dim = rmnpy.Dimension.create_monotonic()
   
   # Create dependent variable and datum
   dependent_var = rmnpy.DependentVariable.create()
   datum = rmnpy.Datum.create()

   print("Successfully created all RMNpy core objects:")
   print(f"  Dataset: {dataset}")
   print(f"  Linear Dimension: {linear_dim}")
   print(f"  Labeled Dimension: {labeled_dim}")
   print(f"  Monotonic Dimension: {monotonic_dim}")
   print(f"  DependentVariable: {dependent_var}")
   print(f"  Datum: {datum}")

Important Notes
---------------

**API Accuracy**: This documentation reflects the actual working RMNpy API that maps correctly to the underlying RMNLib C library.

**SIQuantity Integration**: DependentVariable objects inherit from SIQuantity, providing access to unit functionality through the inherited interface rather than direct method calls.

**CSDM Compliance**: All objects follow the Core Scientific Dataset Model specification for scientific data interchange.
       label="frequency",
       count=1024,
       increment=100.0,
       unit="Hz"
   )
   
   # Add dimension to dataset
   dataset.add_dimension(freq_dim)

Adding Data Variables
---------------------

Data variables contain the actual measured values.

.. code-block:: python

   from rmnpy import DependentVariable
   import numpy as np

   # Create sample data
   data = np.random.random(1024) + 1j * np.random.random(1024)
   
   # Create dependent variable
   dep_var = DependentVariable.create(
       name="intensity",
       unit="arbitrary",
       data=data
   )
   
   # Add to dataset
   dataset.add_dependent_variable(dep_var)

Working with Data
-----------------

Once you have a complete dataset, you can access and manipulate the data:

.. code-block:: python

   # Access dimensions
   dimensions = dataset.dimensions
   print(f"Number of dimensions: {len(dimensions)}")

   # Access dependent variables
   variables = dataset.dependent_variables
   print(f"Number of variables: {len(variables)}")

   # Get data as numpy array
   data_array = variables[0].components[0].quantity

Dataset Serialization
---------------------

RMNpy supports saving and loading datasets in various formats:

.. code-block:: python

   # Save to CSDM format
   dataset.save("experiment.csdf")
   
   # Load from file
   loaded_dataset = Dataset.load("experiment.csdf")

This covers the essential dataset operations. For more advanced usage, see the API reference and examples.
