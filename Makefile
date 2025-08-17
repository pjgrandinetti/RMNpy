# Makefile for RMNpy - provides library synchronization with local or GitHub sources

.PHONY: synclib clean-libs help download-libs rebuild clean clean-all generate-constants bridge

# Default help target
help:
	@echo "RMNpy Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  synclib      - Copy SHARED libraries/headers from local ../directories (fixes type registry)"
	@echo "  download-libs - Download OCTypes, SITypes, and RMNLib libraries/headers from GitHub releases"
	@echo "  bridge       - Create Windows bridge DLL from static libraries (MSYS2/MinGW64)"
	@echo "  clean-libs   - Remove lib/ and include/ directories"
	@echo "  clean        - Remove generated C files and build artifacts"
	@echo "  clean-all    - Remove all generated files and libraries"
	@echo "  rebuild      - Clean libraries and rebuild Python package"
	@echo "  generate-constants - Generate SI quantity constants from C header file"
	@echo "  test         - Run the test suite"
	@echo "  test-wheel   - Build wheel and test that libraries are included"
	@echo "  check-wheel  - Check existing wheel files for required libraries"
	@echo "  help         - Show this help message"

# Copy libraries and headers from local directories
# Copy SHARED libraries and headers from local directories
# Note: Using shared libraries fixes type registry issues across multiple Cython modules
synclib:
	@echo "Synchronizing SHARED libraries from local directories..."
	@echo "Copying from ../OCTypes, ../SITypes, and ../RMNLib to lib/ and include/"
	@mkdir -p lib include/OCTypes include/SITypes include/RMNLib
	# Copy shared libraries (.dylib on macOS, .so on Linux, .dll on Windows)
	@if [ -f ../OCTypes/install/lib/libOCTypes.dylib ]; then \
		echo "  ✓ Copying libOCTypes.dylib (from ../OCTypes)"; \
		cp ../OCTypes/install/lib/libOCTypes.dylib lib/; \
	elif [ -f ../OCTypes/install/lib/libOCTypes.so ]; then \
		echo "  ✓ Copying libOCTypes.so (from ../OCTypes)"; \
		cp ../OCTypes/install/lib/libOCTypes.so lib/; \
	elif [ -f ../OCTypes/install/lib/libOCTypes.dll ]; then \
		echo "  ✓ Copying libOCTypes.dll (from ../OCTypes)"; \
		cp ../OCTypes/install/lib/libOCTypes.dll lib/; \
	else \
		echo "  ✗ libOCTypes shared library not found in ../OCTypes/install/lib/"; \
		echo "  Run 'make install-shared' in ../OCTypes first to build shared libraries"; \
		exit 1; \
	fi
	@if [ -f ../SITypes/install/lib/libSITypes.dylib ]; then \
		echo "  ✓ Copying libSITypes.dylib (from ../SITypes)"; \
		cp ../SITypes/install/lib/libSITypes.dylib lib/; \
	elif [ -f ../SITypes/install/lib/libSITypes.so ]; then \
		echo "  ✓ Copying libSITypes.so (from ../SITypes)"; \
		cp ../SITypes/install/lib/libSITypes.so lib/; \
	elif [ -f ../SITypes/install/lib/libSITypes.dll ]; then \
		echo "  ✓ Copying libSITypes.dll (from ../SITypes)"; \
		cp ../SITypes/install/lib/libSITypes.dll lib/; \
	else \
		echo "  ✗ libSITypes shared library not found in ../SITypes/install/lib/"; \
		echo "  Run 'make install-shared' in ../SITypes first to build shared libraries"; \
		exit 1; \
	fi
	@if [ -f ../RMNLib/install/lib/libRMN.dylib ]; then \
		echo "  ✓ Copying libRMN.dylib (from ../RMNLib)"; \
		cp ../RMNLib/install/lib/libRMN.dylib lib/; \
	elif [ -f ../RMNLib/install/lib/libRMN.so ]; then \
		echo "  ✓ Copying libRMN.so (from ../RMNLib)"; \
		cp ../RMNLib/install/lib/libRMN.so lib/; \
	elif [ -f ../RMNLib/install/lib/libRMN.dll ]; then \
		echo "  ✓ Copying libRMN.dll (from ../RMNLib)"; \
		cp ../RMNLib/install/lib/libRMN.dll lib/; \
	else \
		echo "  ✗ libRMN shared library not found in ../RMNLib/install/lib/"; \
		echo "  Run 'make install-shared' in ../RMNLib first to build shared libraries"; \
		exit 1; \
	fi
	@if [ -d ../OCTypes/install/include/OCTypes ]; then \
		echo "  ✓ Copying OCTypes headers (from ../OCTypes)"; \
		cp ../OCTypes/install/include/OCTypes/*.h include/OCTypes/; \
	elif [ -d OCTypes/install/include/OCTypes ]; then \
		echo "  ✓ Copying OCTypes headers (from OCTypes)"; \
		cp OCTypes/install/include/OCTypes/*.h include/OCTypes/; \
	else \
		echo "  ✗ OCTypes headers not found in ../OCTypes/install/include/OCTypes/ or OCTypes/install/include/OCTypes/"; \
		echo "  Run 'make install' in ../OCTypes or OCTypes first to create the organized header structure"; \
		exit 1; \
	fi
	@if [ -d ../SITypes/install/include/SITypes ]; then \
		echo "  ✓ Copying SITypes headers (from ../SITypes)"; \
		cp ../SITypes/install/include/SITypes/*.h include/SITypes/; \
	elif [ -d SITypes/install/include/SITypes ]; then \
		echo "  ✓ Copying SITypes headers (from SITypes)"; \
		cp SITypes/install/include/SITypes/*.h include/SITypes/; \
	else \
		echo "  ✗ SITypes headers not found in ../SITypes/install/include/SITypes/ or SITypes/install/include/SITypes/"; \
		echo "  Run 'make install' in ../SITypes or SITypes first to create the organized header structure"; \
		exit 1; \
	fi
	@if [ -d ../RMNLib/install/include/RMNLib ]; then \
		echo "  ✓ Copying RMNLib headers with proper structure (from ../RMNLib)"; \
		cp -r ../RMNLib/install/include/RMNLib/* include/RMNLib/; \
	elif [ -d RMNLib/install/include/RMNLib ]; then \
		echo "  ✓ Copying RMNLib headers with proper structure (from RMNLib)"; \
		cp -r RMNLib/install/include/RMNLib/* include/RMNLib/; \
	else \
		echo "  ✗ RMNLib headers not found in ../RMNLib/install/include/RMNLib/ or RMNLib/install/include/RMNLib/"; \
		echo "  Run 'make install' in ../RMNLib or RMNLib first to create the organized header structure"; \
		exit 1; \
	fi
	@echo "  ✓ SHARED library synchronization complete!"
	@echo ""
	@echo "Next steps:"
	@echo "  pip install -e . --force-reinstall"

# Download libraries from GitHub releases
download-libs:
	@echo "Downloading libraries from GitHub releases..."
	@echo "Removing existing lib/ and include/ directories..."
	@rm -rf lib/ include/
	@echo "  ✓ Existing libraries removed"
	@echo ""
	@echo "Libraries will be downloaded automatically during next build."
	@echo "Run: pip install -e . --force-reinstall"

# Remove local libraries to force GitHub download
clean-libs:
	@echo "Removing local lib/ and include/ directories..."
	@rm -rf lib/ include/
	@echo "  ✓ Local libraries removed. Next build will download from GitHub."

# Clean generated C files and build artifacts
clean:
	@echo "Cleaning generated C files and build artifacts..."
	@find src/rmnpy -name "*.c" -exec rm -f {} \; 2>/dev/null || true
	@find src/rmnpy -name "*.so" -exec rm -f {} \; 2>/dev/null || true
	@find . -name "__pycache__" -type d -exec rm -rf {} \; 2>/dev/null || true
	@find . -name "*.pyc" -exec rm -f {} \; 2>/dev/null || true
	@rm -rf build/
	@rm -rf dist/
	@rm -rf *.egg-info/
	@rm -rf .pytest_cache/
	@rm -rf htmlcov/
	@rm -f coverage.xml
	@rm -f .coverage
	@echo "  ✓ Generated files cleaned"

# Clean everything (libs and generated files)
clean-all: clean clean-libs
	@echo "  ✓ All files cleaned"

# Clean and rebuild
rebuild: clean-libs
	@echo "Rebuilding RMNpy package..."
	@pip install -e . --force-reinstall

# Generate SI quantity constants from C header file
generate-constants:
	@echo "Generating SI quantity constants from C header file..."
	@python scripts/extract_si_constants.py

# Run tests
test:
	@echo "Running RMNpy test suite..."
	@python -m pytest tests/ -v

# Check library status
status:
	@echo "RMNpy Library Status:"
	@echo ""
	@if [ -d lib ]; then \
		echo "Libraries in lib/:"; \
		ls -la lib/ 2>/dev/null || echo "  (empty)"; \
		echo ""; \
	else \
		echo "lib/ directory does not exist"; \
		echo ""; \
	fi
	@if [ -d include ]; then \
		echo "Headers in include/:"; \
		ls -la include/ 2>/dev/null || echo "  (empty)"; \
		echo ""; \
	else \
		echo "include/ directory does not exist"; \
		echo ""; \
	fi
	@echo "To sync from local development:"
	@echo "  make synclib"
	@echo ""
	@echo "To download from GitHub releases:"
	@echo "  make download-libs"

# Windows Bridge DLL creation (WindowsPlan.md implementation)
bridge:
	@echo "Creating Windows bridge DLL from static libraries..."
	@if [ ! -f lib/libOCTypes.a ] || [ ! -f lib/libSITypes.a ] || [ ! -f lib/libRMN.a ]; then \
		echo "  ✗ Required static libraries not found in lib/"; \
		echo "    Make sure lib/libOCTypes.a, lib/libSITypes.a, and lib/libRMN.a exist"; \
		echo "    Run 'make download-libs' or 'make synclib' first"; \
		exit 1; \
	fi
	@echo "  ✓ Found required static libraries"
	@mkdir -p lib
	@echo "  Creating bridge DLL: lib/rmnstack_bridge.dll"
	@x86_64-w64-mingw32-gcc -shared -o lib/rmnstack_bridge.dll \
		-Wl,--out-implib,lib/rmnstack_bridge.dll.a \
		-Wl,--export-all-symbols \
		lib/libRMN.a lib/libSITypes.a lib/libOCTypes.a \
		-lopenblas -llapack -lcurl -lgcc_s -lwinpthread -lquadmath -lgomp -lm || \
		(echo "  ✗ Bridge DLL creation failed. Make sure you're in MSYS2 MINGW64 environment"; exit 1)
	@if [ -f lib/rmnstack_bridge.dll ]; then \
		echo "  ✓ Successfully created lib/rmnstack_bridge.dll"; \
		echo "  ✓ Successfully created lib/rmnstack_bridge.dll.a (import library)"; \
		echo "  Checking exports..."; \
		objdump -p lib/rmnstack_bridge.dll | sed -n '/Export Table/,$$p' | head -n 20 || true; \
		echo "  Bridge DLL is ready for Python extensions"; \
	else \
		echo "  ✗ Bridge DLL creation failed"; \
		exit 1; \
	fi

# Test wheel building and verify libraries are included
test-wheel:
	@echo "Building wheel and testing library inclusion..."
	@rm -rf dist build
	@python -m build --wheel
	@echo "Verifying wheel contents..."
	@python scripts/check_wheel_libraries.py

# Check existing wheel files for required libraries
check-wheel:
	@echo "Checking existing wheel files..."
	@python scripts/check_wheel_libraries.py
