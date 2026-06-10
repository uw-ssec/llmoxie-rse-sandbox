#!/usr/bin/env bash
# shellcheck disable=SC2218
# SC2218 ("function only defined later") is a false positive here: shellcheck
# 0.11.0 misflags calls inside main() when the script also uses command
# substitution and `(...) || fn` chains, even though main runs after all
# definitions. Verified by minimal repro; the call at the bottom of this file
# executes last.
set -euo pipefail

# Builds the declarative walkthrough extension into a .vsix (a zip with a
# manifest) using only the Python stdlib, then installs it with
# `code --install-extension` — the same mechanism install-vsix.sh uses for the
# provider extension. Runs at postAttach because that's when `code` exists.
#
# NON-FATAL: the sandbox works without the walkthrough (README + decks), so
# every failure logs and exits 0.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
EXT_SRC="${SCRIPT_DIR}/sandbox-walkthrough"
EXTENSION_ID="uw-ssec.llmoxie-sandbox-walkthrough"

GREEN="\033[0;32m"
RED="\033[0;31m"
BOLD="\033[1m"
RESET="\033[0m"

say() {
  printf "%b\n==> [walkthrough] %s%b\n" "${BOLD}${GREEN}" "$1" "${RESET}"
}

log() {
  printf "      [walkthrough] %s\n" "$*"
}

warn() {
  printf "%b      [walkthrough] WARNING: %s%b\n" "${RED}" "$*" "${RESET}" >&2
}

bail() {
  warn "$*"
  warn "skipping walkthrough install — the README and docs/slides decks cover setup manually."
  exit 0
}

find_python() {
  if command -v python3 >/dev/null 2>&1; then
    command -v python3
    return 0
  fi
  if [ -x "${REPO_ROOT}/.pixi/envs/default/bin/python" ]; then
    printf '%s' "${REPO_ROOT}/.pixi/envs/default/bin/python"
    return 0
  fi
  return 1
}

find_code() {
  # The /usr/local/bin/code shim is unreliable in non-interactive postAttach
  # shells ("code or code-insiders is not installed"), so resolve the VS Code
  # Server remote-cli directly — same approach as install-vsix.sh. Fall back
  # to whatever `code` is on PATH (e.g. the desktop CLI on a local machine).
  local candidate
  for candidate in \
    "${HOME}"/.vscode-server/bin/*/bin/remote-cli/code \
    "${HOME}"/.vscode-server-insiders/bin/*/bin/remote-cli/code \
    "${HOME}"/.vscode-remote/bin/*/bin/remote-cli/code \
    /vscode/vscode-server/bin/*/bin/remote-cli/code \
    /vscode/vscode-server/bin/linux-*/*/bin/remote-cli/code; do
    if [ -x "${candidate}" ]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done
  if command -v code >/dev/null 2>&1; then
    command -v code
    return 0
  fi
  return 1
}

main() {
  say "Installing the Get Started walkthrough extension"

  CODE_BIN="$(find_code)" || bail "no usable 'code' CLI found (searched VS Code Server remote-cli roots and PATH)"
  log "using VS Code CLI: ${CODE_BIN}"
  PY="$(find_python)" || bail "no python3 available to build the .vsix"

  # Version-aware idempotency: re-install when the in-repo extension is newer
  # than what this Codespace already has.
  EXT_VERSION="$(sed -n 's/.*"version": "\([^"]*\)".*/\1/p' "${EXT_SRC}/package.json" | head -1)"
  if "${CODE_BIN}" --list-extensions --show-versions 2>/dev/null | grep -qix "${EXTENSION_ID}@${EXT_VERSION}"; then
    log "already installed: ${EXTENSION_ID}@${EXT_VERSION}"
    exit 0
  fi

  log "copying setup screenshots into extension media"
  cp "${REPO_ROOT}/docs/assets/"*.png "${EXT_SRC}/media/" || bail "screenshot copy failed"

  STAGE="$(mktemp -d)"
  trap 'rm -rf "${STAGE}"' EXIT

  log "staging .vsix layout"
  mkdir -p "${STAGE}/extension"
  cp "${EXT_SRC}/extension.vsixmanifest" "${STAGE}/extension.vsixmanifest"
  cp "${EXT_SRC}/[Content_Types].xml" "${STAGE}/[Content_Types].xml"
  cp "${EXT_SRC}/package.json" "${EXT_SRC}/extension.js" "${EXT_SRC}/README.md" "${STAGE}/extension/"
  mkdir -p "${STAGE}/extension/media"
  cp "${EXT_SRC}/media/"*.md "${EXT_SRC}/media/"*.png "${STAGE}/extension/media/"

  VSIX_PATH="${STAGE}/llmoxie-sandbox-walkthrough.vsix"
  log "building ${VSIX_PATH##*/} with python zipfile"
  (
    cd "${STAGE}"
    "${PY}" - "${VSIX_PATH}" <<'PYEOF'
import os
import sys
import zipfile

out = sys.argv[1]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zf:
    for root, _dirs, files in os.walk("."):
        for name in files:
            path = os.path.join(root, name)
            arcname = os.path.relpath(path, ".")
            if os.path.abspath(path) == os.path.abspath(out):
                continue
            zf.write(path, arcname)
PYEOF
  ) || bail ".vsix build failed"

  log "installing via 'code --install-extension'"
  "${CODE_BIN}" --install-extension "${VSIX_PATH}" || bail "code --install-extension failed"

  if "${CODE_BIN}" --list-extensions 2>/dev/null | grep -qix "${EXTENSION_ID}"; then
    log "installed and registered: ${EXTENSION_ID}"
  else
    warn "installed but not yet listed — it should appear after the window reloads."
  fi

  say "walkthrough ready — it opens on the next window load (or Help > Welcome > LLMoxie RSE Sandbox)"
}

main
