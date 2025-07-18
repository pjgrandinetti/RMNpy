# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html


import os
import sys
from pathlib import Path
from unittest.mock import MagicMock

# Add the src directory to Python path for autodoc
src_path = Path(__file__).parent.parent / "src"
sys.path.insert(0, str(src_path))
print("PYTHONPATH for Sphinx:", sys.path)

# Check if we're building on Read the Docs or CI
on_rtd = os.environ.get('READTHEDOCS') == 'True'
on_ci = os.environ.get('CI') == 'True' or on_rtd

# Mock C extension modules for documentation builds - ALWAYS apply mocking
class MockModule:
    """A simple mock module that behaves correctly with Sphinx"""
    
    def __init__(self, name="MockModule"):
        self.__name__ = name
        self.__file__ = f'/mock/{name}/__init__.py'
        self.__qualname__ = name
        self.__doc__ = f"Mock documentation for {name}"
        
    def __getattr__(self, name):
        return MockModule(f"{self.__name__}.{name}")
    
    def __call__(self, *args, **kwargs):
        return MockModule(f"{self.__name__}()")
    
    def __bool__(self):
        return True
    
    def __str__(self):
        return self.__name__
    
    def __contains__(self, item):
        return False
    
    def __iter__(self):
        return iter([])
    
    def __repr__(self):
        return f"<MockModule '{self.__name__}'>"

# Mock all the problematic modules before any imports
MOCK_MODULES = [
    'rmnpy.core',
    'rmnpy.helpers', 
    'rmnpy.sitypes',
    'rmnpy.sitypes.dimensionality',
    'rmnpy.sitypes.unit',
    'rmnpy.sitypes.scalar',
    'rmnpy.sitypes.helpers',
    'rmnpy.exceptions'
]

for mod_name in MOCK_MODULES:
    sys.modules[mod_name] = MockModule()

# Create a comprehensive mock rmnpy module structure
mock_rmnpy = MockModule('rmnpy')

# Mock all the main classes that Sphinx needs to document
mock_rmnpy.Dataset = MockModule('rmnpy.Dataset')
mock_rmnpy.Dataset.create = MockModule('rmnpy.Dataset.create')
mock_rmnpy.Dimension = MockModule('rmnpy.Dimension')
mock_rmnpy.Dimension.create_linear = MockModule('rmnpy.Dimension.create_linear')
mock_rmnpy.Dimension.create_labeled = MockModule('rmnpy.Dimension.create_labeled')
mock_rmnpy.Dimension.create_monotonic = MockModule('rmnpy.Dimension.create_monotonic')
mock_rmnpy.DependentVariable = MockModule('rmnpy.DependentVariable')
mock_rmnpy.DependentVariable.create = MockModule('rmnpy.DependentVariable.create')
mock_rmnpy.Datum = MockModule('rmnpy.Datum')
mock_rmnpy.Datum.create = MockModule('rmnpy.Datum.create')
mock_rmnpy.SparseSampling = MockModule('rmnpy.SparseSampling')
mock_rmnpy.SIScalar = MockModule('rmnpy.SIScalar')
mock_rmnpy.shutdown = MockModule('rmnpy.shutdown')
mock_rmnpy.RMNLibError = MockModule('rmnpy.RMNLibError')
mock_rmnpy.RMNLibMemoryError = MockModule('rmnpy.RMNLibMemoryError')
mock_rmnpy.RMNLibValidationError = MockModule('rmnpy.RMNLibValidationError')

# Mock the __file__ attribute to prevent import errors
mock_rmnpy.__file__ = '/mock/rmnpy/__init__.py'

sys.modules['rmnpy'] = mock_rmnpy

print("Comprehensive mocking applied for documentation build")

# Add import hook as failsafe for any missed imports
import builtins
original_import = builtins.__import__

def mock_import(name, *args, **kwargs):
    if name.startswith('rmnpy') and name not in sys.modules:
        print(f"Fallback mocking: {name}")
        sys.modules[name] = MockModule(name)
        return sys.modules[name]
    return original_import(name, *args, **kwargs)

builtins.__import__ = mock_import

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'RMNpy'
copyright = '2025, Philip Grandinetti'
author = 'Philip Grandinetti'
version = '0.1.0-alpha'
release = '0.1.0-alpha (DEVELOPMENT - NOT FOR USE)'

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
html_baseurl = 'https://pjgrandinetti.github.io/RMNpy/' if not on_rtd else 'https://rmnpy.readthedocs.io/'

# Read the Docs specific settings
if on_rtd:
    # Disable problematic extensions on RTD if needed
    html_theme_options.update({
        'canonical_url': 'https://rmnpy.readthedocs.io/',
        'analytics_id': '',  # Add Google Analytics ID if desired
        'logo_only': False,
        'display_version': True,
        'prev_next_buttons_location': 'bottom',
        'style_external_links': False,
        'vcs_pageview_mode': '',
    })

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
