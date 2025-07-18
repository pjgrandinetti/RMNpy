# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html


import os
import sys
import tempfile
from pathlib import Path
from unittest.mock import MagicMock

# Add the src directory to Python path for autodoc
src_path = Path(__file__).parent.parent / "src"
sys.path.insert(0, str(src_path))
print("PYTHONPATH for Sphinx:", sys.path)

# Check if we're building on Read the Docs or CI
on_rtd = os.environ.get('READTHEDOCS') == 'True'
on_ci = os.environ.get('CI') == 'True' or on_rtd

# Create a temporary directory for mock files that Sphinx can parse
_temp_dir = tempfile.mkdtemp(prefix='sphinx_mock_')
_mock_rmnpy_dir = Path(_temp_dir) / 'rmnpy'
_mock_rmnpy_dir.mkdir(parents=True, exist_ok=True)

# Mock C extension modules for documentation builds - ALWAYS apply mocking
class MockModule:
    """A simple mock module that behaves correctly with Sphinx"""
    
    def __init__(self, name="MockModule", create_file=True):
        self.__name__ = name
        self.__qualname__ = name
        self.__doc__ = f"Mock documentation for {name}"
        
        # Create actual Python files for Sphinx to parse
        if create_file:
            if '.' in name:
                # Handle submodules
                parts = name.split('.')
                mock_dir = Path(_temp_dir)
                for part in parts[:-1]:
                    mock_dir = mock_dir / part
                    mock_dir.mkdir(exist_ok=True)
                    init_file = mock_dir / '__init__.py'
                    if not init_file.exists():
                        init_file.write_text('# Mock module for Sphinx documentation\n')
                
                # Create the final module file
                final_file = mock_dir / f'{parts[-1]}.py'
                if not final_file.exists():
                    final_file.write_text(f'"""Mock {name} module for documentation."""\n')
                self.__file__ = str(final_file)
            else:
                # Handle top-level modules
                mock_file = Path(_temp_dir) / f'{name}.py'
                if not mock_file.exists():
                    mock_file.write_text(f'"""Mock {name} module for documentation."""\n')
                self.__file__ = str(mock_file)
        else:
            self.__file__ = f'/mock/{name}.py'
        
    def __getattr__(self, name):
        return MockModule(f"{self.__name__}.{name}", create_file=False)
    
    def __call__(self, *args, **kwargs):
        return MockModule(f"{self.__name__}()", create_file=False)
    
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
    sys.modules[mod_name] = MockModule(mod_name)

# Create the main rmnpy package with proper __init__.py
rmnpy_init_content = '''"""RMNpy - A Python library for NMR data processing and analysis.

This is a mock version for documentation generation.
"""

class Dataset:
    """Mock Dataset class for documentation."""
    
    @classmethod
    def create(cls):
        """Create a new Dataset."""
        pass

class Dimension:
    """Mock Dimension class for documentation."""
    
    @classmethod  
    def create_linear(cls):
        """Create a linear dimension."""
        pass
        
    @classmethod
    def create_labeled(cls):
        """Create a labeled dimension."""
        pass
        
    @classmethod
    def create_monotonic(cls):
        """Create a monotonic dimension."""
        pass

class DependentVariable:
    """Mock DependentVariable class for documentation."""
    
    @classmethod
    def create(cls):
        """Create a new DependentVariable."""
        pass

class Datum:
    """Mock Datum class for documentation."""
    
    @classmethod
    def create(cls):
        """Create a new Datum."""
        pass

class SparseSampling:
    """Mock SparseSampling class for documentation."""
    pass

class SIScalar:
    """Mock SIScalar class for documentation."""
    pass

def shutdown():
    """Mock shutdown function."""
    pass

class RMNLibError(Exception):
    """Mock RMNLibError exception."""
    pass

class RMNLibMemoryError(RMNLibError):
    """Mock RMNLibMemoryError exception."""
    pass

class RMNLibValidationError(RMNLibError):
    """Mock RMNLibValidationError exception."""
    pass
'''

# Write the main rmnpy __init__.py file
rmnpy_init_file = _mock_rmnpy_dir / '__init__.py'
rmnpy_init_file.write_text(rmnpy_init_content, encoding='utf-8')

# Verify the file was written correctly
try:
    written_content = rmnpy_init_file.read_text(encoding='utf-8')
    compile(written_content, str(rmnpy_init_file), 'exec')
    print(f"SUCCESS: Mock file verified at {rmnpy_init_file}")
except Exception as e:
    print(f"ERROR: Mock file verification failed: {e}")
    print(f"File exists: {rmnpy_init_file.exists()}")
    print(f"File size: {rmnpy_init_file.stat().st_size if rmnpy_init_file.exists() else 'N/A'}")

# Create sitypes subpackage
sitypes_dir = _mock_rmnpy_dir / 'sitypes'
sitypes_dir.mkdir(exist_ok=True)
sitypes_init = sitypes_dir / '__init__.py'
sitypes_init.write_text('"""Mock sitypes package for documentation."""\n', encoding='utf-8')

# Add the mock directory to Python path so imports work
sys.path.insert(0, str(_temp_dir))

# Now create the mock module and add to sys.modules
mock_rmnpy = MockModule('rmnpy', create_file=False)
mock_rmnpy.__file__ = str(rmnpy_init_file)

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

# Prevent Sphinx pycode analyzer from trying to parse our mock files
def setup(app):
    """Setup function called by Sphinx."""
    
    # Override pycode analyzer to handle mock files gracefully
    from sphinx.pycode import ModuleAnalyzer
    original_analyze = ModuleAnalyzer.analyze
    
    def safe_analyze(self):
        """Override analyze method to handle mock files gracefully."""
        try:
            # Check if this is a mock file
            is_mock_file = False
            if hasattr(self, 'modname') and 'sphinx_mock_' in str(getattr(self, 'modname', '')):
                is_mock_file = True
            if hasattr(self, '_filename') and self._filename and 'sphinx_mock_' in str(self._filename):
                is_mock_file = True
                
            if is_mock_file:
                # Initialize the analyzer with empty data to avoid AttributeError
                self.attr_docs = {}
                self.annotations = {}
                self.finals = set()
                self.overloads = {}
                self.tags = {}
                print(f"Mock file detected, using minimal analysis: {getattr(self, '_filename', 'unknown')}")
                return
                
            return original_analyze(self)
        except Exception as e:
            # If analysis fails, initialize with empty data
            print(f"Skipping pycode analysis due to error: {e}")
            self.attr_docs = {}
            self.annotations = {}
            self.finals = set()
            self.overloads = {}
            self.tags = {}
            return
    
    ModuleAnalyzer.analyze = safe_analyze
    return {'version': '1.0', 'parallel_read_safe': True}

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
exclude_patterns = [
    '_build', 
    'Thumbs.db', 
    '.DS_Store',
    '**/sphinx_mock_*',  # Exclude any temporary mock directories
    '/tmp/sphinx_mock_*',  # Exclude temporary mock directories
]

# Exclude temporary mock files from source file scanning
exclude_patterns.append(f'{tempfile.gettempdir()}/sphinx_mock_*/**')

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
