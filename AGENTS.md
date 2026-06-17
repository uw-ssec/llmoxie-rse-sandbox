# AGENTS.md — sandbox demo guardrails

This repository is a **guided demo sandbox**. When working here, focus your work on
the files under `samples/` — nothing else.

## Scope: only touch `samples/`

**You may write ONLY under `samples/` and `docs/rse/specs/`.**

**DO NOT READ any files in `docs/slides`**
**DO NOT READ any files in `docs/expected-specs`**

**Completely ignore `archive/` and everything under it** — do not read, cite,
search, or modify it. It holds retired demo content that is not part of the
sandbox.

**Focus exclusively on the files under `samples/`.** Treat everything else in this
repository as fixed infrastructure that is out of scope:

- `.devcontainer/` — container setup. Do not modify.
- `.github/` — GitHub workflows and config. Do not modify.
- `vendor/` — the `rse-plugins` submodule. Read-only.
- `docs/` — documentation and the slide deck. Do **not** edit, with one exception:
  generated artifacts **may** be written to `docs/rse/specs/`.
- `README.md`, `pixi.toml`, `pixi.lock`, this `AGENTS.md` — leave as-is.

If a task seems to require changing anything outside `samples/` (other than writing
artifacts to `docs/rse/specs/`), stop and ask before proceeding.

## Demo integrity: ignore the ground truth

`samples/ocean/GROUND_TRUTH.md` documents the known answer baked into the
synthetic buoy data so a **human** can check the demo's result. When researching,
analyzing, experimenting on, or validating that data, **never read, cite, or use
`GROUND_TRUTH.md`**.

**DO NOT READ the data-generation scripts** — `samples/ocean/generate_buoy_sst.py`
and its test `samples/ocean/test_generate_buoy_sst.py`. They hard-code the trend
value baked into the data, so reading them leaks the answer. Do not read, cite,
search, or lift constants from them. Recover results from `buoy_sst.csv` alone;
an analysis that peeks at the answer defeats the demo.

## Conventions

- The environment is managed with **pixi** (`pixi.toml` / `pixi.lock`). Use
  `pixi run` / `pixi add`; do not introduce pip/conda/uv workflows.
- Keep changes reviewable: small, focused diffs over the `samples/` code.
