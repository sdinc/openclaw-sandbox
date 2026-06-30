
# Use official OpenClaw base image which already has openclaw, node, pnpm, etc.
# Testing Docker cache performance - full rebuild test
# OpenClaw version can be overridden via --build-arg OPENCLAW_VERSION=x.y.z
# this breaks dependabot updates so hard coding
#ARG OPENCLAW_VERSION="2026.5.6"
#ARG PLATFORM_ARCH="amd64"
#FROM ghcr.io/openclaw/openclaw:${OPENCLAW_VERSION}-${PLATFORM_ARCH}

FROM ghcr.io/openclaw/openclaw:2026.6.10-amd64

LABEL org.opencontainers.image.description="Brody's OpenClaw sandbox with zsh, uv, and Python deps"

# This allows dependabot to make pr's when a new version is available. 
LABEL org.opencontainers.image.source="https://github.com/openclaw/openclaw/pkgs/container/openclaw"

# Switch to root for system package installation
USER root

ENV DEBIAN_FRONTEND=noninteractive

# Install additional tools: gh (GitHub CLI), zsh, and Chrome dependencies
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    gh \
    zsh \
    build-essential \
    wget \
    gnupg \
    ca-certificates \
    fonts-liberation \
    libnss3 \
    libxss1 \
    libappindicator3-1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    xdg-utils \
    plocate \
    pkg-config  \
    libssl-dev \
  && rm -rf /var/lib/apt/lists/*

# Install Google Chrome Stable (testing cache with mid-file change)
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg \
  && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends google-chrome-stable \
  && rm -rf /var/lib/apt/lists/*

# Install uv for Python package management (as root)
ENV UV_INSTALL_DIR=/usr/local/bin
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Python 3.12 and expose it on PATH (as root)
RUN uv python install 3.12 \
  && ln -sf "$(uv python find 3.12)" /usr/local/bin/python3.12 \
  && ln -sf /usr/local/bin/python3.12 /usr/local/bin/python3 \
  && python3.12 --version

# Bump the version or node installed for use with other tools
RUN npm install -g npm@11.16.0



# Switch back to node user (default non-root user from base image)
USER node

# rust install
RUN curl -LsSf https://sh.rustup.rs | sh -s -- -y
# need to get cargo and rustc on the path
# . "$HOME/.cargo/env"
# RUN echo ". $HOME/.cargo/env" >> ${HOME}/.zshrc
# RUN which cargo
# RUN cargo install pmat


# Install Python deps in home directory so they persist
ENV VIRTUAL_ENV="/home/node/.venv"
ENV PATH="/home/node/.venv/bin:/home/node/.cargo/bin:${PATH}"
ENV UV_PROJECT_ENVIRONMENT="/home/node/.venv"
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
ENV PLAYWRIGHT_BROWSERS_PATH=0
ENV PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/google-chrome-stable

# pmat install
RUN /home/node/.cargo/bin/cargo install pmat

# Build Python venv in home directory
WORKDIR /home/node
COPY --chown=node:node pyproject.toml pyproject.toml

RUN uv venv "${VIRTUAL_ENV}" --python 3.12
RUN uv sync --active

# Set working directory to /opt/workspace for mounted volumes
WORKDIR /opt/workspace

# Verify openclaw is available (comes from base image)
RUN openclaw --version

# Verify pmat is installed
RUN /home/node/.cargo/bin/pmat --version

# Ensure `docker run <image> <cmd>` runs the command directly
ENTRYPOINT []
CMD ["zsh"]
# Testing cache layer performance - bottom-of-file change case (payload: coaching layer test)
