# Jupyter Notebooks Gallery

Interactive examples for hands-on learning with RMNpy.

## Available Notebooks

### 01_installation_and_basic_usage.ipynb

Learn the fundamentals of RMNpy

- Installation verification
- Core classes (Dataset, Dimension, DependentVariable, Datum)
- Basic object creation and manipulation
- Error handling
- Complete workflow example

**Download**: [01_installation_and_basic_usage.ipynb](01_installation_and_basic_usage.ipynb)

### 02_nmr_spectroscopy.ipynb

Real-world NMR spectroscopy applications

- 1D NMR spectrum setup
- Chemical shift dimensions
- Complex signal handling (real/imaginary components)
- 2D NMR experiments (COSY)
- Multi-nuclear NMR (¹H, ¹³C, ³¹P, ¹⁹F)
- Variable temperature studies
- Complete NMR workflow with caffeine analysis

**Download**: [02_nmr_spectroscopy.ipynb](02_nmr_spectroscopy.ipynb)

### 03_advanced_data_manipulation.ipynb

Advanced techniques for large datasets

- Large dataset handling
- Batch processing for memory efficiency
- 3D data analysis
- Time series and kinetics studies
- Statistical analysis
- Data filtering and smoothing
- Memory management best practices

**Download**: [03_advanced_data_manipulation.ipynb](03_advanced_data_manipulation.ipynb)

## How to Use These Notebooks

### Option 1: Local Installation

```bash
# Download the notebook file
# Then start Jupyter
jupyter lab
# or
jupyter notebook
```

### Option 2: Quick Setup

```bash
# Clone the repository
git clone https://github.com/pjgrandinetti/RMNpy.git
cd RMNpy/docs/notebooks

# Install dependencies
pip install jupyter notebook

# Launch Jupyter
jupyter notebook
```

### Option 3: Google Colab

1. Download the notebook file
2. Upload to Google Colab
3. Install RMNpy in the first cell:

   ```python
   !pip install rmnpy
   ```

## Interactive Features

Each notebook includes:

- ✅ **Runnable code cells** - Execute to see RMNpy in action
- 📊 **Data simulation** - Generate realistic scientific data
- 📈 **Analysis examples** - Statistical analysis and data processing
- 🛠️ **Error handling** - Best practices for robust code
- 💡 **Tips and tricks** - Performance optimization

## Requirements

- Python 3.8+
- RMNpy installed
- Jupyter Lab or Jupyter Notebook
- Optional: matplotlib, numpy (for enhanced visualization)

## Troubleshooting

### Common Issues

**Import Error**: Ensure RMNpy is installed in your Jupyter environment:

```python
import sys
!{sys.executable} -m pip install rmnpy
```

**Kernel Issues**: Restart the kernel if you encounter memory issues:

- Kernel → Restart & Clear Output

**File Not Found**: Make sure you've downloaded the notebook file to your working directory.

## Contributing Notebooks

We welcome contributions! To add a new notebook:

1. Create a new `.ipynb` file following our naming convention
2. Include comprehensive documentation and comments
3. Test all code cells thoroughly
4. Add the notebook to this index
5. Submit a pull request

### Notebook Guidelines

- **Self-contained**: Include all necessary imports and setup
- **Well-documented**: Explain each step clearly
- **Educational**: Focus on teaching concepts
- **Practical**: Use realistic examples
- **Error-safe**: Include proper error handling

## Next Steps

After working through these notebooks:

1. **Read the [User Guide](../user_guide/index.md)** for detailed documentation
2. **Check the [API Reference](../api_reference/index.md)** for complete class documentation
3. **Explore [Installation Options](../installation.md)** for advanced setups
4. **Join the community** and share your own examples

## Feedback

Found an issue with a notebook? Have suggestions for improvements?

- [Open an issue on GitHub](https://github.com/pjgrandinetti/RMNpy/issues)
- Email the maintainers
- Contribute improvements via pull requests

Happy coding with RMNpy! 🚀
