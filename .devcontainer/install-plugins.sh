#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[install-plugins] $*"
}

error() {
  echo "[install-plugins] ERROR: $*" >&2
}

if ! command -v copilot >/dev/null 2>&1; then
  log "Installing GitHub Copilot CLI..."
  curl -fsSL https://gh.io/copilot-install | bash
fi

if ! command -v copilot >/dev/null 2>&1; then
  error "copilot CLI not found after install attempt"
  exit 1
fi

log "Adding copilot CLI plugin marketplace: uw-ssec/rse-plugins"
copilot plugin marketplace add uw-ssec/rse-plugins

log "Installing copilot CLI plugin: ai-research-workflows@rse-plugins"
copilot plugin install ai-research-workflows@rse-plugins

log "Copilot CLI plugins installed."
