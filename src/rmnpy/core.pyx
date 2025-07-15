

# cython: language_level=3

# Main entry point for RMNpy Cython interface


# Python-level imports for public API
from .dataset import Dataset
from .datum import Datum
from .dependent_variable import DependentVariable
from .dimension import Dimension

# Expose module-level functions
def shutdown():
    """Clean up RMNLib and related library resources.
    This function should be called when shutting down the application
    to ensure proper cleanup of C library resources.
    """
    RMNLibTypesShutdown()

def get_version():
    """Get the version of RMNpy."""
    return "0.1.0"
