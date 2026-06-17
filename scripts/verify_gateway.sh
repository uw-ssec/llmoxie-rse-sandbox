#!/usr/bin/env bash
set -euo pipefail

# Verifies the LLMoxie / LiteLLM gateway is reachable from this Codespace and
# lists the UW SSEC models. Run via `pixi run verify` or the VS Code task
# "verify-gateway" (wired to the Get Started walkthrough).

GREEN="\033[0;32m"
RED="\033[0;31m"
BOLD="\033[1m"
RESET="\033[0m"

pass() {
  printf "  %b\xE2\x9C\x93%b %s\n" "${GREEN}" "${RESET}" "$1"
}

# fail <what-failed> <single-next-action>
fail() {
  printf "  %b\xE2\x9C\x97 %s%b\n" "${RED}" "$1" "${RESET}"
  printf "\n%b\xE2\x86\x92 Next:%b %s\n" "${BOLD}" "${RESET}" "$2"
  exit 1
}

printf "%bLLMoxie RSE Sandbox \xE2\x80\x94 gateway check%b\n\n" "${BOLD}" "${RESET}"

# The Codespace secrets surface as LITELLM_*; the devcontainer remoteEnv
# guarantees COPILOT_PROVIDER_* in every terminal. Accept either so the check
# works even if only one route is present.
BASE_URL="${LITELLM_BASE_URL:-}"
if [ -z "${BASE_URL}" ] && [ -n "${COPILOT_PROVIDER_BASE_URL:-}" ]; then
  BASE_URL="${COPILOT_PROVIDER_BASE_URL%/v1}"
fi

API_KEY="${LITELLM_API_KEY:-${COPILOT_PROVIDER_API_KEY:-${OAI_API_KEY:-}}}"

if [ -z "${BASE_URL}" ]; then
  fail "gateway base URL is not set (LITELLM_BASE_URL)" \
    "this Codespace was not created through the authorized onboarding flow, so the gateway secrets are missing. Create a Codespace via the onboarding flow (see README \"Trust assumptions\")."
fi
pass "gateway base URL is set"

if [ -z "${API_KEY}" ]; then
  fail "gateway API key is not set (LITELLM_API_KEY)" \
    "this Codespace was not created through the authorized onboarding flow, so the gateway secrets are missing. Create a Codespace via the onboarding flow (see README \"Trust assumptions\")."
fi
pass "gateway API key is set"

MODELS_JSON="$(curl -fsSL --max-time 15 \
  --proto '=https' --tlsv1.2 \
  -H "Authorization: Bearer ${API_KEY}" \
  "${BASE_URL%/}/v1/models")" || fail "gateway unreachable at ${BASE_URL%/}/v1/models" \
    "check your network connection and retry with \`pixi run verify\`. If it keeps failing, the gateway may be down — contact the UW SSEC team."
pass "gateway reachable"

for MODEL in gpt-5.5 gpt-5.4-mini; do
  if ! printf '%s' "${MODELS_JSON}" | grep -q "\"${MODEL}\""; then
    fail "model ${MODEL} not listed by the gateway" \
      "the gateway responded but does not expose ${MODEL}. Contact the UW SSEC team — your key may have the wrong model access."
  fi
  pass "model available: ${MODEL}"
done

printf "\n%b\xE2\x9C\x93 Gateway verified \xE2\x80\x94 select a UW SSEC model in Copilot Chat and you are ready to go.%b\n" "${GREEN}${BOLD}" "${RESET}"
