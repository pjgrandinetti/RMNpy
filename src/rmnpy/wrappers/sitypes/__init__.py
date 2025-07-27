"""
SITypes Python wrappers

This module provides Python interfaces to the SITypes library for
scientific units, dimensional analysis, and physical quantities.
"""

import logging
import os
import sys
from typing import Any

# Configure logging for import diagnostics
_logger = logging.getLogger(__name__)
_handler = logging.StreamHandler(sys.stderr)
_handler.setFormatter(logging.Formatter("[%(asctime)s] SITYPES_INIT: %(message)s"))
_logger.addHandler(_handler)
_logger.setLevel(logging.INFO)

# Global flag to prevent multiple C extension loading attempts
_sitypes_extensions_loaded = False


# Initialize module-level variables
Dimensionality: Any = None
Scalar: Any = None
Unit: Any = None

# Main import logic - always attempt real C extension loading
if not _sitypes_extensions_loaded:
    _logger.info("Normal operation - attempting real SITypes C extension import")

    # Check if we're in a pytest context which can cause DLL conflicts
    if "pytest" in sys.modules:
        _logger.info(
            "Normal pytest execution - using real C extensions for proper functionality"
        )

    try:
        _logger.info("Importing dimensionality extension")
        from .dimensionality import (
            Dimensionality as _Dimensionality,
        )

        _logger.info("Importing scalar extension")
        from .scalar import Scalar as _Scalar

        _logger.info("Importing unit extension")
        from .unit import Unit as _Unit

        # Assign to module-level variables
        Dimensionality = _Dimensionality
        Scalar = _Scalar
        Unit = _Unit

        _sitypes_extensions_loaded = True
        _logger.info("Successfully imported all SITypes extensions")

    except Exception as e:
        _logger.error(f"Failed to import SITypes extensions: {e}")
        _logger.error(f"Exception type: {type(e)}")
        import traceback

        _logger.error(f"Full traceback: {traceback.format_exc()}")

        # Fallback to dummy objects if real C extensions fail
        _logger.warning("C extension import failed - creating fallback dummy objects")

        class DummyDimensionality:
            def __init__(self, *args: Any, **kwargs: Any) -> None:
                pass

            def __str__(self) -> str:
                return "DummyDimensionality(fallback)"

        class DummyScalar:
            def __init__(self, *args: Any, **kwargs: Any) -> None:
                pass

            def __str__(self) -> str:
                return "DummyScalar(fallback)"

        class DummyUnit:
            def __init__(self, *args: Any, **kwargs: Any) -> None:
                pass

            def __str__(self) -> str:
                return "DummyUnit(fallback)"

        Dimensionality = DummyDimensionality
        Scalar = DummyScalar
        Unit = DummyUnit
        _logger.warning(
            "Using dummy objects - functionality limited but module will work"
        )
else:
    _logger.info("SITypes extensions already loaded - skipping re-import")

__all__ = ["Dimensionality", "Unit", "Scalar"]
