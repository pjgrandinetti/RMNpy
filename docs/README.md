# RMNpy Documentation

This directory contains the complete documentation for RMNpy, built with [Sphinx](https://www.sphinx-doc.org/).

## ⚠️ Important: Build Files Are Git-Ignored

The `_build/` directory contains generated documentation files and **should never be committed**. Only commit source files (`.md`, `.py`, `.txt`, etc.). GitHub Actions automatically builds and deploys the documentation.

## Quick Start

### Install Documentation Dependencies

```bash
cd docs
pip install -r requirements.txt
```

### Build HTML Documentation

```bash
# Using make (recommended)
make html

# Or directly with sphinx-build
sphinx-build -b html . _build/html
```

### View Documentation

```bash
# Open in browser (macOS)
open _build/html/index.html

# Or manually navigate to docs/_build/html/index.html
```

## Documentation Structure

```
docs/
├── conf.py              # Sphinx configuration
├── index.md             # Main documentation page
├── installation.md      # Installation guide
├── quickstart.md        # Quick start tutorial
├── changelog.md         # Version history
├── user_guide/          # Comprehensive user guides
│   ├── index.md
│   ├── datasets.md
│   ├── dimensions.md
│   └── ...
├── api_reference/       # Complete API documentation
│   ├── index.md
│   ├── core.md
│   ├── exceptions.md
│   └── types.md
├── examples/            # Practical examples
│   ├── index.md
│   ├── basic_usage.md
│   ├── nmr_spectroscopy.md
│   └── ...
├── _static/             # Static assets (CSS, images)
├── _build/              # Built documentation (generated)
└── requirements.txt     # Documentation dependencies
```

## Build Commands

### Development

```bash
# Clean previous build
make clean

# Build documentation
make html

# Build and open in browser
make html-open

# Live reload server (requires sphinx-autobuild)
pip install sphinx-autobuild
make livehtml
```

### Quality Checks

```bash
# Check for broken links
make linkcheck

# Strict build (treat warnings as errors)
make strict

# Run doctests
make doctest
```

### Advanced

```bash
# Build PDF (requires LaTeX)
make latexpdf

# Quick development build
make dev

# Deploy-ready build
make deploy
```

## Documentation Guidelines

### Writing Style

- Use clear, concise language
- Include practical examples for all features
- Provide both basic and advanced usage patterns
- Add cross-references between related sections

### Code Examples

- All code examples should be complete and runnable
- Include necessary imports
- Add error handling where appropriate
- Test examples before including them

### API Documentation

- Use comprehensive docstrings in the source code
- Document all parameters and return values
- Include usage examples in docstrings
- Keep API docs synchronized with implementation

### Markdown Features

This documentation uses [MyST Markdown](https://myst-parser.readthedocs.io/) with support for:

- Standard Markdown syntax
- Sphinx directives (e.g., `{note}`, `{warning}`)
- Cross-references and auto-linking
- Code highlighting
- Tables and lists

## Theme and Styling

- **Theme**: [Read the Docs](https://sphinx-rtd-theme.readthedocs.io/) theme
- **Custom CSS**: Located in `_static/custom.css`
- **Responsive Design**: Optimized for desktop and mobile
- **Search**: Full-text search with highlighting

## Deployment

### GitHub Pages (Automatic)

Documentation is automatically built and deployed to GitHub Pages when changes are pushed to the main branch via GitHub Actions (`.github/workflows/docs.yml`).

### Manual Deployment

```bash
# Build documentation
make html

# Deploy _build/html/ contents to your web server
rsync -av _build/html/ user@server:/path/to/docs/
```

## Troubleshooting

### Common Issues

**Import errors during build:**
```bash
# Ensure RMNpy is installed in development mode
pip install -e ..
```

**Sphinx not found:**
```bash
pip install -r requirements.txt
```

**Build warnings:**
```bash
# Use strict mode to catch all warnings
make strict
```

**LaTeX errors (for PDF):**
```bash
# Install LaTeX distribution (TeXLive, MiKTeX, etc.)
# Then rebuild
make latexpdf
```

### Getting Help

- Check [Sphinx documentation](https://www.sphinx-doc.org/)
- Review [MyST Markdown guide](https://myst-parser.readthedocs.io/)
- Look at the [Read the Docs theme docs](https://sphinx-rtd-theme.readthedocs.io/)

## Contributing

When contributing to documentation:

1. **Test locally**: Always build and review changes locally
2. **Follow style**: Use existing documentation style and structure
3. **Add examples**: Include practical, working examples
4. **Update links**: Ensure all cross-references work correctly
5. **Check spelling**: Use spell check before submitting

### Adding New Pages

1. Create the markdown file in the appropriate directory
2. Add the page to the relevant `toctree` directive
3. Test the build to ensure proper integration
4. Add cross-references from related pages

Example for adding a new user guide page:

```markdown
# user_guide/new_feature.md

# New Feature Guide

Content here...
```

```markdown
# user_guide/index.md

```{toctree}
:maxdepth: 2

datasets
dimensions
new_feature  # Add this line
dependent_variables
```
```

## License

This documentation is part of the RMNpy project and is licensed under the same terms as the main project.
