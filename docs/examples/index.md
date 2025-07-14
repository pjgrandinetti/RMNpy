# Examples Gallery

Interactive examples and tutorials for using RMNpy effectively.

## 🎨 Interactive Examples Gallery

**Executable examples with automatic output generation:**

The [**Examples Gallery**](../auto_examples/index.html) provides interactive examples that are automatically executed and documented. Each example includes:

- ✅ **Live code execution** with real output
- 📊 **Generated plots and figures** (when applicable)  
- 📥 **Downloadable Python scripts**
- 📓 **Auto-generated Jupyter notebooks**
- 🚀 **One-click Binder launch** for cloud execution

### Featured Gallery Examples

- [**Installation and Basic Usage**](../auto_examples/plot_01_installation_basic_usage.html) - Get started with RMNpy
- [**NMR Spectroscopy**](../auto_examples/plot_02_nmr_spectroscopy.html) - Complete NMR workflow examples
- [**Advanced Data Manipulation**](../auto_examples/plot_03_advanced_data_manipulation.html) - Large datasets and analysis techniques

```{toctree}
:maxdepth: 2

basic_usage
```

## 📓 Manual Jupyter Notebooks

**Download and run these interactive notebooks locally:**

### Getting Started

- [**Installation and Basic Usage**](../notebooks/01_installation_and_basic_usage.ipynb) - Verify installation and learn core concepts
- [**NMR Spectroscopy**](../notebooks/02_nmr_spectroscopy.ipynb) - Complete NMR workflow with realistic examples
- [**Advanced Data Manipulation**](../notebooks/03_advanced_data_manipulation.ipynb) - Large datasets, filtering, and statistical analysis

### How to Use Notebooks

1. **Download**: Right-click on any notebook link → "Save Link As..."
2. **Open**: Launch Jupyter Lab/Notebook: `jupyter lab` or `jupyter notebook`
3. **Run**: Execute cells to interact with RMNpy

## 📋 Code Examples

This section also provides code examples in Markdown format for quick reference.

## Quick Examples

### Basic Dataset Creation

```python
import rmnpy

# Create a simple dataset
dataset = rmnpy.Dataset.create(
    title="Sample Analysis",
    description="Spectroscopic characterization"
)

print(f"Created: {dataset}")
```

### NMR Spectrum Setup

```python
from rmnpy import Dataset, Dimension, DependentVariable

# Create 1H NMR dataset
nmr_dataset = Dataset.create(
    title="1H NMR Spectrum",
    description="Benzene in CDCl3"
)

# Chemical shift dimension
chemical_shift = Dimension.create_linear(
    label="chemical_shift",
    count=512,
    start=10.0,
    increment=-0.02,
    unit="ppm"
)

# Signal intensity
intensity = DependentVariable.create(
    name="intensity",
    unit="arbitrary_units"
)

print(f"NMR Dataset: {nmr_dataset}")
print(f"Chemical shift: {chemical_shift}")
print(f"Intensity: {intensity}")
```

### Error Handling Example

```python
from rmnpy import Dataset
from rmnpy.exceptions import RMNLibError

try:
    # Create dataset
    dataset = Dataset.create(title="Test")
    
    # Access properties
    title = dataset.title
    print(f"Dataset title: {title}")
    
except RMNLibError as e:
    print(f"RMNLib error: {e}")
```

## Complete Examples

For comprehensive examples, see the individual pages:

- **[Basic Usage](basic_usage.md)**: Fundamental operations and patterns

### Coming Soon

Additional example sections will be added:

- **NMR Spectroscopy**: Nuclear magnetic resonance applications  
- **Mass Spectrometry**: Mass spectrometry data handling
- **Data Analysis**: Advanced data processing workflows

## Running the Examples

All examples can be run directly:

```bash
# Save any example as a .py file
python example_script.py

# Or run interactively
python -i example_script.py
```

Make sure RMNpy is installed first:

```bash
pip install -e .  # If building from source
```

## Example Data

Some examples reference sample data. You can create test data using:

```python
import rmnpy
import numpy as np

# Generate sample NMR-like data
frequencies = np.linspace(0, 400, 256)  # 400 Hz range
intensities = np.random.normal(0, 1, 256)  # Random intensities

# Create RMNpy objects to represent this data
dataset = rmnpy.Dataset.create(title="Sample NMR Data")
freq_dim = rmnpy.Dimension.create_linear(
    label="frequency", 
    count=256, 
    unit="Hz"
)
intensity_var = rmnpy.DependentVariable.create(
    name="intensity",
    unit="arbitrary_units"
)
```

:::{note}
**Current Implementation**: Examples focus on object creation and basic operations. Data array manipulation and file I/O examples will be added as those features are implemented.
:::

## Contributing Examples

If you have useful RMNpy examples to share:

1. Follow the existing example format
2. Include clear documentation and comments
3. Add error handling where appropriate
4. Test the example thoroughly
5. Submit a pull request

Examples should be:

- **Complete**: Runnable without modification
- **Documented**: Well-commented and explained
- **Practical**: Solve real-world problems
- **Error-safe**: Include appropriate error handling
