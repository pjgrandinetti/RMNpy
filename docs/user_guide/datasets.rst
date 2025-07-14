Working with Datasets
=====================

The ``Dataset`` class is the central component of RMNpy, representing complete scientific datasets with metadata, dimensions, and data variables.

Creating Datasets
------------------

Basic Dataset Creation
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: python

   from rmnpy import Dataset

   # Create an empty dataset
   dataset = Dataset.create()
   print(f"Empty dataset: {dataset}")

   # Create dataset with title
   dataset = Dataset.create(title="My Experiment")
   print(f"Titled dataset: {dataset}")

   # Create dataset with full metadata
   dataset = Dataset.create(
       title="1H NMR Spectrum",
       description="Benzene in CDCl3 at 298K"
   )
   print(f"Full dataset: {dataset}")

Dataset Properties
~~~~~~~~~~~~~~~~~~

.. code-block:: python

   # Access dataset properties
   print(f"Title: {dataset.title}")
   print(f"Description: {dataset.description}")

Adding Dimensions
-----------------

Datasets can contain multiple dimensions representing different experimental parameters.

.. code-block:: python

   from rmnpy import LinearDimension

   # Create a frequency dimension
   freq_dim = LinearDimension.create(
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
