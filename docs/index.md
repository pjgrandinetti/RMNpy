# RMNpy Documentation

```{toctree}
:maxdepth: 2
:caption: Contents:

installation
quickstart
user_guide/index
api_reference/index
examples/index
auto_examples/index
changelog
```

## Welcome to RMNpy

RMNpy is a Python wrapper for the RMNLib C library, providing access to Core Scientific Dataset Model (CSDM) functionality from Python. It enables Python developers to work with multidimensional scientific datasets using a clean, Pythonic interface while maintaining the performance of the underlying C implementation.

## 🎨 Interactive Examples Gallery

**NEW!** Auto-executing examples with live output:

Explore the [**Examples Gallery**](auto_examples/index.html) featuring:

- 🔬 **Live code execution** with real RMNpy output
- 📊 **Automatic visualization** (plots, figures, analysis)
- 📥 **Download ready-to-run scripts**
- 🚀 **One-click Binder launch** for cloud execution
- 📓 **Auto-generated Jupyter notebooks**

## 📓 Quick Start with Jupyter Notebooks

**Manual notebooks for hands-on learning:**

- [**Installation & Basic Usage**](notebooks/01_installation_and_basic_usage.ipynb) - Get started quickly
- [**NMR Spectroscopy**](notebooks/02_nmr_spectroscopy.ipynb) - Real-world examples  
- [**Advanced Data Manipulation**](notebooks/03_advanced_data_manipulation.ipynb) - Large datasets & analysis

Download any notebook and run it locally in Jupyter Lab/Notebook!

:::{warning}
**Development Status**: RMNpy is currently under active development. Many features are not yet implemented and the API is subject to change. Currently, only basic `Dataset`, `Datum`, `Dimension`, and `DependentVariable` functionality is available.
:::

## Key Features

* **Scientific Dataset Management**: Create, manipulate, and analyze multidimensional scientific datasets
* **CSDM Compatibility**: Full support for Core Scientific Dataset Model format  
* **Memory Safety**: Automatic memory management with proper cleanup
* **NumPy Integration**: Seamless integration with NumPy arrays
* **Performance**: Direct access to optimized C library functions
* **Error Handling**: Comprehensive exception hierarchy for robust error handling

## Quick Example

```python
import rmnpy

# Create a new dataset
dataset = rmnpy.Dataset.create(title="NMR Spectrum Analysis")

# Create dimensions for frequency and time
freq_dim = rmnpy.Dimension.create_linear(
    label="frequency", 
    count=256, 
    unit="Hz"
)

# Create dependent variables
intensity = rmnpy.DependentVariable.create(
    name="signal_intensity",
    unit="arbitrary_units"
)

print(f"Dataset: {dataset}")
print(f"Frequency dimension: {freq_dim}")
print(f"Intensity variable: {intensity}")
```

## Scientific Applications

RMNpy is designed for scientific applications that require:

* **NMR Spectroscopy**: Multi-dimensional NMR data analysis
* **Mass Spectrometry**: Complex spectral dataset handling  
* **Scientific Computing**: General multidimensional dataset manipulation
* **Data Exchange**: CSDM-compliant data sharing between applications

## Architecture

RMNpy is built on a solid foundation:

* **RMNLib**: Core scientific dataset library
* **OCTypes**: Foundation types (strings, arrays, dictionaries, memory management)
* **SITypes**: SI units library (scalars, units, physical quantities)
* **Cython**: High-performance Python-C integration
* **NumPy**: Numerical computing support

## Getting Started

The best way to get started is to follow our [installation guide](installation.md) and then work through the [quickstart tutorial](quickstart.md).

For comprehensive coverage of all features, see our [user guide](user_guide/index.md) and [API reference](api_reference/index.md).

## Indices and tables

* {ref}`genindex`
* {ref}`modindex`
* {ref}`search`
