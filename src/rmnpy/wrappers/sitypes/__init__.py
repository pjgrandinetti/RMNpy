"""
SITypes Python wrappers

This module provides Python interfaces to the SITypes library for
scientific units, dimensional analysis, and physical quantities.
"""

import logging
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


# Pytest re-import detection and protection
def _is_pytest_reimport() -> bool:
    """Detect if this is a pytest re-import that could cause access violations"""
    if "pytest" not in sys.modules:
        return False

    # Check if this module is already fully loaded in sys.modules
    module_name = __name__
    if module_name in sys.modules:
        existing_module = sys.modules[module_name]
        # If the existing module has our classes, this is a re-import
        return (
            hasattr(existing_module, "Dimensionality")
            and hasattr(existing_module, "Scalar")
            and hasattr(existing_module, "Unit")
        )

    return False


# Initialize module-level variables
Dimensionality: Any = None
Scalar: Any = None
Unit: Any = None

# Main import logic with comprehensive pytest protection
if not _sitypes_extensions_loaded:
    is_pytest_reimport = _is_pytest_reimport()

    if is_pytest_reimport:
        _logger.info(
            "Detected pytest re-import - using module reuse to prevent access violation"
        )
        # Reuse the existing module to avoid re-importing C extensions
        existing_module = sys.modules[__name__]
        Dimensionality = existing_module.Dimensionality
        Scalar = existing_module.Scalar
        Unit = existing_module.Unit
        _sitypes_extensions_loaded = True
        _logger.info("Successfully reused existing SITypes extensions")
    else:
        _logger.info(
            "Importing SITypes C extension modules with comprehensive protection"
        )

        # Check if we're in a pytest context which can cause DLL conflicts
        if "pytest" in sys.modules:
            _logger.warning(
                "Detected pytest context - using enhanced defensive import strategy"
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
            _logger.info(
                "Successfully imported all SITypes extensions with comprehensive protection"
            )

        except Exception as e:
            _logger.error(f"Failed to import SITypes extensions: {e}")
            _logger.error(f"Exception type: {type(e)}")
            import traceback

            _logger.error(f"Full traceback: {traceback.format_exc()}")

            # In pytest context, provide graceful fallback
            if "pytest" in sys.modules:
                _logger.warning(
                    "In pytest context - creating dummy objects to prevent test collection failures"
                )
                # Create minimal dummy classes to allow pytest to continue

                class DummyDimensionality:
                    def __init__(self, *args: Any, **kwargs: Any) -> None:
                        pass

                class DummyScalar:
                    def __init__(self, *args: Any, **kwargs: Any) -> None:
                        pass

                class DummyUnit:
                    def __init__(self, *args: Any, **kwargs: Any) -> None:
                        pass

                Dimensionality = DummyDimensionality
                Scalar = DummyScalar
                Unit = DummyUnit
                _logger.warning(
                    "Using dummy objects - tests may be skipped but collection will continue"
                )
            else:
                raise
else:
    _logger.info("SITypes extensions already loaded - skipping re-import")

__all__ = ["Dimensionality", "Unit", "Scalar"]
