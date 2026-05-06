This repo is setup to run open-claw in a sandboxed container. 

# Requirements
* docker
* make
* ollama( use local models to avoid token cost)
* claude( does not have a full free with default like cursor so had to go with local model)
* gh github cli ( mainly writting nice PR descriptions and other github actions manipulation)


# What this installs
* containerized amd64 development environment
* python 
* open claw cli
* claude cli
* other development dependencies
* IBM bob


# Copy Paste quick install
* with out paid you have to run auto and even then if you turn off all models except for ( cursors own model ( composer 2 ) still I burned through free use in 1 hour and my account does not reset for another month. 
* the setup I ran was turn off all models except for composer 2, sonnet 4.6 in the cursor ui. Since I only use cursor-agent as I hate visual studio, my thinking was that cursor-agent in automode would switch between the two choosen models. Not sure that was the case. 
```bash 
# note once you run this and setup your account you only have 
curl https://cursor.com/install -fsS | bash
# requires paid subscription for api key 
curl -fsSL https://claude.ai/install.sh | bash
# OSX
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
# Linux
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```


# Build plan

- **Base image**: `node:24`
- **Python**: Install **Python 3.12** via `uv` inside the image
- **Shell**: `zsh` in-container (used by `make run`)
- **Browser**: Google **Chrome Stable** (amd64) - installed from official Google repository
- **Web automation**: Python **Playwright** (configured to use system Chrome via `PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH`)
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

## Notes

- The image is built and run as **amd64** (`linux/amd64`) for consistency (including on Apple Silicon).
- Playwright is installed, but Playwright’s bundled browsers are skipped; use **Chrome Stable** via channel selection.