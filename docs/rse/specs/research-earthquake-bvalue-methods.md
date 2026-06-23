# Research: Earthquake Gutenberg–Richter b-value estimation methods

**Date:** 2026-06-23
**Scope:** both internal data inspection and external prior art
**Related Documents:** none found in `docs/rse/specs/` at the start of this research; the directory did not yet exist.

## Question / Scope

The research question is: what methods should be considered for estimating the Gutenberg–Richter b-value, the magnitude–frequency slope, for the catalog in `samples/seismic/earthquake_catalog.csv`?

In scope:

- Inspect the permitted seismic input file to identify fields, event count, date range, magnitude range, magnitude precision, and threshold sensitivity relevant to b-value estimation.
- Survey standard b-value estimation methods, especially frequency–magnitude regression, Aki/Utsu maximum-likelihood estimation, uncertainty estimation, magnitude-of-completeness handling, and methods for incomplete catalogs.
- Identify practical failure modes and a recommended direction for later implementation.

Out of scope:

- Reading restricted seismic files such as `samples/seismic/README.md`, `samples/seismic/GROUND_TRUTH.md`, `samples/seismic/generate_catalog.py`, or `samples/seismic/test_generate_catalog.py`.
- Implementing code. Detailed design is deferred to planning.
- Treating b-value estimates as earthquake prediction.

## Codebase Findings

Research was performed against repository commit `a5bfadc` on 2026-06-23.

### Catalog structure and span

- The catalog schema is minimal: `time,magnitude` in `samples/seismic/earthquake_catalog.csv:1`.
- The first data row is `2014-01-01T21:15:59,2.9` in `samples/seismic/earthquake_catalog.csv:2`.
- Early rows confirm ISO-like event timestamps and one-decimal magnitudes, for example `2014-01-02T02:40:45,2.1` in `samples/seismic/earthquake_catalog.csv:3` and `2014-01-10T13:50:53,6.5` in `samples/seismic/earthquake_catalog.csv:9`.
- The final data row is `2023-12-31T17:45:09,2.6` in `samples/seismic/earthquake_catalog.csv:3001`.
- The file has 3000 events plus one header row. The catalog spans 2014-01-01 through 2023-12-31.

### Magnitude distribution and threshold sensitivity

A direct summary of the permitted CSV found:

- Magnitude range: 2.0 to 7.2.
- Magnitudes appear rounded to one decimal place, so a magnitude bin width of $\Delta M = 0.1$ is appropriate for binned formulas.
- Annual event counts are relatively stable over 2014–2023, ranging from 283 to 318 events per year in the inspected file.
- Events at low magnitudes dominate the catalog. The largest one-decimal bins include 489 events at $M=2.0$, 416 at $M=2.1$, 339 at $M=2.2$, and 302 at $M=2.3$.
- A quick binned Aki/Utsu maximum-likelihood threshold scan gave $b \approx 0.78$ for $M_c$ from 2.0 through about 3.4, then more variable estimates as the sample above threshold shrinks.

These data findings imply that any implementation should make $M_c$ explicit, account for one-decimal magnitude binning, report sample size above the selected threshold, and avoid over-interpreting high-threshold estimates with small samples.

## Prior Art

### Gutenberg–Richter relationship

The Gutenberg–Richter frequency–magnitude relation is usually written as:

$$
\log_{10} N(M \ge m) = a - bm
$$

where $N(M \ge m)$ is the cumulative number of events at or above magnitude $m$, $a$ is a productivity/intercept term, and $b$ is the slope controlling the relative proportion of small and large earthquakes. A larger $b$ means relatively more small events; a smaller $b$ means relatively more large events. The original relationship is classically associated with Gutenberg and Richter's earthquake magnitude/frequency work in the 1940s.

### Regression on frequency–magnitude counts

A simple method is to bin magnitudes, compute cumulative counts, and fit a straight line to $\log_{10} N$ versus magnitude. This is useful as a diagnostic plot because it visually exposes roll-off below completeness and curvature at high magnitudes.

However, it is usually not the preferred estimator for a reported b-value. Cumulative counts are not independent across bins, results depend on bin choices and fitted range, and sparse high-magnitude bins can strongly influence ordinary least squares. For this reason, regression should be treated as exploratory/diagnostic rather than the primary estimator.

### Aki/Utsu maximum-likelihood estimator

Aki (1965) introduced maximum-likelihood estimation for the b-value under an exponential magnitude distribution above a completeness threshold. Utsu later developed related finite-sample and practical formulations widely used in seismology.

For unbinned magnitudes above completeness threshold $M_c$, the common estimator is:

$$
b = \frac{\log_{10}(e)}{\bar M - M_c}
$$

For magnitudes rounded or binned with width $\Delta M$, a commonly used correction is:

$$
b = \frac{\log_{10}(e)}{\bar M - (M_c - \Delta M/2)}
$$

For `samples/seismic/earthquake_catalog.csv`, $\Delta M = 0.1$ is consistent with the observed one-decimal magnitudes. This makes binned Aki/Utsu MLE a better primary estimator than linear regression, provided the selected events are above a defensible $M_c$.

### Magnitude of completeness

The magnitude of completeness $M_c$ is the lowest magnitude above which the catalog is assumed complete enough for frequency–magnitude modeling. It is often the dominant practical choice in b-value estimation.

Wiemer and Wyss (2000) discuss methods for estimating minimum magnitude of completeness in earthquake catalogs using examples from Alaska, the western United States, and Japan. Common approaches include maximum curvature of the non-cumulative frequency–magnitude distribution, goodness-of-fit tests against a Gutenberg–Richter model, and manual or domain-informed threshold selection.

For this sample catalog, a threshold-sensitivity table or plot is important because a single unqualified $M_c$ could hide estimation sensitivity. The preliminary threshold scan found stable b-values around $0.78$ across $M_c=2.0$ to $3.4$, but this is only an exploratory result until a completeness criterion and uncertainty method are selected.

### Uncertainty estimation

Practical uncertainty estimates should include at least:

- the number of events $n$ above $M_c$;
- an analytic standard error or confidence interval where assumptions are acceptable;
- a bootstrap interval obtained by resampling events above $M_c$.

Bootstrap uncertainty is straightforward for a demo implementation and makes the sensitivity to sample size visible. It should be paired with threshold sensitivity because uncertainty conditional on one $M_c$ does not capture uncertainty in the completeness threshold itself.

### Incomplete catalogs and b-positive

Catalogs may be temporarily incomplete after large earthquakes or during intense sequences because small events are missed in overlapping waveforms or operational processing. van der Elst (2021) proposed the `b-positive` estimator, based on positive magnitude differences between successive events, to reduce sensitivity to transient short-term incompleteness.

`b-positive` is most relevant if the analysis focuses on active aftershock sequences, sliding windows, or catalogs with unknown time-varying completeness. It is probably not the simplest default for this demo catalog, but it is important prior art and a useful option if later requirements emphasize transient completeness issues.

### Declustering and mixed populations

A b-value estimated from a full catalog can mix background seismicity, aftershock sequences, and potentially multiple tectonic/source regimes. Declustering or spatial/temporal stratification may be needed for scientific interpretation. For this sample, those choices should be framed as limitations unless additional location, region, or sequence metadata are introduced.

## Synthesis

The recommended direction for later implementation is:

1. Load `samples/seismic/earthquake_catalog.csv` and validate that required columns are `time` and `magnitude`.
2. Treat magnitudes as one-decimal binned values with $\Delta M = 0.1$ unless future data prove otherwise.
3. Compute and show a frequency–magnitude diagnostic plot with cumulative and/or non-cumulative counts.
4. Estimate b-value primarily with binned Aki/Utsu maximum likelihood above an explicit $M_c$.
5. Report threshold sensitivity over a user-visible range of $M_c$ values, including sample size above threshold.
6. Use bootstrap resampling for uncertainty intervals.
7. Clearly label regression estimates, if included, as diagnostic comparisons rather than the preferred reported estimate.
8. Mention `b-positive` as an optional method for future work on transiently incomplete aftershock catalogs.

For the current sample dataset, the early exploratory scan suggests a stable binned-MLE value near $b \approx 0.78$ over several plausible thresholds, but that value should not be reported alone. It should be accompanied by the selected $M_c$, $n(M \ge M_c)$, bin width, uncertainty interval, and a threshold-sensitivity table or plot.

Open questions for planning:

- Should $M_c$ be user-specified, automatically estimated, or both?
- Which completeness estimator should be implemented first: maximum curvature, goodness-of-fit, manual threshold, or a combination?
- Should the demo include declustering caveats only, or implement a declustering method later?
- Should outputs be a command-line summary, a plot, a notebook-style analysis script, or tests around a reusable Python function?

## References / Sources

- Code/data: `samples/seismic/earthquake_catalog.csv:1`, `samples/seismic/earthquake_catalog.csv:2`, `samples/seismic/earthquake_catalog.csv:3`, `samples/seismic/earthquake_catalog.csv:9`, `samples/seismic/earthquake_catalog.csv:3001`.
- Gutenberg, B. and Richter, C. F. (1944). Frequency of earthquakes in California. *Bulletin of the Seismological Society of America*, 34(4), 185–188. DOI: `10.1785/BSSA0340040185`.
- Aki, K. (1965). Maximum likelihood estimate of b in the formula log N = a - bM and its confidence limits. *Bulletin of the Earthquake Research Institute*, 43, 237–239.
- Utsu, T. (1965). A method for determining the value of b in a formula log n = a - bM showing the magnitude-frequency relation for earthquakes. *Geophysical Bulletin of Hokkaido University*, 13, 99–103.
- Wiemer, S. and Wyss, M. (2000). Minimum Magnitude of Completeness in Earthquake Catalogs: Examples from Alaska, the Western United States, and Japan. *Bulletin of the Seismological Society of America*, 90(4), 859–869. DOI: `10.1785/0119990114`.
- van der Elst, N. J. (2021). B-Positive: A Robust Estimator of Aftershock Magnitude Distribution in Transiently Incomplete Catalogs. *Journal of Geophysical Research: Solid Earth*, 126(2). DOI: `10.1029/2020JB021027`.
