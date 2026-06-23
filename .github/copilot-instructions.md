# Demo Sandbox Guardrails for Github Copilot

This repository is a **guided demo sandbox**. When working here, focus your work on
the files under `samples/` — nothing else.

- **Write only under `samples/` and `docs/rse/specs/`.** These are the sole writable locations.
- **Read only `samples/seismic/earthquake_catalog.csv` for data inputs.**
- **Use pixi for environment management** — run `pixi run` / `pixi add`.
- **Keep diffs small, focused, and reviewable** over the `samples/` code.
- **You may read `vendor/`** (the `rse-plugins` submodule) — it is read-only reference.

- **Don't read any files in `docs/slides`.**
- **Don't read, cite, search, or modify `archive/`** or anything under it — ignore it completely.
- **Don't read `samples/seismic/generate_catalog.py`.**
- **Don't read `samples/seismic/GROUND_TRUTH.md`.**
- **Don't read `samples/seismic/README.md`.**
- **Don't read `samples/seismic/test_generate_catalog.py`.**
- **Don't modify `.devcontainer/`** (container setup).
- **Don't modify `.github/`** (workflows and config).
- **Don't modify `vendor/`** — it is read-only.
- **Don't edit `docs/`** — with the single exception of writing artifacts to `docs/rse/specs/`.
- **Don't edit `README.md`, `pixi.toml`, `pixi.lock`, or `AGENTS.md`** — leave as-is.
- **Don't introduce pip / conda / uv workflows** — pixi only.
- **Don't change anything outside `samples/`** (other than artifacts to `docs/rse/specs/`) without asking first.
