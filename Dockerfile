
# Use official OpenClaw base image which already has openclaw, node, pnpm, etc.
# OpenClaw version can be overridden via --build-arg OPENCLAW_VERSION=x.y.z
ARG OPENCLAW_VERSION="2026.5.6"
ARG PLATFORM_ARCH="amd64"

FROM ghcr.io/openclaw/openclaw:${OPENCLAW_VERSION}-${PLATFORM_ARCH}

LABEL org.opencontainers.image.description DESCRIPTION="Brody's OpenClaw sandbox with zsh, gh, uv, and Python deps"

# Switch to root for system package installation
USER root

ENV DEBIAN_FRONTEND=noninteractive

# Install additional tools: gh (GitHub CLI) and zsh
RUN apt-get update \
  && apt-get install -y --no-install-recommends gh zsh \
  && rm -rf /var/lib/apt/lists/*

# Install uv for Python package management (as root)
ENV UV_INSTALL_DIR=/usr/local/bin
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Python 3.12 and expose it on PATH (as root)
RUN uv python install 3.12 \
  && ln -sf "$(uv python find 3.12)" /usr/local/bin/python3.12 \
  && ln -sf /usr/local/bin/python3.12 /usr/local/bin/python3 \
  && python3.12 --version

# Switch back to node user (default non-root user from base image)
USER node

# Install Python deps in home directory so they persist
ENV VIRTUAL_ENV="/home/node/.venv"
ENV PATH="/home/node/.venv/bin:${PATH}"
ENV UV_PROJECT_ENVIRONMENT="/home/node/.venv"
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

# Build Python venv in home directory
WORKDIR /home/node
COPY --chown=node:node pyproject.toml pyproject.toml

RUN uv venv "${VIRTUAL_ENV}" --python 3.12
RUN uv sync --active

# Set working directory to /opt/workspace for mounted volumes
WORKDIR /opt/workspace

# Verify openclaw is available (comes from base image)
RUN openclaw --version

# Ensure `docker run <image> <cmd>` runs the command directly
ENTRYPOINT []
CMD ["zsh"]

