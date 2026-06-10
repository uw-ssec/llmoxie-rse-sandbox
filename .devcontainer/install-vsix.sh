#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PIN_FILE="${SCRIPT_DIR}/oai-compatible-copilot-vsix.env"

VSIX_FILENAME=""
EXPECTED_VSIX_SHA256=""

VSIX_DIR="${HOME}/.cache/oai-compatible-copilot"
EXTENSION_ID="uw-ssec.oai-compatible-copilot"

# --- Output styling -------------------------------------------------------
# Colors are emitted unconditionally (not gated on a tty) because the
# devcontainer / Codespaces "attaching container" log renders ANSI codes.
GREEN="\033[0;32m"
RED="\033[0;31m"
BOLD="\033[1m"
RESET="\033[0m"

say() {
  printf "%b\n==> [post-attach] %s%b\n" "${BOLD}${GREEN}" "$1" "${RESET}"
}

log() {
  printf "      [post-attach] %s\n" "$*"
}

error() {
  printf "%b      [post-attach] ERROR: %s%b\n" "${RED}" "$*" "${RESET}" >&2
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    error "required command not found: $1"
    return 1
  fi
}

load_pin_file() {
  local line
  local key
  local value

  if [ ! -f "${PIN_FILE}" ]; then
    error "VSIX pin file not found: ${PIN_FILE}"
    return 1
  fi

  while IFS= read -r line || [ -n "${line}" ]; do
    case "${line}" in
      ""|"#"*) continue ;;
    esac

    case "${line}" in
      *=*) ;;
      *)
        error "invalid line in VSIX pin file: ${line}"
        return 1
        ;;
    esac

    key="${line%%=*}"
    value="${line#*=}"

    case "${key}" in
      VSIX_RELEASE_TAG)
        # Not needed during install, but allowed because the same pin file
        # is shared with post-create.sh.
        ;;
      VSIX_FILENAME)
        VSIX_FILENAME="${value}"
        ;;
      VSIX_SOURCE_COMMIT)
        # Human-readable metadata only. Not needed during install.
        ;;
      EXPECTED_VSIX_SHA256)
        EXPECTED_VSIX_SHA256="${value}"
        ;;
      *)
        error "unexpected key in VSIX pin file: ${key}"
        return 1
        ;;
    esac
  done < "${PIN_FILE}"
}

verify_required_vars() {
  if [ -z "${VSIX_FILENAME:-}" ]; then
    error "VSIX_FILENAME is not set"
    return 1
  fi

  if [ -z "${EXPECTED_VSIX_SHA256:-}" ]; then
    error "EXPECTED_VSIX_SHA256 is not set"
    return 1
  fi

  if [ "${EXPECTED_VSIX_SHA256}" = "REPLACE_WITH_FULL_64_CHARACTER_SHA256" ]; then
    error "EXPECTED_VSIX_SHA256 still contains placeholder value"
    return 1
  fi

  if ! printf '%s' "${EXPECTED_VSIX_SHA256}" | grep -Eq '^[a-fA-F0-9]{64}$'; then
    error "EXPECTED_VSIX_SHA256 must be a raw 64-character hex SHA256"
    return 1
  fi

  if ! printf '%s' "${VSIX_FILENAME}" | grep -Eq '^[A-Za-z0-9._-]+\.vsix$'; then
    error "VSIX_FILENAME must be a safe .vsix basename"
    return 1
  fi

  case "${VSIX_FILENAME}" in
    *..*|*/*)
      error "VSIX_FILENAME must not contain path traversal or slashes"
      return 1
      ;;
  esac
}

verify_vsix_path() {
  local vsix_dir_real
  local vsix_path_real

  vsix_dir_real="$(realpath -m "${VSIX_DIR}")"
  vsix_path_real="$(realpath -m "${VSIX_PATH}")"

  case "${vsix_path_real}" in
    "${vsix_dir_real}"/*) ;;
    *)
      error "resolved VSIX path is outside VSIX cache directory"
      error "VSIX_DIR:  ${vsix_dir_real}"
      error "VSIX_PATH: ${vsix_path_real}"
      return 1
      ;;
  esac
}

verify_sha256() {
  local actual_sha256

  actual_sha256="$(sha256sum "${VSIX_PATH}" | awk '{print $1}')"

  if [ "${actual_sha256}" != "${EXPECTED_VSIX_SHA256}" ]; then
    error "VSIX SHA256 mismatch."
    error "Expected: ${EXPECTED_VSIX_SHA256}"
    error "Actual:   ${actual_sha256}"
    return 1
  fi
}

find_code() {
  # The /usr/local/bin/code shim that ships with mcr.microsoft.com/devcontainers/base
  # only works when the VS Code Server remote-cli is also in PATH AFTER the shim,
  # which is not guaranteed for non-interactive postAttachCommand shells. Resolve
  # the remote-cli `code` directly to avoid that fragility. Search the known
  # install roots (devcontainers, GitHub Codespaces, insiders).
  local pattern
  for pattern in \
    "${HOME}"/.vscode-server/bin/*/bin/remote-cli/code \
    "${HOME}"/.vscode-server-insiders/bin/*/bin/remote-cli/code \
    "${HOME}"/.vscode-remote/bin/*/bin/remote-cli/code \
    /vscode/vscode-server/bin/*/bin/remote-cli/code \
    /vscode/vscode-server/bin/linux-*/*/bin/remote-cli/code; do
    # Iterate over the glob expansion (or literal pattern if no match).
    for candidate in ${pattern}; do
      if [ -x "${candidate}" ]; then
        printf '%s\n' "${candidate}"
        return 0
      fi
    done
  done

  return 1
}

log_code_search_diagnostics() {
  error "VS Code remote-cli not found. Searched under:"
  error "  ${HOME}/.vscode-server/, ${HOME}/.vscode-server-insiders/, ${HOME}/.vscode-remote/, /vscode/vscode-server/"
  error "Listing ~/.vscode* and /vscode for diagnostics:"
  ls -la "${HOME}" 2>&1 | grep -E '\.vscode' >&2 || true
  ls -la /vscode 2>&1 >&2 || true
}

main_install() {
  say "Checking OAI-compatible Copilot extension"

  if ! CODE_BIN="$(find_code)"; then
    log_code_search_diagnostics
    return 1
  fi
  log "Using VS Code CLI: ${CODE_BIN}"

  require_cmd grep || return 1
  require_cmd realpath || return 1
  require_cmd sha256sum || return 1
  require_cmd awk || return 1

  load_pin_file || return 1
  verify_required_vars || return 1

  VSIX_PATH="${VSIX_DIR}/${VSIX_FILENAME}"
  verify_vsix_path || return 1

  if [ ! -f "${VSIX_PATH}" ]; then
    error "VSIX not found at ${VSIX_PATH}"
    error "Expected post-create.sh to download and verify the pinned VSIX first."
    return 1
  fi

  log "Verifying VSIX SHA256 before install..."
  verify_sha256 || return 1

  if "${CODE_BIN}" --list-extensions | grep -qx "${EXTENSION_ID}"; then
    log "Extension already installed: ${EXTENSION_ID}"
    return 0
  fi

  log "Installing extension from verified VSIX: ${VSIX_PATH}"
  "${CODE_BIN}" --install-extension "${VSIX_PATH}"

  if ! "${CODE_BIN}" --list-extensions | grep -qx "${EXTENSION_ID}"; then
    error "extension was not installed: ${EXTENSION_ID}"
    return 1
  fi

  log "OAI-compatible Copilot extension installed: ${EXTENSION_ID}"
}

if ! main_install; then
  printf "%b\n      [post-attach] FATAL: Failed to install required OAI-compatible Copilot extension.%b\n" "${RED}${BOLD}" "${RESET}" >&2
  printf "%b      [post-attach] The VSIX must match the pinned SHA256 before installation.%b\n" "${RED}" "${RESET}" >&2
  printf "%b      [post-attach] Please check logs above.%b\n" "${RED}" "${RESET}" >&2
  exit 1
fi

printf "%b\n==> [post-attach] complete — Copilot extension installed.%b\n" "${BOLD}${GREEN}" "${RESET}"
