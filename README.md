This repo is setup to run open-claw in a sandboxed container. 

# Requirements
* docker
* make

# What is installs
* containerized amd64 development environment
* python 
* open claw cli
* claude cli
* other development dependancies

# Copy Paste quick install

```bash 
# note once you run this and setup your account you only have 
curl https://cursor.com/install -fsS | bash
# requires paid subscription for api key 
curl -fsSL https://claude.ai/install.sh | bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

# Build plan (WIP)

- **Base image**: `node:24`
- **Python**: Install **Python 3.12** via `uv` inside the image
- **Shell**: `zsh` in-container (used by `make run`)
- **Browser**: Google **Chrome Stable** (amd64)
- **Web automation**: Python **Playwright** (configured to use system Chrome)
- **OpenClaw**: `openclaw` CLI installed via npm
- **Goal**: A minimal dev container that has Node 24 + Python 3.12 available (`python3.12` / `python3`)

# Usage

```bash
make build
make run
make run-shell-clean
```

## GCP
```bash
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-darwin-arm.tar.gz
tar -xf google-cloud-cli-darwin-arm.tar.gz
./google-cloud-sdk/install.sh
```

## local llm 
```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama launch claude #choose a local model instead of a cloud based one
```

## Notes

- The image is built and run as **amd64** (`linux/amd64`) for consistency (including on Apple Silicon).
- Playwright is installed, but Playwright’s bundled browsers are skipped; use **Chrome Stable** via channel selection.