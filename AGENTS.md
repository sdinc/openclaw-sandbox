### Purpose
This repo provides a simple Docker-based dev shell (Node 24 + Python 3.12) for working on OpenClaw tooling in a container.

### Common commands
- `make`: show available targets
- `make build`: build the image (`openclaw-sandbox:dev` by default)
- `make run-shell`: start an interactive `zsh` with mounts:
  - repo -> `/workspace`
  - `~/.ssh` -> `/root/.ssh`
  - `~/.zshrc` -> `/root/.zshrc`

### Notes
- The container runs as `root` by default, so home is `/root`.
- The container is built/run as `linux/amd64` by default (see `PLATFORM` in `Makefile`).
- Chrome is installed as `google-chrome-stable`. Playwright is installed with `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1`.
- If you need additional tools later, prefer adding them to `Dockerfile` and documenting them in `README.md`.

