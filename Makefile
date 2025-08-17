# RMNpy Makefile — sync shared libs/headers and helper tasks
# IMPORTANT: recipe lines start with TABs.

SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

# Cross-platform detection
UNAME_S := $(shell uname -s)
IS_MINGW := $(findstring MINGW,$(UNAME_S))

.PHONY: synclib download-libs clean-libs clean clean-all rebuild \
        generate-constants test status test-wheel check-wheel help bridge

help:
	@echo "RMNpy Makefile"
	@echo "  synclib         - Copy SHARED libs/headers from ../OCTypes, ../SITypes, ../RMNLib"
	@echo "  download-libs   - Purge lib/include; next build/wheel should bundle fresh libs"
	@echo "  bridge          - Create Windows bridge DLL from static libs in lib/ (MSYS2/MinGW64)"
	@echo "  clean-libs      - Remove lib/ and include/"
	@echo "  clean           - Remove build artifacts (keeps lib/include)"
	@echo "  clean-all       - Clean + remove lib/include"
	@echo "  rebuild         - Clean libs and reinstall package (editable)"
	@echo "  generate-constants - Generate SI quantity constants"
	@echo "  test            - Run tests"
	@echo "  test-wheel      - Build wheel and verify bundled libs"
	@echo "  check-wheel     - Verify existing wheel bundles required libs"
	@echo "  status          - Show current lib/include contents"

# --- paths
LIBDIR := lib
INCDIR := include
OCT_INC := $(INCDIR)/OCTypes
SIT_INC := $(INCDIR)/SITypes
RMN_INC := $(INCDIR)/RMNLib

# --- helpers
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

# synclib: copy SHARED libs + headers from sibling projects (../*)
synclib:
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

# Optional convenience: purge local bundles so the next wheel build re-bundles
download-libs: clean-libs
	@echo "Local lib/include purged. Next build will bundle fresh libs."

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

rebuild: clean-libs
	@echo "→ Reinstalling RMNpy (editable)…"
	@pip install -e . --force-reinstall

generate-constants:
	@echo "→ Generating SI quantity constants…"
	@python scripts/extract_si_constants.py

test:
	@echo "→ Running tests…"
	@python -m pytest -v

status:
	@echo "== lib/"
	@ls -la "$(LIBDIR)" 2>/dev/null || echo "(missing)"
	@echo "== include/"
	@ls -la "$(INCDIR)" 2>/dev/null || echo "(missing)"

test-wheel:
	@echo "→ Building wheel and verifying bundled libs…"
	@rm -rf dist build
	@python -m build --wheel
	@python scripts/check_wheel_libraries.py

check-wheel:
	@python scripts/check_wheel_libraries.py

# Windows-only: build a bridge DLL from static libs (optional)
bridge:
	@echo "→ Building Windows bridge DLL (MSYS2/MinGW64)…"
	@if [ ! -f "$(LIBDIR)/libOCTypes.a" ] || [ ! -f "$(LIBDIR)/libSITypes.a" ] || [ ! -f "$(LIBDIR)/libRMN.a" ]; then \
	  echo "✗ Need libOCTypes.a, libSITypes.a, libRMN.a in $(LIBDIR)/"; exit 1; \
	fi
	@x86_64-w64-mingw32-gcc -shared -o $(LIBDIR)/rmnstack_bridge.dll \
	  -Wl,--out-implib,$(LIBDIR)/rmnstack_bridge.dll.a \
	  -Wl,--export-all-symbols \
	  $(LIBDIR)/libRMN.a $(LIBDIR)/libSITypes.a $(LIBDIR)/libOCTypes.a \
	  -lopenblas -llapack -lcurl -lgcc_s -lwinpthread -lquadmath -lgomp -lm
	@echo "✓ bridge: $(LIBDIR)/rmnstack_bridge.dll"
