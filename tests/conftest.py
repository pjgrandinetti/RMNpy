import os
import subprocess
import sys

# Build Cython extensions early so extension modules exist before tests are collected
root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
subprocess.run(
    [sys.executable, "setup.py", "build_ext", "--inplace"], cwd=root_dir, check=False
)

# Ensure 'src' directory is on PYTHONPATH for imports
root_src = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src"))
if root_src not in sys.path:
    sys.path.insert(0, root_src)


# Automatically build Cython extension before running tests
def pytest_configure(config):
    # Only build once
    build_marker = os.path.join(os.path.dirname(__file__), ".built")
    if os.path.exists(build_marker):
        return
    sys.stdout.write("Building Cython extensions for tests...\n")
    # Run build_ext in place
    ret = subprocess.run(
        [sys.executable, "setup.py", "build_ext", "--inplace"], check=False
    )
    if ret.returncode != 0:
        sys.stderr.write("Failed to build Cython extensions\n")
    # Mark as built
    open(build_marker, "w").close()
