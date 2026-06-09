# AGENTS.md — sandbox demo guardrails

This repository is a **guided demo sandbox**. When working here, your job is the
research-loop demo over the climate scripts in `samples/` — nothing else.

## Scope: only touch `samples/`

**Focus exclusively on the files under `samples/`.** Treat everything else in this
repository as fixed infrastructure that is out of scope for the demo:

- `.devcontainer/` — container setup. Do not modify.
- `.github/` — Copilot prompt files and config. Do not modify.
- `vendor/` — the `rse-plugins` submodule (the workflow skills themselves). Read-only.
- `docs/` — documentation and the slide deck. Do **not** edit, with one exception:
  workflow artifacts **may** be written to `docs/rse/specs/` (the research loop's
  output directory).
- `README.md`, `pixi.toml`, `pixi.lock`, this `AGENTS.md` — leave as-is.

If a task seems to require changing anything outside `samples/` (other than writing
workflow artifacts to `docs/rse/specs/`), stop and ask before proceeding.

## The `samples/` code

Loose scripts — no package, no tests:

- `climate_model.py` — a toy seasonal temperature model (`estimate_temperature`).
- `climate_data_analysis.py` — a pandas analysis that reads `climate_data.csv`.
- `model_visualization.py` — a matplotlib plot of the same data.
- `climate_data.csv` — `day,temperature_c,humidity_pct` rows.

**Demo goal:** turn these scripts into an installable Python package, following
Scientific Python community guidelines.

## Conventions

- The environment is managed with **pixi** (`pixi.toml` / `pixi.lock`). Use
  `pixi run` / `pixi add`; do not introduce pip/conda/uv workflows.
- Workflow phases (`/research`, `/plan`, `/implement`, `/validate`, `/handoff`)
  write their durable artifacts to `docs/rse/specs/`.
- Keep changes reviewable: small, per-phase diffs over the `samples/` code.
