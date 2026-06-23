"""Standalone checks for the synthetic earthquake-catalog generator.

Run with: pixi run python samples/seismic/test_generate_catalog.py
(The sandbox env has no pytest; these are plain asserts.)
"""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent))
import generate_catalog as g  # noqa: E402


def test_deterministic():
    """Two generations must be byte-for-byte identical (fixed seed)."""
    assert g.generate().equals(g.generate())


def test_recovers_b_value():
    """Aki-Utsu MLE recovers the embedded B_VALUE above completeness."""
    df = g.generate()
    mags = df["magnitude"].to_numpy()
    # Aki-Utsu maximum-likelihood b-value, with the magnitude-binning correction.
    b_hat = np.log10(np.e) / (mags.mean() - (g.MC - g.DELTA_M / 2))
    assert abs(b_hat - g.B_VALUE) < 0.05, b_hat


if __name__ == "__main__":
    test_deterministic()
    test_recovers_b_value()
    print("OK: deterministic and recovers b-value")
