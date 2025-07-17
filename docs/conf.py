# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html


import os
import sys
from pathlib import Path

# Add the src directory to Python path for autodoc
src_path = Path(__file__).parent.parent / "src"
sys.path.insert(0, str(src_path))
print("PYTHONPATH for Sphinx:", sys.path)

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'RMNpy'
copyright = '2025, Philip Grandinetti'
author = 'Philip Grandinetti'
version = '0.1.0'
release = '0.1.0'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    'sphinx.ext.autodoc',
    'sphinx.ext.autosummary',
    'sphinx.ext.viewcode',
    'sphinx.ext.napoleon',
    'sphinx.ext.githubpages',
    'sphinx.ext.intersphinx',
    'sphinx.ext.mathjax',
    # 'sphinx_gallery.gen_gallery',  # Temporarily disabled
]

# Add the src directory to Python path for autodoc
sys.path.insert(0, str(src_path))
src_path = Path(__file__).parent.parent / "src"
sys.path.insert(0, str(src_path))
print("PYTHONPATH for Sphinx:", sys.path)

templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'sphinx_rtd_theme'
html_static_path = ['_static']

# Theme options
html_theme_options = {
    'collapse_navigation': False,
    'sticky_navigation': True,
    'navigation_depth': 4,
    'includehidden': True,
    'titles_only': False,
}

# -- Extension configuration -------------------------------------------------

# Napoleon settings
napoleon_google_docstring = True
napoleon_numpy_docstring = True
napoleon_include_init_with_doc = False
napoleon_include_private_with_doc = False
napoleon_include_special_with_doc = True
napoleon_use_admonition_for_examples = False
napoleon_use_admonition_for_notes = False
napoleon_use_admonition_for_references = False
napoleon_use_ivar = False
napoleon_use_param = True
napoleon_use_rtype = True

# Autodoc settings
autodoc_default_options = {
    'members': True,
    'undoc-members': True,
    'show-inheritance': True,
    'special-members': '__init__',
}

# Intersphinx mapping
intersphinx_mapping = {
    'python': ('https://docs.python.org/3', None),
    'numpy': ('https://numpy.org/doc/stable/', None),
}

# Source file suffixes - RST is primary format
source_suffix = {
    '.rst': 'restructuredtext',
}

# Master document
master_doc = 'index'

# Language
language = 'en'

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are placed in _static.
html_css_files = [
    'custom.css',
]

# HTML output options
html_title = f'{project} v{version}'
html_short_title = project
html_logo = None
html_favicon = None

# Output file base names for HTML help builder
htmlhelp_basename = 'RMNpydoc'

# GitHub Pages configuration
html_baseurl = 'https://pjgrandinetti.github.io/RMNpy/'

# -- Sphinx-Gallery configuration ----------------------------------------

sphinx_gallery_conf = {
    'examples_dirs': 'examples_gallery',   # path to your example scripts
    'gallery_dirs': 'auto_examples',       # path to where to save gallery generated output
    'filename_pattern': r'/plot_.*\.py$',  # raw string to avoid escape sequence warning
    'plot_gallery': True,                  # Enable gallery execution
    'download_all_examples': False,        # download all examples in a zip file
    'image_scrapers': ('matplotlib',),     # which libraries to scrape images from
    'first_notebook_cell': '%matplotlib inline',  # code to execute in first cell
    'show_memory': False,  # Disable memory tracking to avoid issues
    'abort_on_example_error': False,  # Don't abort on errors during development
    'run_stale_examples': False,  # Don't re-run examples that haven't changed
}
