#!/usr/bin/env python3
"""
Backward compatibility wrapper for test_runner.py
The actual test runner is now located in tests/test_runner.py
"""

import sys
import os

# Add the tests directory to Python path
tests_dir = os.path.join(os.path.dirname(__file__), 'tests')
sys.path.insert(0, tests_dir)

# Import and run the actual test runner
if __name__ == "__main__":
    try:
        # Change to the project root directory for the test runner
        original_cwd = os.getcwd()
        project_root = os.path.dirname(__file__)
        os.chdir(project_root)
        
        # Import and execute the test runner
        from test_runner import main
        main()
    except ImportError as e:
        print(f"Error: Could not import test runner: {e}")
        print("Please run the test runner directly: python tests/test_runner.py")
        sys.exit(1)
    finally:
        # Restore original working directory
        os.chdir(original_cwd)
