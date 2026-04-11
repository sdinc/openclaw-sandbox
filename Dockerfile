ARG NODE_VERSION=22.14.0

FROM node:${NODE_VERSION}

ARG WORKINGDEV=/workspace
ARG HOME=${WORKINGDEV}
ENV DEBIAN_FRONTEND=noninteractive

# Install base OS deps, zsh, and packages needed to add Chrome repo.
RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl gh git gnupg zsh \
  && rm -rf /var/lib/apt/lists/*

# run make sure the latest npm
RUN npm install -g npm@11.12.1

# Install Google Chrome Stable (official repo + keyring).
RUN install -m 0755 -d /etc/apt/keyrings \
  && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg \
  && chmod a+r /etc/apt/keyrings/google-chrome.gpg \
  && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends google-chrome-stable \
  && rm -rf /var/lib/apt/lists/*

# Install uv to a global location.
ENV UV_INSTALL_DIR=/usr/local/bin
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Python 3.12 and expose it on PATH as python3.12 and python3.
RUN uv python install 3.12 --cache-dir ${WORKINGDEV}.venv \
  && ln -sf "$(uv python find 3.12)" /usr/local/bin/python3.12 \
  && ln -sf /usr/local/bin/python3.12 /usr/local/bin/python3 \
  && python3.12 --version

# Install Python deps (Playwright) into a venv and install OS deps.
ENV VIRTUAL_ENV=${WORKINGDEV}/.venv
ENV PATH="${WORKINGDEV}/.venv/bin:${PATH}"
ENV UV_PROJECT_ENVIRONMENT=${WORKINGDEV}/.venv
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

WORKDIR /opt/openclaw-sandbox
COPY pyproject.toml /opt/openclaw-sandbox/pyproject.toml

RUN uv venv "${VIRTUAL_ENV}" --python 3.12
RUN uv sync --active

COPY .npmrc ${WORKINGDEV}/

# Install OpenClaw CLI (Node-based).
RUN npm install
RUN openclaw --version

# Ensure `docker run <image> <cmd>` runs the command directly (not via Node entrypoint defaults).
ENTRYPOINT []
CMD ["zsh"]

