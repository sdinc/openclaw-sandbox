# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🚀 Architecture Overview
This repository utilizes a containerized development environment built on `node:24` and relies on Python 3.12, the `openclaw` CLI, and the `claude` CLI. The system architecture is heavily dependent on container orchestration, managing dependencies across Node.js, Python, and Chrome Stable via Playwright.

**Key Components & Technologies:**
*   **Containerization:** The entire development stack is intended to run inside a Docker container for consistency across environments.
*   **Frontend/Tooling:** Relies on `npm` packages and the `openclaw` CLI.
*   **Automation/Testing:** Heavily uses Python's `Playwright` library configured to target system Chrome Stable.
*   **Development Commands:** Core workflows are managed via `make`.

## ⚙️ Core Development Commands
The primary way to work in this codebase is by using the `make` utility defined in the `README.md`.

*   **Build Project:** `make build`
*   **Run/Test Cycle:** `make run`
*   **Clean/Test Shell:** `make run-shell-clean`

For single tests, specific commands may need to be derived from the test runner, but the general execution is managed by `make run`.

## 🧩 Developer Guidelines & Rules
*   **From Container:** When developing or running tasks, the environment is designed to be containerized. The primary working context must simulate execution within this container setup.
*   **CLI Usage:** The `openclaw` CLI and `claude` CLI are central tools. Interactions with these should be prioritized when debugging or adding features.
*   **System Dependencies:** Be mindful of the underlying system dependencies: Docker, Node 24, Python 3.12, and a functional Chrome Stable browser instance.

## 🛠️ Development Workflow Notes
The system assumes the user is following the `README.md` instructions for initial setup, which involves running:
`curl https://cursor.com/install -fsS | bash`
`curl -fsSL https://claude.ai/install.sh | bash`

**General Development Tasks:**
1.  Ensure the required `make` targets are available and executable.
2.  Test failures often stem from environment mismatch (e.g., running outside a container).
3.  When inspecting code, keep the container runtime environment and its explicit dependencies (Node, Python, Chrome) in mind.
