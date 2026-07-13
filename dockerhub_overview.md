# Brody's OpenClaw Sandbox (`spudnicdocker/openclaw-sandbox`)

A fully optimized, containerized `amd64` development sandbox designed specifically for running **OpenClaw** in an isolated, sandboxed environment. Built on top of the official OpenClaw base image, it includes pre-installed Python, Node.js, Google Chrome, Playwright, shell custom configurations, and productivity CLIs.

---

## Key Features

* **OpenClaw CLI**: Fully installed and configured out-of-the-box.
* **Modern Runtimes**: Node.js v24+ and Python v3.12+ (managed efficiently via `uv`).
* **Web Automation Ready**: Includes system-wide **Google Chrome Stable** with **Playwright** pre-configured to use the system browser without duplicate downloads.
* **Developer Tooling**: Embedded CLIs including `gh` (GitHub CLI), `zsh`, `antigravity` (`agy`), and `cursor`.
* **Credential Integration**: Seamlessly maps your host configurations (SSH, Git, Zsh, GitHub CLI) for an identical dev experience.

---

## Direct Usage (Without Repo Cloning)

To spin up the sandboxed environment immediately from any directory on your system:

### 1. Pull the Image
```bash
docker pull spudnicdocker/openclaw-sandbox:latest
```

### 2. Run Command
Because the container is fully isolated, running it with full capabilities requires forwarding your current workspace directory, shell configurations, SSH keys, and GitHub API credentials:

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

---

## Recommended Shell Aliases

Since the full startup command contains many complex arguments and volume mounts, we highly recommend setting up an alias in your shell configuration profile for quick execution.

### For Bash & Zsh
Add the following line to your `~/.bashrc` or `~/.zshrc`:

```bash
alias openclaw-sandbox='docker run --rm -it --platform=linux/amd64 -v "$(pwd)":"/opt/workspace" -w "/opt/workspace" -v "$HOME/.ssh":"/root/.ssh" -v "$HOME/.zshrc":"/root/.zshrc" -v "$HOME/.config/gh":"/root/.config/gh" -v "$HOME/.gitconfig":"/root/.gitconfig" spudnicdocker/openclaw-sandbox:latest zsh'
```

### For Fish Shell
Add the following line to your `~/.config/fish/config.fish`:

```fish
alias openclaw-sandbox="docker run --rm -it --platform=linux/amd64 -v (pwd):/opt/workspace -w /opt/workspace -v \$HOME/.ssh:/root/.ssh -v \$HOME/.zshrc:/root/.zshrc -v \$HOME/.config/gh:/root/.config/gh -v \$HOME/.gitconfig:/root/.gitconfig spudnicdocker/openclaw-sandbox:latest zsh"
```

Once configured, simply enter your project directory and execute:
```bash
openclaw-sandbox
```

---

## Mounted Directories & Configurations
* `$(pwd)` $\rightarrow$ `/opt/workspace` (Main project repository)
* `~/.ssh` $\rightarrow$ `/root/.ssh` (SSH credentials for pushing/pulling to Git)
* `~/.config/gh` $\rightarrow$ `/root/.config/gh` (GitHub CLI authentication states)
* `~/.gitconfig` $\rightarrow$ `/root/.gitconfig` (Global git config signatures and settings)
* `~/.zshrc` $\rightarrow$ `/root/.zshrc` (Interactive shell aliases and presets)
