# Synthetic buoy sea-surface-temperature (SST) sample

`buoy_sst.csv` is a **synthetic** ~10-year daily SST series for a single coastal
buoy, produced by `generate_buoy_sst.py`. It exists so the research-loop demo
(`docs/slides/research-loop-ocean.md`) can test a warming-trend hypothesis
against a **known answer**.

## Columns

| Column | Meaning |
|---|---|
| `date` | Calendar date (`YYYY-MM-DD`), daily from 2014-01-01 |
| `sst_c` | Sea-surface temperature in °C |

## Ground truth (the answer the loop should recover)

The signal is `sst = MEAN + AMP·sin(2π·doy/365.25 + PHASE) + WARMING·years + noise`:

| Parameter | Value | Role |
|---|---|---|
| `MEAN` | 14.0 °C | Annual-mean SST |
| `AMP` | 5.0 °C | Seasonal amplitude |
| `PHASE` | -1.5 rad | Seasonal phase (late-summer peak) |
| `WARMING` | **0.03 °C/yr** | The trend a correct analysis must recover |
| `NOISE_SD` | 0.5 °C | Daily observational noise |
| `SEED` | 20260608 | RNG seed (data provenance) |

A correct trend analysis should recover a warming slope of **≈ 0.03 °C/yr**
(about 0.3 °C/decade) after removing the seasonal cycle. Use this to check what
`/validate` reports in the demo.

## Regenerating

```bash
pixi run python samples/ocean/generate_buoy_sst.py
```

Deterministic: regeneration reproduces `buoy_sst.csv` byte-for-byte.
