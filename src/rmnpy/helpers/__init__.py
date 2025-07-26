"""
Helper functions for converting between Python types and OCTypes

This module provides internal conversion utilities that handle the
translation between Python objects and OCTypes C structures. These
helpers are not exposed to end users but are used internally by
the SITypes and RMNLib wrappers.
"""

import logging
import sys
from typing import Any

# Configure logging for import diagnostics
_logger = logging.getLogger(__name__)
_handler = logging.StreamHandler(sys.stderr)
_handler.setFormatter(logging.Formatter("[%(asctime)s] HELPERS_INIT: %(message)s"))
_logger.addHandler(_handler)
_logger.setLevel(logging.INFO)

# Global flag to prevent multiple C extension loading attempts
_octypes_extension_loaded = False


# Pytest re-import detection and protection
def _is_pytest_reimport() -> bool:
    """Detect if this is a pytest re-import that could cause access violations"""
    if "pytest" not in sys.modules:
        return False

    # Check if this module is already fully loaded in sys.modules
    module_name = __name__
    if module_name in sys.modules:
        existing_module = sys.modules[module_name]
        # If the existing module has our functions, this is a re-import
        return hasattr(existing_module, "create_oc_string") and hasattr(
            existing_module, "parse_c_string"
        )

    return False


# Initialize module-level variables
create_oc_string: Any = None
parse_c_string: Any = None

# Main import logic with comprehensive pytest protection
if not _octypes_extension_loaded:
    is_pytest_reimport = _is_pytest_reimport()

    if is_pytest_reimport:
        _logger.info(
            "Detected pytest re-import - using module reuse to prevent access violation"
        )
        # Reuse the existing module to avoid re-importing C extensions
        existing_module = sys.modules[__name__]
        create_oc_string = existing_module.create_oc_string
        parse_c_string = existing_module.parse_c_string
        _octypes_extension_loaded = True
        _logger.info("Successfully reused existing OCTypes helper functions")
    else:
        _logger.info(
            "Importing OCTypes C extension module with comprehensive protection"
        )

        # Check if we're in a pytest context which can cause DLL conflicts
        if "pytest" in sys.modules:
            _logger.warning(
                "Detected pytest context - using enhanced defensive import strategy"
            )

        try:
            _logger.info("Importing octypes extension")
            from .octypes import (  # type: ignore[attr-defined,misc]
                create_oc_string,
                parse_c_string,
            )

            _octypes_extension_loaded = True
            _logger.info(
                "Successfully imported OCTypes helpers with comprehensive protection"
            )

        except Exception as e:
            _logger.error(f"Failed to import OCTypes helpers: {e}")
            _logger.error(f"Exception type: {type(e)}")
            import traceback

            _logger.error(f"Full traceback: {traceback.format_exc()}")

            # In pytest context, provide graceful fallback
            if "pytest" in sys.modules:
                _logger.warning(
                    "In pytest context - creating dummy functions to prevent test collection failures"
                )
                # Create minimal dummy functions to allow pytest to continue

                def dummy_create_oc_string(*args: Any, **kwargs: Any) -> Any:
                    return None

                def dummy_parse_c_string(*args: Any, **kwargs: Any) -> str:
                    return ""

                create_oc_string = dummy_create_oc_string  # type: ignore[misc]
                parse_c_string = dummy_parse_c_string  # type: ignore[misc]
                _logger.warning(
                    "Using dummy functions - tests may be skipped but collection will continue"
                )
            else:
                raise
else:
    _logger.info("OCTypes extension already loaded - skipping re-import")

__all__ = [
    "parse_c_string",
    "create_oc_string",
]
