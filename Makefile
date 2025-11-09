# =============================================================================
# VPN/Proxy Agent - Project Automation
# =============================================================================
# Provides shortcuts for running tests and working with MkDocs documentation.
# Environment variables:
#   PYTHON - Python interpreter to use (default: python3)
#   MKDOCS - MkDocs executable (default: mkdocs)
#   PIP    - Pip command for installing dependencies (default: python3 -m pip)
# =============================================================================

PYTHON ?= python3
MKDOCS ?= mkdocs
PIP ?= $(PYTHON) -m pip

.PHONY: help test test-bash test-python docs-serve docs-build docs-deps clean

help:
	@echo "Available targets:"
	@echo "  help         - Show this help message"
	@echo "  test         - Run Bash and Python test suites"
	@echo "  test-bash    - Run the Bash utility test suite"
	@echo "  test-python  - Run the Python test suites with pytest"
	@echo "  docs-serve   - Serve documentation locally with MkDocs"
	@echo "  docs-build   - Build the static MkDocs site"
	@echo "  docs-deps    - Install MkDocs via pip"
	@echo "  clean        - Remove MkDocs build artifacts"

# Aggregate Tests -------------------------------------------------------------

test: test-bash test-python

# Bash Tests -----------------------------------------------------------------

test-bash:
	./tests/test_utilities.sh

# Python Tests ---------------------------------------------------------------

test-python:
	$(PYTHON) -m pytest tests

# Documentation --------------------------------------------------------------

docs-serve:
	$(MKDOCS) serve -f docs/mkdocs.yml

docs-build:
	$(MKDOCS) build -f docs/mkdocs.yml

docs-deps:
	$(PIP) install mkdocs

clean:
	rm -rf site/
