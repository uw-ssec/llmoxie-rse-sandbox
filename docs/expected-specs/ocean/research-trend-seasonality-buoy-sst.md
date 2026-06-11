# Research: Separating Trend and Seasonal Cycle in `samples/ocean/buoy_sst.csv`

**Date:** 2026-06-11
**Scope:** both
**Related Documents:** `samples/ocean/README.md`, `samples/ocean/generate_buoy_sst.py`, `samples/ocean/test_generate_buoy_sst.py`

## Question / Scope

Find methods to separate a long-term trend from a seasonal cycle in the daily SST series in `samples/ocean/buoy_sst.csv`. Relevant methods include classical time-series decomposition, regression with seasonal terms, and robust smoothing approaches that can recover a slowly varying trend from an annual cycle.

## Codebase Findings

`samples/ocean/buoy_sst.csv` is a synthetic daily series with `date` and `sst_c` columns spanning 2014-01-01 to 2024-01-01, 3653 rows total. The committed data is intended as a known-answer benchmark for warming-trend recovery. `samples/ocean/README.md:3-5`, `samples/ocean/README.md:11-18`

The ground-truth signal is explicitly defined as mean + annual sinusoid + linear warming + noise. The documented warming rate is `0.03 °C/yr`, seasonal amplitude is `5.0 °C`, and the series is deterministic via seed `20260608`. `samples/ocean/README.md:20-30`, `samples/ocean/generate_buoy_sst.py:20-40`

The generator confirms the core structure: seasonal component uses `sin(2 * pi * doy / 365.25 + PHASE)`, trend is `WARMING * years`, and the output is rounded to three decimals before writing CSV. That makes linear-plus-seasonal models a natural fit for this dataset. `samples/ocean/generate_buoy_sst.py:31-47`

The repository includes a simple validation test that fits intercept + sine + cosine + linear time by least squares and checks that the estimated linear coefficient is close to the embedded warming rate. This is a direct internal example of a regression-with-seasonality approach. `samples/ocean/test_generate_buoy_sst.py:15-35`

Observed pattern from the series: quarterly means rise from winter to summer and fall again in autumn, confirming a strong annual cycle rather than a monotonic-only trend. The fitted harmonic model on the committed file recovers a trend of about `0.0300 °C/yr`, matching the documented ground truth. `samples/ocean/buoy_sst.csv` (computed from the current file), `samples/ocean/README.md:24-29`

## Prior Art

### Classical seasonal decomposition

`statsmodels.tsa.seasonal.seasonal_decompose` decomposes a time series into trend, seasonal, and residual components using moving averages for the trend and an estimated repeating seasonal pattern. It is simple and interpretable, and works well when seasonality is stable and the time index is regular. Its documented limitations include the need for an additive or multiplicative structure, sensitivity to edge effects, and a requirement for at least two full seasonal cycles. [`statsmodels seasonal_decompose`](https://www.statsmodels.org/stable/generated/statsmodels.tsa.seasonal.seasonal_decompose.html)

### STL decomposition

STL (`statsmodels.tsa.seasonal.STL`) is a robust decomposition based on LOESS smoothing. It is designed to separate trend and seasonality more flexibly than classical moving-average decomposition, and it is commonly recommended when the seasonal pattern may drift slowly or contain outliers. The official docs note that STL is robust and flexible, but it remains an additive decomposition and still depends on a chosen seasonal period. [`statsmodels STL`](https://www.statsmodels.org/stable/generated/statsmodels.tsa.seasonal.STL.html)

### Regression with seasonal basis terms

Modeling the series as a linear trend plus harmonic seasonal terms (sine/cosine pairs) is a standard alternative when the seasonal cycle is approximately sinusoidal. It directly estimates the long-term slope while controlling for seasonality, and it is especially convenient when the seasonal phase and amplitude are stable. The internal test file uses exactly this form, which makes it a good candidate baseline for this dataset. `samples/ocean/test_generate_buoy_sst.py:15-35`

### GAM / spline trend models

Generalized additive models can represent the long-term trend with a smooth spline while using a seasonal term for periodic structure. This is useful when the trend is nonlinear, because the long-term component is not forced to be a straight line. The tradeoff is more modeling choices and a higher risk of overfitting than a simple harmonic regression. [`pyGAM`](https://pygam.readthedocs.io/en/latest/)

### State-space / structural time-series models

Structural time-series models combine a latent trend, seasonal states, and noise in a probabilistic framework. They are useful when uncertainty quantification matters or when the trend and seasonal components may evolve over time. The downside is extra modeling and estimation complexity relative to decomposition or least-squares regression. [`statsmodels UnobservedComponents`](https://www.statsmodels.org/stable/generated/statsmodels.tsa.statespace.structural.UnobservedComponents.html)

### Disconfirming evidence / cautions

Classical decomposition methods can mislead if the seasonal pattern changes over time, if the trend is nonlinear, or if the data contain missing values or irregular sampling. STL is more robust than classical decomposition, but it still assumes a fixed seasonal period and additive structure. Harmonic regression is simple and effective here, but it can underfit if the annual cycle is not close to sinusoidal or if the warming rate itself varies over the decade. [`statsmodels seasonal_decompose`](https://www.statsmodels.org/stable/generated/statsmodels.tsa.seasonal.seasonal_decompose.html), [`statsmodels STL`](https://www.statsmodels.org/stable/generated/statsmodels.tsa.seasonal.STL.html)

## Synthesis

For this specific synthetic SST series, the codebase already encodes the answer: the seasonal cycle is a stable annual sinusoid, and the trend is linear. That makes harmonic regression the most direct baseline, with `trend + sin(day-of-year) + cos(day-of-year)` mirroring the generator and the existing test. `samples/ocean/generate_buoy_sst.py:31-40`, `samples/ocean/test_generate_buoy_sst.py:15-35`

If the goal is analysis rather than validation, STL is the strongest general-purpose decomposition option because it is robust and easy to inspect; classical seasonal decomposition is simpler but less flexible. If the long-term trend may be nonlinear, a spline/GAM or state-space model becomes more appropriate, but those are more elaborate than needed to recover the known `0.03 °C/yr` warming embedded in this file. `samples/ocean/README.md:24-29`

## References / Sources

- Code: `samples/ocean/README.md:3-30`, `samples/ocean/generate_buoy_sst.py:20-47`, `samples/ocean/test_generate_buoy_sst.py:15-35`
- External: [statsmodels seasonal_decompose](https://www.statsmodels.org/stable/generated/statsmodels.tsa.seasonal.seasonal_decompose.html), [statsmodels STL](https://www.statsmodels.org/stable/generated/statsmodels.tsa.seasonal.STL.html), [statsmodels UnobservedComponents](https://www.statsmodels.org/stable/generated/statsmodels.tsa.statespace.structural.UnobservedComponents.html), [pyGAM docs](https://pygam.readthedocs.io/en/latest/)