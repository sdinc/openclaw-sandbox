IMAGE ?= openclaw-sandbox:dev

# OpenClaw version - NOTE: Dockerfile is the source of truth
# This should match the version in Dockerfile FROM line
OPENCLAW_VERSION ?= 2026.5.20

PLATFORM ?= linux/amd64
PLATFORM_ARCH ?= amd64
CURDIR ?= `pwd`
CMD ?= zsh
cmd ?=
MOUNT_SSH ?= 1
MOUNT_ZSHRC ?= 1
MOUNT_GH ?= 1
MOUNT_GITCONFIG ?= 1
REQUIRE_TTY ?= 1
.DEFAULT_GOAL := help

CONTAINERDIR ?= /opt/workspace

# Detect if we're already inside the container (user is 'node')
IN_CONTAINER := $(shell [ "$$(whoami)" = "node" ] && echo 1 || echo 0)

.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*## "}; /^[a-zA-Z0-9_-]+:.*## / {printf "%-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: build
build: ## Build the dev image using OpenClaw base
	@cache_from=""; \
	cache_to=""; \
	docker_cmd="docker build"; \
	if [ -n "$$GITHUB_ACTIONS" ]; then \
		docker_cmd="docker buildx build --load"; \
		cache_from="--cache-from type=local,src=/tmp/.buildx-cache"; \
		cache_to="--cache-to type=local,dest=/tmp/.buildx-cache-new,mode=max"; \
	fi; \
	$$docker_cmd --platform=$(PLATFORM) \
		--build-arg OPENCLAW_VERSION=$(OPENCLAW_VERSION) \
		--build-arg PLATFORM_ARCH=$(PLATFORM_ARCH) \
		$$cache_from \
		$$cache_to \
		-t $(IMAGE) .

.PHONY: run
run: ## Run zsh in the container (mounts repo + ~/.ssh + ~/.zshrc)
ifeq ($(IN_CONTAINER),1)
	@run_cmd="$(CMD)"; \
	if [ -n "$(cmd)" ]; then run_cmd="$(cmd)"; fi; \
	echo "Already in container, running command directly: $$run_cmd"; \
	$$run_cmd
else
	@run_cmd="$(CMD)"; \
	if [ -n "$(cmd)" ]; then run_cmd="$(cmd)"; fi; \
	has_tty=0; [ -t 0 ] && [ -t 1 ] && has_tty=1 || true; \
	if [ "$$has_tty" -ne 1 ] && [ "$(REQUIRE_TTY)" = "1" ] && [ "$$run_cmd" = "zsh" ]; then \
		echo "run requires a TTY for an interactive shell."; \
		echo "Tip: run from a terminal, or pass REQUIRE_TTY=0, or set CMD=\"zsh -lc '...'.\""; \
		exit 2; \
	fi; \
	it_flags="$$( [ "$$has_tty" -eq 1 ] && printf '%s' '-it' || printf '%s' '-i' )"; \
	ssh_mount="$$( [ "$(MOUNT_SSH)" = "1" ] && printf '%s' '-v $(HOME)/.ssh:/root/.ssh' || true )"; \
	zshrc_mount="$$( [ "$(MOUNT_ZSHRC)" = "1" ] && printf '%s' '-v $(HOME)/.zshrc:/root/.zshrc' || true )"; \
	gh_mount="$$( [ "$(MOUNT_GH)" = "1" ] && printf '%s' '-v $(HOME)/.config/gh:/root/.config/gh' || true )"; \
	gitconfig_mount="$$( [ "$(MOUNT_GITCONFIG)" = "1" ] && printf '%s' '-v $(HOME)/.gitconfig:/root/.gitconfig' || true )"; \
	docker run --rm $$it_flags --platform=$(PLATFORM) \
		-v "$(CURDIR)":"$(CONTAINERDIR)" \
		-w "$(CONTAINERDIR)" \
		$$ssh_mount \
		$$zshrc_mount \
		$$gh_mount \
		$$gitconfig_mount \
		$(IMAGE) $$run_cmd
endif

.PHONY: run-shell-clean
run-shell-clean: ## Run zsh without mounting ~/.zshrc
ifeq ($(IN_CONTAINER),1)
	@run_cmd="$(CMD)"; \
	if [ -n "$(cmd)" ]; then run_cmd="$(cmd)"; fi; \
	echo "Already in container, running command directly: $$run_cmd"; \
	$$run_cmd
else
	$(MAKE) run MOUNT_ZSHRC=0 cmd="$(cmd)" CMD="$(CMD)"
endif

.PHONY: version-check
version-check: ## Validate version consistency across all package files
	@echo "🔍 Checking OpenClaw version consistency..."
	@echo ""
	@dockerfile_version=$$(grep -E '^FROM ghcr.io/openclaw/openclaw:' Dockerfile | sed -E 's/.*:([0-9]+\.[0-9]+\.[0-9]+)-.*/\1/'); \
	if [ -z "$$dockerfile_version" ]; then \
		echo "❌ ERROR: Could not extract version from Dockerfile"; \
		exit 1; \
	fi; \
	echo "📋 Source of Truth (Dockerfile): $$dockerfile_version"; \
	echo ""; \
	all_match=true; \
	makefile_version=$$(grep -E '^OPENCLAW_VERSION \?=' Makefile | sed -E 's/.*= ([0-9]+\.[0-9]+\.[0-9]+).*/\1/'); \
	if [ "$$makefile_version" = "$$dockerfile_version" ]; then \
		echo "✅ Makefile: $$makefile_version (matches)"; \
	else \
		echo "❌ Makefile: $$makefile_version (expected $$dockerfile_version)"; \
		all_match=false; \
	fi; \
	package_json_version=$$(grep -E '"openclaw_version"' package.json 2>/dev/null | sed -E 's/.*"openclaw_version": "([0-9]+\.[0-9]+\.[0-9]+)".*/\1/'); \
	if [ -z "$$package_json_version" ]; then \
		echo "❌ package.json: openclaw_version field not found (expected $$dockerfile_version)"; \
		all_match=false; \
	elif [ "$$package_json_version" = "$$dockerfile_version" ]; then \
		echo "✅ package.json: $$package_json_version (matches)"; \
	else \
		echo "❌ package.json: $$package_json_version (expected $$dockerfile_version)"; \
		all_match=false; \
	fi; \
	pyproject_version=$$(grep -E 'openclaw_version = ' pyproject.toml 2>/dev/null | sed -E 's/.*= "([0-9]+\.[0-9]+\.[0-9]+)".*/\1/'); \
	if [ -z "$$pyproject_version" ]; then \
		echo "❌ pyproject.toml: openclaw_version field not found (expected $$dockerfile_version)"; \
		all_match=false; \
	elif [ "$$pyproject_version" = "$$dockerfile_version" ]; then \
		echo "✅ pyproject.toml: $$pyproject_version (matches)"; \
	else \
		echo "❌ pyproject.toml: $$pyproject_version (expected $$dockerfile_version)"; \
		all_match=false; \
	fi; \
	echo ""; \
	if [ "$$all_match" = "true" ]; then \
		echo "✨ All versions match! Version consistency check passed."; \
	else \
		echo "💥 Version mismatch detected! Please update all files to match Dockerfile version $$dockerfile_version"; \
		echo ""; \
		echo "To fix, update the following:"; \
		if [ "$$makefile_version" != "$$dockerfile_version" ]; then \
			echo "  - Makefile: OPENCLAW_VERSION ?= $$dockerfile_version"; \
		fi; \
		if [ -z "$$package_json_version" ] || [ "$$package_json_version" != "$$dockerfile_version" ]; then \
			echo "  - package.json: \"openclaw_version\": \"$$dockerfile_version\""; \
		fi; \
		if [ -z "$$pyproject_version" ] || [ "$$pyproject_version" != "$$dockerfile_version" ]; then \
			echo "  - pyproject.toml: openclaw_version = \"$$dockerfile_version\""; \
		fi; \
		exit 1; \
	fi

.PHONY: test
test: version-check ## Comprehensive test suite: chrome, playwright, openclaw, node, python
ifeq ($(IN_CONTAINER),1)
	@echo "Already in container, running tests directly..."
	@echo "=== Testing Chrome ==="
	google-chrome-stable --version
	@echo ""
	@echo "=== Testing Playwright ==="
	python -c "import playwright; print(\"✅ Playwright import successful\")"
	@echo ""
	@echo "=== Testing Node.js ==="
	node --version
	npm --version
	@echo ""
	@echo "=== Testing Python ==="
	python --version
	uv --version
	@echo ""
	@echo "=== Testing OpenClaw CLI ==="
	openclaw --version
	openclaw --help | head -n 5
	openclaw --this-will-fail-intentionally
	@echo ""
	@echo "=== Running npm test suite ==="
	npm test
	@echo ""
	@echo "✨ All tests passed!"
else
	@echo "Running tests via docker..."
	@echo "=== Testing Chrome ==="
	docker run --rm --platform=$(PLATFORM) \
		-v "$(CURDIR)":"$(CONTAINERDIR)" \
		-w "$(CONTAINERDIR)" \
		$(IMAGE) google-chrome-stable --version
	@echo ""
	@echo "=== Testing Playwright ==="
	docker run --rm --platform=$(PLATFORM) \
		-v "$(CURDIR)":"$(CONTAINERDIR)" \
		-w "$(CONTAINERDIR)" \
		$(IMAGE) python -c "import playwright; print(\"✅ Playwright import successful\")"
	@echo ""
	@echo "=== Testing Node.js ==="
	docker run --rm --platform=$(PLATFORM) \
		-v "$(CURDIR)":"$(CONTAINERDIR)" \
		-w "$(CONTAINERDIR)" \
		$(IMAGE) sh -c "node --version && npm --version"
	@echo ""
	@echo "=== Testing Python ==="
	docker run --rm --platform=$(PLATFORM) \
		-v "$(CURDIR)":"$(CONTAINERDIR)" \
		-w "$(CONTAINERDIR)" \
		$(IMAGE) sh -c "python --version && uv --version"
	@echo ""
	@echo "=== Testing OpenClaw CLI ==="
	docker run --rm --platform=$(PLATFORM) \
		-v "$(CURDIR)":"$(CONTAINERDIR)" \
		-w "$(CONTAINERDIR)" \
		$(IMAGE) sh -c "openclaw --version && openclaw --help | head -n 5"
	@echo ""
	@echo "=== Running npm test suite ==="
	docker run --rm --platform=$(PLATFORM) \
		-v "$(CURDIR)":"$(CONTAINERDIR)" \
		-w "$(CONTAINERDIR)" \
		$(IMAGE) npm test
	@echo ""
	@echo "✨ All tests passed!"
endif

.PHONY: test-openclaw
test-openclaw: ## Test OpenClaw-specific functionality
ifeq ($(IN_CONTAINER),1)
	@echo "Testing OpenClaw functionality..."
	@echo "=== OpenClaw CLI Version ==="
	openclaw --version
	@echo ""
	@echo "=== OpenClaw Help ==="
	openclaw --help
	@echo ""
	@echo "=== OpenClaw Commands ==="
	openclaw --help | grep -A 20 "Commands:" || echo "✅ OpenClaw CLI available"
else
	@echo "Testing OpenClaw functionality via docker..."
	@echo "=== OpenClaw CLI Version ==="
	docker run --rm --platform=$(PLATFORM) \
		-v "$(CURDIR)":"$(CONTAINERDIR)" \
		-w "$(CONTAINERDIR)" \
		$(IMAGE) openclaw --version
	@echo ""
	@echo "=== OpenClaw Help ==="
	docker run --rm --platform=$(PLATFORM) \
		-v "$(CURDIR)":"$(CONTAINERDIR)" \
		-w "$(CONTAINERDIR)" \
		$(IMAGE) openclaw --help
	@echo ""
	@echo "=== OpenClaw Commands ==="
	docker run --rm --platform=$(PLATFORM) \
		-v "$(CURDIR)":"$(CONTAINERDIR)" \
		-w "$(CONTAINERDIR)" \
		$(IMAGE) sh -c "openclaw --help | grep -A 20 'Commands:' || echo '✅ OpenClaw CLI available'"
endif

.PHONY: test-quick
test-quick: ## Quick smoke test (no version-check)
ifeq ($(IN_CONTAINER),1)
	@echo "Quick smoke test..."
	google-chrome-stable --version
	python -c "import playwright; print(\"playwright-ok\")"
	openclaw --version
	npm test
else
	@echo "Quick smoke test via docker..."
	docker run --rm --platform=$(PLATFORM) \
		-v "$(CURDIR)":"$(CONTAINERDIR)" \
		-w "$(CONTAINERDIR)" \
		$(IMAGE) sh -c "google-chrome-stable --version && python -c 'import playwright; print(\"playwright-ok\")' && openclaw --version && npm test"
endif

update:
	claude update
