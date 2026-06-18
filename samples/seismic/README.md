# Synthetic earthquake-catalog sample

`earthquake_catalog.csv` is a **synthetic** ~10-year catalog of earthquakes for a
single seismically active region, produced by `generate_catalog.py`. It exists so
the research-loop demo (`docs/slides/research-loop-seismic.md`) can test a
Gutenberg–Richter **b-value** hypothesis against a **known answer**.

## Columns

| Column | Meaning |
|---|---|
| `time` | Origin time of the event (ISO-8601), within 2014–2024 |
| `magnitude` | Earthquake magnitude, reported to 0.1 |

## Ground truth

The generator bakes a known answer into this data so a human can check the demo's
result. It is documented separately in [`GROUND_TRUTH.md`](GROUND_TRUTH.md) —
**for human reviewers only**. AI agents analyzing this data must not read that file
(see the repository `.github/copilot-instructions.md`); the point of the demo is to
recover the answer from `earthquake_catalog.csv` alone.

## Regenerating

```bash
pixi run python samples/seismic/generate_catalog.py
```

Deterministic: regeneration reproduces `earthquake_catalog.csv` byte-for-byte.
