# Makefile for a Hugo website
#
# Usage:
#   make help
#   make dev
#   make dev-drafts
#   make build
#   make build-drafts
#   make clean
#   make new POST="my-first-post"
#
# Optional env vars:
#   HUGO=/path/to/hugo
#   THEME=PaperMod
#   BASEURL=https://example.com/
#   ENV=production|development
#   PORT=1313

SHELL := /bin/bash

HUGO ?= hugo
PORT ?= 1313
ENV ?= development
THEME ?=
PUBLIC_DIR ?= public
RESOURCES_DIR ?= resources
CONTENT_DIR ?= content

# Extra args you might want to pass through (e.g., make dev HUGO_ARGS="--disableFastRender")
HUGO_ARGS ?=

# If a theme name is provided, include it; otherwise leave blank.
ifneq ($(strip $(THEME)),)
	THEME_FLAG := --theme $(THEME)
else
	THEME_FLAG :=
endif

.DEFAULT_GOAL := help
.PHONY: help check version dev dev-drafts build build-drafts clean clean-public clean-resources new fmt

help: ## Show available targets
	@echo ""
	@echo "Hugo Make targets:"
	@awk 'BEGIN {FS = ":.*##"; printf ""} /^[a-zA-Z0-9_.-]+:.*##/ {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Examples:"
	@echo "  make dev"
	@echo "  make dev-drafts"
	@echo "  make build BASEURL=https://example.com/"
	@echo "  make new POST=\"my-first-post\""
	@echo ""

check: ## Verify Hugo is installed and hugo.toml exists
	@command -v $(HUGO) >/dev/null 2>&1 || { \
		echo "Error: '$(HUGO)' not found. Install Hugo or set HUGO=/path/to/hugo"; \
		exit 1; \
	}

	@test -f hugo.toml || { \
		echo "Error: hugo.toml not found at repo root."; \
		echo "This project enforces hugo.toml as the configuration file."; \
		exit 1; \
	}

	@echo "OK: Hugo found and hugo.toml present."


version: ## Print Hugo version
	@$(HUGO) version

dev: check ## Run local dev server
	@echo "Starting Hugo server on http://localhost:$(PORT) (ENV=$(ENV))"
	@HUGO_ENV=$(ENV) $(HUGO) server \
		--bind 0.0.0.0 \
		--port $(PORT) \
		--baseURL $(BASEURL) \
		$(THEME_FLAG) \
		$(HUGO_ARGS)

dev-drafts: check ## Run local server including drafts + future posts
	@echo "Starting Hugo server (drafts enabled) on http://localhost:$(PORT) (ENV=$(ENV))"
	@HUGO_ENV=$(ENV) $(HUGO) server \
		--bind 0.0.0.0 \
		--port $(PORT) \
		--baseURL $(BASEURL) \
		--buildDrafts \
		--buildFuture \
		--buildExpired \
		$(THEME_FLAG) \
		$(HUGO_ARGS)

build: check ## Production build into ./public
	@echo "Building site into ./$(PUBLIC_DIR) (ENV=production) BASEURL=$(BASEURL)"
	@HUGO_ENV=production $(HUGO) \
		--destination $(PUBLIC_DIR) \
		--baseURL $(BASEURL) \
		--minify \
		$(THEME_FLAG) \
		$(HUGO_ARGS)

build-drafts: check ## Build including drafts + future posts (useful for previews)
	@echo "Building site (drafts enabled) into ./$(PUBLIC_DIR)"
	@HUGO_ENV=production $(HUGO) \
		--destination $(PUBLIC_DIR) \
		--baseURL $(BASEURL) \
		--buildDrafts \
		--buildFuture \
		--buildExpired \
		$(THEME_FLAG) \
		$(HUGO_ARGS)

clean: clean-public clean-resources ## Remove build outputs (public/ and resources/)
	@echo "Cleaned."

clean-public: ## Remove ./public
	@rm -rf "$(PUBLIC_DIR)"

clean-resources: ## Remove ./resources (Hugo pipeline cache)
	@rm -rf "$(RESOURCES_DIR)"

# Create a new content page. You can override KIND, SECTION, or FILE if you want.
# Example: make new POST="hello-world"
# Result: content/posts/hello-world.md (depending on your archetypes/defaults)
KIND ?= posts
new: check ## Create a new post: make new POST="my-title"
	@test -n "$(POST)" || { echo "Error: provide POST, e.g. make new POST=\"my-title\""; exit 1; }
	@$(HUGO) new "$(KIND)/$(POST).md"
	@echo "Created: $(CONTENT_DIR)/$(KIND)/$(POST).md"

# Optional: basic formatting for common config formats (safe no-op if tools missing)
fmt: ## Format common config files if formatter tools are available
	@command -v prettier >/dev/null 2>&1 && prettier -w "**/*.{md,mdx,yml,yaml,json}" || true
	@command -v taplo >/dev/null 2>&1 && taplo format || true
	@echo "Formatting complete (where tools were available)."

