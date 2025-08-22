# docs/conf.py

# -- Path setup --------------------------------------------------------------

import os
import sys

# Add the source directory to Python path for autodoc
sys.path.insert(0, os.path.abspath("../src"))

# -- Project information -----------------------------------------------------

project = "RMNpy"
author = "Philip J. Grandinetti"
copyright = "2025, Philip J. Grandinetti"
# The full version, including alpha/beta/rc tags
release = "0.1.0"
# The short X.Y version
version = release
master_doc = "index"

# -- General configuration ---------------------------------------------------

# Sphinx extensions
extensions = [
    "sphinx.ext.autodoc",  # Python autodoc support
    "sphinx.ext.napoleon",  # Google/NumPy style docstrings
    "sphinx.ext.viewcode",  # Add source code links
    "sphinx.ext.intersphinx",  # Link to other docs
    "breathe",  # C/C++ integration via Doxygen
    "myst_parser",  # Markdown support
    "sphinx_copybutton",  # Copy button for code blocks
    "nbsphinx",  # Jupyter notebook support
]

# -- Autodoc configuration -------------------------------------------------

# Mock imports for compiled extensions that can't be built during documentation
autodoc_mock_imports = [
    "rmnpy.wrappers.sitypes.dimensionality",
    "rmnpy.wrappers.sitypes.scalar",
    "rmnpy.wrappers.sitypes.unit",
    "rmnpy.wrappers.rmnlib.dependent_variable",
    "rmnpy.wrappers.rmnlib.dimension",
    "rmnpy.wrappers.rmnlib.sparse_sampling",
    "rmnpy.helpers.octypes",
    "rmnpy.quantities",
]

# -- nbsphinx configuration -------------------------------------------------

# Allow errors in notebook execution so docs can build without the library installed
nbsphinx_allow_errors = True

# Paths that contain templates, relative to this directory.
templates_path = ["_templates"]

# List of patterns, relative to source directory, that match files to ignore.
exclude_patterns = [
    "_build",
    "Thumbs.db",
    ".DS_Store",
    "API_SIMPLIFICATION_REVIEW.md",
    "sphinx_warning_fixes.ipynb",
    "development/DEVELOPMENT.md",
    "development/ENVIRONMENT_SETUP.md",
    "development/NEW_COMPUTER_SETUP.md",
    "development/README.md",
]

# Suppress duplicate C declaration warnings from Breathe
suppress_warnings = [
    "duplicate_declaration",
    "duplicate_declaration.c",
    "autosummary.import_cycle",
    "autodoc.import_object",
    "ref.python",
]

# -- Breathe configuration --------------------------------------------------

# Tell Breathe where the Doxygen XML lives (relative to this conf.py).
# This should match OUTPUT_DIRECTORY = doxygen and XML_OUTPUT = xml in Doxyfile,
# resulting in docs/doxygen/xml.
breathe_projects = {
    "RMNpy": os.path.abspath(os.path.join(os.path.dirname(__file__), "doxygen", "xml")),
}
breathe_default_project = "RMNpy"

# Ensure that .c/.h files use the C domain
breathe_domain_by_extension = {
    "c": "c",
    "h": "c",
    "pyx": "py",
    "pxd": "py",
}
primary_domain = "py"

# -- Autodoc configuration --------------------------------------------------

autodoc_default_options = {
    "members": True,
    "member-order": "bysource",
    "special-members": "__init__",
    "undoc-members": True,
    "exclude-members": "__weakref__",
}

# Add fully qualified names for cross-references to avoid ambiguity
autodoc_typehints = "description"
autodoc_typehints_format = "fully-qualified"

# Suppress specific cross-reference warnings
nitpick_ignore = [
    ("py:class", "rmnpy.wrappers.sitypes.Unit"),
    ("py:class", "rmnpy.wrappers.sitypes.Dimensionality"),
]

# -- Napoleon configuration -------------------------------------------------

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

# -- Intersphinx configuration ----------------------------------------------

intersphinx_mapping = {
    "python": ("https://docs.python.org/3", None),
    "numpy": ("https://numpy.org/doc/stable/", None),
    "cython": ("https://cython.readthedocs.io/en/latest/", None),
}

# -- Options for HTML output -------------------------------------------------

html_theme = "sphinx_rtd_theme"

html_theme_options = {
    "canonical_url": "",
    "analytics_id": "UA-XXXXXXX-1",  # Provided by the user to enable tracking.
    "logo_only": False,
    "prev_next_buttons_location": "bottom",
    "style_external_links": False,
    "vcs_pageview_mode": "",
    "style_nav_header_background": "white",
    # Toc options
    "collapse_navigation": True,
    "sticky_navigation": True,
    "navigation_depth": 4,
    "includehidden": True,
    "titles_only": False,
}

# Add custom CSS files
html_static_path = ["_static"]
html_css_files = ["custom.css"]

# The name of the Pygments (syntax highlighting) style to use.
pygments_style = "sphinx"

# -- Options for LaTeX output -----------------------------------------------

latex_elements = {
    # The paper size ('letterpaper' or 'a4paper').
    "papersize": "letterpaper",
    # The font size ('10pt', '11pt' or '12pt').
    "pointsize": "10pt",
    # Additional stuff for the LaTeX preamble.
    "preamble": "",
    # Latex figure (float) alignment
    "figure_align": "htbp",
}

# Grouping the document tree into LaTeX files.
latex_documents = [
    (master_doc, "RMNpy.tex", "RMNpy Documentation", "Philip J. Grandinetti", "manual"),
]

# -- Options for manual page output -----------------------------------------

# One entry per manual page.
man_pages = [(master_doc, "rmnpy", "RMNpy Documentation", [author], 1)]

# -- Options for Texinfo output ---------------------------------------------

# Grouping the document tree into Texinfo files.
texinfo_documents = [
    (
        master_doc,
        "RMNpy",
        "RMNpy Documentation",
        author,
        "RMNpy",
        "Python bindings for OCTypes, SITypes, and RMNLib.",
        "Miscellaneous",
    ),
]

# -- Options for Epub output ------------------------------------------------

# Bibliographic Dublin Core info.
epub_title = project
epub_author = author
epub_publisher = author
epub_copyright = copyright
