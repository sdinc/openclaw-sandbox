This repo is setup to run open-claw in a sandboxed container. 

# Overview

# Installation
* docker
* make
* ollama( use local models to avoid token cost)
* claude( does not have a full free with default like cursor so had to go with local model)
* gh github cli ( mainly writting nice PR descriptions and other github actions manipulation)
* pmat [repo](https://github.com/paiml/paiml-mcp-agent-toolkit) ```cargo install pmat```

# What this installs
* containerized amd64 development environment
* python 
* open claw cli
* claude cli
* cursor cli
* ollama
* other development deps

# Copy Paste quick install

```bash 
# note once you run this and setup your account you only have 
curl https://cursor.com/install -fsS | bash
# requires paid subscription for api key 
curl -fsSL https://claude.ai/install.sh | bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
## local llm 
curl -fsSL https://ollama.com/install.sh | sh
ollama launch claude #choose a local model instead of a cloud based one
```

# Build plan (WIP)

- **Base image**: `node:24`
- **Python**: Install **Python 3.12** via `uv` inside the image
- **Shell**: `zsh` in-container (used by `make run`)
- **Browser**: Google **Chrome Stable** (amd64)
- **Web automation**: Python **Playwright** (configured to use system Chrome)
- **OpenClaw**: `openclaw` CLI installed via npm
- **Goal**: A minimal dev container that has Node 24 + Python 3.12 available (`python3.12` / `python3`)

## Chrome & Playwright Configuration

Chrome Stable is installed from Google's official repository and Playwright is configured to use it:
- `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1` - Skip downloading Playwright's bundled browsers
- `PLAYWRIGHT_BROWSERS_PATH=0` - Use system browsers only
- `PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/google-chrome-stable` - Point to system Chrome

This ensures consistent browser behavior and reduces image size by avoiding duplicate browser installations.

# Usage

```bash
make build
make run
make run-shell-clean
```

# Testing
make test

## GCP
```bash
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-darwin-arm.tar.gz
tar -xf google-cloud-cli-darwin-arm.tar.gz
./google-cloud-sdk/install.sh
```

## Notes

- The image is built and run as **amd64** (`linux/amd64`) for consistency (including on Apple Silicon).
- Playwright is installed, but Playwright’s bundled browsers are skipped; use **Chrome Stable** via channel selection.

# Usage

Most parts are driven by makefile.  ```make run``` gives you a shell in the container with all the tools installed and the local directory . volume mounted across

# License

refer to LICENSE.md

# Contributing

refer to CONTRIBUTING.md