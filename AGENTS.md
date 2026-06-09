# AGENTS.md — sandbox demo guardrails

This repository is a **guided demo sandbox**. When working here, focus your work on
the files under `samples/` — nothing else.

## Scope: only touch `samples/`

**Focus exclusively on the files under `samples/`.** Treat everything else in this
repository as fixed infrastructure that is out of scope:

- `.devcontainer/` — container setup. Do not modify.
- `.github/` — Copilot prompt files and config. Do not modify.
- `vendor/` — the `rse-plugins` submodule. Read-only.
- `docs/` — documentation and the slide deck. Do **not** edit, with one exception:
  generated artifacts **may** be written to `docs/rse/specs/`.
- `README.md`, `pixi.toml`, `pixi.lock`, this `AGENTS.md` — leave as-is.

If a task seems to require changing anything outside `samples/` (other than writing
artifacts to `docs/rse/specs/`), stop and ask before proceeding.

## Conventions

- The environment is managed with **pixi** (`pixi.toml` / `pixi.lock`). Use
  `pixi run` / `pixi add`; do not introduce pip/conda/uv workflows.
- Keep changes reviewable: small, focused diffs over the `samples/` code.
