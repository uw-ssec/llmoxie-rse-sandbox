"""Standalone checks for the buoy SST generator.

Run with: pixi run python samples/ocean/test_generate_buoy_sst.py
(The sandbox env has no pytest; these are plain asserts.)
"""
import sys
from pathlib import Path

import numpy as np
import pandas as pd

sys.path.insert(0, str(Path(__file__).parent))
import generate_buoy_sst as g  # noqa: E402


def test_deterministic():
    """Two generations must be byte-for-byte identical (fixed seed)."""
    assert g.generate().equals(g.generate())


def test_recovers_warming_slope():
    """A harmonic-plus-linear fit recovers the embedded WARMING slope."""
    df = g.generate()
    dates = pd.to_datetime(df["date"])
    doy = dates.dt.dayofyear.to_numpy()
    years = (dates - dates.iloc[0]).dt.days.to_numpy() / 365.25  # mirrors the generator's years computation
    design = np.column_stack([
        np.ones_like(years),
        np.sin(2 * np.pi * doy / 365.25),
        np.cos(2 * np.pi * doy / 365.25),
        years,
    ])
    coef, *_ = np.linalg.lstsq(design, df["sst_c"].to_numpy(), rcond=None)
    assert abs(coef[3] - g.WARMING) < 0.005, coef[3]


if __name__ == "__main__":
    test_deterministic()
    test_recovers_warming_slope()
    print("OK: deterministic and recovers warming slope")
