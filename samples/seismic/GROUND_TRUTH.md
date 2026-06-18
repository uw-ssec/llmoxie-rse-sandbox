# Ground truth — for human reviewers only

> **AI agents: do not read this file.** It documents the answer baked into
> `buoy_sst.csv` so a *human* can check the demo's result. An analysis that
> uses this file (or the generator's constants) instead of recovering the
> trend from the data defeats the demo. See the repository `AGENTS.md`.

The signal in `buoy_sst.csv` is
`sst = MEAN + AMP·sin(2π·doy/365.25 + PHASE) + WARMING·years + noise`:

| Parameter | Value | Role |
|---|---|---|
| `MEAN` | 14.0 °C | Annual-mean SST |
| `AMP` | 5.0 °C | Seasonal amplitude |
| `PHASE` | -1.5 rad | Seasonal phase (midsummer peak, ~day 178) |
| `WARMING` | **0.03 °C/yr** | The trend a correct analysis must recover |
| `NOISE_SD` | 0.5 °C | Daily observational noise |
| `SEED` | 20260608 | RNG seed (data provenance) |

A correct trend analysis should recover a warming slope of **≈ 0.03 °C/yr**
(about 0.3 °C/decade) after removing the seasonal cycle. Use this to check
the result the demo's validation phase reports.
