#!/usr/bin/env bash
set -euo pipefail

# Final lifecycle step: print an unmissable "ready" banner in the creation
# log terminal. Runs last in postAttachCommand, after the provider VSIX and
# walkthrough installs.

GREEN="\033[0;32m"
BOLD="\033[1m"
RESET="\033[0m"

printf "%b\n" "${BOLD}${GREEN}"
printf "==============================================================\n"
printf "\n"
printf "   \xE2\x9C\x85  SANDBOX READY\n"
printf "\n"
printf "   The LLMoxie RSE Sandbox walkthrough opens automatically\n"
printf "   and takes it from there.\n"
printf "\n"
printf "   To reopen it later: Help > Welcome > LLMoxie RSE Sandbox\n"
printf "\n"
printf "==============================================================\n"
printf "%b\n" "${RESET}"
