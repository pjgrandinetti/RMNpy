# Makefile for RMNpy - provides library synchronization with local or GitHub sources

.PHONY: synclib clean-libs help download-libs rebuild clean clean-all generate-constants

# Default help target
help:
	@echo "RMNpy Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  synclib      - Copy OCTypes, SITypes, and RMNLib libraries/headers from local ../directories"
	@echo "  download-libs - Download OCTypes, SITypes, and RMNLib libraries/headers from GitHub releases"
	@echo "  clean-libs   - Remove lib/ and include/ directories"
	@echo "  clean        - Remove generated C files and build artifacts"
	@echo "  clean-all    - Remove all generated files and libraries"
	@echo "  rebuild      - Clean libraries and rebuild Python package"
	@echo "  generate-constants - Generate SI quantity constants from C header file"
	@echo "  test         - Run the test suite"
	@echo "  help         - Show this help message"

# Copy libraries and headers from local directories
synclib:
	@echo "Synchronizing libraries from local directories..."
	@echo "Copying from ../OCTypes, ../SITypes, and ../RMNLib to lib/ and include/"
	@mkdir -p lib include/OCTypes include/SITypes include/RMNLib
	@if [ -f ../OCTypes/install/lib/libOCTypes.a ]; then \
		echo "  ✓ Copying libOCTypes.a (from ../OCTypes)"; \
		cp ../OCTypes/install/lib/libOCTypes.a lib/; \
	elif [ -f OCTypes/install/lib/libOCTypes.a ]; then \
		echo "  ✓ Copying libOCTypes.a (from OCTypes)"; \
		cp OCTypes/install/lib/libOCTypes.a lib/; \
	else \
		echo "  ✗ libOCTypes.a not found in ../OCTypes/install/lib/ or OCTypes/install/lib/"; \
		echo "  Run 'make install' in ../OCTypes or OCTypes first to build and install the library"; \
		exit 1; \
	fi
	@if [ -f ../SITypes/install/lib/libSITypes.a ]; then \
		echo "  ✓ Copying libSITypes.a (from ../SITypes)"; \
		cp ../SITypes/install/lib/libSITypes.a lib/; \
	elif [ -f SITypes/install/lib/libSITypes.a ]; then \
		echo "  ✓ Copying libSITypes.a (from SITypes)"; \
		cp SITypes/install/lib/libSITypes.a lib/; \
	else \
		echo "  ✗ libSITypes.a not found in ../SITypes/install/lib/ or SITypes/install/lib/"; \
		echo "  Run 'make install' in ../SITypes or SITypes first to build and install the library"; \
		exit 1; \
	fi
	@if [ -f ../RMNLib/install/lib/libRMN.a ]; then \
		echo "  ✓ Copying libRMN.a (from ../RMNLib)"; \
		cp ../RMNLib/install/lib/libRMN.a lib/; \
	elif [ -f RMNLib/install/lib/libRMN.a ]; then \
		echo "  ✓ Copying libRMN.a (from RMNLib)"; \
		cp RMNLib/install/lib/libRMN.a lib/; \
	else \
		echo "  ✗ libRMN.a not found in ../RMNLib/install/lib/ or RMNLib/install/lib/"; \
		echo "  Run 'make install' in ../RMNLib or RMNLib first to build and install the library"; \
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
	@echo "  ✓ Library synchronization complete!"
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
