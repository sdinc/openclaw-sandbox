IMAGE ?= openclaw-sandbox:dev
#IMAGE ?= node:24

# Node version - single source of truth
NODE_VERSION ?= 22.15.0

PLATFORM ?= linux/amd64
CURDIR ?= `pwd`
CMD ?= zsh
cmd ?=
MOUNT_SSH ?= 1
MOUNT_ZSHRC ?= 1
MOUNT_GH ?= 1
MOUNT_GITCONFIG ?= 1
REQUIRE_TTY ?= 1
.DEFAULT_GOAL := help

CONTAINERDIR ?= /container-dir

.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*## "}; /^[a-zA-Z0-9_-]+:.*## / {printf "%-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: check-node-version
check-node-version: ## Validate Node version matches between Makefile and package.json
	@PACKAGE_NODE_VERSION=$$(grep -o '"node": "[^"]*"' package.json | cut -d'"' -f4); \
	if [ "$$PACKAGE_NODE_VERSION" != "$(NODE_VERSION)" ]; then \
		echo "ERROR: Node version mismatch!"; \
		echo "  Makefile NODE_VERSION: $(NODE_VERSION)"; \
		echo "  package.json engines.node: $$PACKAGE_NODE_VERSION"; \
		echo "Please update package.json engines.node to match Makefile NODE_VERSION"; \
		exit 1; \
	else \
		echo "✓ Node version $(NODE_VERSION) matches in Makefile and package.json"; \
	fi

.PHONY: build
build: check-node-version ## Build the dev image
	docker build --platform=$(PLATFORM) --build-arg NODE_VERSION=$(NODE_VERSION) -t $(IMAGE) .

.PHONY: run
run: ## Run zsh in the container (mounts repo + ~/.ssh + ~/.zshrc)
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

.PHONY: run-shell-clean
run-shell-clean: ## Run zsh without mounting ~/.zshrc
	$(MAKE) run MOUNT_ZSHRC=0 cmd="$(cmd)" CMD="$(CMD)"

.PHONY: test
test: ## Smoke test: chrome, playwright, openclaw (amd64)
	docker run --rm --platform=$(PLATFORM) $(IMAGE) google-chrome --version
	docker run --rm --platform=$(PLATFORM) $(IMAGE) python -c "import playwright; print(\"playwright-ok\")"
	docker run --rm --platform=$(PLATFORM) $(IMAGE) pnpm test

update:
	claude update