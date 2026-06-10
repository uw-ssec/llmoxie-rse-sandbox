#!/usr/bin/env bash
set -euo pipefail

# --- Output styling -------------------------------------------------------
# Colors are emitted unconditionally (not gated on a tty) because the
# devcontainer / Codespaces "creating container" log renders ANSI codes.
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BOLD="\033[1m"
RESET="\033[0m"

STAGE="on-create"
TOTAL_STEPS=3

say()  { printf "%b\n==> [%s] (%s/%s) %s%b\n" "${BOLD}${GREEN}" "${STAGE}" "$1" "${TOTAL_STEPS}" "$2" "${RESET}"; }
info() { printf "      %s\n" "$1"; }
warn() { printf "%b  !   %s%b\n" "${YELLOW}" "$1" "${RESET}"; }
err()  { printf "%b  ERROR: %s%b\n" "${RED}" "$1" "${RESET}" >&2; }

say 1 "Preparing workspace"
if [ -e .pixi ]; then
  if [ ! -d .pixi ] || [ -L .pixi ]; then
    err "Refusing to chown .pixi: must be a real directory, not a symlink"
    exit 1
  fi

  PIXI_REAL="$(realpath .pixi)"
  WORKSPACE_REAL="$(realpath .)"

  case "$PIXI_REAL" in
    "$WORKSPACE_REAL"/*) ;;
    *)
      err "Refusing to chown .pixi: resolved path '$PIXI_REAL' is outside workspace '$WORKSPACE_REAL'"
      exit 1
      ;;
  esac

  sudo chown -R --no-dereference vscode:vscode "$PIXI_REAL"
  info "Reclaimed ownership of .pixi volume mount"
else
  info "No .pixi yet — it will be created by pixi in the next step"
fi

say 2 "Installing pixi environment"
pixi install --locked

# Auto-activate the pixi env in every interactive shell so Python is the active
# interpreter for VS Code, Copilot Chat, and integrated terminals — not just on PATH.
say 3 "Configuring shell auto-activation of the pixi env"
BASHRC="${HOME}/.bashrc"
HOOK_MARKER='# >>> pixi shell-hook (llmaven-rse-sandbox) >>>'
if ! grep -qF "${HOOK_MARKER}" "${BASHRC}" 2>/dev/null; then
  {
    echo ""
    echo "${HOOK_MARKER}"
    # Skip activation when a parent process (e.g. pixi-code's `pixi shell` for
    # VS Code terminal activation) has already entered the env. Without this
    # guard, the hook re-prepends the env name to PS1, producing a doubled
    # "(llmaven-rse-sandbox) (llmaven-rse-sandbox)" prompt.
    echo 'if [ -z "${PIXI_ENVIRONMENT_NAME:-}" ]; then'
    pixi shell-hook
    echo 'fi'
    echo "# <<< pixi shell-hook (llmaven-rse-sandbox) <<<"
  } >> "${BASHRC}"
  info "Added pixi shell-hook to ~/.bashrc"
else
  info "~/.bashrc already has the pixi shell-hook"
fi

printf "%b\n==> [%s] complete — workspace is ready.%b\n" "${BOLD}${GREEN}" "${STAGE}" "${RESET}"
info "Next step: open README.md for the sandbox walkthrough"
