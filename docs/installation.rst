Installation
============

This guide covers different ways to install RMNpy on your system.

Prerequisites
-------------

Before installing RMNpy, ensure you have:

* **Python 3.8 or later**
* **NumPy** (required for building and runtime)
* **C compiler** (gcc, clang, or MSVC on Windows)
* **Cython** (required for building from source)

You can install the Python prerequisites with:

.. code-block:: bash

   pip install numpy cython

Development Installation (Recommended)
---------------------------------------

Since RMNpy is currently under active development, we recommend installing from source:

1. Clone the Repository
~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   git clone https://github.com/pjgrandinetti/RMNpy.git
   cd RMNpy

2. Install Dependencies
~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   pip install -r requirements.txt

3. Build and Install in Development Mode
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   pip install -e .

This will:

- Download required C libraries from GitHub releases
- Build the Cython extensions
- Install RMNpy in "editable" mode so changes are reflected immediately

4. Verify Installation
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   python -c "import rmnpy; print('RMNpy installed successfully!')"

Production Installation
-----------------------

.. note::
   PyPI package is coming soon. For now, use development installation.

When available, you'll be able to install RMNpy with:

.. code-block:: bash

   pip install rmnpy

Platform-Specific Notes
------------------------

macOS
~~~~~

On macOS, you may need to install Xcode command line tools:

.. code-block:: bash

   xcode-select --install

Linux
~~~~~

On Ubuntu/Debian systems, install build essentials:

.. code-block:: bash

   sudo apt-get install build-essential python3-dev

On CentOS/RHEL systems:

.. code-block:: bash

   sudo yum groupinstall "Development Tools"
   sudo yum install python3-devel

Windows
~~~~~~~

On Windows, you'll need either:

- **Visual Studio Build Tools** (recommended)
- **Microsoft Visual C++ 14.0** or greater

Download from: https://visualstudio.microsoft.com/visual-cpp-build-tools/

Troubleshooting
---------------

Common Issues
~~~~~~~~~~~~~

**Error: "Cannot find libRMN.a"**

This means the dependency download failed. Try:

.. code-block:: bash

   # Manually run the dependency script
   python scripts/build_deps.py

   # Then rebuild
   pip install -e .

**Error: "Microsoft Visual C++ 14.0 is required"** (Windows)

Install Visual Studio Build Tools as described above.

**Error: "Failed building wheel for rmnpy"**

Ensure you have:

1. Latest pip: ``pip install --upgrade pip``
2. Required dependencies: ``pip install numpy cython``
3. C compiler properly installed

Dependency Strategy
~~~~~~~~~~~~~~~~~~~

RMNpy uses a two-tier dependency strategy:

1. **Production**: Downloads pre-built libraries from GitHub releases
2. **Development**: Falls back to workspace dependencies (../RMNLib, ../OCTypes, ../SITypes)

For more details, see the dependency documentation in the repository.

Verification
------------

Test your installation with:

.. code-block:: python

   import rmnpy
   
   # Check version
   print(f"RMNpy version: {rmnpy.__version__}")
   
   # Create a simple dataset
   dataset = rmnpy.Dataset.create()
   dataset.title = "Test Dataset"
   print(f"Created dataset: {dataset.title}")

If this runs without errors, RMNpy is properly installed!

Next Steps
----------

- Read the :doc:`quickstart` guide
- Explore the :doc:`examples/index`
- Check out the :doc:`user_guide/index`
