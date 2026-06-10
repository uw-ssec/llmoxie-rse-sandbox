#!/usr/bin/env bash
set -euo pipefail

# --- Output styling -------------------------------------------------------
# Colors are emitted unconditionally (not gated on a tty) because the
# devcontainer / Codespaces "starting container" log renders ANSI codes.
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BOLD="\033[1m"
RESET="\033[0m"

STAGE="post-start"
TOTAL_STEPS=3

say()  { printf "%b\n==> [%s] (%s/%s) %s%b\n" "${BOLD}${GREEN}" "${STAGE}" "$1" "${TOTAL_STEPS}" "$2" "${RESET}"; }
info() { printf "      %s\n" "$1"; }
warn() { printf "%b  !   %s%b\n" "${YELLOW}" "$1" "${RESET}"; }

SESSION_DIR="${XDG_RUNTIME_DIR:-$HOME/.cache/llmaven}"
SESSION_FILE="${SESSION_DIR}/session_id"
VSIX_PATH="${HOME}/.cache/oai-compatible-copilot/oai-compatible-copilot-sandbox.vsix"

say 1 "Initializing LLMoxie session"
mkdir -p "${SESSION_DIR}"
chmod 700 "${SESSION_DIR}"

if [ ! -f "${SESSION_FILE}" ]; then
  TMP_SESSION_FILE="$(mktemp "${SESSION_DIR}/session_id.XXXXXX")"
  trap 'rm -f "${TMP_SESSION_FILE}"' EXIT

  cat /proc/sys/kernel/random/uuid > "${TMP_SESSION_FILE}"

  chmod 600 "${TMP_SESSION_FILE}"
  mv "${TMP_SESSION_FILE}" "${SESSION_FILE}"
  trap - EXIT
fi

chmod 600 "${SESSION_FILE}" || true

SESSION_ID="$(cat "${SESSION_FILE}")"
SHORT_SESSION_ID="${SESSION_ID%%-*}"
info "Session: ${SHORT_SESSION_ID}..."

if [ -z "${OAI_API_KEY:-}" ]; then
  warn "OAI_API_KEY is not set; the LLMoxie Copilot extension may not authenticate."
fi

say 2 "Checking OAI-compatible Copilot VSIX artifact"
if [ -f "${VSIX_PATH}" ]; then
  info "VSIX present: ${VSIX_PATH}"
else
  warn "VSIX not found at ${VSIX_PATH}"
fi

say 3 "Checking LLMoxie gateway credentials"
if [ -n "${LITELLM_BASE_URL:-}" ]; then
  info "LITELLM_BASE_URL: configured"
else
  warn "LITELLM_BASE_URL is not set"
fi

if [ -n "${LITELLM_API_KEY:-}" ]; then
  info "LITELLM_API_KEY: detected"
else
  warn "LITELLM_API_KEY is not set"
fi

if [ -n "${OAI_API_KEY:-}" ]; then
  info "OAI_API_KEY alias: detected"
else
  warn "OAI_API_KEY is not set"
fi

printf "%b\n==> [%s] complete — container is ready.%b\n" "${BOLD}${GREEN}" "${STAGE}" "${RESET}"
