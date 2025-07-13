#!/usr/bin/env python3
"""Setup script for RMNpy - Python wrapper for RMNLib scientific data library."""

from setuptools import setup, Extension, find_packages
from Cython.Build import cythonize
import numpy
import os

# Define the extension with complete header dependencies
extensions = [
    Extension(
        "rmnpy.core",
        sources=["src/rmnpy/core.pyx"],
        include_dirs=[
            # Use system-installed headers instead of local copies
            "/usr/local/include",      # Standard system location
            "/usr/local/include/OCTypes",
            "/usr/local/include/SITypes", 
            "/usr/local/include/RMNLib",
            "/opt/homebrew/include",   # Homebrew on Apple Silicon
            "/opt/homebrew/include/OCTypes",
            "/opt/homebrew/include/SITypes",
            "/opt/homebrew/include/RMNLib",
            numpy.get_include()
        ],
        library_dirs=[
            # Use system-installed libraries
            "/usr/local/lib",
            "/opt/homebrew/lib"
        ],
        libraries=["RMNLib", "OCTypes", "SITypes", "curl"],
        language="c",
        # Add any needed compiler flags
        extra_compile_args=["-std=c99", "-Wno-unused-function"],
        extra_link_args=["-lcurl"]
    )
]

# Read long description from README
long_description = ""
if os.path.exists("README.md"):
    with open("README.md", "r", encoding="utf-8") as fh:
        long_description = fh.read()

setup(
    name="RMNpy",
    version="0.1.0",
    author="Philip Grandinetti",
    author_email="grandinetti.1@osu.edu",
    description="Python wrapper for RMNLib scientific data library",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/pjgrandinetti/RMNpy",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    ext_modules=cythonize(extensions, compiler_directives={'language_level': 3}),
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Science/Research",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Topic :: Scientific/Engineering",
    ],
    python_requires=">=3.8",
    install_requires=[
        "numpy>=1.20.0",
        "cython>=0.29.0",
    ],
    extras_require={
        "dev": [
            "pytest>=6.0",
            "pytest-cov",
            "black",
            "flake8",
            "mypy",
        ]
    },
    zip_safe=False,
)
