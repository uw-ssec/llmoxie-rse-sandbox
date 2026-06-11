# Experiment: Harmonic Regression vs Seasonal Decomposition for `samples/ocean/buoy_sst.csv`

---
**Date:** 2026-06-11
**Author:** AI Assistant
**Status:** Complete
**Related Documents:**
- [Research: Separating Trend and Seasonal Cycle in `samples/ocean/buoy_sst.csv`](research-trend-seasonality-buoy-sst.md)
- [Plan: Estimate Warming Trend After Removing Seasonal Cycle in `samples/ocean/buoy_sst.csv`](plan-trend-seasonality-buoy-sst.md)

---

## Experiment Goal

Compare two ways to recover the warming trend in the synthetic daily SST series: harmonic regression with annual sine/cosine terms, and a seasonal-smoothing decomposition baseline. The decision matters because the sample should expose a clear, reliable method for getting the known `0.03 °C/yr` trend after removing seasonality.

**Primary Question:** Which approach best recovers the embedded warming trend from `samples/ocean/buoy_sst.csv` with the least complexity?

**Context:** The committed series is synthetic and known to contain a linear warming rate plus an annual seasonal cycle, so the best method should be both accurate and easy to explain in the sample docs.

## Hypothesis

Harmonic regression will recover the embedded trend exactly to within the desired tolerance and will be simpler to maintain than a decomposition-based smoothing approach. A smoothing/decomposition baseline can also recover the trend, but it will be less direct and more sensitive to window choice.

**Expected Outcome:** Harmonic regression should estimate a slope near `0.0300 °C/yr`; a moving-average decomposition baseline should land in the same neighborhood when its window is chosen sensibly, but the result will depend on the smoothing window.

**Success Criteria:**
- The harmonic model returns a slope within `0.005 °C/yr` of `0.03`.
- The decomposition baseline returns a slope close enough to validate the embedded warming signal.
- The chosen method is understandable from the sample code alone.

## Approaches to Test

### Approach 1: Harmonic regression

**Description:** Fit intercept + sine(day-of-year) + cosine(day-of-year) + linear time by least squares.

**Pros:**
- Directly matches the generator structure.
- Recovers the warming slope as a single coefficient.
- Easy to test and document.

**Cons:**
- Assumes an approximately sinusoidal seasonal cycle.
- Less flexible than a fully nonparametric seasonal smoother.

**Complexity:** Low

### Approach 2: Seasonal smoothing decomposition baseline

**Description:** Estimate the long-term trend with a moving-average smoother and treat the remaining oscillation as seasonal structure.

**Pros:**
- Conceptually close to classical seasonal decomposition.
- Demonstrates a non-regression baseline for comparison.

**Cons:**
- Sensitive to the smoothing window.
- Requires extra judgment about the window size.
- More indirect for a known sinusoidal series.

**Complexity:** Medium

## Experiment Setup

**Environment:**
- Ubuntu 26.04 dev container in the `llmoxie-rse-sandbox` workspace.
- `numpy` and `pandas` available.
- `statsmodels` was not installed, so the STL conceptual comparison was approximated with a moving-average decomposition baseline instead; this is an explicit limitation of the environment, not a claim about STL itself.

**Test Data:**
- `samples/ocean/buoy_sst.csv`

**Constraints:**
- Keep the input data fixed across approaches.
- Use the committed sample CSV only.
- Report only measured outputs.

## Experiments Run

### Experiment 1: Testing Harmonic Regression

**Code Tested:**

`samples/ocean/buoy_sst.csv` was loaded and fit with:

```python
years=(date-date.iloc[0]).days/365.25
design=[1, sin(2π*doy/365.25), cos(2π*doy/365.25), years]
coef = lstsq(design, sst)
```

**Execution:**

`python` run against the committed CSV to fit the model and print the slope.

**Observations:**
- The fit produced a slope of `0.030038216159167852 °C/yr`.
- The result is extremely close to the documented `0.03 °C/yr` ground truth.
- The method uses only a few lines of readable code.

**Results:**
- ✅ Recovered the embedded warming trend within tolerance.
- ✅ No extra packages required.
- ⚠️ Assumes annual seasonality is well approximated by a sinusoid.

**Metrics:**
- Trend estimate: `0.030038216159167852 °C/yr`
- Absolute error vs ground truth: `0.00003821615916785243 °C/yr`

### Experiment 2: Testing Seasonal Smoothing Baseline

**Code Tested:**

The same CSV was smoothed with centered moving-average windows of 30, 90, and 365 days; a slope was then fit to the smoothed series over the interior region.

**Execution:**

`python` run against the committed CSV with three windows.

**Observations:**
- 30-day smoothing estimated a trend of `0.023190866462657157 °C/yr`.
- 90-day smoothing estimated a trend of `0.02923121969845593 °C/yr`.
- 365-day smoothing estimated a trend of `0.02993139842022284 °C/yr`.
- The result depends on the selected window, which adds tuning sensitivity.

**Results:**
- ✅ Can recover the warming signal.
- ❌ Requires choosing a smoothing window.
- ⚠️ The estimate is less direct than harmonic regression.

**Metrics:**
- 30-day slope: `0.023190866462657157 °C/yr`
- 90-day slope: `0.02923121969845593 °C/yr`
- 365-day slope: `0.02993139842022284 °C/yr`

## Comparison Matrix

| Criterion | Harmonic Regression | Seasonal Smoothing Baseline |
|-----------|---------------------|-----------------------------|
| **Performance** | Excellent; exact least-squares slope estimate | Good; slope depends on window |
| **Complexity** | Low | Medium |
| **Maintainability** | High; few lines, direct to the signal | Medium; smoothing choice is an extra knob |
| **Integration Ease** | High; fits the existing test file exactly | Medium; needs a smoothing decision and extra code |
| **Test Coverage** | Strong; direct numeric assertion against ground truth | Moderate; works, but only after window selection |

## Key Insights

1. Harmonic regression is the most direct match to the committed data generator and recovers the target warming rate with negligible error.
2. A smoothing/decomposition baseline can also expose the trend, but the window choice materially affects the output.
3. The environment did not include `statsmodels`, so STL was not measured directly; the baseline comparison is therefore a measured smoothing proxy, not a literal STL benchmark.

**Surprising Findings:**
- A 365-day moving average landed very close to the true warming rate even though it is a crude proxy for decomposition.

**Failed Assumptions:**
- The environment would provide `statsmodels`; it did not, so a direct STL run was not possible here.

## Recommendation

**Recommended Approach:** Harmonic regression

**Reasoning:** It matched the generator, produced the most accurate slope, required the least code, and had no tuning parameter beyond the model specification.

**Why Not Others:**
- **Seasonal smoothing baseline:** It works, but the answer changes with the window and is less transparent for this known sinusoidal series.

**Caveats:**
If the real analysis target has drifting seasonality, irregular sampling, or a non-sinusoidal annual cycle, a true STL or state-space approach would be worth revisiting.

**Implementation Considerations:**
- Keep the harmonic fit in the existing sample test file.
- Document the expected slope in the README.

## Conditions for Alternative Approaches

If the seasonal cycle is not close to sinusoidal, consider STL or a state-space model because they can handle broader seasonal shapes and changing structure.

If the goal is only a quick visual trend filter and the window choice can be tuned interactively, consider a smoothing decomposition baseline because it is simple to explain.

## Next Steps

1. Implement the harmonic-regression helper in `samples/ocean/test_generate_buoy_sst.py`.
2. Add the committed-CSV regression test.
3. Update `samples/ocean/README.md` to name the recommended method.

## References

**Research Documents:**
- [Research: Separating Trend and Seasonal Cycle in `samples/ocean/buoy_sst.csv`](research-trend-seasonality-buoy-sst.md)

**Plan Documents:**
- [Plan: Estimate Warming Trend After Removing Seasonal Cycle in `samples/ocean/buoy_sst.csv`](plan-trend-seasonality-buoy-sst.md)

**Code Files Tested:**
- `samples/ocean/buoy_sst.csv`

**External Resources:**
- `statsmodels` STL documentation was consulted conceptually; direct execution was unavailable in this environment.

---

## Appendix: Raw Experiment Data

```text
Harmonic regression slope: 0.030038216159167852
Moving-average slopes: 30d=0.023190866462657157, 90d=0.02923121969845593, 365d=0.02993139842022284
```