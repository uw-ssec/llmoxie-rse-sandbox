# Base image intentionally uses "base" (not python) because
# environment + dependencies are managed via pixi, not system Python.
FROM mcr.microsoft.com/devcontainers/base:jammy

# Use bash for RUN so pipefail is supported.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG PIXI_VERSION=v0.63.2
ARG PIXI_SHA256_X86_64=b2a9e26bb6c80fe00618a02e7198dec222e1fbcec61e04c11b6e6538089ab100
ARG PIXI_SHA256_AARCH64=dbde6dbc2806602171e17305ce005e1aed519f2f2461a7cafd0093e92b7e7681

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    git \
    jq \
    tar \
    && rm -rf /var/lib/apt/lists/*

# Install pixi by verifying against reviewed, pinned SHA256 values in this Dockerfile.
RUN set -eu \
    && ARCH="$(uname -m)" \
    && case "${ARCH}" in \
        x86_64) PIXI_ARCH="x86_64"; PIXI_SHA256="${PIXI_SHA256_X86_64}" ;; \
        aarch64|arm64) PIXI_ARCH="aarch64"; PIXI_SHA256="${PIXI_SHA256_AARCH64}" ;; \
        *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;; \
       esac \
    && PIXI_ASSET="pixi-${PIXI_ARCH}-unknown-linux-musl.tar.gz" \
    && PIXI_BASE_URL="https://github.com/prefix-dev/pixi/releases/download/${PIXI_VERSION}" \
    && curl -fsSL --compressed -o /tmp/pixi.tar.gz "${PIXI_BASE_URL}/${PIXI_ASSET}" \
    && echo "${PIXI_SHA256}  /tmp/pixi.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/pixi.tar.gz -C /tmp pixi \
    && install -m 0755 /tmp/pixi /usr/local/bin/pixi \
    && rm -f /tmp/pixi /tmp/pixi.tar.gz

ENV VSCODE_HOME=/home/vscode \
    VSCODE_USER=vscode \
    SHELL=/bin/bash

USER ${VSCODE_USER}
WORKDIR /workspaces/llmaven-rse-sandbox

RUN echo 'eval "$(pixi completion -s bash)"' >> ${VSCODE_HOME}/.bashrc

# Pre-install GitHub Copilot CLI and the rse-plugins marketplace plugins
# during the image build so the devcontainer is ready on attach.
COPY --chown=${VSCODE_USER}:${VSCODE_USER} .devcontainer/install-plugins.sh /tmp/install-plugins.sh
RUN bash /tmp/install-plugins.sh && rm -f /tmp/install-plugins.sh
