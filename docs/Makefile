# Makefile for Sphinx documentation

# You can set these variables from the command line, and also
# from the environment for the first two.
SPHINXOPTS    ?=
SPHINXBUILD  ?= sphinx-build
SOURCEDIR    = .
BUILDDIR     = _build

# Put it first so that "make" without argument is like "make help".
help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.PHONY: help Makefile

# Install documentation dependencies
install:
	pip install -r requirements.txt

# Clean build files
clean:
	rm -rf $(BUILDDIR)

# Build HTML documentation
html:
	@$(SPHINXBUILD) -M html "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

# Build HTML and open in browser
html-open: html
	@echo "Opening documentation in browser..."
	@open $(BUILDDIR)/html/index.html || xdg-open $(BUILDDIR)/html/index.html || start $(BUILDDIR)/html/index.html

# Live reload development server
livehtml:
	@if command -v sphinx-autobuild >/dev/null 2>&1; then \
		sphinx-autobuild "$(SOURCEDIR)" "$(BUILDDIR)/html" $(SPHINXOPTS) --port 8000 --host 0.0.0.0; \
	else \
		echo "sphinx-autobuild not found. Install with: pip install sphinx-autobuild"; \
		echo "Then run: make livehtml"; \
	fi

# Check for broken links
linkcheck:
	@$(SPHINXBUILD) -M linkcheck "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

# Build PDF documentation (requires LaTeX)
latexpdf:
	@$(SPHINXBUILD) -M latexpdf "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

# Check documentation for common issues
doctest:
	@$(SPHINXBUILD) -M doctest "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

# Build documentation and check for warnings
strict:
	@$(SPHINXBUILD) -W -b html "$(SOURCEDIR)" "$(BUILDDIR)/html" $(SPHINXOPTS) $(O)

# Quick development build (minimal processing)
dev:
	@$(SPHINXBUILD) -b html "$(SOURCEDIR)" "$(BUILDDIR)/html" -E -a $(SPHINXOPTS) $(O)

# Deploy to GitHub Pages (for CI/CD)
deploy: clean html
	@echo "Documentation built successfully"
	@echo "Deploy the contents of $(BUILDDIR)/html/ to your web server"

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)
