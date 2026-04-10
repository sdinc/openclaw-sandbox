IMAGE ?= openclaw-sandbox:dev
#IMAGE ?= node:24

PLATFORM ?= linux/amd64
CURDIR ?= `pwd`
CMD ?= zsh
MOUNT_SSH ?= 1
MOUNT_ZSHRC ?= 1
REQUIRE_TTY ?= 1
.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*## "}; /^[a-zA-Z0-9_-]+:.*## / {printf "%-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: build
build: ## Build the dev image
	docker build --platform=$(PLATFORM) -t $(IMAGE) .

.PHONY: run
run: ## Run zsh in the container (mounts repo + ~/.ssh + ~/.zshrc)
	@has_tty=0; [ -t 0 ] && [ -t 1 ] && has_tty=1 || true; \
	if [ "$$has_tty" -ne 1 ] && [ "$(REQUIRE_TTY)" = "1" ] && [ "$(CMD)" = "zsh" ]; then \
		echo "run requires a TTY for an interactive shell."; \
		echo "Tip: run from a terminal, or pass REQUIRE_TTY=0, or set CMD=\"zsh -lc '...'.\""; \
		exit 2; \
	fi; \
	it_flags="$$( [ "$$has_tty" -eq 1 ] && printf '%s' '-it' || printf '%s' '-i' )"; \
	ssh_mount="$$( [ "$(MOUNT_SSH)" = "1" ] && printf '%s' '-v $(HOME)/.ssh:/root/.ssh' || true )"; \
	zshrc_mount="$$( [ "$(MOUNT_ZSHRC)" = "1" ] && printf '%s' '-v $(HOME)/.zshrc:/root/.zshrc' || true )"; \
	docker run --rm $$it_flags --platform=$(PLATFORM) \
		-v "$(CURDIR)":/workspace \
		-w /workspace \
		$$ssh_mount \
		$$zshrc_mount \
		$(IMAGE) $(CMD)

.PHONY: run-shell-clean
run-shell-clean: ## Run zsh without mounting ~/.zshrc
	$(MAKE) run MOUNT_ZSHRC=0

.PHONY: test
test: ## Smoke test: chrome, playwright, openclaw (amd64)
	docker run --rm --platform=$(PLATFORM) $(IMAGE) google-chrome --version
	docker run --rm --platform=$(PLATFORM) $(IMAGE) python -c "import playwright; print(\"playwright-ok\")"
	docker run --rm --platform=$(PLATFORM) $(IMAGE) openclaw --version

