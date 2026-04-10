IMAGE ?= openclaw-sandbox:dev
#IMAGE ?= node:24

PLATFORM ?= linux/amd64
CURDIR ?= `pwd`
CMD ?= zsh
.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*## "}; /^[a-zA-Z0-9_-]+:.*## / {printf "%-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: build
build: ## Build the dev image
	docker build --platform=$(PLATFORM) -t $(IMAGE) .

.PHONY: run-shell
run-shell: ## Run zsh in the container (mounts repo + ~/.ssh + ~/.zshrc)
	@it_flags="$$( [ -t 0 ] && [ -t 1 ] && printf '%s' '-it' || printf '%s' '-i' )"; \
	docker run --rm $$it_flags --platform=$(PLATFORM) \
		-v "$(CURDIR)":/workspace \
		-w /workspace \
		-v "$(HOME)/.ssh":/root/.ssh \
		-v "$(HOME)/.zshrc":/root/.zshrc \
		$(IMAGE) $(CMD)

.PHONY: run
run: ## Alias for run-shell
	$(MAKE) run-shell

.PHONY: test
test: ## Smoke test: chrome, playwright, openclaw (amd64)
	docker run --rm --platform=$(PLATFORM) $(IMAGE) google-chrome --version
	docker run --rm --platform=$(PLATFORM) $(IMAGE) python -c "import playwright; print(\"playwright-ok\")"
	docker run --rm --platform=$(PLATFORM) $(IMAGE) openclaw --version

