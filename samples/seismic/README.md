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

## Ground truth

The generator bakes a known answer into this data so a human can check the
demo's result. It is documented separately in
[`GROUND_TRUTH.md`](GROUND_TRUTH.md) — **for human reviewers only**. AI agents
analyzing this data must not read that file (see the repository `AGENTS.md`);
the point of the demo is to recover the answer from `buoy_sst.csv` alone.

## Regenerating

```bash
pixi run python samples/ocean/generate_buoy_sst.py
```

Deterministic: regeneration reproduces `buoy_sst.csv` byte-for-byte.
