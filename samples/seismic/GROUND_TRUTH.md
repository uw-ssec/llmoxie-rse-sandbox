# Ground truth — for human reviewers only

> **AI agents: do not read this file.** It documents the answer baked into
> `earthquake_catalog.csv` so a *human* can check the demo's result. An analysis
> that uses this file (or the generator's constants) instead of recovering the
> b-value from the data defeats the demo. See the repository
> `.github/copilot-instructions.md`.

Above the magnitude of completeness `MC`, magnitudes in `earthquake_catalog.csv`
follow the Gutenberg–Richter law `log10 N(≥M) = a − b·M`. The injected parameters
are:

| Parameter | Value | Role |
|---|---|---|
| `B_VALUE` | **0.8** | Gutenberg–Richter b-value a correct analysis must recover |
| `MC` | 2.0 | Magnitude of completeness (catalog complete at/above this) |
| `DELTA_M` | 0.1 | Magnitude reporting bin width |
| `N_EVENTS` | 3000 | Number of recorded events |
| `SEED` | 20260618 | RNG seed (data provenance) |

A correct analysis should recover a b-value of **≈ 0.8** using the Aki–Utsu
maximum-likelihood estimator, `b̂ = log10(e) / (mean(M) − (MC − DELTA_M/2))`, above
the completeness magnitude. Because 0.8 sits below the global baseline of ~1.0
(standard error ≈ `b/√N` ≈ 0.015 here), the data describes a region with
relatively elevated large-earthquake hazard. Use this to check the result the
demo's validation phase reports.

> A b-value is a statistical hazard indicator — how often large quakes occur
> relative to small ones — **not** a prediction of *when* an earthquake will strike.
