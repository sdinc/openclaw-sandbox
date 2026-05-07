IMAGE ?= openclaw-sandbox:dev

# OpenClaw version - single source of truth
OPENCLAW_VERSION ?= 2026.5.6

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

.PHONY: test
test: ## Smoke test: chrome, playwright, openclaw (amd64)
ifeq ($(IN_CONTAINER),1)
	@echo "Already in container, running tests directly..."
	google-chrome-stable --version
	python -c "import playwright; print(\"playwright-ok\")"
	npm test
else
	@echo "Running tests via docker..."
	docker run --rm --platform=$(PLATFORM) \
		-v "$(CURDIR)":"$(CONTAINERDIR)" \
		-w "$(CONTAINERDIR)" \
		$(IMAGE) google-chrome-stable --version
	docker run --rm --platform=$(PLATFORM) \
		-v "$(CURDIR)":"$(CONTAINERDIR)" \
		-w "$(CONTAINERDIR)" \
		$(IMAGE) python -c "import playwright; print(\"playwright-ok\")"
	docker run --rm --platform=$(PLATFORM) \
		-v "$(CURDIR)":"$(CONTAINERDIR)" \
		-w "$(CONTAINERDIR)" \
		$(IMAGE) npm test
endif
update:
	claude update