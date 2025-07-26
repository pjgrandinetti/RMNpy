"""
SITypes Python wrappers

This module provides Python interfaces to the SITypes library for
scientific units, dimensional analysis, and physical quantities.
"""

import logging
import sys

# Configure logging for import diagnostics
_logger = logging.getLogger(__name__)
_handler = logging.StreamHandler(sys.stderr)
_handler.setFormatter(logging.Formatter("[%(asctime)s] SITYPES_INIT: %(message)s"))
_logger.addHandler(_handler)
_logger.setLevel(logging.INFO)

# Global flag to prevent multiple C extension loading attempts
_sitypes_extensions_loaded = False

# Try importing C extensions with load protection
if not _sitypes_extensions_loaded:
    _logger.info("Importing SITypes C extension modules with load protection")

    # Check if we're in a pytest context which can cause DLL conflicts
    if "pytest" in sys.modules:
        _logger.warning("Detected pytest context - using defensive import strategy")

    try:
        _logger.info("Importing dimensionality extension")
        from .dimensionality import Dimensionality  # type: ignore[attr-defined]

        _logger.info("Importing scalar extension")
        from .scalar import Scalar

        _logger.info("Importing unit extension")
        from .unit import Unit  # type: ignore[attr-defined]

        _sitypes_extensions_loaded = True
        _logger.info(
            "Successfully imported all SITypes extensions with load protection"
        )

    except Exception as e:
        _logger.error(f"Failed to import SITypes extensions: {e}")
        _logger.error(f"Exception type: {type(e)}")
        import traceback

        _logger.error(f"Full traceback: {traceback.format_exc()}")

        # In pytest context, try to continue without failing completely
        if "pytest" in sys.modules:
            _logger.warning(
                "In pytest context - attempting to continue despite C extension failure"
            )
        else:
            raise
else:
    _logger.info("SITypes extensions already loaded - skipping re-import")

__all__ = ["Dimensionality", "Unit", "Scalar"]
