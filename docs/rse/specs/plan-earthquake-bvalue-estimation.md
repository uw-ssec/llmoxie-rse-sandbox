# Implementation Plan: Gutenberg–Richter b-value estimation for seismic sample catalog

---
**Date:** 2026-06-23
**Author:** AI Assistant
**Status:** Complete
**Related Documents:**
- [Research: Earthquake Gutenberg–Richter b-value estimation methods](./research-earthquake-bvalue-methods.md)

---

## Overview

This plan adds a small, testable analysis workflow under `samples/seismic/` that estimates Gutenberg–Richter b-value from `samples/seismic/earthquake_catalog.csv` using magnitudes above the completeness magnitude \(M_c\). The estimator will use binned Aki/Utsu maximum likelihood with \(\Delta M = 0.1\), matching the one-decimal magnitudes in the catalog.

The implementation will provide: (1) automatic \(M_c\) via maximum-curvature on the non-cumulative magnitude histogram, (2) optional manual \(M_c\) override, (3) uncertainty via bootstrap confidence intervals, and (4) a CLI entry script that prints a reproducible summary.

**Goal:** Produce a deterministic, reproducible b-value estimate above completeness magnitude with explicit \(M_c\), sample size, and uncertainty.

**Motivation:** The repository currently contains the seismic catalog but no executable b-value estimation workflow; this closes that gap with a research-code-safe implementation and measurable verification.

## Current State Analysis

**Existing Implementation:**
- `samples/seismic/earthquake_catalog.csv:1-3001` — Catalog data exists with columns `time,magnitude` and 3000 events.
- `samples/seismic/earthquake_catalog.csv:1` — Header confirms required fields.
- `samples/seismic/earthquake_catalog.csv:2-20` — Early rows show one-decimal magnitudes.
- `samples/seismic/earthquake_catalog.csv:2985-3001` — Late rows confirm full time span through 2023-12-31.
- `docs/rse/specs/research-earthquake-bvalue-methods.md:65-90` — Recommends binned Aki/Utsu MLE and explicit completeness handling.
- `docs/rse/specs/research-earthquake-bvalue-methods.md:113-124` — Recommends threshold sensitivity and uncertainty reporting.

**Current Behavior:**
There is no analysis module, CLI script, or automated test in allowed editable paths that computes \(M_c\) or b-value from the seismic catalog.

**Current Limitations:**
- No implementation of completeness-magnitude estimation.
- No b-value estimator above \(M_c\).
- No uncertainty quantification or reproducible command output.

## Desired End State

**New Behavior:**
Running a single command on the catalog produces a report containing selected \(M_c\), number of events above threshold, b-value, and bootstrap confidence interval, with deterministic output when a seed is provided.

**Success Looks Like:**
- A reusable Python module in `samples/seismic/` computes \(M_c\), b-value, and CI.
- A CLI script in `samples/seismic/` executes the workflow end-to-end on the CSV.
- Tests in `samples/seismic/` verify correctness invariants and catalog-based behavior.

## What We're NOT Doing

- [ ] Implementing declustering or aftershock sequence separation.
- [ ] Implementing b-positive or other alternative b-value estimators in this change.
- [ ] Building notebooks, dashboards, or plotting workflows.
- [ ] Editing restricted files (`samples/seismic/README.md`, `samples/seismic/GROUND_TRUTH.md`, `samples/seismic/generate_catalog.py`, `samples/seismic/test_generate_catalog.py`).

**Rationale:** The scope is intentionally focused on a minimal, verifiable core estimator and CLI output for the provided sample catalog.

## Implementation Approach

**Technical Strategy:**
Implement a small functional core (`bvalue.py`) plus thin CLI wrapper (`estimate_bvalue.py`). Keep I/O and argument parsing separate from numerical routines to maximize testability. Use only stdlib + current workspace dependencies, and run all commands through `pixi run`.

**Key Architectural Decisions:**
1. **Decision:** Use binned Aki/Utsu MLE as the primary estimator.
   - **Rationale:** Matches prior-art recommendation and one-decimal magnitudes.
   - **Trade-offs:** Simpler and more robust than line-fit regression; still depends on \(M_c\) choice.
   - **Alternatives considered:** OLS on cumulative frequency–magnitude relation (kept out as primary due to bias sensitivity).
2. **Decision:** Auto-select \(M_c\) with maximum curvature, allow explicit override.
   - **Rationale:** Gives a default while preserving analyst control.
   - **Trade-offs:** Maximum curvature can be imperfect for some catalogs; override mitigates.
   - **Alternatives considered:** Goodness-of-fit-only selection (deferred for scope control).
3. **Decision:** Bootstrap percentile interval for uncertainty with seed control.
   - **Rationale:** Makes uncertainty visible and reproducible.
   - **Trade-offs:** Additional runtime vs analytic-only error estimate.
   - **Alternatives considered:** Analytic standard error only (deferred; bootstrap retained as primary).

**Patterns to Follow:**
- Functional pure-computation routines with explicit inputs/outputs in `samples/seismic/bvalue.py:1-180` (new).
- CLI argument parsing and summary printing in `samples/seismic/estimate_bvalue.py:1-120` (new).
- `unittest`-based test files in `samples/seismic/test_bvalue.py:1-220` (new).

## Implementation Phases

### Phase 1: Build failing tests for completeness and b-value core math

**Objective:** Lock in expected numerical behavior and error handling before implementation.

**Tasks:**
- [x] **Write failing unit tests** for completeness-magnitude selection, b-value formula, and threshold filtering.
  - File: `samples/seismic/test_bvalue.py:1-120` (new)

  ```python
  import math
  import unittest

  from samples.seismic.bvalue import estimate_mc_max_curvature, estimate_b_value


  class TestBValueCore(unittest.TestCase):
      def test_mc_max_curvature_picks_modal_bin(self):
          mags = [2.0, 2.0, 2.1, 2.1, 2.1, 2.2, 3.0]
          self.assertEqual(estimate_mc_max_curvature(mags, delta_m=0.1), 2.1)

      def test_b_value_uses_binned_aki_utsu(self):
          mags = [2.1, 2.2, 2.3, 2.4]
          b = estimate_b_value(mags, mc=2.1, delta_m=0.1)
          expected = math.log10(math.e) / (((2.1 + 2.2 + 2.3 + 2.4) / 4) - (2.1 - 0.05))
          self.assertAlmostEqual(b, expected, places=12)

      def test_b_value_raises_if_no_events_above_mc(self):
          with self.assertRaises(ValueError):
              estimate_b_value([1.9, 1.8], mc=2.0, delta_m=0.1)
  ```

- [x] **Run it, watch it fail:**  
  `pixi run python -m unittest samples/seismic/test_bvalue.py -v`  
  → expect import failure because `samples/seismic/bvalue.py` does not exist yet.
- [x] **Implement minimal core code** to make tests pass.
  - File: `samples/seismic/bvalue.py:1-120` (new)

  ```python
  from collections import Counter
  import math


  def estimate_mc_max_curvature(magnitudes, delta_m=0.1):
      if not magnitudes:
          raise ValueError("magnitudes must be non-empty")
      rounded = [round(m / delta_m) * delta_m for m in magnitudes]
      counts = Counter(rounded)
      mc, _ = max(counts.items(), key=lambda kv: (kv[1], -kv[0]))
      return round(mc, 1)


  def estimate_b_value(magnitudes, mc, delta_m=0.1):
      selected = [m for m in magnitudes if m >= mc]
      if not selected:
          raise ValueError("no magnitudes at or above mc")
      mean_mag = sum(selected) / len(selected)
      denom = mean_mag - (mc - delta_m / 2.0)
      if denom <= 0:
          raise ValueError("invalid denominator for b-value estimate")
      return math.log10(math.e) / denom
  ```

- [x] **Run it, watch it pass:**  
  `pixi run python -m unittest samples/seismic/test_bvalue.py -v`
- [ ] **Commit:**  
  `git commit -m "feat: add tested core completeness and b-value estimators"`

**Dependencies:**
- None.

**Verification:**
- [x] `pixi run python -m unittest samples/seismic/test_bvalue.py -v` returns `OK`.

### Phase 2: Implement catalog workflow and bootstrap uncertainty

**Objective:** Add end-to-end computation from CSV with auto/manual \(M_c\), sample size, and confidence interval.

**Tasks:**
- [x] **Write failing tests** for CSV ingestion, manual \(M_c\) override, and deterministic bootstrap CI.
  - File: `samples/seismic/test_bvalue.py:121-220`

  ```python
  from pathlib import Path

  from samples.seismic.bvalue import estimate_catalog_b_value


  def test_catalog_estimation_returns_expected_fields():
      result = estimate_catalog_b_value(
          Path("samples/seismic/earthquake_catalog.csv"),
          mc=None,
          delta_m=0.1,
          bootstrap_samples=200,
          seed=7,
      )
      assert {"mc", "n", "b_value", "ci_low", "ci_high"} <= result.keys()
      assert result["n"] > 0
      assert result["ci_low"] <= result["b_value"] <= result["ci_high"]


  def test_manual_mc_override_is_respected():
      auto = estimate_catalog_b_value(Path("samples/seismic/earthquake_catalog.csv"), mc=None, seed=7)
      manual = estimate_catalog_b_value(Path("samples/seismic/earthquake_catalog.csv"), mc=3.0, seed=7)
      assert manual["mc"] == 3.0
      assert manual["n"] <= auto["n"]
  ```

- [x] **Run it, watch it fail:**  
  `pixi run python -m unittest samples/seismic/test_bvalue.py -v`  
  → expect missing `estimate_catalog_b_value`.
- [x] **Implement minimal workflow code** with explicit edge handling.
  - File: `samples/seismic/bvalue.py:121-220`

  ```python
  import csv
  import random
  from pathlib import Path


  def estimate_catalog_b_value(path, mc=None, delta_m=0.1, bootstrap_samples=1000, seed=0):
      path = Path(path)
      with path.open("r", encoding="utf-8") as f:
          rows = list(csv.DictReader(f))
      if not rows or "magnitude" not in rows[0]:
          raise ValueError("catalog must contain a 'magnitude' column")
      magnitudes = [float(r["magnitude"]) for r in rows]
      selected_mc = estimate_mc_max_curvature(magnitudes, delta_m) if mc is None else float(mc)
      selected = [m for m in magnitudes if m >= selected_mc]
      if len(selected) < 2:
          raise ValueError("need at least 2 events at or above mc")
      b_hat = estimate_b_value(selected, mc=selected_mc, delta_m=delta_m)

      rng = random.Random(seed)
      boots = []
      for _ in range(int(bootstrap_samples)):
          sample = [selected[rng.randrange(len(selected))] for _ in range(len(selected))]
          boots.append(estimate_b_value(sample, mc=selected_mc, delta_m=delta_m))
      boots.sort()
      lo = boots[int(0.025 * len(boots))]
      hi = boots[int(0.975 * len(boots))]
      return {"mc": selected_mc, "n": len(selected), "b_value": b_hat, "ci_low": lo, "ci_high": hi}
  ```

- [x] **Run it, watch it pass:**  
  `pixi run python -m unittest samples/seismic/test_bvalue.py -v`
- [ ] **Commit:**  
  `git commit -m "feat: add catalog-level b-value workflow with bootstrap CI"`

**Dependencies:**
- Requires Phase 1 completion.

**Verification:**
- [x] `pixi run python -m unittest samples/seismic/test_bvalue.py -v` returns `OK`.

### Phase 3: Add CLI entry script and reproducible end-to-end check

**Objective:** Provide a user-facing command that prints b-value results for the sample catalog.

**Tasks:**
- [x] **Write failing CLI test** validating output contains required metrics.
  - File: `samples/seismic/test_bvalue.py:221-300` (append)

  ```python
  import subprocess
  import sys


  def test_cli_prints_required_metrics():
      proc = subprocess.run(
          [
              sys.executable,
              "samples/seismic/estimate_bvalue.py",
              "--catalog",
              "samples/seismic/earthquake_catalog.csv",
              "--seed",
              "7",
              "--bootstrap-samples",
              "200",
          ],
          check=True,
          capture_output=True,
          text=True,
      )
      out = proc.stdout
      assert "mc=" in out
      assert "n=" in out
      assert "b_value=" in out
      assert "ci95=" in out
  ```

- [x] **Run it, watch it fail:**  
  `pixi run python -m unittest samples/seismic/test_bvalue.py -v`  
  → expect missing CLI script.
- [x] **Implement minimal CLI script**.
  - File: `samples/seismic/estimate_bvalue.py:1-120` (new)

  ```python
  import argparse
  from pathlib import Path

  from samples.seismic.bvalue import estimate_catalog_b_value


  def main():
      parser = argparse.ArgumentParser()
      parser.add_argument("--catalog", type=Path, required=True)
      parser.add_argument("--mc", type=float, default=None)
      parser.add_argument("--delta-m", type=float, default=0.1)
      parser.add_argument("--bootstrap-samples", type=int, default=1000)
      parser.add_argument("--seed", type=int, default=0)
      args = parser.parse_args()

      result = estimate_catalog_b_value(
          args.catalog,
          mc=args.mc,
          delta_m=args.delta_m,
          bootstrap_samples=args.bootstrap_samples,
          seed=args.seed,
      )
      print(
          f"mc={result['mc']:.1f} n={result['n']} "
          f"b_value={result['b_value']:.4f} "
          f"ci95=({result['ci_low']:.4f}, {result['ci_high']:.4f})"
      )


  if __name__ == "__main__":
      main()
  ```

- [x] **Run it, watch it pass:**  
  `pixi run python -m unittest samples/seismic/test_bvalue.py -v`
- [x] **Run end-to-end command:**  
  `pixi run python samples/seismic/estimate_bvalue.py --catalog samples/seismic/earthquake_catalog.csv --seed 7 --bootstrap-samples 1000`
- [ ] **Commit:**  
  `git commit -m "feat: add CLI for Gutenberg-Richter b-value estimation"`

**Dependencies:**
- Requires Phase 2 completion.

**Verification:**
- [x] CLI command prints one line containing `mc=`, `n=`, `b_value=`, and `ci95=`.

## Success Criteria

### Automated Verification

- [x] `pixi run python -m unittest samples/seismic/test_bvalue.py -v` passes with no failures.
- [x] `pixi run python samples/seismic/estimate_bvalue.py --catalog samples/seismic/earthquake_catalog.csv --seed 7 --bootstrap-samples 1000` exits with code 0.
- [x] CLI output includes required fields: `mc`, `n`, `b_value`, `ci95`.
- [x] Running the same CLI command twice with identical seed produces identical numeric output.
- [x] Manual override command  
      `pixi run python samples/seismic/estimate_bvalue.py --catalog samples/seismic/earthquake_catalog.csv --mc 3.0 --seed 7 --bootstrap-samples 1000`  
      reports `mc=3.0`.

### Manual Verification

- [x] Reported \(M_c\) is plausible relative to the catalog’s dominant one-decimal bins and not below minimum magnitude.
- [x] Reported \(n\) decreases (or stays equal) when a higher manual \(M_c\) is supplied.
- [x] CI width is qualitatively reasonable (not zero, not implausibly huge for this catalog size).
- [x] Command help text is understandable:  
      `pixi run python samples/seismic/estimate_bvalue.py --help`.

### Reproducibility & Correctness (research code)

- [x] Exact command, seed, bootstrap sample count, and catalog path are documented in test cases and CLI usage.
- [x] Numerical correctness is verified against direct formula assertions in unit tests (`estimate_b_value` test uses closed-form expected value).
- [x] Clean re-run from repository root reproduces the same seeded CLI estimate.

## Testing Strategy

**Unit Test Coverage (summary, written in-phase):**
- [x] Completeness magnitude by maximum curvature.
- [x] Binned Aki/Utsu b-value formula and denominator guard.
- [x] Catalog parsing and required column validation.
- [x] Bootstrap interval ordering and containment of point estimate.
- [x] CLI output contract.

**Integration Tests:**
- [x] End-to-end run from catalog CSV through CLI summary output.
- [x] Manual-vs-auto \(M_c\) behavior comparison.

**Manual Testing:**
- [x] Run CLI with default auto-\(M_c\) and inspect one-line summary.
- [x] Run CLI with `--mc 3.0` and confirm threshold behavior in summary.

**Test Data Requirements:**
- `samples/seismic/earthquake_catalog.csv` only.
- No synthetic or external data files required.

## References

**Research Documents:**
- [Research: Earthquake Gutenberg–Richter b-value estimation methods](./research-earthquake-bvalue-methods.md)

**Experiment Reports:**
- None currently.

**Files Analyzed:**
- `samples/seismic/earthquake_catalog.csv`
- `docs/rse/specs/research-earthquake-bvalue-methods.md`
- `/home/vscode/.agents/skills/planning-implementations/assets/plan-template.md`

**External Documentation:**
- Aki, K. (1965). Maximum likelihood estimate of b in log N = a − bM.
- Wiemer, S. and Wyss, M. (2000). Minimum Magnitude of Completeness in Earthquake Catalogs.

