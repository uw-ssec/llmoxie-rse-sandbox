#!/usr/bin/env bash
set -euo pipefail

echo "[on-create] Preparing workspace..."

if [ -e .pixi ]; then
  if [ ! -d .pixi ] || [ -L .pixi ]; then
    echo "Refusing to chown .pixi: must be a real directory, not a symlink" >&2
    exit 1
  fi

  PIXI_REAL="$(realpath .pixi)"
  WORKSPACE_REAL="$(realpath .)"

  case "$PIXI_REAL" in
    "$WORKSPACE_REAL"/*) ;;
    *)
      echo "Refusing to chown .pixi: resolved path '$PIXI_REAL' is outside workspace '$WORKSPACE_REAL'" >&2
      exit 1
      ;;
  esac

  sudo chown -R --no-dereference vscode:vscode "$PIXI_REAL"
fi

echo "[on-create] Installing pixi environment..."
pixi install --locked

# Auto-activate the pixi env in every interactive shell so Python is the active
# interpreter for VS Code, Copilot Chat, and integrated terminals — not just on PATH.
echo "[on-create] Adding pixi shell-hook to ~/.bashrc..."
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
fi

echo ""
echo "[on-create] Workspace bootstrap complete."
echo "[on-create] Next step: open README.md for the sandbox walkthrough"
