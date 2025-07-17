# RMNpy Documentation

This directory contains the documentation for RMNpy, built with Sphinx and hosted on Read the Docs.

## Building Documentation Locally

### Prerequisites

1. Install RMNpy with documentation dependencies:
   ```bash
   pip install -e .[docs]
   ```

2. Or install requirements manually:
   ```bash
   pip install -r requirements.txt
   ```

### Building

```bash
cd docs
make html
```

The built documentation will be in `_build/html/`. Open `_build/html/index.html` in your browser.

### Other Build Targets

- `make clean` - Clean build artifacts
- `make linkcheck` - Check for broken links
- `make doctest` - Run doctests in documentation

## Read the Docs Integration

This project is configured for automatic building on Read the Docs:

- **Configuration**: `.readthedocs.yaml` in the project root
- **Requirements**: `requirements.txt` in this directory
- **Python Dependencies**: `pyproject.toml` extras for `[docs]`

### RTD Build Process

1. RTD detects changes to the `main` branch
2. Installs system dependencies (cmake, build-essential)
3. Installs Python dependencies from `pyproject.toml[docs]`
4. Builds C extensions with `python setup.py build_ext --inplace`
5. Runs `sphinx-build` to generate HTML documentation

### Testing RTD Build Locally

Use the provided test script:

```bash
./test_rtd_build.sh
```

This script mimics the RTD environment by:
- Setting `READTHEDOCS=True` environment variable
- Installing dependencies exactly as RTD does
- Building documentation with the same settings

## Documentation Structure

```
docs/
├── index.rst              # Main entry point
├── quickstart.rst         # Getting started guide
├── api_reference/         # API documentation
├── user_guide/           # Detailed user guides
├── examples/             # Example tutorials
├── conf.py               # Sphinx configuration
├── requirements.txt      # Documentation dependencies
└── _static/              # Static files (CSS, images)
```

## Writing Documentation

### Format Guidelines

- **Primary Format**: RestructuredText (`.rst`)
- **API Documentation**: Auto-generated from docstrings
- **Examples**: Include runnable code examples
- **Cross-references**: Use Sphinx directives for linking

### Docstring Format

Use NumPy/Google style docstrings:

```python
def example_function(param1, param2):
    """
    Brief description of the function.
    
    Parameters
    ----------
    param1 : str
        Description of param1
    param2 : int
        Description of param2
        
    Returns
    -------
    bool
        Description of return value
        
    Examples
    --------
    >>> example_function("hello", 42)
    True
    """
    pass
```

### Adding New Documentation

1. Create `.rst` files in appropriate directories
2. Add entries to `index.rst` table of contents
3. Update `conf.py` if needed (new extensions, etc.)
4. Test locally with `make html`

## Troubleshooting

### Common Issues

1. **Import Errors**: Ensure RMNpy is properly installed
2. **Build Failures**: Check that all dependencies are installed
3. **Missing API**: Run `make clean` then rebuild
4. **RTD Build Failures**: Check the RTD build logs

### RTD Environment Variables

- `READTHEDOCS=True` - Indicates building on RTD
- `READTHEDOCS_VERSION` - The version being built
- `READTHEDOCS_PROJECT` - The project name

### Debugging

Enable verbose output:
```bash
sphinx-build -v -b html . _build/html
```

## Links

- [Live Documentation](https://rmnpy.readthedocs.io/)
- [Read the Docs Project](https://readthedocs.org/projects/rmnpy/)
- [Sphinx Documentation](https://www.sphinx-doc.org/)
- [RTD Configuration](https://docs.readthedocs.io/en/stable/config-file/v2.html)
