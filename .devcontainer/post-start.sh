#!/usr/bin/env bash
set -euo pipefail

SESSION_DIR="${XDG_RUNTIME_DIR:-$HOME/.cache/llmaven}"
SESSION_FILE="${SESSION_DIR}/session_id"
VSIX_PATH="${HOME}/.cache/oai-compatible-copilot/oai-compatible-copilot-sandbox.vsix"

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

echo ""
echo "LLMaven session initialized: ${SHORT_SESSION_ID}..."

if [ -z "${OAI_API_KEY:-}" ]; then
  echo "Warning: OAI_API_KEY is not set; the LLMaven Copilot extension may not authenticate."
fi

echo ""
echo "[post-start] VSIX artifact status:"
if [ -f "${VSIX_PATH}" ]; then
  echo "[post-start] VSIX present: ${VSIX_PATH}"
else
  echo "[post-start] Warning: VSIX not found at ${VSIX_PATH}"
fi

if [ -n "${LITELLM_BASE_URL:-}" ]; then
  echo "[post-start] Base URL: configured"
fi

if [ -n "${LITELLM_API_KEY:-}" ]; then
  echo "[post-start] LiteLLM API key: detected"
fi

if [ -n "${OAI_API_KEY:-}" ]; then
  echo "[post-start] OAI API key alias: detected"
fi
