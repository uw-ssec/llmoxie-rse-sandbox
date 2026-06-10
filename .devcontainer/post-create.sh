#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PIN_FILE="${SCRIPT_DIR}/oai-compatible-copilot-vsix.env"

VSIX_RELEASE_TAG=""
VSIX_FILENAME=""
VSIX_SOURCE_COMMIT=""
EXPECTED_VSIX_SHA256=""

VSIX_DIR="${HOME}/.cache/oai-compatible-copilot"

# --- Output styling -------------------------------------------------------
# Colors are emitted unconditionally (not gated on a tty) because the
# devcontainer / Codespaces "creating container" log renders ANSI codes.
GREEN="\033[0;32m"
RED="\033[0;31m"
BOLD="\033[1m"
RESET="\033[0m"

say() {
  printf "%b\n==> [post-create] %s%b\n" "${BOLD}${GREEN}" "$1" "${RESET}"
}

log() {
  printf "      [post-create] %s\n" "$*"
}

error() {
  printf "%b      [post-create] ERROR: %s%b\n" "${RED}" "$*" "${RESET}" >&2
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
        VSIX_RELEASE_TAG="${value}"
        ;;
      VSIX_FILENAME)
        VSIX_FILENAME="${value}"
        ;;
      VSIX_SOURCE_COMMIT)
        VSIX_SOURCE_COMMIT="${value}"
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
  if [ -z "${VSIX_RELEASE_TAG:-}" ]; then
    error "VSIX_RELEASE_TAG is not set"
    return 1
  fi

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

  if ! printf '%s' "${VSIX_RELEASE_TAG}" | grep -Eq '^[A-Za-z0-9._-]+$'; then
    error "VSIX_RELEASE_TAG must contain only letters, numbers, dots, underscores, and hyphens"
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

  if [ -n "${VSIX_SOURCE_COMMIT:-}" ] &&
     ! printf '%s' "${VSIX_SOURCE_COMMIT}" | grep -Eq '^[a-fA-F0-9]{7,40}$'; then
    error "VSIX_SOURCE_COMMIT must be a short or full hex commit SHA"
    return 1
  fi
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

main_download() {
  say "Preparing prebuilt OAI-compatible Copilot VSIX"

  require_cmd curl || return 1
  require_cmd grep || return 1
  require_cmd realpath || return 1
  require_cmd sha256sum || return 1
  require_cmd awk || return 1

  load_pin_file || return 1
  verify_required_vars || return 1

  VSIX_PATH="${VSIX_DIR}/${VSIX_FILENAME}"
  VSIX_URL="https://github.com/uw-ssec/oai-compatible-copilot/releases/download/${VSIX_RELEASE_TAG}/${VSIX_FILENAME}"

  mkdir -p "${VSIX_DIR}"
  verify_vsix_path || return 1

  # Skip download if the image already pre-cached the verified VSIX.
  if [ -f "${VSIX_PATH}" ]; then
    log "VSIX already present, verifying cached copy..."
    if verify_sha256; then
      log "Cache hit: ${VSIX_PATH}"
      return 0
    fi
    log "Cached VSIX failed SHA256 check — re-downloading..."
  fi

  log "Release tag: ${VSIX_RELEASE_TAG}"
  if [ -n "${VSIX_SOURCE_COMMIT:-}" ]; then
    log "Source commit metadata: ${VSIX_SOURCE_COMMIT}"
  fi

  log "Downloading ${VSIX_URL}"
  curl -fsSL \
    --retry 3 \
    --retry-delay 2 \
    --proto '=https' \
    --tlsv1.2 \
    -o "${VSIX_PATH}" \
    "${VSIX_URL}"

  log "Verifying VSIX SHA256 against pinned in-repo value..."
  verify_sha256 || return 1

  chmod 0644 "${VSIX_PATH}"

  log "VSIX ready: ${VSIX_PATH}"
}

if ! main_download; then
  printf "%b\n      [post-create] FATAL: Failed to prepare required OAI-compatible Copilot extension VSIX.%b\n" "${RED}${BOLD}" "${RESET}" >&2
  printf "%b      [post-create] This sandbox is designed to demonstrate that extension.%b\n" "${RED}" "${RESET}" >&2
  printf "%b      [post-create] Please check logs above.%b\n" "${RED}" "${RESET}" >&2
  exit 1
fi

printf "%b\n==> [post-create] complete — Copilot extension VSIX is staged.%b\n" "${BOLD}${GREEN}" "${RESET}"
