# Implementation Plan: Estimate Warming Trend After Removing Seasonal Cycle in `samples/ocean/buoy_sst.csv`

---
**Date:** 2026-06-11
**Author:** AI Assistant
**Status:** Draft
**Related Documents:**
- [Research: Separating Trend and Seasonal Cycle in `samples/ocean/buoy_sst.csv`](research-trend-seasonality-buoy-sst.md)

---

## Overview

This plan adds a reproducible analysis path for the synthetic buoy SST series that estimates the warming trend after removing the annual seasonal cycle. The codebase already contains a ground-truth generator and a regression-style validation test, so the implementation will formalize that analysis in a test-first way and keep the scope limited to the existing sample files under `samples/ocean/`.

The goal is to make the warming estimate explicit and verifiable: the committed series should yield a trend of about `0.03 °C/yr` when modeled with a linear time term plus annual sine/cosine seasonality. The plan does not introduce a new package, UI, or notebook; it strengthens the existing sample analysis and tests only.

**Goal:** Recover the embedded warming trend from `samples/ocean/buoy_sst.csv` after accounting for the seasonal cycle, with a measurable estimate close to `0.03 °C/yr`.

**Motivation:** The sample is meant to demonstrate a known-answer climate analysis. A clear, test-backed trend estimate makes the demo legible and protects it against future regressions.

## Current State Analysis

**Existing Implementation:**
- `samples/ocean/README.md:3-30` — documents the synthetic SST series, its known warming rate, and the regeneration command.
- `samples/ocean/generate_buoy_sst.py:20-47` — generates `sst = mean + annual sinusoid + linear warming + noise` and writes `buoy_sst.csv`.
- `samples/ocean/test_generate_buoy_sst.py:15-35` — already validates the embedded warming slope via a harmonic-plus-linear least-squares fit.
- `samples/ocean/buoy_sst.csv` — the committed data that the analysis must recover.

**Current Behavior:**
The repository already demonstrates the right mathematical structure: a stable annual seasonal cycle plus a linear trend. The existing test shows that the linear coefficient can be recovered from the committed data using a sine/cosine seasonal basis and ordinary least squares. `samples/ocean/test_generate_buoy_sst.py:15-35`

**Current Limitations:**
- No explicit regression test asserts the analysis outcome against the committed CSV values at the sample-data level.
- No dedicated helper exposes the trend/seasonal fit result for reuse by a future analysis or demo step.
- The current validation is embedded in a standalone test script, so the analysis method is not separately named or documented in code.

## Desired End State

**New Behavior:**
The sample analysis should explicitly fit a seasonal harmonic model and report the warming trend after removing the seasonal component. The result should be numerically close to `0.03 °C/yr` on the committed `buoy_sst.csv` file.

**Success Looks Like:**
- A deterministic test computes the trend estimate from `samples/ocean/buoy_sst.csv` and verifies it is within a tight tolerance of `0.03 °C/yr`.
- The analysis uses the committed daily dates to derive day-of-year seasonal terms and linear years since start.
- The implementation remains self-contained under `samples/ocean/` and does not require new dependencies.

## What We're NOT Doing

- [ ] We are not adding STL, GAM, or state-space modeling to the sample code.
- [ ] We are not changing the generator formula or the committed SST data.
- [ ] We are not adding plotting, command-line UI, or notebook workflows.

**Rationale:** The synthetic series already matches the harmonic-regression assumption, and the smallest correct implementation is the best fit for the demo.

## Implementation Approach

**Technical Strategy:**
Keep the analysis in the existing `samples/ocean/test_generate_buoy_sst.py` file, but make the trend estimate a named, reusable helper that returns the fitted warming coefficient from a harmonic regression. The test should assert the helper recovers approximately `0.03 °C/yr` from the committed file, while continuing to protect determinism and data provenance.

**Key Architectural Decisions:**
1. **Decision:** Use harmonic regression with intercept + sine + cosine + linear years.
   - **Rationale:** This exactly matches the documented generator and the current validation approach.
   - **Trade-offs:** It is less general than STL or state-space methods, but it is simpler and more accurate for the known synthetic signal.
   - **Alternatives considered:** STL decomposition and state-space models; rejected for this sample because the data are explicitly sinusoidal with a linear trend.
2. **Decision:** Keep the code in the existing sample test file instead of adding a standalone script.
   - **Rationale:** The repository already uses a plain-assert test as the sample’s validation mechanism, and the request is for analysis rather than a new interface.
   - **Trade-offs:** Less reusable than a dedicated helper module, but preserves the demo’s minimal footprint.
   - **Alternatives considered:** New analysis script; rejected to avoid extra entry points.

**Patterns to Follow:**
- `samples/ocean/generate_buoy_sst.py:31-47` — deterministic generation from date and synthetic parameters.
- `samples/ocean/test_generate_buoy_sst.py:15-35` — existing harmonic fit and numeric assertion pattern.

## Implementation Phases

Each phase's tasks are bite-sized, test-first steps with real code/commands — no placeholders. Sequence each unit of work as: failing test → run it (watch it fail) → minimal implementation → run it (watch it pass) → commit.

### Phase 1: Add a named harmonic-fit helper

**Objective:** Make the trend-estimation logic reusable and explicit in the test file.

**Tasks:**
- [x] **Write the failing test** for a helper that returns the warming estimate from the committed SST CSV.
  - File: `samples/ocean/test_generate_buoy_sst.py:15-35`

  ```python
  def test_estimate_warming_from_committed_csv():
      df = pd.read_csv(Path(__file__).with_name("buoy_sst.csv"))
      slope = g.estimate_warming_rate(df)
      assert abs(slope - g.WARMING) < 0.005
  ```

- [x] **Run it, watch it fail:** `pixi run python samples/ocean/test_generate_buoy_sst.py`
  → expect FAIL because `estimate_warming_rate` does not exist yet.
- [x] **Implement the minimal code** to pass.
  - File: `samples/ocean/test_generate_buoy_sst.py:1-40`

  ```python
  def estimate_warming_rate(df: pd.DataFrame) -> float:
      dates = pd.to_datetime(df["date"])
      doy = dates.dt.dayofyear.to_numpy()
      years = (dates - dates.iloc[0]).dt.days.to_numpy() / 365.25
      design = np.column_stack([
          np.ones_like(years),
          np.sin(2 * np.pi * doy / 365.25),
          np.cos(2 * np.pi * doy / 365.25),
          years,
      ])
      coef, *_ = np.linalg.lstsq(design, df["sst_c"].to_numpy(), rcond=None)
      return float(coef[3])
  ```

- [x] **Run it, watch it pass:** `pixi run python samples/ocean/test_generate_buoy_sst.py`
  → expect PASS and an `OK:` message.
- [ ] **Commit:** `git commit -m "feat: name buoy SST warming-rate fit"`

**Dependencies:**
- Existing `numpy` and `pandas` imports in `samples/ocean/test_generate_buoy_sst.py:1-13`.

**Verification:**
- [x] `pixi run python samples/ocean/test_generate_buoy_sst.py` prints `OK: deterministic and recovers warming slope`.

### Phase 2: Assert the committed CSV trend directly

**Objective:** Verify that the actual sample file, not just generated data in memory, recovers the documented warming rate.

**Tasks:**
- [x] **Write the failing test** that loads `samples/ocean/buoy_sst.csv` directly and asserts the helper estimate is within tolerance.
  - File: `samples/ocean/test_generate_buoy_sst.py:15-40`

  ```python
  def test_committed_csv_recovers_warming_rate():
      df = pd.read_csv(Path(__file__).with_name("buoy_sst.csv"))
      slope = estimate_warming_rate(df)
      assert abs(slope - 0.03) < 0.005
  ```

- [x] **Run it, watch it fail:** `pixi run python samples/ocean/test_generate_buoy_sst.py`
  → expect FAIL until the helper is wired in and the new test is added.
- [x] **Implement the minimal code** to pass by reusing the helper and keeping the existing deterministic test.
  - File: `samples/ocean/test_generate_buoy_sst.py:1-45`

  ```python
  def test_deterministic():
      assert g.generate().equals(g.generate())

  def test_recovers_warming_slope():
      df = g.generate()
      assert abs(estimate_warming_rate(df) - g.WARMING) < 0.005

  def test_committed_csv_recovers_warming_rate():
      df = pd.read_csv(Path(__file__).with_name("buoy_sst.csv"))
      assert abs(estimate_warming_rate(df) - 0.03) < 0.005
  ```

- [x] **Run it, watch it pass:** `pixi run python samples/ocean/test_generate_buoy_sst.py`
  → expect PASS for all assertions.
- [ ] **Commit:** `git commit -m "test: verify buoy SST trend from committed csv"`

**Dependencies:**
- Requires Phase 1 completion.

**Verification:**
- [x] `pixi run python samples/ocean/test_generate_buoy_sst.py` passes with all three tests.

### Phase 3: Document the analysis method in the sample README

**Objective:** Make the trend-removal method visible to readers of the sample data.

**Tasks:**
- [x] **Write the failing documentation expectation** as a review checklist item in the plan by confirming the README lacks an explicit helper name and direct trend-estimate description.
  - File: `samples/ocean/README.md:20-30`

  ```text
  Add a short note that the recommended analysis is harmonic regression with day-of-year sine/cosine terms and linear years, returning ≈ 0.03 °C/yr.
  ```

- [x] **Run the existing documentation review manually:** open `samples/ocean/README.md` and confirm the analysis method is not yet named explicitly.
- [x] **Implement the minimal documentation update** in `samples/ocean/README.md:20-30` to name the harmonic regression method and expected trend estimate.
- [x] **Verify the updated README** still reflects the ground truth and regeneration command.
- [ ] **Commit:** `git commit -m "docs: describe buoy SST trend analysis"`

**Dependencies:**
- Requires Phase 2 completion.

**Verification:**
- [x] `samples/ocean/README.md` explicitly names the trend-estimation method and states the expected `≈ 0.03 °C/yr` result.

## Success Criteria

### Automated Verification

- [ ] `pixi run python samples/ocean/test_generate_buoy_sst.py` passes.
- [ ] The committed CSV trend estimate is within `0.005 °C/yr` of `0.03`.
- [ ] The generator determinism test still passes.
- [ ] The repository stays limited to the existing sample files under `samples/ocean/`.

### Manual Verification

- [ ] A reader can inspect `samples/ocean/README.md` and see the recommended harmonic-regression analysis method.
- [ ] A reader can understand that the seasonal cycle is removed before the trend is interpreted.
- [ ] The reported trend is clearly stated as approximately `0.03 °C/yr`.

### Reproducibility & Correctness (research code)

- [ ] Seeds, data version, environment, and exact command captured in the sample docs and tests.
- [ ] Numerical correctness criterion: harmonic regression on the committed CSV returns a slope within `0.005 °C/yr` of `0.03`.
- [ ] The result reproduces using the committed `samples/ocean/buoy_sst.csv` and the same test command.

## Testing Strategy

Unit tests are written test-first within each phase. This section captures the additional verification beyond the per-phase assertions.

**Unit Test Coverage (summary, written in-phase):**
- [ ] Harmonic regression helper recovers `g.WARMING` from generated data.
- [ ] Harmonic regression helper recovers `0.03` from the committed CSV.
- [ ] Existing determinism test continues to pass.

**Integration Tests:**
- [ ] `pixi run python samples/ocean/test_generate_buoy_sst.py` exercises both generated and committed series end-to-end.

**Manual Testing:**
- [ ] Read `samples/ocean/README.md` and confirm the analysis method is documented.
- [ ] Verify the stated trend estimate matches the test output.

**Test Data Requirements:**
- `samples/ocean/buoy_sst.csv` committed sample data.
- `samples/ocean/generate_buoy_sst.py` synthetic generator for comparison.

## Migration Strategy

Not applicable. The work stays within the existing sample files and does not replace an older implementation.

## Risk Assessment

**Potential Risks:**
1. **Risk:** The helper duplicates logic already present in the standalone test.
   - **Likelihood:** Medium
   - **Impact:** Low
   - **Mitigation:** Keep the helper small and use it in all trend assertions so there is only one implementation path.

2. **Risk:** The committed CSV changes in the future and the exact slope shifts slightly.
   - **Likelihood:** Low
   - **Impact:** Medium
   - **Mitigation:** Keep the tolerance explicit (`0.005 °C/yr`) and compare against the documented ground truth.

## Edge Cases and Error Handling

**Edge Cases:**
1. **Case:** Missing or malformed `date` column.
   - **Expected Behavior:** The analysis should fail loudly during parsing rather than returning a misleading trend.
   - **Implementation:** `pd.to_datetime(df["date"])` in the helper causes a visible parsing error.

2. **Case:** Missing `sst_c` values.
   - **Expected Behavior:** The fit should fail or return an obviously invalid result, prompting data cleanup.
   - **Implementation:** The least-squares fit operates on the raw series and will surface the issue if the series cannot be converted cleanly.

## Performance Considerations

The data set is tiny (3653 rows), so performance is not a concern. The linear solve and date transforms are effectively instantaneous.

## Documentation Updates

- [x] Update `samples/ocean/README.md` to name the harmonic-regression trend estimate.
- [x] Add concise docstrings or comments to the helper in `samples/ocean/test_generate_buoy_sst.py`.

## Timeline Estimate

- Phase 1: short
- Phase 2: short
- Phase 3: short
- Total: short
