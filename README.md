The container that is built from the below is available for download from https://hub.docker.com/r/spudnicdocker/openclaw-sandbox

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
* claude cli claude
* cursor cli cursor-agent
* antigravity cli agy
* ollama
* other development deps

# Copy Paste quick install

```bash 
# antigravity
RUN curl -fsSL https://antigravity.google/cli/install.sh | bash

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

# Configuration

The workspace includes a [`settings.json`](./settings.json) template which configures telemetry settings, trusted workspaces, and pre-approved command execution permissions for the Google Antigravity CLI (`agy`).

For `agy` to recognize and use these settings, copy or link this file to the required configuration path:
```bash
mkdir -p ~/.gemini/antigravity-cli
cp settings.json ~/.gemini/antigravity-cli/settings.json
```

# Usage

Most parts are driven by the `Makefile`. To get a shell in the sandboxed container with all tools installed and the workspace volume-mounted:
```bash
make build
make run
```
To run a clean shell (no saved container state/history):
```bash
make run-shell-clean
```

## Running from Docker Hub (Image Only)

If you don't want to clone the repository or build the image locally, you can pull and run the pre-built image directly from Docker Hub:

```bash
docker pull spudnicdocker/openclaw-sandbox:latest
```

### Run Command

Since the container requires access to your workspace and configurations to work seamlessly, the run command mounts your current directory, SSH keys, shell settings, and GitHub configurations:

```bash
docker run --rm -it --platform=linux/amd64 \
  -v "$(pwd)":"/opt/workspace" \
  -w "/opt/workspace" \
  -v "$HOME/.ssh":"/root/.ssh" \
  -v "$HOME/.zshrc":"/root/.zshrc" \
  -v "$HOME/.config/gh":"/root/.config/gh" \
  -v "$HOME/.gitconfig":"/root/.gitconfig" \
  spudnicdocker/openclaw-sandbox:latest zsh
```

### Recommended Shell Aliases

Because the command has many parameters, we highly recommend setting up an alias in your shell configuration (e.g., `~/.bashrc`, `~/.zshrc`, or `~/.config/fish/config.fish`):

#### For Bash/Zsh:
Add this to your `~/.bashrc` or `~/.zshrc`:
```bash
alias openclaw-sandbox='docker run --rm -it --platform=linux/amd64 -v "$(pwd)":"/opt/workspace" -w "/opt/workspace" -v "$HOME/.ssh":"/root/.ssh" -v "$HOME/.zshrc":"/root/.zshrc" -v "$HOME/.config/gh":"/root/.config/gh" -v "$HOME/.gitconfig":"/root/.gitconfig" spudnicdocker/openclaw-sandbox:latest zsh'
```

#### For Fish:
Add this to your `~/.config/fish/config.fish`:
```fish
alias openclaw-sandbox="docker run --rm -it --platform=linux/amd64 -v (pwd):/opt/workspace -w /opt/workspace -v \$HOME/.ssh:/root/.ssh -v \$HOME/.zshrc:/root/.zshrc -v \$HOME/.config/gh:/root/.config/gh -v \$HOME/.gitconfig:/root/.gitconfig spudnicdocker/openclaw-sandbox:latest zsh"
```

Once configured, simply run this command in any workspace directory to spin up your sandboxed OpenClaw environment:
```bash
openclaw-sandbox
```

For advanced developer and agent workflows, including cached Docker builds and automatic version bumping, please refer to [`AGENTS.md`](./AGENTS.md).

# Testing

You can run the test suite locally with:
```bash
make test
```
Refer to [`AGENTS.md`](./AGENTS.md) for faster testing and Docker cache details.

## GCP Setup

If you need the Google Cloud SDK:
```bash
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-darwin-arm.tar.gz
tar -xf google-cloud-cli-darwin-arm.tar.gz
./google-cloud-sdk/install.sh
```

## Notes

- The Docker image is built and run as **amd64** (`linux/amd64`) for consistency across platforms (including Apple Silicon).
- Playwright is installed, but Playwright’s bundled browsers are skipped; Chrome Stable is used from the system.

# License

Refer to [`LICENSE.md`](./LICENSE.md).

# Contributing

Refer to [`CONTRIBUTING.md`](./CONTRIBUTING.md).