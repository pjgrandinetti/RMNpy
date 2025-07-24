"""
Test configuration and shared utilities

This module provides common test utilities and configuration
for the RMNpy test suite.
"""

import os
import sys

# Add the src directory to Python path for testing
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

# Common test fixtures and utilities will be added here as needed
