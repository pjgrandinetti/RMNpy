RMNpy Documentation
===================

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

Welcome to RMNpy
-----------------

RMNpy is a Python wrapper for the RMNLib C library, providing access to Core Scientific Dataset Model (CSDM) functionality from Python. It enables Python developers to work with multidimensional scientific datasets using a clean, Pythonic interface while maintaining the performance of the underlying C implementation.

🎨 Interactive Examples Gallery
--------------------------------

**NEW!** Auto-executing examples with live output:

Explore the `Examples Gallery <auto_examples/index.html>`__ featuring:

- 🔬 **Live code execution** with real RMNpy output
- 📊 **Automatic visualization** (plots, figures, analysis)
- 📥 **Download ready-to-run scripts**
- 🚀 **One-click Binder launch** for cloud execution
- 📓 **Auto-generated Jupyter notebooks**

🚀 Quick Start
---------------

.. code-block:: python

   import rmnpy

   # Create a new dataset
   dataset = rmnpy.Dataset.create()
   dataset.title = "My Scientific Data"

   # Add dimensions and data
   print(f"Dataset: {dataset.title}")

📚 What You'll Find Here
-------------------------

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
