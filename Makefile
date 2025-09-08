# RMNpy Makefile — sync shared libs/headers and helper tasks
# IMPORTANT: recipe lines start with TABs.
#
# Quick Start:
#   make rebuild-from-source  - When C libraries (OCTypes/SITypes/RMNLib) are updated
#   make rebuild              - When only RMNpy Python code changed
#   make help                 - Show all available commands

SHELL := /bin/bash
MAKEFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

# Cross-platform detection
UNAME_S := $(shell uname -s)
IS_MINGW := $(findstring MINGW,$(UNAME_S))

# GitHub release configuration
GITHUB_OWNER := pjgrandinetti
OCTYPES_REPO := OCTypes
SITYPES_REPO := SITypes
RMNLIB_REPO := RMNLib

.PHONY: synclib download-libs clean-libs clean clean-all rebuild rebuild-from-source \
        test status test-wheel check-wheel help verify-c-libs

help:
	@echo "RMNpy Makefile"
	@echo ""
	@echo "📦 Development Workflow:"
	@echo "  rebuild-from-source - Complete rebuild: sync latest C libs + reinstall RMNpy"
	@echo "  rebuild             - Quick rebuild: reinstall RMNpy with existing local libs"
	@echo "  synclib             - Copy SHARED libs/headers from ../OCTypes, ../SITypes, ../RMNLib"
	@echo "  download-libs       - Download latest C libs from GitHub releases"
	@echo "  download-github-libs - Download latest C libs from GitHub releases"
	@echo ""
	@echo "🧹 Cleanup:"
	@echo "  clean-libs          - Remove lib/ and include/"
	@echo "  clean               - Remove build artifacts (keeps lib/include)"
	@echo "  clean-all           - Clean + remove lib/include"
	@echo ""
	@echo "🔍 Verification:"
	@echo "  verify-c-libs       - Check if C libraries are built and up-to-date"
	@echo "  status              - Show current lib/include contents"
	@echo ""
	@echo "🚀 Release & Testing:"
	@echo "  test                - Run tests"
	@echo "  test-wheel          - Build wheel and verify bundled libs"
	@echo "  check-wheel         - Verify existing wheel bundles required libs"
	@echo ""
	@echo "💡 Use 'rebuild-from-source' when C libraries (OCTypes/SITypes/RMNLib) are updated"

# --- paths
LIBDIR := lib
INCDIR := include
OCT_INC := $(INCDIR)/OCTypes
SIT_INC := $(INCDIR)/SITypes
RMN_INC := $(INCDIR)/RMNLib

# --- helpers
define _download_github_release
	@echo "  • Downloading $(2) from $(GITHUB_OWNER)/$(1)"
	@if [ "$(UNAME_S)" = "Darwin" ]; then \
	  platform="macos-latest"; \
	elif [ "$(UNAME_S)" = "Linux" ]; then \
	  if [ "$$(uname -m)" = "aarch64" ]; then \
	    platform="ubuntu-latest.arm64"; \
	  else \
	    platform="ubuntu-latest.x64"; \
	  fi; \
	else \
	  platform="windows-latest"; \
	fi; \
	zip_name="$(2)-$$platform.zip"; \
	latest_url=$$(curl -s "https://api.github.com/repos/$(GITHUB_OWNER)/$(1)/releases/latest" | grep "browser_download_url.*$$zip_name" | cut -d '"' -f 4); \
	if [ -z "$$latest_url" ]; then \
	  echo "✗ No $$zip_name asset found in latest release of $(1)"; exit 1; \
	fi; \
	echo "    → $$latest_url"; \
	curl -L "$$latest_url" -o "/tmp/$$zip_name"; \
	cd "$(LIBDIR)" && unzip -o "/tmp/$$zip_name"; \
	rm "/tmp/$$zip_name"
endef

define _download_and_extract_headers
	@echo "  • Downloading headers from $(GITHUB_OWNER)/$(1)"
	@zip_name="$(2)-headers.zip"; \
	latest_url=$$(curl -s "https://api.github.com/repos/$(GITHUB_OWNER)/$(1)/releases/latest" | grep "browser_download_url.*$$zip_name" | cut -d '"' -f 4); \
	if [ -z "$$latest_url" ]; then \
	  echo "✗ No $$zip_name asset found in latest release of $(1)"; exit 1; \
	fi; \
	echo "    → $$latest_url"; \
	curl -L "$$latest_url" -o "/tmp/$$zip_name"; \
	mkdir -p "$(3)"; \
	cd "$(3)" && unzip -o "/tmp/$$zip_name"; \
	rm "/tmp/$$zip_name"
endef

define _copy_one_shared
	if [ -f "$(1)/lib/$(2).dylib" ]; then \
	  cp "$(1)/lib/$(2).dylib" "$(LIBDIR)/"; \
	elif [ -f "$(1)/lib/$(2).so" ]; then \
	  cp "$(1)/lib/$(2).so" "$(LIBDIR)/"; \
	elif [ -f "$(1)/lib/$(2).dll" ]; then \
	  cp "$(1)/lib/$(2).dll" "$(LIBDIR)/"; \
	else \
	  echo "✗ $(2) shared lib not found under $(1)/lib/"; exit 1; \
	fi
endef

define _copy_headers
	if [ -d "$(1)" ]; then \
	  if [ -z "$(IS_MINGW)" ]; then \
	    cp -r "$(1)"/* "$(2)"/; \
	  else \
	    powershell -NoProfile -Command "Copy-Item -Path '$(1)/*' -Destination '$(2)/' -Recurse -Force"; \
	  fi; \
	else \
	  echo "✗ headers not found: $(1)"; exit 1; \
	fi
endef

# verify-c-libs: check if C libraries exist and are built
verify-c-libs:
	@echo "→ Verifying C library dependencies…"
	@missing=0; \
	for proj in OCTypes SITypes RMNLib; do \
	  install_dir="../$$proj/install"; \
	  if [ ! -d "$$install_dir" ]; then \
	    echo "✗ $$proj: install directory missing ($$install_dir)"; \
	    echo "  Run 'make install' in ../$$proj/"; \
	    missing=1; \
	  else \
	    lib_count=$$(find "$$install_dir/lib" -name "*.dylib" -o -name "*.so" -o -name "*.dll" 2>/dev/null | wc -l); \
	    header_count=$$(find "$$install_dir/include" -name "*.h" 2>/dev/null | wc -l); \
	    if [ "$$lib_count" -eq 0 ]; then \
	      echo "✗ $$proj: no libraries found in $$install_dir/lib/"; \
	      echo "  Run 'make install' in ../$$proj/"; \
	      missing=1; \
	    elif [ "$$header_count" -eq 0 ]; then \
	      echo "✗ $$proj: no headers found in $$install_dir/include/"; \
	      echo "  Run 'make install' in ../$$proj/"; \
	      missing=1; \
	    else \
	      echo "✓ $$proj: $$lib_count libs, $$header_count headers"; \
	    fi; \
	  fi; \
	done; \
	if [ "$$missing" -eq 1 ]; then \
	  echo ""; \
	  echo "❌ Some C libraries are missing or not built."; \
	  echo "   Build them first, then run 'make rebuild-from-source'"; \
	  exit 1; \
	else \
	  echo "✅ All C library dependencies are available."; \
	fi

# synclib: copy SHARED libs + headers from sibling projects (../*)
synclib: verify-c-libs
	@echo "→ Synchronizing SHARED libraries and headers into RMNpy…"
	@mkdir -p "$(LIBDIR)" "$(OCT_INC)" "$(SIT_INC)" "$(RMN_INC)"
	@echo "  • OCTypes"
	@$(call _copy_one_shared,../OCTypes/install,libOCTypes)
	@$(call _copy_headers,../OCTypes/install/include/OCTypes,$(OCT_INC))
	@echo "  • SITypes"
	@$(call _copy_one_shared,../SITypes/install,libSITypes)
	@$(call _copy_headers,../SITypes/install/include/SITypes,$(SIT_INC))
	@echo "  • RMNLib"
	@$(call _copy_one_shared,../RMNLib/install,libRMN)
	@$(call _copy_headers,../RMNLib/install/include/RMNLib,$(RMN_INC))
	@echo "✓ Done. Bundled libs are in $(LIBDIR)/ and headers in $(INCDIR)/"

# rebuild-from-source: complete rebuild when C libraries are updated
rebuild-from-source: verify-c-libs clean-libs synclib
	@echo "→ Rebuilding RMNpy from latest C libraries…"
	@pip install -e . --force-reinstall
	@echo "✅ RMNpy rebuilt successfully with latest C libraries!"
	@echo ""
	@echo "💡 To verify the rebuild worked:"
	@echo "   - Restart your Python kernel/REPL"
	@echo "   - Test your changes"

rebuild: clean-libs
	@echo "→ Reinstalling RMNpy (editable) with existing local libs…"
	@if [ ! -d "$(LIBDIR)" ] || [ ! -d "$(INCDIR)" ]; then \
	  echo "⚠️  No local libs found. Running synclib first…"; \
	  $(MAKE) synclib; \
	fi
	@pip install -e . --force-reinstall
	@echo "✅ RMNpy rebuilt successfully!"

# download-libs: fetch latest C libraries from GitHub releases
download-libs: clean-libs
	@echo "→ Downloading latest C libraries from GitHub releases…"
	@mkdir -p "$(LIBDIR)" "$(OCT_INC)" "$(SIT_INC)" "$(RMN_INC)"
	@echo "  Fetching OCTypes..."
	@$(call _download_github_release,$(OCTYPES_REPO),libOCTypes)
	@$(call _download_and_extract_headers,$(OCTYPES_REPO),libOCTypes,$(OCT_INC))
	@echo "  Fetching SITypes..."
	@$(call _download_github_release,$(SITYPES_REPO),libSITypes)
	@$(call _download_and_extract_headers,$(SITYPES_REPO),libSITypes,$(SIT_INC))
	@echo "  Fetching RMNLib..."
	@$(call _download_github_release,$(RMNLIB_REPO),libRMN)
	@$(call _download_and_extract_headers,$(RMNLIB_REPO),libRMN,$(RMN_INC))
	@echo "✅ Downloaded latest libraries from GitHub releases!"
	@echo "💡 Run 'make rebuild' to reinstall RMNpy with these libraries"

clean-libs:
	@echo "→ Removing $(LIBDIR)/ and $(INCDIR)/ …"
	@rm -rf "$(LIBDIR)" "$(INCDIR)"
	@echo "✓ Removed."

clean:
	@echo "→ Cleaning Python/Cython build artifacts…"
	@find src/rmnpy -name "*.c" -o -name "*.cpp" -o -name "*.html" -o -name "*.so" -o -name "*.pyd" -o -name "*.dll" -o -name "*.dylib" | xargs -r rm -f
	@rm -rf build dist *.egg-info .pytest_cache htmlcov .mypy_cache .coverage coverage.xml
	@echo "✓ Clean."

clean-all: clean clean-libs

test:
	@echo "→ Running tests…"
	@python -m pytest -v

status:
	@echo "== Current Status =="
	@echo "lib/ directory:"
	@if [ -d "$(LIBDIR)" ]; then \
	  ls -la "$(LIBDIR)" | head -10; \
	  lib_count=$$(find "$(LIBDIR)" -name "*.dylib" -o -name "*.so" -o -name "*.dll" 2>/dev/null | wc -l); \
	  echo "  → $$lib_count library files found"; \
	else \
	  echo "  (missing - run 'make synclib')"; \
	fi
	@echo ""
	@echo "include/ directory:"
	@if [ -d "$(INCDIR)" ]; then \
	  ls -la "$(INCDIR)"; \
	  header_count=$$(find "$(INCDIR)" -name "*.h" 2>/dev/null | wc -l); \
	  echo "  → $$header_count header files found"; \
	else \
	  echo "  (missing - run 'make synclib')"; \
	fi

test-wheel:
	@echo "→ Building wheel and verifying bundled libs…"
	@rm -rf dist build
	@python -m build --wheel
	@python scripts/check_wheel_libraries.py

check-wheel:
	@python scripts/check_wheel_libraries.py
